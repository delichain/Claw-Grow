param(
    [switch]$Yes,
    [switch]$AgentMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Exit-WithMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
    exit 1
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Exit-WithMessage "未检测到 WSL。请先安装 WSL（管理员 PowerShell 执行: wsl --install），然后重试。"
}

$distros = @(wsl.exe -l -q 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($distros.Count -eq 0) {
    Exit-WithMessage "WSL 已安装但没有可用发行版。请先完成 Ubuntu 等发行版初始化。"
}

$scriptArgs = @()
if ($Yes) { $scriptArgs += "-y" }
if ($AgentMode) { $scriptArgs += "--agent-mode" }

$argsSuffix = if ($scriptArgs.Count -gt 0) {
    " -s -- " + (($scriptArgs | ForEach-Object { "'$_'" }) -join " ")
} else {
    ""
}

$bashCommand = "set -euo pipefail; curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/clawgrow-agent.sh | bash$argsSuffix"

Write-Host "通过 WSL 执行 Claw Grow 安装向导..." -ForegroundColor Cyan
& wsl.exe -e bash -lc $bashCommand
exit $LASTEXITCODE
