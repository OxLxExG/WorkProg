unit IOForm;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, RootIntf, Container, Actns,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Rtti,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, PluginAPI, DeviceIntf, Vcl.StdCtrls, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnPopup, Vcl.ActnList, Vcl.StdActns, System.Actions;

type
  TFormIO = class(TDockIForm)
    Memo1: TMemo;
  private
    NConnections: TMenuItem;
    FLBeforeRemove: string;
    FConnectIO: string;
    FLConnectInfo: string;
    FProject: string;
    FMaxLenHex: Integer;
    procedure NSaveAsClick(Sender: TObject);
    procedure NMaxLenHexClick(Sender: TObject);
    procedure NClearClick(Sender: TObject);
    procedure OnIOEvent(IOStatus: EnumIOStatus; Data: PByteArray; DataSize: Integer);
    procedure OnIOEventString(IOStatus: EnumIOStatus; const Data: string);
    procedure SetConnectIO(const Value: string);
    procedure SetLBeforeRemove(const Value: string);
    procedure ConnectionClick(Sender: TObject);
    procedure SetLConnectInfo(const Value: string);
    procedure SetProjectChange(const Value: string);
  protected
    procedure NCPopup(Sender: TObject); override;
    procedure InitializeNewForm; override;
    class function ClassIcon: Integer; override;
  public
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction('Новый монитор ввода-вывода', 'Отладочные', 266, '0:Показать.Отладочные:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    destructor Destroy; override;
    property C_BeforeRemove: string read FLBeforeRemove write SetLBeforeRemove;
    property C_ConnectInfo: string read FLConnectInfo write SetLConnectInfo;
  published
    property C_Project: string read FProject write SetProjectChange;
    property ConnectIO: string read FConnectIO write SetConnectIO;
    property MaxLenHex: Integer read FMaxLenHex write FMaxLenHex default 16;
  end;

implementation

{$R *.dfm}

{ TFormIO }

class function TFormIO.ClassIcon: Integer;
begin
  Result := 266;
end;

procedure TFormIO.ConnectionClick(Sender: TObject);
begin
  ConnectIO := TMenuItem(Sender).Name;
end;

destructor TFormIO.Destroy;
 var
  c: IConnectIO;
  ce: IConnectIOEnum;
begin
  if (FConnectIO <> '') and Supports(GlobalCore, IConnectIOEnum, ce) then
   begin
    c := ce.Get(FConnectIO);
    if Assigned(c) then
     begin
      (c as IDebugIO).IOEvent := nil;
      (c as IDebugIO).IOEventString := nil;
     end;
   end;
  TDebug.Log('    TFormIO.Destroy ' + Caption);
  inherited;
end;

class procedure TFormIO.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormIO.InitializeNewForm;
 var
  ce: IConnectIOEnum;
  m: IManager;
begin
  inherited;
  FMaxLenHex := 16;
  AddToNCMenu('-');
  AddToNCMenu('Очистить', NClearClick);
  AddToNCMenu('Сохранить в файл...', NSaveAsClick);
  AddToNCMenu('Длинна выводимых данных...', NMaxLenHexClick);
  //Item.Action := FileSaveAs;
  NConnections := AddToNCMenu('Подключить к устойству ввода-вывода');
  if Supports(GlobalCore, IConnectIOEnum, ce) then Bind('C_BeforeRemove', ce, ['S_BeforeRemove']); //(ce as IBind).CreateManagedBinding(Self, 'LBeforeRemove', ['S_BeforeRemove']);
  if Supports(GlobalCore, IManager, m) then Bind('C_Project', m, ['S_ProjectChange']); //  (m as IBind).CreateManagedBinding(Self, 'Project', ['LProject']);
end;


procedure TFormIO.NClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TFormIO.NCPopup(Sender: TObject);
 var
  c: IConnectIO;
  Item: TMenuItem;
  ce: IConnectIOEnum;
begin
  inherited;
  NConnections.Clear;
  if Supports(GlobalCore, IConnectIOEnum, ce) then for c in ce do
   begin
    Item := TMenuItem.Create(NConnections);
    Item.Caption := c.ConnectInfo;
    Item.Name := (c as ImanagItem).IName;
    Item.OnClick := ConnectionClick;
    if Assigned((c as IDebugIO).IOEvent) or Assigned((c as IDebugIO).IOEventString) then
     if not SameText((c as ImanagItem).IName, ConnectIO) then
      begin
       Item.Enabled := False;
       Item.Checked := True;
      end
     else Item.Checked := True;
    NConnections.Add(Item);
   end;
end;

procedure TFormIO.NMaxLenHexClick(Sender: TObject);
begin
  FMaxLenHex := InputBox('Длинна данных', 'Длинна данных', FMaxLenHex.ToString()).ToInteger;
end;

procedure TFormIO.NSaveAsClick(Sender: TObject);
begin
  with TSaveDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   DefaultExt := 'txt';
   Options := Options + [ofOverwritePrompt, ofPathMustExist];
   Filter := 'Файл (*.txt)|*.txt';
   if Execute(Handle) then Memo1.Lines.SaveToFile(FileName);
  finally
   Free;
  end;
end;

procedure TFormIO.OnIOEvent(IOStatus: EnumIOStatus; Data: PByteArray; DataSize: Integer);
 function ToHex: string;
  var
   i,n: Integer;
 begin
   Result := '';
   if DataSize > MaxLenHex then n := MaxLenHex
   else n := DataSize;
   for i := 0 to n-1 do Result := Result + ' ' + IntToHex(Data^[i],2);
   if DataSize > 16 then Result := Result +'...';
 end;
  function DataAsStr: string;
  begin
   if not  Assigned(Data) then Result := ''
   else Result := string(Pchar(Data));
  end;
  var
  s: string;
begin
  Memo1.Lines.BeginUpdate;
  try
    DateTimeToString(s, 'hh:nn:ss:zzz', Now);
    case IOStatus of
     iosRx: Memo1.Lines.Insert(0, Format('%s  READ %5d: %s',[s, DataSize, ToHex()]));
     iosTx: Memo1.Lines.Insert(0, Format('%s WRITE %5d: %s',[s, DataSize, ToHex()]));
     iosTimeOut: Memo1.Lines.Insert(0,Format('%s TIME OUT %d %s',[s, DataSize, DataAsStr]));
     iosDebug: Memo1.Lines.Insert(0, Format('%s -- %5d: %s',[s, DataSize, ToHex()]));
    end;
    while Memo1.Lines.Count > 100 do Memo1.Lines.Delete(Memo1.Lines.Count-1);
   finally
    Memo1.Lines.EndUpdate;
   end;
end;

procedure TFormIO.OnIOEventString(IOStatus: EnumIOStatus; const Data: string);
  var
  s: string;
begin
  Memo1.Lines.BeginUpdate;
  try
    DateTimeToString(s, 'hh:nn:ss:zzz', Now);
    case IOStatus of
     iosRx: Memo1.Lines.Insert(0, Format('%s  READ : %s',[s, Data]));
     iosTx: Memo1.Lines.Insert(0, Format('%s WRITE : %s',[s, Data]));
     iosTimeOut: Memo1.Lines[0] := Memo1.Lines[0] + Format('-- %s TIME OUT %s',[s, Data]);
     iosDebug: Memo1.Lines.Insert(0, Format('%s -- %s',[s, Data]));
    end;
    while Memo1.Lines.Count > 100 do Memo1.Lines.Delete(Memo1.Lines.Count-1);
   finally
    Memo1.Lines.EndUpdate;
   end;
end;

procedure TFormIO.SetConnectIO(const Value: string);
 var
  c: IConnectIO;
  ce: IConnectIOEnum;
  m: IManager;
begin
  if FConnectIO = Value then Exit;
  TBindHelper.RemoveControlExpressions(Self, ['C_ConnectInfo']);// Bind.RemoveManagedBinding('LConnectInfo');
  GlobalCore.QueryInterface(IConnectIOEnum, ce);
  if FConnectIO <> '' then
   begin
    c := nil;
    if Assigned(ce) then c := ce.Get(FConnectIO);
    if Assigned(c) then
     begin
      (c as IDebugIO).IOEvent := nil;
      (c as IDebugIO).IOEventString := nil;
     end;
   end;
  FConnectIO := Value;
  if FConnectIO <> '' then
   begin
    c := nil;
    if Assigned(ce) then c := ce.Get(FConnectIO);
    if Assigned(c) then
     begin
      (c as IDebugIO).IOEvent := OnIOEvent;
      (c as IDebugIO).IOEventString := OnIOEventString;
      Caption := c.ConnectInfo;
      Bind('C_ConnectInfo', c, ['S_ConnectInfo']);//  (c as IBind).CreateManagedBinding(Self, 'LConnectInfo', ['LConnectInfo']);
      if Supports(GlobalCore, IManager, m) then FProject := m.ProjectName;
      Exit;
     end
    else FConnectIO := '';
   end;
  Caption := 'Монитор';
end;

procedure TFormIO.SetLBeforeRemove(const Value: string);
begin
  FLBeforeRemove := Value;
  if ConnectIO = '' then Exit;
  if SameText(FLBeforeRemove, ConnectIO) then ConnectIO := '';
end;

procedure TFormIO.SetLConnectInfo(const Value: string);
begin
  FLConnectInfo := Value;
  Caption := FLConnectInfo;
end;

procedure TFormIO.SetProjectChange(const Value: string);
begin
  if (csLoading in ComponentState) then FProject := Value
  else if (Value <> '') and (FProject <> Value) then
   begin
    FProject := Value;
    ConnectIO := '';
   end;
end;

initialization
  RegisterClass(TFormIO);
  TRegister.AddType<TFormIO, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormIO>;
end.





