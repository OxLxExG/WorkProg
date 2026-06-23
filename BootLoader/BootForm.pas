unit BootForm;

interface

uses RootIntf, ExtendIntf, DockIForm, debug_except, DeviceIntf, DlgSetupForm, Parser, Container, Actns,
  Xml.XMLIntf, Xml.XMLDoc, System.Variants, Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics,  Rtti, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  THackData = record
   VatType: Byte;
   PData: Pointer;
   constructor Create(InternalVarType: Byte; AdrVar: Pointer);
  end;

  EFormBoot = class(ENeedDialogException);
  TFormBoot = class(TDockIForm, INotifyBeforeSave)
    Panel: TPanel;
    btRead: TButton;
    btStop: TButton;
    btFile: TButton;
    btOut: TButton;
    btLoad: TButton;
    btIn: TButton;
    sb: TStatusBar;
    Memo: TMemo;
    od: TOpenDialog;
    btHandle: TButton;
    procedure btFileClick(Sender: TObject);
    procedure btHandleClick(Sender: TObject);
    procedure btInClick(Sender: TObject);
    procedure btOutClick(Sender: TObject);
    procedure btReadClick(Sender: TObject);
    procedure btLoadClick(Sender: TObject);
    procedure btStopClick(Sender: TObject);
  private
    adr, subAdr, chip, serial: Integer;
    FXml: IXMLNode;
    Chips: TChips;
    HackSN: THackData;
    FFileName: string;
    FileSize: Integer;
    Buf: array[0..$40000] of Byte;
    FFlagStop: Boolean;
    procedure SetFileName(const Value: string);
    procedure LoadFile(const Value: string);
    procedure ParsChip(PData: PByte);
    procedure SetAdr(Aadr: Integer);
    procedure SetSubAdr(ASubadr: Integer);
    procedure SetChip(AChip: Integer);
    procedure SetSerial(ASerial: Integer);
    procedure WriteSerialToBuf(ASerial: Word);
    function GetDevice: ILowLevelDeviceIO;
    procedure UpdateControl(Ena: Boolean);
    procedure DoIn;
    procedure DoOut;
    procedure DoRead(rd_n: Integer);
    procedure DoLoad;
//    procedure DoRead32;
//    procedure DoLoad32;
    class var Recs: Integer;
    class var Pages: Integer;
    class var adr_sz: Integer;
    class var flash_begin: DWORD;
  protected
   const
    NICON = 293;
    procedure BeforeSave();
    class function ClassIcon: Integer; override;
    procedure Loaded; override;
  public
    [StaticAction('Загрузчик', 'Отладочные', NICON, '0:Показать.Отладочные:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  published
    property FileName: string read FFileName write SetFileName;
  end;

var
  FormBoot: TFormBoot;

implementation

{$R *.dfm}

uses tools, MetaData2.to1, MetaData2.XBParser;


const
 SBT_ADR = 0;
 SBT_SER = 1;
 SBT_CHIP = 2;
 SBT_SUB = 3;
 SBT_FILE = 4;

{ THackData }

constructor THackData.Create(InternalVarType: Byte; AdrVar: Pointer);
begin
   VatType := InternalVarType;
   PData := AdrVar;
end;

{ TFormBoot }

class function TFormBoot.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormBoot.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalBootloader');
end;

procedure TFormBoot.SetFileName(const Value: string);
begin
  FFileName := Value;
  if not (csLoading in ComponentState) then
    if FileExists(FFileName) then
     begin
      sb.Panels[SBT_FILE].Text := FFileName;
      LoadFile(FFileName);
      ParsChip(@Buf[0]);
     end
    else sb.Panels[SBT_FILE].Text := 'Нет файла';
end;

procedure TFormBoot.Loaded;
begin
  inherited ;
  CArray.Add<TChip>(Chips, Tchip.Create(1,  64, $34, 128, 'ATMega88',8));
  CArray.Add<TChip>(Chips, Tchip.Create(2, 128, $7C, 128, 'ATMega164',8));
  CArray.Add<TChip>(Chips, Tchip.Create(3, 128, $180, 1024, 'STM32F103CB',32,$08002000));
  CArray.Add<TChip>(Chips, Tchip.Create(4, 128, $7C, 256, 'ATMega664',8));
  CArray.Add<TChip>(Chips, Tchip.Create(5, 128, $188, 4096, 'STM32F401',32,$08004000));
//  CArray.Add<TChip>(Chips, Tchip.Create(5, 128, $400, 4096, 'STM32F401-1',32,$08008000));
  CArray.Add<TChip>(Chips, Tchip.Create(6, 128, $F4, 1024, 'AVR128db48',32));
  CArray.Add<TChip>(Chips, Tchip.Create(7, 128, $7C, 128, 'Tiny1616',8));
  SetAdr(-1);
  SetSubAdr($78);
  SetChip(-1);
  SetSerial(-1);
//  PInteger(9)^ := 1243;
  FileName := FFileName;
end;

procedure TFormBoot.LoadFile(const Value: string);
 var
  f: TFileStream;
begin
  f := TFileStream.Create(Value, fmOpenRead);
  try
   FillMemory(@buf[0], SizeOf(Buf), 0);
   FileSize := f.Read(buf[0], SizeOf(Buf));
  finally
   f.Free;
  end;
end;

procedure TFormBoot.SetAdr(Aadr: Integer);
begin
  adr := Aadr;
  if adr > 0 then sb.Panels[SBT_ADR].Text := Format('адр:%d', [adr])
  else sb.Panels[SBT_ADR].Text := 'не инициализ.'
end;

procedure TFormBoot.SetChip(AChip: Integer);
 var
  ch: TChip;
begin
  chip := AChip;
  for ch in Chips do if ch.Chip = chip then
   begin
    sb.Panels[SBT_CHIP].Text := Format('чип: %s', [Ch.Info]);
    Recs := ch.Recs;
    Pages := ch.Pages;
    adr_sz := ch.adr_sz;
    flash_begin := ch.flash_begin;
    Exit;
   end;
  sb.Panels[SBT_CHIP].Text := Format('чип %d отсутствует', [chip]);
end;

procedure TFormBoot.SetSerial(ASerial: Integer);
begin
  serial := ASerial;
  if serial > 0 then sb.Panels[SBT_SER].Text := Format('№: %d', [serial])
  else sb.Panels[SBT_SER].Text := 'не инициализ.'
end;

procedure TFormBoot.SetSubAdr(ASubadr: Integer);
begin
  subadr := ASubadr;
  sb.Panels[SBT_SUB].Text := Format('sub:0x%s', [intToHex(subadr,2)])
end;

procedure TFormBoot.WriteSerialToBuf(ASerial: Word);
begin
  if Assigned(HackSN.PData) then
   begin
    PWORD(HackSN.PData)^ := ASerial;
    Exit;
   end;
  MessageDlg('Нет данных для записи серийного номера!', mtWarning, [mbOk], 0);
end;

procedure TFormBoot.ParsChip(PData: PByte);
 var
  ch: TChip;
  len: Word;
  GDoc: IXMLDocument;
  function CheckOldType: Boolean;
  begin
    Result := ((PData[ch.InfoStart] = varRecord) and (len < 4096))
  end;
  function CheckNewType: Boolean;
  begin
    Result := (Pbyte(@PData[ch.InfoStart+2])^ in [1..4]) and
              (PWord(@PData[ch.InfoStart])^ <= 4096);
  end;
begin
  for ch in Chips do
   begin
    len := PWord(@PData[ch.InfoStart+1])^;
    if not CheckOldType and not CheckNewType  then Continue;
    GDoc := NewXMLDocument();
    FXml := GDoc.DocumentElement;
    FXml := GDoc.AddChild('DEVICE');
    SetAdr(-1);
    SetSubAdr($78);
    SetChip(-1);
    SetSerial(-1);
    try
     if Pbyte(@PData[ch.InfoStart])^ = varRecord then
      begin
       TPars.SetInfo(FXml, @PData[ch.InfoStart], len, procedure(InternalVarType: Byte; AdrVar: Pointer)
       begin
         case InternalVarType of
          TPars.var_adr: SetAdr(Pbyte(AdrVar)^);
          TPars.varChip: SetChip(Pbyte(AdrVar)^);
          TPars.varSerial:
           begin
            if PData = @Buf[0] then HackSN := THackData.Create(InternalVarType, AdrVar);
            SetSerial(PWord(AdrVar)^);
           end;
         end;
       end);
      end
     else
     if Pbyte(@PData[ch.InfoStart+2])^ in [1..4] then
      begin
       len := PWord(@PData[ch.InfoStart])^;
       var dv := Tnewpars.SetInfo(FXml, @PData[ch.InfoStart], len);
       HackSN := THackData.Create(TPars.varSerial, TBinaryXParser.HackAdr);
       SetAdr(Byte(dv.Attributes[AT_ADDR]));
       SetChip(Byte(dv.Attributes[AT_CHIP]));
       SetSerial(Byte(dv.Attributes[AT_SERIAL]));
       if dv.HasAttribute(AT_SUB_ADDR) then SetSubAdr(Byte(dv.Attributes[AT_SUB_ADDR]))
      end
     else Continue;
    except
     Continue;
    end;
    Memo.Lines.BeginUpdate;
    try
     Memo.Clear;
     ExecXTree(FXml, function(n: IXMLNode): boolean
      var
       i: Integer;
       t: IXMLNode;
       pre: string;
     begin
       Result := False;
       t:= n;
       pre := '';
       while Assigned(t.ParentNode) do
        begin
         t := t.ParentNode;
         pre := pre + '      ';
        end;
       Memo.Lines.Add(pre+n.NodeName);
       for i := 0 to n.AttributeNodes.Count-1 do
        if n.AttributeNodes[i].NodeName = AT_TIP then Memo.Lines.Add(Format('%s %s=%s',[pre, AT_TIP, Tpars.VarTypeToStr(n.AttributeNodes[i].NodeValue)]))
        else Memo.Lines.Add(Format('%s %s=%s',[pre, n.AttributeNodes[i].NodeName, VarToStr(n.AttributeNodes[i].NodeValue)]));
     end);
    finally
     Memo.Lines.EndUpdate;
    end;
    Break;
   end;
end;

procedure TFormBoot.BeforeSave();
begin
  Memo.Lines.Clear;
end;

procedure TFormBoot.btFileClick(Sender: TObject);
begin
  if od.Execute then FileName := od.FileName;
end;

procedure TFormBoot.btHandleClick(Sender: TObject);
begin
 if TDlgSetupAdr.Execute(adr, subAdr, chip, serial, Chips) then
  begin
   SetAdr(adr);
   SetSubAdr(subAdr);
   SetChip(chip);
   SetSerial(serial);
   if Serial > 0 then  WriteSerialToBuf(serial);
  end;
end;

procedure TFormBoot.UpdateControl(Ena: Boolean);
begin
  btRead.Enabled := Ena;
  btHandle.Enabled := Ena;
  btFile.Enabled := Ena;
  btIn.Enabled := Ena;
  btOut.Enabled := Ena;
  btLoad.Enabled := Ena;
end;

function TFormBoot.GetDevice: ILowLevelDeviceIO;
 var
  d: IDevice;
  a: Integer;
  de: IDeviceEnum;
begin
  if Supports(GlobalCore, IDeviceEnum, de) then
   for d in de do for a in d.GetAddrs do if a = adr then
     if d.Status in [dsNoInit, dsPartReady, dsReady] then Exit(d as ILowLevelDeviceIO)
     else raise EFormBoot.Create(Format('Устройство с адресом %d в работе',[adr]));
  raise EFormBoot.Create(Format('Нет устройств с адресом %d',[adr]));
end;

//type
//  TbootInTest = packed record
//    adr_cmd:TCmdADR;
//    magic: DWORD;
//    constructor Create(a: Byte);
//  end;

//constructor TbootInTest.Create(a: Byte);
//begin
//  adr_cmd := ToAdrCmd(a, CMD_BOOT);
//  magic := $12345678;
//end;

procedure TFormBoot.DoIn;
const
  {$J+} cnt: Byte = 0;{$J-}
 var
  d: TStdRec;
begin
  if adr = -1 then Exit;

  d := TStdRec.Create(adr, CMD_BOOT, 4);
  d.AssignInt($12345600 + subAdr);
//  d := TbootInTest.Create(Adr);
  GetDevice.SendROW(d.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
  begin
    if (D.SizeOf = n) and CompareMem(d.Ptr, p, n) then memo.Lines.Insert(0, Format('В загрузчике %d !!!', [cnt]))
    else memo.Lines.Insert(0, Format('Ошибка перехода в загрузчик %d ', [cnt]));
    inc(cnt);
  end, 100);
end;
procedure TFormBoot.btInClick(Sender: TObject);
begin
  DoIn;
end;

procedure TFormBoot.DoOut;
 var
  d: TStdRec;
begin
  d := TStdRec.Create(adr, CMD_EXIT, 0);
//  d := ToAdrCmd(Adr, CMD_EXIT);
  GetDevice.SendROW(d.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
  begin
    if (d.SizeOf = n) and d.CheckAC(p) then memo.Lines.Insert(0, 'в программе !!!')
    else memo.Lines.Insert(0, 'Ошибка перехода в программу');
  end, 100);
end;
procedure TFormBoot.btOutClick(Sender: TObject);
begin
  DoOut;
end;

//type
//  PPageRead =^TPageRead;
//  TPageRead = packed record
//    CmdAdr: TCmdADR;
//    PageAdr: word;
//    constructor Create(a: Byte; aPageAdr: word);
//  end;
//  PPageRead32 =^TPageRead32;
//  TPageRead32 = packed record
//    CmdAdr: TCmdADR;
//    PageAdr: Dword;
//    constructor Create(a: Byte; aPageAdr: Dword);
//  end;
//
//constructor TPageRead.Create(a: Byte; aPageAdr: word);
//begin
//  CmdAdr := ToAdrCmd(a, CMD_READ);
//  PageAdr := aPageAdr;//PageNo * TFormBoot.Recs;
//end;
//{ TPageRead32 }
//
//constructor TPageRead32.Create(a: Byte; aPageAdr: Dword);
//begin
//  CmdAdr := ToAdrCmd(a, CMD_READ);
//  PageAdr := aPageAdr;//PageNo * TFormBoot.Recs;
//end;

type
  TPageRead = record
    D: TStdRec;
    PageAdr: Integer;
    constructor Create(a: Byte; aPageAdr: Integer);
    function Check(p: Pointer; n: integer): boolean;
    function PData(p: Pointer): Pointer;
  end;
  TPageWrite = record
    D: TStdRec;
    PageAdr: Integer;
    NoErrEndPage, NoErrPartPage: Boolean;
    err, padr: UInt32;
    constructor Create(a: Byte; aPageAdr: Integer; pp: Pointer);
    function Check(p: Pointer; n: integer): boolean;
  end;

{ TPageWrite }

function TPageWrite.Check(p: Pointer; n: integer): boolean;
 var
  res: TStdRec;
  sz: Integer;
  pd: PDWORD;
  pw: PWORD;
begin
  Result := False;
  NoErrEndPage := False;
  NoErrPartPage := False;
  if (TFormBoot.adr_sz = 32) then
   sz := 8
  else
   sz := 4;
  if Assigned(p) and (n = sz + d.SizeOfAC) and d.CheckAC(p) then
  begin
    res := TStdRec.Create(p, d.adr>15, sz);
    if (TFormBoot.adr_sz = 32) then
     begin
      pd := PDWORD(res.DataPtr);
      padr := pd^;
      inc(pd);
      err := pd^;
      NoErrEndPage := err = $FFFFFFFF;
      NoErrPartPage := err = $FFFFFFFE;
     end
    else
     begin
      pw := PWORD(res.DataPtr);
      padr := pw^;
      inc(pw);
      err := pw^;
      NoErrEndPage := err = $FFFF;
      NoErrPartPage := err = $FFFE;
     end;
    Result := (padr = PageAdr) and (NoErrEndPage or NoErrPartPage);
  end;
end;

constructor TPageWrite.Create(a: Byte; aPageAdr: Integer; pp: Pointer);
 var
  pb: PByte;
begin
  PageAdr := aPageAdr;
  if TFormBoot.adr_sz = 32 then
   begin
    D := TStdRec.Create(a, CMD_WRITE, 4+TFormBoot.Recs);
    d.AssignInt(aPageAdr);
    pb := d.DataPtr;
    inc(pb,4);
   end
  else
   begin
    D := TStdRec.Create(a, CMD_WRITE, 2+TFormBoot.Recs);
    d.AssignWord(aPageAdr);
    pb := d.DataPtr;
    inc(pb,2);
   end;
   Move(pp^,pb^,TFormBoot.Recs);
end;

  { TPageRead }

constructor TPageRead.Create(a: Byte; aPageAdr: Integer);
begin
  PageAdr := aPageAdr;
  if TFormBoot.adr_sz = 32 then
   begin
    D := TStdRec.Create(a, CMD_READ, 4);
    d.AssignInt(aPageAdr);
   end
  else
   begin
    D := TStdRec.Create(a, CMD_READ, 2);
    d.AssignWord(aPageAdr);
   end;
end;

function TPageRead.PData(p: Pointer): Pointer;
 var
  pb: PByte;
begin
  pb := p;
  inc(pb, D.SizeOf);
//  if TFormBoot.adr_sz = 32 then inc(pb,4) else inc(pb,2);
  Result := pb;
end;

function TPageRead.Check(p: Pointer; n: integer): boolean;
 var
  res: TStdRec;
  sz: Integer;
begin
  Result := False;
  if (TFormBoot.adr_sz = 32) then
   sz := 4 + TFormBoot.Recs
  else
   sz := 2 + TFormBoot.Recs;
  if Assigned(p) and (n = sz + d.SizeOfAC) and d.CheckAC(p) then
   begin
    res := TStdRec.Create(p, d.adr>15, sz);
    if (TFormBoot.adr_sz = 32) then
        Exit(PDWORD(res.DataPtr)^ = PageAdr)
    else Exit(PWORD(res.DataPtr)^ = PageAdr)
   end;
end;



{type
  TPageWrite = packed record
    CmdAdr: TCmdADR;
    PageAdr: word;
    data: array[0..1023] of Byte;
    constructor Create(a: Byte; aPageAdr: word; pp: Pointer);
    class function Size: Integer; static;
  end;
  TPageWrite32 = packed record
    CmdAdr: TCmdADR;
    PageAdr: DWord;
    data: array[0..1023] of Byte;
    constructor Create(a, aPageAdr: dword; pp: Pointer);
    class function Size: Integer; static;
  end;

  PPageReadRes =^TPageReadRes;
  TPageReadRes = TPageWrite;
  PPageReadRes32 =^TPageReadRes32;
  TPageReadRes32 = TPageWrite32;

  PPageWriteRes = ^TPageWriteRes;
  TPageWriteRes = packed record
    CmdAdr: TCmdADR;
    PageAdr: Word;
    Res: Word;
  end;
  PPageWriteRes32 = ^TPageWriteRes32;
  TPageWriteRes32 = packed record
    CmdAdr: TCmdADR;
    PageAdr: DWord;
    Res: DWord;
  end;

constructor TPageWrite32.Create(a, aPageAdr: dword; pp: Pointer);
begin
  CmdAdr := ToAdrCmd(a, CMD_WRITE);
  PageAdr := aPageAdr;
  Move(pp^, data, TFormBoot.Recs);
end;

class function TPageWrite32.Size: Integer;
begin
  Result := CASZ + SizeOf(Dword) + TFormBoot.Recs;
end;

constructor TPageWrite.Create(a: Byte; aPageAdr: Word; pp: Pointer);
begin
  CmdAdr := ToAdrCmd(a, CMD_WRITE);
  PageAdr := aPageAdr;
  Move(pp^, data, TFormBoot.Recs);
end;

class function TPageWrite.Size: Integer;
begin
  Result := CASZ + SizeOf(word) + TFormBoot.Recs;
end;      }


procedure TFormBoot.DoRead(rd_n: Integer);
 const
//  RD_N = 32;
  ER_N = 7;
 var
  RecFunc: TReceiveDataRef;
  err: Integer;
  CurPg: Integer;
  PgRd: TPageRead;
  Flash: array of Byte;
begin
  GetDevice;
  err := -1;
  CurPg := 0;
  SetLength(Flash, RD_N*Recs);
  FFlagStop := False;
  UpdateControl(False);
  Memo.Clear;
  RecFunc := procedure(p: Pointer; n: integer)
  begin
    if FFlagStop then Exit; // terminate
//    if Assigned(d) and (n = TPageReadRes.Size) and (d.CmdAdr = PgRd.CmdAdr) and (d.PageAdr = PgRd.PageAdr) then
    if PgRd.Check(p,n) then
     begin // good
      move(PgRd.PData(p)^, Flash[CurPg*Recs], Recs);
      Inc(CurPg);
      err := 0;
      if CurPg >= RD_N then
       begin // good end
        UpdateControl(True);
        ParsChip(@Flash[0]);
        Exit;
       end;
     end
    else
     begin // bad
      Inc(err);
      memo.Lines.Insert(0, Format('Ошибка чтения %d ', [err]));
      if err >= ER_N then
       begin // bad end
        memo.Lines.Insert(0, 'Невозможно счтитать');
        UpdateControl(True);
        Exit;
       end;
     end;
    PgRd := TPageRead.Create(adr, flash_begin+CurPg*Recs); // enxt
    try
     sleep(10);
     GetDevice.SendROW(PgRd.D.Ptr, PgRd.D.SizeOf, RecFunc, 1000);
    except
     UpdateControl(True);
     raise;
    end;
  end;
  PgRd := TPageRead.Create(adr, flash_begin+CurPg*Recs); // enxt
  try
   GetDevice.SendROW(PgRd.D.Ptr, PgRd.D.SizeOf, RecFunc, 1000);
  except
   UpdateControl(True);
   raise;
  end;
end;

{procedure TFormBoot.DoRead32;
 const
  RD_N = 20;
  ER_N = 7;
 var
  RecFunc: TReceiveDataRef;
  err: Integer;
  CurPg: Integer;
  PgRd: TPageRead32;
  Flash: array of Byte;
begin
  GetDevice;
  err := -1;
  CurPg := 0;
  SetLength(Flash, RD_N*Recs);
  FFlagStop := False;
  UpdateControl(False);
  Memo.Clear;
  RecFunc := procedure(p: Pointer; n: integer)
   var
    d: PPageReadRes32;
  begin
    if FFlagStop then Exit; // terminate
    d := p;
    if Assigned(d) and (n = TPageReadRes32.Size) and (d.CmdAdr = PgRd.CmdAdr) and (d.PageAdr = PgRd.PageAdr) then
     begin // good
      move(d.data[0], Flash[CurPg*Recs], Recs);
      Inc(CurPg);
      err := 0;
      if CurPg >= RD_N then
       begin // good end
        UpdateControl(True);
        ParsChip(@Flash[0]);
        Exit;
       end;
     end
    else
     begin // bad
      Inc(err);
      memo.Lines.Insert(0, Format('Ошибка чтения %d ', [err]));
      if err >= ER_N then
       begin // bad end
        memo.Lines.Insert(0, 'Невозможно счтитать');
        UpdateControl(True);
        Exit;
       end;
     end;
    PgRd := TPageRead32.Create(adr, flash_begin+CurPg*Recs); // enxt
    try
     sleep(10);
     GetDevice.SendROW(@PgRd, SizeOf(TPageRead32), RecFunc, 1000);
    except
     UpdateControl(True);
     raise;
    end;
  end;
  PgRd := TPageRead32.Create(adr, flash_begin+CurPg*Recs); // enxt
  try
   GetDevice.SendROW(@PgRd, SizeOf(TPageRead32), RecFunc, 1000);
  except
   UpdateControl(True);
   raise;
  end;
end; }

procedure TFormBoot.btReadClick(Sender: TObject);
begin
 if adr_sz = 32 then DoRead(20) else DoRead(32);
end;

procedure TFormBoot.DoLoad;
 const
  ER_N = 7;
 var
  RecFunc: TReceiveDataRef;
  err: Integer;
  CurPg, Npg: Integer;
  PgWr: TPageWrite;
begin
  GetDevice;

  err := -1;
  CurPg := 0;

  LoadFile(FFileName);

  Npg := FileSize div Recs;
  if (FileSize mod Recs) > 0 then Inc(Npg);

  if Serial >0 then WriteSerialToBuf(Serial);

  FFlagStop := False;
  UpdateControl(False);
  Memo.Clear;
  memo.Lines.Add('Запись');
  RecFunc := procedure(p: Pointer; n: integer)
  begin
    if FFlagStop then Exit; // terminate
//    d := p;
//    if Assigned(d) and (n = SizeOf(TPageWriteRes)) and (d.CmdAdr = PgWr.CmdAdr) and (d.PageAdr = PgWr.PageAdr)
//      and ((d.Res = $FFFF) or (d.Res = $FFFE)) then
    if PgWr.Check(p,n) then
     begin
      if PgWr.NoErrPartPage then memo.Lines[0] := memo.Lines[0] + '.'
      else memo.Lines[0] := memo.Lines[0] + ':';
      Inc(CurPg);
      err := 0;
      if (CurPg >= Npg) and PgWr.NoErrEndPage then
       begin
        memo.Lines.Add('Запись окончена');
        UpdateControl(True);
        Exit;
       end;
     end
    else
     begin
      Inc(err);
      if Assigned(p) then memo.Lines.Insert(0, Format('Ошибка записи %d page: %4x  err: %4x', [err, PgWr.PageAdr, PgWr.err]))
      else  memo.Lines.Insert(0, Format('Ошибка записи err: %d', [err]));
      if err >= ER_N then
       begin // bad end
        memo.Lines.Insert(0, 'Невозможно записать');
        UpdateControl(True);
        Exit;
       end;
     end;
    PgWr := TPageWrite.Create(adr, flash_begin+Recs*CurPg, @Buf[Recs*CurPg]); // enxt
    try
     sleep(10);
     GetDevice.SendROW(PgWr.D.Ptr, PgWr.D.SizeOf, RecFunc, 1000);
    except
     UpdateControl(True);
     raise;
    end;
  end;
  PgWr := TPageWrite.Create(adr, flash_begin+Recs*CurPg, @Buf[Recs*CurPg]); // enxt
  try
   GetDevice.SendROW(PgWr.D.Ptr, PgWr.D.SizeOf, RecFunc, 1000);
  except
   UpdateControl(True);
   raise;
  end;
end;

{procedure TFormBoot.DoLoad32;
 const
  ER_N = 7;
 var
  RecFunc: TReceiveDataRef;
  err: Integer;
  CurPg, Npg: Integer;
  PgWr: TPageWrite32;
begin
  GetDevice;

  err := -1;
  CurPg := 0;

  LoadFile(FFileName);

  Npg := FileSize div Recs;
  if (FileSize mod Recs) > 0 then Inc(Npg);

  if Serial >0 then WriteSerialToBuf(Serial);

  FFlagStop := False;
  UpdateControl(False);
  Memo.Clear;
  memo.Lines.Add('Запись');
  RecFunc := procedure(p: Pointer; n: integer)
   var
    d: PPageWriteRes32;
  begin
    if FFlagStop then Exit; // terminate
    d := p;
    if Assigned(d) and (n = SizeOf(TPageWriteRes32)) and (d.CmdAdr = PgWr.CmdAdr) and (d.PageAdr = PgWr.PageAdr)
      and ((d.Res = $FFFFFFFF) or (d.Res = $FFFFFFFE)) then
     begin
      if d.Res = $FFFFFFFE then memo.Lines[0] := memo.Lines[0] + '.'
      else memo.Lines[0] := memo.Lines[0] + ':';
      Inc(CurPg);
      err := 0;
      if (CurPg >= Npg) and (d.Res = $FFFFFFFF) then
       begin
        memo.Lines.Add('Запись окончена');
        UpdateControl(True);
        Exit;
       end;
     end
    else
     begin
      Inc(err);
      if Assigned(d) then memo.Lines.Insert(0, Format('Ошибка записи %d page: %4x  err: %4x', [err, d.PageAdr, d.Res]))
      else  memo.Lines.Insert(0, Format('Ошибка записи err: %d', [err]));
      if err >= ER_N then
       begin // bad end
        memo.Lines.Insert(0, 'Невозможно записать');
        UpdateControl(True);
        Exit;
       end;
     end;
    PgWr := TPageWrite32.Create(adr, flash_begin+CurPg*Recs, @Buf[Recs*CurPg]); // enxt
    try
     sleep(10);
     GetDevice.SendROW(@PgWr, TPageWrite32.Size, RecFunc, 1000);
    except
     UpdateControl(True);
     raise;
    end;
  end;
  PgWr := TPageWrite32.Create(adr,flash_begin+CurPg*Recs, @Buf[Recs*CurPg]); // enxt
  try
   GetDevice.SendROW(@PgWr, TPageWrite32.Size, RecFunc, 1000);
  except
   UpdateControl(True);
   raise;
  end;
end;  }

procedure TFormBoot.btLoadClick(Sender: TObject);
begin
// if adr_sz = 32 then DoLoad32 else
 DoLoad;
end;

procedure TFormBoot.btStopClick(Sender: TObject);
begin
  FFlagStop := True;
  UpdateControl(True);
end;

initialization
  RegisterClass(TFormBoot);
  TRegister.AddType<TFormBoot, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormBoot>;
end.
