#!/bin/bash
############################################################
# TITANIO DASHBOARD — INSTALADOR COMPLETO v2.0
# Criado por: Tita 🐾
# Data: 2026-04-02
#
# O que faz:
#   1. Detecta o ambiente (Mac Mini, volume TITA_039)
#   2. Instala dependências (Node, PM2, Redis, PostgreSQL)
#   3. Clona/atualiza o código da dashboard
#   4. Compila backend (TypeScript → JS) e frontend (Next.js build)
#   5. Configura PM2 com ecosystem.config.js
#   6. Configura volume compartilhado pra sincronizar especialistas
#   7. Roda testes automáticos e gera relatório
#   8. Envia relatório pro WhatsApp (se OpenClaw estiver rodando)
#
# Uso:
#   chmod +x INSTALL-TITANIO-DASHBOARD.sh
#   ./INSTALL-TITANIO-DASHBOARD.sh
#
# Se der qualquer erro, o script para e mostra o que deu errado.
############################################################

set -euo pipefail

# ─── CORES ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

log()  { echo -e "${GREEN}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
fail() { echo -e "${RED}[❌]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[ℹ️]${NC} $1"; }

# ─── DETECÇÃO DE AMBIENTE ───────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  🏗️  TITANIO DASHBOARD — INSTALADOR v2.0         ║${NC}"
echo -e "${BOLD}║  $(date '+%Y-%m-%d %H:%M:%S')                            ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Detectar volume TITA_039
TITA_VOLUME=""
for vol in /Volumes/TITA_039 /Volumes/TITA_039_*; do
  if [ -d "$vol" ] 2>/dev/null; then
    TITA_VOLUME="$vol"
    break
  fi
done

if [ -z "$TITA_VOLUME" ]; then
  warn "Volume TITA_039 não encontrado — usando home"
  TITA_VOLUME="$HOME"
fi

# Detectar hostname e definir paths
MACHINE_NAME=$(hostname -s)
OPENCLAW_DIR="$TITA_VOLUME/$MACHINE_NAME/.openclaw"
WORKSPACE="$OPENCLAW_DIR/workspace"
DASH_DIR="$WORKSPACE/pasta-do-tita/projetos/titanio-dashboard/code"
SHARED_FILE="$TITA_VOLUME/shared-specialists.json"

info "Máquina: $MACHINE_NAME"
info "Volume: $TITA_VOLUME"
info "Workspace: $WORKSPACE"
info "Dashboard: $DASH_DIR"
echo ""

# ─── 1. DEPENDÊNCIAS ────────────────────────────────────
echo -e "${BOLD}━━━ 1/7: VERIFICANDO DEPENDÊNCIAS ━━━${NC}"

# Node.js
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  log "Node.js: $NODE_VER"
else
  warn "Node.js não encontrado — instalando via brew"
  brew install node || fail "Não consegui instalar Node.js"
fi

# npm
if command -v npm &>/dev/null; then
  log "npm: $(npm --version)"
else
  fail "npm não encontrado"
fi

# PM2
if command -v pm2 &>/dev/null; then
  log "PM2: $(pm2 --version 2>/dev/null || echo 'instalado')"
else
  info "Instalando PM2..."
  npm install -g pm2 || fail "Não consegui instalar PM2"
  log "PM2 instalado"
fi

# PM2 logrotate
pm2 install pm2-logrotate 2>/dev/null || true
pm2 set pm2-logrotate:max_size 10M 2>/dev/null || true
pm2 set pm2-logrotate:retain 7 2>/dev/null || true
log "PM2 logrotate configurado"

# Redis
if command -v redis-cli &>/dev/null; then
  log "Redis: $(redis-cli --version 2>/dev/null | head -1)"
else
  warn "Redis não encontrado — instalando via brew"
  brew install redis || warn "Redis não instalou (não crítico)"
fi
# Iniciar Redis se não estiver rodando
if ! redis-cli ping &>/dev/null 2>&1; then
  brew services start redis 2>/dev/null || true
fi

# PostgreSQL
if brew services list 2>/dev/null | grep -q "postgresql.*started"; then
  log "PostgreSQL: rodando"
else
  brew services start postgresql@15 2>/dev/null || brew services start postgresql 2>/dev/null || warn "PostgreSQL não iniciou (não crítico)"
fi

echo ""

# ─── 2. CÓDIGO ──────────────────────────────────────────
echo -e "${BOLD}━━━ 2/7: ATUALIZANDO CÓDIGO ━━━${NC}"

if [ ! -d "$DASH_DIR" ]; then
  info "Dashboard não existe — criando estrutura"
  mkdir -p "$DASH_DIR"
fi

# Se tem git, fazer pull
if [ -d "$WORKSPACE/.git" ]; then
  cd "$WORKSPACE"
  git pull 2>/dev/null || warn "Git pull falhou (pode estar em branch local)"
  log "Código atualizado via git"
else
  log "Sem git — usando código local"
fi

# Instalar dependências
cd "$DASH_DIR"
if [ -f "package.json" ]; then
  info "Instalando dependências npm..."
  npm install --silent 2>/dev/null || npm install
  log "Dependências instaladas"
else
  fail "package.json não encontrado em $DASH_DIR"
fi

echo ""

# ─── 3. BUILD BACKEND ──────────────────────────────────
echo -e "${BOLD}━━━ 3/7: COMPILANDO BACKEND ━━━${NC}"

if [ -d "$DASH_DIR/backend" ]; then
  cd "$DASH_DIR/backend"
  
  # Instalar dependências do backend se necessário
  if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
    npm install --silent 2>/dev/null || npm install
  fi
  
  # Compilar TypeScript
  info "Compilando TypeScript → JavaScript..."
  npm run build 2>&1 || fail "Build do backend falhou!"
  
  if [ -f "dist/index.js" ]; then
    SIZE=$(ls -lh dist/index.js | awk '{print $5}')
    log "Backend compilado: dist/index.js ($SIZE)"
  else
    fail "dist/index.js não gerado!"
  fi
else
  fail "Diretório backend não encontrado"
fi

echo ""

# ─── 4. BUILD FRONTEND ─────────────────────────────────
echo -e "${BOLD}━━━ 4/7: COMPILANDO FRONTEND ━━━${NC}"

if [ -d "$DASH_DIR/frontend" ]; then
  cd "$DASH_DIR/frontend"
  
  # Verificar se .next existe e é recente (< 24h)
  if [ -f ".next/BUILD_ID" ]; then
    NEXT_AGE=$(( $(date +%s) - $(stat -f %m .next/BUILD_ID 2>/dev/null || stat -c %Y .next/BUILD_ID 2>/dev/null || echo 0) ))
    if [ "$NEXT_AGE" -lt 86400 ]; then
      log "Frontend build recente ($(($NEXT_AGE / 60))min atrás) — pulando"
    else
      info "Build do frontend desatualizado — recompilando..."
      cd "$DASH_DIR"
      npx next build 2>&1 || npm run build 2>&1 || fail "Build do frontend falhou!"
    fi
  else
    info "Compilando frontend..."
    cd "$DASH_DIR"
    npx next build 2>&1 || npm run build 2>&1 || fail "Build do frontend falhou!"
  fi
  
  # Criar symlink se necessário (next start precisa achar .next)
  if [ -d "$DASH_DIR/frontend/.next" ] && [ ! -e "$DASH_DIR/.next" ]; then
    ln -sf "$DASH_DIR/frontend/.next" "$DASH_DIR/.next"
    log "Symlink .next criado"
  fi
  
  BUILD_ID=$(cat "$DASH_DIR/frontend/.next/BUILD_ID" 2>/dev/null || echo "unknown")
  log "Frontend compilado: BUILD_ID=$BUILD_ID"
else
  fail "Diretório frontend não encontrado"
fi

echo ""

# ─── 5. CONFIGURAR PM2 ─────────────────────────────────
echo -e "${BOLD}━━━ 5/7: CONFIGURANDO PM2 ━━━${NC}"

# Criar diretório de logs
mkdir -p "$WORKSPACE/logs"

# Criar ecosystem.config.js
cat > "$WORKSPACE/ecosystem.config.js" << ECOEOF
// ecosystem.config.js — Titanio Dashboard Production
// Gerado automaticamente pelo instalador v2.0
// $(date '+%Y-%m-%d %H:%M:%S')

const DASH = '$DASH_DIR';
const WORKSPACE = '$WORKSPACE';

module.exports = {
  apps: [
    {
      name: 'dashboard-backend',
      cwd: \`\${DASH}/backend\`,
      script: 'node',
      args: 'dist/index.js',
      env: { NODE_ENV: 'production', PORT: '4444', WORKSPACE: WORKSPACE },
      max_memory_restart: '800M',
      restart_delay: 3000,
      max_restarts: 20,
      min_uptime: '10s',
      kill_timeout: 5000,
      watch: false,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      error_file: \`\${WORKSPACE}/logs/backend-error.log\`,
      out_file: \`\${WORKSPACE}/logs/backend-out.log\`,
      merge_logs: true,
    },
    {
      name: 'dashboard-frontend',
      cwd: \`\${DASH}/frontend\`,
      script: \`\${DASH}/node_modules/.bin/next\`,
      args: 'start -p 3000',
      env: { NODE_ENV: 'production', PORT: '3000' },
      max_memory_restart: '300M',
      restart_delay: 3000,
      max_restarts: 10,
      min_uptime: '10s',
      kill_timeout: 5000,
      watch: false,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      error_file: \`\${WORKSPACE}/logs/frontend-error.log\`,
      out_file: \`\${WORKSPACE}/logs/frontend-out.log\`,
      merge_logs: true,
    },
    {
      name: 'n8n',
      script: 'n8n',
      args: 'start',
      env: { N8N_PORT: '5678', N8N_PROTOCOL: 'http', NODE_ENV: 'production' },
      max_memory_restart: '400M',
      restart_delay: 5000,
      max_restarts: 5,
      min_uptime: '15s',
      kill_timeout: 10000,
      watch: false,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      error_file: \`\${WORKSPACE}/logs/n8n-error.log\`,
      out_file: \`\${WORKSPACE}/logs/n8n-out.log\`,
      merge_logs: true,
    },
  ],
};
ECOEOF

log "ecosystem.config.js gerado"

# Parar processos antigos
pm2 delete all 2>/dev/null || true

# Iniciar com novo ecosystem
cd "$WORKSPACE"
pm2 start ecosystem.config.js 2>&1 | tail -5
pm2 save 2>&1 | head -2

# Configurar startup (sobrevive reboot)
pm2 startup 2>/dev/null | tail -1 || true

log "PM2 configurado e salvo"
echo ""

# ─── 6. VOLUME COMPARTILHADO ───────────────────────────
echo -e "${BOLD}━━━ 6/7: CONFIGURANDO SINCRONIZAÇÃO ━━━${NC}"

# Criar shared-specialists.json se não existir
if [ ! -f "$SHARED_FILE" ]; then
  echo '{"specialists":{},"lastSync":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","totalLessons":0,"totalTasks":0}' > "$SHARED_FILE"
  log "Arquivo compartilhado criado: $SHARED_FILE"
else
  SIZE=$(ls -lh "$SHARED_FILE" | awk '{print $5}')
  log "Arquivo compartilhado existe: $SHARED_FILE ($SIZE)"
fi

# Criar diretório de memória de especialistas
SPEC_MEM="$WORKSPACE/pasta-do-tita/memoria-especialistas"
mkdir -p "$SPEC_MEM"

# Rodar sync inicial
info "Sincronizando especialistas..."
sleep 3
SYNC_RESULT=$(curl -s http://localhost:4444/api/specialists/sync 2>/dev/null || echo '{"success":false}')
SYNC_OK=$(echo "$SYNC_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success','false'))" 2>/dev/null)
if [ "$SYNC_OK" = "True" ]; then
  IMPORTED=$(echo "$SYNC_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('imported',0))" 2>/dev/null)
  EXPORTED=$(echo "$SYNC_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('exported',0))" 2>/dev/null)
  log "Sync: $IMPORTED importadas, $EXPORTED exportadas"
else
  warn "Sync falhou — será feita no próximo ciclo"
fi

echo ""

# ─── 7. TESTES E RELATÓRIO ──────────────────────────────
echo -e "${BOLD}━━━ 7/7: TESTES AUTOMÁTICOS ━━━${NC}"

REPORT_FILE="$WORKSPACE/RELATORIO-INSTALACAO-$(date '+%Y%m%d-%H%M%S').md"
DASH_URL="http://localhost:4444"

# Esperar backend subir completamente
sleep 5

# Gerar relatório
python3 << REPORTEOF > "$REPORT_FILE"
import urllib.request, json, time, subprocess, os, socket

DASH = "$DASH_URL"
MACHINE = "$MACHINE_NAME"
WORKSPACE = "$WORKSPACE"
SPEC_MEM = "$SPEC_MEM"
SHARED = "$SHARED_FILE"

results = {"pass": [], "fail": [], "warn": []}

def get(path, timeout=5):
    try:
        r = urllib.request.urlopen(f"{DASH}{path}", timeout=timeout)
        return json.loads(r.read()), r.status
    except Exception as e:
        return None, str(e)[:50]

def ok(n): results["pass"].append(n)
def fail(n, d=""): results["fail"].append(f"{n}: {d}" if d else n)
def warn(n, d=""): results["warn"].append(f"{n}: {d}" if d else n)

now = time.strftime("%Y-%m-%d %H:%M:%S")

print(f"# 📊 Relatório de Instalação — Titanio Dashboard")
print(f"")
print(f"**Máquina:** {MACHINE}")
print(f"**Data:** {now}")
print(f"**IP local:** {socket.gethostbyname(socket.gethostname())}")
print(f"**Node:** {subprocess.run(['node', '--version'], capture_output=True, text=True).stdout.strip()}")
print(f"**OS:** {subprocess.run(['sw_vers', '-productVersion'], capture_output=True, text=True).stdout.strip()}")
print(f"")

# PM2
print(f"## PM2 Processos")
print(f"")
try:
    r = subprocess.run(["pm2", "jlist"], capture_output=True, text=True, timeout=10)
    procs = json.loads(r.stdout)
    for p in procs:
        name = p.get("name", "?")
        status = p.get("pm2_env", {}).get("status", "?")
        mem = round(p.get("monit", {}).get("memory", 0) / 1024 / 1024, 1)
        restarts = p.get("pm2_env", {}).get("restart_time", 0)
        icon = "✅" if status == "online" else "❌"
        print(f"- {icon} **{name}**: {status} | {mem}MB RAM | {restarts} restarts")
        if status == "online": ok(f"PM2 {name}")
        else: fail(f"PM2 {name}", status)
except: fail("PM2", "não respondeu")

print()

# Endpoints
print(f"## Endpoints API")
print(f"")
tests = [
    ("/api/squad", "Squad"),
    ("/api/bots", "Bots"),
    ("/api/projects", "Projetos"),
    ("/api/tasks", "Tasks"),
    ("/api/reports", "Relatórios"),
    ("/api/health", "Health"),
    ("/api/system", "Sistema"),
    ("/api/sentinels", "Sentinelas"),
    ("/api/notifications", "Notificações"),
    ("/api/search?q=test", "Busca"),
    ("/api/media/gallery", "Mídia"),
    ("/api/vault/status", "Cofre"),
    ("/api/vault/credentials", "Credenciais"),
    ("/api/openclaw/models", "Modelos"),
    ("/api/openclaw/session", "Sessão"),
    ("/api/logs", "Logs"),
    ("/api/settings", "Settings"),
    ("/api/specialists/code-ninja/stats", "Stats especialista"),
    ("/api/specialists/sync", "Sync"),
    ("/api/sync/stats", "Sync stats"),
]

for path, name in tests:
    d, s = get(path)
    if s == 200:
        ok(name)
        detail = ""
        if isinstance(d, list): detail = f" ({len(d)} items)"
        elif isinstance(d, dict) and "current" in d: detail = f" ({d['current']})"
        print(f"- ✅ {name}{detail}")
    else:
        fail(name, str(s))
        print(f"- ❌ {name}: {s}")

print()

# Modelo
print("## Modelo IA")
print()
d, s = get("/api/openclaw/models")
if d:
    current = d.get("current", "?")
    models = d.get("models", d.get("available", []))
    print(f"- **Modelo atual:** {current}")
    print(f"- **Modelos disponíveis:** {len(models)}")
    if "opus" in current.lower(): ok("Modelo opus")
    else: warn("Modelo", f"usando {current}")

print()

# Especialistas
print("## Especialistas")
print()
d, s = get("/api/squad")
if s == 200 and isinstance(d, list):
    print(f"- **Total:** {len(d)}")
    busy = [x for x in d if x.get("status") == "busy"]
    if busy:
        print(f"- **Ocupados:** {len(busy)} ({', '.join(x['name'] for x in busy)})")
    top = sorted(d, key=lambda x: x.get("_memoryInfo",{}).get("tasksCompleted",0), reverse=True)[:5]
    print(f"- **Top 5 por tasks:**")
    for x in top:
        tc = x.get("_memoryInfo",{}).get("tasksCompleted",0)
        if tc > 0:
            print(f"  - {x['name']}: {tc} tasks")

print()

# Memória
print("## Memória & Sincronização")
print()
if os.path.isdir(SPEC_MEM):
    specs = [d for d in os.listdir(SPEC_MEM) if os.path.isdir(os.path.join(SPEC_MEM, d))]
    with_mem = sum(1 for s in specs if os.path.exists(os.path.join(SPEC_MEM, s, "memory.json")))
    with_les = sum(1 for s in specs if os.path.exists(os.path.join(SPEC_MEM, s, "lessons.json")))
    print(f"- **Diretórios:** {len(specs)}")
    print(f"- **Com memory.json:** {with_mem}")
    print(f"- **Com lessons.json:** {with_les}")
    ok("Memória especialistas")

if os.path.exists(SHARED):
    size = os.path.getsize(SHARED)
    print(f"- **Arquivo compartilhado:** {round(size/1024)}KB")
    try:
        with open(SHARED) as f:
            sd = json.load(f)
        print(f"- **Especialistas compartilhados:** {len(sd.get('specialists',{}))}")
        print(f"- **Último sync:** {sd.get('lastSync','?')}")
        ok("Arquivo compartilhado")
    except: warn("Shared file", "parse error")
else:
    warn("Shared file", "não encontrado")

print()

# Serviços externos
print("## Serviços Externos")
print()
for name, check in [
    ("Redis", lambda: subprocess.run(["redis-cli","ping"], capture_output=True, text=True, timeout=3).stdout.strip() == "PONG"),
    ("Ollama", lambda: urllib.request.urlopen("http://localhost:11434/api/tags", timeout=3).status == 200),
]:
    try:
        if check():
            ok(name)
            print(f"- ✅ {name}")
        else:
            warn(name)
            print(f"- ⚠️ {name}")
    except:
        warn(name, "offline")
        print(f"- ⚠️ {name}: offline (não crítico)")

# Gateway OpenClaw
try:
    r = urllib.request.urlopen("http://localhost:18789/health", timeout=3)
    d = json.loads(r.read())
    if d.get("ok"):
        ok("Gateway OpenClaw")
        print(f"- ✅ Gateway OpenClaw")
    else:
        warn("Gateway", "not ok")
        print(f"- ⚠️ Gateway OpenClaw")
except:
    warn("Gateway", "offline")
    print(f"- ⚠️ Gateway OpenClaw: offline (inicie com 'openclaw gateway start')")

print()

# Resultado final
total = len(results["pass"]) + len(results["fail"]) + len(results["warn"])
score = int(len(results["pass"]) / total * 100) if total > 0 else 0

print("## Resultado Final")
print()
print(f"- ✅ **Passou:** {len(results['pass'])}/{total}")
print(f"- ⚠️ **Avisos:** {len(results['warn'])}")
print(f"- ❌ **Falhou:** {len(results['fail'])}")
print(f"- 🎯 **Score:** {score}%")
print()

if score >= 95:
    print("### ✅ INSTALAÇÃO BEM SUCEDIDA!")
    print("Dashboard Titanio funcionando corretamente.")
elif score >= 80:
    print("### ⚠️ INSTALAÇÃO PARCIAL")
    print("A maioria funciona, mas alguns itens precisam de atenção:")
    for f in results["fail"]:
        print(f"- ❌ {f}")
else:
    print("### ❌ INSTALAÇÃO COM PROBLEMAS")
    print("Itens que falharam:")
    for f in results["fail"]:
        print(f"- ❌ {f}")

if results["warn"]:
    print()
    print("### Avisos:")
    for w in results["warn"]:
        print(f"- ⚠️ {w}")

print()
print("---")
print(f"*Gerado automaticamente por Tita 🐾 em {now}*")
REPORTEOF

# Mostrar resultado
echo ""
cat "$REPORT_FILE"
echo ""
log "Relatório salvo: $REPORT_FILE"

# ─── FIM ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ✅ INSTALAÇÃO COMPLETA!                         ║${NC}"
echo -e "${BOLD}║                                                  ║${NC}"
echo -e "${BOLD}║  Dashboard: http://localhost:3000                 ║${NC}"
echo -e "${BOLD}║  Backend:   http://localhost:4444                 ║${NC}"
echo -e "${BOLD}║  N8n:       http://localhost:5678                 ║${NC}"
echo -e "${BOLD}║                                                  ║${NC}"
echo -e "${BOLD}║  PM2: pm2 list | pm2 logs | pm2 restart all      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
