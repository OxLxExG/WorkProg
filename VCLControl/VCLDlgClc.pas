unit VCLDlgClc;

interface

uses debug_except, ExtendIntf, DockIForm, PluginAPI, Container, RootImpl, DeviceIntf, DataSetIntf, XMLDataSet, RootIntf,
  Xml.XMLIntf, System.TypInfo, System.Threading,  System.IOUtils,  Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls;

type
  EFrmDlgClc = class(EBaseException);
  TFormDlgClc = class(TDialogIForm, IDialog, IDialog<IXMLNode, TDialogResult>)
    Progress: TProgressBar;
    btExit: TButton;
    btTerminate: TButton;
    btStart: TButton;
    sb: TStatusBar;
    procedure btTerminateClick(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
    FModul: IXMLNode;
    FRes: TDialogResult;
    FIDataSet: IDataSet;

//    FTerminate: Boolean;
    FTerminated: Boolean;
    FBeginTime: TDateTime;

    function Run: ITask;
    procedure RunEvent(car: EnumCopyAsyncRun; Stat: TStatistic);
    procedure UpdateControls(FlagEna: Boolean);
    function GetDataSet: TXMLDataSet;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(Modul: IXMLNode; Res: TDialogResult): Boolean;
    property DataSet: TXMLDataSet read GetDataSet;
  public
    { Public declarations }
  end;

  resourcestring
  RS_Metr_Rewrite='Перезапись метрологии';
  CARSTR1='Чтение';
  CARSTR2= 'Пустая память';
   CARSTR3= 'Конец';
   CARSTR4=  'Прервано';
   CARSTR5=   'Ошибка';
   CARSTR6=    'Пакет.Ош.';

implementation

{$R *.dfm}

function FindStat(NRead, Count: int64; tBegin: TDateTime): TStatistic;
 var
  Spd: double;
begin
  Result.NRead := NRead;
  Result.TimeFromBegin := Now - tBegin;
  Result.ProcRun := Result.NRead/Count*100;
  // speed
  if Result.TimeFromBegin > 0 then Spd := Result.NRead / Result.TimeFromBegin else Spd := 0;
  Result.Speed := Spd/1024/1024 /24/3600; // MB/sec
  if Spd > 0 then Result.TimeToEnd := (Count - Result.NRead)/spd
  else Result.TimeToEnd := 0;
end;


{ TFormDlgClc }

function TFormDlgClc.Execute(Modul: IXMLNode; Res: TDialogResult): Boolean;
begin
  Result := True;
//  TBindHelper.RemoveExpressions(Self);
  FModul := Modul;
  FRes := Res;
  Caption := '[' + Modul.nodeName +'] '+RS_Metr_Rewrite;
//  Bind(GlobalCore as IManager, 'C_TableUpdate', ['S_TableModulUpdate']);
  IShow;
end;

function TFormDlgClc.GetDataSet: TXMLDataSet;
begin
  if not Assigned(FIDataSet) then
   begin
    TXMLDataSet.Get(FModul, FIDataSet, False);
    TXMLDataSet(FIDataSet.DataSet).XMLSection;
   end;
  Result := TXMLDataSet(FIDataSet.DataSet)
end;

function TFormDlgClc.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_ClcWrite);
end;

function TFormDlgClc.Run: ITask;
begin
  // поток
  Result := TTask.Run(procedure
   const
    BUFLEN = $8FFF;
   var
    CapturedException : Exception;
    cnt, n: Int64;
    nread, npack, i, nk: Integer;
    buf: TArray<Byte>;
    PRead, pout: PByte;
  begin
      try
       cnt := (DataSet.FileData.Size div DataSet.RecordLength) * DataSet.RecordLength;
       n := 0;
       npack := Min(cnt div DataSet.RecordLength, BUFLEN div DataSet.CalcDataLen);
       SetLength(buf, npack* DataSet.CalcDataLen);
       DataSet.FileData.Position := 0;
       FBeginTime := Now;
       repeat
        nread := DataSet.FileData.Read(npack*DataSet.RecordLength, Pointer(PRead));
        nk := nread div DataSet.RecordLength;
        pout := @buf[0];
        for i := 0 to nk-1 do
         begin
          if FTerminated then break;
          DataSet.CalcData(PRead, pout);
          inc(PRead, DataSet.RecordLength);
          inc(pout, DataSet.CalcDataLen);
         end;
        DataSet.ClcData.Write(DataSet.CalcDataLen*nk, @buf[0], -1, False);
        inc(n, nread);
        RunEvent(carOk, FindStat(n, cnt, FBeginTime));
       until FTerminated or (cnt <= n) or (nread = 0);
       if FTerminated then RunEvent(carTerminate, FindStat(n, cnt, FBeginTime))
       else RunEvent(carEnd, FindStat(n, cnt, FBeginTime));
      except
       CapturedException := Tobject(AcquireExceptionObject) as Exception;
       RunEvent(carError, FindStat(n, cnt, FBeginTime));
       TThread.Queue(TThread.CurrentThread, procedure
        begin
          raise CapturedException;
        end);
      end;
  end);

end;

procedure TFormDlgClc.RunEvent(car: EnumCopyAsyncRun; Stat: TStatistic);
 const
  CARSTR: array[EnumCopyAsyncRun] of string =(CARSTR1, CARSTR2, CARSTR2,CARSTR4,CARSTR5,CARSTR6);
begin
   TThread.Queue(TThread.CurrentThread, procedure
   begin
     if car <> carOk then
      begin
       UpdateControls(True);
      end;
    sb.Panels[4].Text := CARSTR[car];
    if car = carError then Exit;
    sb.Panels[0].Text := Stat.ProcRun.ToString(ffFixed, 7, 1)+'%';
    if Stat.Speed > 0.1 then
      sb.Panels[1].Text := Stat.Speed.ToString(ffFixed, 7, 0)+'Mb/s'
    else
      sb.Panels[1].Text := (Stat.Speed*1024).ToString(ffFixed, 7, 0)+'Kb/s';
    sb.Panels[2].Text := TimeToStr(Stat.TimeFromBegin);
    sb.Panels[3].Text := TimeToStr(Stat.TimeToEnd);
    Progress.Position := Round(Stat.ProcRun);
   end);
end;

procedure TFormDlgClc.btExitClick(Sender: TObject);
begin
  if NCanClose then RegisterDialog.UnInitialize<Dialog_ClcWrite>;
end;

procedure TFormDlgClc.btStartClick(Sender: TObject);
begin
  EBaseException.NeedShowDialog();
  if TFile.Exists(DataSet.CLCFileName) then
   begin
    FIDataSet := nil;
    TFile.Delete(DataSet.CLCFileName);
   end;
  UpdateControls(False);
  FTerminated := False;
  Run;
end;

procedure TFormDlgClc.btTerminateClick(Sender: TObject);
begin
  FTerminated := True;
end;

procedure TFormDlgClc.UpdateControls(FlagEna: Boolean);
begin
  btStart.Enabled := FlagEna;
  btExit.Enabled := FlagEna;
  NCanClose := FlagEna;
end;

initialization
  RegisterDialog.Add<TFormDlgClc, Dialog_ClcWrite>;
finalization
  RegisterDialog.Remove<TFormDlgClc>;
end.
