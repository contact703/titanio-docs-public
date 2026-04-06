# 🚀 PROPOSTA: Dashboard Comercial Autônomo Titanio

> **Para:** Squad Gospia (Zica, Helber, Tiago)  
> **De:** Tita (Kratos)  
> **Data:** 06/04/2026  
> **Objetivo:** Dashboard comercial que carrega agentes e automação, SEM depender do Claude nem do OpenClaw

---

## 🎯 O QUE QUEREMOS

Um sistema que consiga:
1. **Postar em redes sociais** (Instagram, LinkedIn, Twitter, TikTok)
2. **Rodar tráfego pago** (Meta Ads, Google Ads)
3. **Cuidar de finanças** (NFS-e, cobranças, relatórios)
4. **Comunicação interna** (Slack/Discord/WhatsApp interno)
5. **Funcionar OFFLINE** do Claude/OpenClaw (modelos locais ou APIs alternativas)
6. **Ser online** (acessível de qualquer lugar)

---

## 🏗️ 3 ARQUITETURAS PROPOSTAS

### **OPÇÃO A: "Titanio Stack" (100% Nossa, Máxima Flexibilidade)**

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Next.js)                       │
│  Dashboard React · Chat Interface · Painel Financeiro       │
│  Porta: 3000 (público via Cloudflare Tunnel / Tailscale)    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Express + TypeScript)           │
│  API REST · WebSocket · Task Manager · Auth JWT             │
│  Porta: 4444                                                │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐    ┌────────▼────────┐   ┌───────▼───────┐
│   OLLAMA      │    │      N8N        │   │   POSTGRES    │
│ LLM Local     │    │  Workflows      │   │   Database    │
│ Qwen2.5 32B   │    │  22+ automações │   │   + Redis     │
│ Porta: 11434  │    │  Porta: 5678    │   │  Porta: 5432  │
└───────────────┘    └─────────────────┘   └───────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐    ┌────────▼────────┐   ┌───────▼───────┐
│  INSTAGRAPI   │    │   META ADS API  │   │   SEFIN API   │
│  Posts IG     │    │   Tráfego Pago  │   │   NFS-e       │
└───────────────┘    └─────────────────┘   └───────────────┘
```

**PRÓS:**
- 100% controle total
- Zero dependência externa (funciona offline)
- Já temos 80% construído (Dashboard Titanio atual)
- Custo: ~R$50-100/mês (VPS + domínio)

**CONTRAS:**
- Precisa manter infraestrutura
- Updates de segurança são nossa responsabilidade
- Setup inicial mais complexo

**MODELOS LLM (sem Claude):**
- Ollama local: Qwen2.5 32B, Llama 3.1 70B, Mistral
- APIs alternativas: Groq (grátis), Together AI, DeepSeek, OpenRouter
- Google: Gemini 1.5 Flash (barato)

---

### **OPÇÃO B: "Dify + N8n" (Low-Code, Rápido Deploy)**

```
┌─────────────────────────────────────────────────────────────┐
│                    DIFY.AI (Self-Hosted)                    │
│  Builder Visual de Agentes · RAG · Workflows Visuais        │
│  Porta: 3000                                                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    N8N (Automações)                         │
│  Triggers · APIs · Webhooks · Scheduling                    │
│  Porta: 5678                                                │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐    ┌────────▼────────┐   ┌───────▼───────┐
│ OLLAMA/Groq   │    │    POSTGRES     │   │    REDIS      │
│ (Multi-model) │    │    + Vector DB  │   │    Cache      │
└───────────────┘    └─────────────────┘   └───────────────┘
```

**O QUE É DIFY:**
- Plataforma open-source para criar agentes IA
- Interface visual drag-and-drop
- RAG nativo (documentos → conhecimento)
- Suporta 20+ providers LLM (Ollama, Groq, OpenAI, etc)
- Self-hosted ou cloud
- GitHub: 50k+ stars

**PRÓS:**
- Setup em 2 horas (Docker compose)
- Interface amigável para não-devs
- RAG pronto (sobe PDF e IA aprende)
- Multi-tenant (vários clientes/projetos)

**CONTRAS:**
- Menos flexível que código custom
- Docker pesado (~4GB RAM)
- Dependência de framework externo

**STACK:**
```bash
# Deploy completo
docker compose up -d dify n8n postgres redis ollama
```

---

### **OPÇÃO C: "Coolify + Modular" (PaaS Self-Hosted)**

```
┌─────────────────────────────────────────────────────────────┐
│                    COOLIFY (Self-Hosted PaaS)               │
│  Deploy automático · SSL · Domínios · Monitoramento         │
│  Substitui Railway/Vercel/Heroku                            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐    ┌────────▼────────┐   ┌───────▼───────┐
│  APP CUSTOM   │    │   POCKETBASE    │   │  N8N          │
│  (Next.js)    │    │   Backend+Auth  │   │  Automations  │
│  Dashboard UI │    │   1 arquivo     │   │  Workflows    │
└───────────────┘    └─────────────────┘   └───────────────┘
```

**O QUE É COOLIFY:**
- PaaS self-hosted (como Railway mas grátis)
- Deploy via Git push
- SSL automático
- Monitoramento incluído
- GitHub: 35k+ stars

**O QUE É POCKETBASE:**
- Backend completo em 1 arquivo
- Auth + Database + API + Realtime
- Zero config
- Perfeito para MVPs
- GitHub: 40k+ stars

**PRÓS:**
- Setup tipo Heroku mas self-hosted
- Escalável
- Custo mínimo (só VPS)
- Deploy em 1 clique

**CONTRAS:**
- Precisa VPS com 4GB+ RAM
- Curva de aprendizado Coolify

---

## 📊 COMPARATIVO DAS 3 OPÇÕES

| Critério | Opção A (Titanio Stack) | Opção B (Dify + N8n) | Opção C (Coolify) |
|----------|------------------------|---------------------|-------------------|
| **Setup** | 4-8h | 2-4h | 3-6h |
| **Flexibilidade** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Facilidade** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **RAM Mínima** | 4GB | 8GB | 4GB |
| **Custo/mês** | R$50-100 | R$80-150 | R$50-100 |
| **Manutenção** | Média | Baixa | Baixa |
| **Já temos** | 80% | 30% | 10% |
| **Escala** | Manual | Automática | Automática |
| **Multi-tenant** | Custom | Nativo | Custom |

---

## 🧠 MODELOS LLM (Sem Claude/OpenClaw)

### **Gratuitos ou Muito Baratos:**

| Modelo | Onde | Custo | Qualidade |
|--------|------|-------|-----------|
| **Qwen2.5 32B** | Ollama local | R$0 | ⭐⭐⭐⭐ |
| **Llama 3.1 70B** | Ollama local | R$0 | ⭐⭐⭐⭐⭐ |
| **Groq (Llama 3.3 70B)** | API | R$0 (rate limited) | ⭐⭐⭐⭐⭐ |
| **DeepSeek V3** | API | ~R$1/1M tokens | ⭐⭐⭐⭐⭐ |
| **Gemini 1.5 Flash** | API | ~R$5/1M tokens | ⭐⭐⭐⭐ |
| **Mistral Large** | API | ~R$10/1M tokens | ⭐⭐⭐⭐ |

### **Estratégia Recomendada:**
```
Tarefas simples → Groq grátis (com fallback)
Tarefas médias → Qwen local / DeepSeek
Tarefas complexas → Llama 3.1 70B local / Gemini
```

---

## 🔧 MÓDULOS DO SISTEMA

### **1. Módulo Social (Posts)**
```
Instagram → instagrapi (Python, já temos)
LinkedIn → linkedin-api (Python)
Twitter/X → tweepy (Python)
TikTok → tiktok-uploader (Python)
```

**N8n Workflows:**
- `social-scheduler`: agenda posts da semana
- `content-generator`: IA gera posts do tema
- `media-processor`: redimensiona/otimiza mídia

### **2. Módulo Ads (Tráfego Pago)**
```
Meta Ads → facebook-ads-python
Google Ads → google-ads-python
Analytics → GA4 API
```

**N8n Workflows:**
- `campaign-creator`: cria campanhas via API
- `budget-optimizer`: ajusta budget por performance
- `report-daily`: relatório diário de gastos/ROI

### **3. Módulo Financeiro**
```
NFS-e → Manda a Nota (nosso!) ou APIs municipais
Cobranças → Stripe/MercadoPago
Relatórios → Planilhas + PDF
```

**N8n Workflows:**
- `invoice-auto`: emite NFS-e automático
- `payment-tracker`: monitora pagamentos
- `finance-report`: relatório semanal

### **4. Módulo Comunicação**
```
Slack → Slack API
Discord → discord.py
WhatsApp Interno → Evolution API (self-hosted)
Email → Nodemailer + Gmail/Resend
```

**N8n Workflows:**
- `team-notifier`: avisa time de eventos
- `client-update`: atualiza clientes automaticamente
- `escalation`: escala problemas urgentes

---

## 🌐 ACESSO ONLINE (Exposição Segura)

### **Opção 1: Cloudflare Tunnel (Recomendada)**
```bash
# Instala
brew install cloudflared

# Conecta
cloudflared tunnel --url http://localhost:3000
```
- Zero custo
- SSL automático
- DDoS protection
- URL tipo: `https://dashboard.titanio.studio`

### **Opção 2: Tailscale (Time Interno)**
```bash
# Já temos instalado
tailscale up
# Acessa via: http://mac-mini-eduardo:3000
```
- Só time interno acessa
- VPN mesh automática
- Zero config firewall

### **Opção 3: VPS Dedicada**
```
Hetzner: €4/mês (4GB RAM)
DigitalOcean: $6/mês (1GB RAM)
Vultr: $5/mês (1GB RAM)
```

---

## 📋 PLANO DE IMPLEMENTAÇÃO

### **Semana 1: Core**
- [ ] Decidir arquitetura (A, B ou C)
- [ ] Setup base (Docker/PM2)
- [ ] Auth + Multi-tenant
- [ ] Dashboard UI base

### **Semana 2: Agentes**
- [ ] Conectar Ollama/Groq
- [ ] Criar 5 agentes iniciais
- [ ] Interface de chat
- [ ] Histórico de conversas

### **Semana 3: Automações**
- [ ] Módulo Social (Instagram primeiro)
- [ ] Módulo Financeiro (NFS-e)
- [ ] N8n workflows principais
- [ ] Scheduler de tarefas

### **Semana 4: Polish**
- [ ] Módulo Ads (Meta primeiro)
- [ ] Relatórios PDF
- [ ] Exposição online (Cloudflare)
- [ ] Documentação completa

---

## 💰 CUSTO ESTIMADO

### **Setup Inicial:**
| Item | Custo |
|------|-------|
| VPS Hetzner 4GB | €4/mês (~R$25) |
| Domínio .studio | R$50/ano |
| SSL | Grátis (Cloudflare) |
| **Total Setup** | ~R$100 |

### **Operação Mensal:**
| Item | Custo |
|------|-------|
| VPS | R$25/mês |
| APIs LLM (Groq + DeepSeek) | R$20-50/mês |
| Meta Ads API | Grátis |
| Google Ads API | Grátis |
| **Total Mensal** | R$45-75/mês |

---

## 🎯 MINHA RECOMENDAÇÃO

**OPÇÃO A (Titanio Stack)** + **Elementos da B (Dify para RAG)**

**Por quê:**
1. Já temos 80% construído
2. Controle total sobre o código
3. Podemos usar Dify só pro RAG (conhecimento)
4. Custo mais baixo
5. Não ficamos dependentes de nenhum framework

**Próximo passo imediato:**
1. Squad aprova arquitetura
2. Eu monto o MVP em 48h
3. Testamos com 1 cliente real (H2O Films?)
4. Iteramos baseado em feedback

---

## 📎 ANEXOS

### Links Úteis:
- Dify: https://github.com/langgenius/dify
- Coolify: https://github.com/coollabsio/coolify
- PocketBase: https://github.com/pocketbase/pocketbase
- Evolution API (WhatsApp): https://github.com/EvolutionAPI/evolution-api
- Ollama: https://ollama.ai

### Já Temos Pronto:
- Dashboard Titanio v2.0 (Next.js + Express)
- 30 especialistas treinados
- 22 workflows N8n
- instagrapi funcionando
- Manda a Nota (NFS-e)
- Paperclip (orquestrador)

---

**Próxima ação:** Zica/Helber/Tiago escolhem arquitetura no HiClaw e a gente começa a construir!

---
*Gerado por Tita (Kratos) — 06/04/2026 14:05 BRT*
