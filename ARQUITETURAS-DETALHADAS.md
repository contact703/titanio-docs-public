# 🏗️ ARQUITETURAS DETALHADAS — Dashboard Comercial Autônomo

> Documento técnico complementar à proposta principal
> Squad: Zica, Helber, Tiago | Data: 06/04/2026

---

## ARQUITETURA A: "TITANIO STACK" (RECOMENDADA)

### Visão Geral
```
                    ┌─────────────────────────────────────┐
                    │         CLOUDFLARE TUNNEL           │
                    │    dashboard.titanio.studio:443     │
                    └──────────────────┬──────────────────┘
                                       │ HTTPS
                    ┌──────────────────▼──────────────────┐
                    │            NGINX PROXY              │
                    │         (Load Balancer)             │
                    │            Porta: 80/443            │
                    └──────────────────┬──────────────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
┌──────────▼──────────┐   ┌────────────▼────────────┐   ┌──────────▼──────────┐
│   FRONTEND          │   │      BACKEND            │   │     N8N             │
│   Next.js 14        │   │      Express.js         │   │     Workflows       │
│   Porta: 3000       │   │      Porta: 4444        │   │     Porta: 5678     │
│                     │   │                         │   │                     │
│   • Dashboard UI    │   │   • REST API            │   │   • 22 workflows    │
│   • Chat Agentes    │   │   • WebSocket           │   │   • Schedulers      │
│   • Finanças        │   │   • Auth JWT            │   │   • Webhooks        │
│   • Social Manager  │   │   • Task Queue          │   │   • Integrações     │
│   • Ads Panel       │   │   • File Upload         │   │   • Triggers        │
└─────────────────────┘   └────────────┬────────────┘   └──────────┬──────────┘
                                       │                           │
                    ┌──────────────────┼───────────────────────────┤
                    │                  │                           │
         ┌──────────▼──────────┐  ┌────▼────┐  ┌───────────────────▼───────────┐
         │    POSTGRESQL       │  │  REDIS  │  │          OLLAMA               │
         │    Porta: 5432      │  │  :6379  │  │        Porta: 11434           │
         │                     │  │         │  │                               │
         │  • users            │  │ • cache │  │  • Qwen2.5 32B (default)      │
         │  • specialists      │  │ • queue │  │  • Llama 3.1 70B (complex)    │
         │  • tasks            │  │ • sess  │  │  • Mistral 7B (fast)          │
         │  • finances         │  └─────────┘  │  • nomic-embed (embeddings)   │
         │  • social_posts     │               │                               │
         │  • campaigns        │               │  RAM: ~16GB para 32B          │
         └─────────────────────┘               └───────────────────────────────┘
```

### Fluxo de Dados — Exemplo: Post Instagram
```
1. [USER] Clica "Criar Post" no Dashboard
   │
   ▼
2. [FRONTEND] POST /api/social/create
   │
   ▼
3. [BACKEND] Valida auth, cria task
   │
   ▼
4. [OLLAMA] Gera texto do post (Qwen2.5)
   │
   ▼
5. [BACKEND] Salva draft no Postgres
   │
   ▼
6. [N8N] Workflow "social-scheduler" agenda
   │
   ▼
7. [N8N] No horário: chama instagrapi
   │
   ▼
8. [INSTAGRAM] Post publicado
   │
   ▼
9. [BACKEND] Atualiza status, notifica user
```

### Estrutura de Diretórios
```
titanio-dashboard-comercial/
├── frontend/                    # Next.js 14
│   ├── app/
│   │   ├── (auth)/             # Login, registro
│   │   ├── (dashboard)/        # Painel principal
│   │   │   ├── agents/         # Chat com agentes
│   │   │   ├── social/         # Gestão social media
│   │   │   ├── ads/            # Campanhas ads
│   │   │   ├── finance/        # NFS-e, cobranças
│   │   │   └── settings/       # Configurações
│   │   └── api/                # API routes Next
│   ├── components/
│   │   ├── chat/               # Interface de chat
│   │   ├── social/             # Cards de posts
│   │   └── finance/            # Tabelas financeiras
│   └── lib/
│       ├── ollama.ts           # Cliente Ollama
│       └── auth.ts             # JWT helpers
│
├── backend/                     # Express.js
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.ts
│   │   │   ├── agents.ts
│   │   │   ├── social.ts
│   │   │   ├── ads.ts
│   │   │   └── finance.ts
│   │   ├── services/
│   │   │   ├── OllamaService.ts
│   │   │   ├── InstagramService.ts
│   │   │   ├── MetaAdsService.ts
│   │   │   └── NFSeService.ts
│   │   └── workers/
│   │       ├── socialWorker.ts
│   │       └── financeWorker.ts
│   └── prisma/
│       └── schema.prisma
│
├── n8n-workflows/               # Workflows exportados
│   ├── social-scheduler.json
│   ├── content-generator.json
│   ├── campaign-optimizer.json
│   └── finance-reporter.json
│
├── scripts/
│   ├── setup.sh                # Setup inicial
│   ├── deploy.sh               # Deploy produção
│   └── backup.sh               # Backup diário
│
├── docker-compose.yml          # Dev environment
├── docker-compose.prod.yml     # Prod environment
└── README.md
```

### Schema do Banco (Prisma)
```prisma
model User {
  id            String   @id @default(cuid())
  email         String   @unique
  name          String
  password      String
  role          Role     @default(USER)
  organization  Organization @relation(fields: [orgId], references: [id])
  orgId         String
  createdAt     DateTime @default(now())
}

model Organization {
  id            String   @id @default(cuid())
  name          String
  plan          Plan     @default(STARTER)
  users         User[]
  agents        Agent[]
  socialAccounts SocialAccount[]
  campaigns     Campaign[]
  invoices      Invoice[]
}

model Agent {
  id            String   @id @default(cuid())
  name          String
  systemPrompt  String   @db.Text
  model         String   @default("qwen2.5:32b")
  temperature   Float    @default(0.7)
  organization  Organization @relation(fields: [orgId], references: [id])
  orgId         String
  conversations Conversation[]
}

model SocialAccount {
  id            String   @id @default(cuid())
  platform      Platform
  username      String
  accessToken   String   @db.Text
  organization  Organization @relation(fields: [orgId], references: [id])
  orgId         String
  posts         SocialPost[]
}

model SocialPost {
  id            String   @id @default(cuid())
  content       String   @db.Text
  mediaUrl      String?
  status        PostStatus @default(DRAFT)
  scheduledFor  DateTime?
  publishedAt   DateTime?
  account       SocialAccount @relation(fields: [accountId], references: [id])
  accountId     String
}

model Campaign {
  id            String   @id @default(cuid())
  name          String
  platform      AdPlatform
  budget        Float
  status        CampaignStatus @default(DRAFT)
  startDate     DateTime
  endDate       DateTime
  organization  Organization @relation(fields: [orgId], references: [id])
  orgId         String
}

model Invoice {
  id            String   @id @default(cuid())
  number        String   @unique
  amount        Float
  status        InvoiceStatus @default(PENDING)
  nfseNumber    String?
  organization  Organization @relation(fields: [orgId], references: [id])
  orgId         String
  createdAt     DateTime @default(now())
}

enum Role { USER ADMIN OWNER }
enum Plan { STARTER PRO ENTERPRISE }
enum Platform { INSTAGRAM LINKEDIN TWITTER TIKTOK }
enum PostStatus { DRAFT SCHEDULED PUBLISHED FAILED }
enum AdPlatform { META GOOGLE TIKTOK }
enum CampaignStatus { DRAFT ACTIVE PAUSED ENDED }
enum InvoiceStatus { PENDING PAID CANCELLED }
```

---

## ARQUITETURA B: "DIFY + N8N"

### Visão Geral
```
                    ┌─────────────────────────────────────┐
                    │            DIFY (Open Source)       │
                    │         Porta: 80 (Docker)          │
                    │                                     │
                    │   ┌─────────────────────────────┐   │
                    │   │     AGENT BUILDER UI        │   │
                    │   │  • Drag-and-drop workflows  │   │
                    │   │  • RAG (Knowledge Base)     │   │
                    │   │  • Multi-model support      │   │
                    │   └─────────────────────────────┘   │
                    │                                     │
                    │   ┌─────────────────────────────┐   │
                    │   │         API SERVER          │   │
                    │   │  • /v1/chat-messages        │   │
                    │   │  • /v1/completion-messages  │   │
                    │   │  • /v1/files               │   │
                    │   └─────────────────────────────┘   │
                    │                                     │
                    │   ┌──────────┐  ┌──────────────┐   │
                    │   │ POSTGRES │  │    REDIS     │   │
                    │   │ (interno)│  │  (interno)   │   │
                    │   └──────────┘  └──────────────┘   │
                    └────────────────────┬────────────────┘
                                         │
              ┌──────────────────────────┼──────────────────────────┐
              │                          │                          │
   ┌──────────▼──────────┐    ┌──────────▼──────────┐    ┌──────────▼──────────┐
   │       OLLAMA        │    │         N8N         │    │     CUSTOM API      │
   │    (Local LLM)      │    │    (Automations)    │    │  (Express mini)     │
   │    Porta: 11434     │    │    Porta: 5678      │    │    Porta: 4444      │
   │                     │    │                     │    │                     │
   │  • Qwen2.5          │    │  • Social triggers  │    │  • Webhooks         │
   │  • Llama 3.1        │    │  • Finance crons    │    │  • Meta Ads calls   │
   │  • Embeddings       │    │  • Notifications    │    │  • NFS-e emissão    │
   └─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### Docker Compose (Dify)
```yaml
version: '3.8'
services:
  # Dify - API Server
  api:
    image: langgenius/dify-api:0.6.11
    restart: always
    environment:
      - MODE=api
      - SECRET_KEY=${SECRET_KEY}
      - DB_USERNAME=postgres
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - db
      - redis

  # Dify - Worker
  worker:
    image: langgenius/dify-api:0.6.11
    restart: always
    environment:
      - MODE=worker
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - api

  # Dify - Web UI
  web:
    image: langgenius/dify-web:0.6.11
    restart: always
    environment:
      - CONSOLE_API_URL=http://api:5001
    ports:
      - "3000:3000"

  # PostgreSQL
  db:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=dify
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Redis
  redis:
    image: redis:7-alpine
    restart: always
    volumes:
      - redis_data:/data

  # N8n
  n8n:
    image: n8nio/n8n
    restart: always
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n

  # Ollama (se quiser local)
  ollama:
    image: ollama/ollama
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama

volumes:
  postgres_data:
  redis_data:
  n8n_data:
  ollama_models:
```

### Fluxo — Criar Agente no Dify
```
1. Acessa Dify UI (localhost:3000)
2. Cria novo "Agent" ou "Chatflow"
3. Configura:
   - System Prompt
   - Model (Ollama/OpenAI/etc)
   - Tools (APIs externas)
   - Knowledge Base (PDFs, docs)
4. Publica
5. Usa API:
   
   curl -X POST 'http://localhost:3000/v1/chat-messages' \
     -H 'Authorization: Bearer {api_key}' \
     -H 'Content-Type: application/json' \
     -d '{
       "query": "Crie um post sobre IA",
       "user": "user123"
     }'
```

---

## ARQUITETURA C: "COOLIFY + POCKETBASE"

### Visão Geral
```
┌───────────────────────────────────────────────────────────────────┐
│                         COOLIFY                                   │
│              (Self-Hosted PaaS - como Railway)                    │
│                        Porta: 3000                                │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │                    PROJECTS                              │    │
│   │                                                          │    │
│   │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │    │
│   │   │ Dashboard    │  │  PocketBase  │  │     N8n      │  │    │
│   │   │ (Next.js)    │  │  (Backend)   │  │ (Workflows)  │  │    │
│   │   │              │  │              │  │              │  │    │
│   │   │ dashboard.   │  │ api.titanio  │  │ n8n.titanio  │  │    │
│   │   │ titanio.     │  │ .studio      │  │ .studio      │  │    │
│   │   │ studio       │  │              │  │              │  │    │
│   │   └──────────────┘  └──────────────┘  └──────────────┘  │    │
│   │                                                          │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │                    DATABASES                             │    │
│   │                                                          │    │
│   │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │    │
│   │   │  PostgreSQL  │  │    Redis     │  │   Ollama     │  │    │
│   │   │   :5432      │  │    :6379     │  │   :11434     │  │    │
│   │   └──────────────┘  └──────────────┘  └──────────────┘  │    │
│   │                                                          │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│   • SSL Automático (Let's Encrypt)                               │
│   • Deploy via Git Push                                          │
│   • Backups automáticos                                          │
│   • Monitoramento incluído                                       │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### PocketBase como Backend
```go
// PocketBase é 1 arquivo executável que inclui:
// - REST API automática
// - Realtime subscriptions
// - Auth (email, OAuth, etc)
// - Admin dashboard
// - File storage
// - Migrations

// Download: ~15MB
// Execução: ./pocketbase serve --http=0.0.0.0:8090

// Collections (via Admin UI ou API):
// - users (auth collection)
// - organizations
// - agents
// - social_posts
// - campaigns
// - invoices

// API automática:
// GET    /api/collections/agents/records
// POST   /api/collections/agents/records
// PATCH  /api/collections/agents/records/:id
// DELETE /api/collections/agents/records/:id

// Realtime:
// pb.collection('social_posts').subscribe('*', (e) => {
//   console.log(e.action, e.record)
// })
```

---

## 📊 DECISÃO: QUAL ESCOLHER?

### Se o Squad quer...

| Objetivo | Melhor Opção |
|----------|--------------|
| **Controle total + já temos código** | A (Titanio Stack) |
| **Setup mais rápido, aceita Docker pesado** | B (Dify + N8n) |
| **Facilidade de deploy + escalabilidade** | C (Coolify) |
| **RAG poderoso (documentos)** | B (Dify nativo) ou A+Dify |
| **Multi-tenant para clientes** | B ou C |
| **Menor custo operacional** | A |
| **Time não-técnico precisa criar agentes** | B (visual) |

### Minha Recomendação Final:

**OPÇÃO A + Elementos de B**

```
Titanio Stack (nosso código) 
  + Dify apenas para RAG/Knowledge Base
  + N8n para automações
  + Ollama para LLM local
```

Isso nos dá:
- ✅ Controle total do código principal
- ✅ RAG pronto via Dify (não reinventar)
- ✅ Automações poderosas via N8n (já dominamos)
- ✅ Zero custo de API LLM (Ollama local)
- ✅ 80% do código já existe no Dashboard atual

---

## 🚀 PRÓXIMOS PASSOS

1. **AGORA:** Squad escolhe arquitetura no HiClaw
2. **24h:** Setup inicial do ambiente
3. **48h:** MVP com 1 agente + 1 integração social
4. **1 semana:** Sistema completo funcionando

**Quem faz o quê:**
- Tita: Backend + Integrações + LLM
- Helber: Ajustes frontend?
- Tiago: Testes + N8n workflows?
- Zica: Validação + Feedback

---

*Documento técnico — Tita (Kratos) — 06/04/2026*
