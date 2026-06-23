unit MetrAccel.CheckForm;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, RootImpl,
     LuaInclin.Math, XMLLua.Math, MetrInclin.Math2,
     VirtualTrees, Xml.XMLIntf, Vcl.Menus, JvInspector,
     Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
     Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormAccelCheck = class(TFormMetrolog)
    PanelM: TPanel;
    lbInfo: TLabel;
    pc: TCPageControl;
    Tree: TVirtualStringTree;
    PanelP: TPanel;
    TreeA: TVirtualStringTree;
    Splitter: TSplitter;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FNsolver: TMenuItem;
    procedure NShowTrrClick(Sender: TObject);
    procedure NNewAlgClick(Sender: TObject);
  protected
    FStep: record
            stp: Integer;
            root: IXMLNode;
           end;
    FCurViz, FCurZu: Double;
    procedure DoStandartSetup(Item: TJvCustomInspectorItem; Option: IXMLNode; var Data: IXMLNode); override;
    procedure RefindZen(from, too: Integer; alg, trr: IXMLNode);
    function AddStep(const Info: string; z, o: Double): Variant;
    procedure Loaded; override;
    procedure DoSetFont(const AFont: TFont); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
   const
    NICON = 96;
    CNT0 = 8;
    CNT45 = 8;
    CNT90 = 8;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
    class function ClassIcon: Integer; override;
  public

    [StaticAction('Новая метрология акселерометра 20', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

implementation

{$R *.dfm}

uses tools, Vector, {MetrInclin.CheckFormSetup,} MetrInclin;

{ TFormInclinCheck }

procedure TFormAccelCheck.NNewAlgClick(Sender: TObject);
begin
  ReCalc();
  DoUpdateData();
end;

class function TFormAccelCheck.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormAccelCheck.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormAccelCheck.DoSetFont(const AFont: TFont);
begin
  inherited;
  TreeSetFont(TreeA);
end;

procedure TFormAccelCheck.DoStandartSetup(Item: TJvCustomInspectorItem; Option: IXMLNode; var Data: IXMLNode);
begin
  inherited;
  if (Option.NodeName = 'ErrZU') or (Option.NodeName = 'ErrAZ') or (Option.NodeName = 'ErrAZ5') then TJvInspectorFloatItem(Item).Format := '0.00';
end;

procedure TFormAccelCheck.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  TFormInclin.UpdateAH(TreeA, GetMetr(['m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
end;

procedure TFormAccelCheck.DoUpdateData(NewFileData: Boolean);
begin
  inherited DoUpdateData(NewFileData);
  TFormInclin.UpdateAH(TreeA, GetMetr(['m3x4'], GetFileOrDevData), '%1.5f', '%1.3f', '%1.5f');
end;

procedure TFormAccelCheck.Loaded;
begin
  FlagNoUpdateFromEtalon := True;
  SetupStepTree(Tree);
  TFormInclin.InitT(TreeA);
  inherited;
  AddToNCMenu('-', nil, 10);
  AddToNCMenu('Рассчет новых поправок', NNewAlgClick, 11);
  AddToNCMenu('Показывать поправки', NShowTrrClick, 12, AUTO_CHECK[PanelP.Visible]);
  FNsolver := AddToNCMenu('Не использовать НМК', nil, 13, 0, nil);
  AttestatPanel.Align := alBottom;
end;

class function TFormAccelCheck.MetrolMame: string;
begin
  Result := 'accel'
end;

class function TFormAccelCheck.MetrolType: string;
begin
  Result := 'ACL14'
end;

procedure TFormAccelCheck.NShowTrrClick(Sender: TObject);
begin
  PanelP.Visible := TMenuItem(Sender).Checked;
  Splitter.Top := PanelM.Height;
end;

procedure TFormAccelCheck.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
end;


procedure TFormAccelCheck.TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
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


procedure TFormAccelCheck.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
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
    1: SetData('зенит.CLC',        AT_VALUE,     '%7.2f');
    2: SetData('отклонитель.CLC',  AT_VALUE,     '%6.1f');
    3: SetData('амплит_accel.CLC', AT_VALUE,     '%7.1f');
    4: SetData('X.DEV',      AT_VALUE,     '%7.4f');
    5: SetData('Y.DEV',      AT_VALUE,     '%7.4f');
    6: SetData('Z.DEV',      AT_VALUE,     '%7.4f');
    7: SetData('X.CLC',      AT_VALUE,     '%7.1f');
    8: SetData('Y.CLC',      AT_VALUE,     '%7.1f');
    9: SetData('Z.CLC',      AT_VALUE,     '%7.1f');
   end;
end;

function TFormAccelCheck.AddStep(const Info: string;z, o: Double): Variant;
 var
  r: IXMLNode;
begin
  r := TMetrInclinMath.AddStepAccel(FStep.stp, Format(Info, [z,o]), FStep.root);
  TXMLScriptMath.AddXmlPath(r, 'зенит.CLC');
  TXMLScriptMath.AddXmlPath(r, 'отклонитель.CLC');
  TXMLScriptMath.AddXmlPath(r, 'амплит_accel.CLC');
  Result := XToVar(r);
  Result.зенит.CLC.VALUE := 0;
  Result.зенит.METR := ME_ANGLE;
  Result.отклонитель.CLC.VALUE := 0;
  Result.отклонитель.METR := ME_ANGLE;
  Result.амплит_accel.CLC.VALUE := 0;
  Inc(FStep.stp);
end;

function TFormAccelCheck.UserSetupAlg(alg: IXMLNode): Boolean;
 var
  i: Integer;
  procedure AddVizir(v, Delta: Integer);
  begin
    FCurViz := v*Delta;
    AddStep('зенит: %g визир: %g градусов.', FCurZu, FCurViz);
  end;
begin
  Result := True;
  FStep.root := alg;
  FStep.stp := 1;
  FCurZu := 0;
  for I := 0 to CNT0-1 do AddVizir(i, 360 div CNT0);
  FCurZu := 45;
  for I := 0 to CNT45-1 do AddVizir(i, 360 div CNT45);
  FCurZu := 90;
  for I := 0 to CNT90-1 do AddVizir(i, 360 div CNT90);
end;

procedure TFormAccelCheck.RefindZen(from, too: Integer; alg, trr: IXMLNode);
 var
  inp: TAngleFtting.TInput;
  Res: TMatrix4;
  alignInp: TZAlignLS.TInput;
  FSaveAccel: TMatrix4;
  a, b : Double;
  function ToInp2(alg: IXMLNode; from, too: Integer; Trr: TMatrix4): TZAlignLS.TZConstPoints;
   var
    i: Integer;
    v: Variant;
    p: TVector3;
  begin
    SetLength(Result, too-from+1);
    for i := 0 to High(Result) do
     begin
      v := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));
      p.X := v.X.DEV.VALUE;
      p.Y := v.Y.DEV.VALUE;
      p.Z := v.Z.DEV.VALUE;
      Result[i] := Trr * p;
     end;
  end;
  function ToInpRoll(alg: IXMLNode; from, too: Integer; Trr: TMatrix4): TZAlignLS.TInput;
   var
    ArrCnt: TArray<Integer>;
    i, first: Integer;
  begin
    ArrCnt := [CNT0, CNT45, CNT90];// ToRollCounts(alg, from, too);
    SetLength(Result, Length(ArrCnt));
    first := from;
    for i := 0 to High(ArrCnt) do
     begin
      Result[i] := ToInp2(alg, first, first + ArrCnt[i]-1, Trr);
      Inc(first, ArrCnt[i]);
     end;
  end;
  function ToInp(alg: IXMLNode; from, too: Integer): TAngleFtting.TInput;
   var
    i: Integer;
    v:Variant;
  begin
    SetLength(Result, too-from+1);
    for i := 0 to High(Result) do
     begin
      v := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));
      with Result[i] do
       begin
        gx := v.X.DEV.VALUE;
        gy := v.Y.DEV.VALUE;
        gz := v.Z.DEV.VALUE;
       end;
     end;
  end;
  procedure FindZenViz(stp, trr: Variant);
   var
    o, zu, x,y,z: Double;
  begin
    TXMLScriptMath.TrrVect3D(TVxmlData(trr.m3x4).Node, TVxmlData(stp).Node, x, y, z);//, 1000);
    stp.амплит_accel.CLC.VALUE := TXMLScriptMath.Hypot3D(x, y, z);

    o := Arctan2(y, -x);
    zu := Arctan2(Hypot(x, y), z);

    stp.зенит.CLC.VALUE       := TXMLScriptMath.RadToDeg360(zu);
    stp.отклонитель.CLC.VALUE := TXMLScriptMath.RadToDeg360(o);
  end;

  procedure ApplyZen(from, too: Integer; alg, trr: IXMLNode);
   var
    i: Integer;
    t, a: variant;
  begin
    t := XtoVar(trr);
    for I := from to too do
     begin
      a := XToVar(GetXNode(alg, Format('STEP%d',[I])));
      FindZenViz(a, t);
     end;
  end;

begin
{  tG := Matrix4Identity;
  tH := Matrix4Identity;
  with tG do
   begin
    m11 :=	0.91;      m12 :=	0.0012;        m13 :=	 -0.0013;   m14 := -1.4;
    m21 :=	0;        m22 :=	0.92;           m23 :=	0.0023;     m24 := 2.4;
    m31 :=	0.0031;   m32 :=	-0.0032;      m33 :=	 0.93;  m34 := -3.4;
   end;
  with tH do
   begin
    m11 :=	 1.71;         m21 :=	0.003;       m31 :=	-0.0031;
    m12 :=	-0.0112;       m22 :=	1.72;         m32 :=	-0.0032;
    m13 :=	-0.0013;       m23 :=	0.0023;       m33 :=	1.73;
    m14 :=	-10.4;          m24 :=	20.4;          m34 :=	-30.4;
   end;}
//  _TEST_ApplyHGfromStol(alg, from, too, 10.9, 1000, tG, tH);
    inp := ToInp(alg, from, too);
    // без стола
    TSphereLS.RunZ(inp, Res);
{    SetLength(alignInp, 12);//6
    for I := 0 to High(alignInp) do alignInp[i] := ToInp(alg, 5+i*5, 9+i*5, True, Res);}
    alignInp := ToInpRoll(alg, from, too, Res);
    //  SetLength(alignInp, 1);
    //  i := 1;
    //  alignInp[0] := ToInp(alg, 35+i*5, 39+i*5, True, Res);
   if FNsolver.Checked then
    begin
     TZAlignLS.RunLeMa(alignInp, a,b);
     FSaveAccel := TZAlignLS.ApplyLeMa(Res, a, b);
    end
   else
    begin
     TZAlignLS.Run(alignInp, a,b);
     FSaveAccel := TZAlignLS.Apply(Res, a, b);
    end;
    Matrix4AssignToVariant(FSaveAccel, XToVar(trr));
    ApplyZen(from, too, alg, trr);
end;

function TFormAccelCheck.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
begin
  Result := True;
  case Step of
   CNT0+CNT45+CNT90:
       begin
        RefindZen(1, CNT0+CNT45+CNT90, alg, trr);
       end;
  end;
end;

initialization
  RegisterClass(TFormAccelCheck);
  TRegister.AddType<TFormAccelCheck, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormAccelCheck>;
end.
