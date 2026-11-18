; Inno Setup script: one installer for both desktop apps.
; Built by .github/workflows/windows-release.yml, which passes the version:  ISCC /DAppVersion=1.0.0-beta.1 bookstore.iss
;
; Installs for the current user only (no administrator prompt) into
; %LOCALAPPDATA%\Programs\Mooneys, with two Start menu entries:
; "Mooney's" (customers) and "Mooney's Manager" (managers).
; The apps need the three services running: see INSTALL.md.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif

[Setup]
AppId={{6B0F2C1E-5E7A-4C55-9C3B-310B00C5A7E1}
AppName=Mooney's
AppVersion={#AppVersion}
AppPublisher=Mooney's (CSCE310 course project)
AppPublisherURL=https://github.com/KFUPMer/csce310-bookstore
DefaultDirName={autopf}\Mooneys
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=Mooneys-Apps-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=Mooney's (customer and manager apps)
UninstallDisplayIcon={app}\Customer\customer_app.exe
LicenseFile=..\LICENSE

[Files]
Source: "..\clients\customer-app\build\windows\x64\runner\Release\*"; DestDir: "{app}\Customer"; Flags: recursesubdirs ignoreversion
Source: "..\clients\management-app\build\windows\x64\runner\Release\*"; DestDir: "{app}\Manager"; Flags: recursesubdirs ignoreversion
Source: "..\INSTALL.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Mooney's"; Filename: "{app}\Customer\customer_app.exe"; Comment: "Search books, order, and see your bills"
Name: "{autoprograms}\Mooney's Manager"; Filename: "{app}\Manager\management_app.exe"; Comment: "Orders, payments, and books"
Name: "{autodesktop}\Mooney's"; Filename: "{app}\Customer\customer_app.exe"; Tasks: desktopicons
Name: "{autodesktop}\Mooney's Manager"; Filename: "{app}\Manager\management_app.exe"; Tasks: desktopicons

[Tasks]
Name: "desktopicons"; Description: "Put Mooney's and Mooney's Manager on the desktop"

[Run]
Filename: "{app}\Customer\customer_app.exe"; Description: "Open Mooney's now (start the services first)"; Flags: nowait postinstall skipifsilent unchecked
