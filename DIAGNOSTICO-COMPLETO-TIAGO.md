# 🔍 DIAGNÓSTICO COMPLETO — Máquina do Tiago
# Para: OpenClaw Agent do Tiago executar e enviar resultado pra Tita analisar
# Data: 02/04/2026
# Autor: Tita (Time HiClaw)

---

## INSTRUÇÕES PARA O CLAW DO TIAGO

Execute TODOS os blocos abaixo em sequência. O resultado final será salvo em:
`~/.openclaw/workspace/DIAGNOSTICO-RESULTADO-TIAGO.md`

**Após rodar tudo, envie esse arquivo .md de volta para o grupo Gospia ou para a Tita.**

---

## INICIAR DIAGNÓSTICO

```bash
DIAG_FILE="$HOME/.openclaw/workspace/DIAGNOSTICO-RESULTADO-TIAGO.md"
DIAG_DATE=$(date "+%Y-%m-%d %H:%M:%S")

cat > "$DIAG_FILE" << HEADER
# 🔍 DIAGNÓSTICO COMPLETO — Máquina do Tiago
**Data:** $DIAG_DATE
**Hostname:** $(hostname)
**User:** $(whoami)
**macOS:** $(sw_vers -productVersion 2>/dev/null || echo "N/A")
**Arch:** $(uname -m)

---

HEADER
echo "📋 Diagnóstico iniciado: $DIAG_FILE"
```

---

## 1. SISTEMA OPERACIONAL E HARDWARE

```bash
cat >> "$DIAG_FILE" << 'SECTION'
## 1. SISTEMA OPERACIONAL E HARDWARE
SECTION

echo "### Memória RAM" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
vm_stat 2>/dev/null | head -10 >> "$DIAG_FILE"
echo "" >> "$DIAG_FILE"
# RAM total e usada
sysctl -n hw.memsize 2>/dev/null | awk '{printf "RAM Total: %.1f GB\n", $1/1024/1024/1024}' >> "$DIAG_FILE"
memory_pressure 2>/dev/null | head -3 >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Disco" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
df -h / 2>/dev/null | head -5 >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### CPU" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
sysctl -n machdep.cpu.brand_string 2>/dev/null >> "$DIAG_FILE"
echo "Cores: $(sysctl -n hw.ncpu 2>/dev/null)" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 2. OPENCLAW

```bash
echo "## 2. OPENCLAW" >> "$DIAG_FILE"

echo "### Versão" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
openclaw --version 2>&1 >> "$DIAG_FILE" || echo "❌ OpenClaw não encontrado" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Status" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
openclaw status 2>&1 | head -30 >> "$DIAG_FILE" || echo "❌ OpenClaw status falhou" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Gateway" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
openclaw gateway status 2>&1 | head -10 >> "$DIAG_FILE" || echo "❌ Gateway não responde" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Config (sem secrets)" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
openclaw config list 2>&1 | grep -v -iE "key|secret|token|password" | head -30 >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Workspace" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
ls -la ~/.openclaw/workspace/ 2>/dev/null >> "$DIAG_FILE" || echo "❌ Workspace não existe" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 3. DASHBOARD TITANIO

```bash
echo "## 3. DASHBOARD TITANIO" >> "$DIAG_FILE"

echo "### Diretório" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
if [ -d ~/titanio-dashboard ]; then
    echo "✅ ~/titanio-dashboard existe" >> "$DIAG_FILE"
    ls ~/titanio-dashboard/ 2>/dev/null >> "$DIAG_FILE"
else
    echo "❌ ~/titanio-dashboard NÃO encontrado" >> "$DIAG_FILE"
fi
echo '```' >> "$DIAG_FILE"

echo "### Backend rodando?" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
# Checar portas 4444 e 4446
for PORT in 4444 4446; do
    lsof -i :$PORT 2>/dev/null | head -3 >> "$DIAG_FILE"
    if curl -s http://localhost:$PORT/api/squad > /dev/null 2>&1; then
        SQUAD_COUNT=$(curl -s http://localhost:$PORT/api/squad 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 'N/A')" 2>/dev/null)
        echo "✅ Backend porta $PORT: $SQUAD_COUNT especialistas" >> "$DIAG_FILE"
    else
        echo "❌ Backend porta $PORT: não responde" >> "$DIAG_FILE"
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### Frontend rodando?" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
for PORT in 3000 3001 3002; do
    if curl -s http://localhost:$PORT > /dev/null 2>&1; then
        echo "✅ Frontend porta $PORT: online" >> "$DIAG_FILE"
    else
        echo "❌ Frontend porta $PORT: offline" >> "$DIAG_FILE"
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### .env do Backend" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
for DIR in ~/titanio-dashboard/code/backend ~/titanio-dashboard/backend; do
    if [ -f "$DIR/.env" ]; then
        echo "Encontrado: $DIR/.env" >> "$DIAG_FILE"
        grep -v -iE "key|secret|token|password" "$DIR/.env" 2>/dev/null >> "$DIAG_FILE"
        # Verificar OWNER_ID
        OWNER=$(grep "OWNER_ID" "$DIR/.env" 2>/dev/null)
        if echo "$OWNER" | grep -q "tiago"; then
            echo "✅ OWNER_ID correto (tiago)" >> "$DIAG_FILE"
        else
            echo "⚠️ OWNER_ID pode estar errado: $OWNER" >> "$DIAG_FILE"
        fi
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### LaunchAgent Dashboard" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
ls ~/Library/LaunchAgents/com.titanio.* 2>/dev/null >> "$DIAG_FILE" || echo "⚠️ Nenhum LaunchAgent Titanio" >> "$DIAG_FILE"
launchctl list 2>/dev/null | grep -i titanio >> "$DIAG_FILE" || echo "⚠️ Nenhum LaunchAgent Titanio carregado" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 4. ESPECIALISTAS E MEMÓRIA

```bash
echo "## 4. ESPECIALISTAS E MEMÓRIA" >> "$DIAG_FILE"

echo "### Especialistas no disco" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
# Verificar onde estão
for DIR in ~/titanio-dashboard/memoria-especialistas ~/titanio-dashboard/code/backend/memoria-especialistas ~/.openclaw/workspace/memoria-especialistas ~/.openclaw/workspace/pasta-do-tita/memoria-especialistas; do
    if [ -d "$DIR" ]; then
        COUNT=$(ls -d "$DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
        echo "✅ $DIR: $COUNT especialistas" >> "$DIAG_FILE"
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### Shared JSONs" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
for F in /Volumes/TITA_039/shared-specialists.json /Volumes/TITA_039/shared-projects.json /Volumes/TITA_039/specialist-definitions.json; do
    if [ -f "$F" ]; then
        SIZE=$(ls -lh "$F" 2>/dev/null | awk '{print $5}')
        echo "✅ $F ($SIZE)" >> "$DIAG_FILE"
    else
        echo "❌ $F não encontrado" >> "$DIAG_FILE"
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### Memória do Claw" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
[ -f ~/.openclaw/workspace/MEMORY.md ] && echo "✅ MEMORY.md ($(wc -l < ~/.openclaw/workspace/MEMORY.md) linhas)" >> "$DIAG_FILE" || echo "❌ MEMORY.md não existe" >> "$DIAG_FILE"
[ -f ~/.openclaw/workspace/SOUL.md ] && echo "✅ SOUL.md" >> "$DIAG_FILE" || echo "❌ SOUL.md não existe" >> "$DIAG_FILE"
[ -f ~/.openclaw/workspace/USER.md ] && echo "✅ USER.md" >> "$DIAG_FILE" || echo "❌ USER.md não existe" >> "$DIAG_FILE"
[ -f ~/.openclaw/workspace/AGENTS.md ] && echo "✅ AGENTS.md" >> "$DIAG_FILE" || echo "❌ AGENTS.md não existe" >> "$DIAG_FILE"
[ -f ~/.openclaw/workspace/TOOLS.md ] && echo "✅ TOOLS.md" >> "$DIAG_FILE" || echo "❌ TOOLS.md não existe" >> "$DIAG_FILE"
[ -d ~/.openclaw/workspace/memory ] && echo "✅ memory/ ($(ls ~/.openclaw/workspace/memory/ 2>/dev/null | wc -l | tr -d ' ') arquivos)" >> "$DIAG_FILE" || echo "❌ memory/ não existe" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Learning System" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
if [ -d ~/.openclaw/workspace/tita-learning-system ]; then
    echo "✅ tita-learning-system/ existe" >> "$DIAG_FILE"
    [ -f ~/.openclaw/workspace/tita-learning-system/lessons.json ] && {
        LESSONS=$(python3 -c "import json; d=json.load(open('$HOME/.openclaw/workspace/tita-learning-system/lessons.json')); print(len(d.get('lessons',[])))" 2>/dev/null)
        echo "  Lições: $LESSONS" >> "$DIAG_FILE"
    } || echo "  ⚠️ lessons.json não existe" >> "$DIAG_FILE"
else
    echo "❌ tita-learning-system/ não existe" >> "$DIAG_FILE"
fi
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 5. TITANIO BROWSER

```bash
echo "## 5. TITANIO BROWSER" >> "$DIAG_FILE"

echo "### Playwright" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
python3 -c "import playwright; print('✅ Playwright instalado')" 2>/dev/null >> "$DIAG_FILE" || echo "❌ Playwright NÃO instalado" >> "$DIAG_FILE"
python3 -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    b.close()
    print('✅ Chromium funciona')
" 2>/dev/null >> "$DIAG_FILE" || echo "❌ Chromium NÃO funciona" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Scraper Tools" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
[ -x ~/.openclaw/workspace/bin/tita-scraper ] && echo "✅ tita-scraper" >> "$DIAG_FILE" || echo "❌ tita-scraper não encontrado" >> "$DIAG_FILE"
[ -x ~/.openclaw/workspace/bin/tita-browser-agent ] && echo "✅ tita-browser-agent" >> "$DIAG_FILE" || echo "❌ tita-browser-agent não encontrado" >> "$DIAG_FILE"
which tita-scraper > /dev/null 2>&1 && echo "✅ tita-scraper no PATH" >> "$DIAG_FILE" || echo "⚠️ tita-scraper não está no PATH" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Teste real de scraping" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
if [ -x ~/.openclaw/workspace/bin/tita-scraper ]; then
    RESULT=$(python3 ~/.openclaw/workspace/bin/tita-scraper "https://www.google.com" --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'OK: {d[\"title\"]} ({d[\"content_length\"]} chars)')" 2>/dev/null)
    if [ -n "$RESULT" ]; then
        echo "✅ Teste scraping: $RESULT" >> "$DIAG_FILE"
    else
        echo "❌ Teste scraping falhou" >> "$DIAG_FILE"
    fi
else
    echo "⚠️ Scraper não instalado — pular teste" >> "$DIAG_FILE"
fi
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 6. SERVIÇOS E PROCESSOS

```bash
echo "## 6. SERVIÇOS E PROCESSOS" >> "$DIAG_FILE"

echo "### PostgreSQL" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
pg_isready 2>/dev/null && echo "✅ PostgreSQL rodando" >> "$DIAG_FILE" || echo "❌ PostgreSQL não rodando" >> "$DIAG_FILE"
psql -l 2>/dev/null | grep titanio >> "$DIAG_FILE" || echo "⚠️ Nenhum banco titanio_*" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Redis" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
redis-cli ping 2>/dev/null | grep -q PONG && echo "✅ Redis PONG" >> "$DIAG_FILE" || echo "❌ Redis não responde" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### N8n" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
curl -s http://localhost:5678 > /dev/null 2>&1 && echo "✅ N8n porta 5678" >> "$DIAG_FILE" || echo "❌ N8n offline" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Ollama" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
curl -s http://localhost:11434/api/tags 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    models = [m['name'] for m in d.get('models',[])]
    print(f'✅ Ollama: {len(models)} modelos — {models[:5]}')
except:
    print('❌ Ollama não responde')
" 2>/dev/null >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Node.js & npm" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
echo "Node: $(node --version 2>/dev/null || echo 'N/A')" >> "$DIAG_FILE"
echo "npm: $(npm --version 2>/dev/null || echo 'N/A')" >> "$DIAG_FILE"
echo "Python: $(python3 --version 2>/dev/null || echo 'N/A')" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Git repos" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
for DIR in ~/titanio-dashboard ~/.openclaw/workspace; do
    if [ -d "$DIR/.git" ]; then
        BRANCH=$(cd "$DIR" && git branch --show-current 2>/dev/null)
        LAST=$(cd "$DIR" && git log --oneline -1 2>/dev/null)
        echo "✅ $DIR (branch: $BRANCH) — $LAST" >> "$DIAG_FILE"
    fi
done
echo '```' >> "$DIAG_FILE"

echo "### LaunchAgents ativos" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
launchctl list 2>/dev/null | grep -iE "titanio|openclaw|tita|n8n|postgres|redis|ollama" >> "$DIAG_FILE" || echo "Nenhum encontrado" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Processos relevantes" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
ps aux 2>/dev/null | grep -iE "node|python|n8n|ollama|redis|postgres|openclaw" | grep -v grep | awk '{print $11, $12, $13}' | sort -u >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 7. REDE E CONECTIVIDADE

```bash
echo "## 7. REDE E CONECTIVIDADE" >> "$DIAG_FILE"

echo "### IP local" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
ipconfig getifaddr en0 2>/dev/null >> "$DIAG_FILE" || echo "N/A" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Ping ao Gateway Eduardo (192.168.18.174)" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
ping -c 2 -t 3 192.168.18.174 2>/dev/null | tail -3 >> "$DIAG_FILE" || echo "❌ Sem resposta" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### Gateway OpenClaw central" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
curl -s -o /dev/null -w "HTTP %{http_code}" http://192.168.18.174:18789 2>/dev/null >> "$DIAG_FILE" || echo "❌ Gateway central não responde" >> "$DIAG_FILE"
echo "" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "### SSH habilitado?" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"
sudo systemsetup -getremotelogin 2>/dev/null >> "$DIAG_FILE" || echo "⚠️ Verificar manualmente: Preferências > Compartilhamento > Login Remoto" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
```

---

## 8. RESUMO E SCORE

```bash
echo "## 8. RESUMO DO DIAGNÓSTICO" >> "$DIAG_FILE"
echo "" >> "$DIAG_FILE"
echo "### Checklist Rápido" >> "$DIAG_FILE"
echo '```' >> "$DIAG_FILE"

SCORE=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    if eval "$2" > /dev/null 2>&1; then
        echo "✅ $1" >> "$DIAG_FILE"
        SCORE=$((SCORE + 1))
    else
        echo "❌ $1" >> "$DIAG_FILE"
    fi
}

check "OpenClaw instalado" "which openclaw"
check "OpenClaw gateway" "openclaw gateway status 2>&1 | grep -qi 'online\|running\|ok'"
check "Workspace existe" "[ -d ~/.openclaw/workspace ]"
check "SOUL.md" "[ -f ~/.openclaw/workspace/SOUL.md ]"
check "USER.md" "[ -f ~/.openclaw/workspace/USER.md ]"
check "MEMORY.md" "[ -f ~/.openclaw/workspace/MEMORY.md ]"
check "AGENTS.md" "[ -f ~/.openclaw/workspace/AGENTS.md ]"
check "Dashboard diretório" "[ -d ~/titanio-dashboard ]"
check "Backend rodando" "curl -s http://localhost:4444/api/squad > /dev/null 2>&1"
check "Frontend rodando" "curl -s http://localhost:3001 > /dev/null 2>&1 || curl -s http://localhost:3002 > /dev/null 2>&1"
check "PostgreSQL" "pg_isready"
check "Redis" "redis-cli ping 2>/dev/null | grep -q PONG"
check "Especialistas (disco)" "ls -d ~/titanio-dashboard/*/memoria-especialistas/*/ 2>/dev/null | head -1"
check "Learning system" "[ -d ~/.openclaw/workspace/tita-learning-system ]"
check "Playwright" "python3 -c 'import playwright' 2>/dev/null"
check "tita-scraper" "[ -x ~/.openclaw/workspace/bin/tita-scraper ]"
check "tita-browser-agent" "[ -x ~/.openclaw/workspace/bin/tita-browser-agent ]"
check "Git repo dashboard" "[ -d ~/titanio-dashboard/.git ]"
check "Gateway central acessível" "ping -c 1 -t 2 192.168.18.174"
check "OWNER_ID=tiago" "grep -q 'tiago' ~/titanio-dashboard/*/backend/.env 2>/dev/null || grep -q 'tiago' ~/titanio-dashboard/backend/.env 2>/dev/null"

echo "" >> "$DIAG_FILE"
PERCENT=$((SCORE * 100 / TOTAL))
echo "SCORE: $SCORE/$TOTAL ($PERCENT%)" >> "$DIAG_FILE"

if [ $PERCENT -ge 90 ]; then
    echo "GRADE: 🟢 A — Excelente" >> "$DIAG_FILE"
elif [ $PERCENT -ge 70 ]; then
    echo "GRADE: 🟡 B — Bom, precisa de ajustes" >> "$DIAG_FILE"
elif [ $PERCENT -ge 50 ]; then
    echo "GRADE: 🟠 C — Parcial, vários itens faltando" >> "$DIAG_FILE"
else
    echo "GRADE: 🔴 D — Precisa de setup urgente" >> "$DIAG_FILE"
fi
echo '```' >> "$DIAG_FILE"

echo "" >> "$DIAG_FILE"
echo "---" >> "$DIAG_FILE"
echo "*Diagnóstico gerado automaticamente em $DIAG_DATE*" >> "$DIAG_FILE"
echo "*Enviar este arquivo para a Tita (grupo Gospia ou sessão direta) para análise.*" >> "$DIAG_FILE"
```

---

## 9. FINALIZAR

```bash
echo ""
echo "========================================="
echo " DIAGNÓSTICO COMPLETO!"
echo "========================================="
echo " Arquivo: $DIAG_FILE"
echo " Linhas: $(wc -l < "$DIAG_FILE")"
echo "========================================="
echo ""
echo "⚡ PRÓXIMO PASSO: envie o arquivo $DIAG_FILE"
echo "   para o grupo Gospia ou para a Tita analisar."
echo ""
cat "$DIAG_FILE"
```

---

*Gerado por Tita — Time HiClaw — 02/04/2026*
