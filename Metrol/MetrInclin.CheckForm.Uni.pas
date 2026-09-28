unit MetrInclin.CheckForm.Uni;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, AutoMetr.Inclin, RootImpl,
     LuaInclin.Math, XMLLua.Math, UakiIntf, LuaInclin.Temp.Poly, MetrInclin.Temp.Stat,
     VirtualTrees, Xml.XMLIntf, Vcl.Menus, JvInspector, Tools, MetrInclin.VerificationReport,
     Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
     Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
     VirtualTrees.AncestorVCL;

type

  TFormCheckUni = class(TFormMetrolog, IAutomatMetrology)
    Tree: TVirtualStringTree;
    pc: TPageControl;
    tshTest: TTabSheet;
    tshReport: TTabSheet;
    mmo: TMemo;
    sb: TStatusBar;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FAutomatMetrology: TinclAuto;
    FStolVizir: Double;
    FStolAzimut: Double;
    FStolZenit: Double;
//    Fhck: Double;
//    FhckCnt: Integer;
    FColumns: TColumns;
    Verification: TGkiVerificationResult;
    Function GetEtalonMagnit: Double;
    Function GetEtalonAccel: Double;
    Function GetEtalonInclin: Double;
    { Private declarations }
  protected
    procedure InitializeNewForm; override;
    procedure Loaded; override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    procedure DoStartAtt(AttNode: IXMLNode); override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoOnExecuteExport(FilrerNo: Integer; const ExportFile: string; Data: IXMLNode); override;
  public
   const
    NICON = 86;
    destructor Destroy; override;
    property StolVizir: Double read FStolVizir;
    property StolZenit: Double read FStolZenit;
    property StolAzimut: Double read FStolAzimut;

    [StaticAction('Новая поверка UNI', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    property AutomatMetrology: TinclAuto read FAutomatMetrology implements IAutomatMetrology;
  end;


  TErrEtal = class(TColumn)
     Etalon: TFunc<Double>;
     PathDev: string;
     Fmt: string;
     function Get(st: IXMLNode): string; override;
     constructor Create(const name: string;
                        Etalon: TFunc<Double>;
                        const PathDev: string;
                        const Fmt: string='%7.1f';
                        width: Integer = 40);
  end;

  TErrStol = class(TColumn)
     AttrStol: string;
     PathDev: string;
     Fmt: string;
    function Get(st: IXMLNode): string; override;
     constructor Create(const name: string;
                       const AttrStol: string;
                       const PathDev: string;
                       const Fmt: string='%7.1f';
                       width: Integer = 40);
  end;
var
  FormCheckUni: TFormCheckUni;

implementation

{$R *.dfm}

{ TFormCheckUni }




destructor TFormCheckUni.Destroy;
begin
  FAutomatMetrology.Free;
  FColumns.Free;
  inherited;
end;

class procedure TFormCheckUni.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormCheckUni.DoOnExecuteExport(FilrerNo: Integer; const ExportFile: string; Data: IXMLNode);
 var
  inf: TinclTestInfo;
begin
  var V := XtoVar(Data.ChildNodes.FindNode('PoverkaUni'));

 // inherited;
//'<Inclin><PoverkaUni
// DevName="Инклинометр"
// Maker="ООО НПФ &quot;АМК Горизонт&quot;"
// UsedStol="УАК-СИ"
// Category="Рабочее СИ, ООО НПФ &quot;АМК Горизонт&quot;"
// Room="Производственное помещение ОМ" AttCount="5" IsMedian="0"
// MagNaklon="18.8"
// Metrolog=""
// TIME_ATT="0"
// NextDate="0"
end;

procedure TFormCheckUni.DoStartAtt(AttNode: IXMLNode);
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

procedure TFormCheckUni.DoStopAtt(AttNode: IXMLNode);
 var
  v: Variant;
begin
  v := XToVar(AttNode);
  if FAutomatMetrology.UakiExists then
   begin
    v.СТОЛ.азимут := Double(FAutomatMetrology.uaki.Azi.CurrentAngle);
    v.СТОЛ.зенит := Double(FAutomatMetrology.uaki.Zen.CurrentAngle);
    v.СТОЛ.визир := Double(FAutomatMetrology.uaki.Viz.CurrentAngle);
//     if FhckCnt > 0 then
//      begin
//        v.СТОЛ.амплит_magnit := Fhck/FhckCnt;
//        Fhck := 0;
//        FhckCnt := 0;
//      end
//     else
     v.СТОЛ.амплит_magnit := 1000;
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

function TFormCheckUni.GetEtalonAccel: Double;
begin
   Result := 10000;
end;

function TFormCheckUni.GetEtalonInclin: Double;
begin
   Result := GetMetr([MetrolType], FileData).Attributes['MagNaklon']
end;

function TFormCheckUni.GetEtalonMagnit: Double;
begin
   Result := 10000;
end;

procedure TFormCheckUni.InitializeNewForm;
begin
  inherited;
  NTrrApply.Visible := false;
  FlagIgnoreEtalon := True;
end;

procedure TFormCheckUni.Loaded;
begin
  SetupStepTree(Tree);

    FColumns := TColumns.Create([
     TColumnXML.Create('№','','STEP','',50),
     TColumnXML.Create('T','T.DEV'),
     TColumnXML.Create( 'sZu','СТОЛ','зенит','%7.2f'),
     TColumnXML.Create( 'Zu'  , 'зенит.DEV'),
     TErrStol.Create( 'eZU' , 'зенит','зенит'),
     TColumnXML.Create('sAz','СТОЛ','азимут'),
     TColumnXML.Create( 'Az'  , 'азимут.DEV'),
     TErrStol.Create( 'eAz' , 'азимут', 'азимут'),
     TColumnXML.Create( 'Vis'  , 'отклонитель.DEV'),
     TColumnXML.Create( 'H','амплит_magnit.DEV'),
     TErrEtal.Create( 'eH',GetEtalonMagnit,'амплит_magnit'),
     TColumnXML.Create( 'G','амплит_accel.DEV'),
     TErrEtal.Create( 'eG',GetEtalonAccel, 'амплит_accel'),
     TColumnXML.Create( 'I', 'маг_наклон.DEV'),
     TErrEtal.Create( 'eI',GetEtalonInclin, 'маг_наклон')]);
  if Tree.Header.Columns.Count = 0 then
   begin
     FColumns.SetTreeColumns(Tree);
   end;

  inherited;
  FAutomatMetrology := TinclAuto.Create(Self, AutoReport);
  AttestatPanel.Align := alBottom;
end;

class function TFormCheckUni.MetrolMame: string;
begin
  Result := 'Inclin'
end;

class function TFormCheckUni.MetrolType: string;
begin
  Result := 'PoverkaUni'
end;

procedure TFormCheckUni.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  sb.SimpleText := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
end;

procedure TFormCheckUni.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  CellText := '';
  var p: PNodeExData := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  CellText := FColumns.Get(Column, p.XMNode);
end;

function TFormCheckUni.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 var
  InclTests: TArray<TinclTest>;
  st: Variant;
  cnt: Integer;
begin
  Result := true;
  if Step <> alg.ChildNodes.Count then Exit;
  SetLength(InclTests, alg.ChildNodes.Count);
  cnt := 0;
  for var i := 0 to alg.ChildNodes.Count-1 do
   begin
    st := XtoVar(alg.ChildNodes[i]);
    ///
//    st.СТОЛ.зенит := st.TASK.Zenit_Stol;
//    st.СТОЛ.азимут := st.TASK.Azimut_Stol;
//    st.СТОЛ.визир := st.TASK.Vizir_Stol;
    ///
    if string(st.INFO).Contains('NotUse') or (string(st.EXECUTED) = 'false') then Continue;
    InclTests[cnt] := st;
    Inc(cnt);
   end;
  Setlength(InclTests,cnt);
   Verification := TGkiVerificationReport.Build(
    InclTests,
    GetEtalonInclin,
    TGkiVerificationAmplitude.Default,
    TGkiVerificationLimits.Default,
    mmo.Lines);
end;

{ TErrEtal }


{ TErrEtal }

constructor TErrEtal.Create(const name: string; Etalon: TFunc<Double>; const PathDev, Fmt: string; width: Integer);
begin
  inherited Create(name,width);
  Self.Etalon := Etalon;
  Self.PathDev := PathDev;
  Self.Fmt := Fmt;
end;

function TErrEtal.Get(st: IXMLNode): string;
 var
  dev: Double;
  V: IXMLNode;
begin
  Result := name;
  if TryGetX(st, PathDev+'.DEV', V, 'VALUE') then
   begin
    dev := V.NodeValue;
    Result := Format(Fmt, [Etalon() - Dev]);
   end;
end;

{ TErrStol }

constructor TErrStol.Create(const name, AttrStol, PathDev, Fmt: string; width: Integer);
begin
  inherited Create(name,width);
  Self.AttrStol := AttrStol;
  Self.PathDev := PathDev;
  Self.Fmt := Fmt;
end;

function TErrStol.Get(st: IXMLNode): string;
 var
  Angle: Double;
  V: IXMLNode;
begin
  Result := name;
  var Etalon := Double(st.ChildNodes['СТОЛ'].Attributes[AttrStol]);
  if TryGetX(st, PathDev+'.DEV', V, 'VALUE') then
   begin
    Angle := V.NodeValue;
    Angle := DegNormalize(Etalon - Angle);
    if Angle > 180  then Angle := Angle - 360;
    Result := Format(Fmt, [Angle]);
   end;
end;

initialization
  RegisterClass(TFormCheckUni);
  TRegister.AddType<TFormCheckUni, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormCheckUni>;
end.
