unit CRC16;

interface

uses  System.SysUtils, Winapi.Windows;

type
 TrunCRC16 = function ( Data: Pbyte; First: word; Count: DWORD; var CRCLo, CRCHi: byte): word;

function  runCRC16( Data: Pbyte; First: word; Count: Dword; var CRCLo, CRCHi: byte): word;

procedure  SetCRC16(Data: Pbyte; Count, CRCFirst: word); overload;
procedure  SetCRC16( Data: Pbyte; Count: word);  overload;

function CRC16_Find(Data: Pbyte; Count: DWord; var CRC: word): boolean;
function TestCRC16(Data: Pbyte; Count: DWord; CRCFirst: word): boolean; overload;
function  TestCRC16(Data: Pbyte; Count: Dword): boolean; overload;

function  RVCRC16(Data: Pbyte; First: Word; Count: Integer): word;

function GetCRC8(const Buffer; Size: Integer): Byte;

var DefaultCRCFirst: Word = $FFFF;

const RIVAS_CRC_FIRST = $3BAC;

implementation


function CRC16_Find(Data: Pbyte; Count: DWord; var CRC: word): boolean;
 const
    CRCTBL : array[byte] of Word =(
    $0000, $C0C1, $C181, $0140, $C301, $03C0, $0280, $C241,
    $C601, $06C0, $0780, $C741, $0500, $C5C1, $C481, $0440,
    $CC01, $0CC0, $0D80, $CD41, $0F00, $CFC1, $CE81, $0E40,
    $0A00, $CAC1, $CB81, $0B40, $C901, $09C0, $0880, $C841,
    $D801, $18C0, $1980, $D941, $1B00, $DBC1, $DA81, $1A40,
    $1E00, $DEC1, $DF81, $1F40, $DD01, $1DC0, $1C80, $DC41,
    $1400, $D4C1, $D581, $1540, $D701, $17C0, $1680, $D641,
    $D201, $12C0, $1380, $D341, $1100, $D1C1, $D081, $1040,
    $F001, $30C0, $3180, $F141, $3300, $F3C1, $F281, $3240,
    $3600, $F6C1, $F781, $3740, $F501, $35C0, $3480, $F441,
    $3C00, $FCC1, $FD81, $3D40, $FF01, $3FC0, $3E80, $FE41,
    $FA01, $3AC0, $3B80, $FB41, $3900, $F9C1, $F881, $3840,
    $2800, $E8C1, $E981, $2940, $EB01, $2BC0, $2A80, $EA41,
    $EE01, $2EC0, $2F80, $EF41, $2D00, $EDC1, $EC81, $2C40,
    $E401, $24C0, $2580, $E541, $2700, $E7C1, $E681, $2640,
    $2200, $E2C1, $E381, $2340, $E101, $21C0, $2080, $E041,
    $A001, $60C0, $6180, $A141, $6300, $A3C1, $A281, $6240,
    $6600, $A6C1, $A781, $6740, $A501, $65C0, $6480, $A441,
    $6C00, $ACC1, $AD81, $6D40, $AF01, $6FC0, $6E80, $AE41,
    $AA01, $6AC0, $6B80, $AB41, $6900, $A9C1, $A881, $6840,
    $7800, $B8C1, $B981, $7940, $BB01, $7BC0, $7A80, $BA41,
    $BE01, $7EC0, $7F80, $BF41, $7D00, $BDC1, $BC81, $7C40,
    $B401, $74C0, $7580, $B541, $7700, $B7C1, $B681, $7640,
    $7200, $B2C1, $B381, $7340, $B101, $71C0, $7080, $B041,
    $5000, $90C1, $9181, $5140, $9301, $53C0, $5280, $9241,
    $9601, $56C0, $5780, $9741, $5500, $95C1, $9481, $5440,
    $9C01, $5CC0, $5D80, $9D41, $5F00, $9FC1, $9E81, $5E40,
    $5A00, $9AC1, $9B81, $5B40, $9901, $59C0, $5880, $9841,
    $8801, $48C0, $4980, $8941, $4B00, $8BC1, $8A81, $4A40,
    $4E00, $8EC1, $8F81, $4F40, $8D01, $4DC0, $4C80, $8C41,
    $4400, $84C1, $8581, $4540, $8701, $47C0, $4680, $8641,
    $8201, $42C0, $4380, $8341, $4100, $81C1, $8081, $4040);
     //nTemp = *nData++ ^ wCRCWord;
     //        wCRCWord >>= 8;
     //        wCRCWord  ^= wCRCTable[(nTemp & 0xFF)];
begin
   while Count > 0 do
    begin
     CRC := (CRC shr 8) xor CRCTBL[Byte(Data^ xor CRC)];
     Inc(Data);
     Dec(Count);
    end;
   Result := CRC = 0;
end;

const
TCRCHi:array[byte] of byte=(
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$01,$C0,$80,$41,$00,$C1,$81,$40,$00,$C1,$81,$40,$01,$C0,$80,$41,
$00,$C1,$81,$40,$01,$C0,$80,$41,$01,$C0,$80,$41,$00,$C1,$81,$40);
TCRCLo:array[byte] of byte=(
$00,$C0,$C1,$01,$C3,$03,$02,$C2,$C6,$06,$07,$C7,$05,$C5,$C4,$04,
$CC,$0C,$0D,$CD,$0F,$CF,$CE,$0E,$0A,$CA,$CB,$0B,$C9,$09,$08,$C8,
$D8,$18,$19,$D9,$1B,$DB,$DA,$1A,$1E,$DE,$DF,$1F,$DD,$1D,$1C,$DC,
$14,$D4,$D5,$15,$D7,$17,$16,$D6,$D2,$12,$13,$D3,$11,$D1,$D0,$10,
$F0,$30,$31,$F1,$33,$F3,$F2,$32,$36,$F6,$F7,$37,$F5,$35,$34,$F4,
$3C,$FC,$FD,$3D,$FF,$3F,$3E,$FE,$FA,$3A,$3B,$FB,$39,$F9,$F8,$38,
$28,$E8,$E9,$29,$EB,$2B,$2A,$EA,$EE,$2E,$2F,$EF,$2D,$ED,$EC,$2C,
$E4,$24,$25,$E5,$27,$E7,$E6,$26,$22,$E2,$E3,$23,$E1,$21,$20,$E0,
$A0,$60,$61,$A1,$63,$A3,$A2,$62,$66,$A6,$A7,$67,$A5,$65,$64,$A4,
$6C,$AC,$AD,$6D,$AF,$6F,$6E,$AE,$AA,$6A,$6B,$AB,$69,$A9,$A8,$68,
$78,$B8,$B9,$79,$BB,$7B,$7A,$BA,$BE,$7E,$7F,$BF,$7D,$BD,$BC,$7C,
$B4,$74,$75,$B5,$77,$B7,$B6,$76,$72,$B2,$B3,$73,$B1,$71,$70,$B0,
$50,$90,$91,$51,$93,$53,$52,$92,$96,$56,$57,$97,$55,$95,$94,$54,
$9C,$5C,$5D,$9D,$5F,$9F,$9E,$5E,$5A,$9A,$9B,$5B,$99,$59,$58,$98,
$88,$48,$49,$89,$4B,$8B,$8A,$4A,$4E,$8E,$8F,$4F,$8D,$4D,$4C,$8C,
$44,$84,$85,$45,$87,$47,$46,$86,$82,$42,$43,$83,$41,$81,$80,$40);

function  runCRC16( Data: Pbyte; First: word; Count: DWORD; var CRCLo, CRCHi: byte): word;
 var
  i,t: integer;
begin
  CRCLo := Byte(First shr 8);//$FF;
  CRCHi := Byte(First); //$FF;
//  CRCLo := First;//$FF;
//  CRCHi := First shr 8; //$FF;
  for i:=0 to Count-1 do
   begin
    t := CRCHi xor Data^;
    CRCHi := CRCLo xor TCRCHi[t];
    CRCLo := TCRCLo[t];
    inc(Data);
   end;
  i := CRCLo;
  CRCLo := CRCHi;
  CRCHi := i;
  Result := word(CRCHi shl 8 or CRCLo);
end;

function TestCRC16(Data: Pbyte; Count: DWord; CRCFirst: word): boolean; overload;
 var
  CRCLo, CRCHi: byte;
begin
  Result:=false;
  runCRC16(Data, CRCFirst, Count-2, CRCLo, CRCHi);
  inc(Data,Count-2);
  if Data^ = CRCLo then
   begin
    inc(Data);
    if Data^ = CRCHi then Result := True;
   end
end;

function TestCRC16(Data: Pbyte; Count: Dword): boolean; overload;
 var
  CRCLo, CRCHi: byte;
begin
  Result := false;
  if count < 2 then Exit;
  runCRC16(Data, DefaultCRCFirst, Count-2, CRCLo, CRCHi);
  inc(Data,Count-2);
  if Data^ = CRCLo then
   begin
    inc(Data);
    if Data^ = CRCHi then Result := True;
   end
end;

procedure  SetCRC16(Data: Pbyte; Count: word; CRCFirst: word); overload;
 var
  CRCLo, CRCHi: byte;
begin
  runCRC16(Data, CRCFirst, Count, CRCLo, CRCHi);
  inc(Data,Count);
  Data^:=CRCLo;
  inc(Data);
  Data^:=CRCHi;
end;

procedure  SetCRC16( Data: Pbyte; Count: word); overload;
 var
  CRCLo, CRCHi: byte;
begin
  runCRC16(Data, DefaultCRCFirst, Count, CRCLo, CRCHi);
  inc(Data,Count);
  Data^:=CRCLo;
  inc(Data);
  Data^:=CRCHi;
end;

function  RVCRC16(Data: Pbyte; First: Word; Count: Integer): word;
 var
  CRCLo, CRCHi, t: byte;
  i: integer;
begin
  CRCHi := First shr 8;//$FF;
  CRCLo := First; //$FF;
  for i:=0 to Count-1 do
   begin
    t := CRCHi xor Data^;
    CRCHi := CRCLo xor TCRCHi[t];
    CRCLo := TCRCLo[t];
    inc(Data);
   end;
  i := CRCLo;
  CRCLo := CRCHi;
  CRCHi := i;
  Result := word(CRCHi shl 8 or CRCLo);
end;
{function RVTestCRC16(Data: Pbyte; First, Count: word): boolean;
 var
  CRCLo, CRCHi: byte;
begin
  Result:=false;
  runCRC16(Data, First, Count-2, CRCLo, CRCHi);
  inc(Data,Count-2);
  if Data^ = CRCLo then
   begin
    inc(Data);
    if Data^ = CRCHi then Result := True;
   end
end;

procedure RVSetCRC16(Data: Pbyte; First, Count: word);
 var
  CRCLo, CRCHi: byte;
begin
  runCRC16(Data, First, Count, CRCLo, CRCHi);
  inc(Data,Count);
  Data^:=CRCLo;
  inc(Data);
  Data^:=CRCHi;
end;}


function GetCRC8(const Buffer; Size: Integer): Byte;
 const
  CRCTable : array [0..255] of byte = (
    0,94,188,226,97,63,221,131,194,156,126,32,163,253,31,65,
    157,195,33,127,252,162,64,30,95,1,227,189,62,96,130,220,
    35,125,159,193,66,28,254,160,225,191,93,3,128,222,60,98,
    190,224,2,92,223,129,99,61,124,34,192,158,29,67,161,255,
    70,24,250,164,39,121,155,197,132,218,56,102,229,187,89,7,
    219,133,103,57,186,228,6,88,25,71,165,251,120,38,196,154,
    101,59,217,135,4,90,184,230,167,249,27,69,198,152,122,36,
    248,166,68,26,153,199,37,123,58,100,134,216,91,5,231,185,
    140,210,48,110,237,179,81,15,78,16,242,172,47,113,147,205,
    17,79,173,243,112,46,204,146,211,141,111,49,178,236,14,80,
    175,241,19,77,206,144,114,44,109,51,209,143,12,82,176,238,
    50,108,142,208,83,13,239,177,240,174,76,18,145,207,45,115,
    202,148,118,40,171,245,23,73,8,86,180,234,105,55,213,139,
    87,9,235,181,54,104,138,212,149,203,41,119,244,170,72,22,
    233,183,85,11,136,214,52,106,43,117,151,201,74,20,246,168,
    116,42,200,150,21,75,169,247,182,232,10,84,215,137,107,53);
 var
  Buf: PByte;
begin
  Buf := @Buffer;
  Result := 0;
  repeat
   Result := CRCTable[Result xor Buf^];
   inc(Buf);
   Dec(Size);
  until Size = 0;
end;
end.
