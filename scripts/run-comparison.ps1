[CmdletBinding()]
param(
    [string]$SourcePath = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $ProjectRoot "php-src-php-8.3.36"
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker was not found. Install Docker Desktop and make sure it is running."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker is not running or is not ready. Start Docker Desktop and try again."
}

$TestFile = Join-Path $SourcePath "Zend	estsoom_after_main_script.phpt"
$RunnerFile = Join-Path $SourcePath "run-tests.php"

if (-not (Test-Path $TestFile)) {
    throw "Could not find the regression test at $TestFile. Download and extract the PHP source tag php-8.3.36, or pass -SourcePath with the extracted source folder."
}
if (-not (Test-Path $RunnerFile)) {
    throw "Could not find run-tests.php in: $SourcePath"
}

$SourcePath = (Resolve-Path $SourcePath).Path
$Results = @()

foreach ($Version in @("8.3.35", "8.3.36")) {
    $OutputDirectory = Join-Path $ProjectRoot "results-$Version"
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    $LogPath = Join-Path $OutputDirectory "console-output.txt"

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "Running oom_after_main_script.phpt with PHP $Version"
    Write-Host "Log: $LogPath"
    Write-Host "============================================================"

    & docker run --rm --mount "type=bind,source=$SourcePath,target=/src" -w /src "php:$Version-cli" php /src/run-tests.php --show-diff --keep-all Zend/tests/oom_after_main_script.phpt 2>&1 | Tee-Object -FilePath $LogPath
    $ExitCode = $LASTEXITCODE

    $Results += [PSCustomObject]@{
        PHPVersion = $Version
        RunnerExitCode = $ExitCode
        Log = $LogPath
    }
}

Write-Host ""
Write-Host "Comparison runs completed. Review the test summary in each log:"
$Results | Format-Table -AutoSize
Write-Host "Note: a non-zero test-runner exit code can be expected for the pre-patch version."
Write-Host "Interpret the PASS/FAIL test result, not just the process exit code."
