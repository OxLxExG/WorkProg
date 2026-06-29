unit VCLTableDataForm;

interface

{$INCLUDE global.inc}


uses IDataSets, Vcl.ActnList, debug_except, Xml.XMLIntf, FileDataSet,
     VCL.CustomDataForm, Container, ExtendIntf, Actns, Data.DB, XMLDataSet, RootIntf,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RootImpl, CustomPlot, Vcl.Grids, Vcl.DBGrids, Vcl.Menus;

{$IFDEF ENG_VERSION}
  const
   C_CaptGrForm ='New Table';
   C_MenuView ='Visualization windows';
   C_Memu_Show='Show';
  SWRK = 'Information Table';
  SRAM = 'Memory Table';
  C_Table='Table';

{$ELSE}
  const
  C_Table='Таблица';
  SWRK = 'Таблица Информации';
  SRAM = 'Таблица Памяти';
   C_CaptGrForm ='Новая таблица';
   C_MenuView ='Окна визуализации';
   C_Memu_Show='Показать';
{$ENDIF}

type
  TTableDataForm = class(TCustomFormData, INotifyClientBeforeRemove)
    Grid: TDBGrid;
    ds: TDataSource;
    ppm: TPopupMenu;
    NGra: TMenuItem;
    procedure NGraClick(Sender: TObject);
  private
    FDataSetFactory: TDataSetFactory;
    FC_Write: Integer;
    CurrentBlob: TArray<Single>;
    CurrentBlobName: string;
    procedure SetC_Write(const Value: Integer);
   const
    NICON = 133;
    class procedure Act1Click(Sender: TObject);
    procedure SetBind;
    procedure CellClick(Column: TColumn);
    procedure SetDataSetFactory(const Value: TDataSetFactory);
    { Private declarations }
  protected
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
    procedure ClientBeforeRemove(Service: ServiceType; ClientName: string);
  public
    class var SubActions: TArray<IAction>;
    constructor Create; override;
    destructor Destroy; override;
    [StaticAction(C_CaptGrForm, C_MenuView, NICON, '0:'+C_Memu_Show+'.'+C_MenuView,'',False,False,0,True, True)]
    class procedure DoUpdate(Sender: IAction);
    property C_Write: Integer read FC_Write write SetC_Write;
  published
    property DataSetFactory: TDataSetFactory read FDataSetFactory write SetDataSetFactory;
  end;

implementation

{$R *.dfm}

uses tools, Parser, VCLFormShowArrayTable;

type
  TxmlAct = class(TICustomAction)
    XmlSection: IXMLNode;
  end;

{ TTableDataForm }

class procedure TTableDataForm.Act1Click(Sender: TObject);
 var
  dsdef: TXMLDataSetDef;
  gdf: TTableDataForm;
  f: IForm;
  fe: IFormEnum;
begin
  if Sender is TxmlAct then
   begin
    dsdef := TXMLDataSetDef.CreateUser(TxmlAct(Sender).XmlSection, True);
    if Assigned(dsdef) then
     begin
      gdf := CreateUser();
      f := gdf as IForm; // Сразу создать интерфейс для самоуничтожения формы если ошибки
      gdf.DataSetFactory := TDataSetFactory.CreateUser(dsdef);
      gdf.Caption := C_Table+ ' '+dsdef.Section+' ' + dsdef.ModulName;
      if Supports(GlobalCore, IFormEnum, fe) then fe.Add(f);
      (GContainer as ITabFormProvider).Tab(f);
      f.Show;
     end;    
   end;  
end;

procedure TTableDataForm.CellClick(Column: TColumn);
var
  BS: TStream;
begin
  // Проверяем, что кликнули именно по BLOB-полю
  if Column.Field.DataType in [ftBlob] then
  begin
    var bf: TBlobField := TBlobField(Column.Field);
    var bfd: TFileFieldDef :=  TFileDataSet(bf.DataSet).FindFieldDef(bf.FullName);
      var val := bf.Value;
      var a := TPars.ArrayToString(@val[0], bfd.ArraySize, bfd.ArrayType);
      Grid.ShowHint := true;
      Grid.Hint := a;
      CurrentBlob := TPars.ArrayToFloat(@val[0], bfd.ArraySize, bfd.ArrayType);
      CurrentBlobName := Column.Grid.DataSource.DataSet.FieldByName('ID').AsString + ' : ' +  bf.FullName;
      Grid.PopupMenu := ppm;
  end
  else
   begin
      Grid.ShowHint := false;
      Grid.Hint := '';
      Grid.PopupMenu := nil;
      CurrentBlob := [];

   end;
end;

class function TTableDataForm.ClassIcon: Integer;
begin
  Result := NICON;
end;

procedure TTableDataForm.ClientBeforeRemove(Service: ServiceType; ClientName: string);
begin
  if SameText(ClientName, TXMLDataSetDef(DataSetFactory.DataSetDef).BINFileName) then
   begin
    TDebug.Log('TTableDataForm.ClientBeforeRemove[%s] %s = %s',[Caption, ClientName, TXMLDataSetDef(DataSetFactory.DataSetDef).BINFileName]);
    Close_ItemClick(Self);
   end
  else TDebug.Log('TTableDataForm.ClientBeforeRemove[%s] %s <> %s',[Caption, ClientName, TXMLDataSetDef(DataSetFactory.DataSetDef).BINFileName]);
end;

constructor TTableDataForm.Create;
begin
  FDataSetFactory := TDataSetFactory.Create;
  inherited;
end;

destructor TTableDataForm.Destroy;
begin
  FDataSetFactory.Free;
  inherited;
end;

class procedure TTableDataForm.DoUpdate(Sender: IAction);
 const
  SPATH = '0:'+C_Memu_Show+'.'+C_MenuView+'.'+C_CaptGrForm;
 var
  visFlag: Boolean;
  procedure AddMenu(n: IXMLNode; const subpath: string);
   var
    xa: TxmlAct;
    ia: IAction;
  begin
    if not n.HasAttribute(AT_FILE_NAME) then Exit;    
    xa := TxmlAct.CreateUser(ActionAttribute.Create(n.ParentNode.NodeName, C_MenuView, NICON, SPATH+'.'+subpath));
    xa.XmlSection := n;
    xa.OnExecute := Act1Click;
    ia := xa as IAction;
    ia.DefaultShow;
    SubActions := SubActions +[ia];
    visFlag := True;;
  end;
 var
  w,r: IAction;
  n: IXMLNode;
  devs: TArray<IXMLNode>;
begin
  SetLength(SubActions, 0); // = Sender.ChildMenuItems.Clear;
  w := TxmlAct.CreateUser(ActionAttribute.Create(SWRK, C_MenuView, NICON, SPATH));
  r := TxmlAct.CreateUser(ActionAttribute.Create(SRAM, C_MenuView, NICON, SPATH));
  SubActions := SubActions +[w, r];
  w.DefaultShow;
  r.DefaultShow;
  if Assigned((GContainer as IALLMetaDataFactory).Get) and Assigned((GContainer as IALLMetaDataFactory).Get.Get) then
   begin
    devs := FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement);
    visFlag := False;
    for n in GetDevsSections(devs, T_WRK) do AddMenu(n, SWRK);
    w.Visible := visFlag;
    visFlag := False;
    for n in GetDevsSections(devs, T_RAM) do AddMenu(n, SRAM);
    r.Visible := visFlag;
    Sender.Visible := r.Visible or w.Visible;
   // Sender.DefaultShow;
   end
  else Sender.Visible := False;
end;

procedure TTableDataForm.Loaded;
begin
  inherited;
  Grid.OnCellClick := CellClick;
  SetBind;
end;

procedure TTableDataForm.NGraClick(Sender: TObject);
var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_TableGraph>(d) then
    (d as IDialog<string, TArray<Single>>).Execute(CurrentBlobName, CurrentBlob);
end;

procedure TTableDataForm.SetBind;
begin
  if Assigned(DataSetFactory) then
   begin
    if (DataSetFactory.DataSet is TXMLDataSet) and TXMLDataSet(DataSetFactory.DataSet).IsActive then
     begin
      Bind('C_Write', TXMLDataSet(DataSetFactory.DataSet).FileData, ['S_Write']);
     end;
    ds.DataSet := DataSetFactory.DataSet;
    ds.DataSet.Open;
   end;
end;

procedure TTableDataForm.SetC_Write(const Value: Integer);
begin
  FC_Write := Value;
  ds.DataSet.Last;
end;

procedure TTableDataForm.SetDataSetFactory(const Value: TDataSetFactory);
begin
  if Assigned(FDataSetFactory) then FDataSetFactory.Free;
  FDataSetFactory := Value;
  SetBind;
end;

initialization
  RegisterClass(TTableDataForm);
  TRegister.AddType<TTableDataForm, IForm, INotifyClientBeforeRemove>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TTableDataForm>;
end.
