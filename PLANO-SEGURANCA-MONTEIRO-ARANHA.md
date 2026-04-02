# Plano de Segurança — Titanio Studio × Monteiro Aranha
## Documento Técnico Completo

**Versão:** 1.0  
**Data:** 02/04/2026  
**Classificação:** Confidencial — Uso interno Titanio + Monteiro Aranha  
**Elaborado por:** Titanio Studio — Equipe de Segurança

---

## SUMÁRIO EXECUTIVO

Este documento detalha a arquitetura de segurança completa do sistema Titanio Studio implantado na Monteiro Aranha. Cobre proteção de dados, isolamento de procedimentos proprietários, controle de acesso, criptografia, auditoria, conformidade regulatória e planos de contingência.

A premissa central: **os procedimentos estratégicos da Monteiro Aranha são tão valiosos quanto seus dados**. A arquitetura protege ambos.

---

## 1. ARQUITETURA DE SEGURANÇA — VISÃO GERAL

### 1.1 Modelo de Defesa em Profundidade (5 Camadas)

```
CAMADA 1 — PERÍMETRO
  Firewall | WAF | DDoS Protection | Zero Trust Network
      │
CAMADA 2 — REDE
  VPN dedicada | Segmentação | mTLS entre serviços
      │
CAMADA 3 — APLICAÇÃO
  Autenticação MFA | RBAC | Session Management | Rate Limiting
      │
CAMADA 4 — DADOS
  Criptografia AES-256 em repouso | TLS 1.3 em trânsito | Tokenização
      │
CAMADA 5 — PROCEDIMENTOS PROPRIETÁRIOS
  Modo Confidencial | Isolamento de Aprendizado | Auditoria Completa
```

### 1.2 Princípios Fundamentais

1. **Zero Trust:** Nenhum componente confia em outro por padrão. Toda comunicação é autenticada e autorizada.
2. **Least Privilege:** Cada usuário, bot e especialista digital tem apenas as permissões mínimas necessárias.
3. **Defense in Depth:** Múltiplas camadas de proteção — se uma falhar, a próxima contém.
4. **Data Sovereignty:** Dados e procedimentos da Monteiro Aranha NUNCA saem da infraestrutura da empresa.
5. **Auditoria Total:** Toda ação é registrada, rastreável e verificável.

---

## 2. INFRAESTRUTURA E HOSPEDAGEM

### 2.1 Onde os Dados Ficam

| Componente | Localização | Controle |
|-----------|-------------|----------|
| Banco de dados (PostgreSQL) | Servidores Monteiro Aranha | TI da Monteiro Aranha |
| Modelos de aprendizado | Servidores Monteiro Aranha | Titanio + TI MA |
| Documentos e contratos | Storage Monteiro Aranha | TI da Monteiro Aranha |
| Logs de auditoria | Servidores Monteiro Aranha | Imutáveis (append-only) |
| Backups criptografados | Storage Monteiro Aranha + cofre offsite | TI da Monteiro Aranha |
| Dashboard e app | Servidores Monteiro Aranha | Titanio opera, MA controla |

**A Titanio NÃO mantém cópia dos dados da Monteiro Aranha fora da infraestrutura da empresa.**

### 2.2 Conexão Titanio ↔ Monteiro Aranha

```
┌──────────────────┐         VPN IPsec/WireGuard         ┌──────────────────┐
│   TITANIO STUDIO │◄────────────mTLS──────────────────►│ MONTEIRO ARANHA  │
│   (Operação)     │     Túnel criptografado 24/7        │ (Infraestrutura) │
└──────────────────┘                                      └──────────────────┘
```

- **Túnel VPN dedicado** entre Titanio e datacenter Monteiro Aranha
- **mTLS (mutual TLS):** ambos os lados se autenticam com certificados
- **IP allowlisting:** apenas IPs autorizados podem se conectar
- **Sem acesso direto à internet** para serviços internos — tudo passa pelo perímetro

### 2.3 Segmentação de Rede

| Zona | Acesso | Serviços |
|------|--------|----------|
| DMZ | Público (WhatsApp channel) | Gateway de mensagens (sanitizado) |
| App Zone | Interno + VPN | Dashboard, API, especialistas digitais |
| Data Zone | Apenas App Zone | PostgreSQL, storage, modelos |
| Admin Zone | Apenas admin autorizado | Logs, auditoria, backups, config |

Tráfego entre zonas: **apenas por regras explícitas de firewall**. Nenhuma comunicação lateral não autorizada.

---

## 3. PROTEÇÃO DE DADOS

### 3.1 Criptografia

| Estado | Método | Detalhes |
|--------|--------|----------|
| **Em repouso** | AES-256-GCM | Banco de dados, arquivos, backups |
| **Em trânsito** | TLS 1.3 | Toda comunicação interna e externa |
| **Em uso** | Enclaves seguros | Dados sensíveis processados em memória protegida |
| **Backups** | AES-256 + RSA-4096 | Chave de backup no cofre da Monteiro Aranha |

### 3.2 Gestão de Chaves

- **KMS (Key Management Service)** dedicado na infraestrutura MA
- Chaves mestras em **HSM (Hardware Security Module)** ou cofre equivalente
- Rotação automática de chaves a cada 90 dias
- Chaves de criptografia NUNCA saem do perímetro MA
- Titanio **não tem acesso** às chaves mestras de criptografia

### 3.3 Classificação de Dados

| Classificação | Exemplos | Proteção |
|--------------|----------|----------|
| **PÚBLICO** | Releases publicados, site RI | Integridade (assinatura) |
| **INTERNO** | Comunicações internas, rotinas | Criptografia + controle de acesso |
| **CONFIDENCIAL** | Contratos, dados financeiros | Criptografia + RBAC restrito + audit trail |
| **ESTRATÉGICO** | Lógica de investimentos, procedimentos proprietários | Modo confidencial + criptografia + zero-learning + acesso ultra-restrito |

### 3.4 Tokenização

Dados sensíveis (CPFs, contas bancárias, dados de acionistas) são **tokenizados** antes de serem processados pela IA:
- Dado real → token opaco (ex: `acionista_047`)
- IA trabalha com tokens, nunca com dados reais
- Detokenização apenas no momento da entrega ao usuário autorizado
- Logs de auditoria registram tokens, não dados reais

---

## 4. PROTEÇÃO DE PROCEDIMENTOS PROPRIETÁRIOS

### 4.1 O Que Torna Isso Especial

A Monteiro Aranha não se preocupa apenas com dados — o principal ativo é **como a empresa opera**:
- A lógica de análise de investimentos
- Os critérios de decisão estratégica
- O "jeito Monteiro Aranha" de fazer negócios

Proteger isso exige mais que criptografia. Exige **isolamento de conhecimento**.

### 4.2 Três Modos de Operação

#### Modo Normal (Aprendizado Ativo)
- IA executa a tarefa e **aprende** o procedimento
- Próxima vez, executa mais rápido e melhor
- Ideal para: rotinas administrativas, backoffice, comunicações padrão
- Exemplo: "Prepare o release trimestral" → IA aprende formato, tom, estrutura

#### Modo Restrito (Aprendizado Controlado)
- IA executa e aprende **apenas a estrutura**, não o conteúdo estratégico
- Ideal para: contratos, análises financeiras recorrentes
- Exemplo: "Analise este contrato" → IA aprende o formato de análise, mas não guarda os termos específicos

#### Modo Confidencial (Zero-Learning)
- IA executa a tarefa mas **NÃO registra nada** para aprendizado futuro
- Sessão efêmera — ao concluir, contexto é destruído
- Nenhum log de conteúdo (apenas log de que a sessão existiu, sem detalhes)
- Ideal para: decisões de investimento, movimentos de mercado, estratégia M&A
- Botão claro na interface: **"Não usar para aprendizado"**

```
┌─────────────────────────────────────────────┐
│         SELEÇÃO DE MODO POR TAREFA          │
│                                             │
│  ⚪ Normal     — IA aprende tudo            │
│  🟡 Restrito   — IA aprende estrutura       │
│  🔴 Confidencial — IA não guarda nada       │
│                                             │
│  [Configurável por tipo de tarefa ou        │
│   selecionável pelo usuário a cada uso]     │
└─────────────────────────────────────────────┘
```

### 4.3 Isolamento do Modelo Especialista

- O modelo treinado com dados da Monteiro Aranha é **exclusivo** da empresa
- Roda em **instância isolada** na infraestrutura MA
- Não é compartilhado com nenhum outro cliente Titanio
- Não alimenta nenhum modelo global ou base de treinamento externa
- Se o contrato encerrar, o modelo pode ser:
  - Entregue à Monteiro Aranha (se desejarem)
  - Destruído com certificado de destruição (se preferirem)

### 4.4 Garantia Anti-Vazamento

```
DADO/PROCEDIMENTO DA MONTEIRO ARANHA
        │
        ▼
  [PROCESSA NA INFRA MA]
        │
        ▼
  [RESULTADO ENTREGUE AO USUÁRIO MA]
        │
        ▼
  [NADA SAI DO PERÍMETRO]
```

- Nenhum dado é enviado para servidores Titanio
- Nenhum procedimento alimenta modelos de outros clientes
- Nenhuma interação em modo confidencial gera registro de conteúdo
- Auditoria comprova isso — Monteiro Aranha pode verificar a qualquer momento

---

## 5. CONTROLE DE ACESSO

### 5.1 Autenticação

| Método | Descrição |
|--------|-----------|
| **SSO corporativo** | Integração com Active Directory / Azure AD da MA |
| **MFA obrigatório** | TOTP (Google Authenticator) ou chave FIDO2/YubiKey |
| **Sessões controladas** | Timeout de 30min inativo, máximo 8h contínuas |
| **Login geolocalizado** | Alertas para acessos de localizações incomuns |
| **Biometria** | Opcional para dispositivos móveis (Face ID / Touch ID) |

### 5.2 RBAC (Role-Based Access Control)

| Perfil | Quem | Pode |
|--------|------|------|
| **Admin TI** | Equipe TI Monteiro Aranha | Tudo: configuração, logs, backup, auditoria, gestão de usuários |
| **Gestor de Área** | Diretores e gerentes MA | Aprovar tarefas, ver relatórios da área, configurar fluxos da área |
| **Operador** | Funcionários MA | Solicitar tarefas, conversar com especialistas, ver próprias demandas |
| **Acionista** | Acionistas (via WhatsApp) | Solicitar serviços de acionista, consultar benefícios, status de pedidos |
| **Titanio Ops** | Equipe Titanio (operação) | Manutenção do sistema, monitoramento, sem acesso a dados de negócio |
| **Auditor** | Compliance/Auditoria MA | Logs de acesso, audit trail, relatórios de segurança (read-only) |

### 5.3 Permissões Granulares

```
gestor_ri:
  - releases: [criar, editar, aprovar]
  - contratos: [visualizar]
  - investimentos: [NENHUM]
  - acionistas: [visualizar, responder]

gestor_juridico:
  - releases: [visualizar]
  - contratos: [criar, editar, aprovar, modo_confidencial]
  - investimentos: [NENHUM]
  - acionistas: [NENHUM]

diretor_investimentos:
  - releases: [visualizar]
  - contratos: [visualizar]
  - investimentos: [criar, editar, modo_confidencial]
  - acionistas: [NENHUM]
```

### 5.4 Princípio dos Quatro Olhos

Para ações críticas, exigimos **aprovação dupla**:
- Deletar dados → aprovação do solicitante + Admin TI
- Alterar permissões → aprovação do gestor + Admin TI
- Exportar dados → aprovação do gestor + Compliance
- Modo confidencial retroativo (apagar aprendizado) → aprovação do diretor + Admin TI

---

## 6. AUDITORIA E RASTREABILIDADE

### 6.1 O Que É Registrado

**Toda ação no sistema gera um registro imutável:**

| Evento | Dados Registrados |
|--------|------------------|
| Login/Logout | Quem, quando, de onde, dispositivo, resultado |
| Tarefa solicitada | Quem pediu, que tipo, qual modo (normal/restrito/confidencial) |
| Tarefa executada | Qual especialista, duração, sucesso/falha |
| Aprovação/Rejeição | Quem aprovou, quando, contexto |
| Acesso a dados | Quem acessou, qual recurso, quando |
| Alteração de permissões | Quem alterou, o que mudou, aprovadores |
| Exportação de dados | Quem exportou, quais dados, para onde |

### 6.2 Imutabilidade dos Logs

- Logs armazenados em **formato append-only** (não podem ser editados ou deletados)
- Hash chain (cada registro referencia o anterior) — qualquer adulteração é detectável
- Backup separado dos logs em storage offline
- Retenção: mínimo **5 anos** (configurável conforme política MA)

### 6.3 Relatórios de Auditoria

| Relatório | Frequência | Destinatário |
|-----------|-----------|--------------|
| Resumo de acessos | Semanal | Gestor TI |
| Ações críticas | Tempo real (alerta) | Admin TI + Compliance |
| Uso de modo confidencial | Mensal | Diretoria |
| Tentativas de acesso negadas | Diário | Segurança TI |
| Compliance LGPD | Trimestral | DPO |
| Relatório completo | Semestral | Auditoria + Board |

---

## 7. CANAL WHATSAPP — SEGURANÇA DO ATENDIMENTO AO ACIONISTA

### 7.1 Fluxo Seguro

```
ACIONISTA (WhatsApp)
      │
      ▼
  [Gateway Sanitizado — DMZ]
  - Validação do número (cadastro prévio)
  - Sanitização de input (anti-injection)
  - Rate limiting (anti-flood)
      │
      ▼
  [Processamento — App Zone]
  - Identificação do acionista por número
  - Contexto carregado do perfil
  - IA processa o pedido
      │
      ▼
  [Resposta SEMPRE passa por humano]
  - Funcionário MA recebe o caso pré-processado
  - Confere e aprova antes de responder
  - Resposta enviada ao acionista
```

### 7.2 Regras de Segurança do Canal

- **Cadastro prévio obrigatório** — apenas números registrados pela MA são atendidos
- **Verificação de identidade** — primeira interação exige confirmação (código, data nascimento, etc.)
- **Nenhum dado sensível por WhatsApp** — para informações confidenciais, acionista é direcionado ao portal seguro
- **Toda resposta passa por aprovação humana** — IA prepara, humano aprova
- **Logs completos** — toda interação é registrada no audit trail
- **Timeout de sessão** — após 30min sem interação, contexto é encerrado
- **Anti-phishing** — sistema detecta e bloqueia tentativas de engenharia social

---

## 8. CONFORMIDADE REGULATÓRIA

### 8.1 LGPD (Lei Geral de Proteção de Dados)

| Requisito LGPD | Como Atendemos |
|----------------|----------------|
| Base legal para tratamento | Consentimento explícito + legítimo interesse documentado |
| Direito de acesso | Portal do acionista com todos os dados armazenados |
| Direito de correção | Interface de atualização de dados |
| Direito de exclusão | Processo documentado de "esquecimento" com certificado |
| Portabilidade | Exportação em formato aberto (JSON/CSV) |
| Minimização de dados | Apenas dados necessários para a operação |
| DPO designado | Monteiro Aranha designa, Titanio colabora tecnicamente |
| Relatório de impacto (RIPD) | Elaborado antes da implantação |

### 8.2 CVM (Comissão de Valores Mobiliários)

- Releases e comunicações ao mercado passam por **aprovação humana obrigatória**
- IA nunca publica nada sem autorização explícita
- Registro de todas as interações relacionadas a RI
- Conformidade com prazos regulatórios (alertas automáticos)

### 8.3 SOX / Controles Internos

- Segregação de funções (quem solicita ≠ quem aprova)
- Audit trail completo e imutável
- Controles compensatórios documentados
- Testes de controle automatizados

---

## 9. RESPOSTA A INCIDENTES

### 9.1 Classificação de Incidentes

| Severidade | Exemplo | Tempo de Resposta | Escalonamento |
|-----------|---------|-------------------|---------------|
| **P0 — Crítico** | Vazamento de dados, invasão | 15 minutos | CEO + DPO + TI imediato |
| **P1 — Alto** | Tentativa de acesso não autorizado | 1 hora | TI + Titanio Ops |
| **P2 — Médio** | Falha de serviço, degradação | 4 horas | Titanio Ops |
| **P3 — Baixo** | Erro operacional, bug não-crítico | 24 horas | Titanio Ops |

### 9.2 Plano de Resposta (P0)

1. **Detecção** (0-15min): Alerta automático detecta anomalia
2. **Contenção** (15-60min): Isolar sistema afetado, preservar evidências
3. **Investigação** (1-24h): Análise forense, identificar causa raiz
4. **Erradicação** (24-72h): Remover ameaça, aplicar patches
5. **Recuperação** (72h+): Restaurar serviços a partir de backup limpo
6. **Pós-incidente** (1 semana): Relatório completo, lições aprendidas, melhorias

### 9.3 Comunicação de Incidentes

- Notificação à ANPD em até **72 horas** (conforme LGPD)
- Notificação aos titulares afetados conforme gravidade
- Relatório para o board da Monteiro Aranha em até **24 horas**
- Transparência total — sem ocultar falhas

---

## 10. CONTINUIDADE DE NEGÓCIO

### 10.1 Backup

| Tipo | Frequência | Retenção | Teste de Restore |
|------|-----------|----------|-----------------|
| Incremental | A cada 6 horas | 30 dias | Semanal |
| Completo | Diário (3h da manhã) | 90 dias | Mensal |
| Offsite | Semanal | 1 ano | Trimestral |
| Snapshot DB | A cada hora | 7 dias | Semanal |

### 10.2 RTO e RPO

| Métrica | Objetivo | Significado |
|---------|----------|-------------|
| **RPO** (Recovery Point Objective) | 1 hora | Máximo de dados perdidos em caso de falha |
| **RTO** (Recovery Time Objective) | 4 horas | Tempo máximo para restaurar operação |

### 10.3 Disaster Recovery

- Infraestrutura replicada em **zona secundária** (outro datacenter ou cloud privada)
- Failover automático para serviços críticos (dashboard, gateway WhatsApp)
- Teste de DR: **2x por ano** (simulação completa)
- Documentação de procedimentos acessível offline

---

## 11. GOVERNANÇA DA SEGURANÇA

### 11.1 Responsabilidades

| Papel | Responsável | Atribuições |
|-------|-------------|-------------|
| **CISO** | Monteiro Aranha | Governança geral de segurança |
| **DPO** | Monteiro Aranha | Conformidade LGPD |
| **Titanio Security Lead** | Titanio Studio | Segurança da aplicação e operação |
| **Admin TI** | Monteiro Aranha | Infraestrutura, rede, acessos |

### 11.2 Avaliações Periódicas

| Avaliação | Frequência | Responsável |
|-----------|-----------|-------------|
| Pentest (teste de invasão) | Semestral | Empresa terceira independente |
| Análise de vulnerabilidades | Mensal | Titanio + ferramenta automatizada |
| Revisão de acessos | Trimestral | Admin TI + Compliance |
| Auditoria de segurança | Anual | Auditoria externa |
| Treinamento de segurança | Semestral | Titanio + TI MA (para todos os usuários) |

### 11.3 SLA de Segurança

| Métrica | Compromisso |
|---------|-------------|
| Uptime da plataforma | 99.5% (excluindo manutenção programada) |
| Tempo de aplicação de patches críticos | 24 horas |
| Tempo de resposta a incidente P0 | 15 minutos |
| Backup testado com sucesso | 100% dos testes mensais |
| Zero vazamento de dados | Objetivo permanente |

---

## 12. ENCERRAMENTO DO CONTRATO

Caso o contrato seja encerrado:

1. **Entrega de dados:** Todos os dados são exportados e entregues à Monteiro Aranha em formato aberto
2. **Entrega ou destruição do modelo:** A critério da MA — entrega do modelo especialista ou destruição certificada
3. **Revogação de acessos:** Todos os acessos Titanio são revogados em até 24 horas
4. **Certificado de destruição:** Documento assinado confirmando que nenhum dado ou modelo permanece com a Titanio
5. **Período de transição:** 30 dias para transferência de conhecimento à nova equipe ou TI interna
6. **Auditoria final:** Verificação independente de que nada foi retido

---

## ASSINATURAS

| Parte | Nome | Cargo | Data |
|-------|------|-------|------|
| Titanio Studio | __________________ | CEO | ___/___/2026 |
| Monteiro Aranha | __________________ | CISO / Diretor TI | ___/___/2026 |

---

*Documento elaborado por Titanio Studio — Equipe de Segurança*  
*Versão 1.0 — 02/04/2026*  
*Sujeito a revisão após reunião com equipe de TI da Monteiro Aranha*
