unit DataDBForm;

interface

uses DBintf, DBImpl, AbstractDlgParams, DlgFltParam,
     RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Xml.XMLIntf, System.Generics.Collections, System.SyncObjs, Container,
     System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.Graphics, Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.Menus, RootIntf,
     FireDAC.Stan.Intf,
     FireDAC.Stan.Option,
     FireDAC.Stan.Error,
     FireDAC.UI.Intf,
     FireDAC.Phys.Intf,
     FireDAC.Stan.Def,
     FireDAC.Stan.Pool,
     FireDAC.Stan.Async,
     FireDAC.Phys,
     FireDAC.Comp.Client,
     System.IOUtils;

type
  TableParams = record
    UsedParams: string;
    TableName: string;
  end;

  TFormDataDB = class(TCustomFontIForm)
  private
//    FTableChange: string;
    FProject: string;
//    FDevice: string;
    FDataType: TypeDataShow;
    FFrendFormName: string;
//    FFromData: Double;
//    FToData: Double;
    FC_UpdateFields: Integer;
//    function GetInfo: string;
//    procedure SetXInfo(const Value: string);
    procedure NSelectParamsClick(Sender: TObject);
    procedure NExportToLASClick(Sender: TObject);
    procedure NFilterGluClick(Sender: TObject);
    procedure CreateConnection(const dbn: string);
  protected
//    FTypeData: TFormDBTypeData;
    FMemQuery: IMemQuery;
    FDBName: string;
//    XDoc: IXMLDocument;
//    XFormats: IXMLDocument;
    FDBConnection: IDBConnection;
    FDataSource: TDataSource;
    FDataSet: TCustomAsyncMemTable;
    procedure Loaded; override;
    procedure InitializeNewForm; override;
//    function GetTypeDataClass: TFormDBTypeDataClass; virtual; abstract;
    procedure SetProjectChange(const Value: string); virtual;
//    procedure SetDeviceChange(const Value: string); virtual;
//    procedure SetTableChange(const Value: string); virtual;
    procedure SetC_UpdateFields(const Value: Integer); virtual;
    procedure UpdateCaption;
//    procedure UpdateParams;
    procedure DoBeforeClose; virtual;
    procedure DoAfterOpen; virtual;
    procedure DoAfterDialog; virtual;
    function Query: TCustomAsyncADQuery;
//    procedure NToClick(Sender: TObject); virtual;
    class function CreateNewForm(tdsh: TypeDataShow): TFormDataDB;
    // варианты выбора данных
//    property FromData: Double read FFromData write FFromData;
//    property ToData: Double read FToData write FToData;
  public
    class procedure DoCreateForm(Sender: IAction); override;
    procedure ResetParamsAndScreen;
    procedure GotoBookMark(BookMark : Double); virtual;
//    function GetEnumerator: TableParamsEnumerator;
//    property DBConnection: IDBConnection read FDBConnection implements IDBConnection; // или QueryInterface ????
    constructor CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string); virtual;

    property ProjectChange: string read FProject write SetProjectChange;
//    property DeviceChange: string read FDevice write SetDeviceChange;
//    property TableChange: string read FTableChange write SetTableChange;

    property C_UpdateFields: Integer read FC_UpdateFields write SetC_UpdateFields;
  published
    property DBName: string read FDBName write FDBName;
//    property XInfo: string read GetInfo write SetXInfo;
    property DataType: TypeDataShow read FDataType write FDataType;
    property FrendFormName: string read FFrendFormName write FFrendFormName;  // for BookMark
  end;
  TFormDataDBClass = class of TFormDataDB;

{  TFormDataDBLog = class(TFormDataDB)
  private
    procedure NClick(Sender: TObject);
  protected
    procedure InitializeNewForm; override;
  end;

  TFormDataDBRam = class(TFormDataDB)
  private
    procedure GluFilterClick(Sender: TObject);
  protected
    procedure InitializeNewForm; override;
  public
    class procedure DoCreateForm(Sender: IAction); override;
  end;}

//procedure DecodeFmt(const Fmt: string; var digit, pres: integer);

implementation

 uses tools, Vcl.Dialogs, DlgFromToGlu, ExportLas;

{procedure DecodeFmt(const Fmt: string; var digit, pres: integer);
 var
  dt, pr, f: Integer;
begin
  digit := 0;
  pres := 0;
  pr := Pos('%', Fmt);
  dt := Pos('.', Fmt);
  f := Pos('f', Fmt);
  if (pr>0) and (dt>0) and (f>0) then
   begin
    digit := Copy(Fmt, pr+1, dt-pr-1).ToInteger;
    pres :=  Copy(Fmt, dt+1, f-dt-1).ToInteger;
   end
end;}

{$REGION 'TFormDataDB'}

{ TFormDataDB }

procedure TFormDataDB.CreateConnection(const dbn: string);
  var
   q: TCustomAsyncADQuery;
begin
  try
  if dbn <> '' then
   begin
    FDBName := dbn;
    FDBConnection := ConnectionsPool.GetConnection(FDBName);
    q := Query;
    FMemQuery := q as IMemQuery;
    Bind('C_UpdateFields', q as IInterface, ['S_UpdateFields']);
    if q.Active then ResetParamsAndScreen;
   end;
  except
    on E: Exception do TDebug.DoException(E);
  end;
end;

constructor TFormDataDB.CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string);
begin
  DataType := tdsh;
  DBName := ADBName;
  CreateUser();
  UpdateCaption;
end;

class function TFormDataDB.CreateNewForm(tdsh: TypeDataShow): TFormDataDB;
 var
  d: TOpenDialog;
  fe: IFormEnum;
begin
  Result := nil;
  d := TOpenDialog.Create(nil);
  try
   d.InitialDir := Tpath.GetFullPath(ParamStr(0)) + 'Projects';
   d.Filter :=  'Файл проекта (*.db)|*.db';
   d.DefaultExt := 'db';
   d.Options := [ofReadOnly,ofHideReadOnly,ofPathMustExist,ofFileMustExist,ofEnableSizing];
   if d.Execute(Application.Handle) then
    begin
     Result := CreateFromDialog(nil, tdsh, d.FileName);
     if Supports(GlobalCore, IFormEnum, fe) then fe.Add(Result as IForm);
     Result.Show;
    end;
  finally
   d.Free;
  end;
end;

procedure TFormDataDB.GotoBookMark(BookMark: Double);
begin
end;

procedure TFormDataDB.DoAfterDialog;
begin
  FDataSource.DataSet := FDataSet;
end;

procedure TFormDataDB.DoAfterOpen;
begin
  FDataSource.DataSet := FDataSet;
end;

procedure TFormDataDB.DoBeforeClose;
begin
  FDataSource.DataSet := nil;
end;

class procedure TFormDataDB.DoCreateForm(Sender: IAction);
begin
  CreateNewForm(hdtLog);
end;

procedure TFormDataDB.InitializeNewForm;
begin
  inherited;
  FDataSource := CreateUnLoad<TDataSource>;
  FDataSet := CreateUnLoad<TAsyncMemTable>;
end;

procedure TFormDataDB.Loaded;
 const
  TXTDT: array [TypeDataShow] of string = ('Количество данных...', 'Фильтр по кадрам...', 'Фильтр по глубине...');
begin
  inherited;
  AddToNCMenu('-');
  AddToNCMenu('Фильтр данных...', NSelectParamsClick);
  AddToNCMenu('-');
  AddToNCMenu(TXTDT[DataType], NFilterGluClick);
  AddToNCMenu('-');
  AddToNCMenu('Экспортировать в LAS...', NExportToLASClick);

  Bind('ProjectChange', GlobalCore as IManager , ['S_ProjectChange']);
  CreateConnection(FDBName);
//  if Supports(GlobalCore, IDeviceEnum, d) then Bind('DeviceChange', d, ['S_AfterAdd', 'S_AfterRemove', 'S_PublishedChanged']);
end;

procedure TFormDataDB.UpdateCaption;
 const
  TXTDT: array [TypeDataShow] of string = ('LOG', 'RAM', 'GLU');
  TXTACT: array [Boolean] of string = ('', ' A');
begin
  Caption := Format('[%s %s] %s', [TXTDT[DataType], TXTACT[FDBConnection.Active], Tpath.GetFileNameWithoutExtension(DBName)]);
end;

procedure TFormDataDB.SetC_UpdateFields(const Value: Integer);
begin
  FC_UpdateFields := Value;
  if FC_UpdateFields = -1 then ResetParamsAndScreen
  else if FC_UpdateFields = -2 then
   begin
    FDataSet.DisableControls;
    DoBeforeClose;
    FDataSet.Close;
   end;
end;
procedure TFormDataDB.ResetParamsAndScreen;
begin
//  FDataSet.DisableControls;
  try
//   DoBeforeClose;
   FDataSet.CloneCursor(Query);
   DoAfterOpen();
  finally
   FDataSet.EnableControls;
  end;
end;

procedure TFormDataDB.NExportToLASClick(Sender: TObject);
begin

end;

procedure TFormDataDB.NFilterGluClick(Sender: TObject);
begin
  case DataType of
    hdtLog:
     begin
      FMemQuery.ToData := Vcl.Dialogs.InputBox('Количество данных', 'Введите',  FMemQuery.ToData.ToString()).ToDouble;
      FMemQuery.Update;
     end;
    hdtRam: TFormDlgGluFilter.Execute(FMemQuery);
    hdtGlu: TFormDlgGluFilter.Execute(FMemQuery);
  end;
end;

procedure TFormDataDB.NSelectParamsClick(Sender: TObject);
 var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_FilterParameters>(d) then (d as IDialog<TFilterParams>).Execute(TFilterParams.Create(DBName, DataType));
end;

function TFormDataDB.Query: TCustomAsyncADQuery;
 const
  TB_NAME: array [TypeDataShow] of string = ('Log', 'Ram', 'Glu');
begin
  Result := FDBConnection.AddOrGetQuery(TB_NAME[DataType]);
end;


//procedure TFormDataDB.SetDeviceChange(const Value: string);
//begin
//  ResetParamsAndScreen;
//end;

procedure TFormDataDB.SetProjectChange(const Value: string);
begin
  UpdateCaption;
end;

{procedure TFormDataDB.SetTableChange(const Value: string);
begin
  if Value = 'Modul' then ResetParamsAndScreen
  else if FDBConnection.Active and (Value = 'Log') then
   begin
{    FDataSet.DisableControls;
    FDataSource.DataSet := nil;
    FDataSet.Refresh(procedure
    begin
      FDataSource.DataSet := FDataSet;
      sleep(1);
      FthChanged := False;
      FDataSet.RecNo := 0;
      FDataSet.EnableControls;
    end);}
//        FDataSet.ExecSQL;
//        FDataSet.Connection.ExecSQLScalar(FDataSet.SQL.Text);
        //        FDataSet.FetchAll;
//        FReadDataTh.Queue(procedure
//         begin
//          FDataSet.RecNo := 0;
//         end);
//        FReadDataTh.Queue(procedure
//         begin
//          FDataSet.EnableControls;
//         end);
//     end);
//  end;
//end;
{$ENDREGION}

{ TTypeDataLog }

{function TTypeDataLog.SQL: string;
 const
   STR_SQL = 'SELECT Events.id AS "ID" , datetime(Events."Время события") AS "Время" %s FROM Events %s ORDER BY Events."Время события" DESC';
   STR_SQL_LIMIT = ' LIMIT %d';
begin
  Result := innerSQL(STR_SQL, STR_SQL_LIMIT);
end;

procedure TTypeDataLog.AfterGetEnumerator;
begin
  Form.XFormats.DocumentElement.AddChild('ID');
  Form.XFormats.DocumentElement.AddChild('JULIAN_TIME');
end;

procedure TTypeDataLog.AfterLoaded;
 var
  n: TMenuItem;
begin
  Form.AddToNCMenu('-', nil, n);
  Form.AddToNCMenu('Количество данных...', NNDataClick, n);
end;

procedure TTypeDataLog.NNDataClick(Sender: TObject);
 var
  s: string;
begin
  s := IntToStr(Round(Form.FromData));
  if InputQuery('Количество данных', 'Ввести', s) then
   begin
    Form.FromData := s.ToInteger;
    Form.ResetParamsAndScreen;
   end;
end;

function TTypeDataLog.innerSQL(const ssgl, slimit: string): string;
 var
  d: TableParams;
  sp, st: string;
  DislpayLimit: Integer;
begin
  sp := '';
  st := '';
  for d in Form do
   begin
    sp := sp + d.UsedParams;
    st := st + ' LEFT OUTER JOIN '+ d.TableName + ' ON ' + d.TableName + '.ev = Events.id'
   end;
  Result := Format(ssgl, [sp, st]);
  DislpayLimit := Round(Form.FromData);
  if DislpayLimit > 0 then Result :=  Result + Format(slimit, [DislpayLimit, DislpayLimit])
//  XFormats.SaveToFile(ExtractFilePath(ParamStr(0))+'XFormats.xml');
end;   }

{ TFormDataDBLog }

{procedure TFormDataDBLog.InitializeNewForm;
 var
  n: TMenuItem;
begin
  inherited;
  AddToNCMenu('Количество данных...', NClick, n);
end;

procedure TFormDataDBLog.NClick(Sender: TObject);
begin
  FMemQuery.ToData := Vcl.Dialogs.InputBox('Количество данных', 'Введите',  FMemQuery.ToData.ToString()).ToDouble;
  FMemQuery.Update;
end;

{ TFormDataDBRam }

{class procedure TFormDataDBRam.DoCreateForm(Sender: IAction);
begin
  CreateNewForm(hdtRam);
end;

procedure TFormDataDBRam.GluFilterClick(Sender: TObject);
begin
  TFormDlgGluFilter.Execute(FMemQuery);
end;

procedure TFormDataDBRam.InitializeNewForm;
 var
  n: TMenuItem;
begin
  inherited;
  AddToNCMenu('Фильтр по глубине...', GluFilterClick, n);
end; }

end.
