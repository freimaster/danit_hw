param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dns', 'apply', 'destroy', 'verify', 'validate')]
    [string]$Action,
    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot

# Values stay in this process and its children; they are never printed.
$envPath = Join-Path $projectRoot '.env'
if (Test-Path -LiteralPath $envPath) {
    foreach ($line in Get-Content -LiteralPath $envPath) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $pair = $line -split '=', 2
        if ($pair.Count -ne 2 -or $pair[0] -notmatch '^[A-Z][A-Z0-9_]*$') {
            throw 'Invalid .env line. Use NAME=value without shell commands.'
        }
        [Environment]::SetEnvironmentVariable($pair[0], $pair[1], 'Process')
    }
}
if ($env:GITHUB_TOKEN) { $env:TF_VAR_git_token = $env:GITHUB_TOKEN }
if ($env:ARGOCD_ADMIN_PASSWORD) { $env:TF_VAR_argocd_admin_password = $env:ARGOCD_ADMIN_PASSWORD }

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE)." }
}

function Set-ClusterContext {
    $clusterName = & terraform '-chdir=terraform/cluster' output -raw cluster_name
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read cluster state.' }
    $region = & terraform '-chdir=terraform/cluster' output -raw aws_region
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read cluster region.' }
    Invoke-Checked aws @('eks', 'update-kubeconfig', '--name', $clusterName, '--region', $region)
}

function Test-Deployment {
    Set-ClusterContext
    Invoke-Checked kubectl @('wait', '--for=condition=Ready', 'nodes', '--all', '--timeout=300s')
    $nodes = (& kubectl get nodes -o json | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0 -or $nodes.items.Count -ne 1) { throw 'Expected exactly one EKS node.' }
    Invoke-Checked kubectl @('-n', 'argocd', 'wait', 'application/backend', '--for=jsonpath={.status.sync.status}=Synced', '--timeout=600s')
    Invoke-Checked kubectl @('-n', 'argocd', 'wait', 'application/backend', '--for=jsonpath={.status.health.status}=Healthy', '--timeout=600s')
    Invoke-Checked kubectl @('-n', 'backend', 'rollout', 'status', 'deployment/backend', '--timeout=300s')
    $url = & terraform '-chdir=terraform/platform' output -raw app_url
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read app URL.' }
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -ne 200) { throw 'Backend did not return 200.' }
    Write-Output $response.Content
    Write-Output 'One Ready node, Argo CD Synced/Healthy, backend HTTP 200.'
}

$approvalArgs = @()
if ($AutoApprove) { $approvalArgs = @('-auto-approve') }

switch ($Action) {
    'dns' {
        Invoke-Checked terraform @('-chdir=terraform/dns', 'init', '-input=false', '-lockfile=readonly')
        Invoke-Checked terraform (@('-chdir=terraform/dns', 'apply') + $approvalArgs)
        Invoke-Checked terraform @('-chdir=terraform/dns', 'output', 'name_servers')
    }
    'validate' {
        Invoke-Checked python @('-m', 'unittest', 'discover', '-s', 'tests', '-v')
        foreach ($part in @('dns', 'cluster', 'platform')) {
            Invoke-Checked terraform @("-chdir=terraform/$part", 'fmt', '-check')
            Invoke-Checked terraform @("-chdir=terraform/$part", 'init', '-backend=false', '-input=false', '-lockfile=readonly')
            Invoke-Checked terraform @("-chdir=terraform/$part", 'validate')
        }
        Invoke-Checked terraform @('-chdir=terraform/argocd-password', 'fmt', '-check', '-recursive')
        Invoke-Checked terraform @('-chdir=terraform/argocd-password', 'init', '-backend=false', '-input=false')
        Invoke-Checked terraform @('-chdir=terraform/argocd-password', 'test')
        Invoke-Checked helm @('lint', 'argocd')
        Invoke-Checked kubectl @('kustomize', 'k8s')
    }
    'apply' {
        if ($env:ARGOCD_ADMIN_PASSWORD -cnotmatch '^[!-~]{12,72}$') {
            throw 'Set ARGOCD_ADMIN_PASSWORD in .env: 12-72 ASCII characters without whitespace.'
        }
        if (-not (Test-Path -LiteralPath 'terraform/cluster/terraform.tfvars')) {
            throw 'Create terraform/cluster/terraform.tfvars from the example and set admin_cidrs.'
        }
        $imageConfig = Get-Content -LiteralPath 'k8s/kustomization.yaml' -Raw
        if ($imageConfig -match 'newTag:\s*bootstrap') {
            throw 'First push to GitHub, wait for CI to publish an image, then git pull --ff-only.'
        }
        foreach ($part in @('dns', 'cluster', 'platform')) {
            Invoke-Checked terraform @("-chdir=terraform/$part", 'init', '-input=false', '-lockfile=readonly')
            Invoke-Checked terraform (@("-chdir=terraform/$part", 'apply') + $approvalArgs)
        }
        Set-ClusterContext
        Invoke-Checked terraform @('-chdir=terraform/platform', 'output')
        Write-Output 'Delegate DNS to name_servers above, then run: ./scripts/project.ps1 verify'
    }
    'verify' { Test-Deployment }
    'destroy' {
        # Stop on error: Argo finalizers and the ELB must complete before deleting EKS.
        foreach ($part in @('platform', 'cluster', 'dns')) {
            if (Test-Path -LiteralPath "terraform/$part/terraform.tfstate") {
                Invoke-Checked terraform @("-chdir=terraform/$part", 'init', '-input=false', '-lockfile=readonly')
                $remaining = & terraform "-chdir=terraform/$part" state list
                if ($LASTEXITCODE -ne 0) { throw "Cannot read $part state." }
                $managed = @($remaining | Where-Object { $_ -and $_ -notmatch '(^|\.)data\.' })
                if ($managed.Count -eq 0) { continue }
                Invoke-Checked terraform (@("-chdir=terraform/$part", 'destroy') + $approvalArgs)
            }
        }
    }
}
