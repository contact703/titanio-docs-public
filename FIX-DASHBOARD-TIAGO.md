# 🔧 Fix Dashboard — Mac Mini Ilha (Tiago)

> Score atual: 86% → Meta: 95%+
> Gerado por Tita 🐾 em 2026-04-02

---

## Diagnóstico

| Item | Status | Ação |
|------|--------|------|
| Backend/Frontend no PM2 | ❌ Fora do PM2 | Adicionar |
| shared-specialists.json | ⚠️ 52MB (inflado) | Substituir pela versão limpa (0.3MB) |
| Redis | ⚠️ Offline | Instalar e iniciar |
| Memória local especialistas | ❌ 0 dirs | Criar estrutura |
| Modelo | ⚠️ Sonnet | OK pra sessão, mas confirmar default |

---

## PASSO 1 — Instalar Redis

```bash
brew install redis
brew services start redis

# Testar
redis-cli ping
# Deve responder: PONG
```

---

## PASSO 2 — Limpar shared-specialists.json (52MB → 0.3MB)

O arquivo atual tem 527K lições duplicadas. Rodar este script pra limpar:

```bash
SHARED="/Volumes/TITA_039/shared-specialists.json"

# Backup primeiro
cp "$SHARED" "$SHARED.bak-$(date +%Y%m%d)"

# Limpar duplicatas
python3 -c "
import json

with open('$SHARED') as f:
    data = json.load(f)

cleaned = 0
for spec in data.get('specialists', []):
    if 'lessons' in spec:
        original = len(spec['lessons'])
        # Remover duplicatas mantendo ordem
        seen = set()
        unique = []
        for lesson in spec['lessons']:
            key = lesson.get('content', lesson.get('lesson', str(lesson)))
            if key not in seen:
                seen.add(key)
                unique.append(lesson)
        spec['lessons'] = unique
        cleaned += original - len(unique)

with open('$SHARED', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f'Removidas {cleaned} lições duplicadas')
print(f'Arquivo agora: {len(json.dumps(data))//1024}KB')
"
```

---

## PASSO 3 — Colocar Backend e Frontend no PM2

### 3.1. Descobrir onde está o código
```bash
# Procurar o dashboard
find /Volumes/TITA_039 -name "ecosystem.config.js" -maxdepth 5 2>/dev/null
# OU
find /Users/titaniofilms_ilha -name "ecosystem.config.js" -maxdepth 5 2>/dev/null
```

### 3.2. Criar ecosystem.config.js (se não existir)
```bash
# Ajustar DASHBOARD_PATH pro caminho real na máquina do Tiago
DASHBOARD_PATH="/caminho/do/titanio-dashboard/code"

cat > "$DASHBOARD_PATH/ecosystem.config.js" << 'EOF'
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
      exp_backoff_restart_delay: 100
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
      max_memory_restart: '500M'
    }
  ]
};
EOF
```

### 3.3. Compilar e iniciar
```bash
cd "$DASHBOARD_PATH"

# Compilar TypeScript (backend)
npx tsc --outDir dist

# Build frontend
npx next build

# Iniciar com PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Pra iniciar no boot
```

---

## PASSO 4 — Criar estrutura de memória local

```bash
MEMORIA_PATH="/Users/titaniofilms_ilha/.openclaw/workspace/pasta-do-tita/memoria-especialistas"

# Criar dirs pra cada especialista
for spec in ceo oracle-titanio code-ninja marketing-pro content-writer money-maker debug-hunter design-wizard api-master data-guardian; do
  mkdir -p "$MEMORIA_PATH/$spec"
  echo '[]' > "$MEMORIA_PATH/$spec/lessons.json"
  echo '{"conversations":[],"insights":[]}' > "$MEMORIA_PATH/$spec/memory.json"
  echo "✅ $spec"
done

echo "Estrutura criada!"
```

---

## PASSO 5 — Validar (rodar diagnóstico de novo)

```bash
# Checar PM2
pm2 list

# Checar Redis
redis-cli ping

# Checar endpoints
curl -s http://localhost:4444/api/health | python3 -m json.tool
curl -s http://localhost:4444/api/squad | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d)} especialistas')"

# Checar shared-specialists tamanho
ls -lh /Volumes/TITA_039/shared-specialists.json

# Score esperado: 95%+
```

---

## Checklist Final

- [ ] Redis instalado e rodando (PONG)
- [ ] shared-specialists.json < 1MB
- [ ] Backend no PM2 (dashboard-backend: online)
- [ ] Frontend no PM2 (dashboard-frontend: online)
- [ ] Memória local criada (10+ dirs)
- [ ] Todos endpoints respondendo
- [ ] `pm2 save` + `pm2 startup` executados

Depois de tudo, roda o diagnóstico de novo e manda o score aqui! Meta: 95%+ 🎯

---

*Gerado por Tita 🐾 — 2026-04-02*
