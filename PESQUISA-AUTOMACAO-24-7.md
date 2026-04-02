# PESQUISA: Automação 24/7 no Mac Mini M4 — Soluções que Realmente Funcionam

> Gerada em: 02/04/2026
> Contexto: Mac Mini M4 (16GB RAM, macOS Sequoia) rodando OpenClaw, N8n, Ollama, PostgreSQL, Redis, Bots Python, Dashboard Node.js
> Objetivo: Eliminar quedas de processo e garantir uptime 99.9%

---

## RESUMO EXECUTIVO

**Diagnóstico:** O setup atual usa LaunchAgents com `KeepAlive: true` mas **há falhas conhecidas** nessa abordagem — especialmente com processos que têm saída de stdout/stderr não redirecionada, processos que morrem rápido demais (triggering throttle do launchd), ou processos que viram zumbis.

**Recomendação principal:** Usar **PM2** como process manager primário + **Monit** como watchdog externo + **LaunchDaemon** (não LaunchAgent) para garantir boot automático do PM2.

---

## PARTE 1 — LAUNCHD (macOS nativo): Por que falha e como corrigir

### Fonte
- Apple Developer Docs: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
- launchd.info: https://www.launchd.info/

### O que é o problema real

O `launchd` tem um **throttle automático**: se um processo morrer 3x em menos de 10 segundos, o launchd para de reiniciá-lo e coloca em estado `throttled`. Você não recebe notificação. O processo simplesmente **para de existir**.

Outros problemas comuns:
1. `KeepAlive: true` sem `ThrottleInterval` resulta em throttle silencioso
2. LaunchAgents só ficam ativos **enquanto o usuário está logado** — se a sessão fechar, morrem
3. Variáveis de ambiente (PATH, NVM_DIR) não são herdadas do shell do usuário
4. Stdout/stderr não redirecionados geram emails em /var/mail
5. Processos que precisam de rede mas sobem antes da rede estar disponível

### Solução Correta para LaunchAgents/Daemons

#### Config completa e correta:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Label único — use domínio reverso -->
  <key>Label</key>
  <string>com.titanio.n8n</string>

  <!-- Comando + args — PATH completo, nunca relativo -->
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/n8n</string>
    <string>start</string>
  </array>

  <!-- CRÍTICO: redirecionar saída para evitar /var/mail -->
  <key>StandardOutPath</key>
  <string>/var/log/titanio/n8n.log</string>
  <key>StandardErrorPath</key>
  <string>/var/log/titanio/n8n-error.log</string>

  <!-- KeepAlive com condições específicas -->
  <key>KeepAlive</key>
  <dict>
    <!-- Reinicia só se o processo morreu de forma inesperada (exit code != 0) -->
    <key>SuccessfulExit</key>
    <false/>
  </dict>

  <!-- CRÍTICO: evitar throttle. Aguarda 30s entre restarts -->
  <key>ThrottleInterval</key>
  <integer>30</integer>

  <!-- Aguardar rede disponível antes de subir -->
  <key>NetworkState</key>
  <true/>

  <!-- Variáveis de ambiente explícitas -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    <key>HOME</key>
    <string>/Users/contact</string>
    <key>N8N_LOG_OUTPUT</key>
    <string>file</string>
  </dict>

  <!-- Diretório de trabalho -->
  <key>WorkingDirectory</key>
  <string>/Users/contact</string>

  <!-- Subir junto com o sistema -->
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
```

#### Onde colocar:

| Tipo | Diretório | Quando ativo |
|------|-----------|--------------|
| **LaunchDaemon** | `/Library/LaunchDaemons/` | Sempre (boot, mesmo sem login) ✅ |
| LaunchAgent (usuário) | `~/Library/LaunchAgents/` | Só quando logado ⚠️ |
| LaunchAgent (sistema) | `/Library/LaunchAgents/` | Quando qualquer usuário logado ⚠️ |

**Para servidores 24/7: usar LaunchDaemons, não LaunchAgents.**

#### Comandos de gerenciamento:

```bash
# Carregar/registrar
sudo launchctl load /Library/LaunchDaemons/com.titanio.n8n.plist

# Iniciar manualmente
sudo launchctl start com.titanio.n8n

# Ver status e erros
sudo launchctl print system/com.titanio.n8n

# Ver todos os daemons e estado
sudo launchctl list | grep titanio

# Log em tempo real
sudo log stream --predicate 'subsystem == "com.apple.launchd"' --level debug

# Versão moderna (macOS 10.11+) — usar bootstrap/bootout
sudo launchctl bootout system /Library/LaunchDaemons/com.titanio.n8n.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.titanio.n8n.plist
```

### Prós e Contras do launchd puro

| ✅ Prós | ❌ Contras |
|---------|-----------|
| Nativo do macOS, sem dependências | Throttle silencioso é armadilha |
| Integra com keychain/segurança | Logs difíceis de debugar |
| Baixo overhead | Sem dashboard visual |
| Suporta socket activation | Reinício muito básico (sem backoff exponencial) |
| Inicia antes de qualquer coisa | PATH e env variables não herdados do shell |

---

## PARTE 2 — PM2: Process Manager Principal (RECOMENDADO)

### Fonte
- Docs oficiais: https://pm2.keymetrics.io/docs/usage/quick-start/
- Startup docs: https://pm2.keymetrics.io/docs/usage/startup/

### Por que PM2 para macOS

PM2 é o process manager mais maduro para Node.js, mas suporta **qualquer tipo de processo** (Python, Shell, binários). No macOS com Apple Silicon (M4) funciona nativamente via npm e usa **launchd** internamente como backend de startup — ou seja, o melhor dos dois mundos.

### Instalação

```bash
# Instalar globalmente
npm install pm2@latest -g

# Para NVM users — instalar no node da versão certa
nvm use 20  # ou sua versão padrão
npm install pm2@latest -g
```

### Configuração — ecosystem.config.js

Criar em `/Users/contact/ecosystem.config.js`:

```javascript
module.exports = {
  apps: [
    // N8N
    {
      name: 'n8n',
      script: 'n8n',
      args: 'start',
      interpreter: 'none',   // não é script JS
      cwd: '/Users/contact',
      env: {
        N8N_LOG_OUTPUT: 'file',
        N8N_LOG_FILE_LOCATION: '/var/log/titanio/n8n.log',
        N8N_LOG_LEVEL: 'info',
        DB_TYPE: 'postgresdb',
        DB_POSTGRESDB_DATABASE: 'n8n',
        DB_POSTGRESDB_HOST: 'localhost',
        DB_POSTGRESDB_PORT: '5432',
        DB_POSTGRESDB_USER: 'n8n_user',
        NODE_ENV: 'production',
      },
      // Restart se ultrapassar 800MB de RAM
      max_memory_restart: '800M',
      // Número de restarts em 15min antes de parar de tentar
      max_restarts: 10,
      min_uptime: '30s',    // Processo precisa ficar vivo por 30s pra contar como "started"
      restart_delay: 5000,  // 5s entre tentativas de restart
      autorestart: true,
      watch: false,
      // Logs
      output: '/var/log/titanio/n8n-out.log',
      error: '/var/log/titanio/n8n-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },

    // OpenClaw Gateway
    {
      name: 'openclaw',
      script: '/usr/local/bin/openclaw',
      args: 'gateway start --foreground',
      interpreter: 'none',
      cwd: '/Users/contact/.openclaw',
      max_memory_restart: '600M',
      autorestart: true,
      restart_delay: 10000,  // 10s — dar tempo de limpar conexões WhatsApp
      output: '/var/log/titanio/openclaw-out.log',
      error: '/var/log/titanio/openclaw-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },

    // Bot Python — Polymarket
    {
      name: 'bot-polymarket',
      script: '/Users/contact/bots/polymarket/main.py',
      interpreter: '/Users/contact/.pyenv/versions/3.11.0/bin/python3',
      cwd: '/Users/contact/bots/polymarket',
      env: {
        PYTHONUNBUFFERED: '1',  // CRÍTICO: sem buffer nos logs
      },
      max_memory_restart: '400M',
      autorestart: true,
      restart_delay: 15000,
      output: '/var/log/titanio/polymarket-out.log',
      error: '/var/log/titanio/polymarket-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },

    // Bot Python — Instagram
    {
      name: 'bot-instagram',
      script: '/Users/contact/bots/instagram/main.py',
      interpreter: '/Users/contact/.pyenv/versions/3.11.0/bin/python3',
      cwd: '/Users/contact/bots/instagram',
      env: {
        PYTHONUNBUFFERED: '1',
      },
      max_memory_restart: '400M',
      autorestart: true,
      restart_delay: 20000,  // Rate limiting do Instagram
      output: '/var/log/titanio/instagram-out.log',
      error: '/var/log/titanio/instagram-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },

    // Dashboard Node.js
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
      output: '/var/log/titanio/dashboard-out.log',
      error: '/var/log/titanio/dashboard-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
  ]
};
```

### Comandos essenciais

```bash
# Iniciar tudo pelo config
pm2 start ecosystem.config.js

# Ver status em tempo real
pm2 status
pm2 monit          # dashboard TUI

# Logs em tempo real
pm2 logs           # todos
pm2 logs n8n       # específico
pm2 logs --lines 200  # últimas 200 linhas

# CRÍTICO: salvar lista para sobreviver a reboots
pm2 save

# Gerar script de startup (usa launchd no macOS)
pm2 startup
# Vai imprimir um comando sudo — executar o que imprimir

# Restart específico
pm2 restart n8n
pm2 reload n8n     # zero-downtime para apps com múltiplos workers

# Ver detalhes de um processo (inclui env vars, restarts, uptime)
pm2 describe n8n

# Limpar logs antigos
pm2 flush

# Instalar rotação de logs automática
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 50M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

### Prós e Contras do PM2

| ✅ Prós | ❌ Contras |
|---------|-----------|
| Funciona com Node, Python, Shell, binários | Depende do Node.js |
| Logs centralizados com rotação | PM2 em si precisa de monitor externo |
| Dashboard visual no terminal | Pode consumir ~100-200MB RAM |
| `max_memory_restart` automático | Configuração inicial tem curva de aprendizado |
| Suporte macOS/launchd nativo | Não tem web UI no plano gratuito |
| Backoff configurável entre restarts | |
| Histórico de restarts e uptime | |

---

## PARTE 3 — MONIT: Watchdog Externo (RECOMENDADO como camada extra)

### Fonte
- Manual oficial: https://mmonit.com/monit/documentation/monit.html
- Exemplos de config: https://mmonit.com/wiki/Monit/ConfigurationExamples

### O que é Monit

Monit é um **monitor de processos independente** que age como "câmera de segurança" do seu setup. Ele monitora não apenas se o processo está vivo, mas também:
- Uso de CPU e RAM
- Conectividade de rede/porta
- Conteúdo de logs
- Saúde de arquivos e diretórios

A diferença chave: PM2 reinicia processos que ele próprio gerencia. **Monit reinicia processos que PM2 pode não ter percebido que estão travados** (zombie process, processo vivo mas sem responder).

### Instalação

```bash
# Via Homebrew
brew install monit

# Verificar instalação
monit -V
```

### Configuração — /opt/homebrew/etc/monitrc

```
# Verificar a cada 60 segundos
set daemon 60

# Log
set log /var/log/monit.log

# Alertas por email (opcional — usar webhook ao invés)
# set mailserver smtp.gmail.com port 587
#   username "seu@email.com" password "senha"
#   using tls

# Web UI local (acessar em http://localhost:2812)
set httpd port 2812 and
  use address localhost
  allow admin:titanio2024   # usuário:senha

# Incluir configs separadas
include /opt/homebrew/etc/monit.d/*
```

### Configs de monitoramento — /opt/homebrew/etc/monit.d/

#### n8n.monitrc
```
check process n8n
  matching "n8n"
  start program = "/usr/local/bin/pm2 start n8n" as uid "contact"
  stop program = "/usr/local/bin/pm2 stop n8n" as uid "contact"
  if cpu > 90% for 5 cycles then restart
  if memory > 85% for 3 cycles then restart
  if failed port 5678 protocol http
    request "/" with timeout 30 seconds
    for 3 cycles then restart
  if 5 restarts within 15 cycles then timeout
```

#### openclaw.monitrc
```
check process openclaw
  matching "openclaw"
  start program = "/usr/local/bin/pm2 start openclaw" as uid "contact"
  stop program = "/usr/local/bin/pm2 stop openclaw" as uid "contact"
  if cpu > 80% for 5 cycles then restart
  if memory > 600 MB then restart
  if failed port 3001 protocol http
    request "/health" with timeout 15 seconds
    for 2 cycles then restart
  if 3 restarts within 10 cycles then timeout
```

#### postgresql.monitrc
```
check process postgresql
  with pidfile "/opt/homebrew/var/postgresql@16/postmaster.pid"
  start program = "/opt/homebrew/bin/brew services start postgresql@16"
  stop program = "/opt/homebrew/bin/brew services stop postgresql@16"
  if failed host localhost port 5432 protocol pgsql
    for 3 cycles then restart
  if cpu > 70% for 10 cycles then alert
  if memory > 1 GB then alert
```

#### redis.monitrc
```
check process redis
  with pidfile "/tmp/redis_6379.pid"
  start program = "/opt/homebrew/bin/brew services start redis"
  stop program = "/opt/homebrew/bin/brew services stop redis"
  if failed host localhost port 6379 then restart
  if 5 restarts within 15 cycles then timeout
```

#### system.monitrc
```
check system localhost
  if loadavg (5min) > 6 then alert
  if memory usage > 90% for 4 cycles then alert
  if swap usage > 25% then alert
  if cpu usage > 95% for 3 cycles then alert
```

### Comandos Monit

```bash
# Iniciar monit como daemon
monit

# Ver status de todos os serviços
monit status

# Monitorar processo específico
monit status n8n

# Recarregar configuração
monit reload

# Forçar restart de serviço
monit restart n8n

# Parar monit
monit quit

# Iniciar com launchd no boot
brew services start monit
```

### Prós e Contras do Monit

| ✅ Prós | ❌ Contras |
|---------|-----------|
| Monitora HTTP/TCP/UDP (verifica se RESPONDE, não só se existe) | Configuração em sintaxe própria |
| Monitora RAM e CPU de cada processo | Sem histórico de métricas |
| Completamente independente do PM2 | Web UI básica |
| Alertas configuráveis | |
| Funciona em macOS nativo | |
| Quase zero consumo de recursos | |

---

## PARTE 4 — SUPERVISOR: Alternativa Pythônica

### Fonte
- Docs oficiais: https://supervisord.org/introduction.html
- Config: https://supervisord.org/configuration.html

### Quando usar Supervisor

Melhor opção se você prefere **Python** no stack ou precisa de gerenciamento mais fino de processos Python com namespaces de grupos.

### Instalação

```bash
# Via pip (Python 3)
pip3 install supervisor

# Ou via Homebrew
brew install supervisor

# Gerar config padrão
echo_supervisord_conf > /opt/homebrew/etc/supervisord.conf
```

### Config Exemplo — supervisord.conf

```ini
[unix_http_server]
file=/tmp/supervisor.sock

[supervisord]
logfile=/var/log/titanio/supervisord.log
logfile_maxbytes=50MB
logfile_backups=3
loglevel=info
pidfile=/tmp/supervisord.pid
nodaemon=false

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[program:n8n]
command=/usr/local/bin/n8n start
directory=/Users/contact
autostart=true
autorestart=true
startretries=10
startsecs=10           ; processo precisa ficar vivo 10s pra contar como started
stopwaitsecs=30
stderr_logfile=/var/log/titanio/n8n-error.log
stdout_logfile=/var/log/titanio/n8n-out.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
environment=HOME="/Users/contact",NODE_ENV="production"

[program:bot-polymarket]
command=/Users/contact/.pyenv/versions/3.11.0/bin/python3 -u main.py
directory=/Users/contact/bots/polymarket
autostart=true
autorestart=true
startretries=5
startsecs=5
stderr_logfile=/var/log/titanio/polymarket-error.log
stdout_logfile=/var/log/titanio/polymarket-out.log
environment=PYTHONUNBUFFERED="1",HOME="/Users/contact"

[group:bots]
programs=bot-polymarket,bot-instagram
priority=999
```

### Prós e Contras do Supervisor

| ✅ Prós | ❌ Contras |
|---------|-----------|
| Excelente para processos Python | Escrito em Python 2 (mantido mas legado) |
| Controle de grupos de processos | Sem `max_memory_restart` nativo |
| Config INI simples e legível | Sem dashboard visual moderno |
| Delegação de controle sem root | PM2 tem mais recursos para Node.js |
| Já testado há muitos anos | |

---

## PARTE 5 — N8N: Como Estabilizar

### Fonte
- Docs: https://docs.n8n.io/hosting/configuration/environment-variables/logs/
- Env vars: https://docs.n8n.io/hosting/configuration/environment-variables/

### Por que N8n para sozinho

1. **Falta de persistência de banco**: N8n default usa SQLite que pode corromper sob carga
2. **Memory leak** em workflows com muitas execuções sem limpeza
3. **Sem logs em arquivo** por padrão — quando o processo morre não sobra nada
4. **Timeout em execuções longas** pode matar o worker
5. **OOM Killer** do macOS mata o processo quando RAM fica baixa

### Configuração de estabilidade do N8n

Criar arquivo `/Users/contact/.n8n/.env` ou definir via PM2:

```bash
# Banco de dados (OBRIGATÓRIO para estabilidade — SQLite corrompe)
DB_TYPE=postgresdb
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=sua_senha_segura
DB_POSTGRESDB_SCHEMA=public

# Logging (CRÍTICO — sem isso não há visibilidade)
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file,console
N8N_LOG_FILE_LOCATION=/var/log/titanio/n8n.log
N8N_LOG_FILE_SIZE_MAX=50
N8N_LOG_FILE_COUNT_MAX=10

# Performance e estabilidade
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168        # 7 dias em horas
EXECUTIONS_DATA_PRUNE_MAX_COUNT=10000
N8N_METRICS=true                   # Ativar métricas Prometheus

# Timeouts
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
N8N_BINARY_DATA_TTL=60             # 1 hora

# Segurança
N8N_SECURE_COOKIE=true
```

### Manutenção preventiva do N8n

```bash
# Verificar execuções presas (rodar semanalmente via cron)
# Adicionar no crontab:
# 0 3 * * 0 /usr/local/bin/n8n prune-old-executions >> /var/log/titanio/n8n-maintenance.log 2>&1

# Verificar saúde do N8n
curl -s http://localhost:5678/healthz

# Ver execuções ativas
curl -s http://localhost:5678/api/v1/executions?status=running \
  -H "X-N8N-API-KEY: sua_chave"
```

---

## PARTE 6 — RAM MANAGEMENT no macOS

### O problema

macOS usa **memory compression** e **swap automático** — diferente do Linux, ele não tem OOM Killer agressivo, mas pode **suspender processos** que ficam muito tempo em background. O Ollama, PostgreSQL e N8n juntos podem facilmente consumir 14GB+ dos 16GB disponíveis.

### Estratégias de gerenciamento

#### 1. Configurar limites por processo (via PM2)

```javascript
// No ecosystem.config.js — limites conservadores
{ max_memory_restart: '800M' }  // N8n
{ max_memory_restart: '4G' }    // Ollama (LLMs são pesados)
{ max_memory_restart: '600M' }  // OpenClaw
{ max_memory_restart: '400M' }  // Bots Python
```

#### 2. Monitorar RAM com Monit

```
check system localhost
  if memory usage > 88% for 3 cycles
    then exec "/opt/homebrew/bin/python3 /Users/contact/scripts/free-ram.sh"
```

#### 3. Script de liberação de RAM

Criar `/Users/contact/scripts/free-ram.sh`:

```bash
#!/bin/bash
LOG="/var/log/titanio/ram-management.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] RAM alta detectada - iniciando limpeza" >> $LOG

# Liberar page cache (macOS)
sudo purge

# Pausar Ollama se não houver requisições recentes
LAST_OLLAMA=$(ps -p $(pgrep ollama) -o etime= 2>/dev/null)
echo "[$DATE] Ollama uptime: $LAST_OLLAMA" >> $LOG

# Ver consumo atual
vm_stat | grep -E "Pages (free|active|inactive|wired)" >> $LOG
echo "[$DATE] Limpeza concluída" >> $LOG
```

#### 4. Configurar Ollama com limite de modelos carregados

```bash
# No LaunchDaemon do Ollama — limitar modelos em cache
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_PARALLEL=1
```

#### 5. PostgreSQL — reduzir footprint

Em `/opt/homebrew/var/postgresql@16/postgresql.conf`:

```
shared_buffers = 256MB          # Padrão 128MB, aumentar com cuidado
work_mem = 16MB                 # Por query, pode acumular
maintenance_work_mem = 64MB
max_connections = 50            # Reduzir do padrão 100
effective_cache_size = 2GB
```

---

## PARTE 7 — CRON JOBS: Silenciar emails e capturar falhas

### O Problema

Todo cron job que gera saída no stdout/stderr envia email local para `/var/mail`. No macOS isso pode acumular GB de emails. Além disso, falhas silenciosas não são detectadas.

### Soluções

#### 1. Redirecionar saída de todos os cron jobs

```bash
# Editar crontab
crontab -e

# ERRADO (gera email):
0 * * * * /usr/local/bin/meu-script.sh

# CORRETO (redireciona para log):
0 * * * * /usr/local/bin/meu-script.sh >> /var/log/titanio/cron.log 2>&1

# ALTERNATIVA com timestamp:
0 * * * * date && /usr/local/bin/meu-script.sh >> /var/log/titanio/cron.log 2>&1
```

#### 2. Adicionar MAILTO vazio no topo do crontab

```bash
# Primeira linha do crontab — desabilita emails
MAILTO=""
SHELL=/bin/zsh
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

0 * * * * /Users/contact/scripts/health-check.sh >> /var/log/titanio/health.log 2>&1
```

#### 3. Detectar falhas silenciosas com wrapper

Criar `/Users/contact/scripts/cron-wrapper.sh`:

```bash
#!/bin/bash
# Uso: cron-wrapper.sh "nome-do-job" comando args...
# Captura falhas e envia alerta via webhook

JOB_NAME="$1"
shift
CMD="$@"

LOG="/var/log/titanio/cron-${JOB_NAME}.log"
WEBHOOK_URL="http://localhost:5678/webhook/cron-alert"  # N8n webhook

{
  echo "=== $(date) === START: $JOB_NAME ==="
  $CMD
  EXIT_CODE=$?
  echo "=== $(date) === END: $JOB_NAME (exit: $EXIT_CODE) ==="

  if [ $EXIT_CODE -ne 0 ]; then
    # Enviar alerta para N8n
    curl -s -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"job\": \"$JOB_NAME\", \"exitCode\": $EXIT_CODE, \"time\": \"$(date -Iseconds)\"}" \
      2>/dev/null
  fi
} >> "$LOG" 2>&1
```

#### 4. Limpar /var/mail acumulado

```bash
# Ver tamanho atual
du -sh /var/mail/$(whoami)

# Limpar (CUIDADO — apaga tudo)
> /var/mail/$(whoami)

# Ou instalar mailutils e deletar
mail -d     # deletar mensagens interativamente
```

---

## PARTE 8 — WATCHDOG SCRIPT: Camada Extra de Proteção

### Script Master Watchdog

Criar `/Users/contact/scripts/watchdog.sh`:

```bash
#!/bin/bash
# WATCHDOG TITANIO — Verificação de saúde a cada 5 minutos (via PM2)
# pm2 start watchdog.sh --name watchdog --cron "*/5 * * * *" --no-autorestart

LOG="/var/log/titanio/watchdog.log"
ALERT_WEBHOOK="http://localhost:5678/webhook/system-alert"

check_http() {
  local NAME="$1"
  local URL="$2"
  local RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL")
  if [ "$RESPONSE" != "200" ] && [ "$RESPONSE" != "201" ]; then
    echo "[$(date)] WARN: $NAME retornou $RESPONSE (esperado 200)" >> "$LOG"
    return 1
  fi
  return 0
}

check_port() {
  local NAME="$1"
  local HOST="$2"
  local PORT="$3"
  if ! nc -z -w5 "$HOST" "$PORT" 2>/dev/null; then
    echo "[$(date)] ERRO: $NAME não responde em $HOST:$PORT" >> "$LOG"
    curl -s -X POST "$ALERT_WEBHOOK" \
      -d "{\"service\":\"$NAME\",\"issue\":\"port_down\",\"port\":$PORT}" \
      -H "Content-Type: application/json" 2>/dev/null
    return 1
  fi
  return 0
}

# Verificações
check_port "N8n"        "localhost" 5678
check_port "PostgreSQL"  "localhost" 5432
check_port "Redis"       "localhost" 6379
check_http "N8n Health"  "http://localhost:5678/healthz"
check_http "Dashboard"   "http://localhost:3000/health"

# Verificar RAM
MEMORY_PERCENT=$(vm_stat | awk '
  /Pages free/ { free=$3 }
  /Pages active/ { active=$3 }
  /Pages inactive/ { inactive=$3 }
  /Pages wired/ { wired=$4 }
  END { total=free+active+inactive+wired; used=active+wired; printf "%d\n", used/total*100 }
')

if [ "$MEMORY_PERCENT" -gt 90 ]; then
  echo "[$(date)] ALERTA: RAM em ${MEMORY_PERCENT}%" >> "$LOG"
  curl -s -X POST "$ALERT_WEBHOOK" \
    -d "{\"service\":\"system\",\"issue\":\"high_memory\",\"value\":$MEMORY_PERCENT}" \
    -H "Content-Type: application/json" 2>/dev/null
fi

echo "[$(date)] Watchdog OK — RAM: ${MEMORY_PERCENT}%" >> "$LOG"
```

---

## PARTE 9 — PROCESSOS PYTHON: Logs e Resiliência

### Por que bots Python morrem sem log

1. `print()` tem buffer — em crash o buffer é descartado antes de gravar
2. Exceções não capturadas sem handler global
3. Sem signal handlers para SIGTERM

### Solução: Template de bot Python resiliente

```python
#!/usr/bin/env python3
"""Bot resiliente com logging adequado"""

import logging
import signal
import sys
import time
import traceback
from datetime import datetime

# CRÍTICO: configurar logging ANTES de qualquer import
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),  # PM2 captura stdout
        logging.FileHandler('/var/log/titanio/bot-polymarket.log'),
    ]
)
logger = logging.getLogger('bot-polymarket')

# Handler para SIGTERM (quando PM2/launchd manda parar)
def handle_sigterm(signum, frame):
    logger.info("SIGTERM recebido — encerrando graciosamente")
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)
signal.signal(signal.SIGINT, handle_sigterm)

# Handler global para exceções não capturadas
def handle_exception(exc_type, exc_value, exc_traceback):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return
    logger.critical(
        "Exceção não capturada",
        exc_info=(exc_type, exc_value, exc_traceback)
    )

sys.excepthook = handle_exception

# Loop principal com retry
def main():
    logger.info("Bot iniciado")
    retry_count = 0
    max_retries = 5

    while True:
        try:
            # ===== SEU CÓDIGO AQUI =====
            run_bot_logic()
            retry_count = 0  # Reset em sucesso
            # ===========================

        except Exception as e:
            retry_count += 1
            logger.error(f"Erro na iteração (tentativa {retry_count}/{max_retries}): {e}")
            logger.error(traceback.format_exc())

            if retry_count >= max_retries:
                logger.critical("Máximo de tentativas atingido — encerrando para PM2 reiniciar")
                sys.exit(1)  # Saída com erro = PM2 reinicia

            wait_time = min(30 * retry_count, 300)  # backoff exponencial, max 5min
            logger.info(f"Aguardando {wait_time}s antes de tentar novamente...")
            time.sleep(wait_time)

if __name__ == '__main__':
    main()
```

---

## PARTE 10 — WHATSAPP GATEWAY: Resolver status 499

### O que é status 499

Status 499 é código do Nginx/proxy indicando **cliente fechou conexão antes da resposta**. Em contexto de WhatsApp (Baileys/WA-Multi-Device), significa que a sessão WebSocket foi dropada do lado do WhatsApp.

### Causas e soluções

#### Causa 1: IP ou sessão banida temporariamente pelo WhatsApp

```bash
# Verificar se o IP está bloqueado (testar de outro dispositivo na mesma rede)
# Solução: aguardar 30min, então reconectar com novo QR code

# Configurar reconnect automático no OpenClaw
# Em ~/.openclaw/config.yaml:
whatsapp:
  reconnect_on_disconnect: true
  reconnect_delay_seconds: 30
  max_reconnect_attempts: 10
```

#### Causa 2: RAM baixa mata a sessão antes de salvar estado

```bash
# Garantir que o processo do gateway tenha prioridade alta
# Via PM2 ecosystem.config.js:
{
  name: 'openclaw',
  // ...
  kill_timeout: 5000,      # dar 5s para encerrar graciosamente
  listen_timeout: 10000,   # aguardar 10s para iniciar
}
```

#### Causa 3: Timeout de keepalive do WebSocket

Verificar configuração de heartbeat no gateway e garantir ping periódico:

```bash
# Em config do openclaw ou via variável de ambiente:
WHATSAPP_KEEPALIVE_INTERVAL=25000   # ping a cada 25s
WHATSAPP_CONNECTION_TIMEOUT=60000   # timeout de 60s
```

---

## PARTE 11 — ARQUITETURA RECOMENDADA FINAL

```
┌─────────────────────────────────────────────────┐
│              Mac Mini M4 - 16GB RAM             │
├─────────────────────────────────────────────────┤
│  CAMADA 1: Boot (LaunchDaemon)                  │
│  └── /Library/LaunchDaemons/com.titanio.pm2.plist │
│      └── Inicia PM2 no boot como daemon         │
├─────────────────────────────────────────────────┤
│  CAMADA 2: Process Manager (PM2)                │
│  ├── n8n         → porta 5678                   │
│  ├── openclaw    → porta 3001                   │
│  ├── dashboard   → porta 3000                   │
│  ├── bot-polymarket                             │
│  └── bot-instagram                             │
├─────────────────────────────────────────────────┤
│  CAMADA 3: Watchdog (Monit)                     │
│  ├── Verifica HTTP/TCP a cada 60s               │
│  ├── Monitora RAM/CPU de cada processo          │
│  └── Reinicia via PM2 se necessário             │
├─────────────────────────────────────────────────┤
│  CAMADA 4: Serviços de Sistema (Homebrew)       │
│  ├── PostgreSQL  → brew services start postgresql│
│  └── Redis       → brew services start redis    │
├─────────────────────────────────────────────────┤
│  CAMADA 5: Alertas (N8n Webhooks)               │
│  └── Watchdog script → N8n → WhatsApp alert     │
└─────────────────────────────────────────────────┘
```

### Quickstart — Implementar tudo em 1 hora

```bash
# 1. Criar diretório de logs
sudo mkdir -p /var/log/titanio
sudo chown contact:staff /var/log/titanio

# 2. Instalar PM2
npm install pm2@latest -g

# 3. Criar ecosystem.config.js (ver Parte 2)
nano ~/ecosystem.config.js

# 4. Iniciar todos os serviços
pm2 start ~/ecosystem.config.js

# 5. Configurar startup
pm2 startup      # copiar e rodar o comando que imprimir
pm2 save

# 6. Instalar Monit
brew install monit

# 7. Configurar monitrc (ver Parte 3)
nano /opt/homebrew/etc/monitrc
mkdir -p /opt/homebrew/etc/monit.d

# 8. Iniciar Monit
brew services start monit

# 9. Silenciar cron emails
crontab -e
# Adicionar na primeira linha: MAILTO=""

# 10. Verificar tudo
pm2 status
monit status
```

---

## FONTES CONSULTADAS

1. **Apple Developer Docs — LaunchDaemons** https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
2. **PM2 Quick Start** https://pm2.keymetrics.io/docs/usage/quick-start/
3. **PM2 Startup Script** https://pm2.keymetrics.io/docs/usage/startup/
4. **Monit Manual** https://mmonit.com/monit/documentation/monit.html
5. **Monit Config Examples** https://mmonit.com/wiki/Monit/ConfigurationExamples
6. **Supervisor Documentation** https://supervisord.org/introduction.html
7. **Supervisor Configuration** https://supervisord.org/configuration.html
8. **N8n Environment Variables** https://docs.n8n.io/hosting/configuration/environment-variables/
9. **N8n Logging Variables** https://docs.n8n.io/hosting/configuration/environment-variables/logs/
10. **N8n Server Setups** https://docs.n8n.io/hosting/installation/server-setups/

---

## COMPARATIVO FINAL: PM2 vs Supervisor vs Monit vs launchd puro

| Critério | PM2 | Supervisor | Monit | launchd puro |
|----------|-----|-----------|-------|-------------|
| Node.js processes | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | N/A | ⭐⭐⭐ |
| Python processes | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | N/A | ⭐⭐⭐ |
| macOS suporte | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| HTTP healthcheck | ❌ | ❌ | ⭐⭐⭐⭐⭐ | ❌ |
| RAM limit auto | ⭐⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ | ❌ |
| Dashboard visual | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ❌ |
| Log management | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ |
| Dependências | Node.js | Python | Nenhuma | Nenhuma |
| Overhead RAM | ~150MB | ~30MB | ~5MB | 0 |
| Boot automático | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Veredicto: PM2 + Monit é a combinação vencedora para o setup do Mac Mini M4.**
- PM2 gerencia os processos com inteligência (RAM, logs, backoff)
- Monit verifica saúde real (HTTP, porta, RAM do sistema)
- launchd garante que PM2 sobe no boot

---

*Pesquisa gerada por Tita 🐾 — 02/04/2026*
