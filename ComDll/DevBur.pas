unit DevBur;         //claude --resume d5e8255b-d738-4d1e-b84d-9108baff50a6

interface

{$INCLUDE global.inc}

uses  tools, System.IOUtils, RootIntf,  ProtocolBurUnit,   System.DateUtils,
  Winapi.Windows, System.SysUtils, System.Classes, CPort, CRC16, Vcl.ExtCtrls, System.Variants, Xml.XMLIntf, Xml.XMLDoc,
  Generics.Collections,  Vcl.Forms, Vcl.Dialogs,Vcl.Controls, Actns,
  DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

{$IFDEF ENG_VERSION}
 const
   RS_DElay = '<I> Delay...';
   RS_Control= '0:Control|3.<I>:-1';
   RS_WindowDelay= 'Delay window';
   RS_Info1='<I> Information';
   RS_Info2='0:Control|3.<I>;2:';
   RS_Info3='Exit/Enter information reading mode';
   RS_Cont1='(only time)';
   RS_Cont2='0:Control|3.<I>.Additionally|0';
   RS_Cont3= 'Reduced power consumption of the device in the mode of no information, obtaining only the time and state of the device';
   RS_Device1='Switch off the device';
   RS_Device2='0:Control|3.<I>.Additionally|0';
   RS_Device3='Put devices into sleep mode';
{$ELSE}
 const
   RS_DElay = '<I> Задержка...';
   RS_Control= '0:Управление|3.<I>:-1';
   RS_WindowDelay= 'Окно постановки на задержку';
   RS_Info1='<I> Информация';
   RS_Info2='0:Управление|3.<I>;2:';
   RS_Info3='Выход/Вход в режим чтения информации';
   RS_Cont1='(только время)';
   RS_Cont2='0:Управление|3.<I>.Дополнительно|0';
   RS_Cont3= 'Пониженное энергопотребление прибора режимне информации, получение только времени и состояния прибора';
   RS_Device1='Выключить прибор';
   RS_Device2='0:Управление|3.<I>.Дополнительно|0';
   RS_Device3='Перевести приборы в спящий режим';
{$ENDIF}

resourcestring
  RS_ErrReadData = 'Ошибка чтения данных устройства с адресом: %d SZ=%d[%d] CA=0x%x';
  RS_ErrNoInfo = 'Не инициализирована информация об устройствах';
  RS_MetadataERR='Метаданные устройств (%s) не считаны';
  RS_SleapDLG='Перевести приборы в спящий режим?';
  RS_ERR_eep='Адр.уст: %d, EEPROM размер: %d смещение: %d - ошибка чтения секции'#$D#$A;
  RS_ERR_eepwr='Адр.уст: %d, EEPROM размер: %d смещение: %d - ошибка записи секции'#$D#$A;
  RS_NO_eepmeta='Метаданных EEPROM устройства с адресом %d нет';
  RS_ERR_eepLen='Данная версия программы поддерживает длину EEPROM меньше 250 текущая: %d';


  const
    LEN_MAX_SHORT = 252;//-CASZ; //не 252 из-за фая вая
 type
  EReadRamBurException = class(EReadRamException);
    EAsyncReadRamBurException = class(EAsyncReadRamException);
  TBurReadRam = class(TReadRam)
  public
   const
    MAX_RAM = $420000;
    MAX_BAD = 70;
    RLEN =  $7FF-2-2;// $7FFFF-3;
    WAIT_RLEN = 2000;
  private
    type TResRef = reference to procedure;
    procedure Read(RamPtr: Integer; len: DWord;  ev: TReceiveDataRef; WaitTime: Integer = -1; grade: integer = 1);
  protected
    procedure Execute(const binFile: string; FromKadr, ToKadr: Integer; ReadToFF: Boolean; FastSpeed, Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer; PacketLen: Integer = 0; grade:Integer=1); override;
  end;

//  ERamReadInfoBurException = class(ERamReadInfoException);
//    EAsyncRamReadInfoBurException = class(EAsyncRamReadInfoException);
//  TRamReadInfoBur = class(TRamReadInfo)
//  protected
//    procedure Get_Tstart_Tdelay(RAMInfo: IRAMInfo; var tstart: TDateTime; var tdelay: TDateTime);
//    function Update(Info: IXMLInfo; UpdateTimeSyncEvent: TRamEvent = nil): IRAMInfo; override;
//  end;

  TEepromSectionEventRef = reference to procedure (adr: Byte; siz, from: Integer; Err: Boolean);
  TNotifyInfoEventRef = reference to procedure (Exception: Integer; Adr: Integer; Data: PByte; n: Integer);
  TWorkEventRef = reference to procedure (DevAdr: Integer; Work: IXMLInfo; Data: PByte; n: Integer);
  TProfilePatchEventRef = reference to procedure (adr: integer; SelectProfile: IXMLInfo; Err: string = '');

  EBurException = class(EDeviceException);
   EAsyncBurException = class(EAsyncDeviceException);
   EEEpromSectionsException = class(ENeedDialogException);

  TDeviceBur = class(TAbstractDevice, IDevice, ILowLevelDeviceIO, IDataDevice,
                     IDelayDevice, ITurbo, ICycle, ICycleEx, IReadRamDevice, IEepromDevice, IGetActions)
  private
    Ftimer: TTimer;

    FTmpSender: IAction;
    FCycle: TCycleEx;
    FGetActions: TGetActionsImpl;

    procedure OnTimer(Sender: TObject);

    function GetSerialQe: TProtocolBur;
    procedure InfoEvent(Res: TInfoEventRes);
    procedure CheckInfoEvent(Res: TInfoEventRes);
    procedure ReadEepromAdrRef(root: IXMLNode; adr: Byte; ev: TEepromEventRef);
    procedure ReadEepromAdrSection(adr: Byte; siz, from: Integer; output: PByte; Res: TEepromSectionEventRef);
    procedure ReadEepromSectionsRef(eep: IXMLNode; adr: Byte; ev: TEepromEventRef);
    procedure ProfilePatch(adr: integer; node: IXMLnode; event: TProfilePatchEventRef);
    procedure ReadEEPAfterInfo(adr: integer; CbEnd: TProc);
    procedure SaveEEprom(rootEEP: IXMLNode);
    procedure UpdateCb(adr: integer; IsGood: Boolean; var TmpErr, TmpGood: TAddressArray; IsOldClose: Boolean; ev: TInfoEvent; var cnt: Integer);
    procedure SendUnixTime (Next: TProc; const Res: TInfoEventRes);
//    procedure InfoEvent2(Res: TInfoEventRes);
  protected
    function PropertyReadRam: TReadRam; override;
    // ILowLevelDeviceIO
    procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
    // ITurbo
    procedure Turbo(adr: Byte; speed: integer);

    procedure ReadInfoAdr(adr: Byte; ev: TNotifyInfoEventRef);
    procedure ReadWorkAdrRef(root: IXMLNode; adr: Byte; StdOnly: Boolean; ev: TWorkEventRef);

//    function GetActionsDevClass: TAbstractActionsDevClass; override;
//    function GetReadRamClass: TReadRamClass; override;
    function CreateReadRam: TReadRam; override;
    procedure MonitorDebug(const ddata: string; const Args: array of const);
    property ReadRam: TReadRam read PropertyReadRam implements IReadRamDevice;
    property GetActions: TGetActionsImpl read FGetActions implements IGetActions;
  public
    constructor Create(); override;
    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); override;
    destructor Destroy; override;
    procedure CheckMetaData(ev: TInfoEvent);
    procedure InitMetaData(ev: TInfoEvent);
    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false);
    procedure ReadEeprom(Addr: Integer; ev: TEepromEventRef);
    procedure WriteEeprom(Addr: Integer; ev: TResultEventRef; section: Integer = -1);
    procedure SetDelay(StartTime: TDateTime; WorkTime: TTime; ResultEvent: TSetDelayEvent);
    procedure SetDelayRTC(StartTime: TDateTime; ResultEvent: TSetDelayEvent);

    procedure CheckConnect(); override;
    procedure ReadWorkRef(Info: IXMLNode; ev: TWorkEventRef; StdOnly: Boolean);
//    function GetReadDeviceRam(): IReadRamDevice; override;
//    function GetRamReadInfo(): IRamReadInfo; override;
    property SerialQe: TProtocolBur read GetSerialQe;
    property Cycle: TCycleEx read FCycle implements  ICycle, ICycleEx;
// actions
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [DynamicAction(RS_DElay, '<I>', 142, RS_Control, RS_WindowDelay)]
    procedure DoDelay(Sender: IAction);
//    [DynamicAction('<I> Коррекция часов...', '<I>', Dialog_SyncDelay_ICON, '0:Управление|3.<I>', 'Окно коррекции часов модулей. Вызывается перед чтением памяти,в режиме информации.')]
//    procedure DoSync(Sender: IAction);
    [DynamicAction(RS_Info1, '<I>', 52, RS_Info2, RS_Info3)]
    procedure DoData(Sender: IAction);
//    procedure DoInfo(Sender: IAction);
    [DynamicAction(RS_Cont1, '<I>', 69, RS_Cont2, RS_Cont3)]
    procedure DoStd(Sender: IAction);
    [DynamicAction(RS_Device1, '<I>', 71, RS_Device2, RS_Device3)]
    procedure DoIdle(Sender: IAction);
  published
    property CyclePeriod;
  end;

implementation

uses  Parser, MetaData2.to1, Dev.Bur.pipe;


{$REGION  'TBurReadRam - все процедуры и функции'}
{ TBurReadRam }
//Чтение одной секции данных по адресу RamPtr
procedure TBurReadRam.Read(RamPtr: Integer; len: DWord;  ev: TReceiveDataRef; WaitTime: Integer = -1; grade: integer = 1);
begin
//  if FFlagTerminate then Exit;
  with TDeviceBur(FAbstractDevice) do
   try
    SerialQe.Add(procedure(c: integer)
     var
      d: TStdRec;
    begin
     // if FFlagTerminate then Exit;
      D := TStdRec.Create(FAdr, CMD_READ_RAM, SizeOf(DWord)*2);
      D.AssignRamRead(DWord(RamPtr), len);
     // MonitorDebug('Read %d',[c]);
      ConnectIO.Send(d.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
      begin
        if FFlagTerminate then ev(nil, -1)
        else if (n = -1) then ev(nil, -1) //timout
        else if ((len*grade + d.SizeOfAC) = n) and D.CheckAC(p) then
          ev(@PbyteArray(p)[d.SizeOfAC], n-d.SizeOfAC)
        else
         begin
          // not sand event wait all pack
          //ev(nil, -1);
         end;
      end, WaitTime);
    end);
   except
    on E: Exception do
     begin
      TDebug.DoException(E, False);
//      ev(nil, -1);
     end;
   end;
end;

procedure TBurReadRam.Execute(const binFile: string; FromKadr, ToKadr: Integer; ReadToFF: Boolean; FastSpeed, Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer; PacketLen: Integer = 0; grade:Integer=1);
   var
    FuncRead: TReceiveDataRef;
    ErrCnt: Integer;
    Wait: Integer;
    FFileStream: TFileStream;
//    t: Integer;
begin
  inherited ;//Execute(evInfoRead, Addrs);
  if FPacketLen = 0 then FPacketLen := RLEN;

  if FFastSpeed > 0 then
   begin
    TDeviceBur(FAbstractDevice).Turbo(Fadr, FFastSpeed);
    Sleep(100);
    Wait := 2000;
   end
  else Wait := WAIT_RLEN;

  if FPacketLen > 0 then Wait := -1;


  FCurAdr := FFromAdr;
  ErrCnt := 0;

  if binFile <> '' then
   begin
    if TFile.Exists(binFile) then TFile.Delete(binFile);
    FFileStream := TFileStream.Create(binFile, fmCreate);
   end;
  // функция рекурсии
  FuncRead := procedure(Data: Pointer; DataSize: integer)
    procedure CloseAny;
    begin
      TDeviceBur(FAbstractDevice).Turbo(Fadr, 0);
      if Assigned(FFileStream) then FreeAndNil(FFileStream);
    end;
    procedure WriteStream;
     var
      l: Integer;
    begin
      if DataSize < 0 then
       begin
        var st := ProcToEnd;
        st.NRead := ErrCnt;
        if Assigned(FReadRamEvent) then FReadRamEvent(carErrorSector, FAdr, st);
        Exit;
       end;
//      Acquire;
//      try
       l := Length(Fifo);
       SetLength(fifo,l+DataSize);
       move(Data^, fifo[l], DataSize);
//      finally
//       Release;
//      end;
      if Assigned(FFileStream) then FFileStream.Write(Data^, DataSize);
      //fifo.Push(Data, DataSize);
      Inc(FCurAdr, FPacketLen);

      //FEvent.SetEvent;
      WriteToBD;
    end;
    procedure NextRead(Status: EnumCopyAsyncRun);
    begin
      WriteStream;
     // if Assigned(FReadRamEvent) then FReadRamEvent(Status, FAdr, ProcToEnd);
      Read(DWord(FCurAdr), FPacketLen, FuncRead, wait, Fgrade); //рекурсия
    end;
    procedure EndWrite(Reason: EnumCopyAsyncRun);
    begin
      FEndReason := Reason;
      FFlagEndRead := True;
      WriteStream();
      //FEvent.SetEvent;
      CloseAny;
    end;
    procedure ResetConnection;
    begin
      Sleep(150);
      Application.ProcessMessages;
      try
        FAbstractDevice.IConnect.Close;
      except
        on e: Exception do TDebug.DoException(e, False);
      end;
      Sleep(150);
      Application.ProcessMessages;
      try
        FAbstractDevice.IConnect.Open;
      except
        on e: Exception do TDebug.DoException(e, False);
      end;
      Sleep(150);
      Application.ProcessMessages;
    end;

  begin
    if FFlagTerminate then
     begin
      //TDebug.Log('------FFlagTerminate-----');
//      FFlagEndRead := True;
      //WriteToBD;
      //CloseAny;
      Exit;
     end;
    if DataSize < 0 then
     begin
      Inc(ErrCnt);
      if ErrCnt > MAX_BAD then EndWrite(carError)
      else
       begin
        ResetConnection;
        Tdebug.Log('ReserConn nextRead  %d',[ErrCnt]);
        NextRead(carErrorSector);
       end;
     end
    else
     begin
//      if ErrCnt > 0 then LoSpeed := 1000
//      else if LoSpeed > 0 then Dec(LoSpeed, 10);
      ErrCnt := 0;

      if FFlagReadToFF then
       begin
         if isSSD then
         begin
           var rds : Cardinal;
           if CheckZerroes(Data, DataSize, rds) then
           begin
            DataSize := rds;
            EndWrite(carZerroes);
            Exit;
           end;
         end
         else if TestFF(@PbyteArray(Data)[DataSize-256], 256) then
          begin
           while (DataSize > 0) and (PbyteArray(Data)[DataSize-1] = $FF) do Dec(DataSize);
           EndWrite(carZerroes);
           Exit;
         end
       end;

      if (FCurAdr >= FToAdr) then EndWrite(carEnd)
      else NextRead(carOk);
     end;
  end;
//  if LoSpeed > 0 then
//   begin
//    Sleep(LoSpeed);
//   end;
  Read(DWord(FCurAdr), FPacketLen, FuncRead, wait, Fgrade); //начало рекурсии
end;
{$ENDREGION  TBurReadRam}

{$REGION  'TDeviceBur - все процедуры и функции'}
{ TDeviceBur }
procedure TDeviceBur.CheckConnect;
begin
  inherited CheckConnect;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolBur) then
   begin
    ConnectIO.FProtocol := TProtocolBur.Create;
   end;
end;

constructor TDeviceBur.Create;
begin
  inherited;
  FGetActions := TGetActionsImpl.Create(Self);
  FCycle := TCycleEx.Create(Self);
  /////
  Ftimer := TTimer.Create(Self);
  Ftimer.OnTimer := OnTimer;
  Ftimer.Interval := 3000;
  Ftimer.Enabled := False;
  /////
end;

constructor TDeviceBur.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  inherited;
  TRegister.AddType<TDeviceBur>.AddInstance(Name, Self as IInterface);
end;

destructor TDeviceBur.Destroy;
begin
  FCycle.Free;
  FGetActions.Free;
  inherited;
end;

function UnixTime32: UInt32;
begin
  Result := DateTimeToUnix(TTimeZone.Local.ToUniversalTime(Now));
end;


procedure TDeviceBur.SendUnixTime(Next: TProc; const Res: TInfoEventRes);
var
  d: TStdRec;
begin
  d := TStdRec.Create($F, 2, 4);
  d.AssignInt(UnixTime32());
  SendROW(d.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
  begin
    if (d.SizeOf <> n) then Next();
  end, 300);
end;

procedure TDeviceBur.DoData(Sender: IAction);
begin
  //Ftimer.Enabled := True;
  if (Self as ICycle).Cycle then
   begin
    (Self as ICycle).Cycle := False;
    Sender.Checked := False;
   end
  else if (S_Status in [dsNoInit, dsPartReady]) then
   begin
    FTmpSender := Sender;

    TMetaDataPipeline.Create.AddStep(procedure(Next: TProc; const Res: TInfoEventRes)
    begin
     if (Length(FAddressArray) = 1) and (Length(Res.ErrAdr) = 0) then
      begin
        ReadEeprom(FAddressArray[0], procedure (Res: TEepromEventRes)
        begin
          if Res.DevAdr = FAddressArray[0] then SaveEEprom(Res.eep);
          Next();
        end);
      end
    else Next();
    end).AddStep(SendUnixTime).Run(InitMetaData, InfoEvent);
    FTmpSender.Checked := True;
   end
  else
   begin
    FTmpSender := Sender;
    TMetaDataPipeline.Create.AddStep(SendUnixTime).Run(CheckMetaData, CheckInfoEvent);
    FTmpSender.Checked := True;
   end;
end;

procedure TDeviceBur.InfoEvent(Res: TInfoEventRes);
  var
  ix: IProjectDataFile;
begin
  FTmpSender.Checked := False;
  try
   if Length(Res.ErrAdr) > 0 then raise EAsyncBurException.CreateFmt(RS_MetadataERR, [AddressArrayToNames(Res.ErrAdr)])
   else if Supports(GlobalCore, IProjectDataFile, ix) then ix.MetaDataOK := True;
  finally
   if Length(FAddressArray) > Length(Res.ErrAdr) then
    begin
     FTmpSender.Checked := True;
     (Self as ICycle).Cycle := True;
    end;
  end;
end;

procedure TDeviceBur.CheckInfoEvent(Res: TInfoEventRes);
 var
  ix: IProjectDataFile;
  SavedDev, ReadDev: IXMLNode;
  ErrInfo: string;
  d: IXMLNode;
  CONST
   ERRMSG ='Версия подключенного прибора'+#$D#$A+'%s'+#$D#$A
     +' не совпадает с версией прибора текущего проекта'
     +#$D#$A+'%s'+#$D#$A+'необходимо создать новый проект, прибор';
begin
  FTmpSender.Checked := False;
  try
    ErrInfo := '';

    // Адреса из сохранённых метаданных — проверяем наличие и AT_INFO
    if Assigned(FMetaDataInfo.Info) and Assigned(FMetaDataInfo.Info.ChildNodes) then
     for d in XEnum(FMetaDataInfo.Info) do
      if d.HasAttribute(AT_ADDR) then
       begin
        var adr := d.Attributes[AT_ADDR];
        SavedDev := d;
        ReadDev := FindDev(Res.Info, adr);
        if Assigned(ReadDev) then
         if SavedDev.Attributes[AT_INFO] <> ReadDev.Attributes[AT_INFO] then
          begin
           ErrInfo := ErrInfo + Format(ERRMSG,[ReadDev.Attributes[AT_INFO], SavedDev.Attributes[AT_INFO]]);
          end;
       end;

    if ErrInfo <> '' then
     begin
      if Supports(GlobalCore, IProjectDataFile, ix) then ix.MetaDataOK := False;
      raise ENeedDialogException.Create(ErrInfo);
     end;
  finally
    FTmpSender.Checked := True;
    (Self as ICycle).Cycle := True;
  end;
end;


procedure TDeviceBur.DoDelay(Sender: IAction);
 var
  d: Idialog;
begin
  (GContainer as IActionEnum).Get(IName + '_DoStd').Checked := True;
  (Self as ICycleEx).StdOnly := True;
  if RegisterDialog.TryGet<Dialog_SetDeviceDelay>(d) then (d as IDialog<IDelayDevice>).Execute(Self as IDelayDevice);
//  if Supports(GlobalCore, Idialogs, d) then d.Execute(DIALOG_SetDeviceDelay, Self);
end;

procedure TDeviceBur.DoIdle(Sender: IAction);
begin
  if MessageDlg(RS_SleapDLG, mtWarning, [mbYes, mbNo, mbCancel], 0) <> mrYes then Exit;
  SetDelay(0, 0, nil);
end;

{procedure TDeviceBur.DoInfo(Sender: IAction);
begin
  InitMetaData(InfoEvent2);
end;

procedure TDeviceBur.InfoEvent2(Res: TInfoEventRes);
begin
  if Length(Res.ErrAdr) > 0 then raise EAsyncBurException.CreateFmt('Метаданные устройств (%s) не считаны', [TAddressRec(Res.ErrAdr).ToNames]);
end;}

//procedure TDeviceBur.DoRam(Sender: IAction);
// var
//  d: Idialog;
//begin
//  if RegisterDialog.TryGet<Dialog_RamRead>(d) then (d as IDialog<Integer>).Execute(FAddressArray[0]); { TODO : dialog box select modul for read }
//end;

procedure TDeviceBur.DoStd(Sender: IAction);
begin
  Sender.Checked := not Sender.Checked;
  (Self as ICycleEx).StdOnly := Sender.Checked;
end;

//procedure TDeviceBur.DoSync(Sender: IAction);
// var
//  d: Idialog;
//begin
//  if RegisterDialog.TryGet<Dialog_SyncDelay>(d) then (d as IDialog<IDevice>).Execute(Self as IDevice);
//end;

//function TDeviceBur.GetActionsDevClass: TAbstractActionsDevClass;
//begin
//  Result := TActionsDevBur;
//end;

procedure TDeviceBur.ReadEepromAdrSection(adr: Byte; siz, from: Integer; output: PByte; Res: TEepromSectionEventRef);
begin
  with SerialQe, ConnectIO do
   begin
    // MonitorDebug('ADD Before Read Eeprom %d', [Adr]);
     Add(procedure(qe: integer)
       var
        D: TStdRec;
      begin
      //  MonitorDebug('INVOKE Read Eeprom %x %d', [Adr, qe]);
        if siz > 252 then D := TStdRec.Create(adr, CMD_READ_EE, 4)
        else D := TStdRec.Create(adr, CMD_READ_EE, 3);

        D.AssignEEPRead(from, siz);

        Send(D.Ptr, D.SizeOf, procedure(p: Pointer; n: integer)
         var
          pb: PByte;
        begin
          if (n > 0) and (n-d.SizeOfAC = siz) and d.CheckAC(p) then
           begin
            pb := p;
            Inc(Pb, d.SizeOfAC);
            Move(pb^, output^, siz);
            Res(adr, siz, from, False);
           end
           else Res(adr, siz, from, True);
        end);
      end);
   end;
end;

procedure TDeviceBur.ReadEepromSectionsRef(eep: IXMLNode; adr: Byte; ev: TEepromEventRef);
 var
  GlobRes: TEepromEventRes;
  sects: TArray<Byte>;
  outAt, i,e: Integer;
  recur: TEepromSectionEventRef;
  strerr: string;
begin
  SetLength(sects, Integer(eep.Attributes[AT_SIZE]));
  i := -1;
  e := 0;
  outAt := 0;
  strerr := '';
  recur := procedure (adr: Byte; siz, from: Integer; Err: Boolean)
   var
    sec: IXMLNode;
  begin
    if Err then
     begin
      strerr := strerr + Format(RS_ERR_eep, [adr, siz, from]);
      inc(e);
      eep.ChildNodes[i].Attributes[AT_READED] := False;
     end;
    Inc(i);
    Inc(outAt, siz);
    if i = eep.ChildNodes.Count then
     begin
       if i > e then
         try
          TPars.SetData(eep, @sects[0]);
          FExeMetr.Execute(T_EEPROM, Adr);
         finally
          FeepromEventInfo.DevAdr := adr;
          FeepromEventInfo.eep := eep;
          if Assigned(ev) then ev(FeepromEventInfo);
          Notify('S_EepromEventInfo');
         end;
       if strerr <> '' then raise EEEpromSectionsException.Create(strerr);
       Exit;
     end;
    sec := eep.ChildNodes[i];
    sec.Attributes[AT_READED] := True;
    from := sec.Attributes[AT_FROM];
    siz := sec.Attributes[AT_SIZE];
    ReadEepromAdrSection(adr, siz, from, @sects[outAt], recur)
  end;
  recur(adr, 0, 0, False);
end;

function TDeviceBur.CreateReadRam: TReadRam;
begin
  if Supports(IConnect, ImicroSDConnectIO) then Result := TBurReadRam.Create(Self)
  else Result := TBurReadRam.Create(Self);
end;

//function TDeviceBur.GetRamReadInfo: IRamReadInfo;
//begin
//  Result := TRamReadInfoBur.Create(Self);
//end;

//function TDeviceBur.GetReadDeviceRam: IReadRamDevice;
//begin
//  Result := TBurReadRam.Create(Self);
//end;

function TDeviceBur.GetSerialQe: TProtocolBur;
begin
  Result := TProtocolBur(ConnectIO.FProtocol);
end;

procedure TDeviceBur.CheckMetaData(ev: TInfoEvent);
 var
//  a: TArray<IXMLNode>;
  cnt, total: Integer;
  IsOldClose: Boolean;
  CheckInfo: IXMLInfo;
  TmpErr, TmpGood: TAddressArray;

begin
  total := Length(FAddressArray);

  CheckConnect;
  IsOldClose := not ConnectOpen();

  TmpErr := [];
  TmpGood := [];
  cnt := 0;

   var  xd := NewXDocument();
   CheckInfo := xd.AddChild('PROJECT').AddChild('DEVICES');

  for var a in FAddressArray do ReadInfoAdr(a, procedure (Exc: Integer; Adr: Integer; Data: PByte; n: Integer)
   begin
    if Exc = 0 then
     begin
      if Data^ = varRecord then
       TPars.SetInfo(CheckInfo, Data, n)
      else
        TnewPars.SetInfo(CheckInfo, Data, n);
      TmpGood := TmpGood + [Adr];
     end
    else
     TmpErr := TmpErr + [Adr];

    Inc(cnt);
    if cnt = total then
     try
      if IsOldClose then ConnectClose;
      var Res: TInfoEventRes;
      Res.ErrAdr := TmpErr;
      Res.Info := CheckInfo;
      if Assigned(ev) then ev(Res);
     finally
      //Notify('S_MetaDataInfo');
     end;
   end);
end;

procedure TDeviceBur.UpdateCb(adr: integer; IsGood: Boolean; var TmpErr, TmpGood: TAddressArray; IsOldClose: Boolean; ev: TInfoEvent; var cnt: Integer);
 var
  i: Integer;
  ip: IProjectMetaData;
begin
  if IsGood then
   TmpGood := TmpGood + [adr]
  else
   TmpErr := TmpErr + [adr];

  Inc(cnt);
  if (cnt >= Length(FMetaDataInfo.ErrAdr)) then
   try
    FMetaDataInfo.ErrAdr := TmpErr;

    if Length(TmpErr) = 0 then S_Status := dsReady
    else if Length(TmpErr) < Length(FAddressArray) then S_Status := dsPartReady
    else S_Status := dsNoInit;

    if IsOldClose then connectClose;

  //  TDebug.Log('Root3: %s %d', [FMetaDataInfo.Info.NodeName, FMetaDataInfo.Info.ChildNodes.Count]); проблемма записи ресинк

    if Supports(GlobalCore, IProjectMetaData, ip) then
      for i in TmpGood do
       begin
         FExeMetr.UpdateExecRunSetupMetr(FMetaDataInfo.Info, i, FExeMetr);
         ip.SetMetaData(Self as IDevice, i, FindDev(FMetaDataInfo.Info, i)); //проблемма записи ресинк решена сдесь
       end;

  //  TDebug.Log('Root4: %s %d', [FMetaDataInfo.Info.NodeName, FMetaDataInfo.Info.ChildNodes.Count]); проблемма записи ресинк
//      FMetaDataInfo.Info.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'DevBur_SetMetr.xml');
   finally
    try
     if Assigned(ev) then ev(FMetaDataInfo);
    finally
     Notify('S_MetaDataInfo');
    end;
  end;
end;


procedure TDeviceBur.InitMetaData(ev: TInfoEvent);
 var
  cnt: Integer;
  IsOldClose: Boolean;
  TmpErr, TmpGood: TAddressArray;
begin
  with  FMetaDataInfo do
  begin
   if Length(ErrAdr) = 0 then
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

   TmpErr := [];
   TmpGood := [];
   cnt := 0;
   for var a in ErrAdr do ReadInfoAdr(a, procedure (Exc: Integer; Adr: Integer; Data: PByte; n: Integer)
      var
       i: Integer;
       ip: IProjectMetaData;
    begin
      if Exc = 0 then
       begin
        if Data^ = varRecord then
         TPars.SetInfo(FMetaDataInfo.Info, Data, n) // parse all data for device
        else
         begin
          var dv := TnewPars.SetInfo(FMetaDataInfo.Info, Data, n);//, adr, ProfilePath);
          if dv.NodeName = 'Profiles'  then
           begin
            ProfilePatch(adr,dv, procedure (adr: integer; SelectProfile: IXMLInfo; Err: string)
              begin
               UpdateCb(adr,  Assigned(SelectProfile),TmpErr, TmpGood, IsOldClose, ev, cnt);
               if Err <> '' then raise ENeedDialogException.Create(Err)
              end);
            exit;
           end;
         end;
       end;
      UpdateCb(adr,  Exc = 0,TmpErr, TmpGood, IsOldClose, ev, cnt);
   end);
  end;
end;

procedure TDeviceBur.MonitorDebug(const ddata: string; const Args: array of const);
begin
 var d :=  IConnect as IDebugIO;
 if Assigned(d.IOEventString) then d.IOEventString(iosDebug,Format(ddata, Args));
end;

procedure TDeviceBur.OnTimer(Sender: TObject);
begin
  DoData(FTmpSender);
end;


procedure TDeviceBur.ProfilePatch(adr: integer; node: IXMLnode; event: TProfilePatchEventRef);
 type
  PCartD32 = ^TCartD32;
  TCartD32 = packed record
  cmd: Byte;
  len: Word;
  data: Integer;
  end;
 var
  dia: IDialog;
begin
 if RegisterDialog.TryGet<Dialog_MultiProfile>(dia) then (dia as IDialog<IXMLnode, TProc<Integer>>).Execute(node,
    procedure(Profile: Integer)
     var
      D: TCartD32;
      idx: integer;
    begin
      for var I := 0 to node.ChildNodes.Count-1 do
       if node.ChildNodes[i].HasAttribute('profile') then
        if node.ChildNodes[i].Attributes['profile'] = Profile then idx := i;
      D.cmd := $19;
      D.len := 9;
      D.data := Profile;
      SendROW(@d, sizeof(d),
        procedure(p: Pointer; n: integer)
//         var
//          ip: IProjectMetaData;
        begin
          if (n = 7) and (PCartD32(p).data <> $55555555) then
           begin
            node :=TnewPars.PatchProfile(node, idx);
            event(adr, node)
//            if Supports(GlobalCore, IProjectMetaData, ip) then
//            begin
//             FExeMetr.UpdateExecRunSetupMetr(FMetaDataInfo.Info, adr, FExeMetr);
//             ip.SetMetaData(Self as IDevice, adr, FindDev(FMetaDataInfo.Info, adr)); //проблемма записи ресинк решена сдесь
//            end;
//            Notify('S_MetaDataInfo');
           end
          else event(adr, nil, Format('Ошибка выбора профиля: %s',[node.ChildNodes[idx].NodeName]));
        end, 2100);
    end);

end;

function TDeviceBur.PropertyReadRam: TReadRam;
begin
  Result := inherited;
end;

//type
//  TTurbo = packed record
//    CmdAdr: TCmdADR;
//    speed: Byte;
//  end;

procedure TDeviceBur.Turbo(adr: Byte; speed: integer);
 const                         //default 125000          2250000
  SPD: array[0..10]of Integer = (125000, 500000, 1000000, 1500000, 2000000, 2250000, 3000000, 6000000, 8000000, 12000000, 100000000);
begin
  with SerialQe, ConnectIO do
   begin
    Add(procedure(qe: integer)
     var
      d: TStdRec;
      oldOpen: Boolean;
    begin
      if adr > 16 then d := TStdRec.Create($FF, $FD, 1)
      else d := TStdRec.Create($F, $D, 1);
      d.AssignByte(speed);
      CheckConnect;
      oldOpen := ConnectOpen;
      Send(D.Ptr, D.SizeOf, procedure(p: Pointer; n: integer)
      begin
          if speed = 0 then
           begin
            if ConnectIO is TComConnectIO then
            TComConnectIO(ConnectIO).Com.CustomBaudRate := TComConnectIO(ConnectIO).FDefaultSpeed;
//      Exit;
        end else if ConnectIO is TComConnectIO then TComConnectIO(ConnectIO).Com.CustomBaudRate := SPD[speed];
        if not oldOpen then ConnectClose;
      end, 300);
    end);
   end;
end;

procedure TDeviceBur.ReadInfoAdr(adr: Byte; ev: TNotifyInfoEventRef);
type
  PInfoDataHeader=^TInfoDataHeader;
  TInfoDataHeader=packed record
//   CmdAdr: TCmdADR;
   varType: Byte;
   Length: Word;
  end;
  PNewInfoDataHeader=^TNewInfoDataHeader;
  TNewInfoDataHeader=packed record
   Length: Word;
  end;
  const DIHLEN = SizeOf(TInfoDataHeader);
begin
  //  TDebug.Log('ReadInfoAdr %d',[adr]);
  //MonitorDebug('ReadInfoAdr %d',[adr]);
  with SerialQe, ConnectIO do
   begin
    // TDebug.Log('1 QE ADD %d',[adr]);
     Add(procedure(qe: integer)
       var
        D1: TStdRec;
      begin
      //  TDebug.Log('1 QE RUN %d',[adr]);
        D1 := TStdRec.Create(adr, CMD_INFO, 1);
        D1.AssignByte(DIHLEN);
      //   Tdebug.Log('std SEND %x', [d1.CmdAdr]);
      //  MonitorDebug('begin INFO SEND %d %d', [d1.Adr, d1.cmd]);
        (IConnect as IDebugIO).TimoutPayload('begin INFO SEND', d1.adr);
        Send(D1.Ptr, D1.SizeOf, procedure(p1: Pointer; n1: integer)
           var
            savelen: Word;
            from: Word;
            recur: TReceiveDataRef;
            Data: TArray<Byte>;
            bads: Integer;
            Dn: TStdRec;
           // tst: TInfoDataHeader;
         begin
           // MonitorDebug('begin INFO SEND data %d %d %d', [d1.Adr, d1.cmd, n1]);
       //    if assigned(p1) then Tdebug.Log('std READ Header = %x  D1 = %x', [PInfoDataHeader(p1).CmdAdr, d1.CmdAdr])
       //    else Tdebug.Log('std READ Header = nil  D1 = %x', [d1.CmdAdr]);
           if (n1 = D1.SizeOfAC + DIHLEN) and (D1.CheckAC(p1)) then
            begin
              Dn := TStdRec.Create(p1, adr>15, DIHLEN);
           //  tst := PInfoDataHeader(p1)^;
             if PInfoDataHeader(Dn.DataPtr).varType = varRecord then
              savelen := PInfoDataHeader(Dn.DataPtr).Length
             else
              savelen := PNewInfoDataHeader(Dn.DataPtr).Length;
            // Tdebug.Log('%d', [savelen]);
             from := 0;
             bads := 0;
             SetLength(Data, savelen);// + CASZ);
            // PCmdAdr(@Data[0])^ := d1.CmdAdr;

             recur := procedure(pr: Pointer; nr: integer)
               var
                pb: PByteArray;
                n: Integer;
              begin
                pb := pr;
           //     if Assigned(Pb) then Tdebug.Log('adv recur READ Header=%x adr=%x S=%x', [pb[0], adr, saveCmdAdr])
           //     else Tdebug.Log('adv recur READ Header=NIL adr = %x  D1 = %x', [adr, saveCmdAdr]);
                if (nr > D1.SizeOfAC) and D1.CheckAC(pr) then
                 begin
                  n := nr - D1.SizeOfAC;
                  move(pb[D1.SizeOfAC], Data[from], n);
                  Inc(from, n);
                  if from >= savelen then
                   begin
                    //MonitorDebug('end recur %d %d', [Adr, from]);
                    //Tdebug.Log(from.ToString + '  ' + savelen.ToString());
                    ev(0, adr, @Data[0], savelen);
                    Exit;
                   end;
                 end
                else
                 begin
                  inc(bads);
                 // MonitorDebug('bad recur %d %d %d', [Adr, from, bads]);
                  if bads > 7 then
                   begin
                    ev(-1, adr, pr, nr);
                    Exit;
                   end;
                 end;
              // TDebug.Log('2 QE ADD %d',[adr]);
              // MonitorDebug('before recur %d %d', [Adr, from]);
               Add(procedure(qe: integer)
                 var
                  D: TStdRec;
                  l: Integer;
                begin
                //  TDebug.Log('2 QE RUN %d',[adr]);

                  D := TStdRec.Create(adr, CMD_INFO, 3);
                  if savelen-from > LEN_MAX_SHORT-D.SizeOfAC then
                       l := LEN_MAX_SHORT-D.SizeOfAC
                  else l := savelen-from;
                  D.AssignAdvStdRead(l, from);
                //  Tdebug.Log('adv recur SEND %x', [d.CmdAdr]);
                //  MonitorDebug('send recur %d %d', [Adr, from]);
                  Send(D.Ptr, D.SizeOf, recur);
                end)
              end;
             recur(nil, -1);
             //if savelen > 252 then raise EAsyncBurException.CreateFmt('Поддерживается длина метаданных меньше 252 текущая: %d', [savelen]);
            end
           else ev(-1, adr, p1, n1);
         end);
      end);
   end;
end;

procedure TDeviceBur.WriteEeprom(Addr: Integer; ev: TResultEventRef; section: Integer = -1);
 var
  e: IXMLNode;
  recur: TRunSerialQeRef;
begin
  CheckConnect;
  ConnectOpen;
  e := FindEeprom(FMetaDataInfo.Info, Addr);
  if not Assigned(e) then raise EBurException.CreateFmt(RS_NO_eepmeta, [Addr]);
  if e.ChildNodes.First.HasAttribute(AT_FROM) then // деление EEPROM на секции
   begin
     var a: TPars.TOutArray;
     var secind := 0;
     var sect : IXMLNode;
     var arrptr := 0;
     var GoodFlag := true;
     var errStr := '';
     TPars.GetData(e, a);
     while (section <> -1) and (secind < section) do
      begin
       sect := e.ChildNodes[secInd];
       Inc(secind);
       Inc(arrptr, Integer(sect.Attributes[AT_SIZE]));
      end;
     recur := procedure(qe: integer)
     begin
      with SerialQe, ConnectIO do
       begin
        sect := e.ChildNodes[secInd];
        sect.Attributes[AT_WRITED] := False;
        Add(procedure(qe: integer)
           var
            D: TStdRec;
            From: Word;
            Siz: Integer;
          begin
            From := sect.Attributes[AT_FROM];
            Siz := sect.Attributes[AT_SIZE];
            D := TStdRec.Create(Addr, CMD_WRITE_EE, Siz + 2);
            D.AssignEEPWriteP(From, Siz, @a[arrptr]);
            Send(D.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
            begin;
              if n = d.SizeOfAC then sect.Attributes[AT_WRITED] := True
              else
               begin
                GoodFlag := False;
                errStr := errStr + Format(RS_ERR_eepwr,[addr, siz, from]);
               end;
              Inc(secind);
              Inc(arrptr, Siz);
              if (secind < e.ChildNodes.Count) and (section = -1) then recur(-1)
              else if Assigned(ev) then
               begin
                ev(GoodFlag);
                if errStr <> '' then raise EEEpromSectionsException.Create(errStr);
              end;
            end, 2000);
          end);
       end;
     end;
    recur(-1);
   end
  else
   with SerialQe, ConnectIO do
    begin
     Add(procedure(qe: integer)
       var
        a: TPars.TOutArray;
        D: TStdRec;
      begin
        TPars.GetData(e, a);
        D := TStdRec.Create(Addr, CMD_WRITE_EE, Length(a) + 2);
        D.AssignEEPWrite(0, a);
//        D := TEepWrite.Create(Addr, 0, a);
        Send(D.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
        begin;
          if Assigned(ev) then ev(n = d.SizeOfAC);
        end, 2000);
      end);
    end;
end;


procedure TDeviceBur.SaveEEprom(rootEEP: IXMLNode);
 var
  m: IMainScreen;
  a: TPars.TOutArray;
  s : TStream;
begin
  if not Supports(GContainer, IMainScreen, m) then Exit;
  var pfile := m.StatusBarText[1];
  var dir := Tpath.GetDirectoryName(pfile);
  // save sections
  for var e in XEnum(rootEEP) do if e.HasAttribute(AT_FROM) then
   begin
    TPars.LocalGetData(e, a);
    var binf := Tpath.Combine(dir, e.LocalName + '.bin');
    s := TFileStream.Create(binf, fmCreate);
    try
     s.Write(a[0], Length(a));
    finally
     s.Free;
    end;
   end;
end;

procedure TDeviceBur.ReadEEPAfterInfo(adr: integer; CbEnd: TProc);
begin
  ReadEeprom(Adr, procedure (Res: TEepromEventRes)
  begin
    if Res.DevAdr <> Adr then Exit;
    SaveEEprom(Res.eep);
    CbEnd();
  end);
end;

procedure TDeviceBur.ReadEeprom(Addr: Integer; ev: TEepromEventRef);
begin
  CheckConnect;
  ConnectOpen;
  if not Assigned(FMetaDataInfo.Info) then raise EBurException.Create(RS_ErrNoInfo);
  FindAllEeprom(FMetaDataInfo.Info, procedure(eep: IXMLNode; Adr: integer; const name: string)
  begin
  if Addr = Adr then
    begin
      if eep.ChildNodes.First.HasAttribute(AT_FROM) then // деление EEPROM на секции
       begin
        ReadEepromSectionsRef(eep,Adr,ev);
       end
      else ReadEepromAdrRef(eep, adr, procedure (Res: TEepromEventRes)
      begin
       try
        FExeMetr.Execute(T_EEPROM, Adr);
       finally
        if Assigned(ev) then ev(res);
       end;
      end);
    end;
  end);
end;

procedure TDeviceBur.ReadWork(ev: TWorkEvent; StdOnly: Boolean);
 var
  ip: IProjectData;
  ix: IProjectDataFile;
begin
  CheckConnect;
  ConnectOpen;
  ReadWorkRef(FMetaDataInfo.Info, procedure (DevAdr: Integer; Work: IXMLInfo; Data: PByte; n: Integer)
  begin
    FWorkEventInfo.DevAdr := DevAdr;
    FWorkEventInfo.Work := Work;
    try
     FExeMetr.Execute(T_WRK, DevAdr);

//     FMetaDataInfo.Info.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'INCL.xml');

     if Supports(GlobalCore, IProjectDataFile, ix) then ix.SaveLogData(Self as IDevice, DevAdr, Work, Data, n)
     else if Supports(GlobalCore, IProjectData, ip) then ip.SaveLogData(Self as IDevice, DevAdr, Work, StdOnly);
    finally
     if Assigned(ev) then ev(FWorkEventInfo);
     Notify('S_WorkEventInfo');
    end;
  end, StdOnly);
end;

procedure TDeviceBur.ReadWorkRef(Info: IXMLNode; ev: TWorkEventRef; StdOnly: Boolean);
begin
  if not Assigned(Info) then raise EBurException.Create(RS_ErrNoInfo);
  FindAllWorks(Info, procedure(wrk: IXMLNode; Adr: integer; const name: string)
  begin
    ReadWorkAdrRef(wrk, adr, StdOnly, ev);
  end);
end;

procedure TDeviceBur.ReadEepromAdrRef(root: IXMLNode; adr: Byte; ev: TEepromEventRef);
 var
  siz: Integer;
  from: Integer;
begin
  siz := root.Attributes[AT_SIZE];
  if siz > 250 then raise EAsyncBurException.CreateFmt(RS_ERR_eepLen, [siz]);
  if root.HasAttribute(AT_FROM) then from := root.Attributes[AT_FROM] else from := 0;
  with SerialQe, ConnectIO do
   begin
     Add(procedure(qe: integer)
       var
        D: TStdRec;
      begin
        D := TStdRec.Create(adr, CMD_READ_EE, 3);
        D.AssignEEPRead(from, siz);
        Send(D.Ptr, D.SizeOf, procedure(p: Pointer; n: integer)
         var
          pb: PByte;
        begin
          if (n > 0) and (n-d.SizeOfAC = siz) and d.CheckAC(p) then
           begin
            pb := p;
            Inc(Pb, d.SizeOfAC);
            TPars.SetData(root, pb);
//            FMetaDataInfo.Info.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'GK.xml');
            FeepromEventInfo.DevAdr := adr;
            FeepromEventInfo.eep := root;

            if Assigned(ev) then ev(FeepromEventInfo);
            Notify('S_EepromEventInfo');
           end
           else if n<=0 then raise EAsyncBurException.CreateFmt(RS_ErrReadData, [adr, n, siz, d.Adr])
           else  raise EAsyncBurException.CreateFmt(RS_ErrReadData, [adr, n, siz, PByte(p)^]);
        end);
      end);
   end;
end;


procedure TDeviceBur.ReadWorkAdrRef(root: IXMLNode; adr: Byte; StdOnly: Boolean; ev: TWorkEventRef);
 var
  siz, nq: Integer;
  cntStd: Integer;
  p: IXMLNode;
begin
  cntStd := -1;
  if StdOnly then
   begin
    p := root.ParentNode;
    if Assigned(p) and p.HasAttribute(AT_EXT_NP_LEN) then
     begin
      siz := p.Attributes[AT_EXT_NP_LEN];
      cntStd := p.Attributes[AT_EXT_NP];
      end
    else
     begin
      siz := SizeOf(LongWord) + SizeOf(Byte);
      cntStd := 2;
     end;
   end
  else siz := root.Attributes[AT_SIZE];
  nq := -1;
  with SerialQe, ConnectIO do
   begin
    nq := Add(procedure(qe: integer)
       var
        D: TStdRec;
      begin
        if siz < 255 then
         begin
          D := TStdRec.Create(adr, CMD_WORK, 1);
          D.AssignByte(siz);
         end
        else
         begin
          D := TStdRec.Create(adr, CMD_WORK, 2);
          D.AssignWord(siz);
         end;
      //  MonitorDebug('WORK WRITE %d %d',[adr, qe]);
        (IConnect as IDebugIO).TimoutPayload('WORK timout', adr);
        Send(D.Ptr, d.SizeOf, procedure(p: Pointer; n: integer)
         var
          pb,pbs: PByte;
        begin
          pb := p;
          if (n > 0) and ((n-D.SizeOfAC) = siz) and D.CheckAC(pb) then
           begin
            inc(pb, D.SizeOfAC);
//            if StdOnly then TPars.SetStd(root, pb)
//            else
            TPars.SetData(root, pb, True, cntStd);
//            FMetaDataInfo.Info.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'GK.xml');
            if Assigned(ev) then
             begin
              if StdOnly then
               begin
                pbs := pb;
                inc(pbs,siz);
                fillchar(pbs^, Integer(root.Attributes[AT_SIZE])-siz, 0);
               end;
              ev(adr, root, pb, root.Attributes[AT_SIZE]);
             end;
           end
           else if n<=0 then raise EAsyncBurException.CreateFmt(RS_ErrReadData, [adr, n, siz, d.adr])
           else  raise EAsyncBurException.CreateFmt(RS_ErrReadData, [adr, n, siz, PByte(p)^]);
         // MonitorDebug('WORK end %d %d',[adr ,n]);
        end);
      end);
   end;
  // if nq > 1 then  MonitorDebug('================== WORK start %d, %d',[adr, nq]);
end;

procedure TDeviceBur.SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
begin
  CheckConnect;  //низkоуровневая функция без особых проверок
  CheckLocked;
  ConnectOpen();
  try
   SerialQe.Add(procedure(qe: integer)
   begin
     inherited;
   end);
  except
   SerialQe.Clear;
   raise;
  end;
end;

//type
//  TTimeSync = packed record
//    CmdAdr: TCmdADR;
//    time: Integer;
//  end;
procedure TDeviceBur.SetDelayRTC(StartTime: TDateTime; ResultEvent: TSetDelayEvent);
 type
     Rt = packed record
      CodedDelay: Int32;
      CodedDate: UInt32;
 end;
 var
  IsOldClose: Boolean;
begin
  try
   CheckStatus([dsNoInit, dsPartReady, dsReady, dsData]);
   CheckConnect;
   CheckLocked;
   IsOldClose := not ConnectOpen();
   SerialQe.Clear;
   with SerialQe, ConnectIO do Add(procedure(qe: integer)
     var
      D: TStdRec;
      TimePC: TDateTime;
      ElapsedFrames: Double;
      NextFrameIndex: UInt32;
      TargetFrameTime: TDateTime;
      data: Rt;
      // Переменные таймингов
      TotalTransitTimeSec: Double;
      TimeToWaitMS: Integer;
   begin
     d := TStdRec.Create($F, 5, 8);

      TimePC := Now;

      // 1. Рассчитываем сетку кадров ПК
      ElapsedFrames := (TimePC - DateEpoch) / FrameInDays;
      NextFrameIndex := Trunc(ElapsedFrames) + 1;
      TargetFrameTime := DateEpoch + (NextFrameIndex * FrameInDays);

      // 2. Упреждение: 1.16 мс (пакет по UART + 3.5 тишины) + 14 мс (компенсация буфера ОС USB-UART)
      TotalTransitTimeSec := 0.01516;

      // 3. Защита: если до кадра осталось меньше 40 мс, переносим на следующий кадр,
      // иначе Windows гарантированно не успеет проснуться от Sleep
      if ((TargetFrameTime - TimePC) * SecInDay) < (TotalTransitTimeSec + 0.040) then
      begin
        Inc(NextFrameIndex);
        TargetFrameTime := DateEpoch + (NextFrameIndex * FrameInDays);
      end;

      // 4. Расчет полезной нагрузки строго для выбранного будущего кадра
      data.CodedDate := NextFrameIndex;
      data.CodedDelay := Round((TargetFrameTime - StartTime) / FrameInDays);
      D.Assign(@data);


      // 6. Считаем время ожидания в миллисекундах
      TimeToWaitMS := Round(((TargetFrameTime - Now) * SecInDay - TotalTransitTimeSec) * 1000);

      // 7. Основной сон. Вычитаем 2 мс зазора, чтобы планировщик Windows не "переспал" точку старта
      if TimeToWaitMS > 5 then
        Sleep(TimeToWaitMS - 2);

      // 8. Финальный микро-доводчик (Spin-wait). Занимает не более 2-3 мс, CPU не нагрузит.
      while ((TargetFrameTime - Now) * SecInDay) > TotalTransitTimeSec do
      begin
        // Ловим точную приборную отметку (TargetFrameTime - 15.16 мс)
      end;


     Send(D.Ptr, d.Sizeof, procedure(p: Pointer; n: integer)
     begin
       DoDelayEvent(True, CTimeNew.UInt32RTCToDateTime(data.CodedDate) ,
                          CTimeNew.Int32DelayToDateTime(data.CodedDelay), 0, ResultEvent);
       if IsOldClose then ConnectClose();
     end, 100);
   end);
  except
   DoDelayEvent(False, 0, 0, 0, ResultEvent);
   if IsOldClose then ConnectClose();
   raise;
  end;
end;

procedure TDeviceBur.SetDelay(StartTime: TDateTime; WorkTime: TTime; ResultEvent: TSetDelayEvent);
 var
  IsOldClose: Boolean;
begin
  try
   CheckStatus([dsNoInit, dsPartReady, dsReady, dsData]);
   CheckConnect;
   CheckLocked;
   IsOldClose := not ConnectOpen();
   SerialQe.Clear;
   with SerialQe, ConnectIO do Add(procedure(qe: integer)
    var
     D: TStdRec;
//     LNow,
     CNow: TDateTime;
     Delay, RDelay : TTime;
     kadrDelay: Integer;
   begin
     if FAddressArray[0] > 16 then d := TStdRec.Create($FF, $F5, 4)
     else d := TStdRec.Create($F, 5, 4);
//     D := TStdRec.Create(@buf, $FF, $F5, 4);
//     d.CmdAdr := ToAdrCmd($FF, $F5);//$F5
     if StartTime <> 0 then
      begin
       //LNow := Now();
       Delay := StartTime - Now();
       /// kadrDelay <Delay
       kadrDelay := Trunc(Delay * CTime.TIME_TO_KADR);
//       d.time := -kadrDelay;//  -Ctime.ToKadr(Delay);
       D.AssignInt(-kadrDelay);
       /// задержка  кадров по времени
       RDelay := Ctime.FromKadr(kadrDelay); //-Ctime.FromKadr(d.time);
       //Tdebug.Log('%1.5f',[(Delay-RDelay)*24*3600*1000]);
       /// время постановки на задержку синхронно кадрам ожидание до 2ух секунд
       CNow := StartTime - RDelay;// LNow + Delay - RDelay;
       //     Tdebug.Log('Delay Delta %1.2f %% ', [(CNow - Now)*TIME_TO_KADR*100]);
       while CNow > Now do
        begin
         Tthread.Yield;
       //  Tdebug.Log('%1.5f',[(CNow- Now)*24*3600*1000]);
        end;
      end
     else d.AssignInt(0);

     Send(D.Ptr, d.Sizeof, procedure(p: Pointer; n: integer)
     begin
      // Tdebug.Log('%1.5f',[(Now - CNow)*24*3600*1000]);
       DoDelayEvent(True, CNow, RDelay, 0, ResultEvent);
       if IsOldClose then ConnectClose();
     end, 100);
//     Tdebug.Log('Delay Delta ERR %1.4f %%', [(StartTime - Now-RDelay)*TIME_TO_KADR*100]);
   end);
  except
   DoDelayEvent(False, 0, 0, 0, ResultEvent);
   if IsOldClose then ConnectClose();
   raise;
  end;
end;
{$ENDREGION  TDeviceBur}

{$REGION  'TRamReadInfoBur - все процедуры и функции'}
{ TRamReadInfoBur }
//procedure TRamReadInfoBur.Get_Tstart_Tdelay(RAMInfo: IRAMInfo; var tstart, tdelay: TDateTime);
//begin
//  tstart := StrToDateTime(RAMInfo.Attributes[AT_START_TIME]);
//  tdelay := MyStrToTime(RAMInfo.Attributes[AT_DELAY_TIME]);
//end;

{function TRamReadInfoBur.Update(Info: IXMLInfo; UpdateTimeSyncEvent: TRamEvent): IRAMInfo;
  var
   rf: IRAMInfo; // так как невозможно захватить Result
begin
  with TDeviceBur(FAbstractDevice) do
   begin
    CheckConnect;
    if (ConnectIO as IConnectIO).Locked(Cycle) then raise ERamReadInfoBurException.Create(RS_IsCycle);
    if not (ConnectIO as IConnectIO).IsOpen then (ConnectIO as IConnectIO).Open;
    // обновим файл информации чтения
    Result := Get();
    if not Assigned(Info) then raise ERamReadInfoBurException.Create(RS_ErrNoInfo);
    if UpdateRun(Result, Info) then Result.OwnerDocument.SaveToFile(FileInfo);
    // обновим файл информации чтения коэффициенты рассогласования времени
    rf := Result; // так как невозможно захватить Result
    ReadWorkRef(rf, procedure (DevAdr: Integer; Work: IXMLInfo)
     var
      nt, p: IXMLNode;
      ts, td, t: TDateTime;
    begin
      nt := Work.ChildNodes.FindNode('время');
      p := FindDev(rf, DevAdr);
      if not p.HasAttribute(AT_KOEF_TIME) and Assigned(nt) then
       begin
        Get_Tstart_Tdelay(rf, ts, td);
        t := StrToTime(nt.Attributes[AT_ROW]);        //относительное время
        p.Attributes[AT_KOEF_TIME] := (Now-ts)/(t+td); //относительное время
        rf.OwnerDocument.SaveToFile(FileInfo);
        if Assigned(UpdateTimeSyncEvent) then UpdateTimeSyncEvent(DevAdr, Work);
       end;
    end, True);
   end;
end;  }
{$ENDREGION  TRamReadInfoBur}


initialization
  RegisterClass(TDeviceBur);
  TRegister.AddType<TDeviceBur, IDevice>.LiveTime(ltSingletonNamed)
finalization
  GContainer.RemoveModel<TDeviceBur>;
end.
