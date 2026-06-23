unit FormDelay;

interface

uses  DeviceIntf, DockIForm, debug_except, ExtendIntf, RootImpl, PluginAPI, System.Variants, Container, RootIntf, System.TypInfo,
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Dialogs, JvComponentBase, JvInspector, JvExControls, RTTI;

type
  EFormDlyException = class(EBaseException);

  TFormDly = class(TDialogIForm, IDialog, IDialog<IDelayDevice>)
    Timer1: TTimer;
    btSetDelay: TButton;
    sb: TStatusBar;
    btSyncDelay: TButton;
    btClose: TButton;
    Insp: TJvInspector;
    InspectorBorlandPainter: TJvInspectorBorlandPainter;
    procedure Timer1Timer(Sender: TObject);
    procedure btSetDelayClick(Sender: TObject);
    procedure btSyncDelayClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
  private
    Item: IDelayDevice;
//    FDelayStatus: DelayStatus;
    FCanSyncDelay: Boolean;

    FIntervalWork: TTime;
    FIntervalOff: TTime;
    FTimeOff: TDateTime;
    FIntervalDelay: TTime;
    FTimeSetDelay: TDateTime;
    FIntervalOn: TTime;
    FTimeOn: TDateTime;
    function DateStartWork: TDateTime;
//    function DateEndWork: TDateTime;
    procedure OnSetDelay(Res: TSetDelayRes);
    procedure OnSyncDelay(Res: TSetDelayRes);
    procedure UpdateScreen;
    procedure UpdateControl(AEnable: Boolean);
    procedure SetIntervalDelay(const Value: string);
    procedure SetIntervalWork(const Value: string);
    procedure SetTimeOn(const Value: TDateTime);
    function GetIntervalDelay: string;
    function GetIntervalOff: string;
    function GetIntervalOn: string;
    function GetIntervalWork: string;
    function GetTimeOff: string;
    function GetTimeSetDelay: string;
  protected
    function GetInfo: PTypeInfo; override;
    procedure Execute(InputData: IDelayDevice);
  public
    [ShowProp('1 Интервал задержки')]                        property IntervalDelay  : string    read GetIntervalDelay write SetIntervalDelay;
    [ShowProp('2 Время включения прибора')]                  property TimeOn         : TDateTime read FTimeOn        write SetTimeOn;
    [ShowProp('3 Интервал работы (00:00:00-не установлен)')] property IntervalWork   : string    read GetIntervalWork  write SetIntervalWork;
    [ShowProp('4 Время постановки на задержку СП', True)]    property TimeSetDelay   : string    read GetTimeSetDelay;
    [ShowProp('5 Время выключения прибора', True)]           property TimeOff        : string    read GetTimeOff;
    [ShowProp('6 Осталось времени до включения СП', True)]   property IntervalOn     : string    read GetIntervalOn;
    [ShowProp('7 Осталось времени до выключения СП', True)]  property IntervalOff    : string    read GetIntervalOff;
  end;

implementation

{$R *.dfm}

uses tools;

{ TFormDly }


procedure TFormDly.SetIntervalDelay(const Value: string);
begin
  FIntervalDelay := MyStrToTime(Value);
end;

procedure TFormDly.SetIntervalWork(const Value: string);
begin
  FIntervalWork := MyStrToTime(Value);
end;

procedure TFormDly.SetTimeOn(const Value: TDateTime);
begin
  FTimeOn := Value;
end;

function TFormDly.GetIntervalDelay: string;
begin
  Result := MyTimeToStr(FIntervalDelay)
end;

function TFormDly.GetIntervalOff: string;
begin
  Result := MyTimeToStr(FIntervalOff)
end;

function TFormDly.GetIntervalOn: string;
begin
  Result := MyTimeToStr(FIntervalOn)
end;

function TFormDly.GetIntervalWork: string;
begin
  Result := MyTimeToStr(FIntervalWork)
end;

function TFormDly.GetTimeOff: string;
begin
  Result := DateTimeToStr(FTimeOff)
end;

function TFormDly.GetTimeSetDelay: string;
begin
  Result := DateTimeToStr(FTimeSetDelay)
end;

procedure TFormDly.UpdateControl(AEnable: Boolean);
begin
  NCanClose := AEnable;
  btClose.Enabled := AEnable;
  btSetDelay.Enabled := AEnable;
  btSyncDelay.Enabled := FCanSyncDelay and AEnable;
end;

procedure TFormDly.btCloseClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_SetDeviceDelay>;
end;

procedure TFormDly.btSetDelayClick(Sender: TObject);
begin
  if (DateStartWork - Now) > 0 then
  if MessageDlg('Прибор уже на задержке. Снова поставить прибор на задержку с потерей предыдущих данных о задержке?',
     mtWarning, [mbYes, mbNo, mbCancel], 0)<> mrYes then Exit;
  UpdateControl(False);
  sb.Panels[0].Text := 'Постановка на задержку...';
  (Item as IDelayDevice).SetDelay(FIntervalDelay, FIntervalWork, OnSetDelay);
end;
procedure TFormDly.btSyncDelayClick(Sender: TObject);
 var
  Tsyd: TTime;
begin
  UpdateControl(False);
  sb.Panels[0].Text := 'Постановка на задержку (Синхрониз.) ...';
  Tsyd := DateStartWork - Now;
  if Tsyd <= 0 then
   begin
    sb.Panels[0].Text := 'Постановка на задержку (Синхрониз.) НЕВОЗМОЖНА';
    UpdateControl(True);
   end
  else (Item as IDelayDevice).SetDelay(Tsyd, FIntervalWork, OnSyncDelay);
end;

procedure TFormDly.OnSetDelay(Res: TSetDelayRes);
// var
//  id: IDelayManager;
begin
  UpdateControl(True);
  if Res.Res then
   begin
//    FTimeSetDelay := Res.SetTime;
    FIntervalDelay := Res.Delay;
    FIntervalWork := Res.WorkTime;
    UpdateScreen;
    sb.Panels[0].Text := 'Прибор поставлен на задержку';
//    if Supports(GlobalCore, IDelayManager, id) then id.SetDelay(FTimeSetDelay, FIntervalDelay, FIntervalWork);
   end
   else sb.Panels[0].Text := 'Ошибка постановки прибора на задержку';
end;

procedure TFormDly.OnSyncDelay(Res: TSetDelayRes);
begin
  UpdateControl(True);
  if Res.Res then sb.Panels[0].Text := 'Прибор поставлен на задержку (Синхрониз.)'
  else sb.Panels[0].Text := 'Ошибка постановки (Синхрониз.) прибора на задержку';
end;

{function TFormDly.DateEndWork: TDateTime;
begin
  if FTimeSetDelay = 0 then Result := 0
  else if FIntervalWork = 0 then Result := FTimeSetDelay + FIntervalDelay + 100
  else Result := FTimeSetDelay + FIntervalDelay + FIntervalWork
end;}

function TFormDly.DateStartWork: TDateTime;
begin
  if FTimeSetDelay = 0 then Result := 0
  else Result := FTimeSetDelay + FIntervalDelay
end;

procedure TFormDly.Execute(InputData: IDelayDevice);
 var
//  id: IDelayManager;
  c : TRttiContext;
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  ii: TJvCustomInspectorItem;
//    VSetTime, VDelay, VWorkTime: Variant;
begin
  Item := InputData;
  Caption := '[' + (Item as ICaption).Text +'] Постановка на задержку, синхронизация задержки';
{  if Supports(GlobalCore, IDelayManager, id) then
   begin
    id.GetDelay(VSetTime, VDelay, VWorkTime, FDelayStatus);
    if not VarisNull(VWorkTime) then FIntervalWork := VWorkTime;
    if not VarisNull(VDelay) then FIntervalDelay := VDelay;
    if not VarisNull(VSetTime) then FTimeSetDelay := VSetTime;
   end;}
//  UpdateScreen;
  FCanSyncDelay := (Item as IDevice).GetAddrs[0] < 102;
  btSyncDelay.Enabled := FCanSyncDelay;
//  if FDelayStatus = dsEndDelay then
//   begin
//    btSyncDelay.Enabled := False;
//    btSetDelay.Enabled := False;
//   end;
  Insp.Clear;
  c := TRttiContext.Create;
  try
   t := c.GetType(TypeInfo(TFormDly));
   for p in t.getProperties do
    for a in p.GetAttributes do
     if a is ShowPropAttribute then
      begin
       ii := TJvInspectorPropData.New(Insp.Root, Self, TRttiInstanceProperty(p).PropInfo);
       ii.DisplayName := ShowPropAttribute(a).DisplayName;
       ii.ReadOnly := ShowPropAttribute(a).ReadOnly;
//       if ii is TJvInspectorBooleanItem then TJvInspectorBooleanItem(ii).ShowAsCheckbox := True;
      end;
  finally
   c.Free;
  end;
  IShow;
end;

function TFormDly.GetInfo: PTypeInfo;
begin
  Result :=TypeInfo(Dialog_SetDeviceDelay);
end;

procedure TFormDly.UpdateScreen;
begin
  Insp.Refresh;
{  if VarisNull(VSetTime) then lbStart.Caption := 'не поставлен'
  else lbStart.Caption := DateTimeToStr(TDateTime(VSetTime));
  if VarisNull(VDelay) then edDelay.Text := '00:00:00'
  else edDelay.Text := MyTimeToStr(TTime(VDelay));
  if VarisNull(VWorkTime) then edWork.Text := '00:00:00'
  else edWork.Text := MyTimeToStr(TTime(VWorkTime));
  if VarisNull(VSetTime) then
   begin
    lbStartDate.Caption := '--:--:--';
    lbStopDate.Caption := '--:--:--';
   end
  else
   begin
    lbStartDate.Caption := DateTimeToStr(DateStartWork);
    lbStopDate.Caption := DateTimeToStr(DateEndWork);
   end;             }
  Timer1Timer(Self);
end;

procedure TFormDly.Timer1Timer(Sender: TObject);
// var
//  tn: TTime;
begin
  Insp.Refresh;
{  if VarIsNull(VSetTime) then
   begin
    lbCurDelay.Caption := '--:--:--';
    Label3.Caption := 'прибор не поставлен на задержку';
    Exit;
   end;
  tn := Double(VDelay) - (Now - Double(VSetTime));
  if tn < 0 then
   begin
    Label3.Caption := 'время работы прибора';
    tn := -tn;
    if not VarisNull(VWorkTime) and (tn > VWorkTime) then Label3.Caption := 'время после окончания работы прибора';
   end
  else Label3.Caption := 'осталось времени до включения прибора';
  lbCurDelay.Caption := MyTimeToStr(tn);}
end;

initialization
//  RegisterDialog.Add<TFormDly, Dialog_SetDeviceDelay>;
finalization
//  RegisterDialog.Remove<TFormDly>;
end.
