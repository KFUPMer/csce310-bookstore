# Stops the three bookstore services and confirms none is left. Started by stop-services.cmd.
# Plain ASCII on purpose (problem log P-013).

$ErrorActionPreference = 'Continue'
$pidFile = Join-Path $env:TEMP 'bookstore-services.pids'

if (Test-Path $pidFile) {
    # Only if it is still one of ours: after a restart Windows may have given that id to another program (P-024).
    foreach ($id in ((Get-Content $pidFile) -split ' ')) {
        $process = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -in 'java', 'python', 'pythonw') { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
    }
    Remove-Item $pidFile
}
# Also anything else still listening on the services' ports, if it is one of ours (java or python).
Start-Sleep -Milliseconds 800
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 8081, 8082, 8083 } | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    if ($process -and $process.ProcessName -in 'java', 'python', 'pythonw') { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
}
Start-Sleep -Milliseconds 800
$left = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 8081, 8082, 8083 })
if ($left.Count -eq 0) { Write-Host 'All three services are stopped.' -ForegroundColor Green; exit 0 }
Write-Host "Still listening: $(($left.LocalPort | Sort-Object -Unique) -join ', '). Close those windows by hand." -ForegroundColor Red
exit 1
