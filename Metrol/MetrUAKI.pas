unit MetrUAKI;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, UakiIntf, RootImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Menus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UakiUI, UakiUI.Ten, Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TFormUAKI = class(TCustomFontIForm, INotifyCanClose, INotifyBeforeRemove)
    Panel1: TPanel;
    btZero: TButton;
    Button1: TButton;
    edDvis: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edMag: TEdit;
    btUpdateMag: TButton;
    lblH: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure btZeroClick(Sender: TObject);
    procedure edDvisKeyPress(Sender: TObject; var Key: Char);
    procedure btUpdateMagClick(Sender: TObject);
  private
    FBinded: Boolean;
    FC_AxisUpdate: Integer;
    FuiA: TFrameUakiUI;
    FuiZ: TFrameUakiUI;
    FuiV: TFrameUakiUI;
    FuiT: TFrameUakiTEN;
    FC_PublishedChanged: string;
    FC_TenUpdate: Integer;
    function GetUaki: IUaki;
    procedure NetSetupClick(Sender: TObject);
    procedure SetC_AxisUpdate(const Value: Integer);
    procedure btGoClick(Sender: TObject);
    procedure NToleranceClick(Sender: TObject);
    procedure NSurrentSetClick(Sender: TObject);
    procedure HChekOnUpdate(Sender: TObject);
    procedure btReperClick(Sender: TObject);
    procedure InitFrame(var Frame: TFrameUakiUI; const Capt, Nm: string; Addr: Integer);
    procedure SetC_PublishedChanged(const Value: string);
    procedure NetSetupConnection(u: IUaki);
    procedure SetC_TenUpdate(const Value: Integer);
  protected
   const
    NICON = 273;
    function AdressUaki: Integer; virtual;
    function ConnectionType: Integer; virtual;
    procedure DoTenSupport; virtual;
    procedure CanClose(var CanClose: Boolean);
    procedure BeforeRemove();
    procedure InitializeNewForm; override;
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
  public
    destructor Destroy; override;

    [StaticAction('УАК-СИ-АЗВ-Т', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    property Uaki: IUaki read GetUaki;
    property C_AxisUpdate: Integer read FC_AxisUpdate write SetC_AxisUpdate;
    property C_TenUpdate: Integer read FC_TenUpdate write SetC_TenUpdate;
    property C_PublishedChanged: string read FC_PublishedChanged write SetC_PublishedChanged;
  end;

  TFormUAKI2 = class(TFormUAKI)
  protected
   const
    NICON = 274;
    function AdressUaki: Integer; override;
    function ConnectionType: Integer; override;
    procedure DoTenSupport; override;
  public
    [StaticAction('УАК-СИ Ноябрьск', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;
  TFormUAKICom = class(TFormUAKI)
  protected
   const
    NICON = 273;
    function AdressUaki: Integer; override;
    function ConnectionType: Integer; override;
    procedure DoTenSupport; override;
  public
    [StaticAction('УАК-СИ-АЗВ[com]', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;

  TFormUAKINet = class(TFormUAKI)
  protected
   const
    NICON = 272;
    function AdressUaki: Integer; override;
    function ConnectionType: Integer; override;
    procedure DoTenSupport; override;
  public
    [StaticAction('УАК-СИ-АЗВ[net]', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;


implementation

{$R *.dfm}

uses tools, MetrUAKI.ToleranceForm, MagniProTool, AutoMetr.Inclin.ChekH;

{ TFormUAKI }

function TFormUAKI.AdressUaki: Integer;
begin
  Result := ADR_UAKI;
end;

procedure TFormUAKI.BeforeRemove;
 var
  g: IGetDevice;
  de: IDeviceEnum;
  d: IDevice;
  a: TAddressArray;
  u: IUaki;
begin
  u := Uaki;
  (u as ICycle).Cycle := False;
  while (u as ICycle).Cycle do
   begin
    TThread.Yield;
//    TDebug.Log('%s', ['--------------------------NOP---------------------']);

//    Application.ProcessMessages;
   end;
//  if  Supports(GlobalCore, IDeviceEnum, de) then
//   begin
//    TBindHelper.RemoveExpressions(u.GetComponent);
//    de.Remove(u);
//   end;
end;

procedure TFormUAKI.btGoClick(Sender: TObject);
begin
  with TFrameUakiUI(TButton(Sender).Parent) do
  case Adr of
   ADR_AXIS_AZI: Uaki.Azi.GotoAngle(StrToFloat(edNeed.Text));
   ADR_AXIS_ZU: Uaki.Zen.GotoAngle(StrToFloat(edNeed.Text));
   ADR_AXIS_VIZ: Uaki.Viz.GotoAngle(StrToFloat(edNeed.Text));
  end;
end;

procedure TFormUAKI.btReperClick(Sender: TObject);
begin
  with TFrameUakiUI(TButton(Sender).Parent) do
  case Adr of
   ADR_AXIS_AZI: Uaki.Azi.FindMarker;
   ADR_AXIS_ZU: Uaki.Zen.FindMarker;
   ADR_AXIS_VIZ: Uaki.Viz.FindMarker;
  end;
end;

procedure TFormUAKI.btUpdateMagClick(Sender: TObject);
begin
  Uaki.MagnitAmp := StrToFloat(edMag.Text);
  Uaki.MagnitAmp := MagniProGetLastAmp;
  edMag.Text := FloatToStr(Uaki.MagnitAmp);
end;

procedure TFormUAKI.Button1Click(Sender: TObject);
begin
  Uaki.TermimateMoving;
end;

procedure TFormUAKI.CanClose(var CanClose: Boolean);
begin
  BeforeRemove;
end;

procedure TFormUAKI.btZeroClick(Sender: TObject);
// var
//  f: Boolean;
begin
  Uaki.Viz.ClearDeltaAngle;
  edDvis.Text := Uaki.Viz.DeltaAngle.ToString
//  f := (Uaki as ICycle).Cycle;
//  (Uaki as ICycle).Cycle := not f;
//  if f then  btCycl.Caption := 'Опрос-'
//  else  btCycl.Caption := 'Опрос+'
end;

class function TFormUAKI.ClassIcon: Integer;
begin
  Result := NICON;
end;

function TFormUAKI.ConnectionType: Integer;
begin
  Result := 4;
end;

destructor TFormUAKI.Destroy;
begin
  if Assigned(GChekH) then GChekH.UnBind(self);
  inherited;
end;

class procedure TFormUAKI.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUakiForm');
end;

procedure TFormUAKI.DoTenSupport;
begin
  FuiT := CreateUnLoad<TFrameUakiTEN>;
  FuiT.Name := 'FuiT';
  FuiT.Parent := Self;
  FuiT.FuncUaki := GetUaki;
  FuiT.Show;
end;

procedure TFormUAKI.edDvisKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #$D then
   begin
    Uaki.Viz.DeltaAngle := StrToFloat(edDvis.Text);
    Key := #0;
   end;
end;

procedure TFormUAKI.InitFrame(var Frame: TFrameUakiUI; const Capt, Nm: string; Addr: Integer);
begin
  if not Assigned(Frame) then
   begin
    Frame := CreateUnLoad<TFrameUakiUI>;
    Frame.Name := Nm;
    Frame.Parent := Self;
    Frame.Show;
   end;
  Frame.NTolerance.OnClick := NToleranceClick;
  Frame.NCurrentSet.OnClick := NSurrentSetClick;
  Frame.btGo.OnClick := btGoClick;
  Frame.lbReper.OnClick := btReperClick;
  Frame.lbName.Caption := Capt;
  Frame.Adr := addr;
  SetC_AxisUpdate(Addr)
end;

procedure TFormUAKI.InitializeNewForm;
begin
  inherited;
  AddToNCMenu('Установки соединения...', NetSetupClick);
end;

procedure TFormUAKI.Loaded;
 var
  e: TevTypes;
begin
  inherited Loaded;
  DoTenSupport;
//  btCycl.Caption := 'Опрос+';
  InitFrame(FuiV, 'Визир','FuiV', ADR_AXIS_VIZ);
  InitFrame(FuiZ, 'Зенит','FuiZ', ADR_AXIS_ZU);
  InitFrame(FuiA, 'Азимут','FuiA', ADR_AXIS_AZI);
  (Uaki as ICycle).Cycle := True;
  lblH.Font.Color := clRed;
  lblH.Font.Style := [fsBold];
  lblH.Caption := 'нет данных';

//  if not Assigned(GChekH) then GChekH := TChekH.Create;
  e.Update := HChekOnUpdate;
  GChekH.Bind(Self, e);
end;

procedure TFormUAKI.NetSetupClick(Sender: TObject);
begin
  NetSetupConnection(Uaki);
end;

procedure TFormUAKI.NetSetupConnection(u: IUaki);
 var
  c: IConnectIO;
  ge: IConnectIOEnum;
  gc: IGetConnectIO;
  d: IDialog;
begin
  if Assigned(u) and not Assigned(u.IConnect) then
   begin
    if Supports(GlobalCore, IConnectIOEnum, ge) and Supports(GlobalCore, IGetConnectIO, gc) then
     begin
       c := gc.ConnectIO(ConnectionType);
       if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(c);
       u.IConnect := c;
       ge.Add(c);
     end
   end
   else if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(u.IConnect);
end;

procedure TFormUAKI.NSurrentSetClick(Sender: TObject);
  procedure SetCurr(f: TFrameUakiUI; a: IAxis);
  begin
    a.CurrentAngle := StrToFloat(f.edNeed.Text);
    f.lbCurAng.Caption := f.edNeed.Text;
  end;
begin
  with TFrameUakiUI(TMenuItem(Sender).Owner) do
  case Adr of
   ADR_AXIS_AZI: SetCurr(FuiA, Uaki.Azi);
   ADR_AXIS_ZU:  SetCurr(FuiZ, Uaki.Zen);
   ADR_AXIS_VIZ: SetCurr(FuiV, Uaki.Viz);
  end;
end;

procedure TFormUAKI.NToleranceClick(Sender: TObject);
begin
  TDebug.Log(Sender.ClassName);
  with TFrameUakiUI(TMenuItem(Sender).Owner) do
  case Adr of
   ADR_AXIS_AZI: TFormUAKItolerance.Execute(Uaki.Azi);
   ADR_AXIS_ZU:  TFormUAKItolerance.Execute(Uaki.Zen);
   ADR_AXIS_VIZ: TFormUAKItolerance.Execute(Uaki.Viz);
  end;
end;

procedure TFormUAKI.SetC_AxisUpdate(const Value: Integer);
begin
  FC_AxisUpdate := Value;
  case FC_AxisUpdate of
   ADR_AXIS_AZI: FuiA.UpdateScreen(Uaki.Azi);
   ADR_AXIS_ZU: FuiZ.UpdateScreen(Uaki.Zen);
   ADR_AXIS_VIZ: FuiV.UpdateScreen(Uaki.Viz);
  end;
end;

procedure TFormUAKI.SetC_PublishedChanged(const Value: string);
begin
  FC_PublishedChanged := Value;
  if StrToFloat(FuiA.edNeed.Text) <> Uaki.Azi.NeedAngle.Angle then FuiA.edNeed.Text := Uaki.Azi.NeedAngle.ToString;
  if StrToFloat(FuiZ.edNeed.Text) <> Uaki.Zen.NeedAngle.Angle then FuiZ.edNeed.Text := Uaki.Zen.NeedAngle.ToString;
  if StrToFloat(FuiV.edNeed.Text) <> Uaki.Viz.NeedAngle.Angle then FuiV.edNeed.Text := Uaki.Viz.NeedAngle.ToString;
  edDvis.Text := Uaki.Viz.DeltaAngle.ToString;
end;

procedure TFormUAKI.SetC_TenUpdate(const Value: Integer);
begin
  FC_TenUpdate := Value;
  if Assigned(FuiT) then FuiT.UpdateScreen(Value, Uaki);
end;

function TFormUAKI.GetUaki: IUaki;
 var
  g: IGetDevice;
  de: IDeviceEnum;
  d: IDevice;
  a: TAddressArray;
begin
  Result := nil;
  try
  if Supports(GlobalCore, IGetDevice, g) and Supports(GlobalCore, IDeviceEnum, de) then
   begin
    for d in de.Enum() do if Supports(d, IUaki, Result) then Exit(d as IUaki);
    SetLength(a, 1);
    a[0] := AdressUaki;
    d := g.Device(a, 'UAKI', 'UAKI');
    de.Add(d);
    FBinded := False;
    Result := d as IUaki;
    NetSetupConnection(Result);
   end;
  finally
   if not FBinded then
    begin
     Bind('C_AxisUpdate', d, ['S_AxisUpdate']);
     Bind('C_TenUpdate', d, ['S_TenUpdate']);
     Bind('C_PublishedChanged', d, ['S_PublishedChanged']);
     FBinded := True;
    end;
  end;
end;

procedure TFormUAKI.HChekOnUpdate(Sender: TObject);
begin
  var h := TChekH(Sender);

  if h.WireReady then
   begin
    lblH.Font.Color := clWindowText;
    lblH.Font.Style := [];
    var x := h.CurrenData.X;
    var y := h.CurrenData.Y;
    var z := h.CurrenData.Z;
    if h.CurrenData.FlagError then
     begin
      lblH.Font.Color := clRed;
     end;
    lblH.Caption := Format('H: %f',[Sqrt(x*x+y*y+z*z)]);
   end
  else
    begin
     lblH.Font.Color := clRed;
     lblH.Font.Style := [fsBold];
     lblH.Caption := 'нет связи';
    end;
end;

{ TFormUAKI2 }

function TFormUAKI2.AdressUaki: Integer;
begin
  Result := ADR_UAKI2;
end;

function TFormUAKI2.ConnectionType: Integer;
begin
  Result := 1;
end;

class procedure TFormUAKI2.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUaki2Form');
end;

procedure TFormUAKI2.DoTenSupport;
begin
  Caption := 'УАК-СИ Ноябрьск'
end;

{ TFormUAKICom }

function TFormUAKICom.AdressUaki: Integer;
begin
  Result := ADR_UAKI_COM;
end;

function TFormUAKICom.ConnectionType: Integer;
begin
  Result := 1;
end;

class procedure TFormUAKICom.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUakiComForm');
end;

procedure TFormUAKICom.DoTenSupport;
begin
  Caption := 'УАК-СИ-АЗВ[com]'
end;

{ TFormUAKINet }

function TFormUAKINet.AdressUaki: Integer;
begin
  Result := ADR_UAKI_NET;
end;

function TFormUAKINet.ConnectionType: Integer;
begin
  Result := 4;
end;

class procedure TFormUAKINet.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUakiNetForm');
end;

procedure TFormUAKINet.DoTenSupport;
begin
  Caption := 'УАК-СИ-АЗВ[net]'
end;

initialization
  RegisterClass(TFormUAKI);
  TRegister.AddType<TFormUAKI, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormUAKI2);
  TRegister.AddType<TFormUAKI2, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormUAKINet);
  TRegister.AddType<TFormUAKINet, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormUAKICom);
  TRegister.AddType<TFormUAKICom, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormUAKI>;
  GContainer.RemoveModel<TFormUAKI2>;
  GContainer.RemoveModel<TFormUAKICom>;
  GContainer.RemoveModel<TFormUAKINet>;
end.
