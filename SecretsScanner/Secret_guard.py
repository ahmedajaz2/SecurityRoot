#!/usr/bin/env python3
import re
import subprocess
import sys

# Define regex patterns for common secrets
SECRET_PATTERNS = {
    "AWS Access Key": re.compile(r'AKIA[0-9A-Z]{16}'),
    "Generic Secret": re.compile(r'(?i)(secret|api|token|key)[_\-]?[a-z]*\s*[:=]\s*[\'"]?[A-Za-z0-9/\+]{8,}[\'"]?'),
    "Slack Token": re.compile(r'xox[baprs]-[A-Za-z0-9-]{10,48}'),
    "Private Key": re.compile(r'-----BEGIN PRIVATE KEY-----'),
}

def get_staged_files():
    """Get list of staged files (added or modified)."""
    result = subprocess.run(['git', 'diff', '--cached', '--name-only'], capture_output=True, text=True)
    return result.stdout.strip().splitlines()

def scan_file_for_secrets(file_path):
    """Scan file for secret patterns."""
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    matches = []
    for lineno, line in enumerate(lines, 1):
        for name, pattern in SECRET_PATTERNS.items():
            if pattern.search(line):
                matches.append((file_path, lineno, name, line.strip()))
    return matches

def main():
    secrets_found = []

    for file in get_staged_files():
        if file.endswith(('.py', '.js', '.env', '.txt', '.json', '.yaml', '.yml')):
            secrets_found.extend(scan_file_for_secrets(file))
    
    if secrets_found:
        print("❌ Secrets detected in staged files:")
        for file, lineno, name, line in secrets_found:
            print(f"  - {name} in {file}:{lineno} → {line}")
        print("\n🛑 Commit aborted. Please remove the secrets.")
        sys.exit(1)
    else:
        print("✅ No secrets found. Safe to commit.")
        sys.exit(0)

if __name__ == "__main__":
    main()
