unit FileDataSet;

interface

uses ExtendIntf, DataSetIntf, Container, debug_except,
     System.Classes, sysutils, Data.DB, IDataSets, FileCachImpl;

type
  TFileFieldDef = class(TFieldDef)
  private
    FDataOffset: Integer;
    FArraySize: Integer;
    FArrayType: Integer;
    FCalcField: Boolean;
  public
    function IsArrray: Boolean;
    function GetPath: string;
// published неподдерживаются
  public
    property FullName: string read GetPath;
    property DataOffset: Integer read FDataOffset write FDataOffset;
    property ArraySize: Integer read FArraySize write FArraySize default 0;
    property ArrayType: Integer read FArrayType write FArrayType default 0;
    property CalcField: Boolean read FCalcField write FCalcField;
  end;

  TFileFieldDefs = class(TFieldDefs)
  protected
    function GetFieldDefClass: TFieldDefClass; override;
  end;

  TFileDataSet = class(TRLDataSet)
  private
    FFileData: IFileData;
    FBinFileName: string;
    FRecordLength: Integer;
    FCurrDataBuffer: PByte;
    FCurrDataID: Integer;
    function GetFileData: IFileData;
  protected
    procedure SetFieldProps(Field: TField; FieldDef: TFieldDef); override;
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function GetRecData(Buffer: PRecBuffer): PByte;
    function GetCalcData(Buffer: PRecBuffer): PByte; virtual;
    function InternalCalcRecBuffer(Buffer: PRecBuffer): Boolean; virtual;
    function FindFieldData(Buffer: PRecBuffer; Field: TField): PByte;
    function GetFieldDefsClass: TFieldDefsClass; override;
    function GetRecordCount: Integer; override;
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream; override;
//    function GetFileName: string; override;
    function GetItemName: String; override;
    procedure SetItemName(const Value: String); override;
  public
    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
    property FileData: IFileData read GetFileData;
    function FindFieldDef(const FullName: string): TFileFieldDef;
/// <summary>
///  {week reference container}
/// </summary>
    class procedure Get(const FileName: string; RecordLength: Integer; out Res: IDataSet); //virtual;
    class procedure CreateNew(const FileName: string; RecordLength: Integer; out Res: IDataSet); //virtual;
// published неподдерживаются
  public
    property BinFileName: string read FBinFileName write FBinFileName;
    property RecordLength: Integer read FRecordLength write FRecordLength;
  end;

  TFileBlobStream = class(TStream)
  private
    FField: TBlobField;
    FDataSet: TFileDataSet;
    FMode: TBlobStreamMode;
    FOpened: Boolean;
    FModified: Boolean;
    FPosition: Longint;
    Fbuffer: Pointer;
  public
    constructor Create(Field: TBlobField; Mode: TBlobStreamMode);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
  end;


implementation

function ToDBDisplayFormat(Precision: Integer): string;
 var
  i: Integer;
begin
  Result := '#0.';
  for i:= 1 to Precision do Result := Result + '0';
end;

{ TFileDataSet }

class procedure TFileDataSet.Get(const FileName: string; RecordLength: Integer; out Res: IDataSet);
 var
  ii: IInterface;
begin
  if GContainer.TryGetInstance(ClassInfo, FileName, ii) then Res := ii as IDataSet
  else
   begin
    CreateNew(FileName, RecordLength, Res);
    TRegistration.Create(ClassInfo).AddInstance(FileName, Res);
    TFileDataSet(Res.DataSet).WeekContainerReference := True;
   end;
end;

function TFileDataSet.GetCalcData(Buffer: PRecBuffer): PByte;
begin
  Result := nil;
end;

function TFileDataSet.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
begin
  Result := TFileBlobStream.Create(TBlobField(Field), Mode);
end;

class procedure TFileDataSet.CreateNew(const FileName: string; RecordLength: Integer; out Res: IDataSet);
begin
  Res := Create as IDataSet;
  TFileDataSet(Res.DataSet).BinFileName := FileName;
  TFileDataSet(Res.DataSet).RecordLength := RecordLength;
  TFileDataSet(Res.DataSet).FCurrDataID := -1;
end;


function TFileDataSet.GetRecData(Buffer: PRecBuffer): PByte;
begin
  if FCurrDataID = Buffer.ID then Exit(FCurrDataBuffer)
  else
    if FileData.Read(RecordLength, Pointer(Result), Int64(Buffer.ID-1)*Int64(RecordLength)) <> RecordLength then Result := nil
  else
   begin
    FCurrDataBuffer := Result;
    FCurrDataID := Buffer.ID;
   end;
end;

function TFileDataSet.FindFieldData(Buffer: PRecBuffer; Field: TField): PByte;
 var
  Index: Integer;
//  clcb: PBoolean;
  f: TFileFieldDef;
begin
  Result := nil;
  Index := Field.FieldNo - 1; // FieldDefList index (-1 and 0 become less than zero => ignored)
  if Index < 0 then Exit;
  if Index = 0 then Exit(@(Buffer.ID));
  f := TFileFieldDef(FieldDefList[Index]);
  if f.CalcField and AutoCalcFields then
   begin
    Result := GetCalcData(Buffer);
    if not Assigned(Result) then
     begin
      if not Buffer.AutoCalculated and not InternalCalcRecBuffer(Buffer) then Exit;
      Result := PByte(Buffer) + SizeOf(TRecBuffer);
     end;
   end
  else if Field.FieldKind = fkData then Result := GetRecData(Buffer);
  if not Assigned(Result) then Exit;
  Inc(Result, f.DataOffset);
end;

function TFileDataSet.FindFieldDef(const FullName: string): TFileFieldDef;
 var
  i: Integer;
begin
  for i := 0 to FieldDefList.Count-1 do if SameText(TFileFieldDef(FieldDefList[i]).FullName, FullName) then Exit(TFileFieldDef(FieldDefList[i]));
  Result := nil;
end;

function TFileDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
 var
  RecBuf: PRecBuffer;
  Data: Pointer;
  l: Integer;
begin
  Result := False;
  if Field.DataType in [ftADT] then Exit;
 // TDebug.Log('  Field.FieldNo %d  %s   ', [Field.FieldNo, Field.FullName]);
  if not GetActiveRecBuf(RecBuf) then Exit;
  Data := FindFieldData(RecBuf, Field);
  if Data = nil then Exit;
  if Field is TBlobField then
   begin
    SetLength(Buffer, sizeof(Pointer));
    PPointer(@Buffer[0])^ := Data;
   end
  else
   begin
    l := Field.DataSize;
    SetLength(Buffer, l);
    Move(Data^, Buffer[0], l);
   end;
  Result := True;
end;
function TFileDataSet.GetFieldDefsClass: TFieldDefsClass;
begin
  Result := TFileFieldDefs;
end;

function TFileDataSet.GetFileData: IFileData;
begin
  if Assigned(FFileData) then Exit(FFileData);
  FFileData := GFileDataFactory.Factory(TFileData, BinFileName);
  Result := FFileData;
end;

function TFileDataSet.GetItemName: String;
begin
  Result := FBinFileName;
end;

//function TFileDataSet.GetFileName: string;
//begin
//  Result := FBinFileName;
//end;

function TFileDataSet.GetRecordCount: Integer;
 var
  n: Int64;
begin
  n := FileData.Size;
  Result := n div RecordLength;
end;

function TFileDataSet.InternalCalcRecBuffer(Buffer: PRecBuffer): Boolean;
begin
  Result := False;
end;

function TFileDataSet.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IID = IFileData then Result := FileData.QueryInterface(IID, Obj)
  else Result := inherited;
end;

procedure TFileDataSet.SetFieldProps(Field: TField; FieldDef: TFieldDef);
begin
  inherited;
  if (Field is TNumericField) and (FieldDef.Precision > 0) then
     TNumericField(Field).DisplayFormat := ToDBDisplayFormat(FieldDef.Precision);
end;

procedure TFileDataSet.SetItemName(const Value: String);
begin
  FBinFileName := Value;
end;

{ TFileFieldDefs }

function TFileFieldDefs.GetFieldDefClass: TFieldDefClass;
begin
  Result :=  TFileFieldDef;
end;

{ TFileFieldDef }

//function TFileFieldDef.GetFullName: string;
//var
//  ParentField: TFieldDef;
//begin
//  Result := Name;
//  ParentField := ParentDef;
//  while ParentField <> nil do
//   begin
//    Result := Format('%s.%s', [ParentField.Name, Result]);
//    ParentField := ParentField.ParentDef;
//   end;
//end;

function TFileFieldDef.GetPath: string;
 var
  f: TFieldDef;
begin
  Result := Name;
  f := Self;
  while Assigned(f.ParentDef) do
   begin
    f := f.ParentDef;
    Result := f.Name + '.' + Result;
   end;
end;

function TFileFieldDef.IsArrray: Boolean;
begin
  Result := FArraySize <> 0;
end;

{ TFileBlobStream }

constructor TFileBlobStream.Create(Field: TBlobField; Mode: TBlobStreamMode);
 var
  b: TArray<Byte>;
begin
  inherited Create;
  FMode := Mode;
  FField := Field;
  FDataSet := FField.DataSet as TFileDataSet;
  if not FDataSet.GetFieldData(FField, b) then Exit;
  Fbuffer := PPointer(@b[0])^;
end;

function TFileBlobStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := 0;
  if Count > Size - FPosition then Result := Size - FPosition
  else Result := Count;
  if Result > 0 then
  begin
   Move(Fbuffer^, Buffer, Result);
   Inc(FPosition, Result);
   end;
end;

function TFileBlobStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  case Origin of
    soFromBeginning:
      FPosition := Offset;
    soFromCurrent:
      Inc(FPosition, Offset);
    soFromEnd:
      FPosition := FField.Size + Offset;
  end;
  Result := FPosition;
end;

function TFileBlobStream.Write(const Buffer; Count: Integer): Longint;
begin
  Result := FField.Size;
  if Count < Result then Result := Count;
  Move(Buffer, Fbuffer^, Result);
end;

initialization
  RegisterClass(TFileDataSet);
  TRegister.AddType<TFileDataSet, IDataSet>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFileDataSet>;
end.
