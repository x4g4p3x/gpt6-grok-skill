# Run a bounded Cursor CLI Grok worker in a specified project.
# The brief and workspace files read by the worker are sent to Cursor.
param(
    [Parameter(Mandatory = $true)]
    [string]$BriefPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Explore', 'Implement')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$Workspace,

    [ValidateNotNullOrEmpty()]
    [string]$Model = 'grok-4.7-high',

    [switch]$AllowDirty,
    [switch]$TrustWorkspace,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspacePath = (Resolve-Path -LiteralPath $Workspace -ErrorAction Stop).Path
$briefPathResolved = (Resolve-Path -LiteralPath $BriefPath -ErrorAction Stop).Path
$briefText = Get-Content -LiteralPath $briefPathResolved -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($briefText)) {
    throw "The worker brief is empty: $briefPathResolved"
}
if ($briefText.Length -gt 20000) {
    throw 'The worker brief exceeds 20,000 characters. Split it into a smaller delegated task.'
}

$agent = Get-Command agent -ErrorAction Stop
$git = Get-Command git -ErrorAction SilentlyContinue
$existingChanges = @()
if ($Mode -eq 'Implement') {
    if (-not $git) { throw 'Implementation requires Git so the worker diff can be reviewed.' }
    $safeDirectory = $workspacePath.Replace('\', '/')
    $repoRoot = (& $git.Source -c "safe.directory=$safeDirectory" -C $workspacePath rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
        throw 'Implementation requires a Git repository root as -Workspace.'
    }
    $repoRoot = (Resolve-Path -LiteralPath $repoRoot -ErrorAction Stop).Path
    if ($repoRoot -ne $workspacePath) {
        throw "Pass the Git repository root as -Workspace: $repoRoot"
    }
    $statusArgs = @('-c', "safe.directory=$safeDirectory", '-C', $workspacePath, 'status', '--porcelain', '--untracked-files=all', '--', '.')
    $relativeBrief = [IO.Path]::GetRelativePath($workspacePath, $briefPathResolved).Replace('\', '/')
    if (-not $relativeBrief.StartsWith('../') -and -not [IO.Path]::IsPathRooted($relativeBrief)) {
        $statusArgs += ":(exclude)$relativeBrief"
    }
    $existingChanges = @(& $git.Source @statusArgs)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the workspace before dispatch.' }
    if ($existingChanges.Count -gt 0 -and -not $AllowDirty) {
        throw "The workspace contains other changes. Use an isolated checkout, or pass -AllowDirty after reviewing them.`n$($existingChanges -join "`n")"
    }
}

$role = if ($Mode -eq 'Explore') {
    'Investigate only. Do not edit files. Return findings, file paths, open questions, and suggested checks.'
} else {
    'Implement only the delegated scope. Preserve existing work. Do not commit, push, merge, publish, or change unrelated files. Run the relevant checks and report only checks that completed.'
}

$prompt = @"
You are a scoped Grok worker for a Codex lead. Work in the specified project workspace.
Read AGENTS.md if present and follow relevant project validation guidance. $role
Return a concise handoff with: work done, exact files changed, completed validation and results, blockers, and decisions for the lead. The lead will inspect the diff and decide the next step.

DELEGATED BRIEF:
$briefText
"@

$agentArgs = @('--print', '--output-format', 'text', '--model', $Model, '--workspace', $workspacePath)
if ($TrustWorkspace) { $agentArgs += '--trust' }
if ($Mode -eq 'Explore') { $agentArgs += @('--mode', 'ask') }
else { $agentArgs += '--auto-review' }

if ($DryRun) {
    Write-Output "MODEL=$Model"
    Write-Output "MODE=$Mode"
    Write-Output "WORKSPACE=$workspacePath"
    Write-Output "BRIEF=$briefPathResolved"
    Write-Output "EXISTING_CHANGES=$($existingChanges.Count)"
    Write-Output 'DRY_RUN=YES'
    exit 0
}

$runId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N').Substring(0, 8)
$runDirectory = Join-Path ([IO.Path]::GetTempPath()) (Join-Path 'gpt6-grok-workers' $runId)
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
$transcript = Join-Path $runDirectory 'worker-output.txt'

& $agent.Source @agentArgs $prompt 2>&1 | Tee-Object -FilePath $transcript
$workerExit = $LASTEXITCODE
Write-Output "WORKER_TRANSCRIPT=$transcript"
Write-Output "WORKER_EXIT_CODE=$workerExit"
if ($workerExit -ne 0) { exit $workerExit }
