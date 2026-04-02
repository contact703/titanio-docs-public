# 🚀 PLANO DE IMPLEMENTAÇÃO — Ferramentas Open-Source Titanio
**Data:** 02/04/2026  
**Autor:** Tita 🐾 (squad HiClaw)  
**Contexto:** Mac Mini M4, 16GB RAM, macOS, HD 11TB  
**Stack atual:** OpenClaw + N8n + Ollama + PostgreSQL + Redis + Dashboard + bots Python  
**RAM disponível:** ~6GB livre (usando ~10GB dos 16GB)

---

## 📊 CLASSIFICAÇÃO COMPLETA DAS FERRAMENTAS

### ✅ INSTALAR AGORA (Fase 1 — Esta Semana)

| Ferramenta | Prioridade | RAM adicional | Justificativa |
|------------|------------|--------------|---------------|
| **PM2** | 🔴 CRÍTICO | ~150MB | Process manager — elimina quedas silenciosas |
| **Uptime Kuma** | 🔴 CRÍTICO | ~120MB | Monitoramento de todos os serviços com alertas |
| **Tailscale** | 🟠 ALTO | ~30MB | Acesso remoto seguro ao Mac Mini |
| **Monit** | 🟠 ALTO | ~5MB | Watchdog externo para PM2 (layer extra) |

### 📅 INSTALAR DEPOIS (Fase 2 — Próxima Semana)

| Ferramenta | Prioridade | RAM adicional | Justificativa |
|------------|------------|--------------|---------------|
| **BullMQ** | 🟡 MÉDIO | ~0MB (lib) | Filas resilientes — usa Redis já existente |
| **PocketBase** | 🟡 MÉDIO | ~80MB | Backend para apps novos (binário único) |
| **CF Tunnel** | 🟡 MÉDIO | ~30MB | Expor serviços públicos com HTTPS |
| **pm2-logrotate** | 🟡 MÉDIO | 0MB | Rotação automática de logs |

### 🔮 INSTALAR DEPOIS (Fase 3 — Mês que Vem)

| Ferramenta | Prioridade | RAM adicional | Justificativa |
|------------|------------|--------------|---------------|
| **Coolify** | 🟢 BAIXO | ~500MB | PaaS para clientes — avaliar quando tiver VPS Linux |
| **Activepieces** | 🟢 BAIXO | ~400MB | Automações MCP — complementa N8n |
| **Netdata** | 🟢 BAIXO | ~150MB | Métricas de infra em tempo real |

### ❌ NÃO INSTALAR (com justificativa)

| Ferramenta | Motivo |
|------------|--------|
| **Dify** | Muito pesado (~2-3GB, múltiplos containers) — RAM insuficiente. Avaliar quando tiver servidor dedicado |
| **Temporal** | Overkill para o estágio atual. Usar quando tiver workflows críticos financeiros |
| **Grafana + Prometheus** | Overkill agora — Uptime Kuma + Netdata resolvem 90% do problema com menos complexidade |
| **RabbitMQ** | BullMQ com Redis existente resolve sem adicionar outro serviço |
| **OrbStack** | Não é open-source, licença comercial paga. Avaliar se Docker Desktop já está instalado |
| **SurrealDB** | BSL 1.1 — licença incerta para uso comercial |
| **AutoGen** | Pesquisa > produção. Dify é mais adequado quando RAM permitir |
| **Supervisor** | PM2 resolve melhor para nosso stack Node.js + Python |
| **Windmill** | Complexidade desnecessária agora. N8n + scripts já resolvem |
| **Agenda** | BullMQ cobre scheduling também. Agenda requer MongoDB (nova dependência) |

---

## 💾 ANÁLISE DE IMPACTO DE RAM

### Estado atual estimado (~10GB em uso)
```
Processo          RAM estimada
─────────────────────────────
Ollama (com LLM)  ~3.5 - 5.0 GB  (varia com modelo carregado)
N8n               ~400 - 600 MB
OpenClaw Gateway  ~300 - 500 MB
PostgreSQL        ~200 - 400 MB
Redis             ~100 - 150 MB
Dashboard Node    ~100 - 200 MB
Bots Python (2x)  ~200 - 400 MB
macOS Sistema     ~2.0 - 2.5 GB
──────────────────────────────
TOTAL USADO       ~9.0 - 11.0 GB
LIVRE             ~5.0 - 7.0 GB
```

### Após Fase 1 (esta semana)
```
Adições           RAM adicional
─────────────────────────────────
PM2 daemon        +150 MB
Uptime Kuma       +120 MB (Docker container)
Tailscale         +30 MB
Monit             +5 MB
──────────────────────────────────
TOTAL ADICIONADO  +305 MB
NOVO ESTADO       ~10.3 GB usados / ~5.7 GB livre ✅ SEGURO
```

### Após Fase 2 (próxima semana)
```
Adições           RAM adicional
─────────────────────────────────
BullMQ            +0 MB (biblioteca, não processo)
PocketBase        +80 MB
CF Tunnel         +30 MB
──────────────────────────────────
TOTAL ADICIONADO  +110 MB
NOVO ESTADO       ~10.5 GB usados / ~5.5 GB livre ✅ SEGURO
```

### ⚠️ Limite seguro
- **Zona verde:** < 13GB usados (RAM + swap confortável)
- **Zona amarela:** 13-14.5GB (monit alertar, reduzir carga Ollama)
- **Zona vermelha:** > 14.5GB (macOS começa a suspender processos)

**Recomendação:** Configurar PM2 com `max_memory_restart` por processo e Monit para alertar quando sistema > 88% RAM.

---

## 📅 CRONOGRAMA DE IMPLEMENTAÇÃO

### FASE 1 — ESTA SEMANA (Dias 1-5)
**Meta:** Estabilidade total dos processos atuais + visibilidade

#### Dia 1 — PM2 (2-3 horas)
- [ ] Instalar PM2 globalmente
- [ ] Criar `ecosystem.config.js` com todos os processos atuais
- [ ] Migrar N8n, OpenClaw, Dashboard, bots Python para PM2
- [ ] Configurar `max_memory_restart` por processo
- [ ] Configurar startup automático via launchd
- [ ] Instalar pm2-logrotate
- [ ] Testar restart e reboot

#### Dia 2 — Uptime Kuma (1-2 horas)
- [ ] Instalar via Docker (mais fácil de atualizar)
- [ ] Configurar monitors: N8n, OpenClaw, Dashboard, PostgreSQL, Redis
- [ ] Configurar notificações WhatsApp (via N8n webhook)
- [ ] Criar status page para a equipe

#### Dia 3 — Tailscale (30 minutos)
- [ ] Instalar app macOS
- [ ] Criar conta (gratuita para equipes pequenas)
- [ ] Adicionar Mac Mini à rede Tailscale
- [ ] Adicionar dispositivos da equipe (Eduardo, Tiago, Elber)
- [ ] Testar acesso remoto

#### Dia 4 — Monit (1-2 horas)
- [ ] Instalar via Homebrew
- [ ] Configurar monitrc para todos os serviços
- [ ] Configurar HTTP healthchecks (N8n /healthz, etc)
- [ ] Configurar alertas de RAM/CPU
- [ ] Testar: matar processo e verificar se Monit reage

#### Dia 5 — Testes e Validação
- [ ] Simular falhas: matar N8n, matar bot Python
- [ ] Verificar que PM2 reinicia corretamente
- [ ] Verificar que Uptime Kuma notifica
- [ ] Verificar que Monit age como watchdog
- [ ] Documentar configurações finais

---

### FASE 2 — PRÓXIMA SEMANA (Dias 6-10)
**Meta:** Filas resilientes + backend para apps + acesso público seguro

#### Dia 6-7 — BullMQ
- [ ] Instalar `bullmq` nos projetos que precisam de filas
- [ ] Criar worker de exemplo (envio de email assíncrono)
- [ ] Instalar Bull Board (UI para monitorar filas)
- [ ] Integrar com N8n para jobs críticos
- [ ] Configurar retry e dead letter queue

#### Dia 8 — PocketBase
- [ ] Baixar binário arm64 (nativo para M4)
- [ ] Configurar como serviço no PM2
- [ ] Criar schema inicial (Titanio 47, outros apps)
- [ ] Configurar backup automático via cron + N8n

#### Dia 9-10 — Cloudflare Tunnel
- [ ] Instalar cloudflared
- [ ] Criar tunnel para domínios dos clientes
- [ ] Expor N8n webhooks com HTTPS via CF
- [ ] Migrar endpoints públicos para usar CF Tunnel
- [ ] Documentar URLs públicas

---

### FASE 3 — MÊS QUE VEM (Semanas 3-4)
**Meta:** Observabilidade avançada + automações expandidas

#### Semana 3 — Activepieces
- [ ] Avaliar RAM disponível antes de instalar
- [ ] Instalar via Docker Compose
- [ ] Mapear quais automações migrar de N8n
- [ ] Testar conectores MCP (integração com Claude/OpenClaw)
- [ ] Decidir: Activepieces substitui ou complementa N8n?

#### Semana 4 — Netdata + Coolify
- [ ] Instalar Netdata para métricas de infra
- [ ] Avaliar se Coolify é viável no Mac (ou precisa de VPS Linux separado)
- [ ] Se VPS disponível: instalar Coolify lá, Mac Mini como node gerenciado

---

## 🔧 INSTALAR AGORA — Detalhes Completos

### 1. PM2 — CRÍTICO 🔴

**Justificativa:** Processos atuais provavelmente rodam via LaunchAgents com problemas de throttle silencioso. PM2 resolve: logs centralizados, restart inteligente com backoff, limite de RAM por processo, dashboard visual.

**Instalação:**
```bash
# Instalar PM2 globalmente (Node.js deve estar instalado)
npm install pm2@latest -g

# Instalar plugin de rotação de logs
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 50M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true

# Criar diretório de logs
sudo mkdir -p /var/log/titanio
sudo chown $(whoami):staff /var/log/titanio
```

**ecosystem.config.js** (salvar em `~/ecosystem.config.js`):
```javascript
module.exports = {
  apps: [
    {
      name: 'n8n',
      script: 'n8n',
      args: 'start',
      interpreter: 'none',
      cwd: process.env.HOME,
      env: {
        N8N_LOG_OUTPUT: 'file,console',
        N8N_LOG_FILE_LOCATION: '/var/log/titanio/n8n.log',
        N8N_LOG_LEVEL: 'info',
        NODE_ENV: 'production',
        EXECUTIONS_DATA_PRUNE: 'true',
        EXECUTIONS_DATA_MAX_AGE: '168',
      },
      max_memory_restart: '800M',
      max_restarts: 10,
      min_uptime: '30s',
      restart_delay: 5000,
      autorestart: true,
      watch: false,
      output: '/var/log/titanio/n8n-out.log',
      error: '/var/log/titanio/n8n-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
    {
      name: 'openclaw',
      script: 'openclaw',
      args: 'gateway start --foreground',
      interpreter: 'none',
      cwd: process.env.HOME,
      max_memory_restart: '600M',
      max_restarts: 5,
      min_uptime: '20s',
      restart_delay: 10000,
      autorestart: true,
      watch: false,
      output: '/var/log/titanio/openclaw-out.log',
      error: '/var/log/titanio/openclaw-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
    {
      name: 'dashboard',
      script: '/Users/contact/dashboard/server.js',
      cwd: '/Users/contact/dashboard',
      env: {
        NODE_ENV: 'production',
        PORT: '3000',
      },
      max_memory_restart: '300M',
      autorestart: true,
      restart_delay: 3000,
      output: '/var/log/titanio/dashboard-out.log',
      error: '/var/log/titanio/dashboard-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
    // Adicionar bots Python aqui conforme os paths reais
    // {
    //   name: 'bot-polymarket',
    //   script: '/Users/contact/bots/polymarket/main.py',
    //   interpreter: 'python3',
    //   max_memory_restart: '400M',
    //   autorestart: true,
    //   restart_delay: 15000,
    //   output: '/var/log/titanio/polymarket-out.log',
    //   error: '/var/log/titanio/polymarket-error.log',
    // },
  ]
};
```

**Iniciar e persistir:**
```bash
# Iniciar todos os processos
pm2 start ~/ecosystem.config.js

# Ver status
pm2 status

# CRÍTICO: salvar para sobreviver a reboots
pm2 save

# Configurar startup automático (copiar e rodar o comando que imprimir)
pm2 startup

# Verificar logs
pm2 logs --lines 50
```

**Integração com stack atual:**
- N8n usa PostgreSQL (já configurado via env vars)
- Redis já instalado — BullMQ vai usar o mesmo Redis
- Logs em `/var/log/titanio/` — centralizado para todos

---

### 2. Uptime Kuma — CRÍTICO 🔴

**Justificativa:** Visibilidade imediata de todos os serviços. Alerta no WhatsApp quando algo cai. Status page para mostrar aos clientes se necessário.

**Instalação via Docker:**
```bash
# Garantir que Docker está instalado
# Se não tiver: brew install --cask docker

# Instalar Uptime Kuma
docker run -d \
  --restart=always \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:2

# Verificar
docker ps | grep uptime-kuma
# Acessar em: http://localhost:3001
```

**Alternativa sem Docker (via npm):**
```bash
npm install -g uptime-kuma
uptime-kuma-server
# ou
npx uptime-kuma-server
```

**Configurar no PM2 (recomendado — sem Docker):**
```bash
# Instalar sem Docker
git clone https://github.com/louislam/uptime-kuma.git ~/uptime-kuma
cd ~/uptime-kuma
npm run setup

# Adicionar ao ecosystem.config.js:
# {
#   name: 'uptime-kuma',
#   script: 'server/server.js',
#   cwd: '/Users/contact/uptime-kuma',
#   max_memory_restart: '300M',
#   autorestart: true,
#   output: '/var/log/titanio/uptime-kuma-out.log',
#   error: '/var/log/titanio/uptime-kuma-error.log',
# }
```

**Monitors a criar no Uptime Kuma (após instalação):**
```
Serviço          URL/Host        Porta  Tipo
─────────────────────────────────────────────
N8n              localhost       5678   HTTP GET /healthz
OpenClaw         localhost       3001   TCP
Dashboard        localhost       3000   HTTP GET /health
PostgreSQL       localhost       5432   TCP
Redis            localhost       6379   TCP
Uptime Kuma      localhost       3001   (self-monitor)
```

**Notificações — Integrar com N8n:**
```
Em Uptime Kuma Settings > Notifications > Add:
  Tipo: Webhook
  URL: http://localhost:5678/webhook/uptime-alert
  Method: POST

Em N8n — criar workflow:
  Trigger: Webhook /uptime-alert
  → Formata mensagem
  → Envia WhatsApp via OpenClaw
```

---

### 3. Tailscale — ALTO 🟠

**Justificativa:** Acesso remoto ao Mac Mini de qualquer lugar sem abrir portas no roteador. Essencial para a equipe trabalhar de fora.

**Instalação:**
```bash
# Via Homebrew
brew install tailscale

# Ou baixar o app Mac direto: https://tailscale.com/download/mac
# Mais fácil via App (tem ícone na barra de menu)

# Via CLI (após instalar)
sudo tailscale up

# Verificar IP da rede Tailscale
tailscale ip -4
# Ex: 100.x.x.x (endereço privado da rede mesh)
```

**Configuração:**
1. Criar conta em tailscale.com (gratuito até 100 dispositivos)
2. Instalar no Mac Mini e autenticar
3. Instalar no celular/laptop de Eduardo, Tiago, Elber
4. Todos ficam na mesma rede virtual → acesso a `100.x.x.x:5678` (N8n), etc.

**Verificar acesso:**
```bash
# Listar dispositivos na rede Tailscale
tailscale status

# Pingar o Mac Mini de outro dispositivo
tailscale ping mac-mini
```

**Segurança:**
- Ativar `Access Controls` no admin para restringir quem acessa o quê
- Cada pessoa da equipe tem acesso por dispositivo autorizado

---

### 4. Monit — ALTO 🟠

**Justificativa:** Watchdog independente do PM2. Monitora se serviços REALMENTE respondem (HTTP check), não só se o processo existe. Reinicia via PM2 se necessário.

**Instalação:**
```bash
brew install monit
```

**Configuração** (`/opt/homebrew/etc/monitrc`):
```
set daemon 60          # verifica a cada 60s
set log /var/log/titanio/monit.log

set httpd port 2812 and
  use address localhost
  allow admin:titanio2026

include /opt/homebrew/etc/monit.d/*
```

**Criar configs individuais** (`/opt/homebrew/etc/monit.d/`):
```bash
mkdir -p /opt/homebrew/etc/monit.d
```

`n8n.monitrc`:
```
check process n8n matching "n8n"
  start program = "/usr/local/bin/pm2 restart n8n" as uid "contact"
  stop program = "/usr/local/bin/pm2 stop n8n" as uid "contact"
  if cpu > 90% for 5 cycles then restart
  if memory > 85% for 3 cycles then restart
  if failed port 5678 protocol http
    request "/healthz" with timeout 30 seconds
    for 3 cycles then restart
  if 5 restarts within 15 cycles then timeout
```

`system.monitrc`:
```
check system localhost
  if loadavg (5min) > 8 then alert
  if memory usage > 90% for 4 cycles then alert
  if cpu usage > 95% for 3 cycles then alert
```

**Iniciar:**
```bash
brew services start monit
monit status
```

---

## 📅 INSTALAR DEPOIS — Detalhes

### 5. BullMQ — MÉDIO 🟡

**Justificativa:** Filas resilientes para jobs assíncronos. Usa o Redis já instalado — zero overhead de infraestrutura.

**Instalação:**
```bash
# No diretório do projeto que vai usar filas
npm install bullmq

# UI para monitorar filas (Bull Board)
npm install @bull-board/express @bull-board/api
```

**Exemplo de uso:**
```javascript
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ host: 'localhost', port: 6379 });

// Criar fila
const emailQueue = new Queue('emails', { connection });

// Adicionar job
await emailQueue.add('send-welcome', {
  to: 'cliente@email.com',
  template: 'welcome'
});

// Worker que processa
const worker = new Worker('emails', async job => {
  await sendEmail(job.data);
}, { connection });
```

**Integração com N8n:** N8n pode adicionar jobs na fila via função custom ou HTTP request para um endpoint que usa BullMQ.

---

### 6. PocketBase — MÉDIO 🟡

**Justificativa:** Backend completo em 1 binário para apps novos (Titanio 47 e outros). Sem configuração de servidor complexa.

**Instalação:**
```bash
# Baixar binário arm64 para Mac M4
# Verificar última versão em: https://github.com/pocketbase/pocketbase/releases
VERSION="0.22.0"  # verificar versão mais recente
curl -L "https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/pocketbase_${VERSION}_darwin_arm64.zip" \
  -o /tmp/pocketbase.zip
unzip /tmp/pocketbase.zip -d ~/bin/
chmod +x ~/bin/pocketbase

# Testar
~/bin/pocketbase serve
# Acessar: http://localhost:8090/_/
```

**Adicionar ao PM2:**
```javascript
{
  name: 'pocketbase',
  script: '/Users/contact/bin/pocketbase',
  args: 'serve --http="localhost:8090"',
  interpreter: 'none',
  cwd: '/Users/contact/data/pocketbase',
  max_memory_restart: '200M',
  autorestart: true,
  output: '/var/log/titanio/pocketbase-out.log',
  error: '/var/log/titanio/pocketbase-error.log',
}
```

---

### 7. Cloudflare Tunnel — MÉDIO 🟡

**Justificativa:** Expor N8n webhooks e serviços dos clientes com HTTPS sem abrir portas no roteador. Free.

**Instalação:**
```bash
brew install cloudflare/cloudflare/cloudflared
cloudflared tunnel login
cloudflared tunnel create titanio-mac

# Criar config (~/.cloudflared/config.yml)
# tunnel: <ID do tunnel>
# credentials-file: /Users/contact/.cloudflared/<ID>.json
# ingress:
#   - hostname: n8n.titaniofilms.com.br
#     service: http://localhost:5678
#   - hostname: webhooks.titaniofilms.com.br
#     service: http://localhost:5678
#   - service: http_status:404

cloudflared tunnel run titanio-mac
```

---

## ⚠️ RISCOS E MITIGAÇÕES

### Risco 1 — PM2 consome RAM extra e causa instabilidade
- **Probabilidade:** Baixa
- **Impacto:** Alto
- **Mitigação:** Monitorar RAM 24h após instalação. PM2 usa ~150MB mas centraliza logs e previne crashes de outros processos que liberam mais RAM.

### Risco 2 — Migração para PM2 quebra OpenClaw temporariamente
- **Probabilidade:** Média
- **Impacto:** Alto
- **Mitigação:** 
  1. Fazer backup das configs atuais (LaunchAgents) antes
  2. Migrar um serviço por vez, não todos de uma vez
  3. Testar em horário de baixo uso (madrugada)
  4. Manter LaunchAgents como fallback por 48h

### Risco 3 — Uptime Kuma via Docker consome RAM inesperada
- **Probabilidade:** Média
- **Mitigação:** Instalar via npm diretamente (sem Docker) e gerenciar pelo PM2. Ver instruções alternativas acima.

### Risco 4 — Tailscale interfere com rede local dos serviços
- **Probabilidade:** Baixa
- **Impacto:** Médio
- **Mitigação:** Tailscale cria interface de rede separada (utun). Serviços locais continuam em `localhost`. Testar que N8n e PostgreSQL ainda se comunicam normalmente após instalar.

### Risco 5 — PM2 startup não funciona após reboot
- **Probabilidade:** Baixa
- **Mitigação:** Rodar `pm2 startup` e executar o comando que ele imprimir. Depois `pm2 save`. Testar fazendo reboot manual em horário tranquilo.

### Risco 6 — Ollama + novos serviços = OOM
- **Probabilidade:** Média (quando Ollama carrega modelos grandes)
- **Mitigação:**
  - Configurar `OLLAMA_MAX_LOADED_MODELS=1`
  - Monit alertar quando RAM > 88%
  - PM2 `max_memory_restart` para cada processo

---

## 📜 SCRIPT MASTER DE INSTALAÇÃO (Idempotente)

Salvar como `~/scripts/setup-titanio.sh`:

```bash
#!/usr/bin/env bash
# ============================================================
# TITANIO MAC MINI — Script de Setup Master
# Versão: 1.0 | Data: 02/04/2026
# IDEMPOTENTE: pode rodar múltiplas vezes sem quebrar
# Uso: bash ~/scripts/setup-titanio.sh [--fase 1|2|3]
# ============================================================

set -euo pipefail

FASE="${2:-1}"
LOG_DIR="/var/log/titanio"
SCRIPTS_DIR="$HOME/scripts"
ECOSYSTEM_FILE="$HOME/ecosystem.config.js"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_err()  { echo -e "${RED}[✗]${NC} $1"; }
log_info() { echo -e "[→] $1"; }

# ── FUNÇÕES UTILITÁRIAS ────────────────────────────────────

is_installed() {
  command -v "$1" &>/dev/null
}

is_npm_global() {
  npm list -g --depth=0 2>/dev/null | grep -q "$1"
}

is_brew_installed() {
  brew list "$1" &>/dev/null 2>&1
}

is_pm2_running() {
  pm2 list 2>/dev/null | grep -q "$1"
}

# ── FASE 1: PM2 + UPTIME KUMA + TAILSCALE + MONIT ─────────

setup_fase1() {
  echo ""
  echo "══════════════════════════════════════════"
  echo "  FASE 1 — Process Manager + Monitoring"
  echo "══════════════════════════════════════════"
  echo ""

  # 1.1 — Criar diretório de logs
  log_info "Criando diretório de logs..."
  if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
    sudo chown "$(whoami):staff" "$LOG_DIR"
    log_ok "Diretório $LOG_DIR criado"
  else
    log_ok "Diretório $LOG_DIR já existe"
  fi

  mkdir -p "$SCRIPTS_DIR"

  # 1.2 — Instalar PM2
  log_info "Verificando PM2..."
  if is_installed pm2; then
    log_ok "PM2 já instalado: $(pm2 --version)"
  else
    log_info "Instalando PM2..."
    npm install pm2@latest -g
    log_ok "PM2 instalado: $(pm2 --version)"
  fi

  # 1.3 — Instalar pm2-logrotate
  log_info "Verificando pm2-logrotate..."
  if pm2 list 2>/dev/null | grep -q "pm2-logrotate"; then
    log_ok "pm2-logrotate já instalado"
  else
    log_info "Instalando pm2-logrotate..."
    pm2 install pm2-logrotate
    pm2 set pm2-logrotate:max_size 50M
    pm2 set pm2-logrotate:retain 7
    pm2 set pm2-logrotate:compress true
    log_ok "pm2-logrotate configurado"
  fi

  # 1.4 — Criar ecosystem.config.js se não existir
  if [ ! -f "$ECOSYSTEM_FILE" ]; then
    log_info "Criando ecosystem.config.js base..."
    cat > "$ECOSYSTEM_FILE" << 'EOF'
module.exports = {
  apps: [
    {
      name: 'n8n',
      script: 'n8n',
      args: 'start',
      interpreter: 'none',
      cwd: process.env.HOME,
      env: {
        N8N_LOG_OUTPUT: 'file,console',
        N8N_LOG_FILE_LOCATION: '/var/log/titanio/n8n.log',
        N8N_LOG_LEVEL: 'info',
        NODE_ENV: 'production',
        EXECUTIONS_DATA_PRUNE: 'true',
        EXECUTIONS_DATA_MAX_AGE: '168',
      },
      max_memory_restart: '800M',
      max_restarts: 10,
      min_uptime: '30s',
      restart_delay: 5000,
      autorestart: true,
      watch: false,
      output: '/var/log/titanio/n8n-out.log',
      error: '/var/log/titanio/n8n-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
    {
      name: 'openclaw',
      script: 'openclaw',
      args: 'gateway start --foreground',
      interpreter: 'none',
      cwd: process.env.HOME,
      max_memory_restart: '600M',
      max_restarts: 5,
      min_uptime: '20s',
      restart_delay: 10000,
      autorestart: true,
      watch: false,
      output: '/var/log/titanio/openclaw-out.log',
      error: '/var/log/titanio/openclaw-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
  ]
};
EOF
    log_ok "ecosystem.config.js criado em $ECOSYSTEM_FILE"
    log_warn "EDITE o arquivo para adicionar seus processos antes de rodar pm2 start"
  else
    log_ok "ecosystem.config.js já existe em $ECOSYSTEM_FILE"
  fi

  # 1.5 — Instalar Uptime Kuma via npm
  log_info "Verificando Uptime Kuma..."
  if [ -d "$HOME/uptime-kuma" ]; then
    log_ok "Uptime Kuma já instalado em ~/uptime-kuma"
  else
    log_info "Instalando Uptime Kuma..."
    git clone https://github.com/louislam/uptime-kuma.git "$HOME/uptime-kuma"
    cd "$HOME/uptime-kuma"
    npm run setup
    cd "$HOME"
    log_ok "Uptime Kuma instalado"
    log_warn "Adicione uptime-kuma ao ecosystem.config.js manualmente"
    log_warn "script: 'server/server.js', cwd: '/Users/contact/uptime-kuma', port: 3001"
  fi

  # 1.6 — Instalar Tailscale
  log_info "Verificando Tailscale..."
  if is_installed tailscale; then
    log_ok "Tailscale já instalado"
  else
    if is_brew_installed tailscale 2>/dev/null; then
      log_ok "Tailscale já instalado via Homebrew"
    else
      log_info "Instalando Tailscale..."
      brew install tailscale
      log_ok "Tailscale instalado"
    fi
    log_warn "Execute: sudo tailscale up — para autenticar no Tailscale"
  fi

  # 1.7 — Instalar Monit
  log_info "Verificando Monit..."
  if is_installed monit; then
    log_ok "Monit já instalado: $(monit -V 2>&1 | head -1)"
  else
    log_info "Instalando Monit..."
    brew install monit
    log_ok "Monit instalado"
  fi

  # 1.8 — Criar config base do Monit
  MONIT_CONF="/opt/homebrew/etc/monitrc"
  MONIT_D="/opt/homebrew/etc/monit.d"
  mkdir -p "$MONIT_D"

  if [ ! -f "$MONIT_CONF" ] || ! grep -q "titanio" "$MONIT_CONF" 2>/dev/null; then
    log_info "Criando configuração base do Monit..."
    cat > "$MONIT_CONF" << 'EOF'
set daemon 60
set log /var/log/titanio/monit.log

set httpd port 2812 and
  use address localhost
  allow admin:titanio2026

include /opt/homebrew/etc/monit.d/*
EOF
    chmod 600 "$MONIT_CONF"

    # Config N8n
    cat > "$MONIT_D/n8n.monitrc" << 'EOF'
check process n8n matching "n8n"
  start program = "/opt/homebrew/bin/pm2 restart n8n" as uid "contact"
  stop program = "/opt/homebrew/bin/pm2 stop n8n" as uid "contact"
  if cpu > 90% for 5 cycles then restart
  if memory > 85% for 3 cycles then restart
  if failed port 5678 protocol http
    request "/healthz" with timeout 30 seconds
    for 3 cycles then restart
  if 5 restarts within 15 cycles then timeout
EOF

    # Config sistema
    cat > "$MONIT_D/system.monitrc" << 'EOF'
check system localhost
  if loadavg (5min) > 8 then alert
  if memory usage > 90% for 4 cycles then alert
  if cpu usage > 95% for 3 cycles then alert

check process postgresql matching "postgres"
  start program = "/opt/homebrew/bin/brew services start postgresql@16"
  stop program = "/opt/homebrew/bin/brew services stop postgresql@16"
  if failed host localhost port 5432 protocol pgsql
    for 3 cycles then restart

check process redis matching "redis-server"
  start program = "/opt/homebrew/bin/brew services start redis"
  stop program = "/opt/homebrew/bin/brew services stop redis"
  if failed host localhost port 6379 then restart
EOF

    log_ok "Configuração do Monit criada"
    log_warn "Inicie com: brew services start monit"
  else
    log_ok "Monit já configurado"
  fi

  echo ""
  log_ok "══ FASE 1 CONCLUÍDA ══"
  echo ""
  echo "PRÓXIMOS PASSOS MANUAIS:"
  echo "  1. Edite $ECOSYSTEM_FILE com seus processos reais"
  echo "  2. Execute: pm2 start ~/ecosystem.config.js"
  echo "  3. Execute: pm2 startup  (e rode o comando que imprimir)"
  echo "  4. Execute: pm2 save"
  echo "  5. Execute: sudo tailscale up  (para autenticar)"
  echo "  6. Execute: brew services start monit"
  echo "  7. Acesse Uptime Kuma em: http://localhost:3001"
  echo "  8. Acesse Monit em: http://localhost:2812 (admin/titanio2026)"
  echo ""
}

# ── FASE 2: BULLMQ + POCKETBASE + CF TUNNEL ───────────────

setup_fase2() {
  echo ""
  echo "══════════════════════════════════════════"
  echo "  FASE 2 — Filas + Backend + Tunnel"
  echo "══════════════════════════════════════════"
  echo ""

  # 2.1 — BullMQ (instalar como dependência nos projetos)
  log_info "BullMQ é uma biblioteca — instalar nos projetos que precisarem:"
  echo "  cd seu-projeto && npm install bullmq"
  echo "  Para Bull Board (UI): npm install @bull-board/express @bull-board/api"

  # 2.2 — PocketBase
  log_info "Verificando PocketBase..."
  if [ -f "$HOME/bin/pocketbase" ]; then
    log_ok "PocketBase já instalado: $($HOME/bin/pocketbase --version 2>/dev/null || echo 'instalado')"
  else
    log_info "Instalando PocketBase..."
    mkdir -p "$HOME/bin"
    # Buscar versão mais recente
    PB_VERSION=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    if [ -z "$PB_VERSION" ]; then
      PB_VERSION="0.22.0"  # fallback
      log_warn "Não conseguiu buscar versão mais recente. Usando $PB_VERSION"
    fi
    curl -L "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_darwin_arm64.zip" \
      -o /tmp/pocketbase.zip
    unzip -o /tmp/pocketbase.zip pocketbase -d "$HOME/bin/"
    chmod +x "$HOME/bin/pocketbase"
    rm /tmp/pocketbase.zip
    mkdir -p "$HOME/data/pocketbase"
    log_ok "PocketBase $PB_VERSION instalado em ~/bin/pocketbase"
    log_warn "Adicione ao ecosystem.config.js e execute: pm2 reload ecosystem.config.js"
  fi

  # 2.3 — Cloudflare Tunnel
  log_info "Verificando cloudflared..."
  if is_installed cloudflared; then
    log_ok "cloudflared já instalado: $(cloudflared --version 2>&1 | head -1)"
  else
    log_info "Instalando cloudflared..."
    brew install cloudflare/cloudflare/cloudflared
    log_ok "cloudflared instalado"
    log_warn "Execute: cloudflared tunnel login  (para autenticar)"
    log_warn "Execute: cloudflared tunnel create titanio-mac  (para criar o tunnel)"
  fi

  echo ""
  log_ok "══ FASE 2 CONCLUÍDA ══"
  echo ""
  echo "PRÓXIMOS PASSOS MANUAIS:"
  echo "  1. Adicione PocketBase ao ecosystem.config.js"
  echo "  2. Execute: cloudflared tunnel login && cloudflared tunnel create titanio-mac"
  echo "  3. Configure ~/.cloudflared/config.yml com seus domínios"
  echo ""
}

# ── VERIFICAÇÃO DO SISTEMA ─────────────────────────────────

verificar_sistema() {
  echo ""
  echo "══════════════════════════════════════════"
  echo "  STATUS DO SISTEMA"
  echo "══════════════════════════════════════════"
  echo ""

  # RAM
  TOTAL_RAM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  log_info "RAM Total: ${TOTAL_RAM}GB"

  # Serviços PM2
  if is_installed pm2; then
    log_info "PM2 processos:"
    pm2 status 2>/dev/null || log_warn "PM2 sem processos ativos"
  else
    log_warn "PM2: não instalado"
  fi

  # Portas abertas relevantes
  for port_service in "5678:N8n" "3001:Uptime-Kuma/OpenClaw" "3000:Dashboard" "5432:PostgreSQL" "6379:Redis" "8090:PocketBase" "2812:Monit"; do
    PORT="${port_service%%:*}"
    NAME="${port_service##*:}"
    if nc -z localhost "$PORT" 2>/dev/null; then
      log_ok "Porta $PORT ($NAME): ABERTA"
    else
      log_warn "Porta $PORT ($NAME): fechada"
    fi
  done

  # Tailscale
  if is_installed tailscale; then
    TAILSCALE_STATUS=$(tailscale status --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('conectado' if d.get('BackendState')=='Running' else 'desconectado')" 2>/dev/null || echo "verificar")
    log_info "Tailscale: $TAILSCALE_STATUS"
  else
    log_warn "Tailscale: não instalado"
  fi
}

# ── MAIN ───────────────────────────────────────────────────

case "${1:-fase1}" in
  "--fase")
    case "$FASE" in
      "1") setup_fase1 ;;
      "2") setup_fase1; setup_fase2 ;;
      "3") setup_fase1; setup_fase2; log_warn "Fase 3 requer configuração manual (Activepieces, Netdata)" ;;
      *) log_err "Fase inválida: $FASE. Use 1, 2 ou 3"; exit 1 ;;
    esac
    ;;
  "--status")
    verificar_sistema
    ;;
  "--help" | "-h")
    echo "Uso: bash setup-titanio.sh [--fase 1|2|3] [--status]"
    echo "  --fase 1   Instala PM2 + Uptime Kuma + Tailscale + Monit (padrão)"
    echo "  --fase 2   Instala tudo da fase 1 + BullMQ + PocketBase + CF Tunnel"
    echo "  --fase 3   Instala fases 1+2 (fase 3 é manual)"
    echo "  --status   Verifica estado atual do sistema"
    ;;
  *)
    # Default: rodar fase 1
    setup_fase1
    ;;
esac

echo ""
echo "Script finalizado. Veja os logs em /var/log/titanio/"
```

**Para usar:**
```bash
# Dar permissão e rodar
chmod +x ~/scripts/setup-titanio.sh

# Fase 1 (esta semana)
bash ~/scripts/setup-titanio.sh --fase 1

# Verificar status após instalação
bash ~/scripts/setup-titanio.sh --status

# Fase 2 (próxima semana)
bash ~/scripts/setup-titanio.sh --fase 2
```

---

## 🎯 RESUMO EXECUTIVO

### O que fazer HOJE
1. **Rodar** `bash ~/scripts/setup-titanio.sh --fase 1`
2. **Editar** `~/ecosystem.config.js` com os paths reais dos seus processos
3. **Executar** `pm2 start ~/ecosystem.config.js && pm2 save && pm2 startup`
4. **Acessar** Uptime Kuma em `http://localhost:3001` e criar os monitors
5. **Autenticar** Tailscale: `sudo tailscale up`

### Resultado esperado em 5 dias
- ✅ Todos os processos gerenciados pelo PM2 com auto-restart inteligente
- ✅ Dashboard de uptime mostrando status de todos os serviços
- ✅ Alertas no WhatsApp quando algo cair
- ✅ Acesso remoto seguro para toda a equipe
- ✅ Logs centralizados com rotação automática
- ✅ RAM monitorada e alertas automáticos
- ✅ Watchdog externo (Monit) verificando saúde HTTP real

### Não instalar agora (e por quê)
- **Dify:** Precisa ~2-3GB — não cabe nos 6GB livres. Aguardar quando Ollama não estiver rodando modelo grande ou quando tiver mais RAM.
- **Coolify:** Precisa de Linux. Usar no futuro quando tiver VPS Linux separado.
- **Grafana/Prometheus:** Uptime Kuma resolve 90% por menos complexidade. Grafana quando precisar de dashboards de negócio.

---

*Plano criado por Tita 🐾 (squad HiClaw) — 02/04/2026*  
*Baseado em PESQUISA-FERRAMENTAS-OPENSOURCE.md + PESQUISA-AUTOMACAO-24-7.md*
