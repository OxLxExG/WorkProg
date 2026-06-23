unit PrjTool;

interface

uses
      DeviceIntf, ExtendIntf, RootIntf, debug_except, rootimpl, PluginAPI,
      System.SyncObjs, System.DateUtils, System.SysUtils, Xml.XMLIntf, Xml.XMLDoc, Xml.xmldom,
      System.Generics.Collections,
      System.Generics.Defaults,
      System.Bindings.Helper,
      System.Classes, tools, DBimpl,
      FireDAC.Comp.Client,
      FireDAC.Stan.Option,
      Data.DB, System.RTTI, System.Variants;

type
  ISaveDataCash = interface
  ['{149D4C55-CF2E-4FF4-BB73-6A24CC59171F}']
    procedure SaveData(OnEnd: TThreadProcedure);
  end;

  TSaveData = class (THelperXMLtoDB, ISaveDataCash)
  private
    FSql: string;
    Fadr, Fid: integer;
  protected
    procedure SaveData(OnEnd: TThreadProcedure); virtual;
  public
    constructor Create(root: IXMLNode; const sql_fmt: string; adr, id: integer);
  end;

  ISaveLogDataCash = interface(ISaveDataCash)
  ['{186C37D4-A6A4-4BB4-875C-8042BB47A17A}']
    procedure SetStdOnly(StdOnly: Boolean);
  end;

  TSaveLogData = class (TSaveData, ISaveLogDataCash)
  private
    FEventTick: Cardinal;
    FStdOnly: Boolean;
  protected
    procedure SaveData(OnEnd: TThreadProcedure); override;
    procedure SetStdOnly(StdOnly: Boolean);
  end;

implementation

uses DButil, Container, DBintf, FireDAC.Phys.SQLiteWrapper, FireDAC.Phys.SQLiteCli, FireDAC.Stan.Intf;//, VTables;

{$REGION 'MetaData IALLMetaDataFactory IALLMetaData'}

type
  TALLMetaDataFactory = class(TIObject, IALLMetaDataFactory)
    function Get(const DBName: string): IALLMetaData; overload;
    function Get: IALLMetaData; overload;
  end;

  TALLMetaData = class(TIObject, IALLMetaData)
  private
    XDoc: IXMLDocument;
    Connection: IDBConnection;
  protected
    function Get: IXMLDocument;
    procedure Save;
    constructor Create(const DBName: string);
    destructor Destroy; override;
  end;

function TALLMetaDataFactory.Get(const DBName: string): IALLMetaData;
 var
  i: IInterface;
begin
  if GContainer.TryGetInstance(TypeInfo(TALLMetaData), DBName, i, False) then Result := i as IALLMetaData
  else
   begin
    Result := TALLMetaData.Create(DBName);
    TRegister.AddType<TALLMetaData>.AddInstance(DBName, Result as IInterface);
   end
end;

function TALLMetaDataFactory.Get: IALLMetaData;
begin
  Result := Get((GContainer as IManager).ProjectName);
end;


constructor TALLMetaData.Create(const DBName: string);
begin
  Connection := ConnectionsPool.GetConnection(DBName);
  XDoc := NewXDocument;
  XDoc.AddChild('ALL_META_DATA');
end;

destructor TALLMetaData.Destroy;
begin
//  Save;
  inherited;
end;

function TALLMetaData.Get: IXMLDocument;
 var
  n: IXMLNode;
  d: IXMLDocument;
  q: TCustomAsyncADQuery;
  v: Variant;
  s: string;
 label
  NameExists;
  function tst(root: IXMLNode; Adr: Integer): Boolean;
   var
    r: IXMLNode;
  begin
    Result := False;
    for r in XEnum(root) do if (r.Attributes[AT_ADDR] = Adr) then Exit(True);
  end;
begin
  q := Connection.AddOrGetQuery('blablabla');
  q.Acquire;
  try
   q.Open('SELECT Device.id,Device.IName,Modul.Адрес,Modul.MetaData FROM Device,Modul WHERE Device.id = Modul.fk');
   // Remove deleted
   for n in XEnumDec(XDoc.DocumentElement) do
    begin
     for v in q do if v.IName = n.NodeName then goto NameExists;
     XDoc.DocumentElement.ChildNodes.Remove(n);
     NameExists:;
    end;
   // Add new
   for v in q do
    begin
     n := XDoc.DocumentElement.ChildNodes.FindNode(v.IName);
     if not Assigned(n) then
      begin
       n := XDoc.DocumentElement.AddChild(v.IName);
       n.Attributes[AT_DEV_ID] := v.id;
       n.Attributes[AT_SIZE] := v.id;
      end;
     s := v.MetaData;
     if (s = '') or tst(n, v.Адрес) then Continue;
     d := NewXDocument;
     d.LoadFromXML(s);
//     d.DocumentElement.Attributes[AT_FK] := v.id;
     n.ChildNodes.Add(d.DocumentElement);
    end;
  finally
   q.Release;
   Connection.RemoveQuery('blablabla')
  end;
  Result := XDoc;
//  XDoc.SaveToFile(ExtractFilePath(ParamStr(0))+'ALL_META_DATA.xml');
end;

procedure TALLMetaData.Save;
 var
  n, r: IXMLNode;
  q: TCustomAsyncADQuery;
begin
  q := Connection.AddOrGetQuery('temp');
  q.Acquire;
  try
   for r in XEnum(Xdoc.DocumentElement) do for n in XEnum(r) do
    q.ExecSQL(Format(CHNG_MODUL_META,[n.XML, Integer(n.Attributes[AT_ADDR]), Integer(n.ParentNode.Attributes[AT_DEV_ID])]))
  finally
   q.Release;
   Connection.RemoveQuery('temp');
  end;
end;

{$ENDREGION}

{$REGION 'EventTick ILogEventTick'}

type
  IEventTick = interface
    function GetEventTick: Cardinal;
    ///	<summary>
    ///	  Обновляет UserEventTick
    ///	</summary>
    ///  <returns>
    ///   возвращает TRUE если создается новое событие
    ///  </returns>
    function UpdateEvent(var UserEventTick: Cardinal; Adr, Id: Integer): boolean;
    property EventTick: Cardinal read GetEventTick;
  end;

  ILogEventTick = interface(IEventTick)
  ['{C35D16AA-5639-4E1D-9B39-D9BC71B71C31}']
  end;

  TEventTickItem = record
    Tick: Cardinal;
    Adr, Id: Integer;
  end;

  TLogEventTick = class (TIComponent, ILogEventTick)
  private
    FTick: TEventTickItem;
  protected
    function GetEventTick: Cardinal;
    function UpdateEvent(var UserEventTick: Cardinal; Adr, Id: Integer): boolean;
  public
    property S_EventTick: TEventTickItem read FTick write FTick;
  end;

{ TLogEventTick }

function TLogEventTick.GetEventTick: Cardinal;
begin
  Result := FTick.Tick;
end;

function TLogEventTick.UpdateEvent(var UserEventTick: Cardinal; Adr, Id: Integer): boolean;
begin
  Result := FTick.Tick = UserEventTick;
  if Result then
   begin
    FTick.Tick := TThread.GetTickCount;
    ConnectionsPool.Query.AsyncSQL(ADD_EVENT_VAL, [DateTimeToJulianDate(Now)], [ftFloat], qcExecute, nil);
   end;
  UserEventTick := FTick.Tick;
  FTick.Adr := Adr;
  FTick.Id := Id;
  Notify('S_EventTick');
end;

{$ENDREGION}

{$REGION 'SaveData ISaveDataCash, ISaveLogDataCash'}

{ TSaveData }

constructor TSaveData.Create(root: IXMLNode; const sql_fmt: string; adr, id: integer);
begin
  inherited Create(root);
  Fadr := adr;
  Fid := id;
  FSql := Format(sql_fmt, [adr, id, Params]);
end;

procedure TSaveData.SaveData(OnEnd: TThreadProcedure);
begin
  ConnectionsPool.Query.AsyncSQL(FSql, FieldValues, FieldTypes, qcExecute, OnEnd);
end;

{ TSaveLogData }

procedure TSaveLogData.SaveData(OnEnd: TThreadProcedure);
begin
  (GContainer as ILogEventTick).UpdateEvent(FEventTick, FAdr, FId);
  inherited;
end;

procedure TSaveLogData.SetStdOnly(StdOnly: Boolean);
begin
  if FStdOnly <> StdOnly then
   begin
    FStdOnly := StdOnly;
    if FStdOnly then FieldValuesToNil;
   end;
end;

{$ENDREGION}

{$REGION 'MemQuery'}

type
  IHelper = interface(IHelperXMLtoDB)
  ['{B2CD4EB5-D010-4AA5-BEE2-7F6BCE9A53FF}']
    function GetTable: string;
    function SelectFiels(const alias: string): string;
    function JoinTable(const alias, condition: string): string;

    function GetAdr: Integer;
    function GetFk: Integer;

    property Adr: Integer read GetAdr;
    property Fk: Integer read GetFk;
  end;

  TMemQuery = class(TAsyncADQuery, IMemQuery)
   type
    THelper = class(THelperXMLtoDB, IHelper)
      FAdr, Ffk: Integer;
      Owner: TMemQuery;
      function GetAdr: Integer;
      function GetFk: Integer;

      function SelectFiels(const alias: string): string;
      function JoinTable(const alias, condition: string): string;
      function GetTable: string;
      class function Factory(Owner: TMemQuery; Root: IXMLNode; Adr, fk: Integer): IHelper;
    end;
  private
    FDoc: IXMLDocument;
    FHelpes: TArray<IHelper>;
    FFromData: Double;
    FToData: Double;
    FS_UpdateFields: Integer;
    FC_ProjectChange: string;
    function GetData(const DataName: string): Double;
    procedure SetData(const DataName: string; Value: Double);
    function GetFromData: Double;
    function GetToData: Double;
    function GetXParam(const FieldName: string): IXMLNode;
    procedure SetFromData(const Value: Double);
    procedure SetToData(const Value: Double);
    procedure SetS_UpdateFields(const Value: Integer);
    procedure SetC_ProjectChange(const Value: string);
    function GetC_TableUpdate: string;
    procedure SetC_TableUpdate(const Value: string);
  protected
    FC_TableUpdate: TArray<string>;
    procedure SetConnection(const Value: TFDCustomConnection); override;
    function Table: string; virtual; abstract;
    function UpdateNodeName: string; virtual; abstract;
    function SQLGenerate: string; virtual; abstract;
    procedure Update();
    // варианты выбора данных
    property FromData: Double read GetFromData write SetFromData;
    property ToData: Double read GetToData write SetToData;

    procedure UpdateBind; virtual;
    procedure UpdateFields(adr, id: Integer);

//    procedure SetC_EventTick(const Value: TEventTickItem); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    // при изменении проекта проверяем соединение на активное
    property C_ProjectChange: string read FC_ProjectChange write SetC_ProjectChange;
    // при изменении свойств проекта обновляем таблицу S_UpdateFields := -1 все данные, необходимо снова клонировать курсор
    property C_TableUpdate: string read GetC_TableUpdate write SetC_TableUpdate;
    // при изменении таблицы S_UpdateFields := id ????? возможно ненужно
    property S_UpdateFields: Integer read FS_UpdateFields write SetS_UpdateFields;
  end;

{ TMemQuery.THelper }

class function TMemQuery.THelper.Factory(Owner: TMemQuery; Root: IXMLNode; Adr, fk: Integer): IHelper;
 var
  h: THelper;
begin

  Tdebug.Log(Root.NodeName);

  h := THelper.Create(Root, True);
  h.FAdr := Adr;
  h.Ffk := Fk;
  h.Owner := Owner;
  Result := h as IHelper;
end;

function TMemQuery.THelper.GetAdr: Integer;
begin
  Result := Fadr;
end;

function TMemQuery.THelper.GetFk: Integer;
begin
  Result := FFk;
end;

function TMemQuery.THelper.GetTable: string;
begin
  Result := Format('%s_%d_%d', [Owner.Table, fadr, ffk]);
end;

function TMemQuery.THelper.JoinTable(const alias, condition: string): string;
begin
  if Length(FieldNames) <= 0 then Exit('');                      //ev = Events.id
  Result := Format('LEFT OUTER JOIN %s AS %s ON %s.%s',[GetTable, alias, alias, condition]);
end;

function TMemQuery.THelper.SelectFiels(const alias: string): string;
 var
  i: Integer;
begin
  Result := '';
  for I := 0 to Length(FieldNames)-1 do Result := Format('%s,%s."%s"',[Result, alias, FieldNames[i]]);
end;

constructor TMemQuery.Create;
begin
  inherited Create;
  IndexFieldNames := 'ID:D';
  FFromData := -1;
  FToData := -1;
  CachedUpdates := True;
  TBindHelper.Bind(Self, 'C_TableUpdate', GContainer as IProjectData, ['S_TableUpdate']);
end;

destructor TMemQuery.Destroy;
begin
  TBindHelper.RemoveExpressions(Self);
  inherited;
end;

function TMemQuery.GetC_TableUpdate: string;
begin
  Result := string.Join(';', FC_TableUpdate);
end;

function TMemQuery.GetData(const DataName: string): Double;
 var
  v: Variant;
begin
  Acquire;
  try
   v := Connection.ExecSQLScalar('SELECT Значение FROM Options WHERE Имя = :P', [DataName], [ftString]);
   if VarIsNull(v) then Result := 0 else Result := Double(v);
  finally
   Release;
  end;
end;

function TMemQuery.GetFromData: Double;
begin
  if FFromData < 0 then FFromData := GetData(Table + 'FOpt_FromData');
  Result := FFromData;
end;

function TMemQuery.GetToData: Double;
begin
  if FToData < 0 then FToData := GetData(Table + 'FOpt_ToData');
  Result := FToData;
end;

function TMemQuery.GetXParam(const FieldName: string): IXMLNode;
 var
  h: IHelper;
  i: Integer;
begin
  Result := nil;
  for h in FHelpes do for i := 0 to High(h.FieldNames) do if h.FieldNames[i] = FieldName then Exit(h.Fields[i]);
end;

procedure TMemQuery.SetConnection(const Value: TFDCustomConnection);
begin
  inherited;
  Connection.UpdateOptions.FastUpdates := True;
  Connection.UpdateOptions.UpdateChangedFields := False;
  Connection.UpdateOptions.RefreshMode := rmManual;
  Connection.UpdateOptions.CountUpdatedRecords := False;
  UpdateBind();
  Update();
end;

procedure TMemQuery.SetC_ProjectChange(const Value: string);
begin
  FC_ProjectChange := Value;
  UpdateBind();
end;

procedure TMemQuery.SetC_TableUpdate(const Value: string);
begin
  FC_TableUpdate := Value.Split([';'], ExcludeEmpty);
  if (FC_TableUpdate[0] = 'Modul') or
          (SameText(FC_TableUpdate[0], 'Filter')
       and SameText(FC_TableUpdate[1], Table)
       and SameText(FC_TableUpdate[2], (Connection as IDBConnection).DataBase)) then Update()
end;

procedure TMemQuery.SetData(const DataName: string; Value: Double);
begin
  Acquire;
  try
   ExecSQL(ADD_OPTION, [DataName, Value, DataName, 'FilterOptions', 'FilterOptions', null, 1, null, null], [ftString, ftString, ftString, ftString, ftString, ftString, ftString, ftString, ftString]);
  finally
   Release;
  end;
//  Update(); вручную
end;

procedure TMemQuery.SetFromData(const Value: Double);
begin
  if FFromData <> Value then
   begin
    FFromData := Value;
    SetData(Table + 'FOpt_FromData', Value);
   end;
end;

procedure TMemQuery.SetS_UpdateFields(const Value: Integer);
begin
  FS_UpdateFields := Value;
  TBindings.Notify(Self, 'S_UpdateFields');
end;

procedure TMemQuery.SetToData(const Value: Double);
begin
  if FToData <> Value then
   begin
    FToData := Value;
    SetData(Table + 'FOpt_ToData', Value);
   end;
end;

procedure TMemQuery.Update();
 var
  r, u, w: IXMLNode;
begin
  SetLength(FHelpes, 0);
  FDoc := (GContainer as IALLMetaDataFactory).Get(Connection.Params.Values['Database']).Get; // происходит обновление внутри Get()
  for r in XEnum(FDoc.DocumentElement) do for u in XEnum(r) do
   begin
    W := u.ChildNodes.FindNode(UpdateNodeName);
    if Assigned(w) then Carray.Add<IHelper>(FHelpes, THelper.Factory(Self, w, u.Attributes[AT_ADDR], u.ParentNode.Attributes[AT_DEV_ID]));
   end;
   DisableControls;
   S_UpdateFields := -2;
   AsyncSQL(SQLGenerate,[],[], qcOpen, procedure
   begin
     S_UpdateFields := -1;
     EnableControls;
   end);
end;

procedure TMemQuery.UpdateBind;
begin
end;

procedure TMemQuery.UpdateFields(adr, id: Integer);
 var
  h: IHelper;
  ind, i: Integer;
  v: TArray<Variant>;
begin
  ind := 2; // USER LOG RAM
  for h in FHelpes do if (h.Adr = adr) and (h.Fk = id) then
   begin
    v := h.FieldValues;
    for i := 0 to Length(v)-1 do if Fields.Count > ind+i then Fields[ind+i].AsVariant := v[i];
    S_UpdateFields := id;
    Exit;
   end
  else inc(ind, Length(h.FieldNames));
end;

{$ENDREGION}

{$REGION 'TLogQuery'}
type
  TLogQuery = class(TMemQuery)
  private
    FC_EventTick: TEventTickItem;
    procedure SetC_EventTick(const Value: TEventTickItem);
  protected
   const
    STR_SQL = 'SELECT Events.id AS "ID", Events."Время события" AS "Время"%s FROM Events %s ORDER BY Events."Время события" DESC';
//    STR_SQL = 'SELECT Events.id AS "ID", datetime(Events."Время события") AS "Время"%s FROM Events %s ORDER BY Events."Время события" DESC';
    STR_SQL_LIMIT = '%s LIMIT %d';
    function Table: string; override;
    function UpdateNodeName: string; override;
    function SQLGenerate: string; override;
    procedure UpdateBind; override;
  public
    // добавляем записи
    property C_EventTick: TEventTickItem read FC_EventTick write SetC_EventTick;
  end;

procedure TLogQuery.SetC_EventTick(const Value: TEventTickItem);
begin
  DisableControls;
  try
   if FC_EventTick.Tick <> Value.Tick then
    begin
     FC_EventTick := Value;
     First;
     InsertRecord([FieldByName('ID').AsInteger + 1, Now]);
    end;
   UpdateFields(Value.Adr, Value.Id);
  finally
   EnableControls;
  end
end;

function TLogQuery.SQLGenerate: string;
 var
  LeftOuterJoins: TArray<string>;
  Fields: TArray<string>;
  Alias: char;
  h: IHelper;
  procedure AddToArray(var ar: TArray<string>; const s: string);
  begin
    if s <> '' then CArray.Add<string>(ar, s);
  end;
begin
  Alias := 'a';
  for h in FHelpes do
   begin
    AddToArray(Fields, h.SelectFiels(Alias));
    AddToArray(LeftOuterJoins, h.JoinTable(Alias, 'ev = Events.id'));
    inc(Alias, 1);
   end;
  if Length(Fields) = 0 then Result := Format(STR_SQL, ['', ''])
  else Result := Format(STR_SQL, [string.Join('', Fields), string.Join(' ', LeftOuterJoins)]);
  if ToData > 0 then Result := Format(STR_SQL_LIMIT, [Result, Round(ToData)]);
end;

function TLogQuery.Table: string;
begin
  Result := 'Log';
end;

procedure TLogQuery.UpdateBind;
begin
  TBindHelper.RemoveControlExpressions(Self, ['C_EventTick']);
  if Assigned(Connection) and (Connection as IDBConnection).Active then
     TBindHelper.Bind(Self, 'C_EventTick', GContainer as ILogEventTick, ['S_EventTick']);
end;

function TLogQuery.UpdateNodeName: string;
begin
  Result := T_WRK;
end;

{$ENDREGION}

{$REGION ' TRamQuery'}
type
  TRamQuery = class(TMemQuery, IRamQuery)
  private
    LastMaxID: Integer;
    function MaxID: Integer;
  protected
   const                                                                //ORDER BY Ram.ID { TODO : видимо нужен лимит для Ram.ID }
    STR_SQL = 'SELECT Ram.ID AS "ID", Ram."Время события" AS "Время"%s FROM Ram %s LIMIT %d,%d';
    procedure UpdateRam;
//    function GetMaxID: Integer;
    function Table: string; override;
    function UpdateNodeName: string; override;
    function SQLGenerate: string; override;
  public
    constructor Create; override;
  end;

constructor TRamQuery.Create;
begin
  inherited Create;
  IndexFieldNames := 'ID:A';
end;

//function TRamQuery.GetMaxID: Integer;
//begin
//  if LastMaxID <= 0 then
//   if ToData > 0 then LastMaxID := Round(ToData)
//   else LastMaxID := MaxID;
//  Result := LastMaxID;
//end;

function TRamQuery.MaxID: Integer;
 var
  MaxExp: TArray<string>;
  h: IHelper;
begin
  for h in FHelpes do if Length(h.FieldNames) > 0 then                             // подразумеваем 0 поле DEV.TIME (кадр)
      CArray.Add<string>(MaxExp, Format('ifnull((SELECT max("%s") FROM %s),0)',['id' {h.FieldNames[0]}, h.GetTable]));
  if Length(MaxExp) = 0 then Exit(0);
  Acquire;
  try
   Exit(Connection.ExecSQLScalar(Format('SELECT max(%s)', [string.Join(',', MaxExp)])));
  finally
   Release;
  end;
end;

procedure TRamQuery.UpdateRam;
 var
  rmax, tmax, i: Integer;
  DBTimeStart: TDateTime;
begin
  tmax := MaxID;
  Acquire;
  try
   rmax := Connection.ExecSQLScalar('SELECT ifnull(max(id),0) FROM Ram');
   Connection.StartTransaction;
   try
    if tmax > rmax then
     begin
      try
       DBTimeStart := (GContainer as IProjectOptions).Option['TIME_START'];
      except
       DBTimeStart := StrToDateTime((GContainer as IProjectOptions).Option['TIME_START']);
      end;
      for i := rmax+1 to tmax do ExecSQL(ADD_RAM, [i, DateTimeToJulianDate(DBTimeStart+CTime.FromKadr(i))], [ftInteger, ftFloat])
     end
    else if tmax < rmax then ExecSQL(Format(DEL_RAM, [tmax]))
   finally
    Connection.Commit;
   end;
  finally
   Release;
  end;
  if LastMaxID <= 0 then
   if ToData > 0 then LastMaxID := Round(ToData)
   else LastMaxID := tmax;
end;


function TRamQuery.SQLGenerate: string;
 const
  FIELD_ID = 0;
  FIELD_TIME = 1;
 var
  LeftOuterJoins: TArray<string>;
  Fields: TArray<string>;
  Alias: char;
  h: IHelper;
  frd: Integer;
  procedure AddToArray(var ar: TArray<string>; const s: string);
  begin
    if s <> '' then CArray.Add<string>(ar, s);
  end;
begin
  Alias := 'a';
  for h in FHelpes do if Length(h.FieldNames) > 0 then
   begin
    AddToArray(Fields, h.SelectFiels(Alias));
//    if h.Adr = 101 then AddToArray(LeftOuterJoins, h.JoinTable(Alias, Format('%s = Ram.Time',[h.FieldNames[FIELD_TIME]])))

     if h.Adr = 101 then                                                     // подразумеваем 0 поле DEV.TIME (кадр)
         AddToArray(LeftOuterJoins, h.JoinTable(Alias, Format('"%s" = Ram.ID*2',['id'{h.FieldNames[FIELD_ID]}])))
    else AddToArray(LeftOuterJoins, h.JoinTable(Alias, Format('"%s" = Ram.ID  ',['id'{h.FieldNames[FIELD_ID]}])));

    inc(Alias, 1);
   end;
  UpdateRam();
  frd := Round(Double(FromData));
//  tod := GetMaxID;
  if Length(Fields) = 0 then Result := Format(STR_SQL, ['', '', frd, LastMaxID-frd])
  else Result := Format(STR_SQL, [string.Join('', Fields), string.Join(' ', LeftOuterJoins), frd, LastMaxID-frd]);
end;

function TRamQuery.Table: string;
begin
  Result := 'Ram';
end;

function TRamQuery.UpdateNodeName: string;
begin
  Result := T_RAM;
end;

{$ENDREGION}

{$REGION 'Virtual Ram Table'}
//type
// TRamCursor = class(TRowCursor)
//  public
//    constructor Create(ATable: TSQLiteVTable; Connection: TCustomAsyncDBConnection); override;
// end;

{ TRamCursor }

//constructor TRamCursor.Create(ATable: TSQLiteVTable; Connection: TCustomAsyncDBConnection);
//begin
//  inherited;
//  MaxIndex := ((FConnection as IDBConnection).AddOrGetQuery('Ram') as IRamQuery).GetMaxID;
//end;
{$ENDREGION}

{ TRamVtableCursor }

initialization
//  ProjectRowCursorClass := TRamCursor;
  TRegister.AddType<TALLMetaDataFactory, IALLMetaDataFactory>.LiveTime(ltTransient);
  TRegister.AddType<TALLMetaData, IALLMetaData>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TLogEventTick, ILogEventTick>.LiveTime(ltSingleton);
  TRegister.AddType<TLogQuery, IQuery>.LiveTime(ltTransientNamed).AddInstance('Log');
  TRegister.AddType<TRamQuery, IQuery>.LiveTime(ltTransientNamed).AddInstance('Ram');
finalization
  GContainer.RemoveModel<TALLMetaData>;
  GContainer.RemoveModel<TALLMetaDataFactory>;
  GContainer.RemoveModel<TLogEventTick>;
  GContainer.RemoveModel<TLogQuery>;
  GContainer.RemoveModel<TRamQuery>;
end.
