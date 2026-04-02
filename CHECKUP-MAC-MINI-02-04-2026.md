# 🔍 CHECKUP GERAL — Mac Mini Titanio
## Debug Hunter + Mac Specialist Report

**Data:** 02/04/2026 09:53 BRT
**Máquina:** Mac mini M4 (Apple M4, 10 cores, 16GB RAM)
**Uptime:** 1 dia 21h
**macOS:** Darwin 24.6.0 (arm64)

---

## 1. HARDWARE

### RAM (16GB)
- **Livre:** 137.983 pages (2.1GB)
- **Ativa:** 339.029 pages (5.2GB)
- **Inativa:** 297.620 pages (4.5GB)
- **Swap:** 110MB de 1GB usado
- **Veredicto:** 🟡 RAM sob pressão moderada — páginas livres OK mas Chrome consome muito

### Top consumidores RAM
| Processo | RAM | % |
|----------|-----|---|
| openclaw-gateway | 706MB | 4.3% |
| Google Chrome | 368MB | 2.2% |
| openclaw-tui | 343MB | 2.1% |
| Ollama | 341MB | 2.1% |
| next-server (Dashboard) | 320MB | 2.0% |
| Python (Polymarket monitor) | 240MB | 1.5% |
| Node (Dashboard backend) | 220MB | 1.3% |

**Chrome** está em 4 processos totais (~700MB). Se não estiver sendo usado, fechar libera memória significativa.

### Disco
| Volume | Total | Usado | Livre | % |
|--------|-------|-------|-------|---|
| / (SSD) | 228GB | 10GB | 39GB | 22% ✅ |
| TITA_039 (HD) | 11TB | 4.6TB | 6.3TB | 43% ✅ |

### CPU
- **Chip:** Apple M4
- **Cores:** 10
- **Load:** 1.27 / 1.43 / 1.51 (aceitável)
- **Veredicto:** ✅ CPU tranquila

---

## 2. SISTEMAS CORE

| Sistema | Status | Detalhes |
|---------|--------|----------|
| OpenClaw Gateway | ✅ ONLINE | v2026.3.11 (build 29dc654) — ⚠️ Config v2026.4.1 disponível |
| OpenClaw TUI | ✅ RODANDO | PID 7445 |
| Dashboard Backend | ✅ PORTA 4444 | 40 especialistas carregados |
| Dashboard Frontend | ✅ PORTA 3000 | Next.js dev server |
| Ollama | ✅ RODANDO | PID 53007 |
| caffeinate | ✅ ATIVO | Mac não dorme |
| memory-watchdog | ✅ ATIVO | PID 9460, log atualizado 09:00 |

### Offline/Parados
| Sistema | Status | Impacto |
|---------|--------|---------|
| PostgreSQL | ❌ OFF | Dashboard funciona sem ele (SQLite?) mas sync pode falhar |
| Redis | ❌ OFF | Cache e filas não funcionam |
| N8n | ❌ OFF | TODAS as 8+ automações paradas (auto-post, sync, relatórios) |

---

## 3. MEMÓRIA E ESPECIALISTAS

| Item | Status | Detalhes |
|------|--------|----------|
| SOUL.md | ✅ | 2.4KB |
| USER.md | ✅ | 753B |
| MEMORY.md | ✅ | 358 linhas (14.8KB) |
| AGENTS.md | ✅ | 11.9KB |
| TOOLS.md | ✅ | 959B |
| memory/ | ✅ | 113 arquivos |
| Especialistas | ✅ | 40 no backend |
| shared-specialists.json | ✅ | 155MB (sync TITA_039) |
| shared-projects.json | ✅ | 2.6KB |
| Memory Watchdog | ✅ | Consolidação rodando a cada hora |

---

## 4. AUTOMAÇÕES

| Automação | Status | Notas |
|-----------|--------|-------|
| Polymarket auto_trader | ✅ RODANDO | PID 21944 — mas sem saldo USDC (trades não executam) |
| Polymarket monitor | ✅ RODANDO | PID 22812 — scan a cada 5min, log ativo |
| Polymarket dashboard | ✅ RODANDO | PID 22814 |
| N8n workflows (8+) | ❌ N8n OFF | Auto-post, sync memória, relatórios — TUDO parado |
| Instagram auto-post | ❌ OFF | Dependia do N8n + Kimi/Moonshot (sem crédito) |
| Git auto-sync | ❌ OFF | Dependia do N8n |

---

## 5. LaunchAgents

| Agent | Status |
|-------|--------|
| ai.openclaw.gateway | ✅ Ativo |
| com.openclaw.caffeinate | ✅ Ativo |
| com.tita.memory.consolidate | ✅ Ativo |
| com.tita.memory.weekly | ✅ Ativo |
| com.tita.pocketbase | ✅ Ativo |
| com.titanio.n8n | ⚠️ Existe mas N8n offline |
| com.tita.polymarket-bot | ❌ Disabled (.disabled) |
| com.titanio.polymarket.bot | ❌ Disabled (.disabled) |

---

## 6. PROBLEMAS ENCONTRADOS E RESOLVIDOS

### ✅ RESOLVIDO — Mensagem "You have new mail" no terminal
- **Causa:** Cron job antigo `switch-to-opus-19h.sh` (deletado do /tmp) rodava todo dia 19h e falhava
- **Fix:** Cron removido. Emails (4 acumulados) limpos. Agora só tem o cron de restart do gateway (domingo 4h).

### ⚠️ PRECISA AÇÃO — PostgreSQL e Redis offline
- Dashboard funciona mas sync e cache não
- **Fix:** `brew services start postgresql@16 && brew services start redis`

### ⚠️ PRECISA AÇÃO — N8n offline
- Todas as automações (auto-post, sync, relatórios) paradas
- **Fix:** `brew services start n8n` ou `cd ~/.n8n && n8n start`

### ⚠️ PRECISA AÇÃO — OpenClaw desatualizado
- Instalado: v2026.3.11
- Config escrita por: v2026.4.1
- **Fix:** `openclaw update` (pode precisar de sudo)

### 🟡 ALERTA — Chrome consumindo 700MB
- 4 processos Chrome ativos
- Se não está usando, fechar libera ~700MB RAM

### 🟡 ALERTA — Bots Instagram offline
- Moonshot/Kimi sem crédito
- Instagram auto-post depende de N8n que está offline

---

## 7. SCORE GERAL

```
SISTEMAS CORE:       7/10 ✅ (gateway, dashboard, ollama, watchdog OK)
MEMÓRIA/DADOS:      10/10 ✅ (tudo íntegro, 40 especialistas, 155MB sync)
AUTOMAÇÃO:           3/10 ⚠️ (N8n off = maioria das automações paradas)
HARDWARE:            8/10 ✅ (RAM ok, disco ok, CPU ok)
SEGURANÇA:           7/10 🟡 (caffeinate ok, watchdog ok, mas Redis/Postgres off)

SCORE GERAL: 7/10 — BOM, mas precisa ligar N8n + Redis + PostgreSQL
```

---

## 8. AÇÕES RECOMENDADAS (prioridade)

| # | Ação | Impacto | Comando |
|---|------|---------|---------|
| 1 | Ligar PostgreSQL | Alto | `brew services start postgresql@16` |
| 2 | Ligar Redis | Alto | `brew services start redis` |
| 3 | Ligar N8n | Crítico | `brew services start n8n` ou LaunchAgent |
| 4 | Update OpenClaw | Médio | `openclaw update` |
| 5 | Fechar Chrome | Médio | Se não estiver usando — libera 700MB RAM |
| 6 | Recarregar Kimi/Moonshot | Baixo | Para reativar bots Instagram |

---

*Relatório gerado por Debug Hunter + Mac Specialist — Time HiClaw*
*02/04/2026 09:53 BRT*
