# Sets up the three bookstore services on this Windows computer. Started by setup.cmd.
#
# What it does, in order, and safe to run again:
#   1. Java 21, Python 3.10+, MongoDB: installs any that is missing, with winget.
#   2. MySQL: must already be installed (see INSTALL.md); started if it is stopped.
#   3. The Python packages the services need.
#   4. services/.env and a dedicated MySQL account for the services (make_local_setup.py).
#   5. The database and that account: the ONLY question asked is the MySQL root password,
#      typed into MySQL's own prompt. It is never stored. Skipped if already done.
#   6. The test accounts and the 15 books, only if they are not there yet.
#   7. user-service.jar: built with Maven if it is not in the folder already.
#
# Plain ASCII on purpose: Windows PowerShell 5.1 misreads UTF-8 scripts (problem log P-013).

$ErrorActionPreference = 'Continue'   # native tools write warnings to stderr; exit codes are checked instead
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Step($text) { Write-Host ""; Write-Host "== $text" -ForegroundColor Cyan }
function Ok($text) { Write-Host "   OK  $text" -ForegroundColor Green }
function Info($text) { Write-Host "   $text" }
function Stop-Setup($text) {
    Write-Host ""
    Write-Host "   PROBLEM: $text" -ForegroundColor Red
    Write-Host "   Nothing was broken. Fix this, then run setup.cmd again. Help: INSTALL.md" -ForegroundColor Red
    exit 1
}
function Update-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Test-Port($port) {
    $client = New-Object Net.Sockets.TcpClient
    try { $client.Connect('127.0.0.1', $port); return $true } catch { return $false } finally { $client.Close() }
}
function Get-Major($command, $pattern) {
    # Through cmd, so a version printed on stderr (java does that) is read as text, not as an error.
    $text = cmd /c "$command 2>&1"
    if ($LASTEXITCODE -ne 0) { return 0 }
    $m = [regex]::Match(($text -join ' '), $pattern)
    if ($m.Success) { return [int]$m.Groups[1].Value } else { return 0 }
}
function Install-WithWinget($id, $what) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Stop-Setup "$what is missing and winget is not available to install it. Install $what yourself (INSTALL.md lists the downloads)."
    }
    Info "Installing $what with winget (Windows may ask for permission)..."
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    Update-Path
}

Write-Host "Bookstore services: setup" -ForegroundColor Cyan
Write-Host "Folder: $root"
Update-Path

Step "1. Java 21"
if ((Get-Major 'java -version' 'version "(\d+)') -lt 21) {
    Install-WithWinget 'EclipseAdoptium.Temurin.21.JRE' 'Java 21'
    if ((Get-Major 'java -version' 'version "(\d+)') -lt 21) { Stop-Setup 'Java 21 was installed but is not found yet. Close this window and run setup.cmd again.' }
}
Ok (cmd /c 'java -version 2>&1' | Select-Object -First 1)

Step "Python 3.10 or newer"
if ((Get-Major 'python --version' 'Python 3\.(\d+)') -lt 10) {
    Install-WithWinget 'Python.Python.3.12' 'Python 3.12'
    if ((Get-Major 'python --version' 'Python 3\.(\d+)') -lt 10) { Stop-Setup 'Python was installed but is not found yet. Close this window and run setup.cmd again.' }
}
Ok (cmd /c 'python --version 2>&1')

Step "MongoDB (port 27017)"
if (-not (Test-Port 27017)) {
    $service = Get-Service -Name 'MongoDB' -ErrorAction SilentlyContinue
    if (-not $service) { Install-WithWinget 'MongoDB.Server' 'MongoDB Server' }
    $service = Get-Service -Name 'MongoDB' -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne 'Running') {
        Info 'Starting the MongoDB service (Windows may ask for permission)...'
        Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', 'Start-Service MongoDB'
    }
    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-Port 27017) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
    if (-not (Test-Port 27017)) { Stop-Setup 'MongoDB is installed but not answering on port 27017. Start the "MongoDB" service in Windows Services.' }
}
Ok 'MongoDB is answering'

Step "2. MySQL (port 3306)"
$mysql = (Get-Command mysql -ErrorAction SilentlyContinue).Source
if (-not $mysql) {
    $mysql = Get-ChildItem 'C:\Program Files\MySQL\MySQL Server *\bin\mysql.exe' -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $mysql) { Stop-Setup 'MySQL Server 8 is not installed. Install it with the MySQL Installer (INSTALL.md, step 1), then run setup.cmd again.' }
if (-not (Test-Port 3306)) {
    $service = Get-Service -Name 'MySQL*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($service) {
        Info "Starting the $($service.Name) service (Windows may ask for permission)..."
        Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', "Start-Service $($service.Name)"
        Start-Sleep -Seconds 3
    }
    if (-not (Test-Port 3306)) { Stop-Setup 'MySQL is installed but not answering on port 3306. Start its service in Windows Services.' }
}
Ok "MySQL is answering ($mysql)"

Step "3. Python packages"
python -m pip install --disable-pip-version-check --quiet -r services\book-service\requirements.txt -r services\order-service\requirements.txt
if ($LASTEXITCODE -ne 0) { Stop-Setup 'Installing the Python packages failed (see the messages above). Check the internet connection.' }
Ok 'flask, waitress, pymongo, mysql-connector-python, requests, bcrypt'

Step "4. Settings (services\.env)"
python database\make_local_setup.py | Out-Null
if ($LASTEXITCODE -ne 0) { Stop-Setup 'Could not write services\.env.' }
Ok 'services\.env is ready (ignored by git; has a generated password for the services'' MySQL account)'

Step "5. The database and the services' MySQL account"
python database\check_setup.py
$state = $LASTEXITCODE
if ($state -eq 2 -and $env:BOOKSTORE_MYSQL_ROOT_PASSWORD) {
    # For automated tests only (the fresh-machine test on GitHub): no person is there to type it.
    # "(none)" stands for an empty root password, because Windows cannot hold an empty variable.
    Info 'Using the MySQL root password given to this automated test.'
    if ($env:BOOKSTORE_MYSQL_ROOT_PASSWORD -ne '(none)') { $env:MYSQL_PWD = $env:BOOKSTORE_MYSQL_ROOT_PASSWORD }
    cmd /c "`"$mysql`" -u root < `"$root\database\mysql\setup.local.sql`""
    Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    python database\check_setup.py
    $state = $LASTEXITCODE
}
if ($state -eq 2) {
    Write-Host ""
    Write-Host "   MySQL now asks for YOUR MySQL root password, once." -ForegroundColor Yellow
    Write-Host "   It creates the 'bookstore' database and an account that can use only that database." -ForegroundColor Yellow
    Write-Host "   The password goes straight to MySQL; nothing stores it." -ForegroundColor Yellow
    for ($try = 1; $try -le 3 -and $state -eq 2; $try++) {
        cmd /c "`"$mysql`" -u root -p < `"$root\database\mysql\setup.local.sql`""
        python database\check_setup.py
        $state = $LASTEXITCODE
    }
}
if ($state -ne 0) { Stop-Setup 'The databases are not ready (see the line above).' }
Ok 'MySQL and MongoDB are ready'

Step "6. Test accounts and books"
python database\seed.py --if-empty
if ($LASTEXITCODE -ne 0) { Stop-Setup 'Loading the test data failed (see the messages above).' }
Ok 'customer1 / customer123 and manager1 / manager123'

Step "7. user-service.jar"
$jar = 'services\user-service\target\user-service.jar'
if (-not (Test-Path $jar)) {
    if (Get-Command mvn -ErrorAction SilentlyContinue) {
        Info 'Building it with Maven (about a minute)...'
        mvn -q -f services\user-service\pom.xml package -DskipTests
    }
    if (-not (Test-Path $jar)) { Stop-Setup "$jar is missing. Use the Bookstore-Server zip from the GitHub release, which includes it, or install Maven." }
}
Ok $jar

Write-Host ""
Write-Host "Setup is complete." -ForegroundColor Green
Write-Host "Next: double-click start-services.cmd, then open Bookstore from the Start menu."
Write-Host "Bills are saved, but not emailed until a Gmail app password is put in services\.env (INSTALL.md, optional)."
exit 0
