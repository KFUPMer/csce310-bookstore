# Tests a built installer the way a grader would use it: install silently for the current user,
# check what it installed, open both apps, then uninstall. Run by the release workflow after
# building (the development computer's Smart App Control blocks unsigned programs, P-017).
# Each line says what is expected; exits 1 if any check fails. Plain ASCII on purpose (P-013).
param([Parameter(Mandatory)][string]$Setup)

$ErrorActionPreference = 'Continue'
$dir = Join-Path $env:LOCALAPPDATA 'Programs\Mooneys'
$menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$failed = 0
function Expect($what, $ok) {
    if ($ok) { "PASS  $what" } else { "FAIL  $what"; $script:failed++ }
}

$p = Start-Process $Setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -PassThru -Wait
Expect "the installer finishes with exit code 0 (got $($p.ExitCode))" ($p.ExitCode -eq 0)
Expect "it installs into $dir, without an administrator" (Test-Path $dir)
foreach ($f in 'Customer\customer_app.exe', 'Customer\flutter_windows.dll', 'Customer\vcruntime140.dll', 'Customer\msvcp140.dll',
               'Customer\data\flutter_assets\AssetManifest.bin', 'Manager\management_app.exe', 'Manager\flutter_windows.dll', 'INSTALL.md') {
    Expect "it installs $f" (Test-Path (Join-Path $dir $f))
}
Expect 'the Start menu has Mooney''s' (Test-Path (Join-Path $menu 'Mooney''s.lnk'))
Expect 'the Start menu has Mooney''s Manager' (Test-Path (Join-Path $menu 'Mooney''s Manager.lnk'))
"      installed size: {0:N1} MB" -f ((Get-ChildItem $dir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB)

foreach ($exe in 'Customer\customer_app.exe', 'Manager\management_app.exe') {
    $app = Start-Process (Join-Path $dir $exe) -PassThru
    Start-Sleep -Seconds 10
    $app.Refresh()
    # Still running after 10 s: the engine, the DLLs, and the app's assets all loaded.
    Expect "$exe opens and keeps running (window title: '$($app.MainWindowTitle)')" (-not $app.HasExited)
    if (-not $app.HasExited) { $app.Kill() }
}

$p = Start-Process (Join-Path $dir 'unins000.exe') -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -PassThru -Wait
Start-Sleep -Seconds 3
Expect "the uninstaller finishes with exit code 0 (got $($p.ExitCode))" ($p.ExitCode -eq 0)
Expect 'it removes the apps' (-not (Test-Path (Join-Path $dir 'Customer\customer_app.exe')))
Expect 'it removes the Start menu entries' (-not (Test-Path (Join-Path $menu 'Mooney''s.lnk')))

if ($failed) { "$failed check(s) failed"; exit 1 }
'All installer checks passed'
exit 0
