unit TxtParser;

interface

uses System.IOUtils,  System.Generics.Collections, Data.DB, RLDataSet, DateUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls;

type
 //mnem,type,ofset,array_size,uom,title,digits,presi,Rlo,Rhi,color,width,dash
 TmetaDataItem = record
  mnem: string;
  tip: Integer;

  len: Integer;
  ft:  TFieldType;

  ofset: Integer;
  array_size: Integer;
  uom: string;
  title: string;
  digits: Integer;
  presi: Integer;
  Rlo: Double;
  Rhi: Double;
  color: TColor;
  width: Integer;
  dash: Integer;
  constructor Create(const s: string);
  function AsDouble(pData: Pointer): Double;
 end;

 TMetaData = record
   Options: TStrings;
   Data: TArray<TmetaDataItem>;
   function SizeOf(): Integer;
   function TimeStart: TDateTime;
   constructor Create(const ss: TStrings);
 end;

 TPBDataSet = class(TRDataSet)
 private
   FStream: TFileStream;
   FBinName: string;
   FMetaData: TMetaData;
   FRecCount: Integer;
   FKadrLen: Integer;
   FKadrFrom: Integer;
   FCurrentID: Integer;
   FCurrentKadr: TBytes;
   FCurrentTimeStamp: TTimeStamp;
   FCurrentDateTime: TDateTime;
   FDateTimeFieldNo: Integer;
 protected
   procedure InternalClose;  override;
   procedure InternalHandleException;  override;
   procedure InternalInitFieldDefs;  override;
   procedure InternalOpen;  override;
   function IsCursorOpen: Boolean;  override;

   function GetRecordCount: Integer; override;

   function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
  public
   const
    KADR_TO_TDateTime = 2.097152 / 3600 / 24;
   var
    GoodSize: Boolean;
    TimeStart: TDateTime;
    TimeEnd: TDateTime;
    constructor Create(AOwner: TComponent; const bin: string; MetaData: TMetaData);
    property KadrFrom: Integer read FKadrFrom;
 end;

implementation

{$REGION 'metadata'}

type ConvType = record
 Name: string;
 tip: Integer;
 len: Integer;
 ft:  TFieldType;
end;

const ConvTypes: array [0..9] of ConvType = (
 (    Name: 'uint8_t';    Tip: varByte;     len:1; ft:ftByte),
 (    Name: 'int8_t';     Tip: varShortInt; len:1; ft:ftShortint ),

 (    Name: 'uint16_t';   Tip: varWord;     len:2; ft:ftWord  ),
 (    Name: 'int16_t';    Tip: varSmallint; len:2; ft:ftSmallint  ),

 (    Name: 'uint32_t';   Tip: varUInt32;    len:4; ft:ftLongWord  ),
 (    Name: 'int32_t';    Tip: varInteger;   len:4; ft:ftInteger  ),
 (    Name: 'float';      Tip: varSingle;    len:4; ft:ftSingle  ),

 (    Name: 'uint64_t';   Tip: varUInt64;    len:8; ft: ftLargeInt  ),
 (    Name: 'int64_t';    Tip: varInt64;     len:8; ft: ftLargeInt  ),
 (    Name: 'double';     Tip: varDouble;    len:8; ft:ftFloat  )
);

function GetTip(const name: string): Integer;
begin
  for var stdt in ConvTypes do if stdt.Name = name then Exit(stdt.tip);
  raise Exception.CreateFmt('function GetTip(const name: string): Integer; Error type %s', [name]);
end;

function GetConvType(tip: Integer): ConvType;
begin
  for var stdt in ConvTypes do if stdt.tip = tip then Exit(stdt);
end;

{ TMetaData }

constructor TMetaData.Create(const ss: TStrings);
begin
  Options := TStringList.Create;
  var i := 0;
  while (i < ss.Count) and (ss[i] <> '###') do
   begin
    Options.Add(ss[i]);
    Inc(i);
   end;
  Inc(i);
  while (i < ss.Count) do
   begin
    Data := Data + [TmetaDataItem.Create(ss[i])];
    Inc(i);
   end;
end;

function TMetaData.SizeOf: Integer;
begin
  Result := 0;
  for var d in data do Inc(Result, GetConvType(d.tip).len);
end;

function TMetaData.TimeStart: TDateTime;
begin
  Result := StrToDateTime(Options.Values['TIME_START']);
end;

{ TmetaDataItem }

function TmetaDataItem.AsDouble(pData: Pointer): Double;
begin
   case tip of
    varByte: Result := PByte(pData)^;
    varShortInt: Result := PShortInt(pData)^;
    varWord: Result := PWord(pData)^;
    varSmallint: Result := PSmallint(pData)^;
    varUInt32: Result := PUInt32(pData)^;
    varInteger: Result := PInteger(pData)^;
    varSingle: Result := PSingle(pData)^;
    varUInt64: Result := PUInt64(pData)^;
    varInt64: Result := PInt64(pData)^;
    varDouble: Result := PDouble(pData)^;
   end;
end;

constructor TmetaDataItem.Create(const s: string);
begin
  var ar := s.Split([';']);
  if Length(ar) < 13 then raise Exception.CreateFmt(' not find parametrs %d', [Length(ar)]);
  mnem := ar[0];

  tip := GetTip(ar[1]);
  var cv := GetConvType(tip);
  len := cv.len;
  ft := cv.ft;

  ofset := ar[2].ToInteger;
  if ar[3] = '' then  array_size := 1 else array_size := ar[3].ToInteger;
  uom := ar[4];
  title := ar[5];
  if ar[6] = '' then  digits := 0 else digits := ar[6].ToInteger;
  if ar[7] = '' then  presi := 0 else presi := ar[7].ToInteger;
  if ar[8] = '' then  Rlo := 0 else Rlo := ar[8].ToDouble;
  if ar[9] = '' then  Rhi := 0 else Rhi := ar[9].ToDouble;
  if ar[10] = '' then  color := clBlack else color := TColor(DWORD(('$'+ ar[10]).ToInteger));
  if ar[11] = '' then  width := 0 else width := ar[11].ToInteger;
  if ar[12] = '' then  dash := 0 else dash := ar[12].ToInteger;
end;

{$ENDREGION}


{$REGION 'DataSet'}

{ TPBDataSet }

function TPBDataSet.GetRecordCount: Integer;
begin
  Result := FRecCount;
end;

constructor TPBDataSet.Create(AOwner: TComponent; const bin: string; MetaData: TMetaData);
begin
  inherited Create(AOwner);
  FBinName := bin;
  FMetaData := MetaData;
end;

function TPBDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
 var
  ab: PRecBuffer;
begin
  Result := false;
  if Field.IsBlob then Exit(False);
  if not GetActiveRecBuf(ab) then Exit;

  if Field.FieldNo = 1 then
   begin
    SetLength(Buffer, sizeof(Integer));
    PInteger(Buffer)^ := ab.ID;
    Exit(True);
   end;
  if ab.ID <> FCurrentID then
   begin
     FStream.Seek(Int64(ab.ID-1)*FKadrLen, soBeginning);
     FStream.Read(FCurrentKadr, FKadrLen);
     FCurrentID := ab.ID;
     FCurrentDateTime := TimeStart +(PInteger(@FCurrentKadr[0])^-FKadrFrom)*KADR_TO_TDateTime;
     FCurrentTimeStamp := DateTimeToTimeStamp(FCurrentDateTime);
   end;
  if Field.FieldNo = 2 then
   begin
    SetLength(Buffer, sizeof(Cardinal));
    PCardinal(Buffer)^ := FCurrentTimeStamp.Date;
    Exit(True);
   end;
  if Field.FieldNo = 3 then
   begin
    SetLength(Buffer, sizeof(Cardinal));
    PCardinal(Buffer)^ := FCurrentTimeStamp.Time;
    Exit(True);
   end;
  if Field.FieldNo = FDateTimeFieldNo then
   begin
    SetLength(Buffer, sizeof(Double));
    PDouble(Buffer)^ := FCurrentDateTime;
    Exit(True);
   end;
  var m := FMetaData.Data[Field.FieldNo-4];
  SetLength(Buffer, m.len);
  move(FCurrentKadr[m.ofset], Buffer[0], m.len);
  Result := True;
end;

procedure TPBDataSet.InternalClose;
begin
  inherited;
  FreeAndNil(FStream);
end;

procedure TPBDataSet.InternalHandleException;
begin
  Application.HandleException(self);
end;

procedure TPBDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  var fn := 1;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftInteger;
    FieldNo := fn;Inc(fn);
    Name := 'ID';
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftDate;
    FieldNo := fn;Inc(fn);
    Name := 'Date';
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftTime;
    FieldNo := fn;Inc(fn);
    Name := 'Time';
  end;
  for var n in Fmetadata.Data do with FieldDefs.AddFieldDef do
   begin
    if n.array_size > 1 then
     begin
      DataType := ftBlob;
      Size := n.len * n.array_size;
     end
    else
     begin
      DataType := n.ft;
     end;
    FieldNo := fn; Inc(fn);
    Name := n.mnem;
    Precision := n.presi;
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftFloat;
    FieldNo := fn;
    FDateTimeFieldNo := fn;
    Name := 'DateTime';
  end;
end;

procedure TPBDataSet.InternalOpen;
begin
  FStream := TFileStream.Create(FBinName, fmOpenRead);
  FStream.Seek(0, soBeginning);
  FStream.ReadData(FKadrFrom);
  FKadrLen := FMetadata.SizeOf;
  SetLength(FCurrentKadr, FKadrLen);
  FCurrentID := -2;
  var FileSz := FStream.Size;
  GoodSize :=  (FileSz mod FKadrLen) = 0;
  TimeStart := FMetadata.TimeStart + (FKadrFrom-1)*KADR_TO_TDateTime;
  FRecCount := FileSz div FKadrLen;
  TimeEnd := TimeStart +FRecCount*KADR_TO_TDateTime;
  inherited;
end;

function TPBDataSet.IsCursorOpen: Boolean;
begin
  Result := Assigned(FStream);
end;
{$ENDREGION}

end.
