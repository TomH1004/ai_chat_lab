[Setup]
AppName=AI Chat Lab
AppVersion=1.0.0
AppPublisher=Tom Hempel
AppPublisherURL=https://tomhempel.com
AppSupportURL=
AppUpdatesURL=
DefaultDirName={autopf}\AI Chat Lab
DefaultGroupName=AI Chat Lab
AllowNoIcons=yes
LicenseFile=
OutputDir=dist\installer
OutputBaseFilename=AIChatLab-Setup
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\ai_chat_lab.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\AI Chat Lab"; Filename: "{app}\ai_chat_lab.exe"
Name: "{group}\{cm:UninstallProgram,AI Chat Lab}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\AI Chat Lab"; Filename: "{app}\ai_chat_lab.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ai_chat_lab.exe"; Description: "{cm:LaunchProgram,AI Chat Lab}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\AIChatLab"; ValueType: string; ValueName: "DisplayName"; ValueData: "AI Chat Lab"
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\AIChatLab"; ValueType: string; ValueName: "UninstallString"; ValueData: "{uninstallexe}"