# GitLab Runner on Proxmox VE 9

This project does two things:

1. Deploys a VM in Proxmox with Docker and GitLab Runner
2. Runs CI/CD for the Node.js app from `src/app`

The Ansible part is used only to prepare the runner VM.  
The Node.js app from `src/app` is pushed as a separate repository to GitLab, and its pipeline is started by `src/app/.gitlab-ci.yml`.

## Infrastructure

- Proxmox VE 9 host
- Proxmox node
- GitLab instance
- Optional GitLab Container Registry or Docker Hub
- Runner VM on Ubuntu Server 24.04 LTS
- SSH access to the runner VM by private key

All environment-specific values should be stored in your local `env.yml` and GitLab CI/CD variables.

## What Must Already Exist

Before running Ansible, make sure you already have:

1. A working Proxmox VE 9 server
2. A working GitLab server
3. An Ubuntu 24.04 VM template in Proxmox
4. SSH access by key to the future runner VM
5. A GitLab runner authentication token with prefix `glrt-`
6. A Docker Hub account

## Ubuntu Template Requirements

The Ubuntu template in Proxmox must include:

1. Ubuntu Server 24.04 LTS
2. Cloud-init
3. `qemu-guest-agent`
4. Existing user `default-user`
5. SSH server
6. Configured network interface `net0`

The playbook updates these cloud-init values:

1. `ciuser`
2. `sshkeys`
3. `ipconfig0`
4. `nameservers`

## Required Tools on the Control Machine

Install these before the first run:

1. `ansible` or `ansible-core`
2. Python packages `proxmoxer` and `requests`
3. Ansible collection `community.proxmox`

Commands:

```bash
python3 -m pip install --user proxmoxer requests
ansible-galaxy collection install community.proxmox
ansible-galaxy collection list | grep community.proxmox
```

## Configure Ansible

Go to the Ansible directory:

```bash
cd /path/to/project/src
```

Create `env.yml` if needed:

```bash
cp env.yml.example env.yml
```

Open it and fill in real values:

```bash
nano env.yml
```

Pay special attention to:

- `proxmox_api_password`
- `gitlab_runner_auth_token`
- `runner_ssh_private_key_file`
- `gitlab_registry_host`
- `gitlab_registry_port`
- `runner_ip`
- `runner_vm_id`
- `runner_vm_name`

Important:

- `gitlab_runner_auth_token` must start with `glrt-`
- do not use `glpat-...`
- do not use deprecated registration token workflow
- when using a `glrt-` runner authentication token, tags and similar runner settings must be configured in GitLab, not passed to `gitlab-runner register`

If you use an HTTP registry, Docker on the runner VM must end up with a config like this:

```json
{
  "insecure-registries": [
    "registry.example.local:5050"
  ]
}
```

## Deploy Runner VM

Run:

```bash
ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=deploy
```

This command:

1. Creates or reuses the runner VM
2. Configures CPU, RAM, SSH, and network
3. Installs Docker
4. Installs GitLab Runner
5. Registers the runner in GitLab

The playbook is designed to be idempotent:

1. It does not clone the VM again if it already exists
2. It safely reapplies VM settings
3. It skips runner registration if the expected token is already configured

No `meta: refresh_inventory` is required here. `add_host` is enough for the second play.

## Check That Runner VM Works

Connect to the runner VM:

```bash
ssh -i /path/to/private/key <runner_ssh_user>@<runner_ip>
```

Check Docker:

```bash
sudo docker version
```

Check GitLab Runner:

```bash
sudo gitlab-runner status
```

If both commands work, the VM is ready for CI/CD jobs.

Before running pipelines with a `glrt-` runner authentication token, open GitLab and configure runner tags in the UI:

1. Go to `Project -> Settings -> CI/CD -> Runners`
2. Open your runner, for example `proxmox-docker-runner`
3. Add tags such as `docker`, `dind`, and `proxmox`
4. Make sure the runner is allowed to pick jobs that match your pipeline tags

If your jobs stay in `pending` or `stuck`, the most common cause is a tag mismatch between `src/app/.gitlab-ci.yml` and the tags configured on the runner in GitLab.

## CI/CD for Node.js App

The Node.js app lives in:

```bash
src/app
```

If you push only the app to your GitLab repository, then `.gitlab-ci.yml` must be inside `src/app`, and that is how this project is set up now.

Pipeline file:

- `src/app/.gitlab-ci.yml`

Pipeline flow:

1. Build a Docker image for testing
2. Run tests inside the container
3. If tests pass and the branch is the default branch:
4. Log in to Docker Hub
5. Build runtime image
6. Push image to Docker Hub

## GitLab CI/CD Variables

Add these variables in your GitLab project:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

## Push the App and Trigger Pipeline

Go to the app repository:

```bash
cd /path/to/project/src/app
```

Add files:

```bash
git add .
```

Create commit:

```bash
git commit -m "Add GitLab CI pipeline"
```

Push to your GitLab repository:

```bash
git push origin <your-branch>
```

After push:

1. Open GitLab
2. Go to `CI/CD`
3. Open `Pipelines`
4. Check that `test` starts
5. Check that `publish` starts after successful tests

## Check Result in Docker Hub

Pull the latest image:

```bash
docker pull <dockerhub-username>/forstep2:latest
```

If the image is downloaded successfully, the pipeline worked correctly.

## Stop or Remove Runner VM

Stop the VM:

```bash
ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=stop
```

Destroy the VM:

```bash
ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=destroy
```

## Short Full Order

1. `cd /path/to/project/src`
   Go to the Ansible directory

2. `cp env.yml.example env.yml`
   Create config file

3. `nano env.yml`
   Fill in real values

4. `python3 -m pip install --user proxmoxer requests`
   Install Python dependencies

5. `ansible-galaxy collection install community.proxmox:==9.1.0`
   Install Ansible collection

6. `ansible-galaxy collection list | grep community.proxmox`
   Verify the collection

7. `ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=deploy`
   Deploy runner VM

8. `ssh -i /path/to/private/key <runner_ssh_user>@<runner_ip>`
   Connect to runner VM

9. `sudo docker version`
   Check Docker

10. `sudo gitlab-runner status`
    Check GitLab Runner

11. `cd /path/to/project/src/app`
    Go to app repository

12. `git add .`
    Add changes

13. `git commit -m "Add GitLab CI pipeline"`
    Create commit

14. `git push origin <your-branch>`
    Push and trigger pipeline

15. Open GitLab → `CI/CD` → `Pipelines`
    Check jobs

16. `docker pull <dockerhub-username>/forstep2:latest`
    Verify pushed image

17. `cd /path/to/project/src`
    Return to Ansible directory

18. `ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=stop`
    Stop VM

19. `ansible-playbook runner-lifecycle.yml -i 'localhost,' -e @env.yml -e action=destroy`
    Remove VM

## Troubleshooting

- If `deploy` fails, check Proxmox access, VM template name, VM ID, and SSH key path.
- If SSH to the VM fails, check cloud-init, the `default-user`, and network settings.
- If Docker cannot reach the registry, check your registry host, port, and Docker insecure registry config.
- If runner registration fails, check that the token starts with `glrt-`.
- If pipeline does not start, make sure `.gitlab-ci.yml` is in the root of the GitLab repository for the app.
