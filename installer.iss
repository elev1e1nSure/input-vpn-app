[Setup]
AppId={{7F8E9D2A-4B1C-5F3A-9E2D-8A7B6C5D4E3F}}
AppName=Input VPN
AppVersion=1.2.1
AppPublisher=Input VPN
DefaultDirName={autopf}\InputVPN
DefaultGroupName=Input VPN
OutputBaseFilename=InputVPN-Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\app_icon.ico
UninstallDisplayIcon={app}\input_vpn.exe
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
CloseApplications=yes
CloseApplicationsFilter=*input_vpn.exe,*sing-box.exe

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Input VPN"; Filename: "{app}\input_vpn.exe"; IconFilename: "{app}\input_vpn.exe"
Name: "{commondesktop}\Input VPN"; Filename: "{app}\input_vpn.exe"; IconFilename: "{app}\input_vpn.exe"

[Run]
Filename: "{app}\input_vpn.exe"; Description: "Запустить Input VPN"; Flags: nowait postinstall skipifsilent

[Code]

var
  DeleteDataPage: TNewNotebookPage;
  DeleteDataCheckbox: TNewCheckBox;

procedure InitializeUninstallProgressForm();
var
  PageNameLabel: TNewStaticText;
  PageDescLabel: TNewStaticText;
begin
  DeleteDataPage := TNewNotebookPage.Create(UninstallProgressForm);
  DeleteDataPage.Notebook := UninstallProgressForm.InnerNotebook;
  DeleteDataPage.Parent   := UninstallProgressForm.InnerNotebook;
  DeleteDataPage.Align    := alClient;

  PageNameLabel        := TNewStaticText.Create(DeleteDataPage);
  PageNameLabel.Parent := DeleteDataPage;
  PageNameLabel.Top    := ScaleY(8);
  PageNameLabel.Left   := ScaleX(0);
  PageNameLabel.Width  := DeleteDataPage.ClientWidth;
  PageNameLabel.Caption := 'Удаление Input VPN';
  PageNameLabel.Font.Style := [fsBold];

  PageDescLabel        := TNewStaticText.Create(DeleteDataPage);
  PageDescLabel.Parent := DeleteDataPage;
  PageDescLabel.Top    := PageNameLabel.Top + PageNameLabel.Height + ScaleY(4);
  PageDescLabel.Left   := ScaleX(0);
  PageDescLabel.Width  := DeleteDataPage.ClientWidth;
  PageDescLabel.Caption := 'Выберите дополнительные параметры удаления.';

  DeleteDataCheckbox        := TNewCheckBox.Create(DeleteDataPage);
  DeleteDataCheckbox.Parent := DeleteDataPage;
  DeleteDataCheckbox.Top    := PageDescLabel.Top + PageDescLabel.Height + ScaleY(16);
  DeleteDataCheckbox.Left   := ScaleX(0);
  DeleteDataCheckbox.Width  := DeleteDataPage.ClientWidth;
  DeleteDataCheckbox.Caption := 'Удалить настройки и логи (AppData)';
  DeleteDataCheckbox.Checked := False;

  UninstallProgressForm.InnerNotebook.ActivePage := DeleteDataPage;
  UninstallProgressForm.CancelButton.Caption := 'Удалить';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
  AppDataPath: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    // 1. Kill sing-box directly (app runs as admin now)
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM input_vpn.exe /F /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM sing-box.exe /F /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 2. Remove TUN adapter and reset DNS via PowerShell
    Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
      '-NoProfile -NonInteractive -Command "' +
        'Get-NetAdapter | Where-Object { $_.Name -like ''InputVPN*'' } | Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue; ' +
        'Get-NetAdapter | Where-Object { $_.Status -eq ''Up'' } | ForEach-Object { netsh interface ip set dns name=""$($_.Name)"" source=dhcp }"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 3. Clean up any leftover scheduled tasks from old installs
    Exec(ExpandConstant('{sys}\schtasks.exe'), '/delete /f /tn "InputVPNSingBox"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{sys}\schtasks.exe'), '/delete /f /tn "InputVPNStop"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 4. Optionally delete user data
    if Assigned(DeleteDataCheckbox) and DeleteDataCheckbox.Checked then
    begin
      AppDataPath := ExpandConstant('{userappdata}') + '\inputvpn';
      if DirExists(AppDataPath) then
        DelTree(AppDataPath, True, True, True);
    end;
  end;
end;