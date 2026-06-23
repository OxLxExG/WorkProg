unit MetrBKZ3;

interface

uses  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm,
     LuaInclin.Math, XMLLua.Math, MetrInclin.Math2, RootImpl, JDtools, VerySimple.Lua.Lib, tools, XMLLua,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormBKZ3 = class(TFormMetrolog)
    PanelM: TPanel;
    lbInfo: TLabel;
    lbAlpha: TLabel;
    Tree: TVirtualStringTree;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
//    class constructor Create;
//    class procedure ExportToBKS(const TrrFile: string; NewTrr: IXMLNode); overload; static;
  protected
   const
     NICON = 196;
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
//    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
  public
    [StaticAction('Новая калибровка БКZ3', 'Метрология', NICON, '0:Метрология.ВК')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
//  published
//      class function ExportToBKS(L: lua_State): Integer; overload; cdecl; static;
  end;

var
  FormBKZ3: TFormBKZ3;

implementation

{$R *.dfm}

{ TFormBKS }

class function TFormBKZ3.ClassIcon: Integer;
begin
  Result := NICON
end;

//class constructor TFormBKZ3.Create;
//begin
//  TXMLLua.RegisterLuaMethods(TFormBKZ3);
//end;

class procedure TFormBKZ3.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormBKZ3.MetrolMame: string;
begin
  Result := 'БК';
end;

class function TFormBKZ3.MetrolType: string;
begin
  Result := 'TBKZ3nmk'
end;

procedure TFormBKZ3.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
end;

//class function TFormBKZ3.ExportToBKS(L: lua_State): Integer;
//begin
//  ExportToBKS(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
//  Result := 0;
//end;
//
//class procedure TFormBKZ3.ExportToBKS(const TrrFile: string; NewTrr: IXMLNode);
// var
//  ser, dat: string;
//  ss: TStrings;
//begin
//   ser := NewTrr.ParentNode.ParentNode.Attributes[AT_SERIAL];
//   dat := NewTrr.ChildNodes.FindNode(MetrolType).Attributes[AT_TIMEATT];
//   ss := TStringList.Create;
//    try
//     ExecXTree(NewTrr, function(n: IXMLNode): boolean
//        function GetPath(Node: IXMLNode): string;
//        begin
//          Result := Node.NodeName;
//          Node := Node.ParentNode;
//          repeat
//           if Node =  NewTrr then Exit;
//           Result := Node.NodeName +'.'+ Result;
//           Node := Node.ParentNode;
//          until not Assigned(Node);
//        end;
//     begin
//       Result := False;
//       if n.NodeName.StartsWith('TBKZ3') then Exit(True);
//       if n.HasAttribute('K') then
//        begin
//          ss.Add(Format('%13.10f    {%s.K/мA.ед.}',[Double(n.Attributes['K']), GetPath(n)]));
//        end;
//     end);
//     ss[0] := ss[0] + Format(' {БКZ3-%s Дата метрологии %s}',[ser, dat]);
//     ss.SaveToFile(TrrFile);
//   finally
//    ss.Free;
//   end;
//end;

procedure TFormBKZ3.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormBKZ3.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
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
    1: SetData('', 'R');
    2: SetData('', 'FOCUS');
    3: SetData(Format('focus%d.Ubk.DEV',[Integer(p.XMNode.Attributes['FOCUS'])]), AT_VALUE, '%.3f');
    4: SetData(Format('focus%d.Ifocus.DEV',[Integer(p.XMNode.Attributes['FOCUS'])]), AT_VALUE, '%.8f');
    5: SetData(Format('focus%d.Izond.DEV',[Integer(p.XMNode.Attributes['FOCUS'])]), AT_VALUE, '%.3f');
    6: SetData('', 'Kfocus', '%.3f');
    7: SetData('', 'Dfocus', '%.5f');
    8: SetData('', 'K2focus', '%.5f');
    9: SetData('', 'Rp', '%.10f');
    10: SetData('', 'R2', '%.4f');
   end;
end;


initialization
  RegisterClass(TFormBKZ3);
  TRegister.AddType<TFormBKZ3, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormBKZ3>;
end.
