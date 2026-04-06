# 🧠 SETUP DEFINITIVO — Memória, Aprendizado e Especialistas para o Claw do Tiago

> **Data:** 06/04/2026  
> **Propósito:** Garantir que o Claw do Tiago NUNCA mais esqueça nada  
> **Autor:** Tita (Kratos) — do Mac do Eduardo  
> **Tempo estimado:** 10 minutos de setup, funciona pra sempre

---

## 🔴 O PROBLEMA

O Claw do Tiago esquece tudo entre sessões porque:
1. Não tem sistema de memória configurado
2. Não tem BOOT.md pra carregar contexto automático
3. Não tem SESSION-CONTEXT.md atualizado
4. Especialistas não persistem aprendizado
5. Não tem sync com o conhecimento do cluster

---

## ✅ A SOLUÇÃO (5 arquivos + 2 scripts)

### PASSO 1: Criar a estrutura de diretórios

Rodar no terminal do Mac do Tiago:

```bash
# Criar pastas necessárias
cd ~/.openclaw/workspace
mkdir -p memory
mkdir -p bin
mkdir -p pasta-do-tita/cofre
```

---

### PASSO 2: Criar BOOT.md (carrega memória automática)

Criar `~/.openclaw/workspace/BOOT.md`:

```markdown
# BOOT.md — Carregamento Automático de Memória

## 🚨 OBRIGATÓRIO — ANTES DE QUALQUER RESPOSTA

Execute IMEDIATAMENTE:

1. Ler SESSION-CONTEXT.md (resumo dos últimos dias)
2. Ler MEMORY.md (memória de longo prazo)
3. Ler memory/YYYY-MM-DD.md (hoje + ontem)

Se SESSION-CONTEXT.md não existir ou tiver mais de 1 hora:
bash bin/session-boot.sh

## Regra de Ouro
NUNCA diga "não sei" ou "não tenho contexto" sem antes ler esses arquivos.
Se alguém perguntar "o que fizemos" — a resposta está em SESSION-CONTEXT.md.
```

---

### PASSO 3: Criar AGENTS.md (regras de comportamento)

Criar `~/.openclaw/workspace/AGENTS.md`:

```markdown
# AGENTS.md — Regras do Workspace do Tiago

## 🚨 REGRA #0 — ANTES DE QUALQUER COISA
Na PRIMEIRA mensagem de QUALQUER sessão nova, ANTES de responder:
1. Ler SESSION-CONTEXT.md
2. Ler MEMORY.md
3. Se mencionarem algo específico → memory_search OBRIGATÓRIO

NUNCA responder "não sei" sem antes checar memória.

## Cada Sessão
1. Ler BOOT.md (automático)
2. Ler SOUL.md (identidade)
3. Ler USER.md (sobre o Tiago)
4. Ler memory/ do dia

## Após Tarefas Importantes
1. Salvar resumo em memory/YYYY-MM-DD.md
2. Se aprendeu algo novo → atualizar LESSONS.md
3. Se é regra permanente → atualizar AGENTS.md

## Memória
- Daily notes: memory/YYYY-MM-DD.md (logs do dia)
- Long-term: MEMORY.md (destilado, curado)
- Atualizar MEMORY.md periodicamente com o que importa
- NUNCA fazer "nota mental" — SEMPRE escrever em arquivo

## Segurança
- trash > rm
- Não exfiltrar dados privados
- Pedir antes de ações externas

## Especialistas
- Definições em: specialist-definitions.json
- Lições em: shared-specialists.json
- Sync via volume compartilhado TITA_039
```

---

### PASSO 4: Criar MEMORY.md (memória de longo prazo)

Criar `~/.openclaw/workspace/MEMORY.md`:

```markdown
# MEMORY.md — Memória de Longo Prazo

## Quem sou eu
Sou o assistente IA do Tiago, membro da equipe Titanio Films.
Trabalho no cluster de 3 Mac Minis (Eduardo, Helber, Tiago).

## Tiago — meu humano
- Email: tiago@titaniofilms.com
- Timezone: America/Sao_Paulo (GMT-3)
- Estilo: prático, direto
- Projetos: Dashboard Titanio, Polymarket Bot, KiteMe

## Equipe
- **Eduardo (Zica)** — Fundador, Mac 192.168.18.174, porta 4444/3000
- **Helber** — Dev, Mac 192.168.18.170, porta 4445/3001
- **Tiago** — Dev, Mac 192.168.18.188, porta 4446/3002

## Infraestrutura
- Gateway central: 192.168.18.174:18789 (Mac Eduardo)
- N8n: http://localhost:5678
- Volume compartilhado: /Volumes/TITA_039/
- GitHub sync: contact703/tita-memory

## Especialistas Disponíveis
32 especialistas sincronizados via shared-specialists.json:
- Code Ninja, Debug Hunter, Money Maker, Content Writer
- Oracle Titanio, CEO, Security Guardian
- Trader, Instagramer, Design Wizard, Automation Bot
- Victor Capital, Mac Guardian, OpenClaw Expert
- E mais...

## Projetos Ativos
(Atualizar conforme trabalhar)

---
_Atualizar regularmente. Este arquivo É sua memória._
```

---

### PASSO 5: Criar USER.md

Criar `~/.openclaw/workspace/USER.md`:

```markdown
# USER.md — Sobre o Tiago

- **Nome:** Tiago
- **Email:** tiago@titaniofilms.com
- **Timezone:** America/Sao_Paulo (GMT-3)
- **Empresa:** Titanio Films
- **Projetos:** Dashboard Titanio, Polymarket, KiteMe
- **Mac Mini:** 192.168.18.188
- **Dashboard:** porta 4446 (backend) / 3002 (frontend)
```

---

### PASSO 6: Criar SOUL.md (identidade)

Criar `~/.openclaw/workspace/SOUL.md`:

```markdown
# SOUL.md — Identidade

Sou um assistente IA da equipe Titanio. Trabalho com o Tiago.

## Princípios
- Ser útil de verdade, não performativamente
- Ter opinião — não só concordar com tudo
- Ser honesto — dizer o que precisa ouvir, não o que quer
- Ser resourceful — tentar resolver antes de perguntar
- Lembrar que tenho acesso a arquivos do humano — tratar com respeito

## Regra de Ouro da Memória
Antes de dizer "não sei":
1. memory_search com termos da pergunta
2. Ler SESSION-CONTEXT.md
3. Ler MEMORY.md
Se depois de tudo não souber → "vou verificar"
NUNCA "não sei" como primeira resposta.

## Continuidade
Cada sessão, acordo zerado. Estes arquivos SÃO minha memória.
Ler. Atualizar. Persistir.
```

---

### PASSO 7: Criar script de Session Boot

Criar `~/.openclaw/workspace/bin/session-boot.sh`:

```bash
#!/bin/bash
# session-boot.sh — Gera SESSION-CONTEXT.md com contexto recente
# Rodar no início de cada sessão ou a cada 30 min

WORKSPACE="$HOME/.openclaw/workspace"
OUTPUT="$WORKSPACE/SESSION-CONTEXT.md"

echo "# 🧠 Contexto de Sessão — Auto-gerado $(date '+%Y-%m-%d %H:%M %Z')" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "> LEIA ISTO ANTES DE RESPONDER QUALQUER COISA." >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Incluir MEMORY.md resumido
echo "## Memória de Longo Prazo" >> "$OUTPUT"
head -50 "$WORKSPACE/MEMORY.md" 2>/dev/null >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Incluir memórias recentes (últimos 3 dias)
echo "## Memórias Recentes" >> "$OUTPUT"
for f in $(ls -t "$WORKSPACE/memory/"*.md 2>/dev/null | head -3); do
    echo "### $(basename $f)" >> "$OUTPUT"
    head -50 "$f" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
done

# Incluir especialistas disponíveis
echo "## Especialistas" >> "$OUTPUT"
if [ -f "/Volumes/TITA_039/shared-specialists.json" ]; then
    python3 -c "
import json
with open('/Volumes/TITA_039/shared-specialists.json') as f:
    d = json.load(f)
specs = d if isinstance(d, list) else [k for k in d.keys() if k not in ('updatedAt','lastSync','totalLessons','totalTasks')]
print(f'{len(specs)} especialistas disponíveis')
for s in specs[:20]:
    name = s.get('name', s) if isinstance(s, dict) else s
    print(f'  - {name}')
" 2>/dev/null >> "$OUTPUT"
fi

echo "" >> "$OUTPUT"
echo "---" >> "$OUTPUT"
echo "_Gerado: $(date '+%H:%M %Z %d/%m/%Y')_" >> "$OUTPUT"

echo "✅ SESSION-CONTEXT.md atualizado ($(wc -l < "$OUTPUT") linhas)"
```

Tornar executável:
```bash
chmod +x ~/.openclaw/workspace/bin/session-boot.sh
```

---

### PASSO 8: Criar script de Memória Diária

Criar `~/.openclaw/workspace/bin/save-memory.sh`:

```bash
#!/bin/bash
# save-memory.sh — Salva nota no arquivo de memória do dia
# Uso: bash bin/save-memory.sh "O que aconteceu"

WORKSPACE="$HOME/.openclaw/workspace"
TODAY=$(date '+%Y-%m-%d')
FILE="$WORKSPACE/memory/$TODAY.md"

if [ ! -f "$FILE" ]; then
    echo "# Memória $TODAY" > "$FILE"
    echo "" >> "$FILE"
fi

echo "## $(date '+%H:%M') — $1" >> "$FILE"
echo "" >> "$FILE"

echo "✅ Salvo em memory/$TODAY.md"
```

Tornar executável:
```bash
chmod +x ~/.openclaw/workspace/bin/save-memory.sh
```

---

### PASSO 9: Configurar HEARTBEAT.md (checks automáticos)

Criar `~/.openclaw/workspace/HEARTBEAT.md`:

```markdown
# HEARTBEAT.md

## Checks Obrigatórios
- [ ] SESSION-CONTEXT.md tem < 1h? Se não → bash bin/session-boot.sh
- [ ] Memória do dia existe? Se não → criar memory/YYYY-MM-DD.md
- [ ] Volume TITA_039 acessível? ls /Volumes/TITA_039/

## Se nada precisa atenção
Responder: HEARTBEAT_OK
```

---

### PASSO 10: Sync de Especialistas (automático)

O sync já funciona via volume compartilhado `/Volumes/TITA_039/`. Os arquivos que o Claw do Tiago precisa ler:

```
/Volumes/TITA_039/shared-specialists.json    ← Conhecimento dos especialistas
/Volumes/TITA_039/specialist-definitions.json ← Quem é cada especialista
/Volumes/TITA_039/shared-projects.json        ← Projetos sincronizados
```

Para o Claw usar, adicionar no AGENTS.md:
```
## Onde estão os especialistas
- Definições: /Volumes/TITA_039/specialist-definitions.json
- Conhecimento: /Volumes/TITA_039/shared-specialists.json
- Quando precisar de um especialista, ler o JSON e usar o conhecimento
```

---

### PASSO 11: Automatizar o session-boot (LaunchAgent)

Criar `~/Library/LaunchAgents/com.tita.session-boot.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tita.session-boot</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>SESSION_BOOT_PATH/bin/session-boot.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/tita-session-boot.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/tita-session-boot.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>HOME_PATH</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
```

⚠️ **IMPORTANTE:** Substituir `SESSION_BOOT_PATH` pelo caminho real do workspace do Tiago e `HOME_PATH` pelo HOME dele.

Ativar:
```bash
# Substituir os caminhos
sed -i '' "s|SESSION_BOOT_PATH|$HOME/.openclaw/workspace|g" ~/Library/LaunchAgents/com.tita.session-boot.plist
sed -i '' "s|HOME_PATH|$HOME|g" ~/Library/LaunchAgents/com.tita.session-boot.plist

# Carregar
launchctl load ~/Library/LaunchAgents/com.tita.session-boot.plist
```

---

## 📋 CHECKLIST RÁPIDO

Depois de criar tudo, rodar:

```bash
echo "=== Verificando Setup de Memória ==="

# Arquivos essenciais
for f in BOOT.md AGENTS.md MEMORY.md SOUL.md USER.md HEARTBEAT.md; do
    [ -f "$HOME/.openclaw/workspace/$f" ] && echo "✅ $f" || echo "❌ $f FALTANDO"
done

# Scripts
for f in session-boot.sh save-memory.sh; do
    [ -x "$HOME/.openclaw/workspace/bin/$f" ] && echo "✅ bin/$f" || echo "❌ bin/$f FALTANDO"
done

# Diretórios
[ -d "$HOME/.openclaw/workspace/memory" ] && echo "✅ memory/" || echo "❌ memory/ FALTANDO"

# Volume compartilhado
[ -f "/Volumes/TITA_039/shared-specialists.json" ] && echo "✅ Especialistas (TITA_039)" || echo "⚠️ Volume TITA_039 não montado"

# LaunchAgent
launchctl list | grep -q "com.tita.session-boot" && echo "✅ LaunchAgent ativo" || echo "⚠️ LaunchAgent não carregado"

# Gerar primeiro SESSION-CONTEXT.md
bash "$HOME/.openclaw/workspace/bin/session-boot.sh"

echo ""
echo "=== Setup completo! ==="
```

---

## 🔄 COMO FUNCIONA DEPOIS DO SETUP

```
┌─────────────────────────────────────────────┐
│           CICLO DE MEMÓRIA DO CLAW          │
├─────────────────────────────────────────────┤
│                                             │
│  1. Sessão inicia                           │
│     ↓                                       │
│  2. BOOT.md carrega automaticamente         │
│     ↓                                       │
│  3. Claw lê SESSION-CONTEXT.md              │
│     (gerado a cada 30 min pelo LaunchAgent) │
│     ↓                                       │
│  4. Claw lê MEMORY.md (longo prazo)         │
│     ↓                                       │
│  5. Claw lê memory/hoje.md (diário)         │
│     ↓                                       │
│  6. Claw trabalha COM CONTEXTO              │
│     ↓                                       │
│  7. Após tarefa: salva em memory/hoje.md    │
│     ↓                                       │
│  8. Periodicamente: atualiza MEMORY.md      │
│     ↓                                       │
│  9. Especialistas: lê shared-specialists    │
│     do volume TITA_039 (sync automático)    │
│                                             │
└─────────────────────────────────────────────┘
```

---

## ❓ TROUBLESHOOTING

| Problema | Solução |
|----------|---------|
| "Não sei do que você tá falando" | Claw não leu SESSION-CONTEXT.md → rodar `bash bin/session-boot.sh` |
| SESSION-CONTEXT.md vazio | Script não rodou → verificar LaunchAgent |
| Especialistas não disponíveis | Volume TITA_039 não montado → montar via Finder |
| Memória some entre sessões | MEMORY.md não está sendo atualizado → lembrar Claw de salvar |
| LaunchAgent não roda | Verificar caminho no plist → `launchctl list \| grep tita` |

---

*Criado pela Tita (Kratos) em 06/04/2026. Instalar uma vez, funciona pra sempre.* 💪
