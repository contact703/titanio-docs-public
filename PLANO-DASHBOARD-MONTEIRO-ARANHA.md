# Dashboard Monteiro Aranha — Plano Completo
## Titanio Studio

---

# Visão Geral

Uma Dashboard enterprise para a Monteiro Aranha: visual sóbrio, funcional, com login por nível de acesso, especialistas de IA visíveis em tempo real, fluxos de aprovação, canal de acionistas e modo confidencial.

---

# 1. Design e Identidade Visual

## Paleta

A interface segue o padrão visual de holdings financeiras brasileiras: sobriedade, confiança, prestígio.

- Primária: Navy blue (#1a1a2e)
- Secundária: Branco (#ffffff)
- Destaque: Dourado/amber (#d4a853)
- Sucesso: Verde (#22c55e)
- Alerta: Laranja (#f59e0b)
- Erro/Urgente: Vermelho (#ef4444)
- Confidencial: Vermelho escuro (#991b1b)

## Tipografia

- Headings: Inter (modernidade com seriedade)
- Dados e tabelas: JetBrains Mono (legibilidade numérica)
- Corpo: Inter 14px, leading relaxado

## Layout Principal

```
┌──────┬───────────────────────────────────────────┐
│      │  [Logo MA]  Bem-vindo, João    🔔3  ⚙️   │
│      ├───────────────────────────────────────────┤
│  S   │                                           │
│  I   │  ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  D   │  │ Tarefas  │ │ Pendentes│ │ Acionistas│  │
│  E   │  │ IA: 12   │ │ Aprovar:3│ │ Fila: 7  │  │
│  B   │  └──────────┘ └──────────┘ └──────────┘  │
│  A   │                                           │
│  R   │  ┌──────────────────────────────────────┐ │
│      │  │ Especialistas em Operação            │ │
│  📊  │  │ 🤖 RI: Analisando DFP Q4... 72%     │ │
│  📋  │  │ 🤖 Jurídico: Idle                    │ │
│  📄  │  │ 🤖 Financeiro: Gerando relatório...  │ │
│  👥  │  └──────────────────────────────────────┘ │
│  ⚙️  │                                           │
│      │  ┌──────────────┐ ┌─────────────────────┐│
│      │  │ Aprovações   │ │ Chat com IA         ││
│      │  │ recentes     │ │ "Prepare o release" ││
│      │  └──────────────┘ └─────────────────────┘│
└──────┴───────────────────────────────────────────┘
```

Dark mode disponível para sessões longas.

---

# 2. Sistema de Login e Níveis de Acesso

## 6 Níveis de Acesso (RBAC)

| Nível | Perfil | O que vê | O que faz |
|-------|--------|----------|-----------|
| 0 | Admin TI | Tudo + configuração | Gerenciar usuários, roles, sistema |
| 1 | Conselho/Board | Visão consolidada | Aprovar atas e resoluções (read-mostly) |
| 2 | CEO/Diretoria | Todos os módulos | Aprovação final, modo confidencial, relatórios |
| 3 | Departamento | Módulos da área | Operar na área (RI, Jurídico, Financeiro, Backoffice) |
| 4 | Acionista | Portal externo | Enviar demandas, ver status, consultar posição |
| 5 | Especialista IA | Sem UI (service account) | Executar tarefas via API |

## Login

- Email + senha com MFA obrigatório
- MFA via SMS ou WhatsApp (não TOTP — mais acessível para executivos)
- Opção SSO: "Entrar com Google" / "Entrar com Microsoft 365"
- Sessão: 8h para operadores, 30 dias para acionistas (com re-auth em ações sensíveis)

## Primeiro Acesso (Onboarding)

1. Tela de boas-vindas personalizada: "Olá, João! Bem-vindo ao Portal Monteiro Aranha."
2. Tour guiado de 3 passos (não 10)
3. Cada função com ícone + label (nunca só ícone)
4. Linguagem simples: "Aprovar documento" em vez de "Submit approval workflow"
5. Botão "Ajuda" flutuante sempre visível

---

# 3. Módulos da Dashboard

## 3.1 Painel de Especialistas IA (Home)

Cards em tempo real mostrando cada especialista trabalhando:

```
┌──────────────────────────────────────────┐
│  🤖 Especialista RI                      │
│                                          │
│  ◐ Analisando demandas do dia            │
│  ▓▓▓▓▓▓▓░░░  72% concluído              │
│                                          │
│  ✓ Triagem de emails (23)               │
│  ✓ Classificação de pedidos (8)          │
│  ⏳ Gerando relatório consolidado        │
│                                          │
│  Estimativa: ~2 min                      │
│  [Cancelar]  [Ver Detalhes]              │
└──────────────────────────────────────────┘
```

Regras visuais:
- Animação pulse suave no ícone enquanto processa (não spinner agressivo)
- Steps com checklist (não "loading..." genérico)
- Tempo estimado sempre visível
- Botão cancelar acessível
- Resultado com validação humana: "IA sugeriu X — Você concorda?"

Especialistas disponíveis:
- Especialista RI (Relações com Investidores)
- Especialista Jurídico
- Especialista Financeiro
- Especialista Governança
- Especialista Comunicação
- Especialista Backoffice

## 3.2 Aprovação de Documentos

Fluxo visual:

```
RASCUNHO → REVISÃO → APROVAÇÃO JURÍDICO → APROVAÇÃO CEO → PUBLICADO
```

Tabela de pendências:

```
┌──────────┬────────────────┬──────────┬──────────────────┐
│ Tipo     │ Assunto        │ Prazo    │ Ação             │
├──────────┼────────────────┼──────────┼──────────────────┤
│ 📄 Nota  │ Assembleia Q1  │ Hoje     │ [Aprovar] [Ver]  │
│ 📧 Com.  │ Divid. 2025    │ 2 dias   │ [Aprovar] [Ver]  │
│ 📑 Rel.  │ Balanço Mar    │ 5 dias   │ [Aprovar] [Ver]  │
└──────────┴────────────────┴──────────┴──────────────────┘
```

Recursos:
- Status badge colorido (amarelo=pendente, verde=aprovado, vermelho=urgente)
- Botão "Aprovar" inline na tabela (sem navegação extra)
- Aprovação em massa (checkbox + "Aprovar selecionados")
- Contador no menu: "🔔 3 aprovações pendentes"
- Preview inline de PDF
- Diff visual entre versões de documentos
- Histórico de quem aprovou o quê e quando
- Funciona em 2 toques no celular

## 3.3 Canal de Acionistas

Visão interna (equipe RI):

```
┌─────────────────────────────────────────────────┐
│  FILA DE ACIONISTAS                  Total: 7   │
├─────────────────────────────────────────────────┤
│                                                 │
│  [NOVO]  [EM ANÁLISE]  [AGUARDANDO]  [RESOLVIDO]│
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │ João Silva — Seguro veicular            │    │
│  │ Status: 🟡 Em análise                   │    │
│  │ SLA: ████████░░ 80% — Prazo: amanhã 18h │    │
│  │ [Responder] [Escalar] [Ver histórico]   │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │ Maria Costa — Informe rendimentos       │    │
│  │ Status: ✅ Resolvido há 2h              │    │
│  │ [Baixar resposta] [Reabrir]             │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

Visão do acionista (portal externo):

```
┌─────────────────────────────────────────────────┐
│  Olá, João Silva                                │
│                                                 │
│  Suas solicitações:                             │
│  ┌─────────────────────────────────────────┐    │
│  │ Seguro veicular como acionista          │    │
│  │ Status: Em análise                      │    │
│  │ Resposta prevista: amanhã às 18h        │    │
│  │ ████████░░ em andamento                 │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  [+ Nova Solicitação]  [Histórico completo]     │
└─────────────────────────────────────────────────┘
```

Recursos:
- Kanban por status: Novo → Em Análise → Aguardando → Resolvido
- SLA visual com barra de progresso colorida
- Prazo em linguagem natural: "Resposta até amanhã às 18h"
- Timeline: Recebido → Em análise → Aprovação → Concluído
- Visão 360° do acionista (histórico de interações)
- Templates de resposta para pedidos recorrentes
- Notificação proativa via WhatsApp

## 3.4 Documentos e Contratos

- Upload multi-formato (PDF, DOCX, XLSX)
- OCR automático via IA (extração de cláusulas)
- Versionamento: v1.0 → v1.1 → v2.0
- Diff visual entre versões (lado a lado)
- Tags: Contrato | Ata | Política | Estatuto | Procuração
- Alerta de expiração automático
- Busca inteligente com IA
- Acesso por papel (jurídico vê tudo, RI vê docs públicos)

## 3.5 Métricas Financeiras (CEO/Diretoria)

- NAV das participações
- Performance vs benchmark (IBOVESPA, IBX)
- Dividendos recebidos vs projetados
- DRE consolidada
- Posição de caixa
- Mini sparklines por ativo
- Próximas assembleias/eventos
- Export CSV/Excel

## 3.6 Chat com IA (Sidebar)

Sidebar à direita, sempre acessível:

```
┌──────────────────────────┐
│  💬 Assistente MA        │
│                          │
│  Você: Prepare o release │
│  do Q4 2025              │
│                          │
│  🤖 Entendido! Gerando  │
│  rascunho baseado nos    │
│  resultados...           │
│  ▓▓▓▓░░░ 45%            │
│                          │
│  [____________________]  │
│  [Enviar]  🔴Confidencial│
└──────────────────────────┘
```

- Streaming de resposta em tempo real
- Suporte a texto e áudio
- Botão "Modo Confidencial" no rodapé do chat
- Respostas referenciam documentos internos

---

# 4. Modo Confidencial

Banner visual quando ativado:

```
┌─────────────────────────────────────────────────┐
│ 🔴 MODO CONFIDENCIAL ATIVO — SESSÃO PROTEGIDA  │
│     Informações sob sigilo | [Desativar]        │
└─────────────────────────────────────────────────┘
```

Comportamentos:
- Banner vermelho persistente no topo
- IA executa mas NÃO salva para aprendizado
- Dados sensíveis mascarados (████) com clique para revelar
- Screenshots bloqueadas (CSS user-select: none)
- Watermark dinâmico: "Visualizado por João em 02/04/2026 14:32"
- Timeout reduzido: 5 min de inatividade
- Log apenas de metadados (quem abriu sessão, duração — sem conteúdo)

---

# 5. White-Label e Branding

Cada cliente tem seu tema:

- Logo (SVG)
- Cores primária/secundária/destaque
- Favicon
- Domínio customizado: portal.monteiroaranha.com.br
- Footer personalizado
- SSL automático (Let's Encrypt)
- Preview em tempo real no painel admin

Aplicado via CSS Custom Properties (1 variável muda todo o sistema).

---

# 6. Stack Técnica

| Camada | Tecnologia | Por quê |
|--------|-----------|---------|
| Framework | Next.js 15 (App Router) | SSR, performance, React 19 |
| UI | shadcn/ui + Tailwind CSS | Customizável, profissional |
| Charts | Tremor | Feito para dashboards financeiros |
| Auth | Clerk ou NextAuth.js + MFA | Enterprise, SSO, roles |
| RBAC | CASL (biblioteca JS) | Granular, tipado, maduro |
| Database | Supabase (PostgreSQL) | Auth + Realtime + Storage |
| Realtime | Supabase Realtime + SSE | Status de agentes em tempo real |
| Chat IA | Vercel AI SDK (useChat) | Streaming, multi-LLM |
| Chat sidebar | CopilotKit | Plug-and-play em dashboard |
| Docs/Diff | Monaco Editor + react-pdf | Versionamento, diff visual |
| Editor | TipTap (Notion-like) | Releases, documentos editáveis |
| Deploy | Self-hosted (Docker + Nginx) | Controle total |

## Por que Next.js custom e não Retool/Appsmith?

1. Branding é identidade — uma holding centenária não pode parecer "feita no Retool"
2. Modo confidencial exige controle total do DOM e CSS
3. Integração nativa com agentes IA via WebSocket
4. RBAC complexo com regras de negócio sofisticadas
5. Auditoria granular exportável para compliance CVM/B3
6. Custo: Retool Enterprise custa $500-2000/mês. Custom: só infra

## Templates para acelerar

- shadcn-admin (github.com/satnaing/shadcn-admin) — sidebar, RBAC layout
- Vercel AI Chatbot — template oficial Next.js + chat IA
- Tremor templates — charts financeiros prontos

---

# 7. Cronograma de Desenvolvimento

| Fase | Semana | Entregas |
|------|--------|---------|
| Setup + Layout | 1-2 | Next.js + shadcn + auth/RBAC + sidebar + dark mode |
| Módulos Core | 3-4 | Painel de agentes + Aprovações + Chat IA |
| Canal Acionistas | 5 | Portal externo + fila interna + WhatsApp |
| Documentos | 6 | Upload, versionamento, diff, busca IA |
| Métricas | 7 | Charts financeiros, KPIs, export |
| Modo Confidencial | 8 | Sessão efêmera, watermark, mascaramento |
| White-label + Polish | 9-10 | Branding MA, domínio, dark mode, mobile |
| Testes + Go-live | 11-12 | Pentest, UAT com equipe MA, launch |

---

# 8. Resumo Executivo

A Dashboard Monteiro Aranha será:

- Um portal corporativo visual com a marca da empresa
- Login seguro com MFA e 6 níveis de acesso
- Especialistas de IA visíveis em tempo real
- Fluxos de aprovação inline (releases, contratos, comunicações)
- Canal de acionistas com fila, SLA visual e WhatsApp
- Gestão de documentos com versionamento e diff
- Chat com IA na sidebar
- Modo confidencial para operações estratégicas
- Métricas financeiras consolidadas
- 100% customizável e white-label

Construída com tecnologia moderna (Next.js + shadcn + Supabase), visualmente profissional, segura por design.

---

Titanio Studio
contact@titaniofilms.com
