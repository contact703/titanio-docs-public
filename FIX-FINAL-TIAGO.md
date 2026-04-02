# 🔧 FIX FINAL — Dashboard Mac Mini Ilha (Tiago)

> Objetivo: 86% → 95%+ em ~17 minutos
> O Claw do Tiago deve executar TUDO sozinho, na ordem

---

## PASSO 1 — Redis (5 min)

```bash
# Garantir brew no PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Instalar
brew install redis

# Iniciar como serviço (sobrevive reboot)
brew services start redis

# Testar
redis-cli ping
# Esperado: PONG
```

Se `brew` não existir:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

---

## PASSO 2 — Descobrir onde está o Dashboard (2 min)

```bash
# Achar o código do dashboard
DASH_PATH=$(find /Volumes/TITA_039 /Users/titaniofilms_ilha -name "ecosystem.config.js" -path "*/titanio-dashboard/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)

# Se não encontrou ecosystem, procurar pelo backend
if [ -z "$DASH_PATH" ]; then
  DASH_PATH=$(find /Volumes/TITA_039 /Users/titaniofilms_ilha -name "index.ts" -path "*/titanio-dashboard/code/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
fi

# Se AINDA não encontrou, procurar pelo dist compilado
if [ -z "$DASH_PATH" ]; then
  DASH_PATH=$(find /Volumes/TITA_039 /Users/titaniofilms_ilha -name "index.js" -path "*/titanio-dashboard/*/dist/*" 2>/dev/null | head -1 | sed 's|/dist/index.js||' 2>/dev/null)
fi

echo "Dashboard encontrado em: $DASH_PATH"
```

Se nenhum caminho for encontrado, o Dashboard está rodando de outro lugar. Nesse caso:
```bash
# Achar o processo do backend
lsof -i :4444 | grep LISTEN
# O PID vai mostrar o caminho do processo
```

---

## PASSO 3 — Criar ecosystem.config.js (3 min)

```bash
# Usar o DASH_PATH encontrado no passo 2
# Se não encontrou, ajustar manualmente aqui:
# DASH_PATH="/caminho/correto/aqui"

cd "$DASH_PATH"

# Verificar se dist/index.js existe (backend compilado)
if [ ! -f "dist/index.js" ]; then
  echo "⚠️ Backend não compilado. Compilando..."
  npx tsc --outDir dist 2>/dev/null || echo "TypeScript não encontrado, tentando npm run build..."
  npm run build 2>/dev/null
fi

# Criar ecosystem.config.js
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'dashboard-backend',
      script: 'dist/index.js',
      cwd: __dirname,
      env: {
        NODE_ENV: 'production',
        PORT: 4444,
        SHARED_SPECIALISTS_PATH: '/Volumes/TITA_039/shared-specialists.json'
      },
      max_memory_restart: '800M',
      exp_backoff_restart_delay: 100,
      autorestart: true
    },
    {
      name: 'dashboard-frontend',
      script: 'node_modules/.bin/next',
      args: 'start -p 3000',
      cwd: __dirname,
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      max_memory_restart: '500M',
      autorestart: true
    }
  ]
};
EOF

echo "✅ ecosystem.config.js criado"
```

---

## PASSO 4 — Parar processos antigos e iniciar no PM2 (5 min)

```bash
cd "$DASH_PATH"

# Parar processos antigos rodando soltos na porta 4444 e 3000
kill $(lsof -t -i :4444) 2>/dev/null
kill $(lsof -t -i :3000) 2>/dev/null
sleep 2

# Build do frontend (se não existir .next/)
if [ ! -d ".next" ]; then
  echo "Building frontend..."
  npx next build
fi

# Iniciar com PM2
pm2 start ecosystem.config.js

# Esperar 5s e verificar
sleep 5
pm2 list

# Verificar se backend responde
curl -s http://localhost:4444/api/health | head -20
```

---

## PASSO 5 — Persistir no boot (2 min)

```bash
# Salvar estado atual do PM2
pm2 save

# Gerar script de startup (iniciar no boot do Mac)
pm2 startup
# ⚠️ PM2 vai mostrar um comando com sudo — EXECUTAR esse comando!
# Exemplo: sudo env PATH=$PATH:/usr/local/bin pm2 startup launchd -u titaniofilms_ilha --hp /Users/titaniofilms_ilha

# Salvar de novo após startup
pm2 save
```

---

## PASSO 6 — Validação final

```bash
echo "=== VALIDAÇÃO FINAL ==="

# 1. Redis
echo -n "Redis: "
redis-cli ping 2>/dev/null || echo "❌ OFFLINE"

# 2. PM2
echo ""
echo "PM2 processos:"
pm2 list

# 3. Backend
echo ""
echo -n "Backend (4444): "
curl -s http://localhost:4444/api/health | python3 -c "import sys,json; print('✅ OK' if json.load(sys.stdin) else '❌')" 2>/dev/null || echo "❌ OFFLINE"

# 4. Frontend
echo -n "Frontend (3000): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q 200 && echo "✅ OK" || echo "❌ OFFLINE"

# 5. Shared specialists
echo -n "Shared specialists: "
ls -lh /Volumes/TITA_039/shared-specialists.json | awk '{print $5}'

# 6. Endpoints
echo ""
echo "Endpoints:"
for ep in health squad bots projetos tasks relatorios sistema sentinelas notificacoes busca; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:4444/api/$ep")
  [ "$STATUS" = "200" ] && echo "  ✅ $ep" || echo "  ❌ $ep ($STATUS)"
done

echo ""
echo "=== RESULTADO ==="
echo "Se tudo acima está ✅: Score 95%+ 🎯"
echo "Mandar este output no grupo Gospia!"
```

---

## Checklist

- [ ] Redis instalado e PONG
- [ ] Backend no PM2 (dashboard-backend: online)
- [ ] Frontend no PM2 (dashboard-frontend: online)
- [ ] pm2 save + pm2 startup executados
- [ ] Todos endpoints ✅
- [ ] shared-specialists.json < 1MB (já limpo pela Tita)
- [ ] Output da validação enviado no grupo

*Gerado por Tita 🐾 — 2026-04-02*
