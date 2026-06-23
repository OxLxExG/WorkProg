unit VCLDlgRam;

interface

uses RootIntf,
  DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, debug_except, SDcardToolsAsync,  System.Threading, FileCachImpl,
  System.TypInfo, Vcl.Menus,  System.IOUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Container,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Xml.XMLIntf,
  System.Bindings.Helper, Vcl.ExtCtrls, Vcl.Mask, JvExMask, JvToolEdit, RangeSelector, VCLFrameRangeSelect;

type
  EFrmDlgRam = class(ENeedDialogException);
  TFormDlgRam = class(TDialogIForm, IDialog, IDialog<IXMLNode, TDialogResult>)
    btStart: TButton;
    btExit: TButton;
    cbToFF: TCheckBox;
    Progress: TProgressBar;
    btTerminate: TButton;
    sb: TStatusBar;
    rg: TRadioGroup;
    lbFile: TLabel;
    od: TJvFilenameEdit;
    edLen: TEdit;
    lbLen: TLabel;
    cbSD: TComboBox;
    lbSD: TLabel;
    cbClcCreate: TCheckBox;
    RangeSelect: TFrameRangeSelect;
    btContinue: TButton;
    lblssd: TLabel;
    procedure btTerminateClick(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure cbSDChange(Sender: TObject);
    procedure cbSDDropDown(Sender: TObject);
    procedure rgClick(Sender: TObject);
    procedure btContinueClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
    FDevs: TArray<TLogicalDevice>;
    FSDStream: TSDStream;
//    FTerminate: Boolean;
    FTerminated: Boolean;
    FRecSize: Integer;
    FFrom: UInt64;
    FCnt: UInt64;

    FModul: IXMLNode;
    FRes: TDialogResult;
    FDev: IDevice;

    FRamSize: UInt64;
    FDelayStart: TDateTime;
    FkadrSize: Integer;

    FAppend: Boolean;
    FAppendEnable: Boolean;

    Fgrade: Integer;
    IsSSD : Boolean;

    FS_TableModulUpdate: string;
    procedure CheckRAMFile(ram: IXMLNode);
    procedure inerRead(Append: Boolean);
    procedure inerExecute(IsImport: boolean);
    procedure inerReadSSD;
    procedure NImportClick(Sender: TObject);
    procedure NExportClick(Sender: TObject);
    function GetDevice: IDevice;
    procedure UpdateControls(FlagEna: Boolean);
    procedure UpdateControlsSD(SDEna: Boolean);
    procedure UpdateStat(car: EnumCopyAsyncRun; Stat: TStatistic);
    procedure ReadSSDEvent(car: EnumCopyAsyncRun; Stat: TStatistic);
    procedure ReadRamEvent(EnumRR: EnumCopyAsyncRun; DevAdr: Integer; Stat: TStatistic);
    procedure Onterminate(Res: Boolean);
  protected
    procedure Loaded; override;
    function GetInfo: PTypeInfo; override;
    function Execute(Modul: IXMLNode; Res: TDialogResult): Boolean;
  public
    property Dev: IDevice read GetDevice;
    property S_TableModulUpdate: string read FS_TableModulUpdate write FS_TableModulUpdate;
  end;

  resourcestring
   CARSTR1='Чтение';
   CARSTR2='Пустая память';
   CARSTR3='Конец';
   CARSTR4='Прервано';
   CARSTR5='Ошибка';
   CARSTR6='Пакет.Ош.';
   RSE_notImp='Устройство %s неподдерживает импорт из файла';
   RSE_RAMLower='Размер физической памяти %1.2f GB меньше выбранного %1.2f GB ' +#$D#$A +
    'Установлен соответствующий физической памяти!';
   RSM_fizMoReal='Физический объем диска больше указанного в метаданных, выбрать его ?';
   RSE_SelectSpeed='Не выбран диск или скорость UART';
   RSE_MetaRAMnot='Метаданные RAM %s не найдены';
   RSE_ModuleRunning='Модуль %s не выключен !!! Находится в состоянии [%s].';
   RSE_ReadRAM='Чтение памяти';
   RSE_DevNotFound='Устройство %s не найдено';
   RSE_DevNoRAMt='Устройство %s без памяти';
   RSE_NoMetaRAM='Метаданные RAM %s не найдены';
   RSE_RAMReaded='Память уже считана предыдущие данные будут удалены!!!';

implementation

{$R *.dfm}

uses AbstractPlugin, tools, ExportMetaData;

type
 ESpeed = (S125K = $80, S500K = $40, S1M = $20,  S1_5M = $10, S2M = $08, S2_25M = $04, S3M = $02, S6M = $01,
            S8M = $0800, S12M = $0400,
           SSD_ENA = $4000, USB = $8000);
const
  CONST_SPEED: array[0..9] of ESpeed = (S125K, S500K, S1M, S1_5M, S2M, S2_25M, S3M, S6M, S8M, S12M);
  TURBO_CMD: array[0..High(CONST_SPEED)] of Byte = (0,1,2,3, 4,5, 6,7,8,9);
  TXT_SPEDE: array[0..High(CONST_SPEED)] of string = ('125K','0.5M','1M','1.5M', '2M', '2.25M','3M', '6M', '8M', '12M');

 const
  CARSTR: array[EnumCopyAsyncRun] of string =(CARSTR1, CARSTR2, CARSTR3, CARSTR4, CARSTR5, CARSTR6);

function TFormDlgRam.Execute(Modul: IXMLNode; Res: TDialogResult): Boolean;
  procedure EnableSerial(ena: Boolean);
  begin
    rg.Enabled := ena;
    lbFile.Enabled := ena;
    od.Enabled := ena;
    lbLen.Enabled := ena;
    edLen.Enabled := ena;
  end;
  procedure EnableSSD(ena: Boolean);
  begin
    lbSD.Enabled := ena;
    cbSD.Enabled := ena;
  end;
   const
    MAX_RAM = $420000;
 var
  i: Integer;
  ram: IXMLNode;
begin
  Fgrade := 1;
  Result := True;
  TBindHelper.RemoveExpressions(Self);
  FModul := Modul;
  ram := FModul.ChildNodes.FindNode(T_RAM);
  if not Assigned(Ram) then raise EFrmDlgRam.CreateFmt(RSE_MetaRAMnot, [Fmodul.NodeName]);

  if (XToVar(FModul).WRK.автомат.DEV.VALUE and $3F) < 4 then
    raise EFrmDlgRam.CreateFmt(RSE_ModuleRunning, [Fmodul.NodeName, XToVar(FModul).WRK.автомат.CLC.VALUE]);

  if not ram.HasAttribute(AT_RAMSIZE) then
   begin
      if ram.HasAttribute(AT_SSD) then
       begin
        IsSSD := true;
        Fgrade := 512;
        FRamSize := ram.Attributes[AT_SSD]*512;
       end
       else FRamSize := MAX_RAM//     else raise EReadRamException.Create(RS_NoRamSize)
   end
  else if ram.Attributes[AT_RAMSIZE] = 5 then FRamSize := MAX_RAM
  else FRamSize := Ram.Attributes[AT_RAMSIZE] * 1024 * 1024;

  FDelayStart := (GContainer as IProjectOptions).DelayStart;
  FkadrSize := ram.Attributes[AT_SIZE];

  RangeSelect.Init(FkadrSize, FRamSize, FDelayStart);

   // BIT15:USB  BIT14:SSD BIT7:125Kbt BIT6:500Kbt  5-1M 4-2M
  if FModul.HasAttribute(AT_SPEED) then
   begin
    rg.Items.Clear;
    for I := 0 to High(CONST_SPEED) do
     if (CONST_SPEED[i] and FModul.Attributes[AT_SPEED]) <> 0  then
       rg.Items.AddObject(TXT_SPEDE[i], TObject(TURBO_CMD[i]));
    EnableSSD((SSD_ENA and FModul.Attributes[AT_SPEED]) <> 0);
    EnableSerial(rg.Items.Count > 0);
   end;

  if (GContainer as IProjectDataFile).DataFileExists(ram) and not lbSD.Enabled and ram.HasAttribute(AT_TO_KADR) then
   begin
     FAppendEnable := True;
     RangeSelect.Range.SelStart := ram.Attributes[AT_TO_KADR];
     btContinue.Enabled := True;
   end;

  FRes := Res;
  FS_TableModulUpdate := 'Ram';
  Caption := '[' + Modul.nodeName +'] '+RSE_ReadRAM;
  if IsSSD then
   begin
    Caption := Caption + ' SSD';
    lblssd.Caption := 'в байтах'
   end;

  Bind(GlobalCore as IManager, 'C_TableUpdate', ['S_TableModulUpdate']);
  IShow;
end;


procedure TFormDlgRam.UpdateControlsSD(SDEna: Boolean);
begin
  RangeSelect.RunEnable(SDEna);
//  edBegin.Enabled := SDEna;
//  edCnt.Enabled := SDEna;
//  lbEnd.Enabled := SDEna;
//  lbBegin.Enabled := SDEna;
  lbFile.Enabled := not SDEna;
  od.Enabled := not SDEna;
  lbLen.Enabled := not SDEna;
  edLen.Enabled := not SDEna;
//  cbClcCreate.Checked := not SDEna;
  cbClcCreate.Enabled := not SDEna;
end;


procedure TFormDlgRam.UpdateStat(car: EnumCopyAsyncRun; Stat: TStatistic);
begin
  if not Assigned(sb) then Exit;

  sb.Panels[4].Text := CARSTR[car];
  if car = carErrorSector then
   begin
    sb.Panels[4].Text := sb.Panels[4].Text + Stat.NRead.ToString;
   end
  else if car = carError then Exit;
  sb.Panels[0].Text := Stat.ProcRun.ToString(ffFixed, 7, 1)+'%';
  if Stat.Speed > 0.99 then
    sb.Panels[1].Text := Stat.Speed.ToString(ffFixed, 7, 0)+'MB/s'
  else
    sb.Panels[1].Text := (Stat.Speed*1024).ToString(ffFixed, 7, 0)+'KB/s';
  sb.Panels[2].Text := TimeToStr(Stat.TimeFromBegin);
  sb.Panels[3].Text := TimeToStr(Stat.TimeToEnd);
  Progress.Position := Round(Stat.ProcRun);
end;

function TFormDlgRam.GetDevice: IDevice;
begin
  if not Assigned(FDev) then Fdev := (GlobalCore as IDeviceEnum).Get(FModul.ParentNode.NodeName);
  Result := Fdev;
end;

function TFormDlgRam.GetInfo: PTypeInfo;
begin
  Result :=TypeInfo(Dialog_RamRead);
end;

procedure TFormDlgRam.Loaded;
// var
//  n: TMenuItem;
begin
  inherited;
  AddToNCMenu('-');
  AddToNCMenu('Import...', NImportClick);
  AddToNCMenu('Export...', NExportClick);
end;

procedure TFormDlgRam.NExportClick(Sender: TObject);
 var
  d: IDevice;
//  e: IExport;
begin
  d := GetDevice;
{  if Supports(d, IExport, e) then
  with TOpenDialog.Create(nil) do
   try
    InitialDir := ExtractFilePath(ParamStr(0));
    Options := Options + [ofOverwritePrompt, ofPathMustExist];
    Filter := e.Filters;
    if Execute(Handle) then e.Execute(FileName, FilterIndex, procedure (ProcToEnd: Double)
    begin
      sb.Panels[0].Text := Format('Экспорт сталось %1.3f',[ProcToEnd]);
    end);
   finally
    Free;
   end;}
end;

procedure TFormDlgRam.NImportClick(Sender: TObject);
begin
  inerExecute(True);
end;

procedure TFormDlgRam.rgClick(Sender: TObject);
begin
  UpdateControlsSD(false);
  RangeSelect.RunEnable(True);
end;


procedure TFormDlgRam.UpdateControls(FlagEna: Boolean);
begin
  btStart.Enabled := FlagEna;
  btContinue.Enabled := FlagEna and FAppendEnable;
  btExit.Enabled := FlagEna;
  NCanClose := FlagEna;
  cbClcCreate.Enabled := FlagEna;
  cbToFF.Enabled := FlagEna;
  RangeSelect.Enabled := FlagEna;
end;

procedure TFormDlgRam.btContinueClick(Sender: TObject);
begin
  inerRead(True);
end;

procedure TFormDlgRam.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_RamRead>;
end;

procedure TFormDlgRam.inerExecute(IsImport: boolean);
 var
  ri: IRamImport;
  flName: string;
  flIndex, Addr: Integer;
  ram: IXMLNode;

begin
   Progress.Position := 0;
   flIndex := 0;
   if not Assigned(Dev) then raise EFrmDlgRam.CreateFmt(RSE_DevNotFound, [Fmodul.NodeName]);
   if not Supports(Dev, IReadRamDevice) then raise EFrmDlgRam.CreateFmt(RSE_DevNoRAMt, [Fmodul.NodeName]);
   addr := FModul.Attributes[AT_ADDR];
   if IsImport then
    begin
     if not Supports(FDev as IReadRamDevice, IRamImport, ri) then raise EFrmDlgRam.CreateFmt(RSE_notImp, [FModul]);
     with TOpenDialog.Create(nil) do
      try
       InitialDir := ExtractFilePath(ParamStr(0));
       Options := Options + [ofPathMustExist, ofFileMustExist];
       Filter := ri.Filters;
       if not Execute(Handle) then Exit
       else
        begin
         flName := FileName;
         flIndex := FilterIndex;
        end;
      finally
       Free;
      end;
    end;
   ram := FModul.ChildNodes.FindNode(T_RAM);
   CheckRAMFile(ram);
   if FAppend then RangeSelect.Range.SelStart := ram.Attributes[AT_TO_KADR];

   
   //////////////////
  // ram.Attributes['test_before_construct']:= 'test_before_construct';
  // /.ConstructFileName(ram);
  // ram.Attributes['test_before_resync']:= 'test_before_resync';
  // ram.OwnerDocument.Resync;
 //  ram.Attributes['test_after_resync']:= 'test_after_resync';
 //  exit;
   /////////////////
   UpdateControls(False);
   try
    if not IsImport then
     with (FDev as IReadRamDevice) do
      begin
       CreateClcFile := cbClcCreate.Checked;
       var cnt := StrToInt('$'+edLen.Text);
       if cnt <$100 then
        begin
         cnt := $100;
         edLen.Text := '100';
        end;
        if IsSSD then
         begin
           if cnt < $200 then
           begin
            cnt := $200;
            edLen.Text := '200';
           end;
           lblssd.Caption := '=>sectors 0x' + (cnt div $200).ToHexString(2);
         end;

       var turbo := Integer(rg.Items.Objects[rg.ItemIndex]);
       Execute(od.FileName, RangeSelect.kadr.first, RangeSelect.kadr.last, cbToFF.Checked, turbo, addr, ReadRamEvent, addr, cnt, Fgrade)
      end
    else ri.Import(flName, flIndex, RangeSelect.kadr.first, RangeSelect.kadr.last, cbToFF.Checked, addr, ReadRamEvent, addr);
   except
    UpdateControls(True);
    raise;
   end;
end;

procedure TFormDlgRam.CheckRAMFile(ram: IXMLNode);
begin
  if not Assigned(Ram) then raise EFrmDlgRam.CreateFmt(RSE_NoMetaRAM, [Fmodul.NodeName]);
  if not FAppend then
   begin
    if (GContainer as IProjectDataFile).DataFileExists(ram) then
    if (MessageDlg(RSE_RAMReaded, mtWarning, [mbYes, mbCancel], 0) = mrCancel) then
      raise EAbort.Create('mrCancel')
    else
     begin
      (GContainer as IProjectDataFile).DataSectionDelete(ram);
      TBindings.Notify(Self, 'S_TableModulUpdate');
     end;
  //   RemoveXMLAttr(ram, AT_START_TIME);
  //   RemoveXMLAttr(ram, AT_DELAY_TIME);
  //   RemoveXMLAttr(ram, AT_KOEF_TIME);
  //   RemoveXMLAttr(ram, AT_FILE_NAME);
    RemoveXMLAttr(ram, AT_FROM_TIME);
    RemoveXMLAttr(ram, AT_TO_TIME);
    RemoveXMLAttr(ram, AT_FROM_ADR);
    RemoveXMLAttr(ram, AT_TO_ADR);
    RemoveXMLAttr(ram,AT_END_REASON);
    RemoveXMLAttr(ram, AT_FROM_KADR);
    RemoveXMLAttr(ram, AT_TO_KADR);
  end;
end;


procedure TFormDlgRam.inerRead(Append: Boolean);
begin
  Fappend := Append;
  (GlobalCore as IMainScreen).Changed;
  if rg.ItemIndex <> -1 then inerExecute(False)
  else inerReadSSD();
end;

procedure TFormDlgRam.inerReadSSD;
 const
  MB: int64 = 1024*1024;
  GB: int64 = 1024*1024*1024;
 var
  i: Integer;
  ram: IXMLNode;
  lastAdrSave: int64;
begin
  if cbSD.ItemIndex < 0  then raise EFrmDlgRam.Create(RSE_SelectSpeed);
  ram := FModul.ChildNodes.FindNode(T_RAM);
  CheckRAMFile(ram);
  if Assigned(FSDStream) then FreeAndNil(FSDStream);
  FSDStream := TSDStream.Create(FDevs[cbSD.ItemIndex], GENERIC_READ);
//  FTerminate := False;
  FTerminated := False;
  Progress.Position := 0;

  FRecSize := Ram.Attributes[AT_SIZE];
//  FFrom := (StrToInt64(edBegin.Text)*MB div FRecSize) * FRecSize;
//  FCnt :=  (StrToInt64(edCnt.Text)*MB div FRecSize) * FRecSize;
  FFrom := RangeSelect.adr.first;
  FCnt := RangeSelect.adr.cnt;

  ram.Attributes[AT_FROM_ADR] := Format('0x%x',[FFrom]);
  ram.Attributes[AT_FROM_KADR] := FFrom div FRecSize;
  ram.Attributes[AT_FROM_TIME] := CTime.AsString(2.097152/24/3600 * (FFrom div FRecSize));

  for I := 0 to sb.Panels.Count-1 do sb.Panels[i].Text := '';

  if (RangeSelect.adr.last > FSDStream.Size) then
   begin
    lastAdrSave := RangeSelect.adr.last;
    RangeSelect.Range.SelEnd := FSDStream.Size div FRecSize;

    raise ENeedDialogException.CreateFmt(RSE_RAMLower, [FSDStream.Size / GB, lastAdrSave / GB]);
   end;


  UpdateControls(False);
  try

   var fn := GFileDataFactory.ConstructFileName(ram);
   ExportMetaDataToTxt(TPath.ChangeExtension(fn,'txt'), ram, (GContainer as IProjectOptions).DelayStart);
   FSDStream.AsyncCopyTo(fn, FFrom, FCnt, cbToFF.Checked, ReadSSDEvent);
  except
   UpdateControls(True);
   raise;
  end;
end;

procedure TFormDlgRam.ReadSSDEvent(car: EnumCopyAsyncRun; Stat: TStatistic);
 var
  ram: IXMLNode;
begin
  ram := FModul.ChildNodes.FindNode(T_RAM);
  ram.Attributes[AT_TO_ADR] := Format('0x%x',[FFrom + Stat.NRead]);
  ram.Attributes[AT_TO_KADR] := (FFrom + Stat.NRead) div FRecSize;
  ram.Attributes[AT_TO_TIME] := CTime.AsString(2.097152/24/3600 * Double(ram.Attributes[AT_TO_KADR]));

  if not FTerminated and (TTask.CurrentTask.Status <> TTaskStatus.Canceled) then
   TThread.Queue(TThread.CurrentThread, procedure
   begin
     if FTerminated then Exit;
     if car <> carOk then
      begin
       ram.Attributes[AT_END_REASON] := CARSTR[car];
       FTerminated := True;
       UpdateControls(True);
      end;
     UpdateStat(car, Stat);
   end);
end;

procedure TFormDlgRam.ReadRamEvent(EnumRR: EnumCopyAsyncRun; DevAdr: Integer; Stat: TStatistic);
 ////var
 // r:Ixmlnode;
begin
  UpdateStat(EnumRR, Stat);
  if EnumRR in COPY_STOP_EVENT then
   begin
    (GContainer as IALLMetaDataFactory).Get.Save;
    FRes(Self, mrOk);
    UpdateControls(True);
    TBindings.Notify(Self, 'S_TableModulUpdate');
   end;
end;

procedure TFormDlgRam.odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
  od.FileName := '';
end;

procedure TFormDlgRam.btStartClick(Sender: TObject);
begin
  inerRead(False);
//  (GlobalCore as IMainScreen).Changed;
//  if rg.ItemIndex <> -1 then inerExecute(False)
//  else inerReadSSD();
end;

procedure TFormDlgRam.Onterminate(Res: Boolean);
   var
    t: ITurbo;
begin
    if Supports(FDev, ITurbo, t) then
     t.Turbo($F,0);
end;

procedure TFormDlgRam.btTerminateClick(Sender: TObject);
begin
  TAsyncCopy.Terminate();
  if not Assigned(FDev) then Exit;
  try
   (FDev as IReadRamDevice).Terminate(Onterminate)
   except
   UpdateControls(True);
  end;
end;

procedure TFormDlgRam.cbSDChange(Sender: TObject);
 var
  ram: IXMLNode;
begin
  ram := FModul.ChildNodes.FindNode(T_RAM);
  rg.ItemIndex := -1;
  UpdateControlsSD(True);
  if (cbSD.ItemIndex >= 0) and (ram.Attributes[AT_RAMSIZE] < FDevs[cbSD.ItemIndex].DiskSize div 1024 div 1024)
  and (MessageDlg(RSM_fizMoReal, mtWarning, [mbYes, mbNo], 0) = mrYes) then
   begin
    ram.Attributes[AT_RAMSIZE] := FDevs[cbSD.ItemIndex].DiskSize div 1024 div 1024;
    RangeSelect.Init(FkadrSize, FDevs[cbSD.ItemIndex].DiskSize, FDelayStart);
   end;
end;

procedure TFormDlgRam.cbSDDropDown(Sender: TObject);
 var
  d: TLogicalDevice;
begin
  cbSD.Items.Clear;
  FDevs := TSDStream.EnumLogicalDrives;
  for d in FDevs do cbSD.Items.Add(d.Letter);
end;

initialization
  RegisterDialog.Add<TFormDlgRam, Dialog_RamRead>;
finalization
  RegisterDialog.Remove<TFormDlgRam>;
end.
