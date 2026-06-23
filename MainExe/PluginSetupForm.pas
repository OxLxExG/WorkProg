unit PluginSetupForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Container,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, JvDockControlForm,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormPluginSetup = class(TForm)
    btClose: TButton;
    Tree: TVirtualStringTree;
    btSave: TButton;
    btUpdate: TButton;
    procedure btCloseClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btUpdateClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FIniPath: string;
  public
    class var This: TFormPluginSetup;
    class procedure Execute(const IniPath: string); static;
    class procedure LoadPlugins(const IniPath: string; AfteLoad: TProc = nil; LoadBans: Boolean = False); static;
  end;


implementation

{$R *.dfm}

uses PluginManager, PluginAPI, MainForm, debug_except, tools;

type
  PNodeXData = ^TNodeXData;
  TNodeXData = record
    PluginName: String;
//    ID: String;
    Version: String;
    FileName: String;
  end;

{ TFormPluginSetup }

class procedure TFormPluginSetup.Execute(const IniPath: string);
begin
  if not Assigned(This) then  This := TFormPluginSetup.Create(Application.MainForm);
  This.FIniPath := IniPath;
  This.Show();
end;

procedure TFormPluginSetup.FormShow(Sender: TObject);
 var
   i: Integer;
  pv: PVirtualNode;
  xd: PNodeXData;
  p: IPlugin;
begin
  Tree.BeginUpdate;
  Tree.Clear;
  Tree.NodeDataSize := SizeOf(TNodeXData);
  try
   for p in GContainer.Enum<IPlugin>(True) do// .CreateAndExecService<IPluginNotify>(procedure(p: IPluginNotify)
//   GContainer.ExecExistsService<IPlugin>(procedure(p: IPlugin)
    begin
     pv := Tree.AddChild(nil);
     pv.CheckType := ctCheckBox;
     pv.CheckState := csCheckedNormal;
     xd := Tree.GetNodeData(pv);
     xd.PluginName := p.Name;
     xd.Version := Format('%d.%d.%d.%d', [p.Version.Major, p.Version.Minor, p.Version.Release, p.Version.Build]);
     xd.FileName := Plugins.GetItemFile(p as IInterface);
    end;
   for i := Plugins.BanCount-1 downto 0 do
    begin
     if not FileExists(Plugins.Bans[i]) then
      begin
       Plugins.Unban(Plugins.Bans[i]);
       Continue;
      end;
     pv := Tree.AddChild(nil);
     pv.CheckType := ctCheckBox;
     xd := Tree.GetNodeData(pv);
     xd.PluginName := 'нет данных';
     xd.Version := 'нет данных';
     xd.FileName := Plugins.Bans[i];
    end;
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormPluginSetup.btCloseClick(Sender: TObject);
begin
  Close;
  This := nil;
end;

class procedure TFormPluginSetup.LoadPlugins(const IniPath: string; AfteLoad: TProc; LoadBans: Boolean);
begin
  if LoadBans then Plugins.LoadSettings(IniPath);
  BeginDockLoading;
  try
   try
    FormMain.RegisterProviders;
    try
     TDebug.Log('******************** LoadPlugins ***************************');
     Plugins.LoadPlugins(ExtractFilePath(ParamStr(0)), SPluginExt);
    finally
     if Assigned(AfteLoad) then AfteLoad();
    end;
   finally
//    Plugins.DoLoaded;
   end;
   FormMain.LoadNotify;
  finally
   EndDockLoading;
  end;
end;

procedure TFormPluginSetup.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeXData;
begin
  p := Sender.GetNodeData(Node);
  case Column of
   0: CellText := p.PluginName;
   1: CellText := p.Version;
   3: CellText := p.FileName;
  end;
end;

procedure TFormPluginSetup.TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node.CheckType :=  ctCheckBox;
end;

procedure TFormPluginSetup.btSaveClick(Sender: TObject);
 var
  p: PNodeXData;
  pv: PVirtualNode;
begin
  pv := Tree.GetFirst();
  while Assigned(pv) do
   begin
    p := Tree.GetNodeData(pv);
    if pv.CheckState = csCheckedNormal then Plugins.Unban(p.FileName)
    else Plugins.Ban(p.FileName);
    pv := Tree.GetNext(pv);
   end;
  Plugins.SaveSettings(FIniPath);
end;

procedure TFormPluginSetup.btUpdateClick(Sender: TObject);
  procedure ClearDinObj;
   var
    m: IManager;
  begin
    if Supports(Plugins, IManager, m) then m.ClearItems;
  end;
begin
   try
    ClearDinObj; // !!! Важно, ссылок на плугины быить не должно
    Plugins.UnloadAll;
    TFormPluginSetup.LoadPlugins(FIniPath);
   finally
    FormShow(Sender);
   end;
end;

end.
