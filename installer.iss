[Setup]
AppId={{7F8E9D2A-4B1C-5F3A-9E2D-8A7B6C5D4E3F}}
AppName=Input VPN
AppVersion=1.0.5
DefaultDirName={autopf}\InputVPN
DefaultGroupName=Input VPN
OutputBaseFilename=InputVPN-Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\app_icon.ico

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Input VPN"; Filename: "{app}\input_vpn.exe"
Name: "{commondesktop}\Input VPN"; Filename: "{app}\input_vpn.exe"