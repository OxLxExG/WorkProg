unit MetrBK;

interface

 {$M+}

uses
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, debug_except, DockIForm, MetrForm, Container, Actns, ExcelImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.ActiveX,
  Vcl.Menus,  RootImpl, StolBKIntf,  System.UITypes,  JDtools, VerySimple.Lua.Lib,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, JvExControls, JvInspector;

type
  TBKAuto = class(TAutomatMetrology)
  private
    FHideTerminateError: Boolean;
    FNeedSendStop: Boolean;
    FDevBK: IPultBK;
    function GetDevBK: IPultBK;
    procedure NetSetupConnection(u: Idevice);
  protected
    procedure StartStep(Step: IXMLNode); override;
    procedure Stop(); override;
    procedure DoEndMetrology(); override;
  public
    property DevBK: IPultBK read GetDevBK;
  end;

  TFormBK = class(TFormMetrolog, IAutomatMetrology)
    PanelM: TPanel;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    Splitter: TSplitter;
    lbAlpha: TLabel;
    Inspector: TJvInspector;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FAutomatMetrology: TBKAuto;
    FkGZ2: string;
    FkGZ3: string;
    FkGZ1: string;
    FkGZ6: string;
    FkGZ4: string;
    FkGZ5: string;
    FkI: string;
    FkPS2: string;
    FkPS3: string;
    FkPS1: string;
    FkI22: string;
    FkI11: string;
    FU0: string;
    procedure NParamClick(Sender: TObject);
    class constructor Create;
    class destructor Destroy;
//    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
    class procedure Exec_EL1(v,t: IXMLNode); overload; static;
    class procedure Setup_EL1(v: IXMLNode); overload; static;
    class procedure ExportToMbk(const TrrFile: string; NewTrr: IXMLNode); overload; static;
  protected
    procedure Loaded; override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
   const
    PATH_BK_B = 'БК.B.I%d.%s';
    PATH_BK_H = 'БК.H.I%d.%s';
    PATH_BK_U = 'БК.U0.%s';
    PATH_BK_I = 'БК.IT.%s';
    PATH_KS = 'КС.точно.Z%d.%s';
    PATH_KS_I = 'КС.I.%s';
    PATH_PS = 'ПС.Z%d.%s';
    PATH_DPS = 'ПС.DPS.%s';
    MAX_ALG = 11;
    INFO: array [1..MAX_ALG] of string = ('ks1','ks2','ks3','ks4','ks5','ks6','ps1','ps2','dps','I1','I2');
    PULT_CMD: array [1..MAX_ALG] of word = ($FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF);
    NICON = 194;
    class function ClassIcon: Integer; override;
    procedure DoUpdateTrr();
    property AutomatMetrology: TBKAuto read FAutomatMetrology implements IAutomatMetrology;
  public
    destructor Destroy; override;
    [StaticAction('Новая калибровка ВК', 'Метрология', NICON, '0:Метрология.ВК')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    [ShowProp('kGZ1', true)] property kGZ1: string read FkGZ1;
    [ShowProp('kGZ2', true)] property kGZ2: string read FkGZ2;
    [ShowProp('kGZ3', true)] property kGZ3: string read FkGZ3;
    [ShowProp('kGZ4', true)] property kGZ4: string read FkGZ4;
    [ShowProp('kGZ5', true)] property kGZ5: string read FkGZ5;
    [ShowProp('kGZ6', true)] property kGZ6: string read FkGZ6;
    [ShowProp('kI', true)] property kI: string read FkI;
    [ShowProp('kPS1', true)] property kPS1: string read FkPS1;
    [ShowProp('kPS2', true)] property kPS2: string read FkPS2;
    [ShowProp('kPS3', true)] property kPS3: string read FkPS3;
    [ShowProp('kI11', true)] property kI11: string read FkI11;
    [ShowProp('kI22', true)] property kI22: string read FkI22;
    [ShowProp('kU0', true)] property kU0: string read FU0;
  published
    class function Exec_EL1(L: lua_State): Integer; overload; cdecl; static;
    class function Setup_EL1(L: lua_State): Integer; overload; cdecl; static;
    class function ExportToMbk(L: lua_State): Integer; overload; cdecl; static;
  end;

implementation

{$R *.dfm}

uses  tools, XMLLua, XMLLua.Math;

{ TBKAuto }

procedure TBKAuto.DoEndMetrology;
begin
  inherited;
end;

function TBKAuto.GetDevBK: IPultBK;
 var
  de: IDeviceEnum;
  d: IDevice;
  gd: IGetDevice;
begin
  if Assigned(FDevBK) then Exit(FDevBK);
  if Supports(GlobalCore, IDeviceEnum, de) then
   begin
     for d in de.Enum() do if d.Addrs[0] = 2415 then
      begin
       FDevBK := d as IPultBK;
       Exit(FDevBK);
      end;
     if Supports(GlobalCore, IGetDevice, gd) then
      begin
       FDevBK := gd.Device([2415], 'PULT_BK', 'PULT_BK') as IPultBK;
       de.Add(FDevBK);
       NetSetupConnection(FDevBK);
      end;
   end;
  Result := nil;
  raise EFormMetrolog.Create('Устройство поверки BК отсутствует');
end;

procedure TBKAuto.NetSetupConnection(u: Idevice);
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
       c := gc.ConnectIO(1);
       if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(c);
       u.IConnect := c;
       ge.Add(c);
     end
   end
   else if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(u.IConnect);
end;

procedure TBKAuto.StartStep(Step: IXMLNode);
 var
  saveExec: Boolean;
begin
  saveExec := Boolean(step.Attributes['EXECUTED']);
  inherited;
  Report(samUserStop, 'Отправка команды пульту метрологии ВК');
  try
    DevBK.Command(FStep.Attributes['PULT_CMD'], procedure (Res: Boolean)
    begin
      if Res then
       begin
        if Integer(FStep.Attributes['STEP']) in [7..11] then FStep.Attributes['INP_U'] := InputBox('Измерение напряжения', 'U0', '450');
        DoStop;
       end
      else
       begin
        Report(samError, 'Ошибка ответа пульта метрологии ВК');
        Error('Ошибка ответа пульта метрологии ВК');
       end;
    end);
  except
   on E: Exception do
    begin
     Report(samError, 'Ошибка пульта метрологии ВК: '+ E.Message);
     if Boolean(step.Attributes['EXECUTED']) <> saveExec then
      begin
       step.Attributes['EXECUTED'] := saveExec;
       Owner.ReCalc();
      end;
     raise;
    end;
  end;
end;

procedure TBKAuto.Stop;
begin
  Report(samUserStop, 'Прервано пользователем');
  DevBK.Command($FFFF, procedure (Res: Boolean)
  begin
    if not Res then Report(samError, 'Прервано пользователем. Ошибка ответа пульта метрологии ВК');
  end);
  inherited;
end;


{$REGION 'TFormБK'}
class constructor TFormBK.Create;
begin
  TXMLLua.RegisterLuaMethods(TFormBK);
//  TXmlScriptInner.RegisterMethods([
//  'procedure ExportToMbk(const TrrFile: string; NewTrr: Variant)',
//  'procedure Exec_EL1(v, t: variant)',
//  'procedure Setup_EL1(v: variant)'
//  ], CallMeth);
end;

class destructor TFormBK.Destroy;
begin
//  TXmlScriptInner.UnRegisterMethods(CallMeth);
end;

class function TFormBK.MetrolMame: string;
begin
  Result := 'electro';
end;

class function TFormBK.MetrolType: string;
begin
  Result := 'TBK'
end;

procedure TFormBK.NParamClick(Sender: TObject);
begin
  with FAutomatMetrology do
  if Assigned(FDevBK) then NetSetupConnection(FDevBK)
  else DevBK;
end;

class function TFormBK.Setup_EL1(L: lua_State): Integer;
begin
  Setup_EL1(TXMLLua.XNode(L, 1));
  Result := 0;
end;

//class function TFormBK.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//begin
//  if MethodName = 'EXEC_EL1' then  Exec_EL1(Params[0], Params[1])
//  else if MethodName = 'SETUP_EL1' then  Setup_EL1(Params[0])
//  else if MethodName = 'EXPORTTOMBK' then  ExportToMbk(Params[0], Params[1])
//end;

class function TFormBK.ClassIcon: Integer;
begin
  Result := NICON
end;

class procedure TFormBK.Setup_EL1(v: IXMLNode);
 var
  l, p, f, m: IXMLNode;
  i, j: Integer;
 const
  CLL: array[0..6] of TAlphaColor = ($FF240000,$FF480000,$FF6C0000,$FF900000,$FFB40000,$FFD80000,$FFFF0000);
  CLF: array[1..4] of TAlphaColor = ($FF004000,$FF008000,$FF00C000,$FF0000FF);
begin
  for i := 1 to 6 do
   begin
    f := TXMLScriptMath.AddXmlPath(v, Format(PATH_BK_B, [i, T_CLC]));
    m := TXMLScriptMath.AddMetrology(f, 'I1'+i.ToString, 'мА');
    TXMLScriptMath.AddMetrologyFM(m, 6, 1);
    TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
    f := TXMLScriptMath.AddXmlPath(v, Format(PATH_BK_H, [i, T_CLC]));
    m := TXMLScriptMath.AddMetrology(f, 'I2'+i.ToString, 'мА');
    TXMLScriptMath.AddMetrologyFM(m, 6, 1);
    TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
    f := TXMLScriptMath.AddXmlPath(v, Format(PATH_KS, [i, T_CLC]));
    m := TXMLScriptMath.AddMetrology(f, 'KS'+i.ToString, 'мB');
    TXMLScriptMath.AddMetrologyFM(m, 6, 1);
    TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
   end;
  for i := 1 to 2 do
   begin
    f := TXMLScriptMath.AddXmlPath(v, Format(PATH_PS, [i, T_CLC]));
    m := TXMLScriptMath.AddMetrology(f, 'PS'+i.ToString, 'мB');
    TXMLScriptMath.AddMetrologyFM(m, 6, 1);
    TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
   end;
   f := TXMLScriptMath.AddXmlPath(v, Format(PATH_DPS, [T_CLC]));
   m := TXMLScriptMath.AddMetrology(f, 'DPS', 'мB');
   TXMLScriptMath.AddMetrologyFM(m, 6, 1);
   TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
   f := TXMLScriptMath.AddXmlPath(v, Format(PATH_DPS, [T_CLC]));
   m := TXMLScriptMath.AddMetrology(f, 'DPS', 'мB');
   TXMLScriptMath.AddMetrologyFM(m, 6, 1);
   TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
   f := TXMLScriptMath.AddXmlPath(v, Format(PATH_KS_I, [T_CLC]));
   m := TXMLScriptMath.AddMetrology(f, 'I', 'мA');
   TXMLScriptMath.AddMetrologyFM(m, 6, 1);
   TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
   f := TXMLScriptMath.AddXmlPath(v, Format(PATH_BK_U, [T_CLC]));
   m := TXMLScriptMath.AddMetrology(f, 'U0', 'мB');
   TXMLScriptMath.AddMetrologyFM(m, 6, 1);
   TXMLScriptMath.AddMetrologyRG(m, 0, 1000);
end;

class procedure TFormBK.Exec_EL1(v, t: IXMLNode);
 var
  root, trr: IXMLNode;
  i: Integer;
  procedure setclc(k: Double; const path: string; index: Integer =-1);
   var
    d, c: IXMLNode; 
  begin
    if index < 0 then  d := GetXNode(root, Format(path, [T_DEV])) else d := GetXNode(root, Format(path, [index, T_DEV])); 
    if index < 0 then  c := GetXNode(root, Format(path, [T_CLC])) else c := GetXNode(root, Format(path, [index, T_CLC])); 
    if not VarIsNull(d.Attributes[AT_VALUE]) then c.Attributes[AT_VALUE] := k * Double(d.Attributes[AT_VALUE]);
  end;
begin
  root := v;
  trr := t;
  for i := 1 to 6 do
   begin
    setclc(trr.Attributes['kGZ'+i.ToString], PATH_KS, i);  
    setclc(trr.Attributes['kI11_16'], PATH_BK_B, i);
    setclc(trr.Attributes['kI21_26'], PATH_BK_H, i);  
   end;
  setclc(trr.Attributes['kI'], PATH_KS_I);
  setclc(trr.Attributes['kU0'], PATH_BK_U); 
  for i := 1 to 2 do setclc(trr.Attributes['kPS'+i.ToString], PATH_PS, i);  
  setclc(trr.Attributes['kPS3'], PATH_DPS); 
end;

class procedure TFormBK.ExportToMbk(const TrrFile: string; NewTrr: IXMLNode);
 var
  ser, dat: string;
begin
   ser := NewTrr.ParentNode.ParentNode.Attributes[AT_SERIAL];
   dat := NewTrr.ChildNodes.FindNode(MetrolType).Attributes[AT_TIMEATT];
   with TStringList.Create do
    try
     Add(Format('%13.10f    {GZ1/мВ.ед.} {МБК-%s Дата метрологии %s}',[Double(NewTrr.Attributes['kGZ1']), ser, dat]));
     Add(Format('%13.10f    {GZ2/мВ.ед.}',[Double(NewTrr.Attributes['kGZ2'])]));
     Add(Format('%13.10f    {GZ3/мВ.ед.}',[Double(NewTrr.Attributes['kGZ3'])]));
     Add(Format('%13.10f    {GZ4/мВ.ед.}',[Double(NewTrr.Attributes['kGZ4'])]));
     Add(Format('%13.10f    {GZ5/мВ.ед.}',[Double(NewTrr.Attributes['kGZ5'])]));
     Add(Format('%13.10f    {GZ6/мВ.ед.}',[Double(NewTrr.Attributes['kGZ6'])]));
     Add(Format('%13.10f    {gz1/мВ.ед.}',[Double(NewTrr.Attributes['kGZ1'])]));
     Add(Format('%13.10f    {gz2/мВ.ед.}',[Double(NewTrr.Attributes['kGZ2'])]));
     Add(Format('%13.10f    {gz3/мВ.ед.}',[Double(NewTrr.Attributes['kGZ3'])]));
     Add(Format('%13.10f    {gz4/мВ.ед.}',[Double(NewTrr.Attributes['kGZ4'])]));
     Add(Format('%13.10f    {gz5/мВ.ед.}',[Double(NewTrr.Attributes['kGZ5'])]));
     Add(Format('%13.10f    {gz6/мВ.ед.}',[Double(NewTrr.Attributes['kGZ6'])]));
     Add(Format('%13.10f    {I/мА.ед.}',[Double(NewTrr.Attributes['kI'])]));
     Add(Format('%13.10f    {PS1/мВ.ед.}',[Double(NewTrr.Attributes['kPS1'])]));
     Add(Format('%13.10f    {PS2/мВ.ед.}',[Double(NewTrr.Attributes['kPS2'])]));
     Add(Format('%13.10f    {PS3/мВ.ед.}',[Double(NewTrr.Attributes['kPS3'])]));
     Add(Format('%13.10f    {gradPS/мВ.ед.}',[Double(NewTrr.Attributes['kPS3'])]));
     Add(Format('%13.10f    {U0/мВ.ед.}',[Double(NewTrr.Attributes['kU0'])]));
     Add(Format('%13.10f    {I11/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I13/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I13/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I14/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I15/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I16/мА.ед.}',[Double(NewTrr.Attributes['kI11_16'])]));
     Add(Format('%13.10f    {I21/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     Add(Format('%13.10f    {I22/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     Add(Format('%13.10f    {I23/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     Add(Format('%13.10f    {I24/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     Add(Format('%13.10f    {I25/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     Add(Format('%13.10f    {I26/мА.ед.}',[Double(NewTrr.Attributes['kI21_26'])]));
     SaveToFile(TrrFile);
   finally
    Free;
   end;
end;

function TFormBK.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 var
  KR1, ki, KR2, tok: Double;
  tok_sum: integer;
  stp: IXMLNode;
  procedure find(const res: string; k: Double; root:IXMLNode; const dv: string);
   var
    v: Variant;
  begin
    if TryValX(root, dv + '.VALUE', v) and (Abs(Double(V)) > 0) then trr.Attributes[res] := k/Double(V)/2;
  end;
begin
  Result := True;
  KR1 := Option['KR1'];
  KR2 := Option['KR2'];
  KI := Option['KI'];
  stp := alg.ChildNodes.FindNode('STEP'+Step.ToString);
  tok := 0;
  case step of
   1..5: find('kGZ'+ step.ToString, KR1, stp, Format(PATH_KS, [Step, T_DEV]));
   6: 
    begin 
     find('kGZ'+ step.ToString, KR1, stp, Format(PATH_KS, [Step, T_DEV]));
     find('kI', KI, stp, Format(PATH_KS_I, [T_DEV])); 
    end;
   7..8: find('kPS'+ (step-6).ToString, stp.Attributes['INP_U'], stp, Format(PATH_PS, [Step-6, T_DEV]));
   9: find('kPS3', stp.Attributes['INP_U'], stp, Format(PATH_DPS, [T_DEV]));
   10:
    begin
     find('kI11_16', stp.Attributes['INP_U'], stp, Format(PATH_BK_B, [1, T_DEV]));
     find('kU0', stp.Attributes['INP_U'], stp, Format(PATH_BK_U, [T_DEV]));
    end;
   11: find('kI21_26', stp.Attributes['INP_U'], stp, Format(PATH_BK_H, [1, T_DEV]));
  end;
end;

function TFormBK.UserSetupAlg(alg: IXMLNode): Boolean;
  procedure AddData(root: IXMLNode; const DEV: string);
   var
    i: Integer;
  begin
    for i := 1 to 6 do
     begin
      GetXNode(root, Format(PATH_BK_B, [i, DEV]), True).Attributes[AT_VALUE] := 0;
      GetXNode(root, Format(PATH_BK_H, [i, DEV]), True).Attributes[AT_VALUE] := 0;
      GetXNode(root, Format(PATH_KS, [i, DEV]), True).Attributes[AT_VALUE] := 0;
     end;
    for i := 1 to 2 do GetXNode(root, Format(PATH_PS, [i, DEV]), True).Attributes[AT_VALUE] := 0;
    GetXNode(root, Format(PATH_BK_U, [DEV]), True).Attributes[AT_VALUE] := 0;
    GetXNode(root, Format(PATH_KS_I, [DEV]), True).Attributes[AT_VALUE] := 0;
    GetXNode(root, Format(PATH_DPS, [DEV]), True).Attributes[AT_VALUE] := 0;
  end;
  var
   s, t: IXMLNode;
   i: Integer;
begin
  Result := True;
  for i := 1 to MAX_ALG do
   begin
    s := GetXNode(alg, 'STEP'+ i.ToString, True);
    t := GetXNode(s, 'TASK', True);
    AddData(s, 'DEV');
    AddData(s, 'CLC');
    GetXNode(s, Format(PATH_BK_B,[0, 'DEV']), True).Attributes[AT_VALUE] := 0;
    GetXNode(s, Format(PATH_BK_H,[0, 'DEV']), True).Attributes[AT_VALUE] := 0;
    GetXNode(s, Format(PATH_BK_I,['DEV']), True).Attributes[AT_VALUE] := 0;
    s.Attributes['EXECUTED'] := False;
    s.Attributes['STEP'] := i;
    s.Attributes['INP_U'] := 450;
    s.Attributes['INFO'] := Format('%d) %s',[i, INFO[i]]);
    t.Attributes['PULT_CMD'] := PULT_CMD[i];
   end;
end;

procedure TFormBK.DoUpdateTrr;
 var
  r: Variant;
  n: IXMLNode;
begin
  n := GetMetr([], GetFileOrDevData);
  if not (Assigned(n) and n.HasAttribute('kGZ1')) then Exit;
  r := XToVar(n);
  FkGZ1 := r.kGZ1;
  FkGZ2 := r.kGZ2;
  FkGZ3 := r.kGZ3;
  FkGZ4 := r.kGZ4;
  FkGZ5 := r.kGZ5;
  FkGZ6 := r.kGZ6;
  FkI  :=  r.kI;
  FkPS2:=  r.kPS2;
  FkPS3:=  r.kPS3;
  FkPS1:=  r.kPS1;
  FkI11:=  r.kI11_16;
  FkI22:=  r.kI21_26;
  FU0  :=  r.kU0;
  Inspector.Repaint;
end;

destructor TFormBK.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormBK.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormBK.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  DoUpdateTrr;
end;

procedure TFormBK.DoUpdateData(NewFileData: Boolean = False);
begin
  inherited;
  DoUpdateTrr;
end;

procedure TFormBK.Loaded;
begin
  ShowPropAttribute.Apply(Self, Inspector);
  SetupStepTree(Tree);
  SetupEditor(procedure (XMNode: IXMLNode; Column: Integer; var allow: Boolean)
  begin
    allow := Column = 1;
  end,
  function (XMNode: IXMLNode; Column: Integer): string
  begin
    Result := XMNode.Attributes['INP_U']
  end,
  procedure (XMNode: IXMLNode; Column: Integer; const text: string)
  begin
    XMNode.Attributes['INP_U'] := Text.ToInteger;
  end);
  inherited;
  AttestatPanel.Align := alBottom;
  AddToNCMenu('-');
  AddToNCMenu('Параметры связи с пультом метрологии БК...', NParamClick);
  FAutomatMetrology := TBKAuto.Create(Self);
  FAutomatMetrology.Report := AutoReport;
end;

procedure TFormBK.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormBK.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
  procedure SetData(const path, atr: string; const fmt: string = '');
   var
    V: Variant;
    r: IXMLNode;
  begin
    if path = '' then r := p.XMNode
    else r := GetXNode(p.XMNode, Path);
    if not Assigned(r) then Exit;
    if r.HasAttribute(atr) then V := r.Attributes[atr];
    if not VarIsNull(V) then
     if (fmt <> '') then CellText := Format(fmt,[Double(V)])
     else CellText := V;
  end;
begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
   case Column of
    0: SetData('', 'STEP');
    1: SetData('', 'INP_U');
    2..7: SetData(Format(PATH_KS, [Column-1, T_DEV]), AT_VALUE);
    8..13: SetData(Format(PATH_KS, [Column-7, T_CLC]), AT_VALUE);
    14: SetData(Format(PATH_KS_I, [T_DEV]), AT_VALUE);
    15: SetData(Format(PATH_KS_I, [T_CLC]), AT_VALUE);
    16..17: SetData(Format(PATH_PS, [Column-15, T_DEV]), AT_VALUE);
    18: SetData(Format(PATH_DPS, [T_DEV]), AT_VALUE);
    19..20: SetData(Format(PATH_PS, [Column-18, T_CLC]), AT_VALUE);
    21: SetData(Format(PATH_DPS, [T_CLC]), AT_VALUE);
    22..28: SetData(Format(PATH_BK_B, [Column-22, T_DEV]), AT_VALUE);
    29..35: SetData(Format(PATH_BK_H, [Column-29, T_DEV]), AT_VALUE);
    36..41: SetData(Format(PATH_BK_B, [Column-35, T_CLC]), AT_VALUE);
    42..47: SetData(Format(PATH_BK_H, [Column-41, T_CLC]), AT_VALUE);
    48: SetData(Format(PATH_BK_U, [T_DEV]), AT_VALUE);
    49: SetData(Format(PATH_BK_U, [T_CLC]), AT_VALUE);
    50: SetData(Format(PATH_BK_I, [T_DEV]), AT_VALUE);
   end;
end;
{$ENDREGION}

class function TFormBK.Exec_EL1(L: lua_State): Integer;
begin
  Exec_EL1(TXMLLua.XNode(L, 1), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class function TFormBK.ExportToMbk(L: lua_State): Integer;
begin
  ExportToMbk(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

initialization
  RegisterClass(TFormBK);
  TRegister.AddType<TFormBK, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormBK>;
end.
