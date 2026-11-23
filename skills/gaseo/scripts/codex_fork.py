#!/usr/bin/env python3
"""Fork a Codex thread through `codex app-server` (stdio JSON-RPC) and print the new thread id.

A live Codex thread is locked by the terminal that is writing it ("already has an active
writer"), so Paseo cannot resume it directly. The fork copies the conversation so far into a
new thread that Paseo can own; the original thread stays untouched in the terminal.

usage: codex_fork.py <thread_id> [--cwd DIR]     (codex binary: $GASEO_CODEX_BIN or `codex`)
stdout: the new thread id. Exit 1 with a reason on stderr on failure.
"""
import json, os, select, subprocess, sys, time

tid = sys.argv[1]
cwd = sys.argv[sys.argv.index("--cwd") + 1] if "--cwd" in sys.argv else None
p = subprocess.Popen([os.environ.get("GASEO_CODEX_BIN", "codex"), "app-server"], stdin=subprocess.PIPE,
                     stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)


def send(o):
    p.stdin.write(json.dumps(o) + "\n")
    p.stdin.flush()


def wait(id_, timeout=60):
    end = time.time() + timeout
    while time.time() < end:
        ready, _, _ = select.select([p.stdout], [], [], 1)
        if not ready:
            continue
        line = p.stdout.readline()
        if not line:
            break
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if o.get("id") == id_:
            return o
    return None


def fail(msg):
    p.kill()
    print(msg, file=sys.stderr)
    sys.exit(1)


send({"id": 1, "method": "initialize", "params": {"clientInfo": {"name": "gaseo", "version": "0.3.1"}}})
r = wait(1)
if not r or "error" in r:
    fail(f"codex app-server initialize failed: {json.dumps(r)[:300] if r else 'timeout'}")
send({"method": "initialized"})
params = {"threadId": tid}
if cwd:
    params["cwd"] = cwd
send({"id": 2, "method": "thread/fork", "params": params})
r = wait(2)
p.stdin.close()
p.terminate()
if not r or "error" in r:
    print(f"thread/fork failed: {json.dumps(r)[:300] if r else 'timeout'}", file=sys.stderr)
    sys.exit(1)
print(r["result"]["thread"]["id"])
