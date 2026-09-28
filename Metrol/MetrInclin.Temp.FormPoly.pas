unit MetrInclin.Temp.FormPoly;

interface

uses System.Generics.Collections,  MathIntf,  LuaInclin.Math,  TrrInclin.Temp.PolyModel, LuaInclin.Temp.Poly,
     MetrInclin.Temp.Stat,  AutoMetr.Inclin.ChekH,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, tools, XMLLua.Math,
  MetrUAKI,  VirtualTrees.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList, Vcl.ExtCtrls, Vcl.StdCtrls,
  MetrForm, Vcl.ComCtrls, AutoMetr.Inclin, RootImpl,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormMetrInclinTP = class(TFormMetrolog, IAutomatMetrology)
    Tree: TVirtualStringTree;
    lbInfo: TLabel;
    pAlg: TPanel;
    pRes: TPanel;
    sp: TSplitter;
    TreeResA: TVirtualStringTree;
    TreeResH: TVirtualStringTree;
    splRes: TSplitter;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeResAGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeResAPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType);
    procedure TreeResHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: string);
    procedure FormDestroy(Sender: TObject);
  private
    FAutomatMetrology: TinclAuto;
    FStolVizir: Double;
    FStolAzimut: Double;
    FStolZenit: Double;
    FNakl : Double;
    Fhck: Double;
    FhckCnt: Integer;
    pmA,pmH: PolyModel;
    FColumns: TColumns;
    procedure UpdateRes(trr: IXMLNode);
    procedure NShowStolAndDev(Sender: TObject);
    procedure NShowResClick(Sender: TObject);
    procedure NShowDialofClick(Sender: TObject);
    procedure EFileChahge(Sender: TObject);
    procedure UpdateFromOptions(alg: IXMLNode);
    function  TreeResGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; pm: PolyModel): string;
    function GetCurrentAlg: IXMLNode;
    function GetCurrentTrr: IXMLNode;
    procedure HChekOnUpdate(Sender: TObject);
  protected
   const
    NICON = 186;
    procedure InitializeNewForm; override;
    procedure OptionChanged(); override;
    procedure Loaded; override;
    function UserExecStep(Step: Integer; alg,trr: IXMLNode): Boolean; override;
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType); override;
    procedure DoStartAtt(AttNode: IXMLNode); override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    class function ClassIcon: Integer; override;
  public
    procedure RecalcResultAndUpdateTree(Iskoso: Boolean; IsLin: Boolean = False);
    property CurrentTrr: IXMLNode read GetCurrentTrr;
    property CurrentAlg: IXMLNode read GetCurrentAlg;

    property StolVizir: Double read FStolVizir;
    property StolZenit: Double read FStolZenit;
    property StolAzimut: Double read FStolAzimut;
    [StaticAction('Метр. Инкл. Т poly ALL', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    class function MetrolAttrName: string; override;
    destructor Destroy; override;
    property AutomatMetrology: TinclAuto read FAutomatMetrology implements IAutomatMetrology;
  end;
  TFormMetrInclinUniT = class(TFormMetrInclinTP)
   const
    NICON = 196;
    [StaticAction('Метр. Инкл. Т Uni ALL 540', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
    class function MetrolAttrName: string; override;
    end;

  TFormMetrInclinTPOnlyT = class(TFormMetrInclinTP)
   const
    NICON = 186;
    [StaticAction('Метр. Инкл. Т poly ONLY T', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
    end;

implementation

{$R *.dfm}

uses  MetrInclin.Temp.MathPoly;

{$REGION 'Any'}

class function TFormMetrInclinTP.ClassIcon: Integer;
begin
  Result := NICON;
end;

destructor TFormMetrInclinTP.Destroy;
begin
  FAutomatMetrology.Free;
  FColumns.Free;
  inherited;
end;

class procedure TFormMetrInclinTP.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormMetrInclinTP.DoStartAtt(AttNode: IXMLNode);
 var
  n: IXMLNode;
begin
  inherited;
  if TryGetX(AttNode, 'TASK', n) then
   begin
    if n.HasAttribute('Vizir_Stol') then FStolVizir := Double(n.Attributes['Vizir_Stol']);
    if n.HasAttribute('Azimut_Stol') then FStolAzimut := Double(n.Attributes['Azimut_Stol']);
    if n.HasAttribute('Zenit_Stol') then FStolZenit := Double(n.Attributes['Zenit_Stol']);
   end;
end;

procedure TFormMetrInclinTP.DoStopAtt(AttNode: IXMLNode);
 var
  v: Variant;
begin
  v := XToVar(AttNode);
  if FAutomatMetrology.UakiExists then
   begin
    v.СТОЛ.азимут := Double(FAutomatMetrology.uaki.Azi.CurrentAngle);
    v.СТОЛ.зенит := Double(FAutomatMetrology.uaki.Zen.CurrentAngle);
    v.СТОЛ.визир := Double(FAutomatMetrology.uaki.Viz.CurrentAngle);
     if FhckCnt > 0 then
      begin
        v.СТОЛ.амплит_magnit := Fhck/FhckCnt;
        Fhck := 0;
        FhckCnt := 0;
      end
     else v.СТОЛ.амплит_magnit := 1000;
   end
  else
   begin
    v.СТОЛ.зенит := StolZenit;
    v.СТОЛ.визир := StolVizir;
    v.СТОЛ.азимут := StolAzimut;
    v.СТОЛ.амплит_magnit := 1000;
   end;
  inherited;
end;

procedure TFormMetrInclinTP.NShowDialofClick(Sender: TObject);
 var
   Dialog: IDialog;
begin
  RegisterDialog.TryGet('Metrolog', 'TempPoly', Dialog);
  (Dialog as IDialog<TFormMetrInclinTP>).Execute(self);
end;

procedure TFormMetrInclinTP.NShowResClick(Sender: TObject);
begin
  pRes.Visible := TMenuItem(Sender).Checked;
  sp.Top := pAlg.Height;
  sp.Visible := pRes.Visible;
  if pRes.Visible then UpdateRes(GetMetr([], GetFileOrDevData));
end;

procedure TFormMetrInclinTP.NShowStolAndDev(Sender: TObject);
 const
  VSTR: TArray<string> = ['№','T','sZu','sAz','sVis','sH','GX','GY','GZ','HX','HY','HZ'];
begin
  Tree.beginUpdate;
  try
    for var i := 0 to Tree.Header.Columns.Count-1 do
      begin
       var v := Tree.Header.Columns[i];
       Tree.Header.PopupMenu.Items[i].Checked := False;
       v.Options := v.Options - [coVisible];
       for var vs in VSTR do if vs = v.Text then
        begin
         v.Options := v.Options + [coVisible];
         Tree.Header.PopupMenu.Items[i].Checked := True;
         Break;
        end;
      end;
  finally
   Tree.endUpdate;
  end;
end;

procedure TFormMetrInclinTP.EFileChahge(Sender: TObject);
begin
  UpdateFromOptions(GetMetr([MetrolType], GetFileOrDevData));
end;

procedure TFormMetrInclinTP.FormDestroy(Sender: TObject);
begin
  if Assigned(GChekH) then GChekH.UnBind(self);
end;

procedure TFormMetrInclinTP.OptionChanged;
begin
  UpdateFromOptions(GetMetr([MetrolType], GetFileOrDevData));
  inherited;
end;

procedure TFormMetrInclinTP.RecalcResultAndUpdateTree(Iskoso: Boolean; IsLin: Boolean = False);
begin
  TpolyMath.findErr(CurrentAlg, CurrentTrr, SCALE_A,SCALE_H,RES_AMP, FNakl, Iskoso);
  UpdateRes(CurrentTrr);
  AttestatLabel.Caption := TpolyMath.EStatToStr(
  'Accel: %d %1.2f%% av: %1.3f%%     Magnit: %d %1.2f%% av: %1.3f%%     Ink: %d %1.2f av: %1.3f'#$D#$A
  +'Зенит: %d %1.2f av: %1.3f      Азимут: %d %1.2f av: %1.3f     Визир: %d %1.2f av: %1.3f');
  CopyTrrToDev();
  DoUpdateData();
  if TrrFile <> '' then FileData.OwnerDocument.SaveToFile(TrrFile)
end;


procedure TFormMetrInclinTP.InitializeNewForm;
begin
  FColumns:= TColumns.Create([
   TColumnXML.Create('№','','STEP','',50),
   TColumnXML.Create('T','T.DEV'),
   TColumnXML.Create( 'sZu','СТОЛ','зенит','%7.2f'),
   TColumnAngleZ.Create( 'csZu', cacsA ),
   TColumnAngleZ.Create( 'Zu'  , caA   ),
   TColumnAngleZ.Create( 'eZU' , caE   ),
   TColumnXML.Create('sAz','СТОЛ','азимут'),
   TColumnAngle.Create( 'csAz', cacsA ),
   TColumnAngle.Create( 'Az'  , caA   ),
   TColumnAngle.Create( 'eAz' , caE   ),
   TColumnXML.Create('sVis','СТОЛ','визир'),
   TColumnAngleV.Create( 'csViz', cacsA ),
   TColumnAngleV.Create( 'Vis'  , caA   ),
   TColumnAngleV.Create( 'eVis' , caE   ),
   TColumnXML.Create( 'sH','СТОЛ','амплит_magnit'),
   TColumnAmp.Create( 'H',sMag),
   TColumnAmp.Create( 'eH',sMag, True),
   TColumnAmp.Create( 'G',sAcc),
   TColumnAmp.Create( 'eG',sAcc,True),
   TColumnAngleI.Create( 'I', caA),
   TColumnAngleI.Create( 'eI',caE),
   TColumnXML.Create('GX','accel.X.DEV'),
   TColumnXML.Create('GY','accel.Y.DEV'),
   TColumnXML.Create('GZ','accel.Z.DEV'),
   TColumnEtalon.Create('эGX',sAcc,vX),
   TColumnEtalon.Create('эGY',sAcc,vY),
   TColumnEtalon.Create('эGZ',sAcc,vZ),
   TColumnTrr.Create( 'tGX',sAcc,vX),
   TColumnTrr.Create( 'tGY',sAcc,vY),
   TColumnTrr.Create( 'tGZ',sAcc,vZ),
   TColumnErr.Create( 'eGX',sAcc,vX),
   TColumnErr.Create( 'eGY',sAcc,vY),
   TColumnErr.Create( 'eGZ',sAcc,vZ),
   TColumnXML.Create( 'HX','magnit.X.DEV'),
   TColumnXML.Create( 'HY','magnit.Y.DEV'),
   TColumnXML.Create( 'HZ','magnit.Z.DEV'),
   TColumnEtalon.Create( 'эHX', sMag, vX),
   TColumnEtalon.Create( 'эHY', sMag, vY),
   TColumnEtalon.Create( 'эHZ', sMag, vZ),
   TColumnTrr.Create( 'tHX', sMag, vX),
   TColumnTrr.Create( 'tHY', sMag, vY),
   TColumnTrr.Create( 'tHZ', sMag, vZ),
   TColumnErr.Create( 'eHX', sMag, vX),
   TColumnErr.Create( 'eHY', sMag, vY),
   TColumnErr.Create( 'eHZ', sMag, vZ)
 ]);
  inherited;
end;

procedure TFormMetrInclinTP.Loaded;
 var
  e: TevTypes;
  model: string;
begin
  e.Update := HChekOnUpdate;
  if Assigned(GChekH) then GChekH.Bind(Self, e);
  if Tree.Header.Columns.Count = 0 then  FColumns.SetTreeColumns(Tree);

  OnFileChahge := EFileChahge;

  FlagNoUpdateFromEtalon := True;
  SetupStepTree(Tree);
  TreeResA.NodeDataSize := SizeOf(TNodeExData);
  TreeResH.NodeDataSize := SizeOf(TNodeExData);
  inherited;
  FAutomatMetrology := TinclAuto.Create(Self, AutoReport);
  AttestatPanel.Align := alBottom;
  AddToNCMenu('Show dialog...', NShowDialofClick, 0, -1);
  AddToNCMenu('Покозывать только данные аттестации', NShowStolAndDev, 0, -1);
  var m := AddToNCMenu('Результат', NShowResClick, 1, 0);
  m.Checked := pRes.Visible;
  var mtr := GetMetr([], GetFileOrDevData);
  if not Assigned(mtr) then Exit;

  if pRes.Visible then UpdateRes(mtr);
  UpdateFromOptions(mtr.ChildNodes.FindNode(MetrolType));
end;

class function TFormMetrInclinTP.MetrolAttrName: string;
begin
  Result := 'INKLGK4'
end;

class function TFormMetrInclinTP.MetrolMame: string;
begin
  Result := 'Inclin'
end;

class function TFormMetrInclinTP.MetrolType: string;
begin
  Result := 'IT4polyALL'
end;


procedure TFormMetrInclinTP.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
end;

procedure TFormMetrInclinTP.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
 var
  p: PNodeExData;
  r: IXMLNode;
  i: Integer;
  vp: Variant;
//  procedure SetData(const path, attr, fmt: string; Correction: Double = 0; Scale: Double = 1);
//   var
//    V: IXMLNode;
//  begin
//    if TryGetX(p.XMNode, path, V, attr) then
//      if fmt ='%s' then
//        CellText := V.NodeValue
//      else
//        CellText := Format(fmt,[(Double(V.NodeValue) + Correction)*Scale])
//    else
//         CellText := ''
//  end;
//  function StolEtalon(const attr: string): Double;
//   var
//    V: IXMLNode;
//  begin
//    if TryGetX(p.XMNode, 'СТОЛ', V, attr) then
//     Result := Double(V.NodeValue)
//    else
//     Result := 0;
//  end;
//  var
//  FmtEnalon: string;
begin
  CellText := '';
//  if RES_AMP = 1 then FmtEnalon :='%7.3f'
//  else FmtEnalon := '%7.2f';

  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
//  vp := XToVar(p.XMNode);
  CellText := FColumns.Get(Column, p.XMNode);
end;

procedure TFormMetrInclinTP.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType);
var
  xd: PNodeExData;
begin
  inherited;
  xd := Sender.GetNodeData(Node);
  if Assigned(xd.XMNode) and xd.XMNode.HasAttribute('EXECUTED') then
   begin
     FColumns.Paint(Column, xd.XMNode, TargetCanvas);
   end;
end;

procedure TFormMetrInclinTP.TreeResAPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType);
var
  xd: PNodeExData;
begin
  xd := Sender.GetNodeData(Node);
  if not Assigned(xd.XMNode) or(Column < 1) then Exit;
  var n := xd.XMNode;
  if SameText(n.NodeName, string(Sender.Header.Columns[Column].Text[1])) then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then clSkyBlue else clBlue;
end;

function TFormMetrInclinTP.TreeResGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; pm: PolyModel): string;
 var
  p: PNodeExData;
begin
  Result := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  if Column = 0 then
    Result := p.XMNode.NodeName
  else if Column > 0 then
   begin
    if VarIsNull(p.XMNode.NodeValue) then Exit;
    var a := pm.ResultText(p.XMNode);
    if Length(a) >= Column then
      if a[Column-1] <> '' then Result := Format('%1.5f', [ StrToFloat(a[Column-1]) ]);
   end;
end;

procedure TFormMetrInclinTP.TreeResHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
begin
  CellText := TreeResGetText(Sender,Node,Column,pmH);
end;

procedure TFormMetrInclinTP.TreeResAGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
begin
  CellText := TreeResGetText(Sender,Node,Column,pmA);
end;


procedure TFormMetrInclinTP.UpdateFromOptions(alg: IXMLNode);
//  procedure ReadTemperatureModel(const Node: IXMLNode; var Model: PolyModel);
//  begin
//    if Assigned(Node) and Node.HasAttribute('Basis') and
//       SameText(string(Node.Attributes['Basis']), 'Chebyshev') then
//    begin
//      if not Node.HasAttribute('TMin') or not Node.HasAttribute('TMax') then
//        raise Exception.Create('Chebyshev model requires TMin and TMax');
//      Model.UseChebyshevTemperature(Double(Node.Attributes['TMin']),
//                                    Double(Node.Attributes['TMax']));
//    end
//    else
//      Model.UseLegacyTemperature;
//  end;
  procedure UpdateTree(pm: PolyModel; TreeRes: TVirtualStringTree);
    function AddCol(const name: string): TVirtualTreeColumn;
    begin
      Result := TreeRes.Header.Columns.Add;
      Result.Options := [coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus];
      Result.Text := name;
      Result.Width := 70;
      Result.MinWidth := 70;
    end;
  begin
    TreeRes.Header.Columns.Clear;
    var o := AddCol('Ось');
    o.MaxWidth := 70;
    for var m in pm.ResultHeaders do AddCol(m);
    TreeRes.Header.Columns[1].MaxWidth := 70;
  end;
begin
  if not Assigned(alg) then Exit;

  FNakl := alg.Attributes['MagNaklon'];
  pmA :=  string(alg.Attributes['ModelA']);
  pmH := string(alg.Attributes['ModelH']);

  TXMLScriptMath.AddPolyTrr(alg.ParentNode, alg.Attributes['ModelA'], alg.Attributes['ModelH'], False);
  var Poly := alg.ParentNode.ChildNodes.FindNode('Poly');

  if not Poly.HasAttribute('TMin') or not Poly.HasAttribute('TMax') then
    raise Exception.Create('Chebyshev model requires TMin and TMax');
  var TMin := Poly.Attributes['TMin'];
  var TMax := Poly.Attributes['TMax'];

//  ReadTemperatureModel(Poly.ChildNodes.FindNode('accel'), pmA);
//  ReadTemperatureModel(Poly.ChildNodes.FindNode('magnit'), pmH);

  UpdateTree(pmA, TreeResA);
  UpdateTree(pmH, TreeResH);
end;

procedure TFormMetrInclinTP.UpdateRes(trr: IXMLNode);

  procedure AddSence(TreeRes: TVirtualStringTree; s: IXMLNode);
  begin
    TreeRes.BeginUpdate;
    try
      for var pv in TreeRes.Nodes do
        PNodeExData(TreeRes.GetNodeData(pv)).XMNode := nil;
       TreeRes.Clear;
     for var ax in ['X','Y','Z'] do
      begin
       PNodeExData(TreeRes.GetNodeData(TreeRes.AddChild(nil))).XMNode := s.AttributeNodes[ax];
      end;
    finally
      TreeRes.EndUpdate;
    end;
  end;

begin
  AddSence(TreeResA, GetXNode(trr,'Poly.accel'));
  AddSence(TreeResH, GetXNode(trr,'Poly.magnit'));
end;

{$ENDREGION}

function TFormMetrInclinTP.GetCurrentAlg: IXMLNode;
begin
  Result := GetMetr([MetrolType], GetFileOrDevData);
end;

function TFormMetrInclinTP.GetCurrentTrr: IXMLNode;
begin
  Result := GetMetr([], GetFileOrDevData);
end;

procedure TFormMetrInclinTP.HChekOnUpdate(Sender: TObject);
begin
  var h := TChekH(Sender);

  if h.WireReady then
   begin
    var x := h.CurrenData.X;
    var y := h.CurrenData.Y;
    var z := h.CurrenData.Z;
    Fhck := Fhck + Sqrt(x*x+y*y+z*z);
    Inc(FhckCnt);
   end
end;

function TFormMetrInclinTP.UserExecStep(Step: Integer; alg,trr: IXMLNode): Boolean;

//  procedure FindEtalon(st: Variant);
//   var
//     ip: TInclPoint;
//     A,z,o: Double;
//  begin
//    a := st.СТОЛ.азимут;
//    z := st.СТОЛ.зенит;
//    o := st.СТОЛ.визир;
//
//    ip := TMetrInclinMath.FindXYZ(a,z,o,
//    Double(alg.Attributes['MagNaklon']), RES_AMP);
//    st.СТОЛ.GX := ip.G.X;
//    st.СТОЛ.GY := ip.G.Y;
//    st.СТОЛ.GZ := ip.G.Z;
//    st.СТОЛ.HX := ip.H.X;
//    st.СТОЛ.HY := ip.H.Y;
//    st.СТОЛ.HZ := ip.H.Z;
//  end;
//  procedure azo(Trr,st: IXMLNode; var g,h,i: Double);
//   var
//    azi,zen,otk: Double;
//  begin
//  //  FindTrrAxisAndAZO(Trr, st, azi, zen, otk,g,h, i);
//    var a := XToVar(st);
//    a.СТОЛ.err_азимут := TMetrInclinMath.DeltaAngle(azi - a.СТОЛ.азимут);
//    a.СТОЛ.err_визир := TMetrInclinMath.DeltaAngle(otk - a.СТОЛ.визир);
//    if a.СТОЛ.зенит > 180 then a.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(zen -(360 - a.СТОЛ.зенит))
//    else a.СТОЛ.err_зенит := TMetrInclinMath.DeltaAngle(zen - a.СТОЛ.зенит);
//  end;

// procedure TstAmpErr(step: Integer; a: Double; var e,ave: Double; var eStep: Integer; etalon: Double);
// begin
//   var ne := a-etalon;
//   ave := ave + Abs(ne);
//   if Abs(e)  < Abs(ne) then
//    begin
//     e := ne;
//     eStep := step;
//    end;
// end;
//
 var
  Input: TArray<TinclInput>;
  st: Variant;
  cnt: Integer;
//  eg,eh,g,h,
//  ei, ink: Double;
//  aveg,aveh,avei: Double;
//  steg,steh, stei: Integer;
begin
  Result := True;

//  st := XtoVar(alg.ChildNodes.FindNode('STEP'+Step.ToString));

//  if string(st.INFO).Contains('NotUse') then Exit;

  // находим эталоны
//  FindEtalon(st);

  if Step <> alg.ChildNodes.Count then Exit;

  // B = A*x линейная система уравнений по каждой оси

  SetLength(Input, alg.ChildNodes.Count);
  // заполним A,B
  cnt := 0;
  for var i := 0 to alg.ChildNodes.Count-1 do
   begin
    st := XtoVar(alg.ChildNodes[i]);
    if string(st.INFO).Contains('NotUse') or (string(st.EXECUTED) = 'false') then Continue;
    Input[cnt] := st;
    Inc(cnt);
   end;
   Setlength(Input,cnt);
   TpolyMath.Init(pmA,pmH, FNakl, Input);
   // решаем линейную систему уравнений  по каждой оси
//   TpolyMath.RunLS;
//   TpolyMath.ResultToXML(Trr, TpolyMath.Res.G, TpolyMath.Res.H);
   RecalcResultAndUpdateTree(false);
//   TpolyMath.findErr(alg, trr, SCALE_A,SCALE_H,RES_AMP, FNakl);
//   UpdateRes(trr);
//   eg := 0;
//   eh := 0;
//   ei := 0;
//   aveg := 0;
//   aveh := 0;
//   avei := 0;
//   for var i := 0 to alg.ChildNodes.Count-1 do
//   begin
//    st := XtoVar(alg.ChildNodes[i]);
//    if string(st.INFO).Contains('NotUse') or (string(st.EXECUTED) = 'false') then Continue;
//    azo(Trr, alg.ChildNodes[i],g,h,ink);
//    TstAmpErr(i,g,eg,aveg, steg, RES_AMP);
//    TstAmpErr(i,h,eh,aveh, steh, RES_AMP);
//    TstAmpErr(i,ink,ei,avei, stei, FNakl);
//   end;
//   aveg := aveg/alg.ChildNodes.Count;
//   aveh := aveh/alg.ChildNodes.Count;
//   avei := avei/alg.ChildNodes.Count;
//   eg := eg/RES_AMP*100;
//   eh := eh/RES_AMP*100;
//   aveg := aveg/RES_AMP*100;
//   aveh := aveh/RES_AMP*100;
//   AttestatLabel.Caption := Format('Accel: %d %1.2f%% av: %1.3f%%     Magnit: %d %1.2f%% av: %1.3f%%     Ink: %d %1.2f av: %1.3f',
//     [steg+1,eg,aveg, steh+1,eh,aveh,stei+1,ei,avei])
end;


{ TFormMetrInclinTPOnlyT }

class procedure TFormMetrInclinTPOnlyT.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormMetrInclinTPOnlyT.MetrolType: string;
begin
  Result := 'IT4poly'
end;

{ TFormMetrInclinUniT }

class procedure TFormMetrInclinUniT.DoCreateForm(Sender: IAction);
begin
  inherited;

end;

class function TFormMetrInclinUniT.MetrolAttrName: string;
begin
  Result := 'INKLGK5'
end;

class function TFormMetrInclinUniT.MetrolType: string;
begin
  Result := 'ITUniALL';
end;

initialization
//  RegisterClass(TFormMetrInclinTP);
  RegisterClass(TFormMetrInclinUniT);
//  RegisterClass(TFormMetrInclinTPOnlyT);
//  TRegister.AddType<TFormMetrInclinTP, IForm>.LiveTime(ltSingletonNamed);
//  TRegister.AddType<TFormMetrInclinTPOnlyT, IForm>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TFormMetrInclinUniT, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormMetrInclinUniT>;
//  GContainer.RemoveModel<TFormMetrInclinTP>;
//  GContainer.RemoveModel<TFormMetrInclinTPOnlyT>;
end.

//0.902665913105011
//0.93473082780838
//1.01189911365509
//1.13982844352722
//1.26766741275787
//-0.130773618817329
//-0.0275490470230579
//0.0573432072997093
//0.00693212868645787
//0.0184410288929939
//0.0175569280982018
//0.0168231017887592
//0.015779560431838
//0.0149461682885885
//0
//0
//0
//0
//0
//1.63935156866242E-30
//7700
//12000
//19.8196430206299
//31.3578758239746
//
//0.902665913105011 0.93473082780838 1.01189911365509 1.13982844352722 1.26766741275787 -0.130773618817329 -0.0275490470230579 0.0573432072997093 0.00693212868645787 0.0184410288929939 0.0175569280982018 0.0168231017887592
//0.015779560431838
//0.0149461682885885
//0
//0
//0
//0
//0
//0
//0
//0
//0
//0

