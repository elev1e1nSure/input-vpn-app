[Setup]
AppId={{7F8E9D2A-4B1C-5F3A-9E2D-8A7B6C5D4E3F}}
AppName=Input VPN
AppVersion=1.2.9
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

procedure InitializeWizard();
var
  UninstKey: String;
  IsUpgrade: Boolean;
begin
  UninstKey := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7F8E9D2A-4B1C-5F3A-9E2D-8A7B6C5D4E3F}_is1';
  IsUpgrade := RegKeyExists(HKLM, UninstKey) or
               RegKeyExists(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{7F8E9D2A-4B1C-5F3A-9E2D-8A7B6C5D4E3F}_is1');
  if IsUpgrade then
    WizardForm.Caption := 'Обновление Input VPN';
end;

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
  OwnerPidFile: String;
  OwnerPidText: String;
  OwnerPid: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // 1. Kill the app itself
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM input_vpn.exe /F /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 2. Kill ONLY the sing-box.exe this app spawned, identified by owner.pid
    //    Third-party sing-box / VPN clients are never touched.
    OwnerPidFile := ExpandConstant('{userappdata}') + '\inputvpn\singbox\owner.pid';
    if FileExists(OwnerPidFile) then
    begin
      if LoadStringFromFile(OwnerPidFile, OwnerPidText) then
      begin
        OwnerPid := StrToIntDef(Trim(OwnerPidText), 0);
        if OwnerPid > 0 then
        begin
          Exec(ExpandConstant('{sys}\taskkill.exe'), '/PID ' + IntToStr(OwnerPid) + ' /F /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        end;
      end;
      DeleteFile(OwnerPidFile);
    end;

    // 3. Remove only the app's own TUN adapter. Do NOT reset DNS on physical
    //    adapters: the app runs sing-box in TUN mode (hijack-dns) and never
    //    reconfigures physical-NIC DNS, so a blanket DHCP reset would clobber
    //    users' manually-set static DNS that this app never changed.
    Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
      '-NoProfile -NonInteractive -Command "' +
        'Get-NetAdapter | Where-Object { $_.Name -like ''InputVPN*'' } | Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 4. Clean up any leftover scheduled tasks from old installs
    Exec(ExpandConstant('{sys}\schtasks.exe'), '/delete /f /tn "InputVPNSingBox"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{sys}\schtasks.exe'), '/delete /f /tn "InputVPNStop"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // 5. Optionally delete user data
    if Assigned(DeleteDataCheckbox) and DeleteDataCheckbox.Checked then
    begin
      AppDataPath := ExpandConstant('{userappdata}') + '\inputvpn';
      if DirExists(AppDataPath) then
        DelTree(AppDataPath, True, True, True);
    end;
  end;
end;