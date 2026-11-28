#!/usr/bin/env python3
"""Private, loopback-only live Markdown preview for Emacs."""
import hashlib
import html
import mimetypes
import secrets
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

source = Path(sys.argv[1])
dist = Path(sys.argv[2]).resolve()
token = secrets.token_urlsafe(24)
prefix = "/" + token + "/"

STYLE = """
body { max-width: 980px; margin: 40px auto; padding: 0 28px;
 font: 16px/1.6 system-ui,sans-serif; color:#24292f; background:#fff; }
h1,h2 { border-bottom:1px solid #d0d7de; padding-bottom:.3em; }
pre { padding:16px; overflow:auto; background:#f6f8fa; border-radius:6px; }
code { font-family: ui-monospace,monospace; }
table { border-collapse:collapse; } th,td { border:1px solid #d0d7de; padding:6px 13px; }
blockquote { border-left:4px solid #d0d7de; padding-left:1em; color:#57606a; }
.mermaid svg { max-width:100%; height:auto; }
"""
JS = """
const version = document.querySelector('meta[name="preview-version"]').content;
const scrollKey = location.pathname + ':scroll';
window.scrollTo(0, Number(sessionStorage.getItem(scrollKey) || 0));
setInterval(async () => {
  try {
    const r = await fetch('version', {cache:'no-store'});
    if (r.ok && (await r.text()) !== version) {
      sessionStorage.setItem(scrollKey, String(window.scrollY));
      location.reload();
    }
  } catch (_) {}
}, 1000);
const blocks = [...document.querySelectorAll('pre.mermaid, pre > code.mermaid')];
if (blocks.length) {
  try {
    const {default: mermaid} = await import('./assets/mermaid.esm.min.mjs');
    mermaid.initialize({startOnLoad:false, securityLevel:'strict'});
    const nodes = blocks.map(block => {
      const node = document.createElement('div');
      node.className = 'mermaid';
      node.textContent = block.textContent;
      (block.tagName === 'CODE' ? block.parentElement : block).replaceWith(node);
      return node;
    });
    await mermaid.run({nodes});
  } catch (error) {
    const p = document.createElement('p');
    p.textContent = 'Mermaid: ' + error.message;
    document.body.prepend(p);
  }
}
"""

def digest(data):
    return hashlib.sha256(data).hexdigest()

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def send(self, data, mime, status=200):
        self.send_response(status)
        self.send_header("Content-Type", mime)
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy",
            "default-src 'none'; script-src 'self'; style-src 'unsafe-inline'; "
            "img-src 'self' data:; font-src 'self' data:; connect-src 'self'; "
            "base-uri 'none'; form-action 'none'; frame-ancestors 'none'")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.headers.get("Host") != f"127.0.0.1:{self.server.server_port}":
            self.send(b"Forbidden", "text/plain", 403)
            return
        path = unquote(urlsplit(self.path).path)
        if not path.startswith(prefix):
            self.send(b"Not found", "text/plain", 404)
            return
        route = path[len(prefix):]
        if route == "preview.js":
            self.send(JS.encode(), "text/javascript; charset=utf-8")
        elif route.startswith("assets/"):
            asset = (dist / route[len("assets/"):]).resolve()
            if not asset.is_relative_to(dist) or not asset.is_file():
                self.send(b"Not found", "text/plain", 404)
                return
            mime = "text/javascript" if asset.suffix in (".mjs", ".js") else (
                mimetypes.guess_type(asset.name)[0] or "application/octet-stream")
            self.send(asset.read_bytes(), mime)
        elif route in ("", "version"):
            data = source.read_bytes()
            version = digest(data)
            if route == "version":
                self.send(version.encode(), "text/plain")
                return
            result = subprocess.run(
                ["pandoc", "--from=gfm-raw_html", "--to=html5", "--standalone",
                 "--highlight-style=tango", "--metadata=pagetitle:Markdown preview"],
                input=data, capture_output=True, timeout=20)
            if result.returncode:
                body = "<pre>" + html.escape(result.stderr.decode(errors="replace")) + "</pre>"
                page = "<html><head></head><body>" + body + "</body></html>"
            else:
                page = result.stdout.decode("utf-8")
            head = (f'<meta name="preview-version" content="{version}">'
                    f'<style>{STYLE}</style><script type="module" src="preview.js"></script>')
            page = page.replace("</head>", head + "</head>", 1)
            self.send(page.encode(), "text/html; charset=utf-8")
        else:
            self.send(b"Not found", "text/plain", 404)

with ThreadingHTTPServer(("127.0.0.1", 0), Handler) as server:
    print(f"http://127.0.0.1:{server.server_port}{prefix}", flush=True)
    server.serve_forever()
