# 🏗️ ARQUITETURA DASHBOARD TITANIO — CLIENTES EXTERNOS
## Multi-Tenant, Acesso Remoto, Segurança e Privacidade

**Versão:** 1.0  
**Data:** 02/04/2026  
**Autor:** Squad HiClaw — Tita (Especialista em Segurança & Produto)  
**Classificação:** Interno — Equipe Titanio  
**Primeiro cliente-alvo:** H2O Films (distribuidora de cinema, 84K seguidores)

---

## SUMÁRIO EXECUTIVO

Este documento define a **arquitetura completa** para transformar a Dashboard Titanio 2.0 (atualmente interna) em uma plataforma multi-tenant segura, acessível remotamente por clientes como a H2O Films.

**Stack base:** Next.js (frontend) + Express.js (API) + PostgreSQL (dados)

**10 pilares de arquitetura:**
1. Multi-Tenant com isolamento de dados
2. Acesso remoto seguro (decisão: Cloudflare Tunnel)
3. Autenticação robusta (JWT + MFA)
4. RBAC com 3 perfis base
5. Compliance LGPD
6. Dashboard white-label
7. Audit trail completo
8. Backup por cliente
9. Onboarding automatizado
10. Pricing e limites por plano

**Tempo total de implementação estimado: 3-4 semanas** (com a stack já existente)

---

## 1. ARQUITETURA MULTI-TENANT

### 1.1 Estratégias Disponíveis

Existem 3 abordagens clássicas de multi-tenancy:

| Estratégia | Isolamento | Custo | Complexidade | Nossa escolha? |
|------------|-----------|-------|-------------|----------------|
| **Banco separado por cliente** | Máximo | Alto (infra) | Alta (migrations múltiplas) | ❌ Caro demais |
| **Schema separado por cliente** | Alto | Médio | Média | ✅ **RECOMENDADO** |
| **Tabelas compartilhadas + tenant_id** | Baixo/Médio | Baixo | Baixa-Média | ⚠️ Risco de vazamento |

**Decisão: Schema por cliente (PostgreSQL Schemas)**

Cada cliente recebe um schema isolado (`titanio`, `h2o_films`, `cliente_x`). Isso garante:
- Queries não cruzam dados entre clientes (impossível por padrão)
- Migrations podem ser aplicadas cliente a cliente
- Backup e restore individual sem impacto nos outros
- Performance não degrada com crescimento de clientes

### 1.2 Estrutura do Banco de Dados

```sql
-- Schema global (compartilhado, dados de sistema)
CREATE SCHEMA public;  -- já existe

-- Schema por cliente
CREATE SCHEMA titanio;      -- Titanio (uso interno)
CREATE SCHEMA h2o_films;    -- H2O Films
CREATE SCHEMA cliente_xyz;  -- próximo cliente

-- Tabela de tenants no schema público
CREATE TABLE public.tenants (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        VARCHAR(50) UNIQUE NOT NULL,  -- 'h2o_films'
  name        VARCHAR(100) NOT NULL,         -- 'H2O Films'
  schema_name VARCHAR(50) UNIQUE NOT NULL,  -- 'h2o_films'
  plan        VARCHAR(20) DEFAULT 'starter', -- starter/pro/enterprise
  active      BOOLEAN DEFAULT true,
  config      JSONB DEFAULT '{}',            -- cores, logo, domínio
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de usuários (multi-tenant aware)
CREATE TABLE public.users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID REFERENCES public.tenants(id),
  email       VARCHAR(255) NOT NULL,
  name        VARCHAR(100) NOT NULL,
  role        VARCHAR(30) NOT NULL,  -- admin_titanio / gestor_cliente / operador_cliente
  password_hash VARCHAR(255),
  mfa_secret  VARCHAR(100),          -- TOTP secret (criptografado)
  mfa_enabled BOOLEAN DEFAULT false,
  active      BOOLEAN DEFAULT true,
  last_login  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, email)
);

-- Índices críticos para performance
CREATE INDEX idx_users_tenant ON public.users(tenant_id);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_tenants_slug ON public.tenants(slug);
```

### 1.3 Templates de Schema por Cliente

Ao criar um novo cliente, um **schema template** é copiado automaticamente:

```sql
-- Template (aplicado a cada novo schema de cliente)
-- Ex: aplicado em h2o_films

-- Projetos/Campanhas do cliente
CREATE TABLE {schema}.projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(200) NOT NULL,
  type        VARCHAR(50),  -- 'lancamento', 'campanha', 'evento'
  status      VARCHAR(30) DEFAULT 'active',
  metadata    JSONB DEFAULT '{}',
  created_by  UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Métricas/Analytics do cliente
CREATE TABLE {schema}.metrics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID REFERENCES {schema}.projects(id),
  metric_name VARCHAR(100) NOT NULL,
  metric_value NUMERIC,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conteúdo (posts, vídeos, etc.)
CREATE TABLE {schema}.content (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID REFERENCES {schema}.projects(id),
  type        VARCHAR(50),     -- 'post', 'reel', 'story', 'press_release'
  title       VARCHAR(300),
  body        TEXT,
  status      VARCHAR(30) DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  metadata    JSONB DEFAULT '{}',
  created_by  UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Configurações específicas do cliente
CREATE TABLE {schema}.settings (
  key         VARCHAR(100) PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.4 Row-Level Security (Camada Extra de Proteção)

Mesmo com schemas separados, adicionar RLS garante que um bug no código nunca vaze dados:

```sql
-- Habilitar RLS em tabelas críticas (schema público)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Política: usuário só vê users do próprio tenant
CREATE POLICY tenant_isolation ON public.users
  USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Função helper para setar o contexto na conexão
CREATE OR REPLACE FUNCTION set_tenant_context(p_tenant_id UUID)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant_id::text, true);
END;
$$ LANGUAGE plpgsql;
```

### 1.5 Middleware de Tenant no Express

```javascript
// middleware/tenant.js
const { Pool } = require('pg');

// Pool de conexões com suporte a schema dinâmico
const createTenantPool = (schemaName) => {
  return new Pool({
    connectionString: process.env.DATABASE_URL,
    // Seta o search_path na conexão
    // Garantia: queries no schema certo
  });
};

const tenantMiddleware = async (req, res, next) => {
  try {
    // 1. Extrai tenant do JWT ou subdomínio
    const tenantSlug = extractTenant(req);
    
    if (!tenantSlug) {
      return res.status(401).json({ error: 'Tenant not identified' });
    }
    
    // 2. Busca tenant no banco (com cache Redis)
    const tenant = await getTenantBySlug(tenantSlug);
    
    if (!tenant || !tenant.active) {
      return res.status(403).json({ error: 'Tenant inactive or not found' });
    }
    
    // 3. Injeta no request (disponível para todos os handlers)
    req.tenant = tenant;
    req.schemaName = tenant.schema_name;
    
    // 4. Seta o search_path do PostgreSQL para o schema do cliente
    // Isso garante que todas as queries usem o schema correto
    req.db = {
      query: (text, params) => pool.query(
        `SET search_path TO ${tenant.schema_name}, public; ${text}`,
        params
      )
    };
    
    next();
  } catch (error) {
    next(error);
  }
};

// Como extrair o tenant
const extractTenant = (req) => {
  // Opção 1: Subdomínio (h2o.titanio.app)
  const host = req.headers.host;
  const subdomain = host.split('.')[0];
  if (subdomain !== 'www' && subdomain !== 'titanio') {
    return subdomain;
  }
  
  // Opção 2: Header customizado
  if (req.headers['x-tenant-id']) {
    return req.headers['x-tenant-id'];
  }
  
  // Opção 3: JWT claims (tenant_slug no payload)
  if (req.user?.tenant_slug) {
    return req.user.tenant_slug;
  }
  
  return null;
};

module.exports = { tenantMiddleware };
```

**Tempo de implementação:** 3-4 dias  
**Ferramentas open-source:** PostgreSQL (nativo), `pg` (Node.js driver), Redis (cache de tenant lookup)

---

## 2. ACESSO REMOTO SEGURO

### 2.1 Comparação das Opções

| Solução | Pros | Contras | Custo | Adequação para Titanio |
|---------|------|---------|-------|----------------------|
| **Cloudflare Tunnel** | Zero porta aberta, CDN grátis, domínio próprio, DDoS protection | Depende de Cloudflare | Grátis (Free tier suficiente) | ⭐⭐⭐⭐⭐ **MELHOR** |
| **Tailscale** | P2P criptografado, fácil setup, sem DNS | Requer cliente instalado, não serve para browser público | Grátis até 3 users | ⭐⭐⭐ (acesso interno equipe) |
| **WireGuard VPN** | Máximo controle, mais rápido | Requer config manual, IP fixo necessário | Grátis (auto-hospedado) | ⭐⭐ (complexo para cliente final) |
| **ngrok** | Setup zero | Cara em produção, domínio aleatório | $8-25/mês | ⭐⭐ (só dev) |

### 2.2 Decisão: Cloudflare Tunnel (Produção) + Tailscale (Admin)

**Arquitetura híbrida:**

```
┌─────────────────────────────────────────────────────┐
│                   INTERNET                           │
└─────────────────┬───────────────┬───────────────────┘
                  │               │
        ┌─────────▼──────┐  ┌────▼──────────┐
        │  Cloudflare     │  │  Tailscale    │
        │  Tunnel         │  │  Network      │
        │  (clientes)     │  │  (equipe TI)  │
        └─────────┬──────┘  └────┬──────────┘
                  │               │
        ┌─────────▼───────────────▼──────────┐
        │         MAC MINI (Servidor)         │
        │                                     │
        │  [h2o.titanio.app] → Port 3000      │
        │  [dashboard.titanio.app] → Port 3000 │
        │  [admin.titanio.app] → Port 3001    │
        └─────────────────────────────────────┘
```

### 2.3 Setup Cloudflare Tunnel (Passo a Passo)

```bash
# 1. Instalar cloudflared (Mac)
brew install cloudflare/cloudflare/cloudflared

# 2. Autenticar com sua conta Cloudflare
cloudflared tunnel login

# 3. Criar o túnel
cloudflared tunnel create titanio-dashboard
# Resultado: tunnel ID (salvar!)
# Arquivo de credenciais criado em ~/.cloudflared/<TUNNEL_ID>.json

# 4. Criar arquivo de configuração
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <TUNNEL_ID>
credentials-file: /Users/contact/.cloudflared/<TUNNEL_ID>.json

ingress:
  # Dashboard principal (todos os tenants via subdomínio)
  - hostname: "*.titanio.app"
    service: http://localhost:3000
  
  # Admin Titanio
  - hostname: admin.titanio.app
    service: http://localhost:3001
  
  # Catch-all (obrigatório)
  - service: http_status:404
EOF

# 5. Adicionar registros DNS na Cloudflare
cloudflared tunnel route dns titanio-dashboard "*.titanio.app"
cloudflared tunnel route dns titanio-dashboard admin.titanio.app

# 6. Instalar como serviço no macOS (auto-start)
sudo cloudflared service install
sudo launchctl start com.cloudflare.cloudflared

# 7. Verificar status
cloudflared tunnel info titanio-dashboard
```

### 2.4 Proteção Extra: Cloudflare Access (Zero Trust)

Para o painel admin e áreas sensíveis, adicionar autenticação antes mesmo de chegar ao servidor:

```bash
# Via Cloudflare Dashboard → Access → Applications → Add Application
# Configurar:
# - Application: admin.titanio.app
# - Identity Provider: One-time PIN (email) ou Google
# - Policy: Allow apenas emails @titaniofilms.com

# Para H2O Films:
# - Application: h2o.titanio.app
# - Policy: Allow emails do domínio H2O ou lista específica
```

### 2.5 Tailscale para Equipe Titanio

```bash
# Instalar no Mac Mini (servidor)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=192.168.1.0/24

# Instalar nos MacBooks da equipe
brew install tailscale
tailscale up

# Resultado: Helber, Tiago, etc. acessam o servidor
# diretamente pelo IP Tailscale sem Cloudflare
# Útil para: SSH, debug, acesso a admin interno
```

**Tempo de implementação:** 1 dia  
**Custo:** R$0 (Cloudflare Free + Tailscale Free para equipe pequena)

---

## 3. AUTENTICAÇÃO (JWT + MFA)

### 3.1 Arquitetura de Auth

```
┌──────────┐    POST /auth/login     ┌──────────────┐
│  Cliente │ ──────────────────────► │  Auth Service│
│ (Browser)│                         │  (Express)   │
└──────────┘ ◄────────────────────── └──────────────┘
              access_token (15min)          │
              refresh_token (7 dias)        │
              (httpOnly cookie)             │
                                     ┌──────┴──────┐
                                     │ PostgreSQL  │
                                     │ users table │
                                     └─────────────┘
```

### 3.2 Implementação JWT + Refresh Tokens

```javascript
// services/auth.service.js
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const ACCESS_TOKEN_SECRET = process.env.JWT_SECRET;
const REFRESH_TOKEN_SECRET = process.env.JWT_REFRESH_SECRET;

// Gerar par de tokens
const generateTokens = (user) => {
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    tenant_id: user.tenant_id,
    tenant_slug: user.tenant_slug,
  };

  const accessToken = jwt.sign(payload, ACCESS_TOKEN_SECRET, {
    expiresIn: '15m',    // Curto: se vazar, expira rápido
    issuer: 'titanio.app',
    audience: 'titanio-dashboard',
  });

  const refreshToken = jwt.sign(
    { sub: user.id, jti: crypto.randomUUID() },  // jti = unique ID do token
    REFRESH_TOKEN_SECRET,
    { expiresIn: '7d' }
  );

  return { accessToken, refreshToken };
};

// Login com MFA
const login = async (email, password, mfaCode = null, tenantSlug) => {
  // 1. Buscar usuário
  const user = await db.query(
    'SELECT u.*, t.slug as tenant_slug FROM public.users u JOIN public.tenants t ON u.tenant_id = t.id WHERE u.email = $1 AND t.slug = $2',
    [email, tenantSlug]
  );

  if (!user.rows[0]) throw new Error('Invalid credentials');

  // 2. Verificar senha (bcrypt, custo 12)
  const validPassword = await bcrypt.compare(password, user.rows[0].password_hash);
  if (!validPassword) {
    await logAudit(user.rows[0].id, 'login_failed', { reason: 'wrong_password' });
    throw new Error('Invalid credentials');
  }

  // 3. Verificar MFA (se habilitado)
  if (user.rows[0].mfa_enabled) {
    if (!mfaCode) {
      return { requires_mfa: true };  // Frontend mostra tela de MFA
    }
    
    const validMFA = verifyTOTP(user.rows[0].mfa_secret, mfaCode);
    if (!validMFA) {
      await logAudit(user.rows[0].id, 'login_failed', { reason: 'wrong_mfa' });
      throw new Error('Invalid MFA code');
    }
  }

  // 4. Gerar tokens
  const tokens = generateTokens(user.rows[0]);

  // 5. Salvar refresh token (para revogação)
  await db.query(
    'INSERT INTO public.refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, NOW() + INTERVAL \'7 days\')',
    [user.rows[0].id, hashToken(tokens.refreshToken)]
  );

  // 6. Atualizar last_login
  await db.query('UPDATE public.users SET last_login = NOW() WHERE id = $1', [user.rows[0].id]);

  // 7. Log de audit
  await logAudit(user.rows[0].id, 'login_success', {});

  return tokens;
};

// Refresh token (renovar access token sem fazer login novamente)
const refreshAccessToken = async (refreshToken) => {
  // 1. Verificar assinatura
  const payload = jwt.verify(refreshToken, REFRESH_TOKEN_SECRET);

  // 2. Verificar se não foi revogado
  const stored = await db.query(
    'SELECT * FROM public.refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND expires_at > NOW() AND revoked = false',
    [payload.sub, hashToken(refreshToken)]
  );

  if (!stored.rows[0]) throw new Error('Token revoked or expired');

  // 3. Buscar usuário atualizado
  const user = await getUserById(payload.sub);

  // 4. Gerar novo access token
  return generateTokens(user);
};

// Logout (revogar refresh token)
const logout = async (refreshToken) => {
  await db.query(
    'UPDATE public.refresh_tokens SET revoked = true WHERE token_hash = $1',
    [hashToken(refreshToken)]
  );
};

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');
```

### 3.3 Tabela de Refresh Tokens

```sql
CREATE TABLE public.refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash  VARCHAR(64) NOT NULL,  -- SHA-256 do token
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  ip_address  INET,        -- IP que gerou o token
  user_agent  TEXT         -- Browser/App que gerou
);

CREATE INDEX idx_refresh_tokens_user ON public.refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens(token_hash);
```

### 3.4 Implementação MFA (TOTP — Google Authenticator)

```javascript
// services/mfa.service.js
const speakeasy = require('speakeasy');  // npm install speakeasy
const QRCode = require('qrcode');       // npm install qrcode

// Gerar secret para novo usuário
const setupMFA = async (userId, email, tenantName) => {
  const secret = speakeasy.generateSecret({
    name: `${tenantName} Dashboard (${email})`,
    issuer: 'Titanio',
    length: 20,
  });

  // Salvar secret (criptografado) no banco
  const encrypted = encryptSecret(secret.base32);
  await db.query('UPDATE public.users SET mfa_secret = $1 WHERE id = $2', [encrypted, userId]);

  // Gerar QR code para o usuário escanear no Google Authenticator
  const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

  return {
    secret: secret.base32,    // mostrar uma vez para backup manual
    qrCode: qrCodeUrl,        // mostrar no frontend para escanear
  };
};

// Verificar código TOTP
const verifyTOTP = (encryptedSecret, token) => {
  const secret = decryptSecret(encryptedSecret);
  return speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 2,    // Aceita 1 step antes/depois (tolerância de clock)
  });
};

// Ativar MFA após verificação bem-sucedida
const confirmMFA = async (userId, code) => {
  const user = await getUserById(userId);
  const valid = verifyTOTP(user.mfa_secret, code);
  
  if (!valid) throw new Error('Invalid verification code');
  
  await db.query('UPDATE public.users SET mfa_enabled = true WHERE id = $1', [userId]);
  return { success: true };
};
```

### 3.5 Configuração de Cookies Seguros (Next.js)

```javascript
// pages/api/auth/login.js
const setCookies = (res, { accessToken, refreshToken }) => {
  // Refresh token: httpOnly (JS não acessa), Secure, SameSite=Strict
  res.setHeader('Set-Cookie', [
    `refresh_token=${refreshToken}; HttpOnly; Secure; SameSite=Strict; Path=/api/auth; Max-Age=${7 * 24 * 60 * 60}`,
    `access_token=${accessToken}; Secure; SameSite=Strict; Path=/; Max-Age=${15 * 60}`,
  ]);
};
```

**Tempo de implementação:** 3-4 dias  
**Dependências:** `jsonwebtoken`, `bcryptjs`, `speakeasy`, `qrcode`, `redis` (blacklist)

---

## 4. RBAC — CONTROLE DE ACESSO BASEADO EM PAPÉIS

### 4.1 Definição dos Perfis

| Perfil | Quem | Escopo |
|--------|------|--------|
| `admin_titanio` | Helber, Tiago, Tita | Full access — todos os tenants |
| `gestor_cliente` | Diretor / Gerente H2O | Acesso completo ao próprio tenant |
| `operador_cliente` | Equipe operacional H2O | Acesso limitado ao próprio tenant |

### 4.2 Matriz de Permissões Detalhada

| Ação | admin_titanio | gestor_cliente | operador_cliente |
|------|:---:|:---:|:---:|
| **TENANT** ||||
| Criar/deletar tenants | ✅ | ❌ | ❌ |
| Ver outros tenants | ✅ | ❌ | ❌ |
| Editar config do próprio tenant | ✅ | ✅ | ❌ |
| **USUÁRIOS** ||||
| Criar usuários (qualquer tenant) | ✅ | ❌ | ❌ |
| Criar usuários (próprio tenant) | ✅ | ✅ | ❌ |
| Editar próprio perfil | ✅ | ✅ | ✅ |
| Resetar senha de outros | ✅ | ✅ | ❌ |
| **CONTEÚDO** ||||
| Ver dashboard e métricas | ✅ | ✅ | ✅ |
| Criar/editar projetos | ✅ | ✅ | ✅ |
| Deletar projetos | ✅ | ✅ | ❌ |
| Aprovar conteúdo | ✅ | ✅ | ❌ |
| Publicar conteúdo | ✅ | ✅ | ❌ |
| **FINANCEIRO** ||||
| Ver relatórios financeiros | ✅ | ✅ | ❌ |
| Emitir NFS-e | ✅ | ✅ | ❌ |
| **CONFIGURAÇÕES** ||||
| Editar white-label (logo/cores) | ✅ | ✅ | ❌ |
| Configurar integrações | ✅ | ✅ | ❌ |
| **AUDIT** ||||
| Ver logs de audit | ✅ | ✅ (apenas seu tenant) | ❌ |
| Exportar logs | ✅ | ✅ | ❌ |
| **AGENTES IA** ||||
| Configurar agentes | ✅ | ❌ | ❌ |
| Interagir com agentes | ✅ | ✅ | ✅ |
| Ver logs de agentes | ✅ | ✅ | ❌ |

### 4.3 Implementação no Express (Middleware RBAC)

```javascript
// middleware/rbac.js

// Definir permissões por role
const PERMISSIONS = {
  admin_titanio: [
    'tenant:*',
    'user:*',
    'content:*',
    'financial:*',
    'settings:*',
    'audit:*',
    'agent:*',
  ],
  gestor_cliente: [
    'tenant:read',
    'tenant:update',
    'user:create',
    'user:read',
    'user:update',
    'user:delete',
    'content:*',
    'financial:read',
    'financial:create',
    'settings:update',
    'audit:read',
    'agent:interact',
    'agent:logs:read',
  ],
  operador_cliente: [
    'tenant:read',
    'user:read',
    'user:update:self',
    'content:read',
    'content:create',
    'content:update',
    'agent:interact',
  ],
};

// Verificar se o usuário tem a permissão
const hasPermission = (userRole, requiredPermission) => {
  const userPerms = PERMISSIONS[userRole] || [];
  
  return userPerms.some(perm => {
    if (perm === requiredPermission) return true;
    if (perm.endsWith(':*')) {
      const prefix = perm.replace(':*', ':');
      return requiredPermission.startsWith(prefix);
    }
    if (perm === 'tenant:*' && requiredPermission.startsWith('tenant:')) return true;
    if (perm === 'user:*' && requiredPermission.startsWith('user:')) return true;
    if (perm === 'content:*' && requiredPermission.startsWith('content:')) return true;
    return false;
  });
};

// Middleware de autorização
const authorize = (permission) => {
  return (req, res, next) => {
    const userRole = req.user?.role;
    
    if (!userRole) {
      return res.status(401).json({ error: 'Unauthenticated' });
    }

    // Admin Titanio tem acesso a qualquer tenant
    // Outros roles só acessam seu próprio tenant
    if (userRole !== 'admin_titanio') {
      const requestedTenant = req.params.tenantId || req.tenant?.id;
      if (requestedTenant && requestedTenant !== req.user.tenant_id) {
        return res.status(403).json({ error: 'Cross-tenant access denied' });
      }
    }

    if (!hasPermission(userRole, permission)) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        required: permission,
        current: userRole,
      });
    }

    next();
  };
};

// Exemplos de uso nas rotas
// router.get('/financial', authorize('financial:read'), financialController.getReports);
// router.post('/content', authorize('content:create'), contentController.create);
// router.delete('/projects/:id', authorize('content:delete'), projectController.delete);

module.exports = { authorize, hasPermission, PERMISSIONS };
```

### 4.4 RBAC no Frontend (Next.js)

```javascript
// hooks/usePermission.js
import { useAuth } from './useAuth';
import { hasPermission } from '../lib/rbac';

export const usePermission = (permission) => {
  const { user } = useAuth();
  if (!user) return false;
  return hasPermission(user.role, permission);
};

// Uso nos componentes:
// const canDeleteProject = usePermission('content:delete');
// {canDeleteProject && <DeleteButton />}

// Componente de guarda
export const PermissionGate = ({ permission, children, fallback = null }) => {
  const allowed = usePermission(permission);
  return allowed ? children : fallback;
};
```

**Tempo de implementação:** 2-3 dias

---

## 5. PRIVACIDADE — LGPD COMPLIANCE

### 5.1 Princípios LGPD Aplicados

| Princípio LGPD | Implementação |
|----------------|---------------|
| **Finalidade** | Dados coletados apenas para fins definidos no contrato |
| **Necessidade** | Coletar mínimo necessário (sem dados extras) |
| **Transparência** | Política de privacidade clara, termos de uso |
| **Segurança** | Criptografia, acesso controlado, audit trail |
| **Prevenção** | Testes de segurança, revisão de código, pen tests |
| **Não discriminação** | Dados não usados para fins discriminatórios |
| **Responsabilização** | DPO designado, registros de tratamento |

### 5.2 Medidas Técnicas de Privacidade

```javascript
// 1. CRIPTOGRAFIA DE DADOS SENSÍVEIS
// Dados como MFA secrets, tokens de API de terceiros
const crypto = require('crypto');

const ENCRYPTION_KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex'); // 32 bytes
const IV_LENGTH = 16;

const encryptSensitive = (text) => {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
};

const decryptSensitive = (text) => {
  const [ivHex, encryptedHex] = text.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const encrypted = Buffer.from(encryptedHex, 'hex');
  const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let decrypted = decipher.update(encrypted);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
};

// 2. MASCARAMENTO DE DADOS EM LOGS
const maskSensitiveData = (data) => {
  if (typeof data !== 'object') return data;
  const sensitiveKeys = ['password', 'token', 'secret', 'mfa_code', 'api_key'];
  const masked = { ...data };
  sensitiveKeys.forEach(key => {
    if (masked[key]) masked[key] = '***REDACTED***';
  });
  return masked;
};

// 3. ANONIMIZAÇÃO DE DADOS DE ANALYTICS
// Ao guardar IPs e dados de sessão, anonimizar após 30 dias
const anonymizeOldData = async () => {
  await db.query(`
    UPDATE public.refresh_tokens 
    SET ip_address = '0.0.0.0', user_agent = 'ANONYMIZED'
    WHERE created_at < NOW() - INTERVAL '30 days'
  `);
  
  await db.query(`
    UPDATE public.audit_log
    SET ip_address = '0.0.0.0'
    WHERE created_at < NOW() - INTERVAL '90 days'
  `);
};
```

### 5.3 Isolamento Garantido: Dados H2O Nunca Vazam

```sql
-- Teste de isolamento: NUNCA deve retornar dados de outro cliente
-- Executar após cada deploy como smoke test

-- Teste 1: Conectar como usuário H2O e tentar acessar dados Titanio
SET ROLE h2o_user;
SET app.tenant_id = '<H2O_TENANT_ID>';

-- Esta query deve retornar ZERO rows do schema titanio
SELECT COUNT(*) FROM titanio.content; -- ERROR: schema não acessível
SELECT COUNT(*) FROM public.users WHERE tenant_id != '<H2O_TENANT_ID>'; -- ZERO por RLS

-- Teste 2: Query maliciosa via injection deve ser bloqueada pelo RLS
-- Mesmo que SQL injection ocorra, o RLS garante que só retorna dados do tenant correto
```

### 5.4 Direitos dos Titulares (LGPD Art. 18)

```javascript
// routes/privacy.routes.js

// Exportar todos os dados de um usuário (portabilidade)
router.get('/my-data', authenticate, async (req, res) => {
  const userId = req.user.id;
  const tenantSchema = req.tenant.schema_name;
  
  const userData = {
    profile: await getUser(userId),
    content: await db.query(`SELECT * FROM ${tenantSchema}.content WHERE created_by = $1`, [userId]),
    auditLog: await db.query('SELECT * FROM public.audit_log WHERE user_id = $1', [userId]),
    loginHistory: await db.query('SELECT * FROM public.refresh_tokens WHERE user_id = $1', [userId]),
  };
  
  // Remover dados sensíveis do export
  delete userData.profile.password_hash;
  delete userData.profile.mfa_secret;
  
  res.json(userData);
});

// Direito ao esquecimento (deletar conta)
router.delete('/my-account', authenticate, authorize('user:delete:self'), async (req, res) => {
  const userId = req.user.id;
  
  // 1. Anonimizar em vez de deletar fisicamente (preservar integridade referencial)
  await db.query(`
    UPDATE public.users SET 
      email = 'deleted_${userId}@anon.titanio.app',
      name = 'Usuário Deletado',
      password_hash = null,
      mfa_secret = null,
      active = false
    WHERE id = $1
  `, [userId]);
  
  // 2. Revogar todos os tokens
  await db.query('UPDATE public.refresh_tokens SET revoked = true WHERE user_id = $1', [userId]);
  
  // 3. Registrar no audit
  await logAudit(userId, 'account_deleted', { requested_by: 'user' });
  
  res.json({ success: true, message: 'Conta deletada conforme LGPD Art. 18' });
});
```

### 5.5 Checklist LGPD para Onboarding de Cliente

Antes de ativar cada cliente, verificar:
- [ ] Contrato DPA (Data Processing Agreement) assinado
- [ ] Política de privacidade do cliente acessível
- [ ] Finalidade de cada dado coletado documentada
- [ ] Prazo de retenção definido (ex: 2 anos)
- [ ] Responsável pela proteção de dados (DPO) identificado
- [ ] Procedimento de breach notification (72h para ANPD)
- [ ] Backup criptografado configurado
- [ ] Teste de isolamento executado

**Tempo de implementação:** 2-3 dias (técnico) + 1 semana (jurídico/contratos)

---

## 6. DASHBOARD WHITE-LABEL

### 6.1 Arquitetura de Personalização

```
┌─────────────────────────────────────────────────────┐
│                  TITANIO BASE APP                    │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │            Theme Provider (React)            │    │
│  │                                              │    │
│  │  tema = loadTheme(tenant_slug)              │    │
│  │  { cores, logo, fontes, domínio }           │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  Componentes usam: useTheme() → aplica CSS vars     │
└─────────────────────────────────────────────────────┘

URL: h2o.titanio.app  → tema H2O (logo, azul/cinza)
URL: cliente2.titanio.app → tema Cliente 2 (logo, cores)
URL: titanio.app → tema padrão Titanio
```

### 6.2 Estrutura de Configuração de Tema (no Banco)

```sql
-- Na tabela public.tenants, campo config (JSONB):
UPDATE public.tenants SET config = '{
  "theme": {
    "primaryColor": "#1a3c5e",
    "secondaryColor": "#c0392b",
    "accentColor": "#3498db",
    "backgroundColor": "#f8f9fa",
    "textColor": "#2c3e50",
    "fontFamily": "Inter, sans-serif"
  },
  "branding": {
    "logoUrl": "https://cdn.titanio.app/h2o/logo.png",
    "logoSmallUrl": "https://cdn.titanio.app/h2o/logo-small.png",
    "favicon": "https://cdn.titanio.app/h2o/favicon.ico",
    "appName": "H2O Films Dashboard",
    "companyName": "H2O Films"
  },
  "domain": {
    "subdomain": "h2o",
    "customDomain": "dashboard.h2ofilms.com.br"
  },
  "features": {
    "showPoweredBy": true,
    "modules": ["analytics", "content", "catalog", "financial"]
  }
}' WHERE slug = 'h2o_films';
```

### 6.3 Implementação React (ThemeProvider)

```javascript
// contexts/ThemeContext.js
import { createContext, useContext, useEffect } from 'react';

const ThemeContext = createContext(null);

export const ThemeProvider = ({ tenantConfig, children }) => {
  const theme = tenantConfig?.theme || DEFAULT_THEME;
  const branding = tenantConfig?.branding || DEFAULT_BRANDING;

  // Aplicar CSS Custom Properties (funciona com Tailwind e CSS puro)
  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty('--color-primary', theme.primaryColor);
    root.style.setProperty('--color-secondary', theme.secondaryColor);
    root.style.setProperty('--color-accent', theme.accentColor);
    root.style.setProperty('--color-background', theme.backgroundColor);
    root.style.setProperty('--color-text', theme.textColor);
    root.style.setProperty('--font-family', theme.fontFamily);
    
    // Favicon dinâmico
    const favicon = document.querySelector("link[rel='icon']");
    if (favicon && branding.favicon) {
      favicon.href = branding.favicon;
    }
    
    // Título da página
    document.title = branding.appName;
  }, [theme, branding]);

  return (
    <ThemeContext.Provider value={{ theme, branding }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);

// Componente de Logo Dinâmico
export const TenantLogo = ({ size = 'default' }) => {
  const { branding } = useTheme();
  const src = size === 'small' ? branding.logoSmallUrl : branding.logoUrl;
  return <img src={src} alt={branding.companyName} className="tenant-logo" />;
};
```

### 6.4 Carregamento do Tema no Next.js (SSR)

```javascript
// pages/_app.js
import { ThemeProvider } from '../contexts/ThemeContext';

function MyApp({ Component, pageProps, tenantConfig }) {
  return (
    <ThemeProvider tenantConfig={tenantConfig}>
      <Component {...pageProps} />
    </ThemeProvider>
  );
}

// Buscar config do tenant no servidor (antes de renderizar)
MyApp.getInitialProps = async ({ ctx }) => {
  const host = ctx.req?.headers?.host || '';
  const subdomain = host.split('.')[0];
  
  // Buscar config do tenant (com cache Redis 5min)
  const tenantConfig = await fetchTenantConfig(subdomain);
  
  return { tenantConfig };
};

export default MyApp;
```

### 6.5 Domínio Customizado (Para planos Pro/Enterprise)

```nginx
# nginx.conf (ou configuração Cloudflare)
# Cliente quer: dashboard.h2ofilms.com.br apontar para h2o.titanio.app

# No DNS da H2O: CNAME dashboard.h2ofilms.com.br → h2o.titanio.app
# Na Cloudflare (titanio.app): adicionar domínio customizado ao túnel

# No servidor, detectar por header Host:
app.use((req, res, next) => {
  const host = req.headers.host;
  const customDomainMap = {
    'dashboard.h2ofilms.com.br': 'h2o_films',
    'analytics.outrocliente.com': 'outro_cliente',
  };
  
  if (customDomainMap[host]) {
    req.tenantSlug = customDomainMap[host];
  }
  next();
});
```

**Tempo de implementação:** 2-3 dias  
**Ferramentas:** CSS Custom Properties (nativo), `next-themes`, Cloudflare SSL Universal

---

## 7. AUDIT TRAIL — LOG COMPLETO DE AÇÕES

### 7.1 O que Registrar

Toda ação significativa no sistema deve ser registrada:

| Categoria | Eventos |
|-----------|---------|
| **Auth** | login, logout, login_failed, mfa_enabled, password_changed |
| **Conteúdo** | content_created, content_approved, content_published, content_deleted |
| **Financeiro** | invoice_created, payment_recorded |
| **Usuários** | user_created, user_updated, user_deleted, role_changed |
| **Sistema** | backup_started, backup_completed, config_changed |
| **Agentes** | agent_triggered, agent_response, automation_executed |

### 7.2 Esquema da Tabela de Audit

```sql
CREATE TABLE public.audit_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID REFERENCES public.tenants(id),
  user_id       UUID REFERENCES public.users(id),
  action        VARCHAR(100) NOT NULL,  -- 'content:published'
  resource_type VARCHAR(50),            -- 'content', 'user', 'project'
  resource_id   UUID,                   -- ID do recurso afetado
  old_value     JSONB,                  -- Estado anterior (para updates)
  new_value     JSONB,                  -- Estado novo
  ip_address    INET,
  user_agent    TEXT,
  metadata      JSONB DEFAULT '{}',    -- Dados extras
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para queries rápidas
CREATE INDEX idx_audit_tenant ON public.audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_user ON public.audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_action ON public.audit_log(action, created_at DESC);
CREATE INDEX idx_audit_resource ON public.audit_log(resource_type, resource_id);

-- Particionamento por mês (performance para logs grandes)
-- Opcional mas recomendado após 6 meses de dados
```

### 7.3 Função de Log (Reutilizável)

```javascript
// services/audit.service.js

const logAudit = async ({
  tenantId,
  userId,
  action,
  resourceType = null,
  resourceId = null,
  oldValue = null,
  newValue = null,
  req = null,  // request Express para extrair IP/UA
  metadata = {},
}) => {
  // Nunca deixar o audit falhar silenciosamente
  try {
    await db.query(`
      INSERT INTO public.audit_log 
        (tenant_id, user_id, action, resource_type, resource_id, old_value, new_value, ip_address, user_agent, metadata)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `, [
      tenantId,
      userId,
      action,
      resourceType,
      resourceId,
      oldValue ? JSON.stringify(maskSensitive(oldValue)) : null,
      newValue ? JSON.stringify(maskSensitive(newValue)) : null,
      req?.ip || req?.headers?.['x-forwarded-for'] || null,
      req?.headers?.['user-agent'] || null,
      JSON.stringify(metadata),
    ]);
  } catch (error) {
    // Log falhou? Registrar em arquivo de fallback
    console.error('[AUDIT FALLBACK]', { action, userId, error: error.message });
    // Não deixar o erro propagar para o request principal
  }
};

// Middleware automático para todas as rotas (audit passivo)
const auditMiddleware = (action, getResourceInfo = null) => {
  return async (req, res, next) => {
    const originalJson = res.json.bind(res);
    
    res.json = async (data) => {
      // Só fazer audit se a resposta foi bem-sucedida
      if (res.statusCode < 400) {
        const resourceInfo = getResourceInfo ? getResourceInfo(req, data) : {};
        await logAudit({
          tenantId: req.tenant?.id,
          userId: req.user?.id,
          action,
          req,
          ...resourceInfo,
        });
      }
      return originalJson(data);
    };
    
    next();
  };
};

// Uso:
// router.post('/content', authenticate, authorize('content:create'), 
//   auditMiddleware('content:created', (req, res) => ({ resourceType: 'content', resourceId: res.id })),
//   contentController.create
// );

module.exports = { logAudit, auditMiddleware };
```

### 7.4 Interface de Consulta de Audit (Dashboard)

```javascript
// Rota para consultar audit log (apenas gestor e admin)
router.get('/audit', authenticate, authorize('audit:read'), async (req, res) => {
  const { page = 1, limit = 50, action, userId, from, to } = req.query;
  const offset = (page - 1) * limit;
  
  // Admin vê qualquer tenant; gestor só vê o próprio
  const tenantFilter = req.user.role === 'admin_titanio'
    ? req.query.tenantId || req.tenant.id
    : req.tenant.id;
  
  const result = await db.query(`
    SELECT 
      al.*,
      u.name as user_name,
      u.email as user_email
    FROM public.audit_log al
    LEFT JOIN public.users u ON al.user_id = u.id
    WHERE al.tenant_id = $1
      AND ($2::text IS NULL OR al.action = $2)
      AND ($3::uuid IS NULL OR al.user_id = $3)
      AND ($4::timestamptz IS NULL OR al.created_at >= $4)
      AND ($5::timestamptz IS NULL OR al.created_at <= $5)
    ORDER BY al.created_at DESC
    LIMIT $6 OFFSET $7
  `, [tenantFilter, action || null, userId || null, from || null, to || null, limit, offset]);
  
  res.json({ logs: result.rows, page, limit });
});
```

**Tempo de implementação:** 2 dias

---

## 8. BACKUP POR CLIENTE

### 8.1 Estratégia de Backup Isolado

Cada cliente tem seus dados em um schema separado → backup individual é trivial:

```bash
#!/bin/bash
# scripts/backup-client.sh
# Uso: ./backup-client.sh h2o_films

SCHEMA=$1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/Volumes/TITA_039/MAC_MINI_03/backups/clients/${SCHEMA}"
BACKUP_FILE="${BACKUP_DIR}/${SCHEMA}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Iniciando backup do cliente: $SCHEMA"

# Backup do schema do cliente (dados isolados)
pg_dump \
  --schema="$SCHEMA" \
  --format=plain \
  --no-owner \
  --no-acl \
  "$DATABASE_URL" | gzip > "$BACKUP_FILE"

# Backup dos usuários do cliente (tabela compartilhada, filtrado)
pg_dump \
  --table="public.users" \
  --where="tenant_id = (SELECT id FROM public.tenants WHERE slug = '${SCHEMA}')" \
  --format=plain \
  --no-owner \
  "$DATABASE_URL" | gzip >> "$BACKUP_FILE"

# Verificar integridade
BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
echo "✅ Backup concluído: $BACKUP_FILE ($BACKUP_SIZE)"

# Reter apenas últimos 30 backups
ls -t "$BACKUP_DIR"/*.sql.gz | tail -n +31 | xargs rm -f 2>/dev/null

# Registrar no audit log
psql "$DATABASE_URL" -c "
  INSERT INTO public.audit_log (tenant_id, action, metadata) 
  SELECT id, 'backup:completed', jsonb_build_object('file', '$BACKUP_FILE', 'size', '$BACKUP_SIZE')
  FROM public.tenants WHERE slug = '$SCHEMA'
"

echo "🗑️  Backups antigos removidos. Retendo últimos 30."
```

### 8.2 Restore Individual

```bash
#!/bin/bash
# scripts/restore-client.sh
# Uso: ./restore-client.sh h2o_films 20260402_090000

SCHEMA=$1
TIMESTAMP=$2
BACKUP_FILE="/Volumes/TITA_039/MAC_MINI_03/backups/clients/${SCHEMA}/${SCHEMA}_${TIMESTAMP}.sql.gz"

echo "⚠️  ATENÇÃO: Isso vai substituir os dados atuais do cliente $SCHEMA"
echo "Arquivo: $BACKUP_FILE"
read -p "Confirmar? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Cancelado."
  exit 1
fi

# 1. Fazer backup do estado atual antes de restaurar
./backup-client.sh "$SCHEMA"

# 2. Dropar schema atual e recriar
psql "$DATABASE_URL" -c "DROP SCHEMA ${SCHEMA} CASCADE;"
psql "$DATABASE_URL" -c "CREATE SCHEMA ${SCHEMA};"

# 3. Restaurar
gunzip -c "$BACKUP_FILE" | psql "$DATABASE_URL"

echo "✅ Restore concluído para $SCHEMA"
```

### 8.3 Cron de Backup Automático

```bash
# crontab -e
# Backup diário de todos os clientes às 3h
0 3 * * * /Volumes/TITA_039/MAC_MINI_03/.openclaw/workspace/scripts/backup-all-clients.sh

# scripts/backup-all-clients.sh
#!/bin/bash
CLIENTS=$(psql "$DATABASE_URL" -t -c "SELECT slug FROM public.tenants WHERE active = true;")

for client in $CLIENTS; do
  ./backup-client.sh "$client"
done

echo "✅ Backup completo de todos os clientes: $(date)"
```

### 8.4 Backup Criptografado (Para dados sensíveis)

```bash
# Criptografar backup antes de guardar (openssl AES-256)
ENCRYPTION_PASSWORD=$(cat /Volumes/TITA_039/MAC_MINI_03/.openclaw/workspace/.secrets/backup-key)

pg_dump --schema="$SCHEMA" "$DATABASE_URL" | \
  gzip | \
  openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$ENCRYPTION_PASSWORD" \
  > "${BACKUP_FILE}.enc"

# Descriptografar para restore
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$ENCRYPTION_PASSWORD" \
  -in "${BACKUP_FILE}.enc" | \
  gunzip | \
  psql "$DATABASE_URL"
```

**Tempo de implementação:** 1 dia  
**Ferramentas:** `pg_dump` (nativo PostgreSQL), `cron` (nativo macOS/Linux), `openssl`

---

## 9. ONBOARDING AUTOMÁTICO

### 9.1 O Que o Script Faz em 1 Comando

```
./onboard-client.sh h2o_films "H2O Films" starter "admin@h2ofilms.com.br" "João Silva"

1. Cria schema PostgreSQL isolado
2. Cria tabelas do template
3. Cria registro do tenant
4. Cria usuário admin do cliente
5. Configura Cloudflare Tunnel (subdomínio)
6. Aplica tema padrão (pode personalizar depois)
7. Envia email de boas-vindas com credenciais
8. Registra no audit log
9. Cria primeiro backup (estado limpo)
```

### 9.2 Script Completo de Onboarding

```bash
#!/bin/bash
# scripts/onboard-client.sh
# Uso: ./onboard-client.sh <slug> <nome> <plano> <email_admin> <nome_admin>

set -euo pipefail  # Sair imediatamente em caso de erro

SLUG=$1           # ex: h2o_films
NAME=$2           # ex: "H2O Films"
PLAN=$3           # ex: starter
ADMIN_EMAIL=$4    # ex: admin@h2ofilms.com.br
ADMIN_NAME=$5     # ex: "João Silva"

echo "🚀 Iniciando onboarding: $NAME ($SLUG)"

# Gerar senha temporária segura
TEMP_PASSWORD=$(openssl rand -base64 16)
PASSWORD_HASH=$(node -e "const b=require('bcryptjs');console.log(b.hashSync('$TEMP_PASSWORD',12))")

# 1. Criar schema no PostgreSQL
echo "📦 Criando schema de banco de dados..."
psql "$DATABASE_URL" << SQL
-- Schema isolado para o cliente
CREATE SCHEMA IF NOT EXISTS ${SLUG};

-- Tabelas do cliente (copiar template)
CREATE TABLE ${SLUG}.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  type VARCHAR(50),
  status VARCHAR(30) DEFAULT 'active',
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ${SLUG}.content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES ${SLUG}.projects(id),
  type VARCHAR(50),
  title VARCHAR(300),
  body TEXT,
  status VARCHAR(30) DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ${SLUG}.metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES ${SLUG}.projects(id),
  metric_name VARCHAR(100) NOT NULL,
  metric_value NUMERIC,
  dimensions JSONB DEFAULT '{}',
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ${SLUG}.settings (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir configurações padrão
INSERT INTO ${SLUG}.settings (key, value) VALUES
  ('notifications', '{"email": true, "whatsapp": true}'::jsonb),
  ('posting_schedule', '{"times": ["09:00", "14:00", "19:00"]}'::jsonb);
SQL

echo "✅ Schema criado"

# 2. Criar tenant e usuário admin
echo "👤 Criando tenant e usuário admin..."
psql "$DATABASE_URL" << SQL
-- Criar tenant
INSERT INTO public.tenants (slug, name, schema_name, plan, config)
VALUES (
  '${SLUG}',
  '${NAME}',
  '${SLUG}',
  '${PLAN}',
  '{
    "theme": {
      "primaryColor": "#1a3c5e",
      "secondaryColor": "#c0392b",
      "accentColor": "#3498db",
      "backgroundColor": "#f8f9fa"
    },
    "branding": {
      "appName": "${NAME} Dashboard",
      "companyName": "${NAME}"
    },
    "domain": {
      "subdomain": "${SLUG}"
    }
  }'::jsonb
);

-- Criar usuário admin do cliente
INSERT INTO public.users (tenant_id, email, name, role, password_hash)
SELECT 
  id,
  '${ADMIN_EMAIL}',
  '${ADMIN_NAME}',
  'gestor_cliente',
  '${PASSWORD_HASH}'
FROM public.tenants WHERE slug = '${SLUG}';
SQL

echo "✅ Tenant e usuário criados"

# 3. Configurar subdomínio (se usando Cloudflare)
echo "🌐 Configurando subdomínio ${SLUG}.titanio.app..."
# cloudflared tunnel route dns titanio-dashboard "${SLUG}.titanio.app" 2>/dev/null || true
# (pode falhar se wildcard já estiver configurado)
echo "✅ Subdomínio configurado (via wildcard *.titanio.app)"

# 4. Fazer backup inicial (estado limpo)
echo "💾 Criando backup inicial..."
./backup-client.sh "$SLUG"
echo "✅ Backup inicial criado"

# 5. Enviar email de boas-vindas
echo "📧 Enviando credenciais para $ADMIN_EMAIL..."
cat << EMAIL | node -e "
const data = JSON.parse(require('fs').readFileSync('/dev/stdin', 'utf8'));
// Substituir por seu serviço de email (Nodemailer, Resend, etc.)
console.log('Email que seria enviado:', JSON.stringify(data, null, 2));
"
{
  "to": "${ADMIN_EMAIL}",
  "subject": "Bem-vindo ao ${NAME} Dashboard — Titanio",
  "body": "Olá ${ADMIN_NAME}!\n\nSua dashboard está pronta.\n\nURL: https://${SLUG}.titanio.app\nEmail: ${ADMIN_EMAIL}\nSenha temporária: ${TEMP_PASSWORD}\n\nIMPORTANTE: Troque a senha no primeiro acesso.\n\nEquipe Titanio"
}
EMAIL

echo ""
echo "═══════════════════════════════════════════"
echo "✅ ONBOARDING COMPLETO: $NAME"
echo "═══════════════════════════════════════════"
echo "  URL: https://${SLUG}.titanio.app"
echo "  Email: $ADMIN_EMAIL"
echo "  Senha temporária: $TEMP_PASSWORD"
echo "  Plano: $PLAN"
echo "═══════════════════════════════════════════"
echo ""
echo "⚠️  Compartilhe as credenciais de forma segura!"
echo "   Recomendado: 1Password, Bitwarden, ou WhatsApp direto"
```

### 9.3 Onboarding H2O Films (Exemplo Real)

```bash
# Executar AGORA para criar o ambiente H2O Films:
./scripts/onboard-client.sh \
  h2o_films \
  "H2O Films" \
  pro \
  "admin@h2ofilms.com.br" \
  "Diretor H2O"

# Resultado esperado:
# ✅ URL: https://h2o_films.titanio.app (ou h2o.titanio.app)
# ✅ Schema isolado criado
# ✅ Usuário gestor criado
# ✅ Backup inicial feito
```

**Tempo de implementação:** 1 dia  
**Tempo de execução por cliente:** ~2 minutos

---

## 10. PRICING E LIMITES POR PLANO

### 10.1 Definição dos Planos

| Funcionalidade | Starter (R$1.500) | Pro (R$3.500) | Enterprise (R$7.000+) |
|----------------|:---:|:---:|:---:|
| **Usuários** | 3 | 10 | Ilimitado |
| **Projetos ativos** | 5 | 25 | Ilimitado |
| **Conteúdo/mês** | 60 posts | 200 posts | Ilimitado |
| **Agentes IA** | 3 | 6 | 6 + customização |
| **Posts/semana** | 15 | 21 | 21+ |
| **Reels/semana** | 3 | 7 | 7+ |
| **Dashboard** | Básica | Completa | White-label |
| **Vídeo IA** | ❌ | ✅ | ✅ Avançado |
| **NFS-e** | ❌ | ✅ | ✅ |
| **Ads Management** | ❌ | ❌ | ✅ |
| **Relatórios** | Mensal | Semanal | Diário |
| **Suporte** | WhatsApp | Prioritário | Consultor dedicado |
| **API Access** | ❌ | Limitada | Full |
| **Custom Domain** | ❌ | ✅ | ✅ |
| **Retenção de dados** | 6 meses | 1 ano | 3 anos |
| **Backup frequency** | Semanal | Diário | Horário |
| **SLA uptime** | 99% | 99.5% | 99.9% |

### 10.2 Implementação de Limites no Backend

```javascript
// middleware/planLimits.js
const PLAN_LIMITS = {
  starter: {
    maxUsers: 3,
    maxProjects: 5,
    maxContentPerMonth: 60,
    maxAgents: 3,
    apiAccess: false,
    videoAI: false,
    invoiceAutomation: false,
    whiteLabel: false,
    customDomain: false,
    dataRetentionDays: 180,
    backupFrequency: 'weekly',
  },
  pro: {
    maxUsers: 10,
    maxProjects: 25,
    maxContentPerMonth: 200,
    maxAgents: 6,
    apiAccess: true,
    videoAI: true,
    invoiceAutomation: true,
    whiteLabel: false,
    customDomain: true,
    dataRetentionDays: 365,
    backupFrequency: 'daily',
  },
  enterprise: {
    maxUsers: Infinity,
    maxProjects: Infinity,
    maxContentPerMonth: Infinity,
    maxAgents: Infinity,
    apiAccess: true,
    videoAI: true,
    invoiceAutomation: true,
    whiteLabel: true,
    customDomain: true,
    dataRetentionDays: 1095,
    backupFrequency: 'hourly',
  },
};

// Verificar limite antes de criar recurso
const checkLimit = (limitName) => {
  return async (req, res, next) => {
    const plan = req.tenant.plan;
    const limits = PLAN_LIMITS[plan];
    
    if (!limits) return next(); // plano desconhecido = sem restrição (fallback seguro)
    
    const limit = limits[limitName];
    if (limit === Infinity || limit === true) return next();
    if (limit === false) {
      return res.status(403).json({
        error: 'Feature not available on current plan',
        feature: limitName,
        currentPlan: plan,
        upgradeUrl: 'https://titanio.app/pricing',
      });
    }
    
    // Para limites numéricos, contar o atual
    const countMap = {
      maxUsers: `SELECT COUNT(*) FROM public.users WHERE tenant_id = $1 AND active = true`,
      maxProjects: `SELECT COUNT(*) FROM ${req.schemaName}.projects WHERE status = 'active'`,
      maxContentPerMonth: `SELECT COUNT(*) FROM ${req.schemaName}.content WHERE created_at >= date_trunc('month', NOW())`,
    };
    
    if (countMap[limitName]) {
      const result = await db.query(countMap[limitName], [req.tenant.id]);
      const current = parseInt(result.rows[0].count);
      
      if (current >= limit) {
        return res.status(402).json({
          error: 'Plan limit reached',
          limit: { name: limitName, max: limit, current },
          upgradeUrl: 'https://titanio.app/pricing',
        });
      }
    }
    
    next();
  };
};

// Exemplos de uso:
// router.post('/users', authenticate, authorize('user:create'), checkLimit('maxUsers'), userController.create);
// router.post('/projects', authenticate, authorize('content:create'), checkLimit('maxProjects'), projectController.create);
// router.post('/video', authenticate, checkLimit('videoAI'), videoController.generate);

module.exports = { checkLimit, PLAN_LIMITS };
```

### 10.3 Widget de Uso no Dashboard

```javascript
// Componente de uso do plano (barra de progresso)
// Mostrar quantos recursos foram usados vs limite

const PlanUsageWidget = () => {
  const { usage, plan } = usePlanUsage();
  const limits = PLAN_LIMITS[plan];
  
  return (
    <div className="plan-usage">
      <h3>Uso do Plano {plan.toUpperCase()}</h3>
      
      <UsageBar 
        label="Usuários"
        current={usage.users}
        max={limits.maxUsers}
      />
      <UsageBar 
        label="Projetos"
        current={usage.projects}
        max={limits.maxProjects}
      />
      <UsageBar 
        label="Conteúdos este mês"
        current={usage.contentThisMonth}
        max={limits.maxContentPerMonth}
      />
      
      {/* Alertas quando próximo do limite */}
      {usage.users / limits.maxUsers > 0.8 && (
        <Alert type="warning">
          Você usou {Math.round(usage.users/limits.maxUsers*100)}% dos usuários. 
          <UpgradeLink />
        </Alert>
      )}
    </div>
  );
};
```

**Tempo de implementação:** 2 dias

---

## 11. DIAGRAMA COMPLETO DA ARQUITETURA

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INTERNET                                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                 ┌─────────▼──────────┐
                 │  Cloudflare         │
                 │  (DNS + SSL + WAF)  │
                 │                     │
                 │  *.titanio.app      │
                 │  h2o.titanio.app    │
                 └─────────┬──────────┘
                           │ Cloudflare Tunnel (encrypted)
                 ┌─────────▼──────────────────────────────────┐
                 │              MAC MINI (Servidor)            │
                 │                                             │
                 │  ┌──────────────────────────────────────┐  │
                 │  │  Tenant Middleware (detecta cliente)  │  │
                 │  │  → h2o.titanio.app = h2o_films        │  │
                 │  └──────────────┬───────────────────────┘  │
                 │                 │                            │
                 │  ┌──────────────▼───────────────────────┐  │
                 │  │  Auth Middleware (JWT verificado)     │  │
                 │  │  → Extrai: user_id, role, tenant_id   │  │
                 │  └──────────────┬───────────────────────┘  │
                 │                 │                            │
                 │  ┌──────────────▼───────────────────────┐  │
                 │  │  RBAC Middleware (checa permissões)   │  │
                 │  │  → Permite ou nega a ação              │  │
                 │  └──────────────┬───────────────────────┘  │
                 │                 │                            │
                 │  ┌──────────────▼───────────────────────┐  │
                 │  │  Plan Limits Middleware               │  │
                 │  │  → Verifica limites do plano          │  │
                 │  └──────────────┬───────────────────────┘  │
                 │                 │                            │
                 │  ┌──────────────▼───────────────────────┐  │
                 │  │  Express Routes (business logic)     │  │
                 │  │  + Audit Log automático               │  │
                 │  └──────────────┬───────────────────────┘  │
                 │                 │                            │
                 │  ┌──────────────▼───────────────────────┐  │
                 │  │  PostgreSQL                           │  │
                 │  │                                       │  │
                 │  │  public.tenants  ← registro clientes  │  │
                 │  │  public.users    ← todos usuários     │  │
                 │  │  public.audit_log ← todas as ações   │  │
                 │  │                                       │  │
                 │  │  titanio.*   ← dados Titanio         │  │
                 │  │  h2o_films.* ← dados H2O (isolado)  │  │
                 │  │  cliente3.*  ← dados próximo cliente │  │
                 │  └──────────────────────────────────────┘  │
                 └────────────────────────────────────────────┘

Tailscale (admin):
Helber/Tiago → SSH direto ao servidor sem Cloudflare
```

---

## 12. CRONOGRAMA DE IMPLEMENTAÇÃO

### Semana 1 — Fundação (8-10 dias)

| Dia | Tarefa | Responsável | Dependência |
|-----|--------|-------------|-------------|
| 1-2 | Multi-tenant PostgreSQL schemas + RLS | Dev backend | Nada |
| 1-2 | Tenant middleware Express | Dev backend | Nada |
| 3-4 | Auth JWT + Refresh tokens | Dev backend | Multi-tenant |
| 3-4 | MFA TOTP (speakeasy) | Dev backend | Auth |
| 5 | RBAC middleware + permissões | Dev backend | Auth |
| 5 | Plan limits middleware | Dev backend | RBAC |
| 6 | Cloudflare Tunnel setup | Tiago/Helber | Nada |
| 7 | Audit trail (tabela + middleware) | Dev backend | Multi-tenant |

### Semana 2 — Produto (5-7 dias)

| Dia | Tarefa | Responsável | Dependência |
|-----|--------|-------------|-------------|
| 8-9 | ThemeProvider Next.js + CSS vars | Dev frontend | Multi-tenant API |
| 8-9 | Tela de login com MFA | Dev frontend | Auth API |
| 10 | Widget de uso do plano | Dev frontend | Plan limits API |
| 10 | Tela de audit log | Dev frontend | Audit API |
| 11 | Scripts de backup por cliente | Tita | PostgreSQL schemas |
| 12 | Script de onboarding automático | Tita | Tudo acima |
| 13 | Testes de isolamento (smoke tests) | QA | Tudo |

### Semana 3 — H2O Films (3 dias)

| Dia | Tarefa | Responsável |
|-----|--------|-------------|
| 14 | Executar onboarding H2O Films | Tita |
| 14 | Configurar tema H2O (cores, logo) | Designer |
| 15 | Criar usuários da equipe H2O | Tita |
| 15 | Teste com equipe H2O (acesso remoto) | Tiago |
| 16 | Ajustes e go-live | Todos |

**Total: ~16 dias úteis (3-4 semanas)**

---

## 13. CHECKLIST DE SEGURANÇA PRÉ-LANÇAMENTO

Antes de dar acesso a qualquer cliente externo:

### Infraestrutura
- [ ] Cloudflare Tunnel ativo com SSL Universal
- [ ] Cloudflare WAF rules básicas ativas (OWASP ruleset)
- [ ] Rate limiting configurado (100 req/min por IP)
- [ ] Headers de segurança: HSTS, CSP, X-Frame-Options, X-Content-Type-Options

### Banco de Dados
- [ ] RLS habilitado em tabelas críticas
- [ ] Usuário PostgreSQL com permissões mínimas (não usar `postgres`)
- [ ] Conexão SSL obrigatória ao banco
- [ ] Backup inicial testado (backup + restore funcional)
- [ ] Teste de isolamento executado (cliente A não vê dados cliente B)

### Autenticação
- [ ] Senhas com bcrypt custo ≥ 12
- [ ] Access token expira em 15min
- [ ] Refresh token revogável (tabela + blacklist)
- [ ] MFA disponível (não obrigatório no início, mas disponível)
- [ ] Bloqueio de conta após 5 tentativas falhas

### Código
- [ ] Nenhuma credencial em código (usar `.env`)
- [ ] Variáveis de ambiente documentadas (`.env.example`)
- [ ] `helmet` instalado e configurado no Express
- [ ] `cors` configurado apenas para domínios permitidos
- [ ] Input validation em todas as rotas (Joi/Zod)
- [ ] SQL queries parametrizadas (nunca string concatenation)

### LGPD
- [ ] Política de privacidade publicada
- [ ] Termos de serviço publicados
- [ ] DPA assinado com o cliente
- [ ] Prazo de retenção configurado
- [ ] Endpoint `/my-data` funcionando
- [ ] Processo de breach notification documentado

---

## 14. STACK FINAL RECOMENDADA

### Backend (Express)
```
express          — servidor HTTP
pg               — PostgreSQL client
bcryptjs         — hash de senhas
jsonwebtoken     — JWT access tokens
speakeasy        — TOTP/MFA
qrcode           — QR code para MFA
helmet           — headers de segurança
cors             — controle de CORS
express-rate-limit — rate limiting
joi              — validação de input
winston          — logging estruturado
```

### Frontend (Next.js)
```
next             — framework
react            — UI
axios            — HTTP client
js-cookie        — gerenciar cookies de auth
react-toastify   — notificações
recharts         — gráficos de métricas
```

### Infraestrutura
```
cloudflared      — Cloudflare Tunnel (acesso remoto)
tailscale        — VPN equipe interna
pg_dump          — backup PostgreSQL
cron             — agendamento de backups
openssl          — criptografia de backups
redis            — cache de tenant lookup + rate limiting
```

---

## 15. EXEMPLO REAL — FLUXO H2O FILMS

```
1. Diretor da H2O abre: https://h2o.titanio.app
   → Cloudflare Tunnel roteia para Mac Mini:3000
   → Servidor detecta: host = h2o.titanio.app → tenant = h2o_films

2. Faz login com email + senha
   → bcrypt verifica hash
   → Se MFA ativo: mostra campo de código
   → Gera access_token (15min) + refresh_token (7 dias)
   → Audit: "login_success" registrado

3. Acessa o dashboard
   → JWT verificado: role = 'gestor_cliente', tenant = 'h2o_films'
   → ThemeProvider carrega: logo H2O, cores #1a3c5e
   → Todas as queries: SET search_path TO h2o_films, public;
   → Impossível ver dados da Titanio ou outro cliente

4. Tenta deletar um projeto
   → RBAC: gestor_cliente → content:delete → PERMITIDO
   → Audit: "content:deleted" registrado com old_value

5. Tenta ver dados financeiros de outro cliente
   → Tenant middleware: tenant_id do JWT ≠ tenant solicitado
   → Resposta: 403 Cross-tenant access denied
   → Audit: "unauthorized_access_attempt" registrado

6. Às 3h (cron):
   → Backup automático do schema h2o_films
   → Arquivo: /backups/clients/h2o_films/h2o_films_20260402_030000.sql.gz
   → Log: "backup:completed" no audit
```

---

*Documento criado por Squad HiClaw — Titanio Studio*  
*"Cada cliente é um mundo. A arquitetura garante que fiquem separados."*  
*Próxima revisão: após go-live H2O Films*
