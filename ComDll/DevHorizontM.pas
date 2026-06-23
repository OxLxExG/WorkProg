unit DevHorizontM;

interface

uses  tools, System.IOUtils, RootIntf, Parser,   ProtocolBurUnit,
  Winapi.Windows, System.SysUtils, System.Classes, CPort, Vcl.ExtCtrls, System.Variants, Xml.XMLIntf, Xml.XMLDoc,
  Generics.Collections,  Vcl.Forms, Vcl.Dialogs,Vcl.Controls, Actns,
  DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

{$IFDEF ENG_VERSION}
 const
   RS_Info1='<I> Информация';
   RS_Info2='0:Управление|3.<I>;2:';
   RS_Info3='Выход/Вход в режим чтения информации';
{$ELSE}
 const
   RS_Info1='<I> Информация';
   RS_Info2='0:Управление|3.<I>;2:';
   RS_Info3='Выход/Вход в режим чтения информации';
{$ENDIF}

type
  EHMException = class(EDeviceException);
   EAsyncHMException = class(EAsyncDeviceException);

  TDeviceHM = class(TAbstractDevice, IDevice, IDataDevice,{ICycle, ICycleEx,} IGetActions)
  private
    FOldStatus: TDeviceStatus;
    FTmpSender: IAction;
//    Ftimer: TTimer;
//    FCycle: TCycleEx;
    FGetActions: TGetActionsImpl;
//    procedure OnTimer(Sender: TObject);
    procedure InfoEvent(Res: TInfoEventRes);
  protected
  //IDataDevice
    FStartWork: Boolean;
    Fmetadata: TArray<Byte>;
    procedure InitMetaData(ev: TInfoEvent);
    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false);

 //   procedure BeginReadWork;
    procedure EndReadWork;

    property GetActions: TGetActionsImpl read FGetActions implements IGetActions;
  public
    constructor Create(); override;
    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); override;
    destructor Destroy; override;
    procedure CheckConnect(); override;
  //  property Cycle: TCycleEx read FCycle implements  ICycle, ICycleEx;
// actions
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [DynamicAction(RS_Info1, '<I>', 52, RS_Info2, RS_Info3)]
    procedure DoData(Sender: IAction);
//    [DynamicAction('Выключить прибор', '<I>', 71, '0:Управление|3.<I>.Дополнительно|0', 'Перевести приборы в спящий режим')]
    procedure DoIdle(Sender: IAction);
//  published
 //   property CyclePeriod;
  end;

implementation


{$REGION 'CRC'}

const wCRCTable: array of word  = [
        $0000, $1021, $2042, $3063, $4084, $50A5, $60C6, $70E7,
        $8108, $9129, $A14A, $B16B, $C18C, $D1AD, $E1CE, $F1EF,
        $1231, $0210, $3273, $2252, $52B5, $4294, $72F7, $62D6,
        $9339, $8318, $B37B, $A35A, $D3BD, $C39C, $F3FF, $E3DE,
        $2462, $3443, $0420, $1401, $64E6, $74C7, $44A4, $5485,
        $A56A, $B54B, $8528, $9509, $E5EE, $F5CF, $C5AC, $D58D,
        $3653, $2672, $1611, $0630, $76D7, $66F6, $5695, $46B4,
        $B75B, $A77A, $9719, $8738, $F7DF, $E7FE, $D79D, $C7BC,
        $48C4, $58E5, $6886, $78A7, $0840, $1861, $2802, $3823,
        $C9CC, $D9ED, $E98E, $F9AF, $8948, $9969, $A90A, $B92B,
        $5AF5, $4AD4, $7AB7, $6A96, $1A71, $0A50, $3A33, $2A12,
        $DBFD, $CBDC, $FBBF, $EB9E, $9B79, $8B58, $BB3B, $AB1A,
        $6CA6, $7C87, $4CE4, $5CC5, $2C22, $3C03, $0C60, $1C41,
        $EDAE, $FD8F, $CDEC, $DDCD, $AD2A, $BD0B, $8D68, $9D49,
        $7E97, $6EB6, $5ED5, $4EF4, $3E13, $2E32, $1E51, $0E70,
        $FF9F, $EFBE, $DFDD, $CFFC, $BF1B, $AF3A, $9F59, $8F78,
        $9188, $81A9, $B1CA, $A1EB, $D10C, $C12D, $F14E, $E16F,
        $1080, $00A1, $30C2, $20E3, $5004, $4025, $7046, $6067,
        $83B9, $9398, $A3FB, $B3DA, $C33D, $D31C, $E37F, $F35E,
        $02B1, $1290, $22F3, $32D2, $4235, $5214, $6277, $7256,
        $B5EA, $A5CB, $95A8, $8589, $F56E, $E54F, $D52C, $C50D,
        $34E2, $24C3, $14A0, $0481, $7466, $6447, $5424, $4405,
        $A7DB, $B7FA, $8799, $97B8, $E75F, $F77E, $C71D, $D73C,
        $26D3, $36F2, $0691, $16B0, $6657, $7676, $4615, $5634,
        $D94C, $C96D, $F90E, $E92F, $99C8, $89E9, $B98A, $A9AB,
        $5844, $4865, $7806, $6827, $18C0, $08E1, $3882, $28A3,
        $CB7D, $DB5C, $EB3F, $FB1E, $8BF9, $9BD8, $ABBB, $BB9A,
        $4A75, $5A54, $6A37, $7A16, $0AF1, $1AD0, $2AB3, $3A92,
        $FD2E, $ED0F, $DD6C, $CD4D, $BDAA, $AD8B, $9DE8, $8DC9,
        $7C26, $6C07, $5C64, $4C45, $3CA2, $2C83, $1CE0, $0CC1,
        $EF1F, $FF3E, $CF5D, $DF7C, $AF9B, $BFBA, $8FD9, $9FF8,
        $6E17, $7E36, $4E55, $5E74, $2E93, $3EB2, $0ED1, $1EF0 ];

function Crc16(arr:PByte; len: integer): Word;  // CRC-CCITT
begin
    Result := $0000;
    for var i := 0 to len-1 do
       begin
        Result := (Result shl 8) xor wCRCTable[(Result shr 8) xor arr^];
        Inc(arr);
        end;
end;

{$ENDREGION 'CRC' }

{$REGION 'ProtocolHM'}
//   const AMBULAPK = #5F#12#04#07;
   const AMBULA_OUT = $0704125F;
//   const AMBULACP = #3B#12#03#10;
   const AMBULA_IN = $1003123B;

type
  Phmrec= ^Thmrec;
  Thmrec = packed record
  bip, len, bpk, cmd, kv: Byte;
  constructor Create(Abpk, Acmd:Byte);
  function data: Pointer;
end;

constructor Thmrec.Create(Abpk, Acmd: Byte);
begin
  bip := 0;
  len := 5;
  bpk := Abpk;
  cmd := Acmd;
  kv  := 0;
end;

function Thmrec.data: Pointer;
begin
  Result := @kv;
  Inc(Pbyte(Result), 1);
end;


type
  TProtocolHM = class(TProtocolBur)
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
    procedure EventRxChar(Sender: TAbstractConnectIO); override;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $200); override;
  end;

{ TProtocolHM }

procedure TProtocolHM.EventRxChar(Sender: TAbstractConnectIO);
var
//  n, o: Integer;
//  Lo, Hi: byte;
  data: array[0..$10000]of Byte;
begin
  Sender.FTimerRxTimeOut.Enabled := False;
  if (Sender.FICount >= 4+5) and (PInteger(@Sender.FInput[0])^ = AMBULA_IN) then
//  n := Sender.FICount - FOldCount;
//  o := FOldCount;
//  FOldCount := Sender.FICount;
  with Sender do
   begin
    var idx := 4;
    var cnt := 0;
    var p: Phmrec;
    repeat
     p := Phmrec(@FInput[idx]);
     if (FICount < idx+p.len+2) then
      begin
       FTimerRxTimeOut.Enabled := True;
       Exit;
      end;
     FCRC := Crc16(PByte(p), p.len+2);
     if FCRC <> 0 then
      begin
       FTimerRxTimeOut.Enabled := True;
       Exit;
      end;
     Move(p.data^, data[cnt], p.len-5);
     Inc(cnt, p.len-5);
     Inc(idx, p.len+2+4);
    until Boolean(p.kv and %0010000);
    if FICount >= idx-4 then
     begin
      Dec(FICount, idx-4);
      Move(FInput[idx-4], FInput[0], FICount);
     end
    else raise EAsyncHMException.Create('Error FICount >= idx-4');

    //TDebug.Log('CRCBAAD %x   %d ', [Sender.FInput[0], Sender.FICount]);

    try
      DoEvent(@data[0], cnt);
    finally
      Next(); //AsyncSend далее
    end;
   end
   else  Sender.FTimerRxTimeOut.Enabled := True;
  // else TDebug.Log('CRCBAAD %x   %d ', [FInput[0], FICount]);
end;

//16:22:46:134  READ     2:  00 80    1
//16:22:46:102  READ     2:  13 80    2
//16:22:46:069  READ     2:  80 80    3
//16:22:46:037  READ     2:  00 80    4
//16:22:46:005  READ     2:  00 80    5
//16:22:45:974  READ     2:  00 80    6
//16:22:45:942  READ     2:  00 80    7
//16:22:45:910  READ     2:  00 80    8
//16:22:45:877  READ     2:  00 80    9
//16:22:45:845  READ     2:  00 80    0
//16:22:45:814  READ     2:  00 80    11
//16:22:45:781  READ     2:  1C 80    2
//16:22:45:750  READ     2:  00 80    3
//16:22:45:717  READ     2:  00 80    4
//16:22:45:685  READ     2:  00 80    5
//16:22:45:637  READ     2:  FF FF    6
//16:22:45:605  READ     2:  FF FF    7
//16:22:45:573  READ     2:  FF FF    8
//16:22:45:541  READ     2:  FF FF    9
//16:22:45:509  READ     2:  FF FF    20
//16:22:45:477  READ     2:  FF FF    1
//16:22:45:445  READ     2:  FF FF    2
//16:22:45:413  READ     2:  33 80    3
//16:22:45:381  READ     2:  F5 FE    4
//16:22:45:349  READ     2:  00 80    5
//16:22:45:317  READ     2:  00 80    6
//16:22:45:285  READ     2:  00 80    7
//16:22:45:253  READ     2:  00 80    8
//16:22:45:221  READ     2:  00 80    9
//16:22:45:189  READ     2:  00 80    30
//16:22:45:157  READ     2:  0D 80    11
//16:22:45:125  READ     2:  00 00    32

procedure TProtocolHM.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  try
    Sender.DoEvent(nil, -1);
  finally
    Next(); //AsyncSend далее
  end;
end;

procedure TProtocolHM.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
 var
//  CRCLo, CRCHi: byte;
  P: PByte;
begin
  if Cnt > 253 then
    raise EProtocolBurException.CreateFmt('Данных для передачи %d больше 253', [Cnt]);
  if cnt >0 then
   begin
    P:= Data;
    inc(p, 4);
    Move(Data^, P^, cnt);
    PInteger(Data)^ := AMBULA_OUT;
    var CRC := Crc16(p,Cnt);
    CRC := CRC shr 8 + CRC shl 8;
    inc(P, cnt);
    PWORD(P)^:= CRC;
    Inc(cnt, 2+4);
  end;
  Sender.FICount := 0;
  FOldCount := 0;
  FCRC := $FFFF;
end;

{$ENDREGION}

{$REGION 'Parser MetaData'}

type
  /// PDtataSistem указатель на data_system.prb
  ///  имеет смысл только PDtataSistem
  PDtataSistem =^TMDHeader;

  /// 'фиктивные' типы data_system
  PDiscrKadr = ^TDiscrKadr;
  PAnyData = ^TAnyData;
  Pmodules = ^Tmodules;
  Pmetrs  = ^Tmetrs;
  Pcanals = ^Tcanals;
  TMDHeader = packed record
   len: Word;
   id: Word;
   name: array[0..15] of Byte;
   /// типы с изменяемой длинной и положением в структуре данных в data_system.prb
   function DiscrKadr: PDiscrKadr;
   function AnyData : PAnyData;
   function modules : Pmodules;
   function metrs : Pmetrs;
   function canals : Pcanals;
   ///
   function SizeOf: Integer;
   function Getsname: string;
  /// парсер data_system.prb в мой XML формат метаданных с выделением ГК
   procedure GenerateXML(root: IXMLNode);
   property sname: string read Getsname;
  end;

  TDiscrKadr = packed record
   n: Byte;
   data: array[Byte] of word;
   function SizeOf: Integer;
  end;

  TAnyData= packed record
    RAMSize: UInt32;  //в кБайт
    deltaDelay: UInt32; //в мкс,
    MaxDelayTime: UInt32; //c
    kadrLenRAM: Word;
    kadrLenInf: Word;
    packetLen: Word;
    protocol: Word;
    tClearMin: Word;
    tClearMax: Word;
    timout1: Word;
    timout2: Word;
    timout3: Word;
    timout4: Word;
    timout5: Word;
  end;

  TmoduleData = packed record
   id: Word;
   name: array[0..5] of Byte;
   function Getsname: string;
   property sname: string read Getsname;
  end;

  Tmodules = packed record
   n: Byte;
   data: array[Byte] of TmoduleData;
   function SizeOf: Integer;
  end;

  TmetrData = packed record
   id: Word;
   name: array[0..24] of Byte;
   //len: Word;
   function Getsname: string;
   property sname: string read Getsname;
  end;

  Tmetrs = packed record
   n: Byte;
   data: array[Byte] of TmetrData;
   function SizeOf: Integer;
  end;

  TcanalData = packed record
   name: array[0..6] of Byte;
   len: Word;
   datatype: Byte;
   maduleID: Word;
   function Getsname: string;
   property sname: string read Getsname;
  end;

  Tcanals = packed record
   n: Byte;
   data: array[Byte] of TcanalData;
   function SizeOf: Integer;
  end;

{ TMDHeader }

procedure TMDHeader.GenerateXML(root: IXMLNode);
 var
  any, Gk, prb, wrk: IXMLNode;
  index,szGk,szAny: Integer;

  procedure AddCanal(ch: IXMLNode; tip: Integer; len: Integer; var cz: Integer);
//   CTYPES: array [1..8] of string = ('u8','i8','u16','i16','u32','i32','float','double');

   const CONV: array [1..8] of Integer = (varByte,varShortInt,
                                        varWord,varSmallint,
                                        varUInt32,varInteger,
                                        varSingle,varDouble);
   const CONV_LEN: array [1..8] of Integer = (1,1,
                                        2,2,
                                        4,4,
                                        4,8);
  begin
    var dv := ch.AddChild(T_DEV);

    dv.Attributes[AT_TIP] :=  CONV[tip];
    dv.Attributes[AT_INDEX] := index;

    var arr := len div CONV_LEN[tip];
    if arr > 1 then ch.Attributes[AT_ARRAY] := arr;

    inc(cz, len);
    inc(index, len);
  end;

begin
  prb := root.AddChild(sname);
  prb.Attributes[AT_ADDR] := id + 1200;

//  var ad :=  Self.AnyData^;
//  var mo := self.modules^;
//  var mt := metrs^;
//  var ch := canals^;

  wrk := prb.AddChild(T_WRK);

  Gk := wrk.AddChild('ГК');
  Gk.Attributes[AT_METR] := 'GK1';

  any := wrk.AddChild('data');

  index := 0;
  szGk  := 0;
  szAny := 0;

  var ch := canals;
  for var i := 0 to ch.n-1 do
   begin
    var cd := ch.data[i];
    var nam := cd.sname;

    // OLE format string
    if AnsiChar(nam.Chars[0]) in ['0'..'9'] then nam := 'd'+nam;
    nam := nam.Replace('№','No');

    if UpperCase(nam) = 'GK' then
        AddCanal(Gk.AddChild('гк'), cd.datatype and $7F, cd.len, szGk)
    else
        AddCanal(any.AddChild(nam), cd.datatype and $7F, cd.len, szAny);
   end;

   if szGk = 0 then wrk.ChildNodes.Remove(Gk)
   else Gk.Attributes[AT_SIZE] := szGk;
   any.Attributes[AT_SIZE] := szAny;
   wrk.Attributes[AT_SIZE] := szAny + szGk;
   prb.Attributes[AT_SIZE] := szAny + szGk;
   root.Attributes[AT_SIZE] := szAny + szGk;
end;


function TMDHeader.Getsname: string;
 var
  a: AnsiString;
begin
  SetString(A, PAnsiChar(@name[0]), Length(name));
  Result := string(a).Trim;
end;

function TMDHeader.DiscrKadr: PDiscrKadr;
 var
  p: PByte;
begin
  p := @Self;
  Inc(p, System.SizeOf(Self));
  Result := PDiscrKadr(P);
end;

function TMDHeader.AnyData: PAnyData;
 var
  p: PByte;
begin
  p := PByte(DiscrKadr);
  Inc(p, DiscrKadr.SizeOf);
  Result := PAnyData(p);
end;


function TMDHeader.modules: Pmodules;
 var
  p: PByte;
begin
  p := PByte(AnyData);
  Inc(p, System.SizeOf(TanyData));
  Result := Pmodules(p);
end;

function TMDHeader.metrs: Pmetrs;
 var
  p: PByte;
begin
  p := PByte(modules);
  Inc(p, modules.SizeOf);
  Result := Pmetrs(p);
end;

function TMDHeader.canals: Pcanals;
 var
  p: PByte;
begin
  p := PByte(metrs);
  Inc(p, metrs.SizeOf);
  Result := Pcanals(p);
end;


function TMDHeader.SizeOf: Integer;
begin
  Result := System.SizeOf(TMDHeader) +
            DiscrKadr.SizeOf +
            System.SizeOf(TanyData) +
            modules.SizeOf +
            metrs.SizeOf +
            canals.SizeOf;
end;

{ TmoduleData }

function TmoduleData.Getsname: string;
 var
  a: AnsiString;
begin
  SetString(A, PAnsiChar(@name[0]), Length(name));
  Result := string(a).Trim;
end;

{ TmetrData }

function TmetrData.Getsname: string;
 var
  a: AnsiString;
begin
  SetString(A, PAnsiChar(@name[0]), Length(name));
  Result := string(a).Trim;
end;

{ TcanalData }

function TcanalData.Getsname: string;
 var
  a: AnsiString;
begin
  SetString(A, PAnsiChar(@name[0]), Length(name));
  Result := string(a).Trim;
end;

{ TMDDiscrKadr }

function TDiscrKadr.SizeOf: Integer;
begin
  Result := n*2 + 1;
end;

{ Tmodules }

function Tmodules.SizeOf: Integer;
begin
  Result := n*System.SizeOf(TmoduleData) + 1;
end;

{ Tmetrs }

function Tmetrs.SizeOf: Integer;
begin
  Result := n*System.SizeOf(TmetrData) + 1;
end;

{ Tcanals }

function Tcanals.SizeOf: Integer;
begin
  Result := n*System.SizeOf(TcanalData) + 1;
end;


{$ENDREGION 'Parser MetaData'}


{ TDeviceBur }

procedure TDeviceHM.CheckConnect;
begin
  inherited;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolHM) then
   begin
    ConnectIO.FProtocol := TProtocolHM.Create;
//    if ConnectIO is TComConnectIO then ConnectIO.S_ConnectInfo := TComConnectIO(ConnectIO).Com.Port+';1000000';
    if ConnectIO is TComConnectIO then (ConnectIO as TComConnectIO).Com.CustomBaudRate := 1000_000;
   end;
end;

constructor TDeviceHM.Create;
begin
  inherited;
  FStartWork := True;
  FGetActions := TGetActionsImpl.Create(Self);
//  S_Status in [dsNoInit
//  FCycle := TCycleEx.Create(Self);
  /////
//  Ftimer := TTimer.Create(Self);
//  Ftimer.OnTimer := OnTimer;
//  Ftimer.Interval := 3000;
//  Ftimer.Enabled := False;
  /////
end;

constructor TDeviceHM.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  inherited;
  TRegister.AddType<TDeviceHM>.AddInstance(Name, Self as IInterface);
end;

destructor TDeviceHM.Destroy;
begin
//  FCycle.Free;
  FGetActions.Free;
  inherited;
end;

procedure TDeviceHM.DoData(Sender: IAction);
begin
  if  Sender.Checked then
   begin
    EndReadWork;
    Sender.Checked := False;
   end
  else if (S_Status in [dsNoInit, dsPartReady]) then
   begin
    FTmpSender := Sender;
    InitMetaData(InfoEvent);
    FTmpSender.Checked := True;
   end
  else
   begin
    Sender.Checked := True;
    ReadWork(nil);
   end;
end;

procedure TDeviceHM.DoIdle(Sender: IAction);
begin
  if MessageDlg('Перевести приборы в спящий режим?', mtWarning, [mbYes, mbNo, mbCancel], 0) <> mrYes then Exit;
  EndReadWork;
end;

procedure TDeviceHM.EndReadWork;
 var
  IsOldClose: Boolean;
begin
 FStartWork := True;
  try
    S_Status := dsReady;
    ConnectUnlock;
   CheckStatus([dsNoInit, dsPartReady, dsReady, dsData]);
   CheckConnect;
   CheckLocked;
   IsOldClose := not ConnectOpen();
   TProtocolHM(ConnectIO.FProtocol).Clear;
   ConnectIO.FEventReceiveData := nil;
    TProtocolHM(ConnectIO.FProtocol).Add(procedure(qe: integer)
     begin
      var r := Thmrec.Create(FAddressArray[0]-1200, $83);
      ConnectIO.Send(@r, SizeOf(r), procedure(Data: Pointer; DataSize: integer)
      begin
//        if DataSize >= 0 then
//         begin
//          var Res := Phmrec(Data);
//         end;
        if IsOldClose then ConnectClose();
      end);
     end)
  except
   //DoDelayEvent(False, 0, 0, 0, ResultEvent);
   if IsOldClose then ConnectClose();
   raise;
  end;
end;

procedure TDeviceHM.InfoEvent(Res: TInfoEventRes);
begin
  FTmpSender.Checked := False;
  try
   if Length(Res.ErrAdr) > 0 then raise EAsyncHMException.CreateFmt('Метаданные устройств (%s) не считаны', [AddressArrayToNames(Res.ErrAdr)]);
  finally
   if Length(FAddressArray) > Length(Res.ErrAdr) then
    begin
     FTmpSender.Checked := True;
     ReadWork(nil);
    // (Self as ICycle).Cycle := True;
    end;
  end;
end;

//procedure TDeviceHM.OnTimer(Sender: TObject);
//begin
//  DoData(FTmpSender);
//end;


procedure __load_default(root: IXMLNode);
 var
  Buf: array[0..$1000] of Byte;
const
   FILN = 'C:\AVR\~Data_System\Файлы PRB\EMK_090(EMK).prb';
  var
   s: TStream;
begin
  s := TFileStream.Create(FILN, fmOpenRead);
  try
   s.Read(buf[0], SizeOf(Buf));
   root.ChildNodes.Clear;
   var p := PDtataSistem(@Buf[0]);
   p.GenerateXML(root);
  finally
   s.Free;
  end;

end;

procedure TDeviceHM.InitMetaData(ev: TInfoEvent);
 var
  IsOldClose: Boolean;
begin
   if Length(FMetaDataInfo.ErrAdr) = 0 then
    begin
     try
      if Assigned(ev) then ev(FMetaDataInfo);
     finally
      Notify('S_MetaDataInfo');
     end;
     Exit;
    end;

   CheckStatus([dsNoInit, dsPartReady, dsReady]);
   CheckConnect;
   IsOldClose := not ConnectOpen();
   CheckLocked;

   if not Assigned(FMetaDataInfo.Info) then
    begin
     FMetaDataInfo.Info := GetIDeviceMeta((GContainer as IALLMetaDataFactory).Get().Get(), Name);
    end;

   // __load_default(FMetaDataInfo.Info);

    TProtocolHM(ConnectIO.FProtocol).Add(procedure(qe: integer)
     begin
      var r := Thmrec.Create(FAddressArray[0]-1200, $8B);
      ConnectIO.Send(@r, SizeOf(r), procedure(Data: Pointer; DataSize: integer)
      begin
        if DataSize > 0 then
         begin
           var h := PDtataSistem(data);
           h.GenerateXML(FMetaDataInfo.Info);
           SetLength(FMetaDataInfo.ErrAdr, 0);
           S_Status := dsReady;
           FOldStatus := S_Status;
           if IsOldClose then connectClose;
           var ip: IProjectMetaData;
            if Supports(GlobalCore, IProjectMetaData, ip) then
              begin
               FExeMetr.UpdateExecRunSetupMetr(FMetaDataInfo.Info, FAddressArray[0], FExeMetr);
               ip.SetMetaData(Self as IDevice, FAddressArray[0], FindDev(FMetaDataInfo.Info, FAddressArray[0])); //проблемма записи ресинк решена сдесь
              end;
             try
              if Assigned(ev) then ev(FMetaDataInfo);
             finally
              Notify('S_MetaDataInfo');
             end;
         end;
      end);
     end)
end;

procedure TDeviceHM.ReadWork(ev: TWorkEvent; StdOnly: Boolean);
// var
//  IsOldClose: Boolean;
begin

   CheckStatus([dsNoInit, dsPartReady, dsReady]);
   CheckConnect;
   {IsOldClose := not }ConnectOpen();

   FindAllWorks(FMetaDataInfo.Info, procedure(wrk: IXMLNode; adr: integer; const name: string)
      var
       p: TRunSerialQeRef;
        ip: IProjectData;
        ix: IProjectDataFile;
    begin
     if FStartWork then TProtocolHM(ConnectIO.FProtocol).Add(procedure(qe: integer)
      begin
       var r := Thmrec.Create(adr-1200, $84);
       ConnectIO.Send(@r, SizeOf(r), procedure(Data: Pointer; DataSize: integer)
       begin
        if DataSize >= 0 then
         begin
           FStartWork := False;
           FOldStatus := S_Status;
           CheckLocked;
           S_Status := dsData;
           ConnectLock;
           p := procedure(qe: integer)
             begin
              var r := Thmrec.Create(adr-1200, $89);
              ConnectIO.Send(@r, 0, procedure(Data: Pointer; DataSize: integer)
              begin
                if DataSize > 0 then
                 begin
                  var pt:PWORD := PWORD(Data);
                  for var i := 0 to DataSize div 2 - 1 do
                   begin
                     var d: word := pt^;
                     pt^ := (d shl 8) or (d shr 8);
                     Inc(pt);
                   end;
                  TPars.SetData(wrk, Data, True);
                  FWorkEventInfo.DevAdr := Adr;
                  FWorkEventInfo.Work := Wrk;
                  try
                   FExeMetr.Execute(T_WRK, Adr);
              //     FMetaDataInfo.Info.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'INCL.xml');
                    if Supports(GlobalCore, IProjectDataFile, ix) then ix.SaveLogData(Self as IDevice, Adr, Wrk, Data, DataSize)
                    else if Supports(GlobalCore, IProjectData, ip) then ip.SaveLogData(Self as IDevice, Adr, Wrk, StdOnly);
                   //TProtocolHM(ConnectIO.FProtocol).Add(p);
                  finally
                   if Assigned(ev) then ev(FWorkEventInfo);
                   Notify('S_WorkEventInfo');
                  end;
                 end;
              end);
             end;
            TProtocolHM(ConnectIO.FProtocol).Add(p);
         end;
       end);
      end);
    end);
end;


initialization
  RegisterClass(TDeviceHM);
  TRegister.AddType<TDeviceHM, IDevice>.LiveTime(ltSingletonNamed)
finalization
  GContainer.RemoveModel<TDeviceHM>;
end.
