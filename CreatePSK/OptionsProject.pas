unit OptionsProject;

interface

uses  RootIntf, PluginAPI, ExtendIntf, DockIForm, DeviceIntf, debug_except, Parser, VirtualTrees, Container, Actns,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf, VirtualTrees.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
    IsCategiry: Boolean;
//    IsRoot: Boolean;
  end;

  TFormProjectOptions = class(TDockIForm)
    Tree: TVirtualStringTree;
    ppM: TPopupActionBar;
    NCategery: TMenuItem;
    NNew: TMenuItem;
    NDelete: TMenuItem;
    NEdit: TMenuItem;
    N1: TMenuItem;
    procedure NCategeryClick(Sender: TObject);
    procedure NNewClick(Sender: TObject);
    procedure NDeleteClick(Sender: TObject);
    procedure NEditClick(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FOptions: IXMLNode;
    FFileName: string;
    NSave: TMenuItem;
    procedure NSaveClick(Sender: TObject);
    procedure NNewFileClick(Sender: TObject);
    procedure ClearTree;
    procedure UpdateTree;
    procedure ReLoad;
  protected
//    class function ClassIcon: Integer; override;
    procedure Loaded; override;
  public
    [StaticAction('Настройки опций', 'Отладочные', 45, '0:Показать.Отладочные:0')]
    class procedure DoCreateForm(Sender: IAction); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses tools;


//class function TFormProjectOptions.ClassIcon: Integer;
//begin
//  Result := 45;
//end;

class procedure TFormProjectOptions.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalProjectOptionsForm');
end;

procedure TFormProjectOptions.Loaded;
 var
  GDoc: IXMLDocument;
begin
  inherited;
  FFileName := ExtractFilePath(ParamStr(0))+'Devices\Options.xml';
  AddToNCMenu('-');
  AddToNCMenu('Выбрать файл...', NNewFileClick);
  NSave := AddToNCMenu('Сохранить', NSaveClick);
  NSave.Enabled := False;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  ReLoad;
end;

destructor TFormProjectOptions.Destroy;
begin
  ClearTree;
  inherited;
end;

procedure TFormProjectOptions.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

procedure TFormProjectOptions.UpdateTree;
 var
  ct,t: IXMLNode;
  rt: PVirtualNode;
  edr, ed: PNodeExData;
begin
  Tree.BeginUpdate;
  try
   ClearTree;
   for ct in XEnum(FOptions) do
    begin
     rt := Tree.AddChild(nil);
     Include(rt.States, vsExpanded);
     edr := Tree.GetNodeData(rt);
     edr.XMNode := ct;
     edr.IsCategiry := True;
     for t in XEnum(ct) do
      begin
       ed := Tree.GetNodeData(Tree.AddChild(rt));
       ed.XMNode := t;
       ed.IsCategiry := False;
      end;
    end;
   Tree.SortTree(0, sdAscending);
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormProjectOptions.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  CellText := '';
  if not Assigned(p.XMNode) then Exit;
  if p.IsCategiry then
   case Column of
    0: CellText := p.XMNode.NodeName;
    1: CellText := p.XMNode.Attributes['Категория'];
   end
  else
   case Column of
    0: CellText := p.XMNode.NodeName;
    1: CellText := p.XMNode.Attributes['Описание'];
    2: CellText := p.XMNode.Attributes['Единицы'];
    3: if p.XMNode.HasAttribute('Hidden') then CellText := p.XMNode.Attributes['Hidden'];
    4: if p.XMNode.HasAttribute('ReadOnly') then CellText := p.XMNode.Attributes['ReadOnly'];
    5: if p.XMNode.HasAttribute('DataType') then CellText := p.XMNode.Attributes['DataType'];
    6: CellText := p.XMNode.Attributes['Значение'];
   end;
end;

procedure TFormProjectOptions.NSaveClick(Sender: TObject);
begin
  FOptions.OwnerDocument.SaveToFile(FFileName);
  NSave.Enabled := False;
end;

procedure TFormProjectOptions.ReLoad;
 var
  GDoc: IXMLDocument;
begin
  GDoc := NewXDocument();
  GDoc.LoadFromFile(FFileName);
  FOptions := GDoc.DocumentElement;
  UpdateTree;
end;

procedure TFormProjectOptions.NCategeryClick(Sender: TObject);
 var
  astr: array of string;
  n: IXMLNode;
begin
  SetLength(astr, 2);
  if InputQuery('Новая категория', ['Категория', 'Описание'], astr) then
   begin
    n := FOptions.AddChild(astr[0]);
    n.Attributes['Категория'] := Trim(astr[1]);
    NSave.Enabled := True;
    UpdateTree;
   end;
end;

procedure TFormProjectOptions.NDeleteClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    if ex.IsCategiry then Exit;
    if MessageDlg(Format('Удалить %s',[ex.XMNode.NodeName]), TMsgDlgType.mtWarning, [mbOK, mbCancel], 0) = mrOk then
     begin
      ex.XMNode.ParentNode.ChildNodes.Remove(ex.XMNode);
      NSave.Enabled := True;
      UpdateTree;
     end;
    Break;
   end;
end;

procedure TFormProjectOptions.NEditClick(Sender: TObject);
 var
  astr: array of string;
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    if ex.IsCategiry then Exit;
    SetLength(astr, 6);
    astr[0] := ex.XMNode.Attributes['Описание'];
    astr[1] := ex.XMNode.Attributes['Единицы'];
    if ex.XMNode.HasAttribute('Hidden') then astr[2] := ex.XMNode.Attributes['Hidden'];
    if ex.XMNode.HasAttribute('ReadOnly') then astr[3] := ex.XMNode.Attributes['ReadOnly'];
    if ex.XMNode.HasAttribute('DataType') then astr[4] := ex.XMNode.Attributes['DataType'];
    astr[5] := ex.XMNode.Attributes['Значение'];
    if InputQuery(Format('Изменить %s',[ex.XMNode.NodeName]), ['Описание', 'Единицы', 'Скрытый', 'Чтение', 'Тип', 'Значение'], astr) then
     begin
      ex.XMNode.Attributes['Описание'] := Trim(astr[0]);
      ex.XMNode.Attributes['Единицы'] := Trim(astr[1]);
      ex.XMNode.Attributes['Hidden'] := Trim(astr[2]);
      ex.XMNode.Attributes['ReadOnly'] := Trim(astr[3]);
      ex.XMNode.Attributes['DataType'] := Trim(astr[4]);
      ex.XMNode.Attributes['Значение'] := Trim(astr[5]);
      NSave.Enabled := True;
      UpdateTree;
     end;
    Break;
   end;
end;

procedure TFormProjectOptions.NNewClick(Sender: TObject);
 var
  astr: array of string;
  pv: PVirtualNode;
  ex: PNodeExData;
  n: IXMLNode;
begin
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    if not ex.IsCategiry then Exit;
    SetLength(astr, 7);
    if InputQuery('Новый параметр', ['Имя', 'Описание', 'Единицы', 'Скрытый', 'Чтение', 'Тип', 'Значение'], astr) then
     begin
      n := ex.XMNode.AddChild(astr[0]);
      n.Attributes['Описание'] := Trim(astr[1]);
      n.Attributes['Единицы'] := Trim(astr[2]);
      n.Attributes['Hidden'] := Trim(astr[3]);
      n.Attributes['ReadOnly'] := Trim(astr[4]);
      n.Attributes['DataType'] := Trim(astr[5]);
      n.Attributes['Значение'] := Trim(astr[6]);
      NSave.Enabled := True;
      UpdateTree;
     end;
    Break;
   end;
end;

procedure TFormProjectOptions.NNewFileClick(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
   try
    InitialDir := ExtractFilePath(ParamStr(0)) + 'Devices';
    Options := Options + [ofPathMustExist, ofFileMustExist];
    DefaultExt := 'xml';
    Filter := 'Файл опций (*.xml)|*.xml';
    if Execute(Handle) then
     begin
      FFileName := FileName;
      ReLoad;
     end;
   finally
    Free;
   end;
end;

initialization
  RegisterClass(TFormProjectOptions);
  TRegister.AddType<TFormProjectOptions, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormProjectOptions>;
end.
