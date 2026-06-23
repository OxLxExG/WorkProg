unit Plot.DataLink;

interface

uses IDataSets, Container,
     System.SysUtils, ExtendIntf, System.Rtti, System.TypInfo, Data.DB, System.Classes,  debug_except, DataSetIntf, FileDataSet,
     CustomPlot, LasDataSet, XMLDataSet, FileCachImpl, Parser, Winapi.ActiveX;

type
   TReadDataThread = class(TThread)
   private
     FProc: TProc;
   protected
     procedure Execute; override;
   public
     constructor Create(const AProc: TProc);
   end;

   TAddpointEvent<T> = Reference to procedure(Y: Single; const X: T);
   TDataLink<T> = class (TCustomDataLink)
   private
     FXFieldDef: TFileFieldDef;
     FBufferFileName: string;
     function GetBufferFileName: string;
     function GetXFieldDef: TFileFieldDef;
     function GetFieldY: Single;
    type
     TBufferPoint = record
       Y: Single;
       X: T;
     end;
     PFilePoint = ^TFilePoint;
     TFilePoint = record
       Y: Single;
       X: array [0..0] of Byte;
     end;
   protected
     Fids: IDataSet;
     Fevent: TAddpointEvent<T>;
     FfileTmpBuffer: TArray<Byte>;
     FFileData: IFileData;
     FbuffReady: Boolean;
     FYFrom, FYto: Single;
     Fbuff: TArray<TBufferPoint>;
     FInitBufThread: TThread;
     procedure ReadFromDB;
     procedure ReadFromMemBuffer;
     procedure InitMemBuffer(d: TDataSet; NeedInitFromFile: boolean = True);
     function FiendField(const Fullname: string): TField;
     procedure Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<T>);

     function FileRecLen: Integer; virtual;
     procedure InitBuffFromFile; virtual;
     procedure IniTmpFileBuffer(Y: Single; X: TField); virtual;
     function GetXValue(Fx: TField): T; virtual; abstract;
     procedure ResetBuffer; override;
   public
     property YValue: Single read GetFieldY;
     property XFieldDef: TFileFieldDef read GetXFieldDef;
   published
     property BufferFileName: string read GetBufferFileName write FBufferFileName;
   end;

  ILineDataLink = interface(IDataLink)
   ['{437AAA7B-C3CD-4D30-8A75-4CD745EB8BB3}']
    procedure Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<Single>);
  end;

   TlineDataLink = class(TDataLink<single>, ILineDataLink)
   public
     function GetXValue(Fx: TField): single; override;
   end;

  IWaveDataLink = interface(IDataLink)
   ['{D9EA754D-F43C-4029-A05F-F6008EFB3052}']
     function GetArrayCount: Integer;
     function GetRecordCount: Integer;
     procedure Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); overload;
     procedure Read(YFrom, Yto: Single; Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);overload;
     property ArrayCount: Integer read GetArrayCount;
     property RecordCount: Integer read GetRecordCount;
  end;

   TWaveDataLink = class(TDataLink<TArray<ShortInt>>, IWaveDataLink)
   private
     FFileRecLen: Integer;
     FDelta, FScale: Single;
     FEnumFunc: TAsTypeFunction<integer>;
     FArraySize: Integer;
     FArrayCount: Integer;
     FArrayType: Integer;
     FRecordCount: Integer;
     function GetArrayCount: Integer;
     function GetArraySize: Integer;
     function GetArrayType: Integer;
     function GetEnumFunc: TAsTypeFunction<integer>;
     function GetRecordCount: Integer;
   protected
     procedure ResetBuffer; override;
   public
     procedure Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>); overload;
     procedure Read(YFrom, Yto: Single; Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);overload;
     function FileRecLen: Integer; override;
     procedure InitBuffFromFile; override;
     procedure IniTmpFileBuffer(Y: Single; X: TField); override;
     function GetXValue(Fx: TField): TArray<ShortInt>; override;
     function GetShortIntData(var P: Pointer): ShortInt; inline;
     property EnumFunc: TAsTypeFunction<integer> read GetEnumFunc;
     property ArraySize: Integer read GetArraySize;
     property RecordCount: Integer read GetRecordCount write FRecordCount;
   published
     property ArrayType: Integer read GetArrayType write FArrayType;
     property ArrayCount: Integer read GetArrayCount write FArrayCount;
   end;

   TStringDataLink = class(TDataLink<string>)

   end;

implementation

{ TReadDataThread }

constructor TReadDataThread.Create(const AProc: TProc);
begin
  FProc := AProc;
  inherited Create(False);
end;

procedure TReadDataThread.Execute;
begin
  CoInitialize(nil);
  try
   FProc();
  finally
   CoUninitialize;
  end
end;

{$REGION 'TDataLink<T>'}

{ TDataLink<T> }

function TDataLink<T>.FileRecLen: Integer;
begin
  Result := SizeOf(TBufferPoint);
end;

procedure TDataLink<T>.IniTmpFileBuffer(Y: Single; X: TField);
begin
  PFilePoint(@FfileTmpBuffer[0]).Y := Y;
  PSingle(@PFilePoint(@FfileTmpBuffer[0]).X[0])^ := X.AsSingle;
end;

procedure TDataLink<T>.InitBuffFromFile;
 var
  p: Pointer;
begin
  FFileData.Read(FFileData.Size, p, 0);
  Move(P^, Fbuff[0], FFileData.Size);
end;

function TDataLink<T>.FiendField(const Fullname: string): TField;
 var
  i: Integer;
begin
  for i := 0 to DataSet.FieldList.Count-1 do
   begin
    if SameText(DataSet.FieldList[i].FullName, Fullname) then Exit(DataSet.FieldList[i]);
   end;
  raise Exception.CreateFmt('Поле %s ненайдено в %s', [Fullname, DataSet.Name]);
end;

function TDataLink<T>.GetBufferFileName: string;
begin
  if FBufferFileName = '' then FBufferFileName := GenerateBufferFileName;
  Result := FBufferFileName;
end;

function TDataLink<T>.GetFieldY: Single;
begin
//  if not Assigned(FFieldY) then
//   begin
//    FFieldY := FiendField(YParamPath);
//    FFieldX := FiendField(XParamPath);
//    SetLength(FfileTmpBuffer, FileRecLen);
//   end;
  Result := FieldY.AsSingle
end;

function TDataLink<T>.GetXFieldDef: TFileFieldDef;
begin
  if not Assigned(FXFieldDef) then FXFieldDef := TFileDataSet(DataSet).FindFieldDef(XParamPath);
  Result := FXFieldDef;
end;

procedure TDataLink<T>.InitMemBuffer(d: TDataSet; NeedInitFromFile: boolean = True);
 var
  i, Size: Integer;
  fx,fy: TField;
begin
  d.Active := True;
  fx := d.FieldByName(XParamPath);
  fy := d.FieldByName(YParamPath);
  Size := (d.RecordCount{+1}) * FileRecLen;  //  (d.RecordCount+1) ?????  надо разобраться!!!
  FFileData.Lock;
  try
    if FbuffReady then Exit;
    if FFileData.Size > Size then raise Exception.Create('Error Message FFileData.Size > d.RecordCount');
    SetLength(Fbuff, d.RecordCount);
    if FFileData.Size = 0 then
     begin
      d.First;
      i := 0;
     end
    else
     begin
      if NeedInitFromFile then InitBuffFromFile;
      if FFileData.Size = Size then
       begin
        FbuffReady := True;
        Exit;
       end;
      i := FFileData.Size div FileRecLen;
      d.RecNo := i+1;
     end;
     while (not d.Eof) do
      begin
//         Yield;
       Fbuff[i].X := GetXValue(FX);
       Fbuff[i].Y := FY.AsSingle;
       IniTmpFileBuffer(Fbuff[i].Y, fx);
       FFileData.Write(FileRecLen, @FfileTmpBuffer[0], -1, False);
       inc(i);
       d.Next;
      end;
    //TDebug.Log('FbuffReady := True;   %d   ',[FFileData.Size]);
    FbuffReady := True;
   finally
    d.Active := False;
    FFileData.UnLock;
   end;
end;

procedure TDataLink<T>.ReadFromMemBuffer;
 var
  y, Yfirst, dy: Single;
  RecNo: integer;
begin
  Yfirst := Fbuff[0].Y;
  dy := Fbuff[1].y - Fbuff[0].Y;
  if dy = 0 then dy := 1;
  RecNo := Round((FYFrom-Yfirst)/dy)-2;
  if RecNo < 0 then RecNo := 0;
  while (RecNo < Length(Fbuff)) and (Fbuff[RecNo].Y < FYFrom) do Inc(RecNo);
  if RecNo > 0 then Dec(RecNo);
  y := FYTo-1;
  while (RecNo < Length(Fbuff)) and (y < FYto) do
   begin
    Y:= Fbuff[RecNo].Y;
    Fevent(y, Fbuff[RecNo].X);
    Inc(RecNo);
   end;
end;

procedure TDataLink<T>.ResetBuffer;
begin
  FbuffReady := False;
end;

procedure TDataLink<T>.ReadFromDB;
 var
  d: TDataSet;
  b: TBookmark;
  y, Yfirst, dy: Single;
begin
  FFieldX := nil;
  FFieldY := nil;
  d := DataSet;
  b := d.Bookmark;
  d.Active := True;
  d.DisableControls;
  try
   d.First;
   Yfirst := YValue;
   d.Next;
   dy := YValue - Yfirst;
//  if d.RecordCount = 0 then Exit;
//   if dy = 0 then
//     raise EBaseException.CreateFmt('Error Message dy = 0 %f %s %s', [Yfirst, FieldY.FullName, FieldX.FullName]);

   d.RecNo := Round((FYFrom-Yfirst)/dy)-2;
   // доходим до начала экрана
   while (not d.Eof) and (YValue < FYFrom) do d.Next;
   // точка перед экраном
   d.prior;
   // доходим до конца экрана + точка
   y := FYTo-1;
   while (not d.Eof) and (y < FYto) do
    begin
     y := YValue;
     Fevent(y, GetXValue(FieldX));
     d.Next;
    end;
  finally
   d.EnableControls;
   d.Bookmark := b;
  end;
end;


procedure TDataLink<T>.Read(YFrom, Yto: Single; AddpointEvent: TAddpointEvent<T>);
const
  {$J+} tick: Cardinal = 0;{$J-}
 var
  th: TThread;
  ids: IDataSet;
begin
  if Length(FfileTmpBuffer) <> FileRecLen then SetLength(FfileTmpBuffer, FileRecLen);

  Fevent := AddpointEvent;
  FYFrom := YFrom;
  FYto := Yto;
  tick := TThread.GetTickCount;
 // ReadFromDB;
//  TDebug.Log('ReadFromDB %s %f, %f время счит %1.2f',[XFieldDef.FullName, YFrom, Yto, (TThread.GetTickCount- tick)/1000]);
//  Exit;
 //неработает если выбираешь несколько данных LAS проблемма с синхронизацией потоков появляются нулевые У в файле
  if not FbuffReady then
   begin
    if not Assigned(FFileData) then FFileData := GFileDataFactory.Factory(TFileData, BufferFileName);
    if FFileData.Size = DataSet.RecordCount*FileRecLen then
     begin
      th := TReadDataThread.Create(procedure
      begin
        FFileData.Lock;
        try
         try
         //Tdebug.Log('TmpBuff: %d, Rec*Len: %d', [FFileData.Size, DataSet.RecordCount*FileRecLen]);
         if FFileData.Size = DataSet.RecordCount*FileRecLen then
          begin
           SetLength(Fbuff, FFileData.Size div FileRecLen);
           InitBuffFromFile;
           FbuffReady := True;
           NillDataSet;
          end;
          except
           on E: Exception do TDebug.DoException(E);
          end;
        finally
         FFileData.UnLock;
        end;
      end);
      th.WaitFor;
      th.Free;
     end;
   end;
  if FbuffReady then ReadFromMemBuffer
  else if Length(Fbuff) = 0 then
   begin
    //ReadFromDB;
    if not Assigned(FInitBufThread) then FInitBufThread := TReadDataThread.Create(procedure
     var
      ids: IDataSet;
      DSDef: TIDataSetDef;
      CapturedException: Exception;
    begin
      FInitBufThread.FreeOnTerminate := True;
      try
        try
         DSDef := DataSetDef;
         if not DSDef.CreateNew(ids{, False}) then Exit;
         InitMemBuffer(ids.DataSet);
        except
         on E: Exception do TDebug.DoException(E);
        end;
      finally
       FInitBufThread := nil;
      end;
    end);
   end
  else
   begin
//    Owner.Graph.Frost;
//    th := TReadDataThread.Create(procedure
//    begin
      FFileData.Lock;
      try
        try
          if not Assigned(Fids) and not DataSetDef.CreateNew(Fids{, False}) then Exit;
          InitMemBuffer(Fids.DataSet, false);
        finally
         FFileData.UnLock;
//         TThread.Queue(TThread.CurrentThread, procedure
//         begin
//         end);
        end;
      except
       on E: Exception do TDebug.DoException(E);
      end;
//    end);
//    th.WaitFor;
//    th.Free;   // вызывается из  Render RenderLineparams Paint надо вс
//    Owner.Graph.DeFrost;
    { TODO :
// вызывается из  Render RenderLineparams Paint если убрать th.WaitFor то данные рисоваться не будут
надо все переделывать в потоке готовить новые буферы данных
а затем рисовать ?????}
    if FbuffReady then ReadFromMemBuffer;
//    Owner.Graph.DeFrost;
   end;
end;

{$ENDREGION TDataLink<T>}


{ TlineDataLink }

function TlineDataLink.GetXValue(Fx: TField): single;
begin
  Result := Fx.AsSingle;
end;


{$REGION 'TWaveDataLink'}

{ TWaveDataLink }

function TWaveDataLink.FileRecLen: Integer;
begin
  if FFileRecLen = 0 then
   begin
    FFileRecLen := SizeOf(Single) + ArraySize;
   end;
  Result := FFileRecLen;
end;

function TWaveDataLink.GetArrayCount: Integer;
begin
  if FArrayCount = 0 then FArrayCount := XFieldDef.ArraySize;
  Result := FArrayCount;
end;

function TWaveDataLink.GetArraySize: Integer;
begin
  if FArraySize = 0 then FArraySize := ArrayCount * TPars.VarTypeToLength(ArrayType);
  Result := FArraySize;
end;

function TWaveDataLink.GetArrayType: Integer;
begin
  if FArrayType = 0 then ArrayType := XFieldDef.ArrayType;
  Result := FArrayType;
end;

function TWaveDataLink.GetEnumFunc: TAsTypeFunction<integer>;
begin
  if not Assigned(FEnumFunc) then FEnumFunc := Tpars.GetAsTypeFunction(ArrayType);
  Result := FEnumFunc;
end;

function TWaveDataLink.GetRecordCount: Integer;
begin
  if FRecordCount= 0 then FRecordCount := DataSet.RecordCount;
  Result := FRecordCount;
end;

function TWaveDataLink.GetShortIntData(var P: Pointer): ShortInt;
 var
  r: Integer;
begin
  r := Round((EnumFunc(p) + FDelta) * Fscale);
  if r < ShortInt.MinValue then Result := ShortInt.MinValue
  else if r > ShortInt.MaxValue then Result := ShortInt.MaxValue
  else Result := r;
end;

function TWaveDataLink.GetXValue(Fx: TField): TArray<ShortInt>;
 var
  i: Integer;
  b: TArray<byte>;
  p: Pointer;
begin
  Fx.DataSet.GetFieldData(Fx, b);
  p := PPointer(@b[0])^;
  SetLength(Result , ArrayCount);
  for i := 0 to ArrayCount-1 do Result[i] := Round((EnumFunc(p) + FDelta) * Fscale);
end;

procedure TWaveDataLink.InitBuffFromFile;
 var
  p: PFilePoint;
  px: Pointer;
  i,j: Integer;
begin
  FFileData.Read(FFileData.Size, Pointer(p), 0);
//  l := TPars.VarTypeToLength(ArrayType);
  for i := 0 to Length(Fbuff)-1 do
   begin
    Fbuff[i].Y := p.Y;
    SetLength(Fbuff[i].X, ArrayCount);
    px := @p.X[0];
    for j := 0 to ArrayCount-1 do Fbuff[i].X[j] := Round((EnumFunc(px)+ FDelta) * Fscale);
    inc(PByte(p), FileRecLen);
   end;
end;

procedure TWaveDataLink.IniTmpFileBuffer(Y: Single; X: TField);
 var
  dst, src: PByte;
  b: TArray<Byte>;

//  tst: TArray<ShortInt>;
//  px: Pointer;
//  i: Integer;
begin
  X.DataSet.GetFieldData(X, b);
  src := PPointer(@b[0])^;

//  px := src;
//  SetLength(tst , ArrayCount);
//  for i := 0 to ArrayCount-1 do tst[i] := Round((EnumFunc(px)+ FDelta) * Fscale);

  PFilePoint(@FfileTmpBuffer[0]).Y := Y;
  dst := @(PFilePoint(@FfileTmpBuffer[0])^.X[0]);
  Move(src^, dst^,  ArraySize);
end;

procedure TWaveDataLink.Read(YFrom, Yto, Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);
begin
  if (FDelta <> Delta) or (FScale <> Scale) then ResetBuffer;
  FDelta := Delta;
  FScale := Scale;

  inherited read(YFrom, Yto, AddWaveEvent);
end;

procedure TWaveDataLink.ResetBuffer;
begin
  inherited;
  FRecordCount := 0;
end;

procedure TWaveDataLink.Read(Delta, Scale: Single; AddWaveEvent: TAddpointEvent<TArray<ShortInt>>);
  var
   YFrom, Yto: Single;
begin
  DataSet.Active := True;
  DataSet.First;
  YFrom := YValue;
  DataSet.Last;
  Yto := YValue;
  read(YFrom, Yto, Delta, Scale, AddWaveEvent);
end;
{$ENDREGION}

initialization
  RegisterClasses([TlineDataLink, TWaveDataLink, TStringDataLink]);
end.
