unit FindDevices;

interface

{$INCLUDE global.inc}

uses  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, RootIntf, Container, Actns,
  tools, ConnectDeviceHelper,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  FrameFindDevs2, Vcl.Menus;

  {$IFDEF ENG_VERSION}
  const
   C_CaptDevFindForm ='Find Devices';
   C_Memu_Show='Show';
{$ELSE}
  const
   C_CaptDevFindForm ='Поиск приборов';
   C_Memu_Show='Показать';
{$ENDIF}

type
  TFormFindDev = class(TDockIForm, INotifyBeforeSave)
    Panel1: TPanel;
    Panel2: TPanel;
    btStart: TButton;
    btCansel: TButton;
    btExit: TButton;
    Memo: TMemo;
    Splitter1: TSplitter;
    btConnection: TButton;
    ppConnection: TPopupMenu;
    procedure btStartClick(Sender: TObject);
    procedure btCanselClick(Sender: TObject);
    procedure btConnectionClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
    FSelectIO: IConnectIO;
    FTmpDev: IDevice;
    frames: TArray<TFrameFindDev>;
    procedure UpdateControls(enable: Boolean);
    procedure ClearDevs();
  protected
   const
    NICON = 279;
   var
    class function ClassIcon: Integer; override;
    procedure BeforeSave();
  public
//Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction(C_CaptDevFindForm, C_Memu_Show, NICON, '0:'+C_Memu_Show+':1;1:')]
    class procedure DoCreateForm(Sender: IAction); override;
    { Public declarations }
  end;
  resourcestring
   RS_Terminate= '----Прервано---';
   RS_Connect='Подключить';
   RS_Begin='---начало работы ----';
   RS_BusyDevs='1. проверка занятых приборов';
   RS_FindCon='2. поиск соединений';
   RS_findMod='3. поиск модулей';
   RE_Err_DevRun1=' ERR:  Прибор [%s] в работе';
   RE_Err_DevRun2='Прибор [%s] в работе. Необходимо завершить операцию обмена данными';
   RS_No_Conn='ERR нет соединений(COM портов или Сеть)';

implementation

{$R *.dfm}

{ TFormFindDev }

procedure TFormFindDev.BeforeSave;
begin
  ClearDevs;
  Memo.Clear;
end;

procedure TFormFindDev.btCanselClick(Sender: TObject);
begin
  Memo.Lines.Add(RS_Terminate);
  for var f in frames do  f.Fterminate := True;
  UpdateControls(True);
end;

procedure TFormFindDev.btExitClick(Sender: TObject);
begin
  Close_ItemClick(Self);
end;

procedure TFormFindDev.btConnectionClick(Sender: TObject);
begin
  btConnection.Caption := RS_Connect;
  FSelectIO := nil;
  FTmpDev := nil;
  TMenuConnectIO.Apply(ppConnection.Items,
    procedure(c: IConnectIO)
    begin
      FselectIO := c;
      btConnection.Caption := c.ConnectInfo;
    end,
    procedure(c: IConnectIO)
    begin
      FselectIO := c;
      btConnection.Caption := c.ConnectInfo;
    end);
  ppConnection.Popup(btConnection.ClientOrigin.X, btConnection.ClientOrigin.Y+btConnection.Height)
end;

procedure TFormFindDev.btStartClick(Sender: TObject);
 var
  gc: IGetConnectIO;
  d: IDevice;
  de: IDeviceEnum;
  ports: TArray<string>;
begin
  ClearDevs;
  Memo.Lines.Clear;
  Memo.Lines.Add(RS_Begin);
  Memo.Lines.Add(RS_BusyDevs);
  if Supports(GlobalCore, IDeviceEnum, de) then
   for d in de do if Supports(d, IDataDevice) then
    if not (d.Status in [dsNoInit, dsPartReady, dsReady]) and not d.CanClose then
   begin
     Memo.Lines.Add(Format(RE_Err_DevRun1,[(d as ICaption).Text]));
    MessageDlg(Format(RE_Err_DevRun2, [(d as ICaption).Text]),
               mtWarning, [mbOk], 0);
    Exit();
   end;
  Memo.Lines.Add(RS_BusyDevs+' OK');

  Memo.Lines.Add(RS_FindCon);
  if FSelectIO <> nil then
   begin
    (GlobalCore as IconnectIOEnum).Add(FSelectIO);
    ports := [FSelectIO.ConnectInfo];
   end
   else if Supports(GlobalCore, IGetConnectIO, gc) then
   begin
     ports := gc.GetConnectInfo(1);
   end;


  if (Length(ports) = 0) then
   begin
    Memo.Lines.Add(RS_No_Conn);
    Exit;
   end;
  Memo.Lines.Add(RS_FindCon+' OK');

  Memo.Lines.Add(RS_findMod);
  UpdateControls(False);
  for var portName in ports do
   begin
    var f := TFrameFindDev.Create(self);
    f.Name := f.Name + Length(frames).ToString;
    f.Parent := Panel2;
    f.lbCon.Caption := portName;
    frames := frames +[f];
   end;
  for var f in frames do f.Execute(f.lbCon.Caption, Memo, procedure(e: TFrameFindDev)
    begin
     for var ff in frames do if not ff.FExecuted then exit;
     UpdateControls(True);
   end);
   FTmpDev := nil;
end;

class function TFormFindDev.ClassIcon: Integer;
begin
  Result := NICON;
end;

procedure TFormFindDev.ClearDevs;
begin
  for var f in frames do f.Free;
  SetLength(frames, 0);
end;

class procedure TFormFindDev.DoCreateForm(Sender: IAction);
begin
  var f := GetUniqueForm('GlobalFormFindDev');
//  (GContainer as ITabFormProvider).Tab(f);
//  (GContainer as ITabFormProvider).SetActiveTab(f);
end;

procedure TFormFindDev.UpdateControls(enable: Boolean);
begin
  btStart.Enabled := enable;
  btExit.Enabled := enable;
  btCansel.Enabled := not enable;
end;

initialization
  RegisterClass(TFormFindDev);
  RegisterClass(TFrameFindDev);
  TRegister.AddType<TFormFindDev, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormFindDev>;
end.
