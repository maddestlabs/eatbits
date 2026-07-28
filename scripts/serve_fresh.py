import os
import sys
import time
import socket
import subprocess
import webbrowser
import http.server
import socketserver
import argparse
import shutil

PID_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".server.pid")
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Explicitly instruct browsers NOT to cache any files
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, format, *args):
        # Keep terminal log clean
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")

def stop_existing_server():
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            print(f"[+] Stopping existing server process (PID: {pid})...")
            if os.name == 'nt':
                subprocess.run(["taskkill", "/F", "/PID", str(pid)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            else:
                os.kill(pid, 9)
            time.sleep(0.5)
        except Exception as e:
            pass
        finally:
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)

def find_random_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]

def build_flutter_web(wasm=False, profile=False):
    print("=" * 60)
    print("[+] Building Flutter Web application...")
    print("=" * 60)
    
    flutter_bin = shutil.which("flutter") or shutil.which("flutter.bat") or ("flutter.bat" if os.name == 'nt' else "flutter")
    cmd = [flutter_bin, "build", "web"]
    if wasm:
        cmd.append("--wasm")
    if profile:
        cmd.append("--profile")
        
    res = subprocess.run(cmd, cwd=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."), shell=(os.name == 'nt'))
    if res.returncode != 0:
        print("[!] Flutter build failed. Exiting.")
        sys.exit(res.returncode)

def main():
    parser = argparse.ArgumentParser(description="Rebuild Flutter Web and serve on a fresh random port with no-cache headers.")
    parser.add_argument("--port", type=int, default=0, help="Port number to listen on (0 for random)")
    parser.add_argument("--no-build", action="store_true", help="Skip rebuilding Flutter web and only start server")
    parser.add_argument("--wasm", action="store_true", help="Build with --wasm flag")
    parser.add_argument("--profile", action="store_true", help="Build with --profile flag")
    parser.add_argument("--no-browser", action="store_true", help="Do not automatically open browser")
    args = parser.parse_args()

    stop_existing_server()

    if not args.no_build:
        build_flutter_web(wasm=args.wasm, profile=args.profile)

    if not os.path.exists(WEB_DIR):
        print(f"[!] Web build directory not found at: {WEB_DIR}")
        print("[!] Run without --no-build to compile first.")
        sys.exit(1)

    # Register MIME types for WASM and JS
    http.server.SimpleHTTPRequestHandler.extensions_map.update({
        '.wasm': 'application/wasm',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.html': 'text/html',
        '.css': 'text/css',
    })

    port = args.port if args.port > 0 else find_random_port()
    url = f"http://localhost:{port}"

    # Save PID
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    print("\n" + "=" * 60)
    print(f"  [+] FRESH FLUTTER WEB SERVER STARTED")
    print(f"  URL: {url}")
    print(f"  Port: {port} (Randomly assigned)")
    print(f"  Cache-Control: DISABLED (no-store, no-cache)")
    print("=" * 60 + "\n")

    if not args.no_browser:
        print(f"[+] Opening browser at {url}...")
        webbrowser.open(url)

    try:
        with socketserver.TCPServer(("127.0.0.1", port), NoCacheHTTPRequestHandler) as httpd:
            print("[+] Press Ctrl+C to stop the server.\n")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[+] Server stopped by user.")
    finally:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)

if __name__ == "__main__":
    main()
