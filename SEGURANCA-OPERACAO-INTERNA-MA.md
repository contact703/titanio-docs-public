# 🔒 SEGURANÇA — Operação Interna (Documento Confidencial Titanio)
## Sistema Monteiro Aranha operado a partir da infraestrutura Titanio

**Classificação:** INTERNO TITANIO — NÃO COMPARTILHAR COM CLIENTE  
**Data:** 02/04/2026

---

## 1. MODELO DE OPERAÇÃO

O sistema da Monteiro Aranha roda na infraestrutura da Titanio (Mac Mini M4 + futuro servidor dedicado). O OpenClaw é o coração — gerencia agentes, sessões, memória e execução.

```
┌──────────────────────────────────────────────┐
│           TITANIO (NOSSA INFRA)              │
│                                              │
│  ┌────────────┐  ┌─────────────────────┐     │
│  │  OpenClaw   │  │  Dashboard MA       │     │
│  │  Gateway    │  │  (instância isolada)│     │
│  └─────┬──────┘  └──────────┬──────────┘     │
│        │                     │                │
│  ┌─────┴──────┐  ┌──────────┴──────────┐     │
│  │ Especialistas│  │ PostgreSQL MA       │     │
│  │ digitais MA  │  │ (schema isolado)    │     │
│  └─────┬──────┘  └──────────┬──────────┘     │
│        │                     │                │
│  ┌─────┴─────────────────────┴──────────┐     │
│  │    Tunnel seguro (Tailscale/CF)       │     │
│  └─────────────────┬────────────────────┘     │
╚════════════════════╪═════════════════════════╝
                     │ Internet (TLS 1.3)
╔════════════════════╪═════════════════════════╗
│     MONTEIRO ARANHA (ACESSO REMOTO)          │
│                                              │
│  ┌──────────┐  ┌──────────────────────┐      │
│  │ Navegador │  │ WhatsApp Acionistas │      │
│  │ (Dashboard)│  │ (canal dedicado)    │      │
│  └──────────┘  └──────────────────────┘      │
│                                              │
│  Equipe MA acessa via browser/app            │
│  Acionistas acessam via WhatsApp             │
╚══════════════════════════════════════════════╝
```

---

## 2. ISOLAMENTO DE DADOS — COMO PROTEGER RODANDO DAQUI

### 2.1 Schema Isolado no PostgreSQL

Mesmo rodando no nosso server, os dados da MA ficam em schema separado com Row-Level Security:

```sql
-- Schema exclusivo Monteiro Aranha
CREATE SCHEMA monteiro_aranha;

-- Tabelas dentro do schema MA
CREATE TABLE monteiro_aranha.documentos (...);
CREATE TABLE monteiro_aranha.contratos (...);
CREATE TABLE monteiro_aranha.acionistas (...);
CREATE TABLE monteiro_aranha.audit_log (...);

-- RLS: garante que queries da app SÓ veem dados do tenant correto
ALTER TABLE monteiro_aranha.documentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON monteiro_aranha.documentos
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Usuário dedicado com acesso APENAS ao schema MA
CREATE USER ma_app WITH PASSWORD '...';
GRANT USAGE ON SCHEMA monteiro_aranha TO ma_app;
GRANT ALL ON ALL TABLES IN SCHEMA monteiro_aranha TO ma_app;
-- NENHUM acesso a outros schemas
```

### 2.2 Instância OpenClaw Isolada

Não misturar com nosso agente principal. A MA terá:

```yaml
# openclaw-ma.yaml — instância dedicada
gateway:
  port: 18790  # porta separada do nosso gateway (18789)
  bind: 0.0.0.0

agents:
  main:
    name: "Titanio MA"
    model: anthropic/claude-sonnet-4-6  # modelo padrão
    workspace: /data/monteiro-aranha/workspace
    
  specialists:
    - id: ri-specialist
      name: "Especialista RI"
      model: anthropic/claude-sonnet-4-6
    - id: juridico-specialist
      name: "Especialista Jurídico"
      model: anthropic/claude-sonnet-4-6
    - id: financeiro-specialist  
      name: "Especialista Financeiro"
      model: anthropic/claude-sonnet-4-6

# Dados NUNCA se misturam com o workspace Titanio
data_dir: /data/monteiro-aranha/
memory_dir: /data/monteiro-aranha/memory/
```

### 2.3 Volumes de Dados Separados

```
/data/
├── titanio/              ← NOSSOS dados (workspace atual)
│   ├── workspace/
│   ├── memory/
│   └── specialists/
│
├── monteiro-aranha/      ← DADOS MA (totalmente isolado)
│   ├── workspace/
│   ├── memory/
│   ├── specialists/
│   ├── documents/
│   ├── contracts/
│   ├── backups/
│   └── audit-logs/
│
└── [futuro-cliente]/     ← Cada cliente tem seu volume
```

**Criptografia do volume MA:** AES-256 com chave dedicada. Se o disco for roubado, dados inacessíveis.

---

## 3. ACESSO REMOTO SEGURO

### 3.1 Opção A: Tailscale (recomendado)

```bash
# No nosso Mac Mini
tailscale up --hostname=titanio-server

# Equipamentos da MA se conectam ao Tailscale
# Acesso direto e seguro sem abrir portas

# Dashboard MA acessível em:
# https://titanio-server:3100 (via Tailscale)
```

Prós: zero config de firewall, criptografia ponta-a-ponta, ACLs por usuário
Contras: cada dispositivo MA precisa ter Tailscale instalado

### 3.2 Opção B: Cloudflare Tunnel (mais transparente para o cliente)

```bash
# Criar tunnel dedicado para MA
cloudflared tunnel create monteiro-aranha
cloudflared tunnel route dns monteiro-aranha ma.titanio.app

# Config: ~/.cloudflared/config-ma.yml
tunnel: <tunnel-id>
ingress:
  - hostname: ma.titanio.app
    service: http://localhost:3100  # Dashboard MA
  - hostname: api-ma.titanio.app
    service: http://localhost:18790  # Gateway MA
  - service: http_status:404
```

Prós: cliente acessa via browser normal (HTTPS), sem instalar nada
Contras: passa pela Cloudflare (mas com TLS end-to-end)

### 3.3 Recomendação

**Cloudflare Tunnel para a Dashboard** (acesso fácil para equipe MA) +
**Tailscale para administração** (nosso acesso técnico seguro)

---

## 4. MODO CONFIDENCIAL — IMPLEMENTAÇÃO TÉCNICA

O modo confidencial é o diferencial. Aqui como funciona de verdade:

### 4.1 Sessão Efêmera

```typescript
// Quando usuário ativa modo confidencial:
class ConfidentialSession {
  private context: Map<string, any> = new Map();
  private readonly sessionId: string;
  private readonly startedAt: Date;
  
  constructor(userId: string, specialistId: string) {
    this.sessionId = crypto.randomUUID();
    this.startedAt = new Date();
    
    // Log APENAS metadados (sem conteúdo)
    auditLog.append({
      event: 'confidential_session_started',
      sessionId: this.sessionId,
      userId,
      specialistId,
      timestamp: this.startedAt,
      // NÃO registrar: task, prompt, conteúdo, resultado
    });
  }
  
  async execute(task: string): Promise<string> {
    // Processar com IA normalmente
    const result = await specialist.process(task, {
      saveLessons: false,       // NÃO salvar lições
      saveMemory: false,        // NÃO salvar na memória
      saveContext: false,        // NÃO salvar contexto
      logContent: false,        // NÃO logar conteúdo
    });
    
    return result;
    // Resultado entregue ao usuário e descartado do servidor
  }
  
  destroy(): void {
    // Limpar TUDO da memória
    this.context.clear();
    
    auditLog.append({
      event: 'confidential_session_ended',
      sessionId: this.sessionId,
      duration: Date.now() - this.startedAt.getTime(),
      // NÃO registrar o que foi feito
    });
    
    // Garbage collect forçado
    if (global.gc) global.gc();
  }
}
```

### 4.2 Flags no SquadManager

```typescript
// No assignTask do SquadManager, checar modo:
async assignTask(id: string, task: string, options?: {
  mode: 'normal' | 'restricted' | 'confidential'
}) {
  if (options?.mode === 'confidential') {
    // Criar sessão efêmera
    const session = new ConfidentialSession(userId, id);
    const result = await session.execute(task);
    session.destroy();
    return { result, saved: false, learned: false };
  }
  
  if (options?.mode === 'restricted') {
    // Executar normalmente mas salvar só estrutura
    const result = await this.executeTask(id, task);
    await this.saveStructureOnly(id, task, result);
    return { result, saved: true, learned: 'structure_only' };
  }
  
  // Modo normal — salva tudo
  return await this.executeAndLearn(id, task);
}
```

---

## 5. SEPARAÇÃO DO NOSSO USO vs USO DA MA

### 5.1 API Keys Separadas

```env
# .env da instância MA
ANTHROPIC_API_KEY_MA=sk-ant-...  # Key DEDICADA para MA
# OU rotear pelo nosso gateway com billing separado

# NUNCA usar a mesma key do nosso agente principal
# Isso garante:
# 1. Rate limit separado
# 2. Billing separado (saber quanto a MA gasta)
# 3. Se nossa key cair, MA não é afetada
```

### 5.2 Processos Separados

```
PM2 — Nossos processos:
├── openclaw-gateway (porta 18789)
├── titanio-dashboard (porta 4444/3000)
├── n8n, bots, watchdogs...

PM2 — Processos MA:
├── openclaw-ma-gateway (porta 18790)
├── ma-dashboard (porta 3100)
├── ma-whatsapp-gateway (porta 3200)
├── ma-backup-service
```

Totalmente isolados. Se um crashar, o outro continua.

### 5.3 Backup Separado

```bash
# backup-ma.sh — roda independente dos nossos backups
#!/bin/bash
BACKUP_DIR="/data/monteiro-aranha/backups"
DATE=$(date +%Y%m%d_%H%M)

# Dump do schema MA (não dos nossos dados)
pg_dump -n monteiro_aranha > "$BACKUP_DIR/db_$DATE.sql"

# Workspace e memória MA
tar czf "$BACKUP_DIR/workspace_$DATE.tar.gz" /data/monteiro-aranha/workspace/

# Criptografar
openssl enc -aes-256-cbc -salt -in "$BACKUP_DIR/db_$DATE.sql" \
  -out "$BACKUP_DIR/db_$DATE.sql.enc" -pass file:/data/monteiro-aranha/.backup-key

# Limpar não-criptografados
rm "$BACKUP_DIR/db_$DATE.sql"

# Retenção: 30 backups incrementais, 90 full
find "$BACKUP_DIR" -name "*.enc" -mtime +90 -delete
```

---

## 6. RISCOS E MITIGAÇÕES

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Nosso Mac Mini cai | Média | PM2 auto-restart + Uptime Kuma alerta em 30s |
| RAM insuficiente (16GB) | Alta | Instância MA leve (Haiku pra tasks simples) + servidor dedicado futuro |
| Equipe MA acessa dados Titanio | Baixa | Schema isolation + RLS + user dedicado |
| Nós acessamos dados MA indevidamente | Baixa | Audit trail + policy interna + contrato |
| Key Anthropic esgota | Média | Keys separadas + fallback Ollama local |
| Internet cai | Média | Ollama local como fallback para tasks básicas |
| Cliente pede auditoria | Certa | Logs prontos, audit trail imutável |
| Contrato encerra | Possível | Export automatizado + certificado de destruição |

---

## 7. ROADMAP TÉCNICO

### Fase 1 — Setup (Semana 1-2)
- [ ] Criar volume /data/monteiro-aranha/ com criptografia
- [ ] Instância OpenClaw dedicada (porta 18790)
- [ ] Schema PostgreSQL isolado com RLS
- [ ] Cloudflare Tunnel para Dashboard MA
- [ ] 6 especialistas digitais configurados
- [ ] API key Anthropic separada ou billing via gateway

### Fase 2 — Canal WhatsApp (Semana 3)
- [ ] Número WhatsApp Business dedicado para MA
- [ ] Gateway de mensagens com sanitização
- [ ] Sistema de aprovação humana (fila no Dashboard)
- [ ] Cadastro de acionistas

### Fase 3 — Modos de aprendizado (Semana 4)
- [ ] Implementar ConfidentialSession
- [ ] UI de seleção de modo (normal/restrito/confidencial)
- [ ] Audit trail com hash chain
- [ ] Testes de penetração básicos

### Fase 4 — Imersão (Mês 2)
- [ ] Pessoa Titanio na MA mapeando processos
- [ ] Treinamento dos especialistas com dados reais
- [ ] Ajustes finos
- [ ] Go-live

---

## 8. CUSTO INTERNO ESTIMADO (PRA NÓS)

| Item | Custo mensal |
|------|-------------|
| Tokens IA (Sonnet + Haiku) | ~R$ 800-2.000 |
| Infra (proporcional Mac Mini ou VPS) | ~R$ 200-500 |
| Cloudflare Tunnel | Grátis |
| Tailscale | Grátis (até 100 devices) |
| Backup storage | ~R$ 50 |
| **Total interno** | **R$ 1.050-2.550** |
| **Cobramos** | **R$ 12.000/mês** |
| **Margem** | **79-91%** |

Se volume de uso for alto, migrar para servidor dedicado (~R$ 500/mês VPS com 32GB RAM).

---

## 9. HARDWARE FUTURO (QUANDO ESCALAR)

Se MA + H2O + outros clientes, o Mac Mini não aguenta. Plano:

**Curto prazo (1-3 clientes):** Mac Mini M4 16GB (atual) — funciona
**Médio prazo (3-5 clientes):** VPS dedicado 32GB RAM (~R$ 500/mês)
**Longo prazo (5+ clientes):** Servidor próprio ou cluster de Mac Minis

---

*Documento interno Titanio — NÃO compartilhar com cliente*
*02/04/2026*
