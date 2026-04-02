# 🕷️ HiClaw — Plano Técnico Consolidado: Monteiro Aranha
## Como Vamos Construir Tudo

**Data:** 02/04/2026
**Squad:** Code Ninja + Security Guard + DevOps Ninja + API Master
**Status:** Análise completa — pronto para implementação

---

## PARTE 1 — ARQUITETURA TÉCNICA (Code Ninja)

# 🏗️ Stack Técnica Completa: Monteiro Aranha — Relatório de Execução

Vou projetar e entregar a arquitetura técnica completa com código executável e diagramas.

---

## 1. ARQUITETURA GERAL (Diagrama ASCII)

```
┌─────────────────────────────────────────────────────────────────┐
│                      MONTEIRO ARANHA STACK                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   FRONTEND       │
│  Next.js 14      │
│  - White-label   │
│  - Design System │
│  - Chat UI       │
└────────┬─────────┘
         │ REST/WebSocket
         │
┌────────▼──────────────────────────────────────────────────────┐
│                    API GATEWAY & AUTH                         │
│              (Express + JWT + Rate Limiting)                  │
└────────┬──────────────────────────────────────────────────────┘
         │
    ┌────┴────────────────────────────────┐
    │                                     │
┌───▼──────────────┐        ┌───────────┴──────────────┐
│   CORE API       │        │   IA ENGINE              │
│ - Express REST   │        │ ┌──────────────────────┐ │
│ - Controllers    │        │ │ Ollama (Local)       │ │
│ - Services       │        │ │ - Embeddings         │ │
│ - Middleware     │        │ │ - Small Models       │ │
└───┬──────────────┘        │ └──────────┬───────────┘ │
    │                       │            │             │
    │                       │ ┌──────────▼───────────┐ │
    │                       │ │ Claude API (Remote)  │ │
    │                       │ │ - Complex Tasks      │ │
    │                       │ │ - Reasoning          │ │
    │                       │ └──────────────────────┘ │
    │                       └──────────────────────────┘
    │
    ├──────────────────────────────────┐
    │                                  │
┌───▼──────────────┐        ┌─────────┴──────────┐
│    DATABASE      │        │  CACHE LAYER       │
│  PostgreSQL      │        │  Redis             │
│  - Users         │        │  - Sessions        │
│  - Specialists   │        │  - AI responses    │
│  - Audit Log     │        │  - Rate limits     │
│  - Documents     │        │  - Approvals Queue │
└──────────────────┘        └────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│             WHATSAPP GATEWAY (Approval Layer)                │
│  - Twilio/WhatsApp Cloud API                                 │
│  - Human approval workflow                                   │
│  - Audit trail                                               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    3 MODOS OPERACIONAIS                       │
│                                                               │
│  NORMAL → All features | RESTRITO → Limited | CONFIDENCIAL → │
│  Only approved users, full audit, encryption, 2FA            │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│           ESPECIALISTAS DIGITAIS (AI Agents)                 │
│  CEO | RI | Jurídico | Finanças | Marketing | Design        │
│         (Cada um com contexto + fine-tuning)                 │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. ESTRUTURA DE PASTAS DO PROJETO

```
monteiro-aranha/
├── frontend/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── dashboard/
│   │   ├── chat/
│   │   └── admin/
│   ├── components/
│   │   ├── design-system/
│   │   ├── chat/
│   │   └── specialists/
│   ├── lib/
│   │   ├── api-client.ts
│   │   ├── auth.ts
│   │   └── modes.ts
│   └── package.json
│
├── backend/
│   ├── src/
│   │   ├── main.ts (Express app)
│   │   ├── auth/
│   │   │   ├── jwt.ts
│   │   │   └── middleware.ts
│   │   ├── controllers/
│   │   │   ├── chat.controller.ts
│   │   │   ├── specialist.controller.ts
│   │   │   └── admin.controller.ts
│   │   ├── services/
│   │   │   ├── ai.service.ts (Ollama + Claude)
│   │   │   ├── specialist.service.ts
│   │   │   ├── whatsapp.service.ts
│   │   │   └── mode.service.ts
│   │   ├── models/
│   │   │   ├── user.model.ts
│   │   │   ├── specialist.model.ts
│   │   │   └── audit.model.ts
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts
│   │   │   ├── mode-enforcement.middleware.ts
│   │   │   └── audit.middleware.ts
│   │   ├── db/
│   │   │   ├── postgres.ts
│   │   │   └── migrations/
│   │   └── config/
│   │       └── env.ts
│   └── package.json
│
├── ai-engine/
│   ├── ollama/
│   │   ├── models.ts
│   │   └── embeddings.ts
│   ├── claude/
│   │   └── client.ts
│   ├── specialists/
│   │   ├── ceo-agent.ts
│   │   ├── ri-agent.ts
│   │   ├── juridico-agent.ts
│   │   ├── financas-agent.ts
│   │   ├── marketing-agent.ts
│   │   └── design-agent.ts
│   └── training/
│       └── fine-tuning.ts
│
├── whatsapp-gateway/
│   ├── twilio-client.ts
│   ├── approval-workflow.ts
│   └── audit-trail.ts
│
└── docker-compose.yml
```

---

## 3. CÓDIGO: SETUP INICIAL (Backend)

### 3.1 Express + Database

```typescript
// backend/src/main.ts
import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import redis from 'redis';
import jwt from 'jsonwebtoken';

dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3001;

// ==================== DATABASE ====================
export const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// ==================== REDIS ====================
export const redisClient = redis.createClient({
  url: process.env.REDIS_URL
---

## PARTE 2 — SEGURANÇA E CÓDIGO (Security Guard)

# Monteiro Aranha — Modo Confidencial + Tokenização + Audit Trail | Execução

---

## 📋 Análise do Requisito

Lendo `PLANO-SEGURANCA-MONTEIRO-ARANHA.md` para extrair contexto...

**Requisitos extraídos:**
1. ✅ Modo Confidencial (sessão efêmera, contexto destruído)
2. ✅ Middleware de Tokenização (dados sensíveis → tokens opacos)
3. ✅ Audit Trail com Hash Chain (imutável, auditável)
4. ✅ IA não persiste em lessons.json durante modo confidencial
5. ✅ Log apenas registra existência (não conteúdo)

---

## 🔨 EXECUÇÃO — Código Funcional TypeScript

### 1️⃣ **Sistema de Tokenização (tokenizer.ts)**

```typescript
// src/security/tokenizer.ts
import crypto from 'crypto';

interface TokenMap {
  [token: string]: {
    value: string;
    createdAt: number;
    expiresAt: number;
    category: 'pii' | 'credential' | 'payment' | 'secret';
  };
}

export class DataTokenizer {
  private tokenMap: TokenMap = {};
  private tokenTTL = 3600000; // 1 hora em ms
  private readonly SENSITIVE_PATTERNS = {
    email: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
    cpf: /\d{3}\.\d{3}\.\d{3}-\d{2}/g,
    creditCard: /\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}/g,
    apiKey: /api[_-]?key[\s:=]+[a-zA-Z0-9-_]{32,}/gi,
    jwt: /eyJhbGciOi[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g,
    password: /password[\s:=]+[^\s,}]+/gi,
    phoneNumber: /\(?[0-9]{2}\)?[\s-]?[0-9]{4,5}[\s-]?[0-9]{4}/g,
  };

  /**
   * Gera um token opaco para um valor sensível
   */
  generateToken(value: string, category: 'pii' | 'credential' | 'payment' | 'secret'): string {
    const token = `TOK_${crypto.randomBytes(16).toString('hex').toUpperCase()}`;
    const now = Date.now();

    this.tokenMap[token] = {
      value,
      createdAt: now,
      expiresAt: now + this.tokenTTL,
      category,
    };

    // Auto-cleanup em background
    setTimeout(() => this.revokeToken(token), this.tokenTTL);

    return token;
  }

  /**
   * Detects e tokeniza dados sensíveis automaticamente
   */
  tokenizeContent(content: string): { tokenized: string; tokens: Map<string, string> } {
    const tokens = new Map<string, string>();
    let tokenized = content;

    // Email
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.email, (match) => {
      const token = this.generateToken(match, 'pii');
      tokens.set(token, 'email');
      return token;
    });

    // CPF
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.cpf, (match) => {
      const token = this.generateToken(match, 'pii');
      tokens.set(token, 'cpf');
      return token;
    });

    // Cartão de Crédito
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.creditCard, (match) => {
      const token = this.generateToken(match, 'payment');
      tokens.set(token, 'card');
      return token;
    });

    // API Keys
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.apiKey, (match) => {
      const token = this.generateToken(match, 'secret');
      tokens.set(token, 'apiKey');
      return token;
    });

    // JWT
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.jwt, (match) => {
      const token = this.generateToken(match, 'credential');
      tokens.set(token, 'jwt');
      return token;
    });

    // Passwords
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.password, (match) => {
      const token = this.generateToken(match, 'credential');
      tokens.set(token, 'password');
      return token;
    });

    // Phone Numbers
    tokenized = tokenized.replace(this.SENSITIVE_PATTERNS.phoneNumber, (match) => {
      const token = this.generateToken(match, 'pii');
      tokens.set(token, 'phone');
      return token;
    });

    return { tokenized, tokens };
  }

  /**
   * Revoga um token (torna irrecuperável)
   */
  revokeToken(token: string): boolean {
    if (this.tokenMap[token]) {
      delete this.tokenMap[token];
      return true;
    }
    return false;
  }

  /**
   * Recupera valor apenas com acesso explícito (audit trail ativado)
   */
  detokenize(token: string, auditLog: AuditLogger): string | null {
    const entry = this.tokenMap[token];

    if (!entry) {
      auditLog.logTokenAccess(token, 'REVOKED', 'token not found');
      return null;
    }

    if (entry.expiresAt < Date.now()) {
      auditLog.logTokenAccess(token, 'EXPIRED', entry.category);
      delete this.tokenMap[token];
      return null;
    }

    auditLog.logTokenAccess(token, 'SUCCESS', entry.category);
    return entry.value;
  }

  /**
   * Status do tokenizer (para monitoramento)
   */
  getStatus(): { activeTokens: number; categories: Record<string, number> } {
    const categories: Record<string, number> = {
      pii: 0,
      credential: 0,
      payment: 0,
      secret: 0,
    };

    Object.values(this.tokenMap).forEach((entry) => {
      if (entry.expiresAt > Date.now()) {
        categories[entry.category]++;
      }
    });

    return {
      activeTokens: Object.keys(this.tokenMap).length,
      categories,
    };
  }

  /**
   * Limpa TODOS os tokens (usado ao finalizar sessão confidencial)
   */
  purgeAll(): void {
    this.tokenMap = {};
  }
}

// Singleton global
export const tokenizer = new DataTokenizer();
```

---

### 2️⃣ **Audit Trail com Hash Chain (auditLogger.ts)**

```typescript
// src/security/auditLogger.ts
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

interface AuditEntry {
  timestamp: number;
  action: string;
  actor: string;
  resource: string;
  status: 'SUCCESS' | 'FAILED' | 'BLOCKED' | 'REVOKED' | 'EXPIRED';
  metadata: Record<string, any>;
  hash: string;
  previousHash: string
---

## PARTE 3 — INFRAESTRUTURA E DEPLOY (DevOps Ninja)

# Monteiro Aranha — Docker Compose Completo + Scripts de Deploy

Lendo contexto primeiro conforme lição aprendida.

```bash
📖 Verificando documentação
```

Carregando: MA-BRIEFING.md, PLANO-IMPLEMENTACAO-FERRAMENTAS.md, PLANO-SEGURANCA-MONTEIRO-ARANHA.md

---

## EXECUÇÃO: Docker Compose + Scripts de Deploy

Vou criar a infraestrutura **completa e pronta para produção** com todos os serviços, volumes persistentes, healthchecks, redes isoladas e scripts de backup/instalação.

### 1️⃣ **DOCKER COMPOSE COMPLETO**

```yaml
# /docker-compose.yml (Monteiro Aranha Production)

version: '3.9'

services:
  # ============================================
  # DATABASE LAYER
  # ============================================
  
  postgresql:
    image: postgres:16-alpine
    container_name: ma-postgresql
    environment:
      POSTGRES_USER: ${DB_USER:-ma_user}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-change_me_in_production}
      POSTGRES_DB: ${DB_NAME:-monteiro_aranha}
      POSTGRES_INITDB_ARGS: "-c max_connections=200 -c shared_buffers=256MB"
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d
    ports:
      - "${DB_PORT:-5432}:5432"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-ma_user}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    image: redis:7-alpine
    container_name: ma-redis
    command: redis-server --appendonly yes --appendfsync everysec --maxmemory ${REDIS_MAX_MEMORY:-512mb} --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "${REDIS_PORT:-6379}:6379"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ============================================
  # AI & LLM LAYER
  # ============================================

  ollama:
    image: ollama/ollama:latest
    container_name: ma-ollama
    environment:
      OLLAMA_HOST: 0.0.0.0:11434
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "${OLLAMA_PORT:-11434}:11434"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 16G
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"

  # ============================================
  # APPLICATION LAYER
  # ============================================

  app-backend:
    build:
      context: ./services/backend
      dockerfile: Dockerfile
    container_name: ma-app-backend
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      DB_HOST: postgresql
      DB_PORT: 5432
      DB_USER: ${DB_USER:-ma_user}
      DB_PASSWORD: ${DB_PASSWORD:-change_me_in_production}
      DB_NAME: ${DB_NAME:-monteiro_aranha}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      OLLAMA_HOST: http://ollama:11434
      JWT_SECRET: ${JWT_SECRET:-generate_secure_key}
      API_PORT: ${API_PORT:-3000}
      LOG_LEVEL: ${LOG_LEVEL:-info}
    depends_on:
      postgresql:
        condition: service_healthy
      redis:
        condition: service_healthy
      ollama:
        condition: service_healthy
    volumes:
      - ./services/backend:/app
      - /app/node_modules
      - backend_logs:/app/logs
    ports:
      - "${API_PORT:-3000}:3000"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "5"

  app-frontend:
    build:
      context: ./services/frontend
      dockerfile: Dockerfile
    container_name: ma-app-frontend
    environment:
      REACT_APP_API_URL: ${REACT_APP_API_URL:-http://localhost:3000}
      REACT_APP_ENV: ${NODE_ENV:-production}
    depends_on:
      - app-backend
    volumes:
      - ./services/frontend:/app
      - /app/node_modules
      - frontend_build:/app/build
    ports:
      - "${FRONTEND_PORT:-3001}:80"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "5"

  # ============================================
  # MESSAGING & GATEWAY LAYER
  # ============================================

  whatsapp-gateway:
    build:
      context: ./services/whatsapp-gateway
      dockerfile: Dockerfile
    container_name: ma-whatsapp-gateway
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      WHATSAPP_API_KEY: ${WHATSAPP_API_KEY:-}
      WHATSAPP_PHONE_ID: ${WHATSAPP_PHONE_ID:-}
      BACKEND_URL: http://app-backend:3000
      GATEWAY_PORT: ${GATEWAY_PORT:-8080}
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      app-backend:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./services/whatsapp-gateway:/app
      - /app/node_modules
      - gateway_logs:/app/logs
    ports:
      - "${GATEWAY_PORT:-8080}:8080"
    networks:
      - ma-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-
---

## PARTE 4 — INTEGRAÇÕES E APIs (API Master)

# Projeto Monteiro Aranha — Arquitetura Completa de Integrações & APIs

Vou projetar a stack de integrações do zero. Lendo contexto do projeto primeiro.

---

## 📋 Análise Preliminar

Consultando documentos da biblioteca:

```bash
cat PLANO-SEGURANCA-MONTEIRO-ARANHA.md
cat MA-BRIEFING.md
cat ARQUITETURA-DASHBOARD-CLIENTES.md
```

**Premissas do projeto:**
- Monteiro Aranha: empresa de segurança com acionistas, múltiplos sistemas legados
- Necessidade de canal seguro para acionistas (WhatsApp)
- SSO corporativo (Active Directory)
- API REST para app mobile/web
- Sistema de webhooks para notificações em tempo real
- Integração com ERP/CRM existentes
- Sistema de aprendizado para automatizar tarefas

---

## 🏗️ ARQUITETURA PROPOSTA

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONTEIRO ARANHA — STACK                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   WhatsApp   │  │      AD      │  │   App CLI    │            │
│  │   Business   │  │    (SSO)     │  │    (OAuth)   │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                 │                 │                     │
│         └─────────────────┼─────────────────┘                     │
│                           │                                       │
│                    ┌──────▼────────┐                             │
│                    │   API Gateway  │  (auth, rate limit, log)   │
│                    │  (Kong/Traefik)│                            │
│                    └──────┬─────────┘                             │
│                           │                                       │
│  ┌────────────────────────┼────────────────────────┐             │
│  │                        │                        │             │
│  ▼                        ▼                        ▼             │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│ │  Core APIs   │  │  Webhook     │  │  Learning    │            │
│ │  (REST)      │  │  System      │  │  Engine      │            │
│ │  • Acionistas│  │  • Events    │  │  • Tasks     │            │
│ │  • Usuarios  │  │  • Notifs    │  │  • Training  │            │
│ │  • Audit     │  │  • Integration  │  • Model    │            │
│ └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│        │                 │                 │                     │
│        └─────────────────┼─────────────────┘                     │
│                          │                                        │
│              ┌───────────┴───────────┐                            │
│              │                       │                            │
│              ▼                       ▼                            │
│      ┌──────────────┐      ┌──────────────┐                     │
│      │  Adapters    │      │  PostgreSQL  │                     │
│      │  (ERP/CRM)   │      │  + Redis     │                     │
│      │  • SAP       │      │  (cache)     │                     │
│      │  • Salesforce│      │              │                     │
│      │  • Custom    │      │              │                     │
│      └──────────────┘      └──────────────┘                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

# 1️⃣ INTEGRAÇÃO WHATSAPP BUSINESS API — Fluxo Completo

## OpenAPI Spec

```yaml
# ma-whatsapp-api.openapi.yaml
openapi: 3.0.0
info:
  title: Monteiro Aranha WhatsApp Business API
  version: 1.0.0
  description: Canal seguro para acionistas via WhatsApp
servers:
  - url: https://api.monteiro-aranha.com/v1/whatsapp
    description: Production

paths:
  /messages:
    post:
      summary: Enviar mensagem a acionista
      operationId: sendMessageToShareholder
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                phone:
                  type: string
                  pattern: '^\+\d{10,15}$'
                  example: '+5585987654321'
                message:
                  type: string
                  minLength: 1
                  maxLength: 4096
                template_id:
                  type: string
                  description: Usar templates pré-aprovados pela Meta
                  enum:
                    - SHAREHOLDER_UPDATE
                    - DIVIDEND_NOTICE
                    - MEETING_REMINDER
                    - EMERGENCY_ALERT
                media:
                  type: object
                  properties:
                    type:
                      enum: [image, document, video]
                    url:
                      type: string
                      format: uri
                context_id:
                  type: string
                  description: ID da mensagem que está respondendo
              required:
                - phone
              oneOf:
                - required: [message]
                - required: [template_id]
      responses:
        '202':
          description: Mensagem aceita para envio
          content:
            application/json:
              schema:
                type: object
                properties:
                  message_id:
                    type: string
                  status:
                    type: string
                    enum: [queued, sent, delivered, failed]
                  timestamp:
                    type: string
                    format: date-time
        '400':
          description: Request inválido
        '401':
          description: Não autenticado
        '429':
          description: Rate limit excedido

  /messages/{message_id}:
    get:
      summary: Status de mensagem
      operationId: getMessageStatus
      security:
        - bearerAuth: []
      parameters:
        - name: message_id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Status atual
          content:
            application/json:
              schema:
                type: object
                properties:
                  message_id:
                    type: string
                  status:
                    enum: [queued, sent, delivered, read, failed]
                  delivery_timestamp:
                    type: string
                    format: date-time
                  error:
                    type: object
                    properties:
                      code:
                        type: string
                      message:
                        type: string

  /templates:
    get:
      summary: Lista templates pré-aprovados
      operationId: listTemplates
      security:
        - bearerAuth: []
      responses:
        '200':
          description: Lista de templates
          content:
            application/json:
              schema:
                type: object
                properties:
                  templates:
                    type: array
                    items:
                      type: object
                      properties:
                        template_id:
                          type: string
---
*Documento consolidado pelo HiClaw — Titanio Studio — 02/04/2026*
