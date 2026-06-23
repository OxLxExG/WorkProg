unit LasImpl;

interface

uses LAS, RootImpl, debug_except,
    System.SysUtils, System.Classes, System.Variants;

type
  TLasFormatHelper = record helper for TLasFormat
    function GetValue: Variant;
    procedure SetValue(const Value: Variant);
    constructor Create(const aMnem, aUnits: string; const aData: string = ''; const aDescription: string = ''); overload;
    constructor Create(const line: string); overload;
    property Value: Variant read GetValue write SetValue;
  end;


function NewLasDoc(EmptyCurve: Boolean = False): ILasDoc;
function GetLasDoc(const FileName: string; Encoding: LasEncoding): ILasDoc;
function GetLasEncoding(Encoding: LasEncoding): TEncoding;


implementation

uses tools, Container;

{ TLasFormatHelper }

constructor TLasFormatHelper.Create(const aMnem, aUnits, aData, aDescription: string);
begin
  Mnem := aMnem;
  Units := aUnits;
  Data := aData;
  Description := aDescription;
end;

constructor TLasFormatHelper.Create(const line: string);
 var
  s: string;
begin
  Mnem := Trim(line.Remove(line.IndexOf('.')));
  Description := Trim(line.Substring(line.IndexOf(':')+1));
  s := line.Substring(line.IndexOf('.')+1, line.IndexOf(':')-line.IndexOf('.')-1);
  if s.Chars[0] <> ' ' then
   begin
    Units := s.Remove(s.IndexOf(' '));
    s := s.Substring(s.IndexOf(' '));
   end;
  Data := Trim(s);
end;

function TLasFormatHelper.GetValue: Variant;
begin
  Result := Data;
end;

procedure TLasFormatHelper.SetValue(const Value: Variant);
begin
  Data := Value;
end;

 const
  LAS_V_VERS: TLasFormat = (Mnem:'VERS'; Data: '2.0'; Description:'CWLS log ASCII Standard -VERSION 2.0');
  LAS_V_WRAP: TLasFormat = (Mnem:'WRAP'; Data: 'NO'; Description:'One line per depth step');

  LAS_W_STRT: TLasFormat = (Mnem:'STRT'; Units: 'M'; Description:'Глубина первой строки данных');
  LAS_W_STOP: TLasFormat = (Mnem:'STOP'; Units: 'M'; Description:'Глубина последней строки данных');
  LAS_W_STEP: TLasFormat = (Mnem:'STEP'; Units: 'M'; Description:'Шаг глубины');
  LAS_W_NULL: TLasFormat = (Mnem:'NULL'; Data: '-999.25'; Description:'NULL VALUE');
  LAS_W_COMP: TLasFormat = (Mnem:'COMP'; Description:'Имя компании');
  LAS_W_WELL: TLasFormat = (Mnem:'WELL'; Description:'Название скважины');
  LAS_W_FLD: TLasFormat = (Mnem:'FLD'; Description:'Месторождение');
  LAS_W_LOC: TLasFormat = (Mnem:'LOC'; Description:'LOCATION');
  LAS_W_PROV: TLasFormat = (Mnem:'PROV'; Description:'PROVINCE');
  LAS_W_SRVC: TLasFormat = (Mnem:'SRVC'; Data: 'АМК "Горизонт"'; Description:'SERVICE COMPANY');
  LAS_W_LIC: TLasFormat = (Mnem:'LIC'; Description:'ERCB LICENCE NUMBER');
  LAS_W_DATE: TLasFormat = (Mnem:'DATE'; Description:'LOG DATE');
  LAS_W_UWI: TLasFormat = (Mnem:'UWI'; Description:'UNIQUE WELL ID');

  LAS_C_DEPT: TLasFormat = (Mnem:'DEPT'; Units: 'M'; Description:'1   DEPTH');

type
  TLasDoc = class;

  TSection = class(TIObject, ILasSection, IOptSection)
  private
   FOwner: TLasDoc;
   FSectID: string;
   FPriambula: TArray<string>;
  protected
   procedure AddLine(const line: String); virtual;
   procedure ClearBufers(); virtual;
   function Priambula: TArray<string>; // Priambula[0] = '~Well infor...'
  public
   constructor Create(Owner: TLasDoc; const SectID: string; const Priambula: array of string);
   procedure ToStrings(ss: TStrings); virtual;
   function FromStrings(ss: TStrings): boolean;
  end;

  TFSection = class(TSection, ILasFormatSection)
  private
    FItems: TArray<TLasFormat>;
  protected
    function GetItem(const Mnem: string): PLasFormat;
    procedure Add(const NewItem: TLasFormat); virtual;
    procedure AddLine(const line: String); override;
    procedure ClearBufers(); override;
    function Mnems: TArray<string>;
    function Formats: TArray<TLasFormat>;
    function IndexOff(const Mnem: string): Integer;
  public
    procedure ToStrings(ss: TStrings); override;
  end;

  TCSection = class(TFSection, ICurveSection)
  private
    FDispStr: TArray<string>;
  protected
    procedure ClearBufers(); override;
    procedure Add(const NewItem: TLasFormat); override;
    function GetDisplayFormat(const Mnem: string): string;
    procedure SetDisplayFormat(const Mnem, Value: string);
  public
    function MnemsToString: String;
  end;

  TDSection = class(TSection, ILasDataSection)
  private
   RowData: TArray<Variant>;
   CurrIndex: Integer;
   sNul: Double;
  //sNul := Double(FOwner.Well.Items['NULL'].Value);
  //sd := line.Split([' '], TStringSplitOptions.ExcludeEmpty);
  //SetLength(v, Length(sd));

    FData: TArray<TArray<Variant>>;
    function RowToString(Index : Integer): string;
    function GetDataLength: integer;
  protected
    procedure ClearBufers(); override;
    function CheckData(const Data: array of Variant): Boolean;
    procedure AddData(const Data: array of Variant);
    procedure Clear;
    function GetData: TArray<TArray<Variant>>;
    procedure AddLine(const line: String); override;
    property DataLength: integer read GetDataLength;
  public
    procedure ToStrings(ss: TStrings); override;
    destructor Destroy; override;
  end;

  TLasDoc = class(TIObject, ILasDoc)
  private
    FfileName: string;
    FEncoding: LasEncoding;
    FSections: array [LasSection] of ILasSection;
    function GetItem(const Mnem: string; Index: Integer): Variant;
    procedure SetItem(const Mnem: string; Index: Integer; const Value: Variant);
    function GetDataCount: Integer;
    function GetEncoding: LasEncoding;
    procedure SetEncoding(const Value: LasEncoding);
    function GetFileName: string;
  protected
    function Well: ILasFormatSection;
    function Curve: ICurveSection;
    function Data: ILasDataSection;
    function Version: ILasFormatSection;
    function Params: ILasFormatSection;
    function Other: IOptSection;

    procedure SaveToFile(const AFileName: String);
    procedure LoadFromFile(const AFileName: String);

    property Encoding: LasEncoding read GetEncoding write SetEncoding;

    property FileName: string read GetFileName;

    property DataCount: Integer read GetDataCount;
    property Item[const Mnem: string; Index: Integer]: Variant read GetItem write SetItem;
  public
    constructor Create(EmptyCurve: Boolean);
    destructor Destroy; override;
  end;

function NewLasDoc(EmptyCurve: Boolean = False): ILasDoc;
begin
  Result := TLasDoc.Create(EmptyCurve);
end;

function GetLasEncoding(Encoding: LasEncoding): TEncoding;
begin
    case Encoding of
      lsenDOS: Result := TEncoding.GetEncoding(866);
      lsenUTF8: Result := TEncoding.UTF8;
      else Result := TEncoding.ANSI;
    end;
end;
function GetLasDoc(const FileName: string; Encoding: LasEncoding): ILasDoc;
 var
  i: IInterface;
begin
  if GContainer.TryGetInstKnownServ(TypeInfo(ILasDoc), FileName, i, False) then Exit(i as IlasDoc)
  else
   begin
    Result := NewLasDoc;
    Result.Encoding := Encoding;
    Result.LoadFromFile(FileName);
    TRegister.AddType<TLasDoc, ILasDoc>.LiveTime(ltSingletonNamed).AddInstance(FileName, Result as IInterface);
   end;
end;

{$REGION 'Sections'}

{ TSection }

constructor TSection.Create(Owner: TLasDoc; const SectID: string; const Priambula: array of string);
 var
  i: Integer;
begin
  FOwner := Owner;
  FSectID := SectID;
  SetLength(FPriambula, Length(Priambula));
  for i := 0 to Length(Priambula)-1 do FPriambula[i] := Priambula[i];
end;

procedure TSection.AddLine(const line: String);
begin
  CArray.Add<string>(FPriambula, line);
end;

procedure TSection.ClearBufers;
begin
  SetLength(FPriambula, 0);
end;

function TSection.FromStrings(ss: TStrings): boolean;
 var
  i: Integer;
begin
  Result := False;
  i := 0;
  while i < ss.Count do
   if ss[i].StartsWith(FSectID) then // find section
    begin
     ClearBufers;
     CArray.Add<string>(FPriambula, ss[i]);
     inc(i);
     while ss[i].StartsWith('#') and (i < ss.Count) do // parse priamula
      begin
       CArray.Add<string>(FPriambula, ss[i]);
       inc(i);
      end;
     while i < ss.Count do // parse data
      begin
       if ss[i].StartsWith('~') then Break
       else if (ss[i].Length > 0) and not ss[i].StartsWith('#') then AddLine(ss[i]);
       inc(i);
      end;
      Exit(True);
    end
   else if ss[i].StartsWith('~A') then Exit(False)
   else Inc(i);
end;

function TSection.Priambula: TArray<string>;
begin
  Result := FPriambula;
end;

procedure TSection.ToStrings(ss: TStrings);
 var
  s: string;
begin
  for s in FPriambula do ss.Add(s);
end;

{ TFSection }

procedure TFSection.Add(const NewItem: TLasFormat);
begin
  CArray.Add<TLasFormat>(FItems, NewItem);
end;

procedure TFSection.AddLine(const line: String);
begin
  Add(TLasFormat.Create(line));
end;

procedure TFSection.ClearBufers;
begin
  inherited;
  SetLength(FItems, 0);
end;

function TFSection.Formats: TArray<TLasFormat>;
begin
  Result := FItems;
end;

function TFSection.GetItem(const Mnem: string): PLasFormat;
 var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Length(FItems)-1 do if SameText(FItems[i].Mnem, Mnem) then Exit(@FItems[i]);
end;

function TFSection.IndexOff(const Mnem: string): Integer;
begin
  Result := Length(FItems)-1;
  while Result >= 0 do
   if SameText(Mnem, FItems[Result].Mnem) then Exit
   else Dec(Result);
end;

function TFSection.Mnems: TArray<string>;
 var
  i: Integer;
begin
  SetLength(Result, Length(FItems));
  for i := 0 to Length(FItems)-1 do Result[i] := FItems[i].Mnem;
end;

procedure TFSection.ToStrings(ss: TStrings);
 var
  d: TLasFormat;
begin
  inherited;
  for d in FItems do ss.Add(Format('%12s.%-5s %-30s : %s', [d.Mnem,d.Units,d.Data,d.Description]));
end;

{ TCSection }

procedure TCSection.Add(const NewItem: TLasFormat);
begin
  inherited;
  CArray.Add<string>(FDispStr, '');
end;

procedure TCSection.ClearBufers;
begin
  inherited;
  SetLength(FDispStr, 0);
end;

function TCSection.GetDisplayFormat(const Mnem: string): string;
 var
  i: Integer;
begin
  for i := 0 to Length(FItems)-1 do if SameText(Mnem, Fitems[i].Mnem) then Exit(FDispStr[i]);
  Result := '';
end;

function TCSection.MnemsToString: String;
 var
  i: Integer;
begin
  Result := Format('%6s',[FItems[0].Mnem]);
  for i := 1 to Length(FItems)-1 do Result := Result + Format(' %10.10s',[FItems[i].Mnem]);
end;

procedure TCSection.SetDisplayFormat(const Mnem, Value: string);
 var
  i: Integer;
begin
  for i := 0 to Length(FItems)-1 do if SameText(Mnem, Fitems[i].Mnem) then FDispStr[i] := Value;
end;

{ TDSection }

procedure TDSection.AddData(const Data: array of Variant);
 var
  i: Integer;
  v: TArray<Variant>;
begin
  SetLength(v, Length(Data));
  for i := 0 to Length(v)-1 do v[i] := Data[i];
  CArray.Add<TArray<Variant>>(FData, v); // FData := FData + v;
end;

procedure TDSection.AddLine(const line: String);
 var
  sd: TArray<string>;
  s: string;
  i: Integer;
  d: Double;
begin
  sd := line.Split([' '], TStringSplitOptions.ExcludeEmpty);
  for  i := 0 to Length(sd)-1 do
   begin
    s := Trim(sd[i]);
    if TryStrToFloat(s, d) then
     begin
      if d = sNul then RowData[CurrIndex] := Null
      else RowData[CurrIndex] := d
     end
    else RowData[CurrIndex] := s;
    Inc(CurrIndex);
   end;
  if CurrIndex = Length(RowData) then
   begin
     AddData(RowData);
     CurrIndex := 0;
   end;
end;

function TDSection.CheckData(const Data: array of Variant): Boolean;
begin
  Result := Length(TCSection(FOwner.Curve).FItems) = Length(Data);
end;

procedure TDSection.Clear;
begin
  SetLength(Fdata, 0);
end;

procedure TDSection.ClearBufers;
begin
  inherited;
  try
   sNul := Double(FOwner.Well.Items['NULL'].Value);
  except
   sNul := -999.25;
  end;
  SetLength(RowData, DataLength);
  Clear;
end;

destructor TDSection.Destroy;
begin
  TDebug.Log('TDSection.Destroy');
  inherited;
end;

function TDSection.GetData: TArray<TArray<Variant>>;
begin
  Result := FData;
end;

function TDSection.GetDataLength: integer;
begin
  Exit(Length(FOwner.Curve.Mnems));
end;

function TDSection.RowToString(Index: Integer): string;
 var
  i: Integer;
  v: TArray<Variant>;
  cs: TCSection;
begin
  v := FData[Index];
  Result := '';
  cs := TCSection(FOwner.Curve);
  for i := 0 to Length(v)-1 do
   if VarIsNull(v[i]) then
     Result := Result + Format(' %10s',[FOwner.Well.Items['NULL'].Data])
   else if cs.FDispStr[i] <> '' then
     Result := Result + Format(cs.FDispStr[i],[Double(v[i])])
   else
     Result := Result +  Format(' %10s',[String(v[i])]);
end;

procedure TDSection.ToStrings(ss: TStrings);
 var
  i: Integer;
begin
  inherited;
  for i:=0 to Length(Fdata)-1 do ss.Add(RowToString(i));
end;

{$ENDREGION}

{ TLasDoc }

constructor TLasDoc.Create(EmptyCurve: Boolean);
 var
  s: TFSection;
begin
//  inherited Create;
  FEncoding := lsenANSI;

  s := TFSection.Create(Self, '~V', ['~Version Information']);
  s.Add(LAS_V_VERS);
  s.Add(LAS_V_WRAP);
  FSections[lsVersion] := s;

  s := TFSection.Create(Self,'~W', ['~Well Information Block',
                               '#MNEM.UNIT                DATA                         DESCRIPTION',
                               '#----- -----           ----------           -----------------------']);
  s.Add(LAS_W_STRT); { TODO : Данные проекта должны добавляться автоматом из БД }
  s.Add(LAS_W_STOP);
  s.Add(LAS_W_STEP);
  s.Add(LAS_W_NULL);
  s.Add(LAS_W_COMP);
  s.Add(LAS_W_WELL);
  s.Add(LAS_W_FLD);
  s.Add(LAS_W_LOC);
  s.Add(LAS_W_PROV);
  s.Add(LAS_W_SRVC);
  s.Add(LAS_W_LIC);
  s.Add(LAS_W_DATE);
  s.Add(LAS_W_UWI);
  FSections[lsWell] := s;

  s := TCSection.Create(Self, '~C', ['~Curve Information Block',
                               '#MNEM.UNIT                                    Curve Description',
                               '#---------                               ----------------------------']);
  if not EmptyCurve then s.Add(LAS_C_DEPT); { TODO : кривые должны добавляться автоматом из БД и метаданных XML диалога выбора параметров }
  FSections[lsCurve] := s;

  FSections[lsPar] := TFSection.Create(Self,'~P', [
  '~Parameter Information Section',
  '#MNEM.UNIT              Value                              Description',
  '#---------  ----------------------------------------   -----------------------------------']);

  FSections[lsOther] := TFSection.Create(Self,'~O', ['~O Прочие данные','#----------------------------']);

  FSections[lsLog] := TDSection.Create(Self, '~A', ['~Ascii Log data section']);
end;

function TLasDoc.Version: ILasFormatSection;
begin
  Result := FSections[lsVersion] as ILasFormatSection;
end;

function TLasDoc.Curve: ICurveSection;
begin
  Result := FSections[lsCurve] as ICurveSection;
end;

function TLasDoc.Data: ILasDataSection;
begin
  Result := FSections[lsLog] as ILasDataSection;
end;

destructor TLasDoc.Destroy;
begin
  TDebug.Log('TLasDoc.Destroy');
  inherited;
end;

function TLasDoc.GetDataCount: Integer;
begin
  Result := Length(Data.Items);
end;

function TLasDoc.GetEncoding: LasEncoding;
begin
  Result := FEncoding;
end;

function TLasDoc.GetFileName: string;
begin
 Result := FfileName;
end;

function TLasDoc.GetItem(const Mnem: string; Index: Integer): Variant;
 var
  i: Integer;
begin
  i := TFSection(Curve).IndexOff(Mnem);
  if i < 0 then Exit(VarNull); // raise Exception.Create('Error Message TLasDoc.GetItem(const Mnem: string; Index: Integer): Variant; i < 0');
  if Index >= DataCount then Exit(VarNull); //raise Exception.CreateFmt('Error Message TLasDoc.GetItem Index %d >= DataCount %d', [Index, DataCount]);
  var di := Data.Items[Index];
  if i< Length(di)then Exit(di[i])
  else Exit(VarNull);
end;

procedure TLasDoc.SetEncoding(const Value: LasEncoding);
begin
  FEncoding := Value;
end;

procedure TLasDoc.SetItem(const Mnem: string; Index: Integer; const Value: Variant);
 var
  i: Integer;
begin
  i := TFSection(Curve).IndexOff(Mnem);
  if i < 0 then raise Exception.Create('Error Message TLasDoc.GetItem(const Mnem: string; Index: Integer): Variant; i < 0');
  if Index >= DataCount then raise Exception.Create('Error Message TLasDoc.GetItem(const Mnem: string; Index: Integer): Variant; i < 0');
  var di := Data.Items[Index];
  if i >= Length(di) then
  begin
   SetLength(di,i+1);
   Data.Items[Index] := di;
  end;
  di[i] := Value;
end;

function TLasDoc.Well: ILasFormatSection;
begin
  Result := FSections[lsWell] as ILasFormatSection;
end;

function TLasDoc.Params: ILasFormatSection;
begin
  Result := FSections[lsPar] as ILasFormatSection;
end;

function TLasDoc.Other: IOptSection;
begin
  Result := FSections[lsOther] as IOptSection;
end;

procedure TLasDoc.LoadFromFile(const AFileName: String);
 var
  ss: TStrings;
  se: ILasSection;
begin
  ss := TStringList.Create;
  try
   ss.LoadFromFile(AFileName, GetLasEncoding(FEncoding));
   for se in FSections do TSection(se).FromStrings(ss);
  finally
   ss.Free;
  end;
  FfileName := AFileName;
end;

procedure TLasDoc.SaveToFile(const AFileName: String);
 var
  ss: TStrings;
  se: ILasSection;
  ds: TDSection;
begin
  ss := TStringList.Create;
  try
   ds := TDSection(Data);
   Well.Items['STRT'].Value := ds.FData[0, 0];
   Well.Items['STOP'].Value := ds.FData[High(ds.FData), 0];
   Well.Items['STEP'].Value := ds.FData[1, 0] - ds.FData[0, 0];
   ds.FPriambula[0] := '~A ' + TCSection(Curve).MnemsToString;
   for se in FSections do TSection(se).ToStrings(ss);
   ss.SaveToFile(AFileName, GetLasEncoding(FEncoding));
  finally
   ss.Free;
  end;
  FfileName := AFileName;
end;

end.
