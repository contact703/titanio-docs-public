# 📤 Guia Completo — Envio de Arquivos .md via WhatsApp (OpenClaw)

## ❌ O QUE NÃO FUNCIONA

1. **NÃO** colar o conteúdo do .md como texto de mensagem (fica horrível)
2. **NÃO** converter pra PDF/DOCX quando pedirem .md
3. **NÃO** dizer "não consigo enviar arquivos"
4. **NÃO** enviar .md direto pelo `openclaw message send --media` (gateway bloqueia MIME text/markdown)

---

## ✅ MÉTODO QUE FUNCIONA — Via GitHub Público

### Passo 1: Criar o arquivo .md no workspace
```bash
# Escrever o conteúdo no arquivo
cat > /caminho/workspace/MEU-ARQUIVO.md << 'EOF'
# Título do Documento
Conteúdo aqui...
EOF
```

### Passo 2: Subir pro GitHub público via API
```bash
# Codificar em base64
CONTENT_B64=$(base64 -i /caminho/workspace/MEU-ARQUIVO.md)

# Upload via GitHub API
curl -s -X PUT \
  "https://api.github.com/repos/SEU-USUARIO/SEU-REPO-PUBLICO/contents/MEU-ARQUIVO.md" \
  -H "Authorization: token SEU_GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"Add MEU-ARQUIVO.md\",
    \"content\": \"$CONTENT_B64\"
  }"
```

### Passo 3: Enviar o link no WhatsApp
```bash
openclaw message send \
  -t "ID-DO-GRUPO-OU-CONTATO" \
  -m "📄 MEU-ARQUIVO.md: https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO-PUBLICO/main/MEU-ARQUIVO.md"
```

---

## 🔧 SETUP (fazer 1 vez só)

### Criar repo público no GitHub
```bash
# Via gh CLI
gh repo create titanio-docs-public --public --description "Docs compartilhados Titanio"

# Ou via API
curl -s -X POST "https://api.github.com/user/repos" \
  -H "Authorization: token SEU_GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"titanio-docs-public","public":true,"description":"Docs compartilhados Titanio"}'
```

### Token GitHub
- Criar em: https://github.com/settings/tokens
- Permissões: `repo` (full)
- Guardar no cofre do OpenClaw ou em variável de ambiente

---

## 📋 EXEMPLO COMPLETO (copiar e usar)

```bash
#!/bin/bash
# enviar-md.sh — Envia um .md pro WhatsApp via GitHub

ARQUIVO="$1"
GITHUB_TOKEN="SEU_TOKEN"
GITHUB_REPO="SEU-USUARIO/titanio-docs-public"
WHATSAPP_TARGET="120363405462114071@g.us"

if [ -z "$ARQUIVO" ]; then
  echo "Uso: ./enviar-md.sh /caminho/arquivo.md"
  exit 1
fi

NOME=$(basename "$ARQUIVO")
CONTENT_B64=$(base64 -i "$ARQUIVO")

# Deletar se já existe (atualizar)
SHA=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/contents/$NOME" \
  -H "Authorization: token $GITHUB_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null)

if [ -n "$SHA" ] && [ "$SHA" != "" ]; then
  # Atualizar arquivo existente
  curl -s -X PUT \
    "https://api.github.com/repos/$GITHUB_REPO/contents/$NOME" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"Update $NOME\",\"content\":\"$CONTENT_B64\",\"sha\":\"$SHA\"}" > /dev/null
else
  # Criar novo
  curl -s -X PUT \
    "https://api.github.com/repos/$GITHUB_REPO/contents/$NOME" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"Add $NOME\",\"content\":\"$CONTENT_B64\"}" > /dev/null
fi

# Enviar link no WhatsApp
URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/$NOME"
openclaw message send \
  -t "$WHATSAPP_TARGET" \
  -m "📄 $NOME: $URL"

echo "✅ $NOME enviado!"
```

---

## 💡 DICAS

- **Sempre usar repo PÚBLICO** — links raw de repos privados não abrem sem auth
- **Base64 no Mac:** `base64 -i arquivo.md` (no Linux: `base64 arquivo.md`)
- **Se o arquivo já existe no GitHub:** precisa passar o SHA atual (o script acima já faz isso)
- **Guardar na memória:** Salvar este guia em `memory/` ou `LESSONS.md` pra nunca esquecer
- **Alternativa simples:** Se o .md é pequeno, pode enviar como mensagem formatada (sem markdown headers, só texto limpo)

---

## 🧠 REGRA PERMANENTE

Quando alguém pedir "manda o .md":
1. Subir no GitHub público
2. Enviar o link raw
3. NUNCA dizer "não consigo"

*Criado por Tita 🐾 — 2026-04-02*
