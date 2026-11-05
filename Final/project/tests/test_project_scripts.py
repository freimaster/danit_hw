"""Exercise the real .env loaders without invoking Terraform or AWS."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

POWERSHELL = shutil.which("powershell.exe") if os.name == "nt" else shutil.which("pwsh")


class ProjectScriptTests(unittest.TestCase):
    def run_apply(self, shell, password):
        source = Path(__file__).resolve().parents[1]
        temporary_root = source / ".tools"
        temporary_root.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temporary_root) as directory:
            root = Path(directory) / "renamed project with spaces"
            (root / "scripts").mkdir(parents=True)
            for name in ("project.sh", "project.ps1"):
                shutil.copyfile(source / "scripts" / name, root / "scripts" / name)
            (root / "terraform" / "cluster").mkdir(parents=True)
            (root / "terraform" / "cluster" / "terraform.tfvars").touch()
            (root / "k8s").mkdir()
            (root / "k8s" / "kustomization.yaml").write_text("newTag: published\n")
            (root / ".env").write_bytes(f"ARGOCD_ADMIN_PASSWORD={password}\r\n".encode())
            binaries = root / "bin"
            binaries.mkdir()
            marker = root / "terraform-called"
            stub = (
                "import os\nfrom pathlib import Path\n"
                "value = 'ok' if os.environ.get('TF_VAR_argocd_admin_password') == os.environ['EXPECTED_PASSWORD'] else 'mismatch'\n"
                "Path(os.environ['TEST_MARKER']).write_text(value)\n"
                "raise SystemExit(77)\n"
            )
            if os.name == "nt":
                (binaries / "fake_terraform.py").write_text(stub)
                (binaries / "terraform.cmd").write_text('@echo off\npython "%~dp0fake_terraform.py"\n')
            else:
                command = binaries / "terraform"
                command.write_text("#!/usr/bin/env python3\n" + stub)
                command.chmod(0o755)
            environment = dict(os.environ)
            environment.pop("ARGOCD_ADMIN_PASSWORD", None)
            environment.pop("TF_VAR_argocd_admin_password", None)
            environment.update(PATH=str(binaries) + os.pathsep + environment["PATH"],
                               EXPECTED_PASSWORD=password, TEST_MARKER=str(marker))
            if shell == "bash":
                command = ["bash", str(root / "scripts" / "project.sh"), "apply", "--auto-approve"]
            else:
                command = [shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                           str(root / "scripts" / "project.ps1"), "apply", "-AutoApprove"]
            result = subprocess.run(command, cwd=directory, env=environment, capture_output=True, text=True, timeout=30)
            return result, marker.read_text() if marker.exists() else None

    def check_literal(self, shell):
        password = 'Local$env#pass&x=42!"'
        result, marker = self.run_apply(shell, password)
        self.assertEqual(marker, "ok", result.stderr)
        self.assertNotEqual(result.returncode, 0)  # The stub stops before any real deployment.
        self.assertNotIn(password, result.stdout + result.stderr)

    def check_invalid(self, shell):
        for password in ("", "short", "x" * 73, "password with spaces"):
            with self.subTest(shell=shell, length=len(password)):
                result, marker = self.run_apply(shell, password)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(marker, "Invalid passwords must fail before Terraform is invoked.")

    @unittest.skipUnless(os.name != "nt" and shutil.which("bash"), "Bash test runs on Linux/WSL")
    def test_bash_preserves_literal_password_after_directory_rename(self):
        self.check_literal("bash")

    @unittest.skipUnless(os.name != "nt" and shutil.which("bash"), "Bash test runs on Linux/WSL")
    def test_bash_rejects_invalid_password_before_terraform(self):
        self.check_invalid("bash")

    @unittest.skipUnless(POWERSHELL, "Native PowerShell unavailable")
    def test_powershell_preserves_literal_password_after_directory_rename(self):
        self.check_literal(POWERSHELL)

    @unittest.skipUnless(POWERSHELL, "Native PowerShell unavailable")
    def test_powershell_rejects_invalid_password_before_terraform(self):
        self.check_invalid(POWERSHELL)
