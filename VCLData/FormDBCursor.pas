unit FormDBCursor;

//{$DEFINE USE_EH}

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Xml.XMLIntf,Container,
 // DataDBForm,
{$IFDEF USE_EH}
  DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh, GridsEh,
  DBAxisGridsEh, DBGridEh,
{$ELSE}
  Vcl.Grids, Vcl.DBGrids,// DBGrid,
{$ENDIF}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Data.DB, Vcl.StdCtrls;



type

{$IFDEF USE_EH}
  TInternalDBGrid=class(TDBGridEh);
  TColumn=TColumnEh;
{$ELSE}
  TInternalDBGrid=class(TDBGrid);
 // TColumn=TIColumn;
{$ENDIF}

  ///	<remarks>
  ///	  абстрактный класс таблицы данных
  ///	</remarks>
  TFormCursor = class(TFormDataDB)
  private
    FCursorY: Double;
    FMenu: TPopupMenu;
    FDBGrid: TInternalDBGrid;
    FColWidth: string;
    FColunmsIndex: TStringList;
    FRecNo: integer;
    FRecRow: integer;
    FGotoFirst: Boolean;

    function GetColWidth: string;
    procedure SetDBColunms;
    procedure UpdateDisplayFormat;
//    procedure NColumnClick(Sender: TObject);
    procedure SetColunmsIndex(const Value: TStringList);
    function GetColunmsIndex: TStringList;
    procedure OnDrawColCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    function GetRecNo: integer;
//    procedure ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure SetBookmarkClick(Sender: TObject);
    procedure GotoBookmarkClick(Sender: TObject);
    procedure ShowBookmarkInPlotClick(Sender: TObject);
    function GetRecRow: integer;
//    procedure MouseWheel(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure NGotoFirstClick(Sender: TObject);
    procedure SelectParametersClick(Sender: TObject);
  protected
    procedure Loaded; override;
    procedure InitializeNewForm; override;
    procedure DoAfterOpen; override;
    procedure DoAfterDialog; override;
    procedure SetC_UpdateFields(const Value: Integer); override;
    class function ClassIcon: Integer; override;
  public
    procedure GotoBookMark(BookMark : Double); override;
    destructor Destroy; override;
  published
    property ColunmsIndex: TStringList read GetColunmsIndex write SetColunmsIndex;
    property ColunmsWidth: string read GetColWidth write FColWidth;
    property CursorY: Double read FCursorY write FCursorY;
    property RecNo: integer read GetRecNo write FRecNo;
    property RecRow: integer read GetRecRow write FRecRow;
    property GotoFirst: Boolean read FGotoFirst write FGotoFirst;
  end;

 TFormCursorlog = class(TFormCursor)
 end;

 TFormCursorRam = class(TFormCursor)
 end;

implementation

uses tools, math, DlgViewParam;

{$R *.dfm}

{$REGION 'TFormCursor'}

{ TFormCursor }

class function TFormCursor.ClassIcon: Integer;
begin
  Result := 49
end;

procedure TFormCursor.InitializeNewForm;
  procedure Add(const capt: string; clck: TNotifyEvent);
   var
    Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FMenu);
    Item.Caption := capt;
    Item.OnClick := clck;
    FMenu.Items.Add(Item);
  end;
begin
  inherited;
  FcursorY := -1;
  FColunmsIndex := TStringList.Create;
  FMenu := CreateUnLoad<TPopupMenu>;
  FDBGrid := CreateUnLoad<TInternalDBGrid>;
{$IFDEF USE_EH}
  FDBGrid.TitleParams.MultiTitle := True;
{$ENDIF}
//  FDBGrid.OnMouseWheelDown := MouseWheel;
//  FDBGrid.OnMouseWheelUp := MouseWheel;
  FDBGrid.OnDrawColumnCell := OnDrawColCell;
  FDBGrid.Align := alClient;
  FDBGrid.ReadOnly := True;
  FDBGrid.DefaultDrawing := False;
  FDBGrid.Parent := Self;
  FDBGrid.DataSource := FDataSource;
  FDBGrid.PopupMenu := FMenu;
//  TInternalDBGrid(FDBGrid).OnContextPopup := ContextPopup;
  Add('Отметить закладку', SetBookmarkClick);
  Add('Перейти на закладку', GotoBookmarkClick);
  Add('Показать закладку на графике', ShowBookmarkInPlotClick);
  Add('-', nil);
  Add('Выбрать параметры...', SelectParametersClick);
end;

procedure TFormCursor.Loaded;
begin
  inherited;
  AddToNCMenu('-');
  AddToNCMenu('Переходить к поступивщим данным', NGotoFirstClick, -1, AUTO_CHECK[FGotoFirst]);
end;

//procedure TFormCursor.MouseWheel(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
//begin
//  Handled := FthChanged;
//end;

{procedure TFormCursor.ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
 var
//  i: Integer;
  Item: TMenuItem;
  procedure Add(const capt: string; clck: TNotifyEvent);
  begin
    Item := TMenuItem.Create(FMenu);
    Item.Caption := capt;
    Item.OnClick := clck;
    FMenu.Items.Add(Item);
  end;
begin
  FMenu.Items.Clear;
  if MousePos.Y <= TInternalDBGrid(FDBGrid).DefaultRowHeight then //for I := 0 to FDBGrid.Columns.Count-1 do
   begin
    Add(FDBGrid.Columns[i].FieldName, NColumnClick);
    Item.Tag := Integer(Pointer(FDBGrid.Columns[i]));
    Item.AutoCheck := True;
    Item.Checked := FDBGrid.Columns[i].Visible;
   end
  else
   begin
    Add('Отметить закладку', SetBookmarkClick);
    Add('Перейти на закладку', GotoBookmarkClick);
    Add('Показать закладку на графике', ShowBookmarkInPlotClick);
   end
end;   }

destructor TFormCursor.Destroy;
begin
  FColunmsIndex.Free;
  inherited;
end;

{procedure TFormCursor.NColumnClick(Sender: TObject);
 var
  m: TMenuItem;
  c: TColumn;
begin
  m := TMenuItem(Sender);
  c := TColumn(Pointer(m.Tag));
  c.Visible := m.Checked;
end;}

procedure TFormCursor.NGotoFirstClick(Sender: TObject);
begin
  FGotoFirst := not FGotoFirst;
  TMenuItem(Sender).Checked := FGotoFirst;
end;

procedure TFormCursor.OnDrawColCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if FcursorY = FDataSet.FieldByName('ID').Value then  FDBGrid.Canvas.Brush.Color := $00C2B5FF;
  FDBGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TFormCursor.DoAfterDialog;
 var
  i: Integer;
begin
  for I := 0 to FDBGrid.Columns.Count-1 do
   begin
    if FDBGrid.Columns[i].Width > 200 then FDBGrid.Columns[i].Width := 200;
    FDBGrid.Columns[i].Alignment := taRightJustify;
   end;
  UpdateDisplayFormat;
end;

procedure TFormCursor.DoAfterOpen;
//  procedure AddField(const fn: string; ft: TFieldType);
{  procedure AddField(fld: TField);
   var
    f, fold: TADTField;
    fds: TFieldDefs;
    ss: TArray<string>;
    i,ix: Integer;
  begin
    //ss := fn.Split(['.']);
    ss := fld.FullName.Split(['.']);
    if Length(ss) <= 1 then Exit;
    i := 0;
    fold := nil;}
{    while i < High(ss) do
     begin
      f := TADTField.Create(FDataSet);
      f.FieldName := ss[i];
      if Assigned(fold) then f.ParentField := fold;
      fold := f;
      inc(i);
     end;
    fld.ParentField := f;}
{    fds := FDataSet.FieldDefs;
    repeat
      ix := fds.IndexOf(ss[i]);
      if ix < 0 then fds := TFieldDef.Create(fds, ss[i], ftADT, 0, True, FDataSet.Fields.Count+i).ChildDefs
      else fds := fds[ix].ChildDefs;
      Inc(i);
    until i = High(ss);
    TFieldDef.Create(fds, ss[i], fld.DataType, fld.Size, True, fld.FieldNo);
//    TFieldDef.Create(fds, ss[i], ft, 0, False, FDataSet.Fields.Count+i);
  end;
 var
  f: TField;
  ss: TArray<string>;
  tt: TArray<TFieldType>;
  i: Integer;}
begin
  inherited;
  FDataSet.DisableControls;
  try
//   for f in FDataSet.Fields do AddField(f);
{   for f in FDataSet.Fields do
    begin
     CArray.Add<TFieldType>(tt, f.DataType);
     CArray.Add<string>(ss, f.FullName);
    end;}
//   for i := 0 to Length(ss)-1 do AddField(ss[i], tt[i]);
//   FDataSet.Close;
//   FDataSet.Fields.Clear;
 //  FDataSet.CreateDataSet;
//   FDataSet.Open;


   UpdateDisplayFormat;
   SetDBColunms;
   FDataSet.RecNo := FRecNo;
   FDataSet.MoveBy(-FRecRow+1);
  finally
   FDataSet.EnableControls;
  end;
end;

function TFormCursor.GetColunmsIndex: TStringList;
 var
  i: Integer;
begin
  FColunmsIndex.Clear;
  if Assigned(FDBGrid) then for I := 0 to FDBGrid.Columns.Count-1 do FColunmsIndex.Add(FDBGrid.Columns[i].Title.Caption);
  Result := FColunmsIndex;
end;

function TFormCursor.GetColWidth: string;
 var
  a: TArray<Integer>;
  i: Integer;
begin
  SetLength(a, FDBGrid.Columns.Count);
  for I := 0 to FDBGrid.Columns.Count-1 do a[i] := FDBGrid.Columns[i].Width;
  Result := TAddressRec(a).ToStr;
end;

function TFormCursor.GetRecNo: integer;
begin
  Result :=  FDataSet.RecNo;
end;

function TFormCursor.GetRecRow: integer;
begin
  Result := TInternalDBGrid(FDBGrid).Row;
end;

procedure TFormCursor.GotoBookMark(BookMark: Double);
 var
  dlt,dltn: Double;
  F: TField;
  n: Integer;
begin
  dlt := 1000000;
  n := -1;
  f := FDataSet.FieldByName('ID');
  FDataSet.DisableControls;
  FDataSet.First;
  while not FDataSet.Eof do
   begin
    dltn := Abs(f.Value - BookMark);
     if dltn < dlt then
      begin
        dlt := dltn;
        n := FDataSet.RecNo;
        FcursorY := f.Value;
      end;
    FDataSet.Next;
   end;
  if n >=0 then FDataSet.RecNo := n;
  FDataSet.EnableControls;
end;

procedure TFormCursor.GotoBookmarkClick(Sender: TObject);
begin
  GotoBookMark(FCursorY);
end;

procedure TFormCursor.SelectParametersClick(Sender: TObject);
 var
  sd:  TArray<string>;
  i: Integer;
  d: Idialog;
begin
  for i := 0 to FDBGrid.Columns.Count-1 do if FDBGrid.Columns[i].Visible then CArray.Add<string>(sd, FDBGrid.Columns[i].FieldName);
  if RegisterDialog.TryGet<Dialog_SelectViewParameters>(d) then (d as IDialog<TViewParams>).Execute(TViewParams.Create(DBName, DataType, sd,
  procedure (sel: Tarray<string>)
   var
    i: Integer;
    s: string;
   label
    label_show;
  begin
    FDataSet.DisableControls;
    try
     for i := 0 to FDBGrid.Columns.Count-1 do
      begin
       for s in sel do if s = FDBGrid.Columns[i].FieldName then  goto label_show;
       FDBGrid.Columns[i].Visible := False;
       Continue;
      label_show:
       FDBGrid.Columns[i].Visible := True;
      end;
     UpdateDisplayFormat;
    finally
     FDataSet.EnableControls;
    end;
  end));
end;

procedure TFormCursor.SetBookmarkClick(Sender: TObject);
begin
  FcursorY := FDataSet.FieldByName('ID').Value;
  FDBGrid.Repaint;
end;

procedure TFormCursor.ShowBookmarkInPlotClick(Sender: TObject);
 var
  f: TFormDataDB;
  fe: IFormEnum;
  fi : IForm;
begin
  if not Supports(GlobalCore, IFormEnum, fe) then Exit;
  fi := fe.Get(FrendFormName);
  if not Assigned(fi) then Exit;
  f := TFormDataDB(fi.GetComponent);
  fi.Show; // из интерфейса Show покажет скрытые формы
  f.GotoBookMark(CursorY);
  FDBGrid.SetFocus;
end;

procedure TFormCursor.SetColunmsIndex(const Value: TStringList);
begin
  FColunmsIndex.Assign(Value);
end;

procedure TFormCursor.SetC_UpdateFields(const Value: Integer);
begin
  if Value <0 then inherited SetC_UpdateFields(Value)
  else if FGotoFirst then FDataSet.First;
end;

procedure TFormCursor.SetDBColunms;
 var
  i,j, x: Integer;
  a: TArray<Integer>;
begin
  for j := 0 to FDBGrid.Columns.Count-1 do for I := 0 to FDBGrid.Columns.Count-1 do  // неоптимально
   begin
    FDBGrid.Columns[j].Title.Alignment := taRightJustify;
    x := FColunmsIndex.IndexOf(FDBGrid.Columns[i].Title.Caption);
    if (x>=0) and (x< FDBGrid.Columns.Count) and (X<>i) then FDBGrid.Columns[i].Index := x;
   end;

  if FColWidth <> '' then
   begin
    a := TAddressRec(FColWidth);
    for i := 0 to min(Length(a), FDBGrid.Columns.Count)-1 do
     begin
      FDBGrid.Columns[i].Visible := a[i] > 0;
      FDBGrid.Columns[i].Width := a[i];
     end;
   end
  else for i := 0 to FDBGrid.Columns.Count-1 do if FDBGrid.Columns[i].Width > 200 then FDBGrid.Columns[i].Width := 200;
end;

function ToDBDisplayFormat(d, p: Integer): string;
 var
  i: Integer;
begin
  Result := '#0.';
  for i:= 1 to p do Result := Result + '0';
end;

procedure TFormCursor.UpdateDisplayFormat;
 var
  i: Integer;
  Node: IXMLNode;
  s: string;
begin
  for i := 0 to FDataSet.Fields.Count-1 do
   begin
    Node := FMemQuery.GetXParam(FDataSet.Fields[i].FieldName);
    FDataSet.Fields[i].Alignment := taRightJustify;
    if not Assigned(Node) then Continue;
    if Node.HasAttribute(AT_AQURICY) then
       TFloatField(FDataSet.Fields[i]).DisplayFormat := ToDBDisplayFormat(Node.Attributes[AT_DIGITS], Node.Attributes[AT_AQURICY]);
    {$IFDEF USE_EH}
    s := FDataSet.Fields[i].FieldName;
    s := s.Replace('.','|');
    {$ELSE}
    if Node.HasAttribute(AT_TITLE) then s := Node.Attributes[AT_TITLE]
    else s := FDataSet.Fields[i].FieldName;
    {$ENDIF}
    if Node.HasAttribute(AT_EU) then s := s + '('+ Node.Attributes[AT_EU] +')';
    TFloatField(FDataSet.Fields[i]).DisplayLabel := s;
   end;
end;

{$ENDREGION}

initialization
  RegisterClass(TFormCursorLog);
  TRegister.AddType<TFormCursorLog, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormCursorRam);
  TRegister.AddType<TFormCursorRam, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormCursorLog>;
  GContainer.RemoveModel<TFormCursorRam>;
end.
