unit MainMeta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Generics.Collections, RTTI, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, JvAppStorage, JvAppIniStorage, JvComponentBase, JvFormPlacement, Vcl.Menus;

type
 EnumType = (VT_EMPTY, VT_NULL,
	VT_I2,VT_I4,
	VT_R4,VT_R8,
	VT_CY,VT_DATE,VT_BSTR,VT_DISPATCH,
	VT_ERROR,
	VT_BOOL,VT_VARIANT,VT_UNKNOWN,VT_DECIMAL,
	VT_I1=16,
	VT_UI1,
	VT_UI2,
	VT_UI4,VT_I8,
	VT_UI8,VT_INT,VT_UINT,
	VT_VOID,VT_HRESULT,VT_PTR,VT_SAFEARRAY,VT_CARRAY,VT_USERDEFINED,
	VT_LPSTR,VT_LPWSTR,VT_RECORD=36,
	VT_I3,VT_UI3,VT_INFO, VT_ADDRES,VT_I2_15,VT_UI2_15, VT_RAM_SIZE,
	VT_CHIP=56,VT_SERIAL, VT_I2_15_INV, VT_ARRAY,
	VT_FILETIME=64,VT_BLOB,VT_STREAM,VT_STORAGE,VT_STREAMED_OBJECT,
	VT_STORED_OBJECT,VT_BLOB_OBJECT,VT_CF,VT_CLSID);

  TparsRec = record
   Tip, CIData, InfData, ArrSz: string;
  end;

  TTip = class
   tip: EnumType;
   TypeCiName: string;
   constructor Create(ATypeCiName: string; Atip: EnumType); overload;
   function  GetName(const ACiname, ADatName: string): string;
   procedure DeclareInMeta(ss: TStrings; const ACiname, ADatName, ArrSz: string); virtual;
   procedure MetaImplement(ss: TStrings; const ACiname, ADatName, ArrSz, Preambula: string); virtual;
  end;

  TData = class
    tip: TTip;
    DatName: string;
    CiName, ArrSize: string;
    constructor Create(const Atip, ACiname, ADatName, ArrSz: string); overload;
    constructor Create(const Rec: TparsRec); overload;
    procedure DeclareInMeta(ss: TStrings);
    procedure MetaImplement(ss: TStrings; const Preambula: string);
  end;

  TRecTip = class(TTip)
   DeclaredTypes: TArray<TStrings>;
   Fdt: TArray<TData>;
   constructor Create(ATypeCiName: string; dt: TArray<TparsRec>);
   procedure DeclareInMeta(ss: TStrings; const ACiname, ADatName, ArrSz: string); override;
   procedure MetaImplement(ss: TStrings; const ACiname, ADatName, ArrSz, Preambula: string); override;
   procedure DeclareMetaDataType(const ACiname, ADatName: string);
  end;


  TFormMeta = class(TForm)
    mIn: TMemo;
    mOut: TMemo;
    Splitter: TSplitter;
    FormStorage: TJvFormStorage;
    FileStorage: TJvAppIniFileStorage;
    ppM: TPopupMenu;
    NCompile: TMenuItem;
    procedure NCompileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
    { Public declarations }
  end;

var
  FormMeta: TFormMeta;

implementation

{$R *.dfm}
var
 GTypeDic: TDictionary<string, TTip>;
 GMetaTypeDeclare: TDictionary<string, TStrings>;

{ CArray }
type
  CArray = class
    class procedure Add<T>(var Values: TArray<T>; const Value: T);
  end;

class procedure CArray.Add<T>(var Values: TArray<T>; const Value: T);
begin
  SetLength(Values, Length(Values) + 1);
  Values[High(Values)] := Value;
end;


function EnumToStr(et : EnumType): string;
begin
  case et of
       VT_I2: Result := Trim('     VT_I2');
       VT_I4: Result := Trim('     VT_I4');
       VT_R4: Result := Trim('     VT_R4');
       VT_R8: Result := Trim('     VT_R8');
       VT_CY: Result := Trim('     VT_CY');
     VT_DATE: Result := Trim('   VT_DATE');
     VT_BSTR: Result := Trim('   VT_BSTR');
  VT_DECIMAL: Result := Trim('VT_DECIMAL');
       VT_I1: Result := Trim('     VT_I1');
      VT_UI1: Result := Trim('    VT_UI1');
      VT_UI2: Result := Trim('    VT_UI2');
      VT_UI4: Result := Trim('    VT_UI4');
       VT_I8: Result := Trim('     VT_I8');
      VT_UI8: Result := Trim('    VT_UI8');
      VT_INT: Result := Trim('    VT_INT');
     VT_UINT: Result := Trim('   VT_UINT');
   VT_RECORD: Result := Trim(' VT_RECORD');
       VT_I3: Result := Trim('     VT_I3');
      VT_UI3: Result := Trim('    VT_UI3');
    VT_I2_15: Result := Trim('  VT_I2_15');
   VT_UI2_15: Result := Trim(' VT_UI2_15');
 VT_RAM_SIZE: Result := Trim('VT_RAM_SIZE');
     VT_CHIP: Result := Trim('   VT_CHIP');
   VT_SERIAL: Result := Trim(' VT_SERIAL');
   VT_ARRAY:  Result := Trim('  VT_ARRAY');
  else raise Exception.Create('function EnumToStr(et : EnumType): string;');
  end;
end;

procedure TFormMeta.FormCreate(Sender: TObject);
begin
  GTypeDic := TDictionary<string, TTip>.Create;
  GMetaTypeDeclare := TDictionary<string, TStrings>.Create(20);
end;

procedure TFormMeta.NCompileClick(Sender: TObject);

 var
  aw: Tarray<string>;

  procedure FetchLine(s: string);
   const
   CNC: array[0..5] of Char = ('{', '}', '[', ']', ';',' ');
   var
    i,j: Integer;
    w, c: string;
  begin
    s := Trim(s);
    j := Pos('///', s);
    if j > 0 then
     begin
      c := Trim(Copy(s, j+3, Length(s)-j-2));
      Delete(s, j, Length(s)-j+1);
      s := Trim(s);
     end
    else c := '';
    i := 1;
    While i <= Length(s) do
     begin
      for j := 0 to High(CNC) do if s[i] = CNC[j] then
       begin
        w := Copy(s, 1, i-1);
        if W <>'' then CArray.Add<string>(aw, w);
        if s[i] <> ' ' then CArray.Add<string>(aw, s[i]);
        Delete(s, 1, i);
        s := Trim(s);
        i := 0;
        Break;
       end;
      Inc(i);
     end;
    if Length(s) > 0 then  CArray.Add<string>(aw, s);
    if Length(c) > 0 then
     begin
      CArray.Add<string>(aw, '/');
      CArray.Add<string>(aw, c);
     end;
  end;

 var
  i: Integer;

  function nextAw(const s: string; DecIfFalse: Boolean = False): boolean;
  begin
    Inc(i);
    if i >= Length(aw) then Exit(False);
    Result := s = aw[i];
    if not Result and DecIfFalse then Dec(i);
  end;

  function GetAw: string;
  begin
    Inc(i);
    if i >= Length(aw) then raise Exception.Create('function GetAw: string');
    Result := aw[i];
  end;

  function ParsSimple(DecI: Boolean = False): TparsRec;
  begin
    if DecI then Dec(i);
    Result.Tip := GetAw;
    Result.CIData := GetAw;
    Result.InfData := '';
    if nextAw('[', True) then
     begin
      Result.ArrSz := GetAw;
      if not nextAw(']') then raise Exception.Create('not found ]');
     end;
    if not nextAw(';') then raise Exception.Create('function ParsSimple : TparsRec not found ;');
    if nextAw('/', True) then Result.InfData := GetAw
  end;

  procedure ParsRecDef;
   var
    ps: TArray<TparsRec>;
  begin
    while not nextAw('}', True) do CArray.Add<TparsRec>(ps, ParsSimple);
    TRecTip.Create(GetAw, ps);
    while not nextAw(';') do;
  end;

 var
  s: string;
  p: TPair<string, TStrings>;
  dt: TData;
  GlobData: TArray<TData>;
begin
  GTypeDic.Clear;
  GMetaTypeDeclare.Clear;
  SetLength(GlobData, 0);
  // init simle types
  TTip.Create('float', VT_R4);
  TTip.Create('int8_t', VT_I1);
  TTip.Create('uint8_t', VT_UI1);
  TTip.Create('int16_t', VT_I2);
  TTip.Create('uint16_t', VT_UI2);
  TTip.Create('int32_t', VT_I4);
  TTip.Create('uint32_t', VT_UI4);
  // create array nodes
  SetLength(aw, 0);
  for s in mIn.Lines do FetchLine(s);
  i := 0;
  // parse script create meta data
  while i < Length(aw) do
   begin
    if (aw[i] = 'typedef') then
     if nextAw('struct') and nextAw('{') then ParsRecDef // type Record
     else raise Exception.Create('if aw[i] = typedef and nextAw(struct) and nextAw({)')
    else CArray.Add<TData>(GlobData, TData.Create(ParsSimple(True))); // instance
    Inc(i);
   end;
  mOut.Clear;
  mOut.Lines.Add('/* Данные сгенерированы из:');
  mOut.Lines.AddStrings(mIn.Lines);
  mOut.Lines.Add('*/');
  mOut.Lines.Add('');
  // add meta data types
  for p in GMetaTypeDeclare do
   begin
    mOut.Lines.Add('// тип метаданных: '+ p.Key);
    mOut.Lines.AddStrings(p.Value);
    mOut.Lines.Add('');
   end;
  // implement global meta data
  for dt in GlobData do
   begin
    mOut.Lines.Add(Format('// заполнение данных %s %s', [dt.tip.TypeCiName, dt.CiName]));
    mOut.Lines.Add(Format('#define META_%s_%s meta_%s_%s meta_%s;', [UpperCase(dt.tip.TypeCiName), UpperCase(dt.CiName), dt.CiName, dt.tip.TypeCiName, dt.CiName]));
    mOut.Lines.Add(Format('#define META_%s_%s_IMPL\', [UpperCase(dt.tip.TypeCiName), UpperCase(dt.CiName)]));
    dt.MetaImplement(mOut.Lines,'  ');
    mOut.Lines[mOut.Lines.Count-1] := Copy(mOut.Lines[mOut.Lines.Count-1], 1, LastDelimiter('\', mOut.Lines[mOut.Lines.Count-1])-1);
    mOut.Lines.Add('');
   end;
end;

{$REGION 'classes'}

{ TTip }

constructor TTip.Create(ATypeCiName: string; Atip: EnumType);
begin
  tip := Atip;
  TypeCiName := ATypeCiName;
  GTypeDic.Add(TypeCiName, Self);
end;

procedure TTip.DeclareInMeta(ss: TStrings; const ACiname, ADatName, ArrSz: string);
begin
  if ArrSz = '' then
   ss.Add(Format('    varType_t varType%0:s; uint8_t param%0:s[sizeof("%1:s")];', [ACiname, GetName(ACiname, ADatName)]))
  else
   ss.Add(Format('    varType_t TypeArr%0:s; uint16_t Arrlen%0:s; varType_t varType%0:s; uint8_t param%s[sizeof("%1:s")];',
                      [ACiname, GetName(ACiname, ADatName)]));
end;

function TTip.GetName(const ACiname, ADatName: string): string;
begin
  if ADatName = '' then Result := ACiname
  else if ADatName[1] <>'|' then Result := ADatName
  else Result := ACiName+ADatName;
end;

procedure  TTip.MetaImplement(ss: TStrings; const ACiname, ADatName,ArrSz, Preambula: string);
begin
  if ArrSz = '' then
   ss.Add(Format('%s%s, "%s",\', [Preambula, EnumToStr(tip), GetName(ACiname, ADatName)]))
  else
   ss.Add(Format('%sVT_ARRAY, %s, %s, "%s",\', [Preambula, ArrSz, EnumToStr(tip), GetName(ACiname, ADatName)]));
end;

{ TRecTip }

constructor TRecTip.Create(ATypeCiName: string; dt: TArray<TparsRec>);
 var
  i: integer;
begin
  inherited Create(ATypeCiName, VT_RECORD);
  SetLength(Fdt, Length(dt));
  for i :=0 to Length(dt)-1 do Fdt[i] := TData.Create(dt[i]);
end;

procedure TRecTip.DeclareInMeta(ss: TStrings; const ACiname, ADatName, ArrSz: string);
begin
  ss.Add(Format('    meta_%s_%s meta_%s;', [ACiname, TypeCiName, ACiname]));
end;

procedure TRecTip.DeclareMetaDataType(const ACiname, ADatName: string);
 var
  d: TData;
  ss: TStrings;
  key: string;
begin
  key := Format('meta_%s_%s=%s',[ACiName, TypeCiName, GetName(ACiname, ADatName)]);
  if GMetaTypeDeclare.ContainsKey(key) then Exit;
  ss := TStringList.Create;
  CArray.Add<TStrings>(DeclaredTypes, ss);
  ss.Add('typedef struct {');
  ss.Add(Format('  varType_t RecType; uint16_t SelfLen; uint8_t RecName[sizeof("%s")];',[ GetName(ACiname, ADatName)]));
  for d in Fdt do d.DeclareInMeta(ss);
  ss.Add(Format('} meta_%s_%s __attribute__((aligned));', [ACiName, TypeCiName]));
  GMetaTypeDeclare.Add(key, ss);
end;

procedure TRecTip.MetaImplement(ss: TStrings; const ACiname, ADatName, ArrSz, Preambula: string);
 var
  d: TData;
begin
  ss.Add(Format('%s{VT_RECORD, sizeof(meta_%s_%s),"%s",\',[Preambula , ACiname, TypeCiName, GetName(ACiname, ADatName)]));
  for d in Fdt do d.MetaImplement(ss, Preambula+ '   ');
  ss.Add(Preambula + '},\');
end;

{ TData }

constructor TData.Create(const Atip, ACiname, ADatName,ArrSz: string);
begin
  if not GTypeDic.TryGetValue(Atip, tip) then raise Exception.Create('constructor TData.Create(const Atip, ACiname, ADatName: string);');
  DatName := ADatName;
  CiName := ACiname;
  ArrSize := ArrSz;
  if tip is TRecTip then TRecTip(tip).DeclareMetaDataType(CiName, DatName);
end;

constructor TData.Create(const Rec: TparsRec);
begin
  Create(Rec.Tip, Rec.CIData, Rec.InfData, Rec.ArrSz);
end;

procedure TData.DeclareInMeta(ss: TStrings);
begin
  tip.DeclareInMeta(ss, CiName, DatName, ArrSize);
end;

procedure TData.MetaImplement(ss: TStrings; const Preambula: string);
begin
  tip.MetaImplement(ss, CiName, DatName, ArrSize, Preambula)
end;
{$ENDREGION}

end.
