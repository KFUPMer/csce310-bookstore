# Starts the three bookstore services, each in its own minimized window, and waits until they answer.
# Started by start-services.cmd. stop-services.cmd stops exactly what this started.
# Plain ASCII on purpose (problem log P-013).
# -Hidden: no windows at all. The apps use it to start the services themselves (LocalServices in bookstore-ui).
param([switch]$Hidden)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$pidFile = Join-Path $env:TEMP 'bookstore-services.pids'

function Test-Port($port) {
    $client = New-Object Net.Sockets.TcpClient
    try { $client.Connect('127.0.0.1', $port); return $true } catch { return $false } finally { $client.Close() }
}

$busy = @(8081, 8082, 8083 | Where-Object { Test-Port $_ })
if ($busy.Count -eq 3) { Write-Host 'The services are already running.' -ForegroundColor Green; exit 0 }
if ($busy.Count -gt 0) {
    Write-Host "Something is already using port(s) $($busy -join ', '). Run stop-services.cmd first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$root\services\.env")) { Write-Host 'Run setup.cmd first.' -ForegroundColor Red; exit 1 }

$style = if ($Hidden) { 'Hidden' } else { 'Minimized' }
Write-Host 'Starting user-service (8081), book-service (8082), order-service (8083)...'
$python = (Get-Command python).Source
$started = @(
    Start-Process java -ArgumentList '-jar', 'target\user-service.jar' -WorkingDirectory "$root\services\user-service" -WindowStyle $style -PassThru
    Start-Process $python -ArgumentList '-m', 'book_service' -WorkingDirectory "$root\services\book-service" -WindowStyle $style -PassThru
    Start-Process $python -ArgumentList '-m', 'order_service' -WorkingDirectory "$root\services\order-service" -WindowStyle $style -PassThru
)
($started | ForEach-Object { $_.Id }) -join ' ' | Set-Content $pidFile

$deadline = (Get-Date).AddSeconds(60)
do {
    Start-Sleep -Milliseconds 500
    $up = @(8081, 8082, 8083 | Where-Object { Test-Port $_ })
} while ($up.Count -lt 3 -and (Get-Date) -lt $deadline)

if ($up.Count -eq 3) {
    Write-Host 'All three services are running. Open Mooney''s or Mooney''s Manager from the Start menu.' -ForegroundColor Green
    if ($Hidden) { Write-Host 'They run in the background; stop them with stop-services.cmd.' }
    else { Write-Host 'Leave their three minimized windows open; stop them with stop-services.cmd.' }
    exit 0
}
$down = @(8081, 8082, 8083 | Where-Object { $_ -notin $up })
Write-Host "Port(s) $($down -join ', ') did not answer within 60 seconds. Open the minimized window of that service to read why." -ForegroundColor Red
Write-Host 'Usually: run setup.cmd first, or start MySQL or MongoDB.'
exit 1
