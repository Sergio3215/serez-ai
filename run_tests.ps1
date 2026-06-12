# ── serez-ai Test Runner ─────────────────────────────────────────────────────
# Usage: .\run_tests.ps1 [-sz <ruta>] [-filter <str>]
# CWD = serez-ai/ → import "src/training/losses" etc. resuelven localmente.
param([string]$sz = "", [string]$filter = "")

$repo = $PSScriptRoot

if (-not $sz) {
    foreach ($c in @(
        (Join-Path $repo "..\Serez-code\target\release\sz.exe"),
        (Join-Path $repo "..\Serez-code\target\debug\sz.exe"))) {
        if (Test-Path $c) { $sz = $c; break }
    }
}
if (-not $sz -or -not (Test-Path $sz)) {
    Write-Host "sz no encontrado. Use: .\run_tests.ps1 -sz <ruta>" -ForegroundColor Red
    exit 1
}

$framework = Join-Path $repo "tests\framework.sz"
$fwContent = Get-Content $framework -Raw

$tests = Get-ChildItem (Join-Path $repo "tests") -Filter "*.sz" |
         Where-Object { $_.Name -ne "framework.sz" } |
         Sort-Object Name
if ($filter) { $tests = $tests | Where-Object { $_.Name -like "*$filter*" } }

Write-Host "serez-ai tests ($($tests.Count)) — sz: $sz`n" -ForegroundColor Cyan
$pass = 0; $fail = 0

foreach ($f in $tests) {
    $tmp = [System.IO.Path]::GetTempFileName() + ".sz"
    Set-Content -Path $tmp -Value ($fwContent + "`n" + (Get-Content $f.FullName -Raw)) -NoNewline

    $out = [System.IO.Path]::GetTempFileName()
    $err = [System.IO.Path]::GetTempFileName()
    $p = Start-Process -FilePath $sz -ArgumentList "`"$tmp`"" -NoNewWindow -PassThru `
         -WorkingDirectory $repo -RedirectStandardOutput $out -RedirectStandardError $err
    $code = 0; $stdout = ""; $stderr = ""
    if (-not $p.WaitForExit(60000)) { $p | Stop-Process -Force; $stderr = "TIMEOUT"; $code = 124 }
    else { $code = $p.ExitCode; $stdout = (Get-Content $out -Raw); $stderr = (Get-Content $err -Raw) }
    Remove-Item $tmp, $out, $err -ErrorAction SilentlyContinue

    $failed = ($code -ne 0) -or ($stdout -match "\[FAIL\]") -or ($stderr -match "❌")
    if ($failed) {
        Write-Host "[FAIL] $($f.Name) (exit $code)" -ForegroundColor Red
        if ($stderr) { ($stderr -split "`r?`n" | Select-Object -First 3) | ForEach-Object { Write-Host "       $_" -ForegroundColor Yellow } }
        ($stdout -split "`r?`n" | Where-Object { $_ -match "\[FAIL\]" } | Select-Object -First 3) | ForEach-Object { Write-Host "       $_" -ForegroundColor Yellow }
        $fail++
    } else {
        $sum = ($stdout -split "`r?`n" | Where-Object { $_ -match "Results:" } | Select-Object -Last 1)
        Write-Host "[PASS] $($f.Name)" -ForegroundColor Green
        if ($sum) { Write-Host "       $($sum.Trim())" -ForegroundColor Gray }
        $pass++
    }
}

Write-Host "`n────────────────────────────────"
Write-Host "TOTAL: $pass passed  $fail failed"
if ($fail -gt 0) { exit 1 } else { exit 0 }
