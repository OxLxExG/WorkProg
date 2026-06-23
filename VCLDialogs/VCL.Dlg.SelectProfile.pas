unit VCL.Dlg.SelectProfile;

interface

uses DockIForm, ExtendIntf, PluginAPI,
  Xml.XMLIntf, System.TypInfo, RootImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, VirtualTrees, Vcl.StdCtrls;

type

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    index: word;
    name: string;
  end;

  TDialogSelectProfile = class(TDialogIForm, IDialog, IDialog<IXMLNode, TProc<Integer>>)
    Tree: TVirtualStringTree;
    Panel: TPanel;
    Button: TButton;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ButtonClick(Sender: TObject);
  private
    { Private declarations }
    res : TProc<Integer>;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(node: IXMLNode; ares : TProc<Integer>): Boolean;
    class function ClassIcon: Integer; override;
  end;


implementation

{$R *.dfm}

{ TDialogSelectProfile }

function TDialogSelectProfile.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_MultiProfile);
end;

procedure TDialogSelectProfile.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
 var
  xd: PNodeExData;
begin
  xd := Tree.GetNodeData(Node);
  if Column = 0 then CellText := '0x' + xd.index.ToHexString
  else if Column = 1 then CellText := xd.name;
end;

procedure TDialogSelectProfile.ButtonClick(Sender: TObject);
 var
  xd: PNodeExData;
begin
  xd := Tree.GetNodeData(Tree.FocusedNode);
  res(xd.index);
  RegisterDialog.UnInitialize(GetInfo);
end;

class function TDialogSelectProfile.ClassIcon: Integer;
begin
  Result := 127;
end;

function TDialogSelectProfile.Execute(node: IXMLNode; ares : TProc<Integer>): Boolean;
 var
  xd: PNodeExData;
begin
  res := ares;
  Tree.NodeDataSize := Sizeof(TNodeExData);
  for var i := 0 to node.ChildNodes.Count-1 do
   begin
     var n := node.ChildNodes[i];
     if n.NodeName <> 'Метрология' then
      begin
       xd := Tree.GetNodeData(Tree.AddChild(nil));
       xd.index := n.Attributes['profile'];
       xd.name := n.NodeName;
      end;
   end;
    Tree.Selected[Tree.GetFirst] := True; // Выделяем узел
    Tree.FocusedNode :=Tree.GetFirst;    // Передаем фокус
  ISHow;
end;

initialization
  RegisterDialog.Add<TDialogSelectProfile, Dialog_MultiProfile>();
finalization
  RegisterDialog.Remove<TDialogSelectProfile>;

end.
