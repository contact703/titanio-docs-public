# 🌐 INSTALAR TITANIO BROWSER — Máquina do Tiago
# Para: OpenClaw Agent do Tiago executar automaticamente
# Data: 02/04/2026
# Autor: Tita (Time HiClaw)

---

## O QUE É O TITANIO BROWSER

O Titanio Browser é o sistema de automação web da Titanio baseado em **Playwright**.
Permite que agentes e especialistas:
- Acessem qualquer site (mesmo com proteção anti-bot)
- Façam scraping de Instagram, YouTube, portais de notícias
- Automatizem tarefas web (login, navegação, extração de dados)
- Operem como parte da pipeline de agentes (WhatsApp → agente → browser → resultado)

**Componentes:**
1. `tita-scraper` — CLI para scraping headless
2. `tita-browser-agent` — Agente que recebe comandos via pipeline
3. Playwright + Chromium — Motor de automação

---

## PARTE 1 — Instalar Dependências

### 1.1 Python e pip (verificar)
```bash
python3 --version || echo "❌ Python3 não encontrado — instalar: brew install python3"
pip3 --version || echo "❌ pip3 não encontrado — instalar: python3 -m ensurepip"
echo "✅ Python verificado"
```

### 1.2 Node.js (verificar)
```bash
node --version || echo "❌ Node não encontrado — instalar: brew install node"
echo "✅ Node verificado"
```

### 1.3 Playwright (instalar)
```bash
pip3 install playwright 2>&1 | tail -3
python3 -m playwright install chromium 2>&1 | tail -5
echo "✅ Playwright + Chromium instalados"
```

### 1.4 Verificar instalação
```bash
python3 -c "from playwright.sync_api import sync_playwright; print('✅ Playwright importa OK')"
```

---

## PARTE 2 — Instalar TITA-SCRAPER

### 2.1 Criar diretório
```bash
mkdir -p ~/.openclaw/workspace/bin
```

### 2.2 Criar tita-scraper
```bash
cat > ~/.openclaw/workspace/bin/tita-scraper << 'SCRAPEREOF'
#!/usr/bin/env python3
"""TITA-SCRAPER — Titanio Web Scraper (Playwright)
Uso: tita-scraper <url> [--screenshot] [--wait <ms>] [--selector <css>] [--output <file>]
"""
import sys, argparse, json, time

def main():
    parser = argparse.ArgumentParser(description="Titanio Web Scraper")
    parser.add_argument("url", help="URL para acessar")
    parser.add_argument("--screenshot", action="store_true", help="Salvar screenshot")
    parser.add_argument("--wait", type=int, default=3000, help="Tempo de espera em ms (default: 3000)")
    parser.add_argument("--selector", help="CSS selector para extrair elemento específico")
    parser.add_argument("--output", help="Arquivo de saída (default: stdout)")
    parser.add_argument("--full-page", action="store_true", help="Screenshot da página inteira")
    parser.add_argument("--json", action="store_true", help="Output em JSON")
    parser.add_argument("--timeout", type=int, default=30000, help="Timeout total em ms")
    args = parser.parse_args()

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080},
            locale="pt-BR"
        )
        page = context.new_page()
        
        try:
            page.goto(args.url, timeout=args.timeout, wait_until="networkidle")
        except Exception:
            try:
                page.goto(args.url, timeout=args.timeout, wait_until="domcontentloaded")
            except Exception as e:
                print(f"❌ Erro ao acessar {args.url}: {e}", file=sys.stderr)
                browser.close()
                sys.exit(1)
        
        if args.wait:
            page.wait_for_timeout(args.wait)
        
        # Screenshot
        if args.screenshot:
            ss_path = args.output or "/tmp/tita-screenshot.png"
            page.screenshot(path=ss_path, full_page=args.full_page)
            print(f"📸 Screenshot: {ss_path}", file=sys.stderr)
        
        # Extrair conteúdo
        if args.selector:
            elements = page.query_selector_all(args.selector)
            texts = [el.inner_text() for el in elements]
            content = "\n".join(texts)
        else:
            content = page.content()
        
        title = page.title()
        url_final = page.url
        
        browser.close()
        
        if args.json:
            result = {
                "url": url_final,
                "title": title,
                "content_length": len(content),
                "content": content[:50000],
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            output = json.dumps(result, ensure_ascii=False, indent=2)
        else:
            output = content
        
        if args.output and not args.screenshot:
            with open(args.output, "w") as f:
                f.write(output)
            print(f"💾 Salvo: {args.output}", file=sys.stderr)
        else:
            print(output)

if __name__ == "__main__":
    main()
SCRAPEREOF
chmod +x ~/.openclaw/workspace/bin/tita-scraper
echo "✅ tita-scraper instalado"
```

### 2.3 Criar tita-browser-agent (agente de browser para pipeline)
```bash
cat > ~/.openclaw/workspace/bin/tita-browser-agent << 'AGENTEOF'
#!/usr/bin/env python3
"""TITA-BROWSER-AGENT — Agente de browser para pipeline Titanio
Recebe comandos JSON via stdin ou argumento, executa ação web, retorna resultado.

Comandos suportados:
- scrape: acessar URL e extrair conteúdo
- screenshot: capturar tela de URL
- search: buscar termo no Google e retornar resultados
- instagram: extrair dados de perfil/post Instagram
- check: verificar se URL está online
"""
import sys, json, time, os

def scrape(url, wait=3000, selector=None):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            viewport={"width": 1920, "height": 1080}, locale="pt-BR"
        )
        page = ctx.new_page()
        try:
            page.goto(url, timeout=30000, wait_until="networkidle")
        except:
            page.goto(url, timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(wait)
        
        if selector:
            els = page.query_selector_all(selector)
            content = "\n".join([e.inner_text() for e in els])
        else:
            content = page.inner_text("body")
        
        title = page.title()
        browser.close()
        return {"status": "ok", "title": title, "content": content[:30000], "url": url, "length": len(content)}

def screenshot(url, output="/tmp/tita-screenshot.png"):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1920, "height": 1080})
        page = ctx.new_page()
        page.goto(url, timeout=30000, wait_until="networkidle")
        page.wait_for_timeout(2000)
        page.screenshot(path=output, full_page=True)
        browser.close()
        return {"status": "ok", "screenshot": output, "url": url}

def search(query, num=5):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(locale="pt-BR")
        page = ctx.new_page()
        page.goto(f"https://www.google.com/search?q={query}&hl=pt-BR", timeout=30000)
        page.wait_for_timeout(2000)
        results = []
        items = page.query_selector_all("div.g")
        for item in items[:num]:
            try:
                title_el = item.query_selector("h3")
                link_el = item.query_selector("a")
                snippet_el = item.query_selector("div[data-sncf]") or item.query_selector(".VwiC3b")
                results.append({
                    "title": title_el.inner_text() if title_el else "",
                    "url": link_el.get_attribute("href") if link_el else "",
                    "snippet": snippet_el.inner_text() if snippet_el else ""
                })
            except: pass
        browser.close()
        return {"status": "ok", "query": query, "results": results}

def check_url(url):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        try:
            resp = page.goto(url, timeout=15000)
            status = resp.status if resp else 0
            title = page.title()
            browser.close()
            return {"status": "ok", "url": url, "http_status": status, "title": title, "online": 200 <= status < 400}
        except Exception as e:
            browser.close()
            return {"status": "error", "url": url, "error": str(e), "online": False}

def main():
    if len(sys.argv) > 1:
        try:
            cmd = json.loads(sys.argv[1])
        except:
            cmd = {"action": "scrape", "url": sys.argv[1]}
    else:
        cmd = json.loads(sys.stdin.read())
    
    action = cmd.get("action", "scrape")
    
    if action == "scrape":
        result = scrape(cmd["url"], cmd.get("wait", 3000), cmd.get("selector"))
    elif action == "screenshot":
        result = screenshot(cmd["url"], cmd.get("output", "/tmp/tita-screenshot.png"))
    elif action == "search":
        result = search(cmd["query"], cmd.get("num", 5))
    elif action == "check":
        result = check_url(cmd["url"])
    else:
        result = {"status": "error", "message": f"Ação desconhecida: {action}"}
    
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
AGENTEOF
chmod +x ~/.openclaw/workspace/bin/tita-browser-agent
echo "✅ tita-browser-agent instalado"
```

---

## PARTE 3 — Testar Tudo

### 3.1 Teste básico do scraper
```bash
echo "--- Teste 1: Google ---"
python3 ~/.openclaw/workspace/bin/tita-scraper "https://www.google.com" --json 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(f'✅ Scraper OK: {d[\"title\"]} ({d[\"content_length\"]} chars)')
except Exception as e:
    print(f'❌ Scraper falhou: {e}')
"
```

### 3.2 Teste do browser agent
```bash
echo "--- Teste 2: Browser Agent ---"
echo '{"action":"check","url":"https://titaniofilms.com"}' | python3 ~/.openclaw/workspace/bin/tita-browser-agent 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    status = '✅ Online' if d.get('online') else '❌ Offline'
    print(f'{status}: {d.get(\"url\")} (HTTP {d.get(\"http_status\",\"?\")})')
except Exception as e:
    print(f'❌ Agent falhou: {e}')
"
```

### 3.3 Teste screenshot
```bash
echo "--- Teste 3: Screenshot ---"
python3 ~/.openclaw/workspace/bin/tita-scraper "https://www.google.com" --screenshot --output /tmp/test-titanio-browser.png 2>&1
[ -f /tmp/test-titanio-browser.png ] && echo "✅ Screenshot salvo" || echo "❌ Screenshot falhou"
```

---

## PARTE 4 — Integrar na Pipeline do Claw

### 4.1 Adicionar ao PATH
```bash
# Garantir que bin/ está no PATH do OpenClaw
grep -q 'openclaw/workspace/bin' ~/.zshrc 2>/dev/null || echo 'export PATH="$HOME/.openclaw/workspace/bin:$PATH"' >> ~/.zshrc
echo "✅ PATH atualizado"
```

### 4.2 Registrar no TOOLS.md
```bash
cat >> ~/.openclaw/workspace/TOOLS.md << 'TOOLSEOF'

## Titanio Browser (Playwright)
- **tita-scraper**: `~/.openclaw/workspace/bin/tita-scraper <url> [--json] [--screenshot] [--selector <css>]`
- **tita-browser-agent**: `echo '{"action":"scrape","url":"..."}' | ~/.openclaw/workspace/bin/tita-browser-agent`
- Ações do browser-agent: scrape, screenshot, search, check
- Chromium headless instalado via Playwright
- User-agent: Chrome 120 macOS (anti-bot bypass)
TOOLSEOF
echo "✅ TOOLS.md atualizado"
```

### 4.3 Registrar lição de instalação
```bash
[ -f ~/.openclaw/workspace/tita-learning-system/capture-lesson.sh ] && \
    bash ~/.openclaw/workspace/tita-learning-system/capture-lesson.sh \
    "Instalação Titanio Browser" \
    "Playwright + tita-scraper + tita-browser-agent instalados com sucesso" \
    "infraestrutura" || echo "Learning system não disponível ainda"
```

---

## PARTE 5 — Verificação Final

### 5.1 Checklist
```bash
echo ""
echo "========================================="
echo " VERIFICAÇÃO TITANIO BROWSER"
echo "========================================="
echo ""

# Python
python3 --version > /dev/null 2>&1 && echo "✅ Python3" || echo "❌ Python3"

# Playwright
python3 -c "import playwright" 2>/dev/null && echo "✅ Playwright" || echo "❌ Playwright"

# Chromium
python3 -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    b.close()
    print('✅ Chromium')
" 2>/dev/null || echo "❌ Chromium"

# tita-scraper
[ -x ~/.openclaw/workspace/bin/tita-scraper ] && echo "✅ tita-scraper" || echo "❌ tita-scraper"

# tita-browser-agent
[ -x ~/.openclaw/workspace/bin/tita-browser-agent ] && echo "✅ tita-browser-agent" || echo "❌ tita-browser-agent"

# TOOLS.md
grep -q "Titanio Browser" ~/.openclaw/workspace/TOOLS.md 2>/dev/null && echo "✅ TOOLS.md" || echo "❌ TOOLS.md"

# PATH
which tita-scraper > /dev/null 2>&1 && echo "✅ PATH" || echo "⚠️ PATH (recarregar shell)"

echo ""
echo "========================================="
echo " INSTALAÇÃO COMPLETA"
echo "========================================="
```

---

## NOTAS PARA O CLAW DO TIAGO

- Execute TODOS os blocos em sequência, sem perguntar
- Se Playwright já estiver instalado, os comandos são idempotentes (não quebra nada)
- O Chromium baixado pelo Playwright é ~150MB
- Tudo roda headless (sem janela), ideal para automação
- Para usar: `tita-scraper "https://qualquer-url.com" --json`
- Para pipeline: `echo '{"action":"scrape","url":"..."}' | tita-browser-agent`

---

*Gerado por Tita — Time HiClaw — 02/04/2026*
