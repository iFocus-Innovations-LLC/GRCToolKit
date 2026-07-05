#!/usr/bin/env python3
"""
Local Ansible runner API for GRCToolKit MVP demos.
Binds to 127.0.0.1 only. Started by scripts/run-local.sh alongside the static UI server.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, unquote

ROOT = Path(__file__).resolve().parents[1]
PLAYBOOKS_DIR = (ROOT / "ansible" / "playbooks").resolve()
DEFAULT_INVENTORY = PLAYBOOKS_DIR / "inventory.yml"
PLAYBOOK_TIMEOUT_SEC = 180
REPORT_DIR = Path("/tmp/grc-oscal-reports")
REPORT_PREFIX = "oscal-assessment-"
REPORT_SUFFIX = ".pdf"
MAX_REPORT_FILENAME = 128
MAX_JSON_BODY_BYTES = 10_000_000


def _build_playbook_allowlist() -> dict[str, Path]:
    """Build stem -> resolved path map at startup (CodeQL-safe allowlist)."""
    allowed: dict[str, Path] = {}
    for path in sorted(PLAYBOOKS_DIR.rglob("*.yml")):
        if path.name == "inventory.yml":
            continue
        stem = path.relative_to(PLAYBOOKS_DIR).with_suffix("").as_posix()
        resolved = path.resolve()
        if PLAYBOOKS_DIR not in resolved.parents and resolved.parent != PLAYBOOKS_DIR:
            continue
        allowed[stem] = resolved
    return allowed


def _build_playbook_commands(allowed: dict[str, Path], inventory: Path) -> dict[str, list[str]]:
    """Pre-build subprocess argv lists so runtime uses no user-controlled path strings."""
    inv_arg = str(inventory)
    return {
        stem: ["ansible-playbook", "-i", inv_arg, str(path), "--limit", "localhost"]
        for stem, path in allowed.items()
    }


ALLOWED_PLAYBOOKS: dict[str, Path] = _build_playbook_allowlist()
INVENTORY_PATH = DEFAULT_INVENTORY.resolve()
ALLOWED_CMD: dict[str, list[str]] = _build_playbook_commands(ALLOWED_PLAYBOOKS, INVENTORY_PATH)

sys.path.insert(0, str(ROOT / "scripts"))
try:
    from oscal_pdf import generate_oscal_report_files

    PDF_SUPPORT = True
except Exception:  # noqa: BLE001 — fpdf2 may be missing at import time
    generate_oscal_report_files = None  # type: ignore[assignment,misc]
    PDF_SUPPORT = False


def playbook_stem(name: str) -> str:
    return name.replace(".yml", "").replace(".yaml", "")


def resolve_playbook_stem(name: str) -> str:
    stem = playbook_stem(name.strip().lstrip("/"))
    if not stem or ".." in stem or stem.startswith("."):
        raise ValueError("Invalid playbook name")
    if stem not in ALLOWED_CMD:
        raise ValueError(f"Playbook not in allowlist: {stem}")
    return stem


def _extract_report_token(raw: str) -> str | None:
    """Return validated report id token from URL segment (no path components)."""
    segment = unquote(raw).split("/")[-1].split("\\")[-1]
    if not segment.startswith(REPORT_PREFIX) or not segment.endswith(REPORT_SUFFIX):
        return None
    middle = segment[len(REPORT_PREFIX) : -len(REPORT_SUFFIX)]
    if not middle or len(middle) > MAX_REPORT_FILENAME - len(REPORT_PREFIX) - len(REPORT_SUFFIX):
        return None
    token_chars: list[str] = []
    for ch in middle:
        if not (ch.isalnum() or ch in "-_"):
            return None
        token_chars.append(ch)
    return "".join(token_chars)


def _find_report_pdf(raw: str) -> tuple[str, Path] | None:
    """Locate report by scanning REPORT_DIR (avoids user-controlled path join)."""
    token = _extract_report_token(raw)
    if token is None:
        return None
    canonical = f"{REPORT_PREFIX}{token}{REPORT_SUFFIX}"
    for path in REPORT_DIR.glob(f"{REPORT_PREFIX}*.pdf"):
        if path.is_file() and path.name == canonical:
            return canonical, path
    return None


def control_id_from_playbook(stem: str) -> str:
    parts = stem.split("-")
    if len(parts) >= 2 and parts[0].isalpha() and parts[1].isdigit():
        return f"{parts[0].upper()}-{parts[1]}"
    return stem.upper()


def parse_recap(stdout: str) -> dict:
    recap = {"ok": 0, "changed": 0, "unreachable": 0, "failed": 0, "skipped": 0}
    match = re.search(
        r"failed=(\d+).*unreachable=(\d+).*ok=(\d+).*changed=(\d+).*skipped=(\d+)",
        stdout,
        re.DOTALL,
    )
    if match:
        recap["failed"] = int(match.group(1))
        recap["unreachable"] = int(match.group(2))
        recap["ok"] = int(match.group(3))
        recap["changed"] = int(match.group(4))
        recap["skipped"] = int(match.group(5))
    return recap


def build_findings(stem: str, stdout: str, stderr: str, exit_code: int) -> list:
    recap = parse_recap(stdout)
    control = control_id_from_playbook(stem)
    combined = "\n".join(part for part in (stdout, stderr) if part).strip()
    tail = combined[-6000:] if combined else "No Ansible output captured."

    if exit_code == 0 and recap["failed"] == 0 and recap["unreachable"] == 0:
        status = "PASS"
        message = "Playbook completed successfully (read-only validation)."
    else:
        status = "FAIL"
        message = (
            f"Playbook finished with failures (failed={recap['failed']}, "
            f"unreachable={recap['unreachable']})."
        )
        if re.search(
            r"BECOME|sudo password|Missing sudo|permission denied|Authentication failure|Incorrect sudo",
            combined,
            re.I,
        ):
            message += (
                " Root/sudo required — for production use manual CLI handoff per "
                "docs/ANSIBLE-AUDIT-OPERATIONS.md."
            )

    return [
        {
            "control": control,
            "status": status,
            "message": message,
            "evidence": tail,
        }
    ]


def validate_localhost_inventory(inventory_path: Path) -> None:
    """v1 API: only allow localhost / local connection inventories."""
    text = inventory_path.read_text(encoding="utf-8")
    if not re.search(r"^\s*localhost\s*:", text, re.MULTILINE):
        raise ValueError(
            "Inventory must include a localhost host for v1 API runs. "
            "Remote production scans require manual CLI per docs/ANSIBLE-AUDIT-OPERATIONS.md"
        )
    if re.search(r"ansible_host:\s*(?!127\.0\.0\.1|localhost|\s*$)", text):
        raise ValueError(
            "Remote ansible_host is not allowed via the local runner API in v1. "
            "Use manual CLI from a jump host per docs/ANSIBLE-AUDIT-OPERATIONS.md"
        )
    if "ansible_connection: local" not in text:
        raise ValueError(
            "Inventory must use ansible_connection: local for v1 API runs. "
            "See docs/ANSIBLE-AUDIT-OPERATIONS.md"
        )
    if re.search(r"ansible_connection:\s*(ssh|smart)\b", text):
        raise ValueError(
            "SSH/smart connection inventories are not allowed via the local runner API in v1. "
            "See docs/ANSIBLE-AUDIT-OPERATIONS.md"
        )


def run_playbook(playbook_name: str) -> dict:
    if shutil.which("ansible-playbook") is None:
        raise RuntimeError(
            "ansible-playbook not found. Install Ansible (e.g. brew install ansible)."
        )

    stem = resolve_playbook_stem(playbook_name)
    if not INVENTORY_PATH.is_file():
        raise FileNotFoundError(f"Inventory not found: {INVENTORY_PATH}")

    validate_localhost_inventory(INVENTORY_PATH)

    cmd = ALLOWED_CMD[stem]
    playbook_path = ALLOWED_PLAYBOOKS[stem]

    proc = subprocess.run(
        cmd,
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        timeout=PLAYBOOK_TIMEOUT_SEC,
    )

    stdout = proc.stdout or ""
    stderr = proc.stderr or ""
    findings = build_findings(stem, stdout, stderr, proc.returncode)

    return {
        "status": "completed" if proc.returncode == 0 else "failed",
        "exitCode": proc.returncode,
        "output": stdout,
        "stderr": stderr,
        "findings": findings,
        "playbook": stem,
        "inventory": str(INVENTORY_PATH),
        "command": cmd,
    }


class AnsibleRunnerHandler(BaseHTTPRequestHandler):
    server_version = "GRCToolKitAnsibleRunner/1.0"

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def _send_bytes(self, status: int, body: bytes, content_type: str, filename: str | None = None) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        if filename:
            self.send_header("Content-Disposition", 'attachment; filename="report.pdf"')
        self.end_headers()
        self.wfile.write(body)

    def _read_json_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length > MAX_JSON_BODY_BYTES:
            raise ValueError("Request body too large")
        raw = self.rfile.read(length).decode("utf-8") if length else "{}"
        try:
            return json.loads(raw or "{}")
        except json.JSONDecodeError as exc:
            raise ValueError("Invalid JSON body") from exc

    def _handle_report_download(self, path: str) -> None:
        prefix = "/api/reports/download/"
        if not path.startswith(prefix):
            self._send_json(404, {"error": "Not found"})
            return
        filename = unquote(path[len(prefix) :])
        found = _find_report_pdf(filename)
        if found is None:
            self._send_json(404, {"error": "Report not found"})
            return
        canonical_name, pdf_path = found
        body = pdf_path.read_bytes()
        self._send_bytes(200, body, "application/pdf", canonical_name)

    def _handle_oscal_pdf(self) -> None:
        try:
            data = self._read_json_body()
        except ValueError as exc:
            self._send_json(400, {"error": str(exc)})
            return

        compliance_report = data.get("complianceReport")
        if not compliance_report:
            self._send_json(400, {"error": "Missing complianceReport field"})
            return
        if not PDF_SUPPORT or generate_oscal_report_files is None:
            self._send_json(
                503,
                {
                    "error": "PDF support unavailable. Install: pip3 install -r scripts/requirements-local-demo.txt",
                },
            )
            return

        try:
            paths = generate_oscal_report_files(
                compliance_report,
                data.get("validationResults"),
                REPORT_DIR,
            )
            port = self.server.server_address[1]
            pdf_name = paths["pdfFilename"]
            download_url = f"http://127.0.0.1:{port}/api/reports/download/{pdf_name}"
            self._send_json(
                200,
                {
                    **paths,
                    "downloadUrl": download_url,
                    "reportDir": str(REPORT_DIR),
                },
            )
        except RuntimeError as exc:
            self._send_json(503, {"error": str(exc)})
        except Exception as exc:  # noqa: BLE001
            self._send_json(500, {"error": str(exc)})

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/health":
            self._send_json(
                200,
                {
                    "ok": True,
                    "ansible": shutil.which("ansible-playbook") is not None,
                    "pdf": PDF_SUPPORT,
                    "reportDir": str(REPORT_DIR),
                    "inventory": str(DEFAULT_INVENTORY),
                    "playbooksDir": str(PLAYBOOKS_DIR),
                },
            )
            return
        if path.startswith("/api/reports/download/"):
            self._handle_report_download(path)
            return
        self._send_json(404, {"error": "Not found"})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        if path == "/api/reports/oscal-pdf":
            self._handle_oscal_pdf()
            return
        if path != "/api/ansible/playbook":
            self._send_json(404, {"error": "Not found"})
            return

        try:
            data = self._read_json_body()
        except ValueError as exc:
            self._send_json(400, {"error": str(exc)})
            return

        playbook = data.get("playbook")
        if not playbook:
            self._send_json(400, {"error": "Missing playbook field"})
            return

        try:
            result = run_playbook(playbook)
            self._send_json(200, result)
        except (ValueError, FileNotFoundError) as exc:
            self._send_json(400, {"error": str(exc)})
        except subprocess.TimeoutExpired:
            self._send_json(504, {"error": f"Playbook timed out after {PLAYBOOK_TIMEOUT_SEC}s"})
        except RuntimeError as exc:
            self._send_json(503, {"error": str(exc)})
        except Exception as exc:  # noqa: BLE001 — surface runner failures to UI
            self._send_json(500, {"error": str(exc)})


def main() -> None:
    parser = argparse.ArgumentParser(description="GRCToolKit local Ansible runner API")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8081)
    args = parser.parse_args()

    if args.host not in ("127.0.0.1", "localhost", "::1"):
        raise SystemExit("Refusing to bind outside localhost")

    httpd = ThreadingHTTPServer((args.host, args.port), AnsibleRunnerHandler)
    httpd.allow_reuse_address = True
    print(f"Ansible runner API: http://{args.host}:{args.port}/health", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
