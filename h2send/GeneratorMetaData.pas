unit GeneratorMetaData;

interface

uses   System.SysUtils, System.classes, System.Generics.Collections;


const BIT_PER_COD = 5;

type

  TipInfo = record
   tip: Integer;
   name: string;
   st: string;
   len: Integer;
 end;

 Tattr = record
  name: string;
  value: string;
 end;

 TAnyDef = class
   name: string;
   attrs: TArray<Tattr>;
 end;
 TAnyImpl = class(TAnyDef)
   arraylen: integer;
 end;
  TComplexDef = class(TAnyDef)
    Items: TArray<TAnyImpl>;
  end;

  TSimpleImpl = class(TAnyImpl)
   tip: TipInfo;
  end;
  TComplexImpl = class(TAnyImpl)
    tname: string;
  end;


  //enum support_type_e
{
  INT8, INT16, INT32, FLOAT,
  UINT8, UINT16, UINT32, UFLOAT,
}
const INT8 = 0;
const INT16=1;
const INT32=2;
const FLOAT=3;
const UINT8=4;
const UINT16=5;
const UINT32=6;
const UFLOAT=7;

 const STD_ATTRS: array[0..6] of string = ('bits','delta','kmul','kdiv', 'from','to','send');

 const STD_TYPES: array[0..7] of TipInfo =(
   (tip: INT8;   name: 'int8_t';    st: 'INT8';  len:1  ),
   (tip: INT16;  name: 'int16_t';   st: 'INT16'; len:2  ),
   (tip: INT32;  name: 'int32_t';   st: 'INT32'; len:4  ),
   (tip: FLOAT;  name: 'float';     st: 'FLOAT'; len:4  ),
   (tip: UINT8;  name: 'uint8_t';   st: 'UINT8';  len:1 ),
   (tip: UINT16; name: 'uint16_t';  st: 'UINT16'; len:2 ),
   (tip: UINT32; name: 'uint32_t';  st: 'UINT32'; len:4 ),
   (tip: UFLOAT; name: 'ufloat';    st: 'UFLOAT'; len:4 )
 );

type
  TGeneratorMetaData = class
  private
    FDefines: TDictionary<string, string>;
    FStructs: TArray<TComplexDef>;
    FOneNames: TArray<string>;
    FexpandedStruct: TComplexDef;
    row, col: integer;
    token: string;
    TokRow: TArray<string>;
    CurTok: array[0..100] of string;
    CurrenAttrs: TArray<Tattr>;
    CurrentStruct: TComplexDef;
    tockens: TArray<TArray<string>>;
    function CheckIncCol: boolean;
    function ExtractTokens(const ToTocken: string): TArray<string>;
    function GetTokens(n: integer = 100; rowonly: boolean = true): boolean;
    function CheckIncRow: boolean;
    function AttrFactory: TAttr;
    function GetValue(const s: string): string;
    function SimpleCreate(d: TipInfo; const tocs: Tarray<string>): TSimpleImpl;
    function ComplexCreate(tname:string; const tocs: Tarray<string>): TComplexImpl;
    procedure AssignAnyImpl(ad: TAnyImpl;const tocs: Tarray<string>);
    procedure RaiseException(const message: string);
    procedure GenerateStruct(const prefix: string; outss: TStrings; st:TComplexImpl; var LenGen, offset,OffsetInArray,OffsetInBit: integer);
    procedure GenerateStructDef(const prefix: string; outss: TStrings; st:TComplexDef; var LenGen, offset,OffsetInArray,OffsetInBit: integer);
    procedure GenerateSimple(const prefix: string; outss: TStrings; st:TSimpleImpl; var LenGen, offset,OffsetInArray,OffsetInBit: integer);
  public
    constructor Create(tockens: TArray<TArray<string>>);
    procedure Parse;
    procedure Generate(outss: TStrings; const MetaName: string);
  end;


implementation

{ TGeneratorMetaData }

function StrAsInt(val: string): Integer;
begin
  if val = '' then Exit(0);
  if val.StartsWith('0x', True) then
    val := val.Replace('0x', '$', [rfIgnoreCase]);
   Result := StrToInt(val);//.ToInteger();
end;


function TGeneratorMetaData.CheckIncCol: boolean;
begin
  inc(col);
  Result := col < Length(TokRow);
end;

function TGeneratorMetaData.CheckIncRow: boolean;
begin
  inc(Row);
  Result := Row < Length(tockens);
  if Result then
   begin
    TokRow := tockens[row];
    col := -1;
   end;
end;

function TGeneratorMetaData.GetTokens(n: integer = 100; rowonly: boolean = true): boolean;
begin
  Result := True;
  for var j := 0 to n-1 do
   begin
    if not CheckIncCol then
     if rowonly then exit(false)
     else if not CheckIncRow then exit(false);
    CurTok[j] := TokRow[col];
   end;
end;

function TGeneratorMetaData.GetValue(const s: string): string;
 var
  v: string;
begin
  Result := s;
  while FDefines.TryGetValue(Result, v) do Result := v;
end;

function TGeneratorMetaData.ExtractTokens(const ToTocken: string): TArray<string>;
begin
 Result := [];
 repeat
  while CheckIncCol do
   if TokRow[col] = '/*' then ExtractTokens('*/')
   else if TokRow[col] = ToTocken then Exit
   else Result := Result + [TokRow[col]];
//    Result := Result + [#$D#$A];
 until not CheckIncRow;
end;

procedure TGeneratorMetaData.RaiseException(const message: string);
begin
  raise Exception.Createfmt('%s'+#$D#$A+'tok:%d row:%d toc: %s %s %s %s %s %s', [message,col,row,
  token, CurTok[0], CurTok[1], CurTok[2], CurTok[3], CurTok[4]]);
end;

function TGeneratorMetaData.SimpleCreate(d: TipInfo; const tocs: Tarray<string>): TSimpleImpl;
begin
  Result := TSimpleImpl.Create;
  Result.tip := d;
  Result.attrs := Copy(CurrenAttrs,0,Length(CurrenAttrs));
  AssignAnyImpl(Result,tocs);
end;

function TGeneratorMetaData.ComplexCreate(tname: string; const tocs: Tarray<string>): TComplexImpl;
begin
  Result := TComplexImpl.Create;
  Result.tname := tname;
  AssignAnyImpl(Result,tocs);
end;

procedure TGeneratorMetaData.AssignAnyImpl(ad: TAnyImpl; const tocs: Tarray<string>);
begin
  ad.name := tocs[0];
  if (Length(tocs) >=4) and (tocs[1] ='[') and  (tocs[3] =']') then
  begin
    ad.arraylen :=  StrAsInt(GetValue(tocs[2]));
  end
  else ad.arraylen := 1;
end;

function TGeneratorMetaData.AttrFactory(): TAttr;
begin
  GetTokens();
  for var a in STD_ATTRS do if a = CurTok[0] then
   begin
    Result.name := CurTok[0];
    Result.value := GetValue(CurTok[2]);//may bee bad last value   for //- send
    Exit;
   end;
  RaiseException(Format('атрибут с именем(%s) не найден', [CurTok[0]]));
end;

constructor TGeneratorMetaData.Create(tockens: TArray<TArray<string>>);
begin
  Self.tockens := tockens;
  FDefines:= TDictionary<string, string>.Create;
end;

procedure TGeneratorMetaData.Parse;
begin
   CurrentStruct := nil;
   row := -1;
   while row < Length(tockens) do
    begin
     if not CheckIncRow then Exit;
     while col < Length(TokRow) do
      begin
       if not CheckIncCol then break;
       token := TokRow[col];
       // поддерживаем  простые дефайны 10,16чные числа
       if token = '#' then
        begin
         if not GetTokens(3) then break;
         if CurTok[0] = 'define' then
          begin
           FDefines.AddOrSetValue(CurTok[1], CurTok[2]);
          end;
         Break;
        end
       // поддерживаем  многострочные коментарии
       else if token = '/*' then  ExtractTokens('*/')
       // добавляем атрибуты
       else if token = '//%' then
        begin
         CurrenAttrs := CurrenAttrs + [AttrFactory()];
         Break;
        end
       // добавляем данные структуры
       else if Assigned(CurrentStruct) then
        begin
         var bCre := false;
         // создаем данные стандартного типа...
         for var d in STD_TYPES do if d.name = token then
         begin
           CurrentStruct.Items := CurrentStruct.Items + [SimpleCreate(d,ExtractTokens(';'))];
           bCre := True;
           Break;
         end;
       // ...или создаем данные структурного типа
         if not bCre then for var s in FStructs do if s.name = token then
         begin
          CurrentStruct.Items := CurrentStruct.Items + [ComplexCreate(s.name,ExtractTokens(';'))];
          bCre := True;
          Break;
         end;
        // добавляем данные структуры (сбрасываем атрибуты)....
        if bCre then
         begin
          CurrenAttrs := [];
         end
       // ...или проверяем окончание структуры....
        else if token = '}' then
          begin
           GetTokens(1);
           CurrentStruct.name := CurTok[0];
           FStructs := FStructs + [CurrentStruct];
           CurrenAttrs := [];
           CurrentStruct := nil;
          end
          else
       // ...или ошибка структуры
          begin
            RaiseException('ошибка структуры');
          end;
        end
       // начинаем добавлять структурy
       else if token = 'typedef' then
        begin
         if not GetTokens(1) then break;
         if (CurTok[0] = 'struct') then
          begin
           ExtractTokens('{');
           CurrentStruct := TcomplexDef.Create;
           CurrentStruct.attrs := Copy(CurrenAttrs, 0, Length(CurrenAttrs));
           CurrenAttrs := [];
          end;
        end
      end;
    end;
end;


const PREAMB ='#pragma once'#$D#$A+
               #$D#$A+
              '#include "packer.h"'#$D#$A#$D#$A+
              '#define LEN_ARRAY_GENERATED %d'#$D#$A+
              '#define LEN_ARRAY5BIT %d'#$D#$A+
              '#define CNT_UNUSEDBITS %d'#$D#$A+
               #$D#$A+
              '/// @brief  упаковка данных по 5 бит'#$D#$A+
              '/// @param inData указатель на структуру данных для передачи'#$D#$A+
              '/// @param outData указатель на массив выходных данных uint8_t TRANS_5BitData[1+4+LEN_ARRAY5BIT+1]; &TRANS_5BitData[5]'#$D#$A+
              '#define Encode(inData, outData) inner_Encode(inData, outData, %3:s,LEN_ARRAY_GENERATED)'#$D#$A+
              #$D#$A+
              '/// @brief распаковка данных по 5 бит'#$D#$A+
              '/// @param inData указатель на массив принятых данных uint8_t DECODE_5BitData[LEN_ARRAY5BIT]; &DECODE_5BitData[0]'#$D#$A+
              '/// @param outData указатель на структуру данных для передачи'#$D#$A+
              '#define Decode(inData, outData) inner_Decode(inData, outData, %3:s,LEN_ARRAY_GENERATED)'#$D#$A+
              #$D#$A+
              '/// @brief возвращает достоверность члена данных структуры'#$D#$A+
              '/// @param %3:s_field имя из %3:s_fields'#$D#$A+
              '/// @param inQuality указатель на массив качества принятых данных в процентах'#$D#$A+
              '/// @return качество данных в процентах'#$D#$A+
              '#define Quality(%3:s_field, inQuality) inner_Quality(%3:s_field,inQuality, %3:s, LEN_ARRAY_GENERATED)'#$D#$A+
              #$D#$A+
              'enum %3:s_fields {'#$D#$A+
              '%4s'#$D#$A+
              '};'#$D#$A+
              #$D#$A+
              'const GeneratedItem_t %3:s[LEN_ARRAY_GENERATED] = {'#$D#$A+
              '// TYPE |OFF|BTS|5BL|5BI|BI|      delta           |        amp';

const AMUL = '};'#$D#$A#$D#$A;

procedure TGeneratorMetaData.Generate(outss: TStrings; const MetaName: string);

 var
  offset, OffsetInArray, LenGen,
  OffsetInBit: integer;
begin
  LenGen :=0;
  offset := 0;
  OffsetInArray := 0;
  OffsetInBit := 0;
  for var st in FStructs do
   for var a in st.attrs do
     if a.name = 'send' then
     begin
      var ss: Tstrings;
      ss := TstringList.Create;
      try
        GenerateStructDef('', ss, st,LenGen, offset, OffsetInArray, OffsetInBit);
        // generate preambula
        if OffsetInBit > 0 then
              outss.Add(Format(PREAMB,[LenGen, OffsetInArray+1, 5-OffsetInBit, MetaName, string.Join(',', FOneNames)]))
        else  outss.Add(Format(PREAMB,[LenGen, OffsetInArray, 0, MetaName, string.Join(',', FOneNames)]));
        outss.AddStrings(ss);
        // generate ambula
        outss.Add(AMUL);
      finally
        ss.Free;
      end;
      exit;
     end;
end;

//typedef struct
{
    support_type_e type;    // тип данных
    uint16_t offset;        // смещение в структуре данных для передачи
    uint8_t bits;           // атрибут bits число бит для передачи (точность)
    //uint8_t N5bit;         // сколько 5bit данных в массиве занимает величина 1..7 вычисляется
    uint8_t OffsetInArray;   // начиная с какого элемента в 5bit массиве
    uint8_t OffsetInBit;     // начиная с какого бита первого элемента в 5bit массиве  0..4
    float delta;             // атрибут delta
    float kamp;              // атрибуты kmul/kdiv
} //GeneratedItem_t;

procedure TGeneratorMetaData.GenerateSimple(const prefix: string; outss: TStrings; st: TSimpleImpl; var LenGen, offset, OffsetInArray, OffsetInBit: integer);
  function GetAtr(const atr: string; out val: string): Boolean;
  begin
    for var a in st.attrs do
      if a.name = atr then
        begin
         val := a.value;
         Exit(True);
        end;
    Result := False;
  end;
  procedure OneSimple(const NameOne: string);
   var
    amp: double;
    delta: double;
    bits: integer;
    val: string;
  begin
    FOneNames := FOneNames +[NameOne.Replace('.','').Replace('[','').Replace(']','')];
    bits := 8;
    amp := 1;
    delta := 0.0;
    if GetAtr('bits',val) then bits := val.ToInteger;
    if GetAtr('delta',val) then
     begin
      delta := val.ToDouble;
     end;
    if GetAtr('kmul', val) then amp := val.ToDouble;
    if GetAtr('kdiv', val) then amp := amp / val.ToDouble;
    if GetAtr('to', val) then
     begin
       var signed := st.tip.tip <= FLOAT;
       var too: double := val.ToDouble; // >0 raise
       if too < 0 then raise Exception.CreateFmt('Error attr "to" lower zerro 0 < %f',[too]);
       var from: double := 0; // if signed -sub zero
       if signed then from := - too;
       if GetAtr('from', val) then from := val.ToDouble;
       if signed then
       begin
        if from >= 0 then raise Exception.CreateFmt('Error signed val attr "from" >= 0 (%f)!!!',[from]);
        delta := -(too + from)/2;
        too := too + delta; //+range
        from := too + delta;//-range
        amp := ((1 shl (bits-1)) - 1)/ too;
       end
       else
       begin
         if from < 0 then raise Exception.CreateFmt('Error unsigned val attr "from" < 0 (%f)!!!',[from]);
         delta := -from;
         too := too - from; // range
         amp := ((1 shl bits) - 1)/ too;
       end;
     end;

    var oia := OffsetInArray;
    var oib := OffsetInBit;
    var nb5 := 1;
    var bts := bits;

    while bts > 0 do
     begin
      Dec(bts);
      inc(OffsetInBit);
      if OffsetInBit = BIT_PER_COD then
       begin
        inc(nb5);
        inc(OffsetInArray);
        OffsetInBit := 0;
       end;
     end;
     if OffsetInBit=0 then Dec(nb5);

        outss.Add(Format('{%-7s,%3d,%3d,%3d,%3d,%d, %22e,%22e}, // %s',[st.tip.st,offset, bits, nb5, oia, oib, delta, amp, NameOne]));

    inc(offset, st.tip.len);
    inc(LenGen);
  end;
begin
  var name := st.name;
  if prefix<>'' then name := prefix+'.'+ name;
  if st.arraylen > 1 then
    for var I := 0 to st.arraylen-1 do
       OneSimple(Format('%s[%d]',[name,i]))
  else OneSimple(name);
end;

procedure TGeneratorMetaData.GenerateStruct(const prefix: string; outss: TStrings; st: TComplexImpl; var LenGen, offset, OffsetInArray, OffsetInBit: integer);
begin
  var name := st.name;
  if prefix<>'' then name := prefix+'.'+ name;
  for var std in FStructs do
   if st.tname = std.name then
   begin
    if st.arraylen > 1 then
      for var I := 0 to st.arraylen-1 do
         GenerateStructDef(Format('%s[%d]',[name,i]), outss, std ,LenGen, offset, OffsetInArray, OffsetInBit)
      else
         GenerateStructDef(name, outss, std,LenGen, offset, OffsetInArray, OffsetInBit);
    Break
   end;
end;

procedure TGeneratorMetaData.GenerateStructDef(const prefix: string; outss: TStrings; st: TComplexDef; var LenGen, offset, OffsetInArray, OffsetInBit: integer);
begin
  for var itm in st.Items do
   begin
    if itm is TSimpleImpl then
      GenerateSimple(prefix, outss, TSimpleImpl(itm),LenGen, offset, OffsetInArray, OffsetInBit)
    else
      GenerateStruct(prefix, outss, TComplexImpl(itm),LenGen, offset, OffsetInArray, OffsetInBit)
   end;
end;

end.
