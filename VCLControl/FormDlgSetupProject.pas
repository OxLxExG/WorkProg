unit FormDlgSetupProject;

interface

uses RootImpl, RootIntf, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, TypInfo, Xml.XMLIntf, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, JvExControls, JvInspector, JvComponentBase, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnPopup;

type
  EFormSetupProject = class(EBaseException);
  TFormSetupProject = class(TDialogIForm, IDialog, IDialog<Pointer>)
    btExit: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Insp: TJvInspector;
    InspZ: TJvInspector;
    ppM: TPopupActionBar;
    NReadOnly: TMenuItem;
    Painter: TJvInspectorDotNETPainter;
    PainterZ: TJvInspectorDotNETPainter;
    procedure UpdateGlu(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
  public
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: Pointer): Boolean;
  end;

var
  FormSetupProject: TFormSetupProject;


implementation

{$R *.dfm}

uses tools, DlgSetupDate;


type
 TCategory = class(TJvInspectorCustomCategoryItem)
 private
   DBCateg: string;
 end;

{$REGION 'TData'}

 TData = class(TJvCustomInspectorData)
 private
   FData: IXMLNode;
   DBName: string;
 protected
   procedure InnerAsString(const Value: string); virtual;
   function GetAsFloat: Extended; override;
   function GetAsInt64: Int64; override;
   function GetAsOrdinal: Int64; override;
   function GetAsString: string; override;
   function GetAsVariant: Variant; override;
   procedure SetAsFloat(const Value: Extended); override;
   procedure SetAsInt64(const Value: Int64); override;
   procedure SetAsOrdinal(const Value: Int64); override;
   procedure SetAsString(const Value: string); override;
   procedure SetAsVariant(const Value: Variant); override;
  public
   function HasValue: Boolean; override;
   function IsAssigned: Boolean; override;
   function IsInitialized: Boolean; override;
   class function New(const AParent: TJvCustomInspectorItem; opt: IXMLNode): TJvCustomInspectorItem; reintroduce; overload;
 end;

 TDataDev = class(TData)
 protected
   Fid: Integer;
   procedure InnerAsString(const Value: string); override;
  public
   class function New(const AParent: TJvCustomInspectorItem; Data: Variant): TJvCustomInspectorItem; reintroduce; overload;
 end;

 TDataZ = class(TDataDev)
 protected
   FNode: IXMLNode;
   procedure InnerAsString(const Value: string); override;
  public
   class function New(const AParent: TJvCustomInspectorItem; Node: IXMLNode; Id: Integer; ReadOnly: Boolean): TJvCustomInspectorItem; reintroduce; overload;
 end;


function IsTrue(const atr: string; h: IXMLNode): boolean;
 var
  s: string;
begin
  Result := False;
  if h.HasAttribute(atr) then
   begin
     s := h.Attributes[atr];
     Result := sameText(S, 'True') or SameText(s, '1');
   end;
end;


{ TData }

class function TData.New(const AParent: TJvCustomInspectorItem; opt: IXMLNode): TJvCustomInspectorItem;
 var
  Dat: TData;
  dn: string;
  tip: Pointer;
  intTip: Integer;
begin
//   v.Attributes['Описание'] := Description;
//   v.Attributes['Единицы'] := Units;
//   v.Attributes['Hidden'] := Hidden;
//   v.Attributes['ReadOnly'] := ReadOnly;
//   v.Attributes['DataType'] := DataType;


  if opt.HasAttribute('Единицы') and (opt.Attributes['Единицы'] <> '') then
     dn := Format('%s [%s]', [opt.Attributes['Описание'], opt.Attributes['Единицы']])
  else dn := opt.Attributes['Описание'];

  if opt.HasAttribute('DataType') and (opt.Attributes['DataType'] <> '') then
     intTip := Integer(opt.Attributes['DataType'])
  else intTip := 0;

  case intTip of
   PRG_TIP_INT      : tip := System.TypeInfo(Integer);
   PRG_TIP_REAL     : tip := System.TypeInfo(Double);
   PRG_TIP_DATE_TIME: tip := System.TypeInfo(TDateTime);
   PRG_TIP_DATE     : tip := System.TypeInfo(TDate);
   PRG_TIP_TIME     : tip := System.TypeInfo(TTime);
   PRG_TIP_BOOL     : tip := System.TypeInfo(Boolean);
   else               tip := System.TypeInfo(Variant);
  end;

  Dat := CreatePrim(dn, tip);
  Dat.DBName := opt.NodeName;
  Dat.FData := opt;
  Dat := TData(DataRegister.Add(Dat));

  if Dat <> nil then
   begin
    Result := Dat.NewItem(AParent);
    Result.ReadOnly := IsTrue('ReadOnly', opt);
   end
  else Result := nil;
end;

procedure TData.InnerAsString(const Value: string);
begin
  if  Assigned(FData) and not SameText(FData.Attributes['Значение'], Value) then
   begin
    (GlobalCore as IProjectOptions).Option[DBName] := Value;
   end;
end;

function TData.IsAssigned: Boolean;
begin
  Result := True;
end;
function TData.IsInitialized: Boolean;
begin
  Result := True
end;
function TData.HasValue: Boolean;
begin
  Result := True;
end;
function TData.GetAsFloat: Extended;
begin
  try
   Result := Extended(FData.Attributes['Значение']);
  except
   Result := 0;
  end;
end;
function TData.GetAsInt64: Int64;
begin
  try
   Result := Int64(FData.Attributes['Значение']);
  except
   Result := 0;
  end;
end;
function TData.GetAsOrdinal: Int64;
begin
  try
   Result := Int64(FData.Attributes['Значение']);
  except
   Result := 0;
  end;
end;
function TData.GetAsString: string;
begin
  Result := FData.Attributes['Значение'];
end;
function TData.GetAsVariant: Variant;
begin
  Result := FData.Attributes['Значение'];
end;
procedure TData.SetAsString(const Value: string);
begin
  InnerAsString(Value)
end;
procedure TData.SetAsFloat(const Value: Extended);
begin
  InnerAsString(FloatToStr(Value));
end;
procedure TData.SetAsInt64(const Value: Int64);
begin
  InnerAsString(IntToStr(Value));
end;
procedure TData.SetAsOrdinal(const Value: Int64);
begin
  InnerAsString(IntToStr(Value));
end;
procedure TData.SetAsVariant(const Value: Variant);
begin
  InnerAsString(VarToStr(Value));
end;

{ TDataDev }

procedure TDataDev.InnerAsString(const Value: string);
begin
  if  Assigned(Fdata) and (FData.Attributes['Значение'] <> Value) then
   begin
    FData.Attributes['Значение'] := Value;
{    ConnectionsPool.Query.Acquire;
    try
     ConnectionsPool.Query.ExecSQL('UPDATE Device SET Znd = :P1 WHERE id = :P2', [Value, Fid]);
    finally
     ConnectionsPool.Query.Release;
    end;}
   end;
end;

class function TDataDev.New(const AParent: TJvCustomInspectorItem; Data: Variant): TJvCustomInspectorItem;
 var
  Dat: TDataDev;
begin
  Dat := CreatePrim(Data.Имя, System.TypeInfo(Double));
  Dat.Fid := Data.id;
  Dat.FData.Attributes['Значение'] := Double(Data.Znd);
  Dat := TDataDev(DataRegister.Add(Dat));
  if Dat <> nil then
   begin
    Result := Dat.NewItem(AParent);
    Result.Expanded := True;
   end
  else Result := nil;

end;

{ TDataZ }

procedure TDataZ.InnerAsString(const Value: string);
begin
  if  Assigned(Fdata) and (FData.Attributes['Значение'] <> Value) then
   begin
    FData.Attributes['Значение'] := Value;
    FNode.Attributes[AT_ZND] := FData.Attributes['Значение'];
{    ConnectionsPool.Query.Acquire;
    try
     ConnectionsPool.Query.ExecSQL('UPDATE Modul SET MetaData = :P1 WHERE id = :P2', [FNode.OwnerDocument.XML.Text, Fid]);
    finally
     ConnectionsPool.Query.Release;
    end;}
   end;
end;

class function TDataZ.New(const AParent: TJvCustomInspectorItem; Node: IXMLNode; Id: Integer; ReadOnly: Boolean): TJvCustomInspectorItem;
 var
  Dat: TDataZ;
begin
  if Node.HasAttribute(AT_ZND) then
   begin
    Dat := CreatePrim(Node.NodeName, System.TypeInfo(Double));
    Dat.FData.Attributes['Значение'] := Double(Node.Attributes[AT_ZND]);
   end
//  else if not ReadOnly then  Dat := CreatePrim(Node.NodeName, System.TypeInfo(Double))
  else Dat := CreatePrim(Node.NodeName, System.TypeInfo(string));
  Dat.FNode := Node;
  Dat.Fid := Id;
  Dat := TDataZ(DataRegister.Add(Dat));
  if Dat <> nil then
   begin
    Result := Dat.NewItem(AParent);
    Result.ReadOnly := ReadOnly;
   end
  else Result := nil;
end;
{$ENDREGION}

{ TFormSetupProject }

procedure TFormSetupProject.UpdateGlu(Sender: TObject);
 var
  v: Variant;
  i: Integer;
  doc: IXMLDocument;
  procedure rec(const AParent: TJvCustomInspectorItem; r: IXMLNode; rdonly: Boolean);
   var
    n: IXMLNode;
    cii: TJvCustomInspectorItem;
  begin
    if (r.NodeName = T_MTR) or (r.NodeName = T_WRK) then Exit
    else if r.NodeName = T_RAM then cii := AParent
    else cii := TDataZ.New(AParent, r, v.id, rdonly);
    cii.Expanded := not rdonly;
    for n in XEnum(r) do rec(cii, n, NReadOnly.Checked)
  end;
begin
  InspZ.Clear;
{ ConnectionsPool.Query.Acquire;
  try
   ConnectionsPool.Query.Open('SELECT * FROM Device');
   for v in ConnectionsPool.Query do TDataDev.New(InspZ.Root, v);
   ConnectionsPool.Query.Close;
  for I := 0 to InspZ.Root.Count-1 do
   begin
    ConnectionsPool.Query.Open('SELECT * FROM Modul WHERE fk ='+ TDataDev(InspZ.Root.Items[i].Data).Fid.ToString);
    try
     for v in ConnectionsPool.Query do if not VarIsNull(v.MetaData) and (v.MetaData <> '') then
      begin
       doc := NewXDocument();
       doc.LoadFromXML(v.MetaData);
       rec(InspZ.Root.Items[i], doc.DocumentElement, NReadOnly.Checked);
      end;
    finally
     ConnectionsPool.Query.Close;
    end;
   end;
  finally
   ConnectionsPool.Query.Release;
  end;}
end;

procedure TFormSetupProject.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_SetupProject>;
end;

function TFormSetupProject.Execute(InputData: Pointer): Boolean;
 var
  cat, opt: IXMLNode;
  ii: TCategory;
begin
  Result := True;

  if CurrentThemeIsDark then
   begin
    Painter.BackgroundColor := clThBkg;
    Painter.NameFont.Color := clThWindowTextNormal;
    Painter.ValueFont.Color := clSkyBlue;
    Painter.CategoryColor := clThButtonNormal;
    Painter.CategoryFont.Color := clThWindowTextNormal;
    Painter.DividerColor := clThBorder;
    Painter.GridColor1 := clThBorder;
    Painter.GridColor2 := clThBorder;
    Painterz.BackgroundColor := clThBkg;
    Painterz.NameFont.Color := clThWindowTextNormal;
    Painterz.ValueFont.Color := clSkyBlue;
    Painterz.CategoryColor := clThButtonNormal;
    Painterz.CategoryFont.Color := clThWindowTextNormal;
    Painterz.DividerColor := clThBorder;
    Painterz.GridColor1 := clThBorder;
    Painterz.GridColor2 := clThBorder;
   end;

  // Свойства проекта
  Insp.Clear;
    for cat in XEnum((GContainer as IProjectOptions).GetOptoins) do
     begin
      ii := nil;
      for opt in XEnum(cat) do
        if not IsTrue('Hidden', opt) then
         begin
          if not Assigned(ii) then
           begin
            ii := TCategory.Create(Insp.Root, nil);
            ii.SortKind := iskNone;
            ii.DBCateg := cat.NodeName;
            ii.DisplayName := cat.Attributes['Категория'];
            ii.Expanded := True;
           end;
          TData.New(ii, opt);
         end;
     end;
  // Cмещение глубины
  UpdateGlu(Self);
  IShow;
end;

function TFormSetupProject.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_SetupProject);
end;

initialization
  RegisterDialog.Add<TFormSetupProject, Dialog_SetupProject>;
finalization
  RegisterDialog.Remove<TFormSetupProject>;
end.
