"""Local operator helper. Never emit credentials or API response bodies."""
import base64
import json
import os
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

from nacl import encoding, public

root = Path(__file__).resolve().parents[1] / 'project'
env = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines() if line and not line.startswith('#'))
os.environ['GIT_TERMINAL_PROMPT'] = '0'
os.environ['GCM_INTERACTIVE'] = 'Never'
result = subprocess.run(['git', 'credential', 'fill'], input='protocol=https\nhost=github.com\n\n', capture_output=True, text=True, cwd=root)
if result.returncode:
    raise SystemExit('No GitHub credential available in Git Credential Manager.')
credential = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
token = credential.get('password')
if not token:
    raise SystemExit('Git Credential Manager did not return a token.')

def api(path, method='GET', body=None):
    req = urllib.request.Request('https://api.github.com' + path,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
                 'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'eks-project-setup'}, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            data = response.read()
            return json.loads(data) if data else None
    except urllib.error.HTTPError as exc:
        raise SystemExit(f'GitHub {method} {path}: HTTP {exc.code}') from None

repo = api('/repos/freimaster/test')
print('GitHub repository:', repo['full_name'], 'public:', not repo['private'], 'permissions:', repo.get('permissions'))
key = api('/repos/freimaster/test/actions/secrets/public-key')
box = public.SealedBox(public.PublicKey(key['key'].encode(), encoding.Base64Encoder()))
for name in ['DOCKERHUB_USERNAME', 'DOCKERHUB_TOKEN']:
    encrypted = base64.b64encode(box.encrypt(env[name].encode())).decode()
    api('/repos/freimaster/test/actions/secrets/' + name, 'PUT', {'encrypted_value': encrypted, 'key_id': key['key_id']})
    print('GitHub Secret configured:', name)
settings = api('/repos/freimaster/test/actions/permissions')
print('Actions enabled:', settings['enabled'])
