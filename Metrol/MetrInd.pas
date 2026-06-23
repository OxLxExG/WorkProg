unit MetrInd;

interface

uses  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm,
     LuaInclin.Math, XMLLua.Math, MetrInclin.Math2, RootImpl, JDtools, VerySimple.Lua.Lib, tools, XMLLua,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormInd = class(TFormMetrolog)
    PanelM: TPanel;
    lbInfo: TLabel;
    lbAlpha: TLabel;
    Tree: TVirtualStringTree;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    AtCnt: Integer;
    SummPh: array[0..7] of double;
    function SumToString(const fmt: string = ''): string;
//    class constructor Create;
//    class procedure ExportToBKS(const TrrFile: string; NewTrr: IXMLNode); overload; static;
  protected
   const
     NICON = 335;
    procedure Loaded; override;
    procedure DoStartAtt(AttNode: IXMLNode); override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function UserSummKadr(summ, KadrData: IXMLNode): Boolean; override;
    function UserShowCurrentSumm(show, summ: IXMLNode; AttN, AttCnt: Integer): Boolean; override;
    class function ClassIcon: Integer; override;
//    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
  public
    [StaticAction('Новая калибровка на воздухе', 'Метрология', NICON, '0:Метрология.Индукционник')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

var
  FormInd: TFormInd;

implementation

{$R *.dfm}

class function TFormInd.ClassIcon: Integer;
begin
  Result := NICON
end;

class procedure TFormInd.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormInd.DoStartAtt(AttNode: IXMLNode);
begin
  inherited;
  AtCnt := 0;
  for var i := 0 to 7 do SummPh[i] := 0;
end;

class function TFormInd.MetrolMame: string;
begin
  Result := 'Ind';
end;

class function TFormInd.MetrolType: string;
begin
  Result := 'TIndAir'
end;

function TFormInd.SumToString(const fmt: string): string;
 var
  s: array[0..7]of string;
begin
  for var i := 0 to 7 do
   begin
    var d: Double := (57290*SummPh[i] / AtCnt);
    if fmt = 'int' then s[i] := IntToStr(Round(d))
    else if fmt = '' then s[i] := d.ToString()
    else s[i] := Format(fmt,[d]);
   end;
  Result := string.Join(' ', s);
end;

procedure TFormInd.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
end;

procedure TFormInd.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormInd.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
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
    1: SetData('', 'PH1');
    2: SetData('', 'PH2');
    3: SetData('', 'Air_zz');
   end;
end;


function TFormInd.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
begin
  Result := True;
  if AtCnt > 0 then  trr.Attributes['Air_zz'] := SumToString('int');
end;

function TFormInd.UserShowCurrentSumm(show, summ: IXMLNode; AttN, AttCnt: Integer): Boolean;
begin
  show.Attributes['PH1'] := summ.Attributes['PH1'];
  show.Attributes['PH2'] := summ.Attributes['PH2'];
  show.Attributes['Air_zz'] := SumToString('%1.2f');
  Result := True;
end;

function TFormInd.UserSummKadr(summ, KadrData: IXMLNode): Boolean;
 var
  s1,s2: string;
begin
  var k := XToVar(KadrData);
  s1 := k.PH_RX_1.DEV.VALUE;
  s2 := k.PH_RX_1.DEV.VALUE;
  summ.Attributes['PH1'] := s1;
  summ.Attributes['PH2'] := s2;
  var as1 := s1.Split([' '], TStringSplitOptions.ExcludeEmpty);
  var as2 := s2.Split([' '], TStringSplitOptions.ExcludeEmpty);
  for var I := 0 to 7 do
   begin
    var f1: Double := StrToFloat(as1[i]);
    var f2: Double := StrToFloat(as2[i]);
    var df := f2-f1;
    while df > PI do df := df - 2*Pi;
    while df <= -PI do df := df + 2*Pi;
    SummPh[i] := SummPh[i] + df;
   end;
  Inc(AtCnt);
  summ.Attributes['Air_zz'] := SumToString('int');
  Result := True;
end;

initialization
  RegisterClass(TFormInd);
  TRegister.AddType<TFormInd, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInd>;
end.
