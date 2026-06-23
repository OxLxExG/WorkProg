unit ActionsDev;

interface

uses AbstractDev, ExtendIntf, RootImpl, DeviceIntf, debug_except, PluginAPI, RootIntf, Container,
     System.SysUtils, Menus, Classes, ActnList, System.TypInfo, RTTI, Vcl.Dialogs, Vcl.Controls;

type
  EActionsDevException = class(EBaseException);

  TActionRec = record
    Act: IAction;
    CaptionFormat: string;
    PathFormat: string;
    ShowInTool: Boolean;
    constructor Create( AAct: IAction; const CaptFmt, PathFmt: string; InTool: Boolean);
  end;

  TActionsDev = class(TAbstractActionsDev)
  private
    FActions: Tarray<TActionRec>;
    FDName: string;
    FStatus: TDeviceStatus;
    procedure SetDName(const Value: string);
    procedure SetLStatus(const Value: TDeviceStatus);
  protected
    function GetActById(Id: integer): IAction;
    procedure AddMenus(Root: TMenuItem); override;
    function Init(const PathFormat, CaptionFormat, Hint: string; ev: TIActionEvent; ImagIndex: Integer = -1;
                  ShowInTool: Boolean = False;
                  AutoCheck: Boolean = False;
                  Enabled: Boolean = True;
                  Checked: Boolean = False;
                  GroupIndex: Integer = 0): TActionRec;
  public
   // должны быть public т.к. имя ищется в RTTI
    procedure DoDelay(Sender: IAction);
    procedure DoRam(Sender: IAction);
    procedure DoData(Sender: IAction);virtual;

    procedure CreateAddManager(); override;
    procedure ShowInMenu(); override;
    procedure NotifyRemove(); override;

    property DName: string read FDName write SetDName;
    property LStatus: TDeviceStatus read FStatus write SetLStatus;
  end;

  TActionsDevBur = class(TActionsDev)
  private
   procedure InfoEvent(Res: TInfoEventRes); safecall;
   procedure InfoEvent2(Res: TInfoEventRes); safecall;
  public
    procedure CreateAddManager(); override;
   // должны быть public т.к. имя ищется в RTTI
    procedure DoData(Sender: IAction); override;
    procedure DoInfo(Sender: IAction);
    procedure DoStd(Sender: IAction);
    procedure DoIdle(Sender: IAction);
  end;

implementation

uses tools;

const
 PATH_STD = 'Управление.%s';
 PATH_EXX = 'Управление.%s.Дополнительно';
 ID_DATA = 206;

{ TActionRec }

constructor TActionRec.Create(AAct: IAction; const CaptFmt, PathFmt: string; InTool: Boolean);
begin
  Act:= AAct;
  CaptionFormat := CaptFmt;
  PathFormat := PathFmt;
  ShowInTool := InTool;
end;

{ TActionsDev }

function TActionsDev.Init(const PathFormat, CaptionFormat, Hint: string; ev: TIActionEvent; ImagIndex: Integer = -1;
                  ShowInTool: Boolean = False;
                  AutoCheck: Boolean = False;
                  Enabled: Boolean = True;
                  Checked: Boolean = False;
                  GroupIndex: Integer = 0): TActionRec;
 var
  ap: IActionProvider;
  a: IAction;
begin
  if not Supports(GlobalCore, IActionProvider, ap) then Exit;
  FDName := (Controller as IDevice).Name;
  a := ap.Create(FDName, Format(CaptionFormat, [FDName]), GetIActionName(Controller, ev), ev, ImagIndex, GroupIndex);
  a.Hint := Hint;
  a.AutoCheck := AutoCheck;
  a.Checked := Checked;
  a.Enabled := Enabled;
  Result := TActionRec.Create(a, CaptionFormat, PathFormat, ShowInTool);
end;

procedure TActionsDev.NotifyRemove;
 var
  ap: IActionProvider;
  a: TActionRec;
begin
  if not Supports(GlobalCore, IActionProvider,ap) then Exit;
  for a in FActions do with a do
   begin
    ap.HideInBar(0, Act);
    if ShowInTool then ap.HideInBar(2, Act);
   end;
end;

procedure TActionsDev.SetDName(const Value: string);
 var
  ap: IActionProvider;
  a: TActionRec;
begin
  if FDName <> Value then
   begin
    if Supports(GlobalCore, IActionProvider,ap) then for a in FActions do with a do
     begin
      Act.Category := Value;
      Act.Caption := Format(CaptionFormat, [Act.Category]);
      ap.HideInBar(0, Act);
      ap.ShowInBar(0, Format(PathFormat, [Act.Category]), act);
      if ShowInTool then
       begin
        ap.HideInBar(2, Act);
        ap.ShowInBar(2, '', act);
       end;
     end;
    FDName := Value;
   end;
end;

procedure TActionsDev.SetLStatus(const Value: TDeviceStatus);
 var
  a: IAction;
begin
  FStatus := Value;
  a := GetActById(ID_DATA);
  if Assigned(a) then a.Checked := FStatus = dsData;
end;

procedure TActionsDev.ShowInMenu;
 var
  ap: IActionProvider;
  a: TActionRec;
begin
  if not Supports(GlobalCore, IActionProvider,ap) then Exit;
  for a in FActions do with a do
   begin
    ap.ShowInBar(0, Format(PathFormat, [Act.Category]), Act);
    if ShowInTool then ap.ShowInBar(2, '', Act);
   end;
end;

procedure TActionsDev.CreateAddManager;
 var
  b: IBind;
begin
  if Supports(Controller, IBind, b) then
   begin
    b.CreateManagedBinding(Self, 'LStatus', ['LStatus']);
    b.CreateManagedBinding(Self, 'DName', ['DName']);
   end;
  if Supports(Controller, IDelayDevice) then
     CArray.Add<TActionRec>(FActions, Init(PATH_STD, '%s Задержка...', 'Окно постановки на задержку', DoDelay, 204));
  if Supports(Controller, IReadRamDevice)   then
     CArray.Add<TActionRec>(FActions, Init(PATH_STD, '%s Чтение памяти...', 'Окно создания нового чтения памяти', DoRam, 205));
  if Supports(Controller, IDataDevice)  then
     CArray.Add<TActionRec>(FActions, Init(PATH_STD, '%s Информация', 'Выход/Вход в режим чтения информации', DoData, ID_DATA, True));
end;

procedure TActionsDev.AddMenus(Root: TMenuItem);
 var
  a: TActionRec;
  Item: TMenuItem;
begin
  Root.Clear;
  for a in FActions do
   begin
    Item := TMenuItem.Create(Root);
    Item.Action := TCustomAction((a.Act as IInterfaceComponentReference).GetComponent);
    Root.Add(Item);
   end;
end;

procedure TActionsDev.DoData(Sender: IAction);
 var
  cy: ICycle;
begin
  if Supports(Controller, ICycle, cy) then cy.Cycle := not Sender.Checked;
end;

procedure TActionsDev.DoDelay(Sender: IAction);
 var
  d: Idialogs;
begin
  if Supports(GlobalCore, Idialogs, d) then  d.Execute(DIALOG_SetDeviceDelay, Controller);
end;

procedure TActionsDev.DoRam(Sender: IAction);
 var
  d: Idialogs;
begin
  if Supports(GlobalCore, Idialogs, d) then  d.Execute(DIALOG_CREATE_RamRead, Controller);
end;

function TActionsDev.GetActById(Id: integer): IAction;
 var
  a: TActionRec;
begin
  Result := nil;
  for a in FActions do if a.Act.ImageIndex = id then Exit(a.Act);
end;

{ TActionsDevBur }

const
  AN_Std = '(только время)';
  AN_Std_h = 'Пониженное энергопотребление прибора режимне информации, получение только времени и состояния прибора';
  AN_Idle = 'Выключить прибор';
  AN_Idle_h = 'Перевести приборы в спящий режим';
//  AN_Meta = 'Инициализировать';
//  AN_Meta_h = 'Чтение информации о данных';

procedure TActionsDevBur.CreateAddManager;
begin
  inherited;
  CArray.Add<TActionRec>(FActions, Init(PATH_EXX, AN_Std,  AN_Std_h,  DoStd,  207, False, True));
  CArray.Add<TActionRec>(FActions, Init(PATH_EXX, AN_Idle, AN_Idle_h, DoIdle, 208));
//  CArray.Add<TActionRec>(FActions, Init(PATH_EXX, AN_Meta, AN_Meta_h, DoInfo, 209));
end;

procedure TActionsDevBur.DoData(Sender: IAction);
begin
  if (Controller as IDataDevice).Status in [dsNoInit, dsPartReady] then (Controller as IDataDevice).InitMetaData(InfoEvent)
  else inherited;
end;

procedure TActionsDevBur.InfoEvent(Res: TInfoEventRes);
begin
  try
   if Length(Res.ErrAdr) > 0 then raise EActionsDevException.CreateFmt('Метаданные устройств (%s) не считаны', [TAddressRec(Res.ErrAdr).ToNames]);
  finally
   inherited DoData(GetActById(ID_DATA))
  end;
end;


procedure TActionsDevBur.InfoEvent2(Res: TInfoEventRes);
begin
  if Length(Res.ErrAdr) > 0 then raise EActionsDevException.CreateFmt('Метаданные устройств (%s) не считаны', [TAddressRec(Res.ErrAdr).ToNames]);
end;

procedure TActionsDevBur.DoIdle(Sender: IAction);
 var
  ir: IRegistry;
  ts: TDateTime;
  td: TTime;
begin
  if Supports(GlobalCore, IRegistry, ir) then
   begin
    ts := StrToDateTime(ir.LoadString('FormDelay\TimeSetDelay', DateTimeToStr(Now)));
    td := MyStrToTime(ir.LoadString('FormDelay\TimeDelay', MyTimeToStr(1/24)));
    if (ts + td - Now) > 0 then
    if MessageDlg('Приборы на задержке. Перевести приборы в спящий режим?', mtWarning, [mbYes, mbNo, mbCancel], 0) <> mrYes then Exit;
   end;
  (Controller as IDelayDevice).SetDelay(0, 0, nil);
end;

procedure TActionsDevBur.DoInfo(Sender: IAction);
begin
  (Controller as IDataDevice).InitMetaData(InfoEvent2);
end;

procedure TActionsDevBur.DoStd(Sender: IAction);
begin
  (Controller as ICycleEx).StdOnly := Sender.Checked;
end;

end.
