$toolsRoot = $PSScriptRoot
$env:PYTHONPATH = Join-Path $toolsRoot 'python'
$env:PATH = "$toolsRoot;$(Join-Path $toolsRoot 'terraform');$(Join-Path $toolsRoot 'helm/windows-amd64');$env:PATH"
foreach ($line in Get-Content -LiteralPath (Join-Path $toolsRoot '../project/.env')) {
    if ($line -and -not $line.StartsWith('#')) {
        $pair = $line -split '=', 2
        [Environment]::SetEnvironmentVariable($pair[0], $pair[1], 'Process')
    }
}
$env:AWS_PAGER = ''
if ($env:GITHUB_TOKEN) { $env:TF_VAR_git_token = $env:GITHUB_TOKEN }
if ($env:ARGOCD_ADMIN_PASSWORD) { $env:TF_VAR_argocd_admin_password = $env:ARGOCD_ADMIN_PASSWORD }
