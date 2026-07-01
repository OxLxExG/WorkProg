unit Plot.VirtualDataLink;

interface

{$INCLUDE global.inc}

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  Data.DB, DataSetIntf, IDataSets, FileDataSet, CustomPlot.DataLink, CustomPlot,
  Plot.VirtualData, Parser, ExtendIntf, Container, debug_except, tools;

type
  {$REGION 'Virtual DataLink interfaces'}

  TAddpointEvent<T> = Reference to procedure(Y: Single; const X: T);

  IVirtualLineDataLink = interface(IDataLinkBuffer)
    ['{437AAA7B-C3CD-4D30-8A75-4CD745EB8BB3}']
    procedure Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<Single>);
  end;

  IVirtualWaveDataLink = interface(IDataLinkBuffer)
    ['{D9EA754D-F43C-4029-A05F-F6008EFB3052}']
    function GetArrayCount: Integer;
    function GetRecordCount: Integer;
    procedure Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); overload;
    procedure Read(YFrom, Yto: Single; Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); overload;
    property ArrayCount: Integer read GetArrayCount;
    property RecordCount: Integer read GetRecordCount;
  end;

  {$ENDREGION}

  {$REGION 'TVirtualDataLink'}

  /// <summary>
  /// Base class for virtualized DataLink implementations. Inherits from TCustomDataLinkBuffer
  /// so it keeps the IDataLinkBuffer contract (DrowMemoryBuffer etc.) without using a
  /// temporary file. Heavy work is performed in a background thread using the
  /// TVirtualDataReader cache.
  /// </summary>
  TVirtualDataLink = class abstract(TCustomDataLinkBuffer)
  private
    FReaderBase: TVirtualDataReaderBase;
    FReaderLock: TCriticalSection;
    FLastYFrom: Single;
    FLastYTo: Single;
  protected
  function GetArrayCount: Integer; virtual;
  function GetRecordCount: Integer; virtual;
  function CreateReader: TVirtualDataReaderBase; virtual; abstract;
  procedure DoRead(YFrom, YTo: Single; AddpointEvent: TAddpointEvent<Single>); virtual;
  public
    constructor Create(AOwner: TObject); override;
    destructor Destroy; override;
    procedure Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<Single>); virtual;
    procedure ResetBuffer; override;
  end;

  {$ENDREGION}

  {$REGION 'Line and Wave implementations'}

  TVirtualLineDataLink = class(TVirtualDataLink, IVirtualLineDataLink)
  protected
    function CreateReader: TVirtualDataReaderBase; override;
    function GetReader: TLineVirtualDataReader;
  end;

  TVirtualWaveDataLink = class(TVirtualDataLink, IVirtualWaveDataLink)
  private
    FArrayCount: Integer;
    FRecordCount: Integer;
    FDelta: Single;
    FScale: Single;
    function GetReader: TWaveVirtualDataReader;
  protected
    function GetArrayCount: Integer; override;
    function GetRecordCount: Integer; override;
    function CreateReader: TVirtualDataReaderBase; override;
  public
    procedure Read(YFrom, Yto: Single; Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); reintroduce; overload; virtual;
    procedure Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); reintroduce; overload; virtual;
    procedure ResetBuffer; override;
  end;

  {$ENDREGION}

implementation

{$REGION 'TVirtualDataLink'}

constructor TVirtualDataLink.Create(AOwner: TObject);
begin
  inherited;
  FReaderLock := TCriticalSection.Create;
  FLastYFrom := NaN;
  FLastYTo := NaN;
end;

destructor TVirtualDataLink.Destroy;
begin
  FReaderBase.Free;
  FReaderLock.Free;
  inherited;
end;

function TVirtualDataLink.GetArrayCount: Integer;
var
  FDS: TFileDataSet;
  XDef: TFileFieldDef;
  XF: TField;
begin
  Result := 0;
  if DataSet is TFileDataSet then
  begin
    FDS := TFileDataSet(DataSet);
    XF := FieldX;
    if Assigned(XF) then
    begin
      XDef := FDS.FindFieldDef(XF.FullName);
      if Assigned(XDef) then
        Result := XDef.ArraySize;
    end;
  end;
end;

function TVirtualDataLink.GetRecordCount: Integer;
begin
  DataSet.Active := True;
  Result := DataSet.RecordCount;
end;

procedure TVirtualDataLink.DoRead(YFrom, YTo: Single; AddpointEvent: TAddpointEvent<Single>);
var
  d: TDataSet;
  Yfirst, Ylast, dy: Double;
  RecFrom, RecTo, i, Cnt: Integer;
  Window: TVirtualDataWindow;
  Records: TArray<TLineRecord>;
  Rec: TLineRecord;
  LocalReader: TLineVirtualDataReader;
  LocalYField: TField;
  YName, XName: string;
  function EstimateRange: Boolean;
  var
    RecLow, RecHigh, TmpI: Integer;
  begin
    d.RecNo := 1;
    Yfirst := LocalYField.AsFloat;
    d.RecNo := d.RecordCount;
    Ylast := LocalYField.AsFloat;
    Result := True;
    if Ylast > Yfirst then
    begin
      dy := (Ylast - Yfirst) / Max(1, d.RecordCount - 1);
      RecFrom := Floor((Min(YFrom, YTo) - Yfirst) / dy) - 2;
      RecTo := Ceil((Max(YFrom, YTo) - Yfirst) / dy) + 2;
    end
    else if Ylast < Yfirst then
    begin
      dy := (Yfirst - Ylast) / Max(1, d.RecordCount - 1);
      RecFrom := Floor((Yfirst - Max(YFrom, YTo)) / dy) - 2;
      RecTo := Ceil((Yfirst - Min(YFrom, YTo)) / dy) + 2;
    end
    else
    begin
      RecFrom := 0;
      RecTo := d.RecordCount - 1;
    end;
    RecLow := Min(0, d.RecordCount - 1);
    RecHigh := Max(0, d.RecordCount - 1);
    RecFrom := Max(RecLow, RecFrom);
    RecTo := Min(RecHigh, RecTo);
    if RecFrom > RecTo then
    begin
      TmpI := RecFrom;
      RecFrom := RecTo;
      RecTo := TmpI;
    end;
  end;

begin
  d := DataSet;
  if not Assigned(d) then Exit;
  d.Active := True;
  if d.RecordCount = 0 then Exit;

  LocalYField := FieldY;
  if not Assigned(LocalYField) then Exit;
  YName := LocalYField.FullName;
  XName := '';
  if Assigned(FieldX) then
    XName := FieldX.FullName;

  FReaderLock.Enter;
  try
    if not Assigned(FReaderBase) then
      FReaderBase := CreateReader;
    LocalReader := TLineVirtualDataReader(FReaderBase);
  finally
    FReaderLock.Leave;
  end;

  if not EstimateRange then Exit;

  Window.YFrom := Min(YFrom, YTo);
  Window.YTo := Max(YFrom, YTo);
  Window.RecordFrom := RecFrom;
  Window.RecordTo := RecTo;
  Window.ScreenHeightPx := 0;

  try
    SetVirtualParamNames(YName, XName);
    Records := LocalReader.GetWindow(d, Window);
    Cnt := Length(Records);
    for i := 0 to Cnt - 1 do
    begin
      Rec := Records[i];
      AddpointEvent(Rec.Y, Rec.X);
    end;
  except
    on E: Exception do
    begin
      TDebug.DoException(E);
      raise;
    end;
  end;
end;

procedure TVirtualDataLink.Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<Single>);
begin
  FLastYFrom := YFrom;
  FLastYTo := Yto;
  DoRead(YFrom, Yto, AddpointEvent);
end;

procedure TVirtualDataLink.ResetBuffer;
begin
  inherited;
  FReaderLock.Enter;
  try
    if Assigned(FReaderBase) then
      FReaderBase.Invalidate;
  finally
    FReaderLock.Leave;
  end;
  FieldY := nil;
  FieldX := nil;
  FLastYFrom := NaN;
  FLastYTo := NaN;
end;

{$ENDREGION}

{$REGION 'Line / Wave implementations'}

function TVirtualLineDataLink.CreateReader: TVirtualDataReaderBase;
begin
  Result := TVirtualDataReaderFactory.CreateLineReader(DataSet);
end;

function TVirtualLineDataLink.GetReader: TLineVirtualDataReader;
begin
  Result := TLineVirtualDataReader(FReaderBase);
end;

function TVirtualWaveDataLink.CreateReader: TVirtualDataReaderBase;
begin
  Result := TVirtualDataReaderFactory.CreateWaveReader(DataSet);
end;

function TVirtualWaveDataLink.GetReader: TWaveVirtualDataReader;
begin
  Result := TWaveVirtualDataReader(FReaderBase);
end;

function TVirtualWaveDataLink.GetArrayCount: Integer;
var
  FDS: TFileDataSet;
  XDef: TFileFieldDef;
  XF: TField;
begin
  if FArrayCount = 0 then
  begin
    if DataSet is TFileDataSet then
    begin
      FDS := TFileDataSet(DataSet);
      XF := FieldX;
      if Assigned(XF) then
      begin
        XDef := FDS.FindFieldDef(XF.FullName);
        if Assigned(XDef) then
          FArrayCount := XDef.ArraySize;
      end;
    end;
    if FArrayCount = 0 then
      FArrayCount := inherited GetArrayCount;
  end;
  Result := FArrayCount;
end;

function TVirtualWaveDataLink.GetRecordCount: Integer;
begin
  if FRecordCount = 0 then
    FRecordCount := inherited GetRecordCount;
  Result := FRecordCount;
end;

procedure TVirtualWaveDataLink.Read(YFrom, Yto, Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);
var
  d: TDataSet;
  Yfirst, Ylast, dy: Double;
  RecFrom, RecTo, i, Cnt, Idx: Integer;
  YFind: Double;
  Window: TVirtualDataWindow;
  Records: TArray<TWaveRecord>;
  Rec: TWaveRecord;
  Reader: TWaveVirtualDataReader;
  LocalYField: TField;
  YName, XName: string;
  function EstimateRange: Boolean;
  var
    RecLow, RecHigh, TmpI: Integer;
  begin
    d.RecNo := 1;
    Yfirst := LocalYField.AsFloat;
    d.RecNo := d.RecordCount;
    Ylast := LocalYField.AsFloat;
    Result := True;
    if Ylast > Yfirst then
    begin
      dy := (Ylast - Yfirst) / Max(1, d.RecordCount - 1);
      RecFrom := Floor((Min(YFrom, YTo) - Yfirst) / dy) - 2;
      RecTo := Ceil((Max(YFrom, YTo) - Yfirst) / dy) + 2;
    end
    else if Ylast < Yfirst then
    begin
      dy := (Yfirst - Ylast) / Max(1, d.RecordCount - 1);
      RecFrom := Floor((Yfirst - Max(YFrom, YTo)) / dy) - 2;
      RecTo := Ceil((Yfirst - Min(YFrom, YTo)) / dy) + 2;
    end
    else
    begin
      RecFrom := 0;
      RecTo := d.RecordCount - 1;
    end;
    RecLow := Min(0, d.RecordCount - 1);
    RecHigh := Max(0, d.RecordCount - 1);
    RecFrom := Max(RecLow, RecFrom);
    RecTo := Min(RecHigh, RecTo);
    if RecFrom > RecTo then
    begin
      TmpI := RecFrom;
      RecFrom := RecTo;
      RecTo := TmpI;
    end;
  end;
begin
  d := DataSet;
  d.Active := True;
  LocalYField := FieldY;
  if not Assigned(LocalYField) then Exit;
  YName := LocalYField.FullName;
  XName := '';
  if Assigned(FieldX) then
    XName := FieldX.FullName;

  if (FDelta <> Delta) or (FScale <> Scale) then
  begin
    FDelta := Delta;
    FScale := Scale;
    ResetBuffer;
  end;

  if not Assigned(FReaderBase) then
    FReaderBase := CreateReader;
  Reader := GetReader;
  if Reader is TBinaryWaveVirtualDataReader then
    TBinaryWaveVirtualDataReader(Reader).SetWaveTransform(Delta, Scale);
  if Reader is TDataSetWaveVirtualDataReader then
    TDataSetWaveVirtualDataReader(Reader).SetWaveTransform(Delta, Scale);

  if d.RecordCount = 0 then Exit;

  try
    SetVirtualParamNames(YName, XName);
    if YFrom = YTo then
    begin
      // Single-record mode: find nearest Y and read only that record
      Idx := IndexOfY(YFrom, fndNear, YFind);
      if Idx >= 0 then
        if Reader.ReadRecord(d, Idx, Rec) then
          AddWaveEvent(Rec.Y, Rec.X);
      Exit;
    end;

    if not EstimateRange then Exit;

    Window.YFrom := Min(YFrom, YTo);
    Window.YTo := Max(YFrom, YTo);
    Window.RecordFrom := RecFrom;
    Window.RecordTo := RecTo;
    Window.ScreenHeightPx := 0;

    Records := Reader.GetWindow(d, Window);
    Cnt := Length(Records);
    for i := 0 to Cnt - 1 do
    begin
      Rec := Records[i];
      AddWaveEvent(Rec.Y, Rec.X);
    end;
  except
    on E: Exception do
    begin
      TDebug.DoException(E);
      raise;
    end;
  end;
end;

procedure TVirtualWaveDataLink.Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);
var
  YFrom, Yto: Single;
  d: TDataSet;
  YF: TField;
begin
  d := DataSet;
  d.Active := True;
  YF := FieldY;
  d.RecNo := 1;
  YFrom := YF.AsFloat;
  d.RecNo := d.RecordCount;
  Yto := YF.AsFloat;
  Read(YFrom, Yto, Delta, Scale, AddWaveEvent);
end;

procedure TVirtualWaveDataLink.ResetBuffer;
begin
  inherited;
  FArrayCount := 0;
  FRecordCount := 0;
  FDelta := 0;
  FScale := 1;
end;

{$ENDREGION}

initialization
  RegisterClasses([TVirtualLineDataLink, TVirtualWaveDataLink]);

end.
