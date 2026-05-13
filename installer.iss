[Setup]
AppName=Input VPN
AppVersion=1.0.2
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