unit Plot.VirtualData;

interface

{$INCLUDE global.inc}

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  System.Math, System.SyncObjs, System.TypInfo,
  Data.DB, DataSetIntf, IDataSets, FileDataSet, FileCachImpl, ExtendIntf,
  Parser, Container, debug_except, tools, CustomPlot.DataLink;

// Thread-local helpers used by virtual readers to know which Y/X fields to extract.
// The DataLink sets them before asking the reader for a window.
function FYParamName: string;
function FXParamName: string;
procedure SetVirtualParamNames(const YName, XName: string);

type
  {$REGION 'Virtual window / cache records'}

  /// <summary>
  /// A simple immutable window describing visible range on the Y axis.
  /// </summary>
  TVirtualDataWindow = record
    YFrom: Double;
    YTo: Double;
    RecordFrom: Integer;
    RecordTo: Integer;
    ScreenHeightPx: Integer;
    function IsEmpty: Boolean;
    function Contains(Y: Double): Boolean;
  end;

  /// <summary>
  /// Type of one line record extracted from the virtualized data source.
  /// </summary>
  TLineRecord = record
    Y: Single;
    X: Single;
  end;

  /// <summary>
  /// Type of one wave record extracted from the virtualized data source.
  /// </summary>
  TWaveRecord = record
    Y: Single;
    X: TArray<ShortInt>;
  end;

  /// <summary>
  /// Describes what is needed to read a single record directly from the binary file.
  /// </summary>
  TFileFieldLayout = record
    YOffset: Integer;   // byte offset of Y field inside record
    XOffset: Integer;   // byte offset of X field inside record
    YSize: Integer;     // byte size of Y field (typically SizeOf(Single))
    XSize: Integer;     // byte size of one X element (for arrays = element size)
    XCount: Integer;    // for arrays, else 1
    XType: Integer;     // parser type id (TPars) for array element conversion
    YVarType: Integer;  // VarType used to convert Y raw bytes to Single
    XVarType: Integer;  // VarType used to convert X raw bytes to Single
    YFieldNo: Integer;  // TField.FieldNo in the dataset (1 = ID/record number)
    XFieldNo: Integer;  // TField.FieldNo in the dataset (1 = ID/record number)
    RecordLength: Integer;
  end;

  {$ENDREGION}

  {$REGION 'Base virtual data reader'}

  /// <summary>
  /// Common non-generic base for both line and wave virtual readers.
  /// Holds the Y index and the per-record cache but does not depend on a generic X type.
  /// </summary>
  TVirtualDataReaderBase = class abstract(TInterfacedObject)
  private
    FCacheLock: TCriticalSection;
    FRecordCount: Integer;
    FFieldLayout: TFileFieldLayout;
    FCurrentDataSet: TDataSet;
    FLastWindow: TVirtualDataWindow;
    function GetRecordCount(const DataSet: TDataSet): Integer;
    function BuildLayout(const DataSet: TDataSet): Boolean;
  public
    procedure Invalidate; virtual;
  protected
//    function ReadYAtIndex(const DataSet: TDataSet; RecNo: Integer; out Y: Single): Boolean; virtual;
    property FieldLayout: TFileFieldLayout read FFieldLayout;
    property CurrentDataSet: TDataSet read FCurrentDataSet;
    property RecordCount: Integer read FRecordCount;
    property LastWindow: TVirtualDataWindow read FLastWindow;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'Line reader / cache'}

  /// <summary>
  /// Cache for line data records keyed by record number.
  /// </summary>
  TLineRecordCache = TDictionary<Integer, TLineRecord>;

  TLineVirtualDataReader = class abstract(TVirtualDataReaderBase)
  private
    FCache: TLineRecordCache;
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; virtual; abstract;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Invalidate; override;
    function GetWindow(const DataSet: TDataSet; const AWindow: TVirtualDataWindow): TArray<TLineRecord>;
  end;

  TBinaryLineVirtualDataReader = class(TLineVirtualDataReader)
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; override;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; override;
  end;

  TDataSetLineVirtualDataReader = class(TLineVirtualDataReader)
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; override;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean; override;
  end;

  {$ENDREGION}

  {$REGION 'Wave reader / cache'}

  /// <summary>
  /// Cache for wave data records keyed by record number.
  /// </summary>
  TWaveRecordCache = TDictionary<Integer, TWaveRecord>;

  TWaveVirtualDataReader = class abstract(TVirtualDataReaderBase)
  private
    FCache: TWaveRecordCache;
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; virtual; abstract;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Invalidate; override;
    function GetWindow(const DataSet: TDataSet; const AWindow: TVirtualDataWindow): TArray<TWaveRecord>;
    function ReadRecord(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
  end;

  TBinaryWaveVirtualDataReader = class(TWaveVirtualDataReader)
  private
    FDelta: Single;
    FScale: Single;
    FEnumFunc: TAsTypeFunction<Integer>;
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; override;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; override;
  public
    procedure SetWaveTransform(Delta, Scale: Single); virtual;
    property Delta: Single read FDelta;
    property Scale: Single read FScale;
  end;

  TDataSetWaveVirtualDataReader = class(TWaveVirtualDataReader)
  private
    FDelta: Single;
    FScale: Single;
  protected
    function ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; override;
    function ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean; override;
  public
    procedure SetWaveTransform(Delta, Scale: Single); virtual;
    property Delta: Single read FDelta;
    property Scale: Single read FScale;
  end;

  {$ENDREGION}

  {$REGION 'Reader factory'}

  TVirtualDataReaderFactory = class
  public
    class function CreateLineReader(const DataSet: TDataSet): TLineVirtualDataReader;
    class function CreateWaveReader(const DataSet: TDataSet): TWaveVirtualDataReader;
  end;

  {$ENDREGION}

implementation

{$REGION 'Helpers'}

function ReadBufferAsSingle(const P: PByte; const VarType: Integer): Single; overload; forward;

function DBFieldTypeToVarType(const FT: TFieldType): Integer;
begin
  case FT of
    ftByte:      Result := varByte;
    ftShortint:  Result := varShortInt;
    ftSmallint:  Result := varSmallint;
    ftWord:      Result := varWord;
    ftInteger:   Result := varInteger;
    ftLongWord:  Result := varLongWord;
    ftFloat:     Result := varDouble;
    ftSingle:    Result := varSingle;
    ftCurrency:  Result := varCurrency;
    ftDate:      Result := varDate;
    ftDateTime:  Result := varDate;
    ftString:    Result := varString;
    ftWideString:Result := varOleStr;
    ftBlob:      Result := varByte;
  else
    Result := varSingle; // fallback
  end;
end;

function ReadBufferAsSingle(const Buffer: TValueBuffer; const VarType: Integer): Single; overload;
begin
  if Length(Buffer) = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := ReadBufferAsSingle(@Buffer[0], VarType);
end;

function ReadBufferAsSingle(const P: PByte; const VarType: Integer): Single; overload;
begin
  case VarType of
    varDouble, varDate:
      Result := PDouble(P)^;
    varSingle:   Result := PSingle(P)^;
    varInteger:  Result := PInteger(P)^;
    varSmallint: Result := PSmallInt(P)^;
    varShortInt: Result := PShortInt(P)^;
    varByte:     Result := PByte(P)^;
    varWord:     Result := PWord(P)^;
    varLongWord: Result := PLongWord(P)^;
    varInt64:    Result := PInt64(P)^;
    varUInt64:   Result := PUInt64(P)^;
    varCurrency: Result := PCurrency(P)^;
  else
    Result := 0;
  end;
end;

{$ENDREGION}

{$REGION 'TVirtualDataWindow'}

function TVirtualDataWindow.IsEmpty: Boolean;
begin
  Result := (YFrom = YTo) or (RecordFrom < 0) or (RecordTo < RecordFrom);
end;

function TVirtualDataWindow.Contains(Y: Double): Boolean;
begin
  Result := (Y >= YFrom) and (Y <= YTo);
end;

{$ENDREGION}

{$REGION 'TVirtualDataReaderBase'}

constructor TVirtualDataReaderBase.Create;
begin
  inherited;
  FCacheLock := TCriticalSection.Create;
  FRecordCount := -1;
  FCurrentDataSet := nil;
  FillChar(FFieldLayout, SizeOf(FFieldLayout), 0);
end;

destructor TVirtualDataReaderBase.Destroy;
begin
  FCacheLock.Free;
  inherited;
end;

procedure TVirtualDataReaderBase.Invalidate;
begin
  FRecordCount := -1;
  FCurrentDataSet := nil;
  FillChar(FFieldLayout, SizeOf(FFieldLayout), 0);
end;

function TVirtualDataReaderBase.GetRecordCount(const DataSet: TDataSet): Integer;
begin
  if (FCurrentDataSet <> DataSet) or (FRecordCount < 0) then
  begin
    Result := DataSet.RecordCount;
    FRecordCount := Result;
    FCurrentDataSet := DataSet;
  end
  else
    Result := FRecordCount;
end;

function TVirtualDataReaderBase.BuildLayout(const DataSet: TDataSet): Boolean;
var
  FDS: TFileDataSet;
  FYDef, FXDef: TFileFieldDef;
  YField, XField: TField;
  YName, XName: string;
  YVT, XVT: Integer;
begin
  Result := False;
  if not (DataSet is TFileDataSet) then Exit;
  FDS := TFileDataSet(DataSet);

  YName := FYParamName;
  XName := FXParamName;
  YField := DataSet.FindField(YName);
  XField := DataSet.FindField(XName);
  if not Assigned(YField) or not Assigned(XField) then Exit;

  FYDef := FDS.FindFieldDef(YField.FullName);
  FXDef := FDS.FindFieldDef(XField.FullName);
  if not Assigned(FYDef) or not Assigned(FXDef) then Exit;

  FFieldLayout.RecordLength := FDS.RecordLength;
  FFieldLayout.YOffset := FYDef.DataOffset;
  FFieldLayout.XOffset := FXDef.DataOffset;
  FFieldLayout.YFieldNo := YField.FieldNo;
  FFieldLayout.XFieldNo := XField.FieldNo;

  if FYDef.ArraySize > 0 then
  begin
    YVT := FYDef.ArrayType;
    FFieldLayout.YSize := TPars.VarTypeToLength(YVT);
  end
  else
  begin
    YVT := DBFieldTypeToVarType(YField.DataType);
    FFieldLayout.YSize := YField.DataSize;
  end;
  FFieldLayout.YVarType := YVT;

  if FXDef.ArraySize > 0 then
  begin
    XVT := FXDef.ArrayType;
    FFieldLayout.XSize := TPars.VarTypeToLength(XVT);
    FFieldLayout.XCount := FXDef.ArraySize;
    FFieldLayout.XType := XVT;
  end
  else
  begin
    XVT := DBFieldTypeToVarType(XField.DataType);
    FFieldLayout.XSize := XField.DataSize;
    FFieldLayout.XCount := 1;
    FFieldLayout.XType := XVT;
  end;
  FFieldLayout.XVarType := XVT;

  Result := (FFieldLayout.YSize > 0) and (FFieldLayout.XSize > 0);
end;

{$ENDREGION}

{$REGION 'TVirtualDataReaderBase'}

{$ENDREGION}

{$REGION 'TLineVirtualDataReader'}

constructor TLineVirtualDataReader.Create;
begin
  inherited;
  FCache := TLineRecordCache.Create;
end;

destructor TLineVirtualDataReader.Destroy;
begin
  FCache.Free;
  inherited;
end;

procedure TLineVirtualDataReader.Invalidate;
begin
  inherited;
  FCache.Clear;
end;

function TLineVirtualDataReader.GetWindow(const DataSet: TDataSet; const AWindow: TVirtualDataWindow): TArray<TLineRecord>;
var
  i, Cnt, RecFrom, RecTo, Capacity: Integer;
  Rec: TLineRecord;
  LocalCache: TLineRecordCache;
  Res: TArray<TLineRecord>;
begin
  Result := nil;
  if AWindow.IsEmpty or not Assigned(DataSet) then Exit;

  if FCurrentDataSet <> DataSet then
    Invalidate;

  FCurrentDataSet := DataSet;
  GetRecordCount(DataSet);

  RecFrom := Max(0, AWindow.RecordFrom - 2);
  RecTo := Min(FRecordCount - 1, AWindow.RecordTo + 2);
  if RecFrom > RecTo then Exit;

  Cnt := RecTo - RecFrom + 1;
  SetLength(Res, Cnt);
  Capacity := 0;

  FCacheLock.Enter;
  try
    LocalCache := TLineRecordCache.Create(FCache);
  finally
    FCacheLock.Leave;
  end;

  try
    for i := RecFrom to RecTo do
    begin
      if not LocalCache.TryGetValue(i, Rec) then
      begin
        if ReadRecordDirect(DataSet, i, Rec) then
        begin
          FCacheLock.Enter;
          try
            FCache.AddOrSetValue(i, Rec);
          finally
            FCacheLock.Leave;
          end;
        end;
      end;
      if not IsNaN(Rec.Y) then
      begin
        Res[Capacity] := Rec;
        Inc(Capacity);
      end;
    end;
  finally
    LocalCache.Free;
  end;

  SetLength(Res, Capacity);
  Result := Res;
  FLastWindow := AWindow;
end;

{$ENDREGION}

{$REGION 'TBinaryLineVirtualDataReader'}

function TBinaryLineVirtualDataReader.ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean;
var
  FDS: TFileDataSet;
  P: PByte;
  ReadBytes: Integer;
  Offset: Int64;
  HasLayout: Boolean;
  function LayoutReady: Boolean;
  begin
    if FFieldLayout.RecordLength = 0 then
      HasLayout := BuildLayout(DataSet)
    else
      HasLayout := True;
    Result := HasLayout;
  end;
begin
  HasLayout := False;
  Result := False;
  if not (DataSet is TFileDataSet) then Exit;
  if not LayoutReady then Exit;

  FDS := TFileDataSet(DataSet);
  Offset := Int64(RecNo) * Int64(FFieldLayout.RecordLength);
  FDS.FileData.Lock;
  try
    ReadBytes := FDS.FileData.Read(FFieldLayout.RecordLength, Pointer(P), Offset);
    if ReadBytes < FFieldLayout.RecordLength then Exit;

    if FFieldLayout.YFieldNo = 1 then
      Rec.Y := RecNo + 1
    else
      Rec.Y := ReadBufferAsSingle(P + FFieldLayout.YOffset, FFieldLayout.YVarType);

    if FFieldLayout.XFieldNo = 1 then
      Rec.X := RecNo + 1
    else
      Rec.X := ReadBufferAsSingle(P + FFieldLayout.XOffset, FFieldLayout.XVarType);

    Result := True;
  finally
    FDS.FileData.UnLock;
  end;
end;

function TBinaryLineVirtualDataReader.ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean;
var
  FDS: TFileDataSet;
  YField, XField: TField;
  YData, XData: TValueBuffer;
  YName, XName: string;
  HasLayout: Boolean;
  function LayoutReady: Boolean;
  begin
    if FFieldLayout.RecordLength = 0 then
      HasLayout := BuildLayout(DataSet)
    else
      HasLayout := True;
    Result := HasLayout;
  end;
begin
  HasLayout := False;
  Result := False;
  if not (DataSet is TFileDataSet) then Exit;
  if not LayoutReady then Exit;

  FDS := TFileDataSet(DataSet);
  YName := FYParamName;
  XName := FXParamName;
  YField := DataSet.FindField(YName);
  XField := DataSet.FindField(XName);
  if not Assigned(YField) or not Assigned(XField) then Exit;

  DataSet.Active := True;
  DataSet.RecNo := RecNo + 1;

  if FDS.GetFieldData(YField, YData) and FDS.GetFieldData(XField, XData) then
  begin
    Rec.Y := ReadBufferAsSingle(YData, DBFieldTypeToVarType(YField.DataType));
    Rec.X := ReadBufferAsSingle(XData, DBFieldTypeToVarType(XField.DataType));
    Result := True;
  end;
end;

{$ENDREGION}

{$REGION 'TDataSetLineVirtualDataReader'}

function TDataSetLineVirtualDataReader.ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean;
begin
  Result := ReadRecordViaDataSet(DataSet, RecNo, Rec);
end;

function TDataSetLineVirtualDataReader.ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TLineRecord): Boolean;
var
  YField, XField: TField;
  YData, XData: TValueBuffer;
  YName, XName: string;
  FDS: TFileDataSet;
  XDef: TFileFieldDef;
begin
  Result := False;
  YName := FYParamName;
  XName := FXParamName;
  YField := DataSet.FindField(YName);
  XField := DataSet.FindField(XName);
  if not Assigned(YField) or not Assigned(XField) then Exit;

  DataSet.Active := True;
  DataSet.DisableControls;
  try
    DataSet.RecNo := RecNo + 1;
    if not DataSet.GetFieldData(YField, YData) then Exit;
    Rec.Y := ReadBufferAsSingle(YData, DBFieldTypeToVarType(YField.DataType));

    if DataSet is TFileDataSet then
    begin
      FDS := TFileDataSet(DataSet);
      XDef := FDS.FindFieldDef(XField.FullName);
      if (XDef <> nil) and (XDef.ArraySize > 1) then
      begin
        // Wave-like array on a line field: take first element as line value.
        DataSet.GetFieldData(XField, XData);
        Rec.X := ReadBufferAsSingle(XData, XDef.ArrayType);
      end
      else if FDS.GetFieldData(XField, XData) then
        Rec.X := ReadBufferAsSingle(XData, DBFieldTypeToVarType(XField.DataType))
      else
        Rec.X := 0;
    end
    else
    begin
      if DataSet.GetFieldData(XField, XData) then
        Rec.X := ReadBufferAsSingle(XData, DBFieldTypeToVarType(XField.DataType))
      else
        Rec.X := 0;
    end;
    Result := True;
  finally
    DataSet.EnableControls;
  end;
end;

{$ENDREGION}

{$REGION 'TWaveVirtualDataReader'}

constructor TWaveVirtualDataReader.Create;
begin
  inherited;
  FCache := TWaveRecordCache.Create;
end;

destructor TWaveVirtualDataReader.Destroy;
begin
  FCache.Free;
  inherited;
end;

procedure TWaveVirtualDataReader.Invalidate;
begin
  inherited;
  FCache.Clear;
end;

function TWaveVirtualDataReader.ReadRecord(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
begin
  Result := ReadRecordDirect(DataSet, RecNo, Rec);
end;

function TWaveVirtualDataReader.GetWindow(const DataSet: TDataSet; const AWindow: TVirtualDataWindow): TArray<TWaveRecord>;
var
  i, Cnt, RecFrom, RecTo, Capacity: Integer;
  Rec: TWaveRecord;
  LocalCache: TWaveRecordCache;
  Res: TArray<TWaveRecord>;
begin
  Result := nil;
  if AWindow.IsEmpty or not Assigned(DataSet) then Exit;

  if not Assigned(FCurrentDataSet) or (FCurrentDataSet <> DataSet) then
    Invalidate;

  FCurrentDataSet := DataSet;
  GetRecordCount(DataSet);

  RecFrom := Max(0, AWindow.RecordFrom - 2);
  RecTo := Min(FRecordCount - 1, AWindow.RecordTo + 2);
  if RecFrom > RecTo then Exit;

  Cnt := RecTo - RecFrom + 1;
  SetLength(Res, Cnt);
  Capacity := 0;

  FCacheLock.Enter;
  try
    LocalCache := TWaveRecordCache.Create(FCache);
  finally
    FCacheLock.Leave;
  end;

  try
    for i := RecFrom to RecTo do
    begin
      if not LocalCache.TryGetValue(i, Rec) then
      begin
        if ReadRecordDirect(DataSet, i, Rec) then
        begin
          FCacheLock.Enter;
          try
            FCache.AddOrSetValue(i, Rec);
          finally
            FCacheLock.Leave;
          end;
        end;
      end;
      if not IsNaN(Rec.Y) then
      begin
        Res[Capacity] := Rec;
        Inc(Capacity);
      end;
    end;
  finally
    LocalCache.Free;
  end;

  SetLength(Res, Capacity);
  Result := Res;
  FLastWindow := AWindow;
end;

{$ENDREGION}

{$REGION 'TBinaryWaveVirtualDataReader'}

procedure TBinaryWaveVirtualDataReader.SetWaveTransform(Delta, Scale: Single);
begin
  FDelta := Delta;
  FScale := Scale;
  Invalidate;
end;

function TBinaryWaveVirtualDataReader.ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
var
  FDS: TFileDataSet;
  P: PByte;
  ReadBytes: Integer;
  Offset: Int64;
  Src: Pointer;
  i, Val: Integer;
  HasLayout: Boolean;
  function LayoutReady: Boolean;
  begin
    if FFieldLayout.RecordLength = 0 then
      HasLayout := BuildLayout(DataSet)
    else
      HasLayout := True;
    Result := HasLayout;
  end;
begin
  HasLayout := False;
  Result := False;
  if not (DataSet is TFileDataSet) then Exit;
  if not LayoutReady then Exit;

  if FFieldLayout.XType <> 0 then
    FEnumFunc := TPars.GetAsTypeFunction(FFieldLayout.XType);
  if not Assigned(FEnumFunc) then Exit;

  FDS := TFileDataSet(DataSet);
  Offset := Int64(RecNo) * Int64(FFieldLayout.RecordLength);
  FDS.FileData.Lock;
  try
    ReadBytes := FDS.FileData.Read(FFieldLayout.RecordLength, Pointer(P), Offset);
    if ReadBytes < FFieldLayout.RecordLength then Exit;
    if FFieldLayout.YFieldNo = 1 then
      Rec.Y := RecNo + 1
    else
      Rec.Y := ReadBufferAsSingle(P + FFieldLayout.YOffset, FFieldLayout.YVarType);

    SetLength(Rec.X, FFieldLayout.XCount);
    Src := P + FFieldLayout.XOffset;
    for i := 0 to FFieldLayout.XCount - 1 do
    begin
      Val := Round((FEnumFunc(Src) + FDelta) * FScale);
      if Val < ShortInt.MinValue then Val := ShortInt.MinValue
      else if Val > ShortInt.MaxValue then Val := ShortInt.MaxValue;
      Rec.X[i] := ShortInt(Val);
      //Inc(PByte(Src), FFieldLayout.XSize);
    end;
    Result := True;
  finally
    FDS.FileData.UnLock;
  end;
end;

function TBinaryWaveVirtualDataReader.ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
var
  FDS: TFileDataSet;
  YField, XField: TField;
  YData, Raw: TValueBuffer;
  YName, XName: string;
  HasLayout: Boolean;
  XDef: TFileFieldDef;
  P: Pointer;
  i, Val, XSize: Integer;
  EnumFunc: TAsTypeFunction<Integer>;
  function LayoutReady: Boolean;
  begin
    if FFieldLayout.RecordLength = 0 then
      HasLayout := BuildLayout(DataSet)
    else
      HasLayout := True;
    Result := HasLayout;
  end;
begin
  HasLayout := False;
  Result := False;
  if not (DataSet is TFileDataSet) then Exit;
  if not LayoutReady then Exit;

  FDS := TFileDataSet(DataSet);
  YName := FYParamName;
  XName := FXParamName;
  YField := DataSet.FindField(YName);
  XField := DataSet.FindField(XName);
  if not Assigned(YField) or not Assigned(XField) then Exit;

  DataSet.Active := True;
  DataSet.RecNo := RecNo + 1;

  if not FDS.GetFieldData(YField, YData) then Exit;
  Rec.Y := ReadBufferAsSingle(YData, DBFieldTypeToVarType(YField.DataType));

  XDef := FDS.FindFieldDef(XField.FullName);
  if not Assigned(XDef) or (XDef.ArraySize <= 0) then Exit;

  XSize := TPars.VarTypeToLength(XDef.ArrayType);
  EnumFunc := TPars.GetAsTypeFunction(XDef.ArrayType);
  if not Assigned(EnumFunc) then Exit;

  FDS.GetFieldData(XField, Raw);
  P := PPointer(@Raw[0])^;
  SetLength(Rec.X, XDef.ArraySize);
  for i := 0 to XDef.ArraySize - 1 do
  begin
    Val := Round((EnumFunc(P) + FDelta) * FScale);
    if Val < ShortInt.MinValue then Val := ShortInt.MinValue
    else if Val > ShortInt.MaxValue then Val := ShortInt.MaxValue;
    Rec.X[i] := ShortInt(Val);
  end;
  Result := True;
end;

{$ENDREGION}

{$REGION 'TDataSetWaveVirtualDataReader'}

procedure TDataSetWaveVirtualDataReader.SetWaveTransform(Delta, Scale: Single);
begin
  FDelta := Delta;
  FScale := Scale;
  Invalidate;
end;

function TDataSetWaveVirtualDataReader.ReadRecordDirect(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
begin
  Result := ReadRecordViaDataSet(DataSet, RecNo, Rec);
end;

function TDataSetWaveVirtualDataReader.ReadRecordViaDataSet(const DataSet: TDataSet; RecNo: Integer; out Rec: TWaveRecord): Boolean;
var
  YField, XField: TField;
  YData, Raw: TValueBuffer;
  YName, XName: string;
  FDS: TFileDataSet;
  XDef: TFileFieldDef;
  P: Pointer;
  i, Val, XSize: Integer;
  EnumFunc: TAsTypeFunction<Integer>;
begin
  Result := False;
  YName := FYParamName;
  XName := FXParamName;
  YField := DataSet.FindField(YName);
  XField := DataSet.FindField(XName);
  if not Assigned(YField) or not Assigned(XField) then Exit;

  DataSet.Active := True;
  DataSet.DisableControls;
  try
    DataSet.RecNo := RecNo + 1;
    if not DataSet.GetFieldData(YField, YData) then Exit;
    Rec.Y := ReadBufferAsSingle(YData, DBFieldTypeToVarType(YField.DataType));

    if DataSet is TFileDataSet then
    begin
      FDS := TFileDataSet(DataSet);
      XDef := FDS.FindFieldDef(XField.FullName);
      if not Assigned(XDef) or (XDef.ArraySize <= 0) then Exit;
      XSize := TPars.VarTypeToLength(XDef.ArrayType);
      EnumFunc := TPars.GetAsTypeFunction(XDef.ArrayType);
      if not Assigned(EnumFunc) then Exit;
      FDS.GetFieldData(XField, Raw);
      P := PPointer(@Raw[0])^;
      SetLength(Rec.X, XDef.ArraySize);
      for i := 0 to XDef.ArraySize - 1 do
      begin
        Val := Round((EnumFunc(P) + FDelta) * FScale);
        if Val < ShortInt.MinValue then Val := ShortInt.MinValue
        else if Val > ShortInt.MaxValue then Val := ShortInt.MaxValue;
        Rec.X[i] := ShortInt(Val);
      end;
    end
    else
    begin
      // Generic dataset: read X as raw buffer; cannot scale without type info.
      DataSet.GetFieldData(XField, Raw);
      SetLength(Rec.X, Length(Raw));
      if Length(Raw) > 0 then
        Move(Raw[0], Rec.X[0], Length(Raw));
    end;
    Result := True;
  finally
    DataSet.EnableControls;
  end;
end;

{$ENDREGION}

{$REGION 'TVirtualDataReaderFactory'}

class function TVirtualDataReaderFactory.CreateLineReader(const DataSet: TDataSet): TLineVirtualDataReader;
begin
  if DataSet is TFileDataSet then
    Result := TBinaryLineVirtualDataReader.Create
  else
    Result := TDataSetLineVirtualDataReader.Create;
end;

class function TVirtualDataReaderFactory.CreateWaveReader(const DataSet: TDataSet): TWaveVirtualDataReader;
begin
  if DataSet is TFileDataSet then
    Result := TBinaryWaveVirtualDataReader.Create
  else
    Result := TDataSetWaveVirtualDataReader.Create;
end;

{$ENDREGION}

{$REGION 'FYParamName / FXParamName helpers'}

threadvar
  GVirtualYParamName: string;
  GVirtualXParamName: string;

function FYParamName: string;
begin
  Result := GVirtualYParamName;
end;

function FXParamName: string;
begin
  Result := GVirtualXParamName;
end;

procedure SetVirtualParamNames(const YName, XName: string);
begin
  GVirtualYParamName := YName;
  GVirtualXParamName := XName;
end;

{$ENDREGION}

end.
