# 🔧 Pesquisa: Ferramentas Open-Source para Titanio Studio
**Data:** 02/04/2026  
**Contexto:** Mac Mini M4 como servidor, já temos N8n + OpenClaw  
**Critério:** Open-source, licença comercial ok, self-hosted, acesso remoto

---

## 📊 RESUMO RÁPIDO — TOP PICKS POR CATEGORIA

| Categoria | Recomendado | Motivo |
|-----------|-------------|--------|
| Process Manager | **PM2** | Já funciona, referência da indústria |
| Workflow Automation | **Activepieces** | Visual igual Zapier, MCP nativo, TS |
| Self-hosted PaaS | **Coolify** | Mais fácil que CapRover, deploy 1-click |
| Monitoring | **Uptime Kuma** + **Netdata** | Um pra uptime, outro pra infra |
| Message Queue | **BullMQ** | Node.js nativo, Redis, rápido |
| Scheduling | **Temporal** | Durable execution, enterprise-grade |
| Containers | **OrbStack** | O melhor pra macOS, ponto final |
| Remote Access | **Tailscale** + **CF Tunnel** | Dupla imbatível |
| Database | **PocketBase** | 1 binário, backend completo |
| AI Agents | **Dify** | Visual + API, complementa OpenClaw |

---

## 1. PROCESS MANAGERS

### PM2
- **GitHub:** https://github.com/Unitech/pm2
- **Licença:** AGPL-3.0
- **Stars:** ~41k ⭐
- **O que faz:** Process manager para Node.js e qualquer processo. Mantém apps vivos, auto-restart, load balancer, logs, monit dashboard.
- **macOS Apple Silicon:** ✅ Estável (mencionado explicitamente no repo)
- **Instalação:**
  ```bash
  npm install pm2 -g
  pm2 start app.js
  ```
- **Prós:** Battle-tested, roda qualquer linguagem (Node, Python, Ruby, binários), cluster mode, zero-downtime reload, monit via web ou terminal
- **Contras:** AGPL (cuidado em SaaS), UI web paga (Keymetrics), não é container-aware
- **Serve pro nosso caso:** ✅ SIM — já é padrão para manter processos vivos no macOS sem systemd. OpenClaw provavelmente já usa.

### Monit
- **GitHub:** https://bitbucket.org/tildeslash/monit
- **Licença:** AGPL-3.0
- **Stars:** N/A (não é GitHub)
- **O que faz:** Monitoring e management de processos Unix. Auto-restart, alertas, web dashboard simples.
- **macOS Apple Silicon:** ✅ Disponível via Homebrew
- **Instalação:**
  ```bash
  brew install monit
  monit -c ~/.monitrc
  ```
- **Prós:** Leve, sem dependências, watch de CPU/memória por processo
- **Contras:** UI antiga, configuração verbose
- **Serve pro nosso caso:** ⚠️ PARCIAL — útil como watchdog complementar ao PM2

### Supervisor
- **GitHub:** https://github.com/Supervisor/supervisor
- **Licença:** BSD-derived (uso comercial ok)
- **Stars:** ~8k ⭐
- **O que faz:** Sistema de controle de processos Unix, similar ao PM2 mas para Python.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  pip install supervisor
  supervisord -c supervisord.conf
  ```
- **Prós:** Estável, simples, bom pra Python
- **Contras:** Python-centric, UI web básica, sem clustering
- **Serve pro nosso caso:** ⚠️ PARCIAL — só se tiver processos Python pra gerenciar

---

## 2. WORKFLOW AUTOMATION

### Activepieces ⭐ RECOMENDADO
- **GitHub:** https://github.com/activepieces/activepieces
- **Licença:** MIT (self-hosted) + Enterprise edition
- **Stars:** ~12k+ ⭐
- **O que faz:** Alternativa open-source ao Zapier/Make. 280+ integrações prontas. Interface visual drag-and-drop. Suporte nativo a MCP servers — todas as integrações ficam disponíveis como ferramentas para LLMs (Claude Desktop, Cursor, etc).
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  curl -s https://raw.githubusercontent.com/activepieces/activepieces/main/deploy.sh | bash
  # ou via Docker Compose
  docker compose up -d
  ```
- **Prós:** Código em TypeScript (familiar), 280+ conectores, MCP nativo, comunidade ativa, interface mais moderna que N8n, AI-first
- **Contras:** Mais novo que N8n, menos templates/community flows
- **Serve pro nosso caso:** ✅ SIM MUITO — Complementa N8n. Os 280+ conectores MCP são killer feature para integrar com OpenClaw/LLMs.

### Windmill
- **GitHub:** https://github.com/windmill-labs/windmill
- **Licença:** AGPLv3 (self-host gratuito, licença comercial disponível)
- **Stars:** ~12k+ ⭐
- **O que faz:** Plataforma dev para scripts, workflows e UIs internas. Suporte a Python, TypeScript, Go, Bash, SQL. 13x mais rápido que Airflow. Alternativa ao Retool + Temporal.
- **macOS Apple Silicon:** ✅ (Docker)
- **Instalação:**
  ```bash
  curl https://raw.githubusercontent.com/windmill-labs/windmill/main/docker-compose.yml -o docker-compose.yml
  docker compose up -d
  ```
- **Prós:** Multi-linguagem, webhooks automáticos por script, UI builder, cron scheduler built-in, muito poderoso
- **Contras:** AGPL (verificar se afeta SaaS), mais complexo de configurar, mais voltado pra dev
- **Serve pro nosso caso:** ✅ SIM — Excelente para scripts técnicos e automações dev. Mais para o Tiago/Elber do que para clientes.

### Temporal
- **GitHub:** https://github.com/temporalio/temporal
- **Licença:** MIT
- **Stars:** ~12k+ ⭐
- **O que faz:** Durable execution platform. Workflows que não falham — auto-retry, resumo após crash, long-running processes. Veio do Uber Cadence.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install temporal
  temporal server start-dev
  ```
- **Prós:** MIT, workflows resilientes para sempre, suporte a Go/Java/Python/TS/PHP, web UI em localhost:8233
- **Contras:** Mais complexo, precisa aprender o modelo de programação, overhead para tarefas simples
- **Serve pro nosso caso:** ✅ SIM — Para processos críticos que não podem falhar (pagamentos, envios, etc). Overkill para automações simples.

### Prefect
- **GitHub:** https://github.com/PrefectHQ/prefect
- **Licença:** Apache 2.0
- **Stars:** ~16k ⭐
- **O que faz:** Workflow orchestration para data pipelines em Python. Scheduling, retries, caching, event-based triggers. Self-hosted ou Prefect Cloud.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  pip install -U prefect
  prefect server start
  ```
- **Prós:** Apache 2.0, Python puro, UI linda, muito usado em data engineering
- **Contras:** Python-only, menos adequado para workflows não-Python
- **Serve pro nosso caso:** ⚠️ PARCIAL — Bom se tiver pipelines de dados em Python. Não substitui N8n para integrações visuais.

---

## 3. SELF-HOSTED PAAS

### Coolify ⭐ RECOMENDADO
- **GitHub:** https://github.com/coollabsio/coolify
- **Licença:** Apache 2.0
- **Stars:** ~40k+ ⭐
- **O que faz:** Alternativa self-hosted ao Heroku/Netlify/Vercel. Deploy de apps, bancos de dados, e 280+ serviços 1-click no seu próprio servidor via SSH. Sem lock-in.
- **macOS Apple Silicon:** ✅ (instala no servidor, não necessariamente no Mac como runtime)
- **Instalação:**
  ```bash
  curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
  ```
- **Prós:** Facilíssimo, SSL automático, deploy via Git, suporta Docker/Docker Compose, 280+ serviços (Postgres, Redis, Wordpress, etc), sem vendor lock-in
- **Contras:** Requer Linux para o servidor Coolify em si (Mac Mini pode ser o target gerenciado)
- **Serve pro nosso caso:** ✅ SIM — Para gerenciar deploys dos projetos dos clientes. Mas requer instalar em Linux; Mac Mini precisa de wrapper.

### CapRover
- **GitHub:** https://github.com/caprover/caprover
- **Licença:** Apache 2.0
- **Stars:** ~13k ⭐
- **O que faz:** PaaS automatizado com Docker + Nginx. Deploy de qualquer app sem conhecimento de Docker. SSL automático via Let's Encrypt, CLI + Web UI.
- **macOS Apple Silicon:** ✅ (Docker)
- **Instalação:**
  ```bash
  npm install -g caprover
  caprover serversetup
  ```
- **Prós:** Simples, sem lock-in, suporte a apps de qualquer linguagem, one-click services
- **Contras:** Docker Swarm por baixo (overhead), menos features que Coolify
- **Serve pro nosso caso:** ✅ SIM — Alternativa ao Coolify, ligeiramente mais simples para começar.

### Dokku
- **GitHub:** https://github.com/dokku/dokku
- **Licença:** MIT
- **Stars:** ~28k ⭐
- **O que faz:** Heroku em miniatura. Deploy via `git push`. PaaS minimalista baseado em Docker.
- **macOS Apple Silicon:** ⚠️ Funciona via Docker (não nativo macOS)
- **Instalação:**
  ```bash
  # No servidor Linux:
  wget -NP . https://dokku.com/install/v0.34.9/bootstrap.sh
  bash bootstrap.sh
  ```
- **Prós:** Extremamente leve, MIT, interface familiar (Heroku-like), plugável
- **Contras:** Mais manual que Coolify, sem UI web moderna, melhor em Linux
- **Serve pro nosso caso:** ⚠️ PARCIAL — Boa opção se quiser algo minimalista. Coolify é mais completo.

---

## 4. MONITORING

### Uptime Kuma ⭐ RECOMENDADO
- **GitHub:** https://github.com/louislam/uptime-kuma
- **Licença:** MIT
- **Stars:** ~65k+ ⭐
- **O que faz:** Monitoring de uptime estilo Uptime Robot mas self-hosted. Monitora HTTP, TCP, DNS, Ping, Docker containers. Notifica via Telegram, Discord, Slack, Email, e 90+ canais.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  docker run -d --restart=always -p 3001:3001 \
    -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:2
  ```
- **Prós:** MIT, UI linda e reativa, notificações para 90+ serviços, múltiplos status pages, gratuito para sempre
- **Contras:** Sem métricas avançadas (só uptime), sem alertas de CPU/memória
- **Serve pro nosso caso:** ✅ SIM MUITO — Monitorar todos os serviços (N8n, OpenClaw, sites dos clientes). Essencial.

### Netdata ⭐ RECOMENDADO
- **GitHub:** https://github.com/netdata/netdata
- **Licença:** GPL v3 (self-hosted gratuito)
- **Stars:** ~74k+ ⭐
- **O que faz:** Monitoring de infraestrutura em tempo real. Métricas por segundo de CPU, RAM, disco, rede, containers. Zero configuração, deploy imediato. ML-powered anomaly detection.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh
  sh /tmp/netdata-kickstart.sh
  ```
- **Prós:** Zero config, métricas em tempo real, ML automático, muito leve, dashboard rico
- **Contras:** GPL v3 (verificar se precisa de licença comercial para uso interno), cloud é pago para features avançadas
- **Serve pro nosso caso:** ✅ SIM — Pair com Uptime Kuma: Kuma monitora uptime de serviços, Netdata monitora saúde do Mac Mini.

### Grafana
- **GitHub:** https://github.com/grafana/grafana
- **Licença:** AGPL-3.0 (self-hosted) + licença comercial disponível
- **Stars:** ~66k ⭐
- **O que faz:** Plataforma de observabilidade e visualização. Dashboards para métricas, logs e traces de múltiplas fontes (Prometheus, InfluxDB, PostgreSQL, etc).
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install grafana
  brew services start grafana
  ```
- **Prós:** Indústria padrão, dashboards infinitamente customizáveis, suporte a 100+ data sources, alertas
- **Contras:** AGPL, mais complexo — precisa de data source separado (Prometheus, etc), overhead de configuração
- **Serve pro nosso caso:** ✅ SIM — Para dashboards executivos e métricas de negócio. Mas é overkill no começo; começar com Uptime Kuma + Netdata.

### Prometheus
- **GitHub:** https://github.com/prometheus/prometheus
- **Licença:** Apache 2.0
- **Stars:** ~57k ⭐
- **O que faz:** Sistema de monitoramento e banco de dados de séries temporais. Coleta métricas via pull HTTP. Base do stack Prometheus + Grafana.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install prometheus
  prometheus --config.file=prometheus.yml
  ```
- **Prós:** Apache 2.0, padrão CNCF, multi-dimensional, PromQL poderoso, sem dependência de storage distribuído
- **Contras:** Só coleta métricas (precisa de Grafana para visualizar), configuração manual de targets
- **Serve pro nosso caso:** ⚠️ PARCIAL — Usar junto com Grafana se quiser stack de observabilidade completo. Não é prioridade no início.

---

## 5. MESSAGE QUEUE

### BullMQ ⭐ RECOMENDADO
- **GitHub:** https://github.com/taskforcesh/bullmq
- **Licença:** MIT
- **Stars:** ~6k ⭐
- **O que faz:** Message queue e batch processing para Node.js/Python/Elixir/PHP baseado em Redis. Jobs com retry, delay, prioridade, cron, parent-child relationships.
- **macOS Apple Silicon:** ✅ (Node.js + Redis)
- **Instalação:**
  ```bash
  npm install bullmq
  # Redis necessário:
  brew install redis && brew services start redis
  ```
- **Prós:** MIT, Node.js nativo (igual ao nosso stack), Redis como backend (confiável), tipagem TypeScript, muito ativo
- **Contras:** Requer Redis rodando, não tem UI própria (Bull Board separado)
- **Serve pro nosso caso:** ✅ SIM MUITO — Para tarefas assíncronas nos projetos: envio de emails, processamento de vídeo, webhooks resilientes. Integra perfeitamente com N8n e OpenClaw.

### RabbitMQ
- **GitHub:** https://github.com/rabbitmq/rabbitmq-server
- **Licença:** Mozilla Public License 2.0 (uso comercial ok)
- **Stars:** ~12k ⭐
- **O que faz:** Message broker enterprise. AMQP, pub/sub, work queues, routing avançado. Gerencia mensagens entre serviços.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install rabbitmq
  brew services start rabbitmq
  ```
- **Prós:** Enterprise-grade, multi-protocolo (AMQP, MQTT, STOMP), web management UI embutida, clustering
- **Contras:** Mais pesado que BullMQ, requer aprender conceitos de AMQP, overkill para uso simples
- **Serve pro nosso caso:** ⚠️ PARCIAL — Só se precisar de messaging entre múltiplos serviços/linguagens. BullMQ é mais simples para Node.js.

---

## 6. SCHEDULING

### Temporal (ver seção Workflow)
Para scheduling robusto com retry e durable execution — já coberto acima.

### Agenda
- **GitHub:** https://github.com/agenda/agenda
- **Licença:** MIT
- **Stars:** ~9k ⭐
- **O que faz:** Job scheduling para Node.js usando MongoDB. Cron syntax, jobs únicos ou recorrentes, persistência.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  npm install agenda
  # MongoDB necessário
  ```
- **Prós:** MIT, simples, Node.js nativo
- **Contras:** Requer MongoDB, menos ativo recentemente
- **Serve pro nosso caso:** ⚠️ PARCIAL — BullMQ cobre agendamento também. Só usar Agenda se já tiver MongoDB.

### Ofelia
- **GitHub:** https://github.com/mcuadros/ofelia
- **Licença:** MIT
- **Stars:** ~3k ⭐
- **O que faz:** Job scheduler para Docker. Substitui cron em ambientes containerizados. Roda containers, exec, HTTP, local jobs em schedules.
- **macOS Apple Silicon:** ✅ (Docker)
- **Instalação:**
  ```bash
  docker run -d --name ofelia \
    -v /var/run/docker.sock:/var/run/docker.sock \
    mcuadros/ofelia:latest daemon
  ```
- **Prós:** MIT, Docker-native, sem necessidade de cron no host
- **Contras:** Requer Docker, menos features que Temporal
- **Serve pro nosso caso:** ✅ SIM — Para agendar tarefas em containers de forma simples e sem cron no macOS.

---

## 7. CONTAINER ALTERNATIVES

### OrbStack ⭐ RECOMENDADO (para macOS)
- **GitHub:** https://github.com/orbstack/orbstack
- **Licença:** Proprietário (uso pessoal gratuito, comercial pago) ⚠️
- **Stars:** ~5k ⭐
- **O que faz:** Substituto ultrarrápido ao Docker Desktop no macOS. Inicia em 2 segundos, menor uso de CPU/RAM/bateria, Rosetta para x86. Gerencia containers Docker, Kubernetes e máquinas Linux.
- **macOS Apple Silicon:** ✅✅✅ OTIMIZADO
- **Instalação:**
  ```bash
  brew install orbstack
  ```
- **Prós:** MUITO mais rápido que Docker Desktop, nativo Swift no macOS, VPN e SSH integrados, interface de barra de menu
- **Contras:** ⚠️ NÃO É OPEN-SOURCE — licença comercial paga para uso empresarial (~$8/mês)
- **Serve pro nosso caso:** ✅ SIM — O melhor Docker runtime para Mac Mini M4. Vale o custo para produção.

### Podman
- **GitHub:** https://github.com/containers/podman
- **Licença:** Apache 2.0
- **Stars:** ~24k ⭐
- **O que faz:** Gerenciador de containers OCI sem daemon (daemonless). Substituto ao Docker, compatível com Docker CLI. Roda no macOS via VM gerenciada.
- **macOS Apple Silicon:** ✅ (via Podman Machine)
- **Instalação:**
  ```bash
  brew install podman
  podman machine init
  podman machine start
  ```
- **Prós:** Apache 2.0, rootless containers, sem daemon central, compatível com Docker Compose
- **Contras:** Mais lento que OrbStack no macOS, VM por baixo, menos integrado ao sistema
- **Serve pro nosso caso:** ✅ SIM — Alternativa 100% free ao Docker Desktop. Menos polido que OrbStack mas gratuito.

---

## 8. REMOTE ACCESS

### Tailscale ⭐ RECOMENDADO
- **GitHub:** https://github.com/tailscale/tailscale
- **Licença:** BSD-3-Clause (cliente open-source; servidor relay é proprietário)
- **Stars:** ~21k ⭐
- **O que faz:** VPN mesh usando WireGuard. Conecta dispositivos numa rede privada segura sem configurar portas ou firewall. Funciona atrás de NAT.
- **macOS Apple Silicon:** ✅✅ App nativo macOS
- **Instalação:**
  ```bash
  brew install tailscale
  sudo tailscale up
  ```
- **Prós:** Zero config, seguro (WireGuard), acesso remoto ao Mac Mini de qualquer lugar, gratuito para uso pessoal/pequenas equipes
- **Contras:** Servidor relay é proprietário (mas código do cliente é open), plano gratuito tem limite de 100 dispositivos
- **Serve pro nosso caso:** ✅ SIM MUITO — Acesso seguro ao Mac Mini de qualquer lugar sem abrir portas no roteador. Essencial para trabalho remoto.

### Cloudflare Tunnel (cloudflared)
- **GitHub:** https://github.com/cloudflare/cloudflared
- **Licença:** Apache 2.0
- **Stars:** ~10k ⭐
- **O que faz:** Expõe serviços locais para internet via Cloudflare sem abrir portas. Tunnel criptografado do Mac Mini → Cloudflare → usuário.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install cloudflare/cloudflare/cloudflared
  cloudflared tunnel login
  cloudflared tunnel create meu-tunnel
  ```
- **Prós:** Apache 2.0, gratuito para uso básico, sem IP público necessário, DDoS protection automática, domínio HTTPS automático
- **Contras:** Tráfego passa pela Cloudflare (não totalmente privado), free tier tem limites de largura de banda
- **Serve pro nosso caso:** ✅ SIM — Para expor N8n, webhooks, e serviços dos clientes na internet de forma segura e com HTTPS automático.

> **Combo recomendado:** Tailscale para acesso interno da equipe + CF Tunnel para serviços públicos de clientes.

---

## 9. DATABASE

### PocketBase ⭐ RECOMENDADO
- **GitHub:** https://github.com/pocketbase/pocketbase
- **Licença:** MIT
- **Stars:** ~45k+ ⭐
- **O que faz:** Backend completo em 1 único binário Go. Banco SQLite com realtime subscriptions, autenticação, file storage, admin dashboard, REST API — tudo pronto.
- **macOS Apple Silicon:** ✅ Binário nativo arm64
- **Instalação:**
  ```bash
  # Download do binário arm64 em pocketbase.io/docs
  ./pocketbase serve
  # Acessa em http://localhost:8090/_/
  ```
- **Prós:** MIT, 1 arquivo, zero dependências, admin UI embutida, SDK JS/Dart, ideal para apps rápidos e MVPs
- **Contras:** SQLite (não escala horizontalmente para multi-server), ainda em desenvolvimento ativo (não v1 ainda)
- **Serve pro nosso caso:** ✅ SIM MUITO — Backend rápido para apps dos clientes (Titanio 47, etc). Zero infra overhead.

### SurrealDB
- **GitHub:** https://github.com/surrealdb/surrealdb
- **Licença:** Business Source License 1.1 (uso comercial precisa verificar) ⚠️
- **Stars:** ~28k ⭐
- **O que faz:** Banco multi-modelo em Rust. Unifica document, graph, relational, time-series, vector search. Roda embedded, single-node, ou cluster. Bom para AI agents e knowledge graphs.
- **macOS Apple Silicon:** ✅ Binário nativo
- **Instalação:**
  ```bash
  brew install surrealdb/tap/surreal
  surreal start --log trace --user root --pass root memory
  ```
- **Prós:** Ultra-rápido (Rust), multi-modelo, vector search embutido, ótimo para AI
- **Contras:** ⚠️ BSL 1.1 — verificar se uso comercial é gratuito em self-host, ainda maturing
- **Serve pro nosso caso:** ⚠️ VERIFICAR LICENÇA — Se licença ok, excelente para dados de AI agents e projetos complexos.

### Turso (libSQL)
- **GitHub:** https://github.com/tursodatabase/libsql
- **Licença:** MIT
- **Stars:** ~15k+ ⭐
- **O que faz:** Fork open-source do SQLite (libSQL) com replicação, acesso remoto, e multi-tenancy. "SQLite for production".
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  brew install tursodatabase/tap/turso
  turso dev  # server local
  ```
- **Prós:** MIT, compatível com SQLite, edge-ready, replicação embutida, SDK em 8+ linguagens
- **Contras:** Cloud Turso é necessário para features avançadas de replicação, CLI mais voltado ao cloud
- **Serve pro nosso caso:** ✅ SIM — Para apps que precisam de SQLite mais robusto com acesso remoto. Ótimo para Titanio 47.

---

## 10. AI AGENT FRAMEWORKS

### Dify ⭐ RECOMENDADO
- **GitHub:** https://github.com/langgenius/dify
- **Licença:** Apache 2.0 (self-hosted)
- **Stars:** ~100k+ ⭐ 🔥 (um dos mais starred em AI)
- **O que faz:** Plataforma visual de desenvolvimento de LLM apps. Workflow builder visual, RAG pipeline, agent capabilities, model management (qualquer LLM), observabilidade.
- **macOS Apple Silicon:** ✅ (Docker Compose)
- **Instalação:**
  ```bash
  git clone https://github.com/langgenius/dify.git
  cd dify/docker
  cp .env.example .env
  docker compose up -d
  # Acessa em http://localhost/install
  ```
- **Prós:** Apache 2.0, UI visual para não-developers, suporta qualquer modelo (GPT, Claude, Gemini, Ollama local), RAG pronto, 100k+ stars
- **Contras:** Docker Compose necessário, pesado (múltiplos containers), mais pra apps de produção do que código
- **Serve pro nosso caso:** ✅ SIM MUITO — Complementa OpenClaw perfeitamente. OpenClaw para automação sistêmica, Dify para apps LLM visuais para clientes.

### CrewAI
- **GitHub:** https://github.com/crewAIInc/crewAI
- **Licença:** MIT
- **Stars:** ~28k ⭐
- **O que faz:** Framework Python para orquestrar múltiplos AI agents com roles definidos. Agents trabalham em equipe em tarefas complexas. Independente de LangChain.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  pip install crewai
  crewai create crew meu-projeto
  ```
- **Prós:** MIT, Python, fácil de entender (role-based agents), bom para tarefas de pesquisa/análise
- **Contras:** Python-only, runtime local (sem UI), precisa de API key para LLMs, menos produção-ready que Dify
- **Serve pro nosso caso:** ✅ SIM — Para automações de pesquisa, análise de conteúdo, relatórios automáticos. Complementa OpenClaw.

### LangGraph
- **GitHub:** https://github.com/langchain-ai/langgraph
- **Licença:** MIT
- **Stars:** ~14k ⭐
- **O que faz:** Framework de baixo nível para agentes stateful de longa duração. Durable execution, human-in-the-loop, memória de curto e longo prazo. Usado por Klarna, Replit, Elastic.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  pip install -U langgraph
  ```
- **Prós:** MIT, muito poderoso, state machine para agents, suporte a qualquer LLM, bom para fluxos complexos
- **Contras:** Curva de aprendizado alta, baixo nível (mais código), ecossistema LangChain dependente
- **Serve pro nosso caso:** ⚠️ PARA DESENVOLVEDORES — Bom para o Tiago/Elber construir agents customizados. Não é plug-and-play.

### AutoGen (Microsoft)
- **GitHub:** https://github.com/microsoft/autogen
- **Licença:** MIT
- **Stars:** ~40k ⭐
- **O que faz:** Framework multi-agent da Microsoft. Agents conversam entre si para resolver tarefas. AutoGen Studio tem UI no-code.
- **macOS Apple Silicon:** ✅
- **Instalação:**
  ```bash
  pip install autogen-agentchat autogen-ext[openai]
  # UI no-code:
  pip install autogenstudio
  autogenstudio ui
  ```
- **Prós:** MIT, Microsoft backing, ativo, AutoGen Studio tem UI visual, bom para pesquisa
- **Contras:** Foco em pesquisa mais que produção, pode ser verbose, está migrando para "Microsoft Agent Framework"
- **Serve pro nosso caso:** ⚠️ PARCIAL — Interessante para experimentação. Dify é mais produção-ready para clientes.

---

## 🎯 PLANO DE IMPLEMENTAÇÃO SUGERIDO

### Fase 1 — Essenciais (implementar agora)
1. **Uptime Kuma** → Monitorar todos os serviços (15 min de setup)
2. **Tailscale** → Acesso remoto seguro da equipe ao Mac Mini
3. **CF Tunnel** → Expor webhooks e serviços de clientes com HTTPS
4. **BullMQ** → Tarefas assíncronas para os projetos ativos

### Fase 2 — Produtividade (próximo mês)
5. **Activepieces** → Automações visuais complementando N8n (especialmente MCP para LLMs)
6. **PocketBase** → Backend rápido para novos projetos/apps
7. **OrbStack** → Substituir Docker Desktop no Mac Mini

### Fase 3 — Scale (quando necessário)
8. **Temporal** → Para workflows críticos que não podem falhar
9. **Dify** → Plataforma de AI apps para clientes
10. **Netdata + Grafana** → Observabilidade completa de infraestrutura

### Fase 4 — Avançado (projetos específicos)
11. **Windmill** → Scripts técnicos multi-linguagem
12. **Coolify** → PaaS para gerenciar deploys de clientes
13. **CrewAI / LangGraph** → AI agents customizados
14. **Turso** → Banco de dados para apps móveis

---

## ⚠️ OBSERVAÇÕES IMPORTANTES

### Licenças que precisam de atenção:
- **AGPL-3.0** (PM2, Windmill, Grafana) — Self-hosted é geralmente ok, mas verificar se SaaS modifica o código e distribui
- **SurrealDB BSL 1.1** — Uso comercial pode ter restrições; verificar antes de usar em produção
- **OrbStack** — NÃO é open-source; uso comercial é pago (~$8/mês)

### Compatibilidade Apple Silicon (M4):
Todas as ferramentas marcadas ✅ funcionam no Mac Mini M4, seja nativamente (arm64) ou via Rosetta/Docker com multi-arch images. Priorizar binários arm64 nativos para melhor performance.

### Stack atual vs novos:
- **N8n** continua — não substituir, complementar com Activepieces para MCP
- **OpenClaw** continua — Dify e CrewAI são camadas acima, não substitutos
- **PM2** provavelmente já em uso — confirmar configuração

---

*Pesquisa realizada em 02/04/2026 — verificar stars/licenças atualizadas nos repos antes de usar.*
