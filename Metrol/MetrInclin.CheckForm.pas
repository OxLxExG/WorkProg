unit MetrInclin.CheckForm;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, AutoMetr.Inclin, RootImpl,
     LuaInclin.Math, XMLLua.Math, UakiIntf,
     VirtualTrees, Xml.XMLIntf, Vcl.Menus, JvInspector,
     Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
     Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormInclinCheck = class(TFormMetrolog, IAutomatMetrology)
    PanelM: TPanel;
    lbInfo: TLabel;
    pc: TCPageControl;
    Tree: TVirtualStringTree;
    PanelP: TPanel;
    Splitter2: TSplitter;
    TreeA: TVirtualStringTree;
    TreeH: TVirtualStringTree;
    Splitter: TSplitter;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FAutomatMetrology: TinclAuto;
    FStolVizir: Double;
    FStolAzimut: Double;
    FStolZenit: Double;
//    procedure NParamClick(Sender: TObject);
    procedure NShowTrrClick(Sender: TObject);
    procedure NAziCorrClick(Sender: TObject);
    procedure NZenCorrClick(Sender: TObject);
    procedure NNewAlgClick(Sender: TObject);
    procedure NOldAlgClick(Sender: TObject);
  protected
    FStep: record
            stp: Integer;
            root: IXMLNode;
           end;
    FCurAzim, FCurViz, FCurZu: Double;
    FExtendMenus: TMenuItem;
    FNewAlg: Boolean;
    FAziCorr: Double;
    FZenCorr: Double;
    procedure DoStandartSetup(Item: TJvCustomInspectorItem; Option: IXMLNode; var Data: IXMLNode); override;
    function NAziCorrCaption: string;
    function NZenCorrCaption: string;
    function FindMaxErr(alg: IXMLNode; from, too: Integer; const attr: string): Double;
    procedure RefindAzi(from, too: Integer; alg, trr: IXMLNode);
    procedure RefindZen(from, too: Integer; alg, trr: IXMLNode);
    function AddStep(const Info: string; a, z, o: Double): Variant;
    procedure Loaded; override;
    procedure DoSetFont(const AFont: TFont); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
//    procedure UserExecStepUpdateStolAngle(Step: Integer; alg, trr: IXMLNode);
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
    class function ClassIcon: Integer; override;
  public
   const
    NICON = 86;
    destructor Destroy; override;
    property StolVizir: Double read FStolVizir;
    property StolZenit: Double read FStolZenit;
    property StolAzimut: Double read FStolAzimut;

    [StaticAction('Новая поверка 104', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    property AutomatMetrology: TinclAuto read FAutomatMetrology implements IAutomatMetrology;
  end;

  TFormInclinCheckPoly = class(TFormInclinCheck)
  protected
   function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
  public
   const
    NICON = 86;
    [StaticAction('Новая поверка 104 POLY', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolAttrName: string; override;
  end;
implementation

{$R *.dfm}

uses tools, {MetrInclin.CheckFormSetup,} MetrInclin,


TrrInclin.Temp.PolyModel,
MetrInclin.Temp.Stat,
LuaInclin.Temp.Poly,
MetrInclin.Temp.MathPoly;

{$REGION 'Std'}

{ TFormInclinCheck }

procedure TFormInclinCheck.NNewAlgClick(Sender: TObject);
begin
  FNewAlg := True;
  ReCalc();
  DoUpdateData();
end;

procedure TFormInclinCheck.NOldAlgClick(Sender: TObject);
begin
  FNewAlg := False;
  HasXTree(GetMetr([], DevData), GetMetr([], FileData), procedure(devroot, dev, failRoot, fail: IXMLNode)
  begin
    fail.NodeValue := dev.NodeValue;
  end);
  ReCalc();
  DoUpdateData();
end;


function TFormInclinCheck.NAziCorrCaption: string;
begin
  Result := Format('Поправка азимута стола [%g]...', [FAziCorr])
end;



procedure TFormInclinCheck.NAziCorrClick(Sender: TObject);
begin
  FAziCorr := InputBox('Поправка азимута стола', 'Новое значение', FAziCorr.ToString()).ToDouble;
  TMenuItem(Sender).Caption := NAziCorrCaption;
  ReCalc();
end;

class function TFormInclinCheck.ClassIcon: Integer;
begin
  Result := NICON;
end;

destructor TFormInclinCheck.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormInclinCheck.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormInclinCheck.DoSetFont(const AFont: TFont);
begin
  inherited;
  TreeSetFont(TreeH);
  TreeSetFont(TreeA);
end;

procedure TFormInclinCheck.DoStandartSetup(Item: TJvCustomInspectorItem; Option: IXMLNode; var Data: IXMLNode);
begin
  inherited;
  if (Option.NodeName = 'ErrZU') or (Option.NodeName = 'ErrAZ') or (Option.NodeName = 'ErrAZ5') then TJvInspectorFloatItem(Item).Format := '0.00';
end;

procedure TFormInclinCheck.DoStopAtt(AttNode: IXMLNode);
 var
  v: Variant;
  n: IXMLNode;
  crZenit: Double;
begin
  if TryGetX(AttNode, 'TASK', n) then
   begin
    if n.HasAttribute('Vizir_Stol') then FStolVizir := Double(n.Attributes['Vizir_Stol']);
    if n.HasAttribute('Azimut_Stol') then FStolAzimut := Double(n.Attributes['Azimut_Stol']);
    if n.HasAttribute('Zenit_Stol') then FStolZenit := Double(n.Attributes['Zenit_Stol']);
   end;
  v := XToVar(AttNode);
  if FAutomatMetrology.UakiExists then
   begin
    v.СТОЛ.азимут := Double(FAutomatMetrology.uaki.Azi.CurrentAngle);
    v.СТОЛ.зенит := Double(FAutomatMetrology.uaki.Zen.CurrentAngle);
    v.СТОЛ.амплит_magnit := FAutomatMetrology.uaki.MagnitAmp;
   end
  else
   begin
    v.СТОЛ.азимут := StolAzimut;
    v.СТОЛ.зенит := StolZenit;
//    v.СТОЛ.амплит_magnit := 1000;
   end;
  v.СТОЛ.err_азимут := TMetrInclinMath.DeltaAngle(v.азимут.CLC.VALUE - (v.СТОЛ.азимут + FAziCorr));
  crZenit := (v.СТОЛ.зенит + FZenCorr);
  if crZenit > 180 then v.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(v.зенит.CLC.VALUE -(360 - crZenit))
  else v.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(v.зенит.CLC.VALUE - crZenit);
  inherited;
  TFormInclin.UpdateAH(TreeA, GetMetr(['accel','m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
  TFormInclin.UpdateAH(TreeH, GetMetr(['magnit','m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
end;

procedure TFormInclinCheck.DoUpdateData(NewFileData: Boolean);
begin
  inherited DoUpdateData(NewFileData);
  TFormInclin.UpdateAH(TreeA, GetMetr(['accel','m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
  TFormInclin.UpdateAH(TreeH, GetMetr(['magnit','m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
end;

procedure TFormInclinCheck.Loaded;
// var
//  n: TMenuItem;
begin
  FlagNoUpdateFromEtalon := True;
  SetupStepTree(Tree);
  TFormInclin.InitT(TreeA);
  TFormInclin.InitT(TreeH);
  inherited;
//  NIsMedian.Visible := True;
  AddToNCMenu('-', nil, 10);
  FExtendMenus := AddToNCMenu('Дополнительно', nil, 11, -1);
  AddToNCMenu('-', nil, 12);

  AddToNCMenu('Пересчитать поверку с поправками устройства', NOldAlgClick, -1, -1, FExtendMenus);
  AddToNCMenu('-', nil, -1, -1, FExtendMenus);
  AddToNCMenu(NAziCorrCaption, NAziCorrClick, -1, -1, FExtendMenus);
  AddToNCMenu(NZenCorrCaption, NZenCorrClick, -1, -1, FExtendMenus);
  AddToNCMenu('Рассчет новых поправок', NNewAlgClick, 14);
  AddToNCMenu('Показывать поправки', NShowTrrClick, 15, AUTO_CHECK[PanelP.Visible]);

  //n.Checked := PanelP.Visible;
//  AddToNCMenu('Параметры поверки...', NParamClick);
  FAutomatMetrology := TinclAuto.Create(Self, AutoReport);
  AttestatPanel.Align := alBottom;
end;

class function TFormInclinCheck.MetrolMame: string;
begin
  Result := 'Inclin'
end;

class function TFormInclinCheck.MetrolType: string;
begin
  Result := 'P_1'
end;

//procedure TFormInclinCheck.NParamClick(Sender: TObject);
//begin
//  if TFormInclinCheckSetup.Execute(GetMetr([MetrolType], FileData)) then
//     if TrrFile <> '' then FileData.OwnerDocument.SaveToFile(TrrFile)
//end;

procedure TFormInclinCheck.NShowTrrClick(Sender: TObject);
begin
  PanelP.Visible := TMenuItem(Sender).Checked;
  Splitter.Top := PanelM.Height;
end;

function TFormInclinCheck.NZenCorrCaption: string;
begin
  Result := Format('Поправка зенита стола [%g]...', [FZenCorr])
end;

procedure TFormInclinCheck.NZenCorrClick(Sender: TObject);
begin
  FZenCorr := InputBox('Поправка зенита стола', 'Новое значение', FZenCorr.ToString()).ToDouble;
  TMenuItem(Sender).Caption := NZenCorrCaption;
  ReCalc();
end;

procedure TFormInclinCheck.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
end;


procedure TFormInclinCheck.TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeTData;
begin
  p := Sender.GetNodeData(Node);
  case Column of
   0: CellText := p.Item;
   1: CellText := p.x;
   2: CellText := p.y;
   3: CellText := p.z;
   4: CellText := p.d4;
  end;
end;


procedure TFormInclinCheck.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
  r: IXMLNode;
  procedure SetData(const path, attr, fmt: string; Correction: Double = 0);
   var
    V: IXMLNode;
  begin
    if TryGetX(p.XMNode, path, V, attr) then CellText := Format(fmt,[Double(V.NodeValue) + Correction])
    else CellText := ''
  end;
begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
   case Column of
    0: begin
        r := p.XMNode;
        if r.HasAttribute('STEP') then CellText := r.Attributes['STEP']
        else CellText := 'STEP';
       end;
    1: SetData('СТОЛ',             'азимут',     '%7.2f', FaziCorr);
    2: SetData('азимут.CLC',       AT_VALUE,     '%6.1f');
    3: SetData('СТОЛ',             'err_азимут', '%6.2f');
    4: SetData('СТОЛ',             'зенит',      '%7.2f', FZenCorr);
    5: SetData('зенит.CLC',        AT_VALUE,     '%7.2f');
    6: SetData('СТОЛ',             'err_зенит',  '%6.2f');
    7: SetData('отклонитель.CLC',  AT_VALUE,     '%6.1f');
    8: SetData('маг_отклон.CLC',   AT_VALUE,     '%6.1f');
    9: SetData('амплит_accel.CLC', AT_VALUE,     '%7.3f');
   10: SetData('амплит_magnit.CLC',AT_VALUE,     '%7.3f');
   11: SetData('маг_наклон.CLC',   AT_VALUE,     '%6.1f');
   12: SetData('accel.X.DEV',      AT_VALUE,     '%7.4f');
   13: SetData('accel.Y.DEV',      AT_VALUE,     '%7.4f');
   14: SetData('accel.Z.DEV',      AT_VALUE,     '%7.4f');
   15: SetData('magnit.X.DEV',     AT_VALUE,     '%7.4f');
   16: SetData('magnit.Y.DEV',     AT_VALUE,     '%7.4f');
   17: SetData('magnit.Z.DEV',     AT_VALUE,     '%7.4f');
   18: SetData('accel.X.CLC',      AT_VALUE,     '%7.1f');
   19: SetData('accel.Y.CLC',      AT_VALUE,     '%7.1f');
   20: SetData('accel.Z.CLC',      AT_VALUE,     '%7.1f');
   21: SetData('magnit.X.CLC',     AT_VALUE,     '%7.1f');
   22: SetData('magnit.Y.CLC',     AT_VALUE,     '%7.1f');
   23: SetData('magnit.Z.CLC',     AT_VALUE,     '%7.1f');
   24: SetData('СТОЛ',             'амплит_magnit', '%7.1f');
   25: SetData('T.DEV',            AT_VALUE, '%7.1f');
   end;
end;

function TFormInclinCheck.AddStep(const Info: string; a, z, o: Double): Variant;
 var
  r: IXMLNode;
begin
  r := TMetrInclinMath.AddStep(FStep.stp, Format(Info, [a,z,o]), FStep.root);
  TXMLScriptMath.AddXmlPath(r, 'зенит.CLC');
  TXMLScriptMath.AddXmlPath(r, 'азимут.CLC');
  TXMLScriptMath.AddXmlPath(r, 'отклонитель.CLC');
  TXMLScriptMath.AddXmlPath(r, 'маг_отклон.CLC');
  TXMLScriptMath.AddXmlPath(r, 'амплит_accel.CLC');
  TXMLScriptMath.AddXmlPath(r, 'амплит_magnit.CLC');
  TXMLScriptMath.AddXmlPath(r, 'маг_наклон.CLC');
  TXMLScriptMath.AddXmlPath(r, 'СТОЛ');
  TXMLScriptMath.AddXmlPath(r, 'T.DEV');
  Result := XToVar(r);
  Result.T.DEV.VALUE := 0;
  Result.зенит.CLC.VALUE := 0;
  Result.зенит.METR := ME_ANGLE;
  Result.азимут.CLC.VALUE := 0;
  Result.азимут.METR := ME_ANGLE;
  Result.отклонитель.CLC.VALUE := 0;
  Result.отклонитель.METR := ME_ANGLE;
  Result.маг_отклон.CLC.VALUE := 0;
  Result.маг_отклон.METR := ME_ANGLE;
  Result.маг_наклон.CLC.VALUE := 0;
  Result.маг_наклон.METR := ME_ANGLE;
  Result.амплит_accel.CLC.VALUE := 0;
  Result.амплит_magnit.CLC.VALUE := 0;
  Result.СТОЛ.азимут := a;
  Result.СТОЛ.зенит := z;
//  Result.СТОЛ.визир := 0;
  Result.СТОЛ.err_азимут := 0;
  Result.СТОЛ.err_зенит := 0;
  Result.СТОЛ.амплит_magnit := 1000;
  Inc(FStep.stp);
end;

function TFormInclinCheck.UserSetupAlg(alg: IXMLNode): Boolean;
 var
  s: Variant;
  i, zu: Integer;
  procedure AddVizir(v: Integer);
  begin
    FCurViz := v*45;
    s := AddStep('прибор: визир %2:g градусов.', FCurAzim, FCurZu, FCurViz);
    s.TASK.Vizir_Dev := FCurViz;
    s.TASK.Vizir_tol := 0.5;
    s.TASK.Vizir_NIter := 4;
    s.TASK.Dalay_Kadr := 5;
  end;
  procedure AddAzim(a: Integer);
  begin
    FCurAzim := a*30;
    s := AddStep('стол: Азимут %g градусов.', FCurAzim, FCurZu, FCurViz);
    s.TASK.Azimut_Stol := FCurAzim;
    s.TASK.Dalay_Kadr := 5;
  end;
begin
  Result := True;
  FStep.root := alg;
  FStep.stp := 1;
  FCurZu := 30;
  FCurAzim := 0;
  FCurViz := 0;
  s := AddStep('стол: Азимут стол 0, Зенит 30, прибор: визир 0 градусов.', FCurAzim, FCurZu, FCurViz);
  s.TASK.Azimut_Stol := 0;
  s.TASK.Zenit_Stol := 30;
  s.TASK.Vizir_Dev :=  0;
  s.TASK.Vizir_tol :=  0.5;
  s.TASK.Vizir_NIter :=  4;
  s.TASK.Dalay_Kadr := 5;

  for I := 1 to 7 do AddVizir(i);

  FCurZu := 60;
  while FCurZu <= 120 do
   begin
    FCurViz := 315;
    s := AddStep('Зенит %1:g, прибор: визир 315 градусов.', FCurAzim, FCurZu, FCurViz);
    s.TASK.Zenit_Stol := FCurZu;
    s.TASK.Vizir_Dev :=  315;
    s.TASK.Vizir_tol :=  0.5;
    s.TASK.Vizir_NIter :=  4;
    s.TASK.Dalay_Kadr := 5;
    for I := 6 downto 0 do AddVizir(i);
    FCurZu := FCurZu + 30;
    if FCurZu > 120 then Break;
    s := AddStep('Зенит %1:g, прибор: визир 0 градусов.', FCurAzim, FCurZu, FCurViz);
    s.TASK.Zenit_Stol := FCurZu;
    s.TASK.Vizir_Dev :=  0;
    s.TASK.Vizir_tol :=  0.5;
    s.TASK.Vizir_NIter :=  4;
    s.TASK.Dalay_Kadr := 5;
    for I := 1 to 7 do AddVizir(i);
    FCurZu := FCurZu +30;
   end;
   FCurAzim := 0;
   FCurZu := 120;
   FCurViz := 180;
  s := AddStep('стол: Азимут стол %g, Зенит 120, прибор: визир 180 градусов.', FCurAzim, FCurZu, FCurViz);
  s.TASK.Azimut_Stol := 0;
  s.TASK.Zenit_Stol := 120;
  s.TASK.Vizir_Dev := 180;
  s.TASK.Vizir_tol :=  0.5;
  s.TASK.Vizir_NIter := 4;
  s.TASK.Dalay_Kadr := 5;
  for i := 1 to 11 do AddAzim(i);
  FCurZu := 90;
  while FCurZu >= 30 do
   begin
    s := AddStep('стол: Азимут стол 330, Зенит %1:g градусов', FCurAzim, FCurZu, FCurViz);
    s.TASK.Zenit_Stol := FCurZu;
    s.TASK.Dalay_Kadr := 5;
    for i := 10 downto 0 do AddAzim(i);
    FCurZu := FCurZu - 30;
    if FCurZu < 30 then break;
    s := AddStep('стол: Азимут стол 0, Зенит %1:g градусов', FCurAzim, FCurZu, FCurViz);
    s.TASK.Zenit_Stol := FCurZu;
    s.TASK.Dalay_Kadr := 5;
    for i := 1 to 11 do AddAzim(i);
    FCurZu := FCurZu - 30;
   end;
  FCurZu := 10;
  s := AddStep('стол: Азимут стол 0, Зенит %1:g градусов', FCurAzim, FCurZu, FCurViz);
  s.TASK.Zenit_Stol := 10;
  s.TASK.Dalay_Kadr := 5;
  for i := 1 to 11 do AddAzim(i);
  FCurZu := 5;
  s := AddStep('стол: Азимут стол 330, Зенит %1:g градусов', FCurAzim, FCurZu, FCurViz);
  s.TASK.Zenit_Stol := 5;
  s.TASK.Dalay_Kadr := 5;
  for i := 10 downto 0 do AddAzim(i);
end;

function TFormInclinCheck.FindMaxErr(alg: IXMLNode;  from, too: Integer; const attr: string): Double;
 var
  i: Integer;
  n: IXMLNode;
begin
  Result := 0;
  for I := from to too do if TryGetX(alg, Format('STEP%d.СТОЛ',[I]), n, attr) and (Abs(Result) < Abs(n.NodeValue)) then Result := n.NodeValue
end;


procedure TFormInclinCheck.RefindZen(from, too: Integer; alg, trr: IXMLNode);
 var
  i: Integer;
  t, a: variant;
  crZen: Double;
begin
  t := XtoVar(trr);
  for I := from to too do
   begin
    a := XToVar(GetXNode(alg, Format('STEP%d',[I])));
    TMetrInclinMath.FindZenViz(a, t);
    crZen := (a.СТОЛ.зенит + FZenCorr);
    if crZen > 180 then a.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(a.зенит.CLC.VALUE -(360 - crZen))
    else a.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(a.зенит.CLC.VALUE - crZen);
   end;
end;

procedure TFormInclinCheck.RefindAzi(from, too: Integer; alg, trr: IXMLNode);
 var
  i: Integer;
  t, a: variant;
begin
  t := XtoVar(trr);
  for I := from to too do
   begin
    a := XToVar(GetXNode(alg, Format('STEP%d',[I])));
    TMetrInclinMath.FindAzim(a, t);
    a.СТОЛ.err_азимут := TMetrInclinMath.DeltaAngle(a.азимут.CLC.VALUE - (a.СТОЛ.азимут + FAziCorr));
   end;
end;

function TFormInclinCheck.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
begin
  Result := True;
//  UserExecStepUpdateStolAngle(Step, alg, trr);
  case Step of
   32 :
       begin
        RefindZen(1, 32, alg, trr);
        RefindAzi(1, 32, alg, trr);
        alg.Attributes['ErrZU']  := FindMaxErr(alg, 1,    32, 'err_зенит');
       end;
   80 :
     begin
      RefindZen(33, 80, alg, trr);
      RefindAzi(33, 80, alg, trr);
      alg.Attributes['ErrAZ']  := FindMaxErr(alg, 33,   80, 'err_азимут');
     end;
   104:
    begin
     RefindZen(81, 104, alg, trr);
     RefindAzi(81, 104, alg, trr);
     alg.Attributes['ErrAZ5'] := FindMaxErr(alg, 81,  104, 'err_азимут');
    end;
  end;
end;

{procedure TFormInclinCheck.UserExecStepUpdateStolAngle(Step: Integer; alg, trr: IXMLNode);
 var
  n: IXMLNode;
begin
  if TryGetX(alg, Format('STEP%d.TASK',[Step]), n) then
   begin
     if n.HasAttribute('Vizir_Stol') then FStolVizir := Double(n.Attributes['Vizir_Stol']);
     if n.HasAttribute('Azimut_Stol') then FStolAzimut := Double(n.Attributes['Azimut_Stol']);
     if n.HasAttribute('Zenit_Stol') then FStolZenit := Double(n.Attributes['Zenit_Stol']);
   end;
end;}

{$ENDREGION}

{ TFormInclinCheckPoly }

class procedure TFormInclinCheckPoly.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclinCheckPoly.MetrolAttrName: string;
begin
  Result := 'INKLGK4'
end;

function TFormInclinCheckPoly.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 var
   pmA,pmH: PolyModel;
   Naklon: Double;
   Input: TArray<TinclInput>;
   cnt: Integer;
begin
  Result := True;
  if Step = 104 then
    begin


     Naklon := alg.Attributes['MagNaklon'];
     pmA :=  GetXNode(trr, 'Poly.accel').Attributes['Model'];
     pmH :=  GetXNode(trr, 'Poly.magnit').Attributes['Model'];

     SetLength(Input, alg.ChildNodes.Count);
     cnt := 0;
     for var i := 0 to alg.ChildNodes.Count-1 do
      begin
       var st := XtoVar(alg.ChildNodes[i]);
       if string(st.INFO).Contains('NotUse') or (string(st.EXECUTED) = 'false') then Continue;
       Input[cnt] := st;
       Inc(cnt);
      end;
     Setlength(Input,cnt);
     TpolyMath.Init(pmA,pmH, Naklon, Input);



    TpolyMath.findErr(alg, trr, SCALE_A,SCALE_H, RES_AMP, Naklon, False);


    for var i:= 0 to High(TpolyMath.InclRes) do
    begin
     var a := XtoVar(GetXNode(alg, Format('STEP%d',[i+1])));
     var r := TpolyMath.InclRes[i];
      a.зенит.CLC.VALUE := r.Zen.Angle;
      a.азимут.CLC.VALUE := r.Azi.Angle;
      a.отклонитель.CLC.VALUE := r.Otk.Angle;
      a.маг_отклон.CLC.VALUE := r.MO.Angle;
      a.маг_наклон.CLC.VALUE := r.Nakl.Angle;
      a.амплит_accel.CLC.VALUE := r.Amp[sAcc];
      a.амплит_magnit.CLC.VALUE := r.Amp[sMag];
     a.СТОЛ.err_зенит := r.Zen.Error;
     a.СТОЛ.err_азимут := r.Azi.Error;
    end;

    AttestatLabel.Caption := TpolyMath.EStatToStr(
      'Accel: %d %1.2f%% av: %1.3f%%     Magnit: %d %1.2f%% av: %1.3f%%     Ink: %d %1.2f av: %1.3f'#$D#$A
     +'Зенит: %d %1.2f av: %1.3f      Азимут: %d %1.2f av: %1.3f     Визир: %d %1.2f av: %1.3f');
   end;

end;

initialization
  RegisterClass(TFormInclinCheck);
  TRegister.AddType<TFormInclinCheck, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormInclinCheckPoly);
  TRegister.AddType<TFormInclinCheckPoly, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInclinCheck>;
  GContainer.RemoveModel<TFormInclinCheckPoly>;
end.
