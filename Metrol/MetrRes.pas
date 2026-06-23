unit MetrRes;

interface

 {$M+}

uses
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, debug_except, DockIForm, MetrForm, Container, Actns, ExcelImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.ActiveX,
  Vcl.Menus,  RootImpl, StolBKIntf,  System.UITypes,  JDtools, VerySimple.Lua.Lib,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, JvExControls, JvInspector;

type
  TFormRes = class(TFormMetrolog)
    Tree: TVirtualStringTree;
    PanelM: TPanel;
    lbInfo: TLabel;
    lbAlpha: TLabel;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  protected
    procedure Loaded; override;
   const
    NICON = 194;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Новая калибровка резистивиметра', 'Метрология', NICON, '0:Метрология.R')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

implementation

{$R *.dfm}

uses  tools, XMLLua, XMLLua.Math;

class function TFormRes.MetrolMame: string;
begin
  Result := 'Res';
end;
class function TFormRes.MetrolType: string;
begin
  Result := 'TR1'
end;
class function TFormRes.ClassIcon: Integer;
begin
  Result := NICON
end;

class procedure TFormRes.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormRes.Loaded;
begin
  SetupStepTree(Tree);
  SetupEditor(procedure (XMNode: IXMLNode; Column: Integer; var allow: Boolean)
  begin
    allow := Column = 1;
  end,
  function (XMNode: IXMLNode; Column: Integer): string
  begin
    Result := XMNode.Attributes['INP_Y']
  end,
  procedure (XMNode: IXMLNode; Column: Integer; const text: string)
  begin
    XMNode.Attributes['INP_Y'] := Text.ToDouble;
  end);
  inherited;
  AttestatPanel.Align := alBottom;
end;

procedure TFormRes.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormRes.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
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
    1: SetData('', 'INP_Y');
    2: SetData('U.DEV', AT_VALUE, '%8.3f');
    3: SetData('I.DEV', AT_VALUE, '%8.3f');
    4: SetData('', 'Y', '%8.3f');
    5: SetData('', 'Ytrr', '%8.3f');
    6: SetData('', 'Err', '%8.1f');
    7: SetData('', 'Rtrr', '%8.3f');
    8: SetData('', 'k0', '%8.3f');
    9: SetData('', 'k1', '%8.3f');
    10: SetData('', 'k2', '%8.3f');
    11: SetData('', 'k3', '%8.3f');
    12: SetData('', 'k4', '%8.3f');
    13: SetData('', 'k5', '%8.3f');
    14: SetData('', 'R2', '%8.3f');
   end;
end;

initialization
  RegisterClass(TFormRes);
  TRegister.AddType<TFormRes, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormRes>;
end.
