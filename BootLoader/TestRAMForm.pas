unit TestRAMForm;

interface

uses RootIntf, ExtendIntf, DockIForm, debug_except, DeviceIntf, DlgSetupForm, Parser, Container, Actns,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, tools,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls;
{// чтение внешней памяти
#define CMD_ERAM 0x1 | ADDRESS
// запись внешней памяти ТОЛЬКО В ТЕСТОВЫХ ЦЕЛЯХ
#define CMD_ERAM_WRITE 0x9 | ADDRESS
// стирание внешней памяти ТОЛЬКО В ТЕСТОВЫХ ЦЕЛЯХ
#define CMD_ERAM_CLEAR 0xA | ADDRESS
// установка страницы для записи
#define CMD_ERAM_SET_BASE 0xC | ADDRESS}
const
   CMD_ERAM = 1;
   CMD_ERAM_WRITE  = 9;
   CMD_ERAM_CLEAR  = $A;
   CMD_ERAM_SET_BASE = $C;
   CMD_ERAM_GET_BAD = $C;

type
  TSetWritePage = packed record
    CmdAdr: Byte;
    Page: Word;
    constructor Create(addr: Byte; Apg: Word);
  end;

  TSetWritePageEx = packed record
    CmdAdr: Byte;
    Page: Word;
    Chip: Byte;
    constructor Create(addr: Byte; Apg: Word; AChip: Byte);
  end;

  TSetWritePageEx2 = packed record
    CmdAdr: Byte;
    Page: DWord;
    constructor Create(addr: Byte; Apg: DWord);
  end;


  TGetBadPage = packed record
    CmdAdr: Byte;
    Length: Word;
  end;

  PRamWrite =^TRamWrite;
  TRamWrite = packed record
    CmdAdr: Byte;
    len: Byte;
    data: array [0..61] of DWORD;
    constructor Create(DevAdr: Byte; var addr: DWORD);
  end;

  PRamWriteNew =^TRamWriteNew;
  TRamWriteNew = packed record
  private
    data: TArray<Byte>;
    function GetItem(index: Integer): DWORD;
    procedure SetItem(index: Integer; const Value: DWORD);
  public
    from: DWORD;
    Count: Integer;
    function CmdAdr: Byte;
    function Ptr: Pointer;
    function Size: Integer;
    constructor Create(DevAdr: Byte; afrom: DWORD; alen: word);
    property Item[index: Integer]: DWORD read GetItem write SetItem;
  end;

  PRamRead =^TRamRead;
  TRamRead = packed record
    CmdAdr: Byte;
    PH, P6LB2H, BL: Byte;
    Length: word;
    constructor Create(DevAdr: Byte; RmAdr: DWord; len: word);
  end;

  PRamReadNew =^TRamReadNew;
  TRamReadNew = packed record
    CmdAdr: Byte;
    Adres: DWORD;
    Length: DWORD;
  end;

  EFormRamTestError = class(EBaseException);
  TFormRamTest = class(TDockIForm)
    sb: TStatusBar;
    Memo: TMemo;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    edADR: TEdit;
    edPageW: TEdit;
    btSetBase: TButton;
    btRead: TButton;
    btWrite: TButton;
    edBaseR: TEdit;
    lbBaseW: TLabel;
    edPageR: TEdit;
    btClear: TButton;
    edArdesWrite: TEdit;
    btWriteRam: TButton;
    edAdresRead: TEdit;
    btReadRam: TButton;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    elLenWrite: TEdit;
    btLenRead: TEdit;
    Label6: TLabel;
    btReadBads: TButton;
    AdrHex: TLabel;
    edChip: TEdit;
    SetMX: TButton;
    btFormat: TButton;
    procedure btSetBaseClick(Sender: TObject);
    procedure btWriteClick(Sender: TObject);
    procedure btReadClick(Sender: TObject);
    procedure btClearClick(Sender: TObject);
    procedure btWriteRamClick(Sender: TObject);
    procedure btReadRamClick(Sender: TObject);
    procedure btReadBadsClick(Sender: TObject);
    procedure SetMXClick(Sender: TObject);
    procedure btFormatClick(Sender: TObject);
  private
    function GetDevice(adr: Integer): ILowLevelDeviceIO;
    { Private declarations }
  protected
   const
    NICON = 294;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Проверка памяти', 'Отладочные', NICON, '0:Показать.Отладочные:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;


implementation

{$R *.dfm}

{ TFormRamTest }

class function TFormRamTest.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormRamTest.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalFormRamTest');
end;

function TFormRamTest.GetDevice(adr: Integer): ILowLevelDeviceIO;
 var
  d: IDevice;
  a: Integer;
  de: IDeviceEnum;
begin
  if Supports(GlobalCore, IDeviceEnum, de) then
   for d in de do for a in d.GetAddrs do if a = adr then
     if d.Status in [dsNoInit, dsPartReady, dsReady] then Exit(d as ILowLevelDeviceIO)
     else raise EFormRamTestError.Create(Format('Устройство с адресом %d в работе',[adr]));
  raise EFormRamTestError.Create(Format('Нет устройств с адресом %d',[adr]));
end;

procedure TFormRamTest.SetMXClick(Sender: TObject);
 var
  lld: ILowLevelDeviceIO;
  d: TSetWritePageEx2;
  adr: Integer;
  addr: DWORD;
begin
  adr := StrToInt(edADR.Text);
  addr := StrToInt('$'+edArdesWrite.Text);
  AdrHex.Caption := edArdesWrite.Text;
  lld := GetDevice(adr);
  d := TSetWritePageEx2.Create(Adr, addr);
    lld.SendROW(@d, SizeOf(d), procedure(p: Pointer; n: integer)
    begin
      lbBaseW.Caption := '0';
      if (1 = n) and (d.CmdAdr = PByteArray(p)[0]) then
           sb.Panels[0].Text := 'OK адрес базовый в памяти'
      else sb.Panels[0].Text := 'BAD адрес базовый в памяти'
    end, 1000);
end;

procedure TFormRamTest.btClearClick(Sender: TObject);
begin
  Memo.Clear;
end;

procedure TFormRamTest.btReadClick(Sender: TObject);
  type
   PDwordArray = ^Tda;
   Tda = array [0..$8000-1] of DWORD;
  const
   RLEN = 62*4;
 var
  lld: ILowLevelDeviceIO;
  a: TRamRead;
  adr: Integer;
  base, page: word;
  adres: DWORD;
begin
  adr := StrToInt(edADR.Text);
  base := StrToInt('$' + edBaseR.Text);
  page := StrToInt('$' + edPageR.Text);
  adres := page*$210+base;
  a := TRamRead.Create(Adr, adres, RLEN);
  lld := GetDevice(adr);
 // edRam.Text := IntToStr(StrToInt(edRam.Text) + RLEN);
  lld.SendROW(@a, SizeOf(a), procedure(p: Pointer; n: integer)
   var
    i: Integer;
    d: PDwordArray;
  begin
    if ((RLEN+1) = n) and (PByteArray(p)[0] = a.CmdAdr) then
     begin
       memo.Lines.BeginUpdate;
       d := @PByteArray(p)[1];
       for i := 0 to RLEN div 4 - 1 do memo.Text := memo.Text + Format('%8.8x ',[d[i]]);
       memo.Lines.EndUpdate;
       Inc(adres, RLEN);
       edBaseR.Text := IntToHex(adres mod $210, 3);
       edPageR.Text := IntToHex((adres div $210) mod $2000, 4);
     end;
  end);
end;

procedure TFormRamTest.btSetBaseClick(Sender: TObject);
 var
  lld: ILowLevelDeviceIO;
  d: TSetWritePage;
  dex: TSetWritePageEx;
  adr: Integer;
  chip: Byte;
  page: Word;
begin
  adr := StrToInt(edADR.Text);
  chip := StrToInt(edChip.Text);
  page := StrToInt('$'+edPagew.Text);
  lld := GetDevice(adr);
  if chip = 0 then
   begin
    d := TSetWritePage.Create(Adr, page);
    lld.SendROW(@d, SizeOf(d), procedure(p: Pointer; n: integer)
    begin
      lbBaseW.Caption := '0';
      if (1 = n) and (d.CmdAdr = PByteArray(p)[0]) then
           sb.Panels[0].Text := 'OK адрес базовый в памяти'
      else sb.Panels[0].Text := 'BAD адрес базовый в памяти'
    end, 1000);
   end
  else
   begin
    dex := TSetWritePageEx.Create(Adr, page, chip);
    lld.SendROW(@dex, SizeOf(dex), procedure(p: Pointer; n: integer)
    begin
      lbBaseW.Caption := '0';
      if (1 = n) and (dex.CmdAdr = PByteArray(p)[0]) then
           sb.Panels[0].Text := 'OK адрес базовый в памяти'
      else sb.Panels[0].Text := 'BAD адрес базовый в памяти'
    end, 1000);
   end;
end;

procedure TFormRamTest.btWriteClick(Sender: TObject);
 var
  lld: ILowLevelDeviceIO;
  d: TRamWrite;
  adr, chip: Integer;
  base, page: word;
  adres: DWORD;
begin
  adr := StrToInt(edADR.Text);
  base := StrToInt('$' + lbBaseW.Caption);
  page := StrToInt('$' + edPageW.Text);
  chip := StrToInt(edChip.Text);
  adres := chip*$420000 + (page*$210 + base); //div 4;
  AdrHex.Caption := Format('0x%x ', [adres]);
  d := TRamWrite.Create(Adr, adres);
  lld := GetDevice(adr);
  lld.SendROW(@d, SizeOf(d), procedure(p: Pointer; n: integer)
  begin
    if (n = 2) and (PByteArray(p)[0] = d.CmdAdr) and (PByteArray(p)[1] = 1) then
      begin
       sb.Panels[0].Text := Format('Записано %x ', [adres]);
       lbBaseW.Caption := IntToHex(adres mod $210, 3);
       edPageW.Text  :=    IntToHex((adres div $210) mod $2000, 4);
       edChip.Text := IntToStr( adres div $420000);
      end
    else sb.Panels[0].Text := Format('Ошибка записи %d ', [adres]);
  end, 2000);
end;


procedure TFormRamTest.btWriteRamClick(Sender: TObject);
 var
  lld: ILowLevelDeviceIO;
  d: TRamWriteNew;
  adr: Integer;
  adres: DWORD;
  len: Word;
begin
  adr := StrToInt(edADR.Text);
  adres := StrToInt('$' + edArdesWrite.Text);
  len := StrToInt('$' + elLenWrite.Text);
  d := TRamWriteNew.Create(Adr, adres, len);
  lld := GetDevice(adr);
  lld.SendROW(d.Ptr, d.Size, procedure(p: Pointer; n: integer)
  begin
    if (n = 2) and (PByteArray(p)[0] = d.CmdAdr) and (PByteArray(p)[1] = 1) then
      begin
       sb.Panels[0].Text := Format('Записано c %x длина(DWORD) %x', [adres, len]);
      end
    else sb.Panels[0].Text := Format('Ошибка записи %x %x ', [adres, len]);
  end, 2000);
end;


function ToAdrCmd(a, cmd: Byte): Byte;
begin
  Result := (a shl 4) or cmd;
end;

procedure TFormRamTest.btFormatClick(Sender: TObject);
var
  lld: ILowLevelDeviceIO;
  d: TStdRec;
  adr: Integer;
  addr: DWORD;
begin
  adr := StrToInt(edADR.Text);
  d := TStdRec.Create(adr, CMD_ERAM_CLEAR, 4);
  d.AssignInt($12345678);
  lld := GetDevice(adr);
  lld.SendROW(d.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
  begin
    if (D.SizeOf = n) and CompareMem(d.Ptr, p, n) then memo.Lines.Insert(0, '!!! NAND Formated !!!')
    else memo.Lines.Insert(0, 'com ERROR')
    end, 5000);
end;

procedure TFormRamTest.btReadBadsClick(Sender: TObject);
  type
   PDwordArray = ^Tda;
   Tda = array [0..$8000-1] of DWORD;
 var
  lld: ILowLevelDeviceIO;
  a: TGetBadPage;
  adr: Integer;
begin
  adr := StrToInt(edADR.Text);
  a.CmdAdr := ToAdrCmd(adr, CMD_ERAM_GET_BAD);
  a.Length := StrToInt('$' + btLenRead.Text)*4;
  lld := GetDevice(adr);
  lld.SendROW(@a, SizeOf(a), procedure(p: Pointer; n: integer)
   var
    i: Integer;
    d: PDwordArray;
    s: string;
  begin
    if ((a.Length+1) = n) and (PByteArray(p)[0] = a.CmdAdr) then
     begin
       d := @PByteArray(p)[1];
       s := '';
       for i := 0 to a.Length div 4 - 1 do s := s + Format('%8.8x ',[d[i]]);
//       memo.Lines.BeginUpdate;
       memo.Text := s;
//       memo.Lines.EndUpdate;
     end;
  end, 2000);
end;

procedure TFormRamTest.btReadRamClick(Sender: TObject);
  type
   PDwordArray = ^Tda;
   Tda = array [0..$8000-1] of DWORD;
 var
  lld: ILowLevelDeviceIO;
  a: TRamReadNew;
  adr: Integer;
begin
  adr := StrToInt(edADR.Text);
  a.CmdAdr := ToAdrCmd(adr, CMD_ERAM);
  a.Adres := StrToInt('$' + edAdresRead.Text);
  a.Length := StrToInt('$' + btLenRead.Text)*4;
  lld := GetDevice(adr);
  lld.SendROW(@a, SizeOf(a), procedure(p: Pointer; n: integer)
   var
    i: Integer;
    d: PDwordArray;
    s: string;
  begin
    if ((a.Length+1) = n) and (PByteArray(p)[0] = a.CmdAdr) then
     begin
       d := @PByteArray(p)[1];
       s := '';
       for i := 0 to a.Length div 4 - 1 do s := s + Format('%8.8x ',[d[i]]);
//       memo.Lines.BeginUpdate;
       memo.Text := s;
//       memo.Lines.EndUpdate;
     end;
  end, 2000);
end;

{ TRamWrite }

constructor TRamWrite.Create(DevAdr: Byte; var addr: DWORD);
 var
  i: Integer;
begin
  CmdAdr := ToAdrCmd(DevAdr, CMD_ERAM_WRITE);
  len := 62 * 4;
  for i := 0 to 61 do
    begin
     Data[i] := addr;// xor $A55A;
     Inc(addr,4);
    end;
end;

{ TSetWritePage }

constructor TSetWritePage.Create(addr: Byte; Apg: Word);
begin
  CmdAdr := ToAdrCmd(addr, CMD_ERAM_SET_BASE);
  Page := Apg;
end;

{ TRamRead }

constructor TRamRead.Create(DevAdr: Byte; RmAdr: DWord; len: word);
 var
  page, base: Word;
begin
  CmdAdr := ToAdrCmd(DevAdr, CMD_ERAM);
  page := (RmAdr div 528) mod $2000;
  base := RmAdr mod 528;
  PH := page shr 6;
  BL := base and $FF;
  P6LB2H := (page shl 2) or (base shr 8);
  Length := len;
end;

{ TRamWriteNew }

constructor TRamWriteNew.Create(DevAdr: Byte; afrom: DWORD; alen: word);
 var
  i : DWORD;
begin
  SetLength(data, alen*4+1+4);
  data[0] := ToAdrCmd(DevAdr, CMD_ERAM_WRITE);
  from := afrom;
  Count := alen;
  for i := 0 to Count-1 do Item[i] := afrom + i;
end;

function TRamWriteNew.CmdAdr: Byte;
begin
  Result := data[0];
end;

function TRamWriteNew.GetItem(index: Integer): DWORD;
 var
  pw: PDWORD;
begin
  pw := @data[1+4];
  inc(pw, index);
  Result := pw^;
end;

function TRamWriteNew.Ptr: Pointer;
begin
  Result := @data[0];
end;

procedure TRamWriteNew.SetItem(index: Integer; const Value: DWORD);
 var
  pw: PDWORD;
begin
  pw := @data[1+4];
  inc(pw, index);
  pw^ := Value;
end;

function TRamWriteNew.Size: Integer;
begin
  Result := Length(data);
end;

{ TSetWritePageEx }

constructor TSetWritePageEx.Create(addr: Byte; Apg: Word; AChip: Byte);
begin
  CmdAdr := ToAdrCmd(addr, CMD_ERAM_SET_BASE);
  Page := Apg;
  Chip := AChip;
end;

{ TSetWritePageEx2 }

constructor TSetWritePageEx2.Create(addr: Byte; Apg: DWord);
begin
  CmdAdr := ToAdrCmd(addr, CMD_ERAM_SET_BASE);
  Page := Apg;
end;


initialization
  RegisterClass(TFormRamTest);
  TRegister.AddType<TFormRamTest, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormRamTest>;
end.



