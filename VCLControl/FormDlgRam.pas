unit FormDlgRam;

interface

uses  DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, debug_except, Data.DB, System.TypInfo, Vcl.Menus,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Container,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Bindings.Helper, Vcl.ExtCtrls, Vcl.Mask, JvExMask, JvToolEdit;

type
  EFrmDlgRam = class(EBaseException);
  TFrmDlgRam = class(TDialogIForm, IDialog, IDialog<Integer>)
    btStart: TButton;
    btExit: TButton;
    cbToFF: TCheckBox;
    Progress: TProgressBar;
    btTerminate: TButton;
    sb: TStatusBar;
    rg: TRadioGroup;
    Label1: TLabel;
    od: TJvFilenameEdit;
    edLen: TEdit;
    Label2: TLabel;
    procedure btExitClick(Sender: TObject);
    procedure btTerminateClick(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
  private
    FModul: string;
    FModulID: Integer;
    FDev: IDevice;
    FS_TableModulUpdate: string;
    procedure inerExecute(IsImport: boolean);
    procedure NImportClick(Sender: TObject);
    procedure NExportClick(Sender: TObject);
    function GetDevice: IDevice;
    procedure UpdateControls(FlagEna: Boolean);
    procedure ReadRamEvent(EnumRR: EnumReadRam; DevAdr: Integer; ProcToEnd: Double);
  protected
    procedure Loaded; override;
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: Integer): Boolean;
  public
    property S_TableModulUpdate: string read FS_TableModulUpdate write FS_TableModulUpdate;
  end;

implementation

{$R *.dfm}

uses AbstractPlugin, tools, DBImpl;

function TFrmDlgRam.Execute(InputData: Integer): Boolean;
begin
  Result := True;
  TBindHelper.RemoveExpressions(Self);
  FModulID := InputData;
  FS_TableModulUpdate := 'Ram';
  ConnectionsPool.Query.Acquire;
  try
   FModul := ConnectionsPool.Query.Connection.ExecSQLScalar('SELECT Модуль FROM Modul WHERE id = '+ FModulID.ToString);
   Caption := '[' + FModul +'] Чтение памяти';
  finally
   ConnectionsPool.Query.Release;
  end;
  Bind(GlobalCore as IManager, 'C_TableUpdate', ['S_TableModulUpdate']);
  IShow;
end;

function TFrmDlgRam.GetDevice: IDevice;
 const
  SEL = 'SELECT Device.IName FROM Device,Modul WHERE Modul.id = %d AND Modul.fk = Device.id';
begin
  if Assigned(FDev) then Exit(FDev);
  ConnectionsPool.Query.Acquire;
  try
   Result := (GlobalCore as IDeviceEnum).Get(ConnectionsPool.Query.Connection.ExecSQLScalar(Format(SEL, [FModulID])))
  finally
   ConnectionsPool.Query.Release;
  end;
end;

function TFrmDlgRam.GetInfo: PTypeInfo;
begin
  Result :=TypeInfo(Dialog_RamRead);
end;

procedure TFrmDlgRam.Loaded;
// var
//  n: TMenuItem;
begin
  inherited;
  AddToNCMenu('-');
  AddToNCMenu('Импортировать...', NImportClick);
  AddToNCMenu('Экспортировать...', NExportClick);
end;

procedure TFrmDlgRam.NExportClick(Sender: TObject);
 var
  d: IDevice;
//  e: IExport;
begin
  d := GetDevice;
{  if Supports(d, IExport, e) then
  with TOpenDialog.Create(nil) do
   try
    InitialDir := ExtractFilePath(ParamStr(0));
    Options := Options + [ofOverwritePrompt, ofPathMustExist];
    Filter := e.Filters;
    if Execute(Handle) then e.Execute(FileName, FilterIndex, procedure (ProcToEnd: Double)
    begin
      sb.Panels[0].Text := Format('Экспорт сталось %1.3f',[ProcToEnd]);
    end);
   finally
    Free;
   end;}
end;

procedure TFrmDlgRam.NImportClick(Sender: TObject);
begin
  inerExecute(True);
end;

procedure TFrmDlgRam.ReadRamEvent(EnumRR: EnumReadRam; DevAdr: Integer; ProcToEnd: Double);
  procedure Stop(const reason: string);
  begin
    sb.Panels[0].Text := reason;
    UpdateControls(True);
  end;
begin
  Progress.Position := 100 - Round(ProcToEnd);
  case EnumRR of
   eirReadOk:        sb.Panels[0].Text := Format('Чтение памяти Адрес: %d осталось %1.3f',[DevAdr, ProcToEnd]);
   eirReadErrSector: sb.Panels[0].Text := Format('Ошибка чтения памяти Адрес: %d осталось %1.3f', [DevAdr, ProcToEnd]);
   eirCantRead:  Stop(Format('Невозможно считать память Адрес: %d', [DevAdr]));
   eirEnd:       Stop('чтение памяти ОКОНЧЕНО');
   eirTerminate: Stop('чтение памяти прервано');
  end;
end;

procedure TFrmDlgRam.UpdateControls(FlagEna: Boolean);
begin
  btStart.Enabled := FlagEna;
  btExit.Enabled := FlagEna;
  NCanClose := FlagEna;
end;

procedure TFrmDlgRam.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_RamRead>;
end;

procedure TFrmDlgRam.inerExecute(IsImport: boolean);
 const
      GET_ALL_DATA = 'SELECT Device.IName, Device.id,'+
                     ' Modul.Адрес, Modul.ToAdr'+
                     ' FROM Device, Modul'+
                     ' WHERE Modul.id = %d AND Modul.fk = Device.id';
     CLR_DATA = 'UPDATE Modul SET'+
                    ' FromAdr = NULL,'+
                    ' ToAdr = NULL,'+
                    ' FromKadr = NULL,'+
                    ' ToKadr = NULL,'+
                    ' FromTime = NULL,'+
                    ' ToTime = NULL'+
                    ' WHERE id = %d';

 var
  de: IDeviceEnum;
  ds: TAsyncADQuery;
  ri: IRamImport;
  flName: string;
  flIndex: Integer;
begin
  if not Supports(GlobalCore, IDeviceEnum, de) then Exit;
  ds := ConnectionsPool.Query;
  ds.Acquire;
  ds.Open(Format(GET_ALL_DATA,[FModulID]));
  try
   FDev := de.Get(ds['IName']);
   if not Assigned(FDev) then raise EFrmDlgRam.CreateFmt('Устройство %s не найдено', [ds['IName']]);
   if not Supports(FDev, IReadRamDevice) then raise EFrmDlgRam.CreateFmt('Устройство %s без памяти', [FModul]);
   if IsImport then
    begin
     if not Supports(FDev as IReadRamDevice, IRamImport, ri) then raise EFrmDlgRam.CreateFmt('Устройство %s неподдерживает импорт из файла', [FModul]);
     with TOpenDialog.Create(nil) do
      try
       InitialDir := ExtractFilePath(ParamStr(0));
       Options := Options + [ofPathMustExist, ofFileMustExist];
       Filter := ri.Filters;
       if not Execute(Handle) then Exit
       else
        begin
         flName := FileName;
         flIndex := FilterIndex;
        end;
      finally
       Free;
      end;
    end;
   if not ds.FieldByName('ToAdr').IsNull then
    if (MessageDlg('Память уже считана предыдущие данные будут удалены!!!', mtWarning, [mbYes, mbCancel], 0) = mrCancel) then Exit
    else
     begin
      ds.Connection.ExecSQL(Format('DELETE FROM Ram_%s_%s', [ds['Адрес'], ds['id']]));
      ds.Connection.ExecSQL(Format(CLR_DATA, [FModulID]));
      TBindings.Notify(Self, 'S_TableModulUpdate');
     end;
   UpdateControls(False);
   try
    if not IsImport then
     (FDev as IReadRamDevice).Execute(od.FileName, 0, 0, cbToFF.Checked, rg.ItemIndex, ds['Адрес'], ReadRamEvent, FModulID, StrToInt('$'+edLen.Text))
    else ri.Import(flName, flIndex,0,0, cbToFF.Checked, ds['Адрес'], ReadRamEvent, FModulID);
   except
    UpdateControls(True);
    raise;
   end;
  finally
    ds.Release;
  end;
end;

procedure TFrmDlgRam.odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
  od.FileName := '';
end;

procedure TFrmDlgRam.btStartClick(Sender: TObject);
begin
  inerExecute(False);
end;

procedure TFrmDlgRam.btTerminateClick(Sender: TObject);
begin
  if not Assigned(FDev) then Exit;
  try
   (FDev as IReadRamDevice).Terminate();
  except
   UpdateControls(True);
  end;
end;

initialization
  RegisterDialog.Add<TFrmDlgRam, Dialog_RamRead>;
finalization
  RegisterDialog.Remove<TFrmDlgRam>;
end.
