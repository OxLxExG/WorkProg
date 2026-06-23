unit DBImpl;

interface

uses debug_except, RootIntf, DBIntf, System.SyncObjs,
     System.SysUtils, System.Classes, Data.DB, System.Generics.Collections,
     FireDAC.Stan.Intf,
     FireDAC.Stan.Option,
     FireDAC.Stan.Error,
     FireDAC.UI.Intf,
     FireDAC.Phys.Intf,
     FireDAC.Stan.Def,
     FireDAC.Stan.Pool,
     FireDAC.Phys.SQLite,
     FireDAC.Stan.Async,
     FireDAC.Phys,
     FireDAC.Comp.DataSet,
     FireDAC.Comp.Client;

type
  TAsyncADQuery = class(TCustomAsyncADQuery)
  public
    procedure AsyncSQL(const ASQL: String; const AParams: array of Variant; const ATypes: array of TFieldType; cmd: TQueryCommand; ARes: TThreadProcedure; Unic: Boolean = True); override;
  end;

  TAsyncMemTable = class(TCustomAsyncMemTable)
  private
    FCriticalSection: TCriticalSection;
  public
    procedure Acquire; override;
    procedure Release; override;
    procedure CloneCursor(ASource: TFDDataSet; AReset: Boolean = False; AKeepSettings: Boolean = False); override;
  end;

  EConnections = class(EBaseException);
  ConnectionsPool = class
  private
    class var FQuery: TAsyncADQuery;
  public
    class function GetConnection(const ADataBase: string; AActive: boolean = False): IDBConnection;
    // безымянный активный Query
    class function Query: TAsyncADQuery; overload;
    // именной активный Query
    class function Query(const QName: string): TAsyncADQuery; overload;
    // активный IDBConnection
    class function ActiveConnection: IDBConnection;
  end;

implementation

uses Container, tools;//, VTables;

{$REGION 'AsyncDB'}

type
  TAsyncDBConnection = class(TCustomAsyncDBConnection, IInterface, IDBConnection)
  public
   type
    TParams = TArray<Variant>;
    TFields = TArray<TFieldType>;
    TqeRec = record
      Query: TAsyncADQuery;
      sql: string;
      Params: TParams;
      FieldsTypes: TFields;
      Cmd: TQueryCommand;
      Unique: Boolean;
      ResultSQL: TThreadProcedure;
      constructor Create(AQuery: TFDQuery; const Asql: string;
                         const AParams: array of Variant; const ATypes: array of TFieldType;
                         ACmd: TQueryCommand; AUnique: Boolean;
                         AResultSQL: TThreadProcedure);
    end;
  private
   type
    Tth = class(TQeueThread<TqeRec>)
    protected
      procedure Exec(data: TqeRec); override;
    public
      function CompareTask (ToQeTask, InQeTask: TqeRec): Boolean;
    end;
   var
    Fthread: Tth;
    FFileName: string;
    FRefCount: Integer;
    FActive: Boolean;
    FLockConn: TCriticalSection;
    FQeries: TObjDictionary<string, TAsyncADQuery>;
  protected
   // IInterface
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function _AddRef: Integer; reintroduce; stdcall;
    function _Release: Integer; reintroduce; stdcall;
  public
    ///	<summary>
    ///	  В стиле Spring конструктор без параметров
    ///	</summary>
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;
    class function NewInstance: TObject; override;
    procedure AfterConstruction; override;
   // IDBConnection
    function DataBase: string;
    function IsActive: Boolean;
    function AddOrGetQuery(const StdName: string = ''): TCustomAsyncADQuery; overload;
    function AddOrGetQuery(const StdName: string; QueryClass: TCustomAsyncADQueryClass): TCustomAsyncADQuery; overload;
    procedure RemoveQuery(const StdName: string);

    procedure Acquire; override;
    procedure Release; override;
  end;

{ TAsyncDBConnection.TqeRec }

constructor TAsyncDBConnection.TqeRec.Create(AQuery: TFDQuery; const Asql: string;
                         const AParams: array of Variant; const ATypes: array of TFieldType;
                         ACmd: TQueryCommand; AUnique: Boolean;
                         AResultSQL: TThreadProcedure);
  var
   i: Integer;
begin
  Query    := TAsyncADQuery(AQuery);
  sql      := Asql;
  Cmd      := ACmd;
  Unique   := AUnique;
  ResultSQL:= AResultSQL;

  SetLength(Params, Length(AParams));
  for I := 0 to Length(AParams)-1 do Params[i] := AParams[i];

  SetLength(FieldsTypes, Length(ATypes));
  Move(ATypes[0], FieldsTypes[0], Length(ATypes)*SizeOf(TFieldType));
end;

{ TAsyncDBConnection.Tth }

function TAsyncDBConnection.Tth.CompareTask(ToQeTask, InQeTask: TqeRec): Boolean;
begin
  if ToQeTask.Unique then Result := False
  else if (ToQeTask.Query = InQeTask.Query) and (ToQeTask.sql = InQeTask.sql) then Result := True
  else Result := False
end;

procedure TAsyncDBConnection.Tth.Exec(data: TqeRec);
begin
//  TDebug.Log( data.sql +' TAsyncDBConnection.Tth.Exec ++++ ', []);
  data.Query.Acquire;
  try
//   TDebug.Log( data.sql +' TAsyncDBConnection.Tth.Exec ----', []);
   with data do
    case Cmd of
     qcOpen:    Query.Open(   sql, Params, FieldsTypes);
     qcExecute: Query.ExecSQL(sql, Params, FieldsTypes);
     qcRefresh: Query.Refresh;
    end;
  finally
   data.Query.Release;
  end;
//  TDebug.Log('  if Assigned(data.ResultSQL) then Synchronize(data.ResultSQL);++++++    ');
  if Assigned(data.ResultSQL) then Synchronize(data.ResultSQL);
//  TDebug.Log('  if Assigned(data.ResultSQL) then Synchronize(data.ResultSQL);-------    ');
end;

{ TAsyncDBConnection }

constructor TAsyncDBConnection.Create();
begin
  inherited Create(nil);
  FLockConn := TCriticalSection.Create;
  FQeries := TObjDictionary<string, TAsyncADQuery>.Create;
  Fthread := Tth.Create(False, 'DB');
  DriverName := 'Sqlite';
end;

destructor TAsyncDBConnection.Destroy;
begin
  if Assigned(ConnectionsPool.FQuery) and FQeries.ContainsValue(ConnectionsPool.FQuery) then ConnectionsPool.FQuery := nil;
  GContainer.RemoveInstance(ClassInfo, FFileName);  // FRefCount = -1;
  Fthread.Terminate;
  Fthread.WaitFor;
  Fthread.Free;
  FQeries.Free;
  FLockConn.Free;
//  FRowModule.Free;
  inherited;
end;

function TAsyncDBConnection.AddOrGetQuery(const StdName: string; QueryClass: TCustomAsyncADQueryClass): TCustomAsyncADQuery;
begin
 if not FQeries.TryGetValue(StdName, TAsyncADQuery(Result)) then
  begin
   Result := QueryClass.Create();
   Result.Connection := Self;
   FQeries.Add(StdName, TAsyncADQuery(Result));
  end;
end;

function TAsyncDBConnection.AddOrGetQuery(const StdName: string): TCustomAsyncADQuery;
 var
  q: IInterface;
begin
  if not FQeries.TryGetValue(StdName, TAsyncADQuery(Result)) then
   if GContainer.TryGetInstKnownServ(TypeInfo(IQuery), StdName, q, True) then
    begin
     Result := TAsyncADQuery((q as IQuery).GetComponent);
     Result.Connection := Self;
     FQeries.Add(StdName, TAsyncADQuery(Result));
    end
   else Result := AddOrGetQuery(StdName, TAsyncADQuery);
end;

class function TAsyncDBConnection.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TAsyncDBConnection(Result).FRefCount := 1;
end;

function TAsyncDBConnection.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
  if GetInterface(IID, Obj) then Exit(S_OK)
end;

procedure TAsyncDBConnection.RemoveQuery(const StdName: string);
 var
  q: TAsyncADQuery;
begin
  Acquire;
  try
   if FQeries.TryGetValue(StdName, q) then FQeries.Remove(StdName);
  finally
   Release;
  end;
end;

procedure TAsyncDBConnection.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

function TAsyncDBConnection.DataBase: string;
begin
  Result := FFileName;
end;

function TAsyncDBConnection.IsActive: Boolean;
begin
  Result := FActive;
end;

procedure TAsyncDBConnection.Acquire;
begin
  FLockConn.Acquire;
end;

procedure TAsyncDBConnection.Release;
begin
  FLockConn.Release;
end;

function TAsyncDBConnection._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TAsyncDBConnection._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then Destroy;
end;

{ TAsyncADQuery }

procedure TAsyncADQuery.AsyncSQL(const ASQL: String; const AParams: array of Variant; const ATypes: array of TFieldType; cmd: TQueryCommand; ARes: TThreadProcedure; Unic: Boolean = True);
begin
  TAsyncDBConnection(Connection).Fthread.Enqueue(TAsyncDBConnection.TqeRec.Create(Self, ASQL, AParams, ATypes, cmd, Unic, ARes));
end;

{$ENDREGION}

{$REGION 'ConnectionsPool'}

{ ConnectionsPool }

class function ConnectionsPool.GetConnection(const ADataBase: string; AActive: boolean): IDBConnection;
 var
  d: IDBConnection;
  c: TAsyncDBConnection;
  procedure SetActive(cn: IDBConnection);
  begin
    Result := cn;
    if AActive then
     begin
      TAsyncDBConnection(Result).FActive := True;
      FQuery := TAsyncADQuery(Result.AddOrGetQuery);
     end;
  end;
begin
  Result := nil;
  for d in GContainer.InstancesAsArray<IDBConnection> do
   begin
    if AActive then TAsyncDBConnection(d).FActive := False;
    if SameText(d.DataBase, ADataBase) then SetActive(d);
   end;
  if not Assigned(Result) then
   begin
    c := TAsyncDBConnection.Create;
    with c, c.FormatOptions do
     begin
      SetActive(c as IDBConnection);
      FFileName := ADataBase;
      LoginPrompt := False;

      OwnMapRules := True;
      with MapRules.Add do
       begin
        SourceDataType := dtMemo;
        TargetDataType := dtAnsiString;
       end;
      with MapRules.Add do
       begin
        SourceDataType := dtWideMemo;
        TargetDataType := dtWideString;
       end;
      UpdateOptions.CountUpdatedRecords := False;
      UpdateOptions.FastUpdates := True;

      ResourceOptions.CmdExecMode := amBlocking;
      FetchOptions.Mode := fmAll;

      Params.Values['Database'] := ADataBase;
//      Params.Values['MonitorBy'] := 'Remote';
      Connected := true;

//      with TRowModule.Create('v_rowid_module', CliObj) do Connection := c;
     end;
    TRegister.AddType<TAsyncDBConnection, IDBConnection>.LiveTime(ltSingletonNamed).AddInstance(ADataBase, Result as IInterface);
//    Result._Release; // [Week] AddInstance
   end;
end;

class function ConnectionsPool.Query: TAsyncADQuery;
begin
//  Result := ConnectionsPool.Query('');
  if not Assigned(FQuery) then raise EConnections.Create('Необходимо открыть проект');
  Result := FQuery;
end;

class function ConnectionsPool.ActiveConnection: IDBConnection;
 var
  d: IDBConnection;
begin
  for d in GContainer.InstancesAsArray<IDBConnection> do if d.Active then Exit(d);
  raise EConnections.Create('Необходимо открыть проект');
end;

class function ConnectionsPool.Query(const QName: string): TAsyncADQuery;
 var
  d: IDBConnection;
begin
  for d in GContainer.InstancesAsArray<IDBConnection> do if d.Active then Exit(TAsyncADQuery(d.AddOrGetQuery(QName)));
  raise EConnections.Create('Необходимо открыть проект');
end;

{$ENDREGION}

{ TAsyncMemTable }

procedure TAsyncMemTable.Acquire;
begin
  if Assigned(FCriticalSection) then FCriticalSection.Acquire
  else raise Exception.Create('TAsyncMemTable.Acquire NOT ASSIGNED Assigned(FCriticalSection)');
end;

procedure TAsyncMemTable.Release;
begin
  if Assigned(FCriticalSection) then FCriticalSection.Release;
end;

procedure TAsyncMemTable.CloneCursor(ASource: TFDDataSet; AReset, AKeepSettings: Boolean);
begin
  inherited;
  if (ASource is TAsyncADQuery) and Assigned(TAsyncADQuery(ASource).Connection)
     then FCriticalSection := TAsyncDBConnection(TAsyncADQuery(ASource).Connection).FLockConn;
end;

end.
