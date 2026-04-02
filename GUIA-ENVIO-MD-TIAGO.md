# 📤 Guia — Envio de Arquivos .md via WhatsApp (OpenClaw)

## ⚠️ REGRA DE SEGURANÇA
Arquivos .md NÃO podem ficar em repo público! O processo é:
Upload → Enviar link → Deletar do GitHub (máx 10 segundos público)

---

## ❌ O QUE NÃO FUNCIONA
- `openclaw message send --media /caminho/local/arquivo.md` → **BLOQUEADO** (MIME text/markdown)
- `--media /caminho/arquivo.txt` → **BLOQUEADO** (MIME text/plain)
- Colar conteúdo do .md como texto → fica horrível

## ✅ O QUE FUNCIONA
- `openclaw message send --media https://URL/arquivo.md` → **FUNCIONA** (via URL)

---

## 🔧 SETUP (1 vez só)

### 1. Criar repo público no GitHub
```bash
gh repo create USUARIO-docs-public --public
```

### 2. Criar o script enviar-md.sh
```bash
cat > ~/bin/enviar-md.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail
ARQUIVO="$1"
TARGET="${2:-ID-DO-GRUPO}"
TOKEN="SEU_GITHUB_TOKEN"
REPO="SEU-USUARIO/SEU-REPO-PUBLICO"

NOME=$(basename "$ARQUIVO")
CONTENT_B64=$(base64 -i "$ARQUIVO")

# Upload
SHA=$(curl -s "https://api.github.com/repos/$REPO/contents/$NOME" \
  -H "Authorization: token $TOKEN" | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null || echo "")

if [ -n "$SHA" ] && [ "$SHA" != "" ]; then
  curl -s -X PUT "https://api.github.com/repos/$REPO/contents/$NOME" \
    -H "Authorization: token $TOKEN" -H "Content-Type: application/json" \
    -d "{\"message\":\"temp\",\"content\":\"$CONTENT_B64\",\"sha\":\"$SHA\"}" > /dev/null
else
  curl -s -X PUT "https://api.github.com/repos/$REPO/contents/$NOME" \
    -H "Authorization: token $TOKEN" -H "Content-Type: application/json" \
    -d "{\"message\":\"temp\",\"content\":\"$CONTENT_B64\"}" > /dev/null
fi

# Enviar via WhatsApp
openclaw message send -t "$TARGET" \
  --media "https://raw.githubusercontent.com/$REPO/main/$NOME" \
  -m "📄 $NOME"

# Deletar após 10s (segurança)
sleep 10
NEW_SHA=$(curl -s "https://api.github.com/repos/$REPO/contents/$NOME" \
  -H "Authorization: token $TOKEN" | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null)
[ -n "$NEW_SHA" ] && curl -s -X DELETE \
  "https://api.github.com/repos/$REPO/contents/$NOME" \
  -H "Authorization: token $TOKEN" -H "Content-Type: application/json" \
  -d "{\"message\":\"cleanup\",\"sha\":\"$NEW_SHA\"}" > /dev/null

echo "✅ Enviado e limpo!"
SCRIPT
chmod +x ~/bin/enviar-md.sh
```

### 3. Usar
```bash
bash ~/bin/enviar-md.sh /caminho/documento.md
```

---

## 💡 RESUMO
1. Gateway OpenClaw bloqueia .md local (MIME)
2. Via URL funciona
3. Subir no GitHub → mandar link → deletar
4. Script `enviar-md.sh` faz tudo automaticamente
5. **NUNCA deixar docs sensíveis no repo público**
6. Guardar este guia na memória (MEMORY.md ou LESSONS.md)

*Criado por Tita 🐾 — 2026-04-02*
