unit VCLDlgExportCaliper;

interface
{$INCLUDE global.inc}

uses DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, RootIntf, debug_except, Actns, Container, tools,
  Xml.XMLIntf, DataSetIntf, XMLDataSet,  System.TypInfo, System.Math, System.IOUtils, DB,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Mask, JvExMask, JvToolEdit, VCLFrameRangeSelect;

const
  APPB_END_IF:  PAnsiChar = '#1#34  ';
  APPB_END_AK1: PAnsiChar = '#1#35  ';
  APPB_END_AK1_800: PAnsiChar = '#1#67  ';

{$IFDEF ENG_VERSION}
 const
  RS_caliper = '-Caliper...';
  RS_Export = 'Export';
  RS_file ='0:File.Export|1:3';
{$ELSE}
 const
  RS_caliper = '-Профилемер...';
  RS_Export = 'Экспорт';
  RS_file ='0:Файл.Экспорт|1:3';
{$ENDIF}

type
    TRecMap = record
     ix: Integer;
     name: string;
     k: Integer;
    end;

  TFormDlgExportCaliper = class(TDialogIForm, IDialog, IDialog<TDialogResult>)
    od: TJvFilenameEdit;
    btStart: TButton;
    btTerminate: TButton;
    btExit: TButton;
    Progress: TProgressBar;
    Label3: TLabel;
    edFKD: TEdit;
    RangeSelect: TFrameRangeSelect;
    sb: TStatusBar;
    cbFKD: TComboBox;
    Label1: TLabel;
    cbAuto: TCheckBox;
    procedure btExportClick(Sender: TObject);
    procedure btTerminateClick(Sender: TObject);
    procedure cbFKDChange(Sender: TObject);
    procedure cbAutoClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
    FIStat: IStatistic;
    FkadrFirst, FkadrLast: Integer;
    FIDataSet: IDataSet;
    FXDataSet: TXMLDataSet;
    IfFields: TArray<TField>;
    Fterminate: Boolean;
    procedure UpdateControls(FlagEna: Boolean);
  public
    function GetInfo: PTypeInfo; override;
    function Execute(Res: TDialogResult): Boolean;
   [StaticAction(RS_caliper, RS_Export, 128, RS_file)]
   class procedure DoExportCalip(Sender: IAction);
  end;

  resourcestring
   RS_EmptyFileName='пустое имя файла';
   RS_run='работа';
   RS_terminated='прервано';
   RS_End='конец';
   RS_NoModule='Нет считанных данных или модуля профилемера!!!';
   RS_No_bd_Calip='Нет базы данных профилемера!!!';

implementation

{$R *.dfm}

    const
     SUB_EXP = 'Профилемер';

     FKDN = '%s.Caliper.fkd.d%d.DEV';

     FI_FORMAT:array [0..6] of TRecMap=(
     (ix: 0; name: '.время.DEV'; k: 1),
     (ix: 1; name: '.Caliper.accel.X.CLC'; k: 1),
     (ix: 2; name: '.Caliper.accel.Y.CLC'; k: 1),
     (ix: 3; name: '.Caliper.accel.Z.CLC'; k: 1),
     (ix: 4; name: '.Caliper.T.DEV'; k: 100),
     (ix: 5; name: '.Caliper.потребление.DEV'; k: 1),
     (ix: 6; name: '.Caliper.ГК.гк.DEV'; k: 1)
     );


{ TFormDlgExportCaliper }

procedure TFormDlgExportCaliper.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize(EXPORT_DIALOG_CATEGORY, SUB_EXP);
end;

procedure TFormDlgExportCaliper.btExportClick(Sender: TObject);
//  function getCal: IXMLNode;
//   var
//    n: IXMLNode;
//  begin
//   Result := nil;
//    for n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
//     if n.Attributes[AT_ADDR] = 7 then
//      begin
//       Result := n.ChildNodes.FindNode(T_RAM);
//       if Assigned(Result) and Result.HasAttribute(AT_FILE_NAME) then Exit(Result);
//      end;
//   raise EBaseException.Create('Нет данных профилемера!!!');
//  end;
begin
//  TXMLDataSet.Get(getCal, FIDataSet);
//  if not Assigned(FIDataSet) then raise EBaseException.Create('Нет базы данных профилемера!!!');
  Fterminate := False;
  UpdateControls(False);
  TThread.CreateAnonymousThread(procedure
   var
    f,ak: TFileStream;
    akFileName, ifFileName: string;
    frm, i: Integer;
    newPos: Integer;
    akLen: Integer;
    akFields: TArray<TField>;
    ifarr: TArray<Integer>;
    cs0: array[0..1] of word;
    b, bdef: TArray<Byte>;
    umin, umax: Integer;
   // fldID: TField;
     procedure UpdateSb4(const s: string);
     begin
       TThread.Synchronize(nil, procedure
        begin
          sb.Panels[4].Text := s;
        end);
     end;
  begin
     try
      try
        if od.FileName <> '' then
         begin
          akFileName := TPath.ChangeExtension(od.FileName, 'ak1');
          ifFileName := TPath.ChangeExtension(od.FileName, 'if');
          if TFile.Exists(ifFileName) then TFile.Delete(ifFileName);
          if TFile.Exists(akFileName) then TFile.Delete(akFileName);
          f := TFileStream.Create(ifFileName, fmCreate);
          ak := TFileStream.Create(akFileName, fmCreate);
         end
        else
         begin
          UpdateSb4(RS_EmptyFileName);
          Exit;
         end;
        FXDataSet.DisableControls;
//        fldID := FXDataSet.FieldByName('ID');
        Setlength(akFields, 9);
        for I := 0 to 8 do akFields[i] := FXDataSet.FieldByName(Format(FKDN,[FXDataSet.XMLSection.ParentNode.NodeName, i]));
        ///
        if cbAuto.Checked then
         begin
          if Abs(akFields[0].Size - 2*800) < 10 then akLen := 800*2
          else akLen := 682*2;
          edFKD.Text := IntToStr(akLen div 2);
         end
        ///
        else akLen := StrToInt(edFKD.Text)*2;
        Setlength(bdef, akLen);
        Setlength(ifarr, Length(FI_FORMAT));
        umin := RangeSelect.kadr.first - FkadrFirst;
        umax := RangeSelect.kadr.last - FkadrFirst;
        FXDataSet.RecNo := umin;
        FIStat := TStatisticCreate.Create((umax-umin)*Length(ifarr)*Sizeof(Integer));
        UpdateSb4(RS_run);
        for frm := umin to umax do
         begin
          for I := 0 to High(ifarr) do
           if Assigned(IfFields[i]) and not IfFields[i].isNull then
            if IfFields[i] is TNumericField then
             if IfFields[i] is TFloatField then
              begin
               ifarr[FI_FORMAT[i].ix] := Round(IfFields[i].AsFloat * FI_FORMAT[i].k);
              end
             else ifarr[FI_FORMAT[i].ix] := IfFields[i].AsInteger * FI_FORMAT[i].k
            else ifarr[FI_FORMAT[i].ix] := 0
           else ifarr[FI_FORMAT[i].ix] := 0;

///         ID <> время.DEV !!! если считывали память не сначала
//          if ifarr[0] = fldID.AsInteger then
//           begin
            f.Write(ifarr[0], Length(ifarr)*Sizeof(Integer));
            FIStat.UpdateAdd(Length(ifarr)*Sizeof(Integer));

            cs0[0] := ifarr[0] mod 10;
            cs0[1] := ifarr[0] div 10;
            ak.Write(cs0, Length(cs0)*Sizeof(Word));
            for I := 0 to 8 do
             if Assigned(akFields[i]) and not akFields[i].isNull then
              begin
               FXDataSet.GetFieldData(akFields[i], b);
               if akFields[i].Size < akLen then
                   move(PPointer(@b[0])^^, bdef[0], akFields[i].Size)
               else
                   move(PPointer(@b[0])^^, bdef[0], akLen);
               ak.Write(bdef[0], akLen);
               FillChar(bdef[0], akLen, 0);
              end
             else ak.Write(bdef[0], akLen);
//           end
//          else raise Exception.CreateFmt('ID %d <> Кадру  %d',[ifarr[0], fldID.AsInteger]);

          FXDataSet.Next;

          if Fterminate then
            begin
             UpdateSb4(RS_terminated);
             Exit;
            end;

          if (umax - umin) > 0 then newPos := Round((frm - umin)/(umax -umin)*100)
          else newPos := 0;
          if (Progress.Position <> newPos) then TThread.Synchronize(nil, procedure
          begin
            Progress.Position := newPos;
            TStatisticCreate.UpdateStandardStatusBar(sb, FIStat.Statistic);
          end);
         end;
        f.Write(APPB_END_IF[0], 7);
        if akLen = 800*2 then
           ak.Write(APPB_END_AK1_800[0], 7)
         else
           ak.Write(APPB_END_AK1[0], 7);
        UpdateSb4(RS_End);
      finally
       UpdateControls(True);
       FXDataSet.EnableControls;
       f.Free;
       ak.Free;
      end;
     except
      on E: Exception do TDebug.DoException(E);
     end;
  end).Start();
end;

procedure TFormDlgExportCaliper.UpdateControls(FlagEna: Boolean);
begin
  RangeSelect.Enabled := FlagEna;
  btStart.Enabled := FlagEna;
  btExit.Enabled := FlagEna;
  NCanClose := FlagEna;
end;

procedure TFormDlgExportCaliper.btTerminateClick(Sender: TObject);
begin
  Fterminate := True;
end;

procedure TFormDlgExportCaliper.cbAutoClick(Sender: TObject);
 var
  akField: TField;
  akLen : Integer;
begin
  cbFKD.Enabled := not cbAuto.Checked;
  if cbAuto.Checked then
  begin
    akField := FXDataSet.FieldByName(Format(FKDN,[FXDataSet.XMLSection.ParentNode.NodeName, 0]));
    if Abs(akField.Size - 2*800) < 10 then akLen := 800*2
    else akLen := 682*2;
    edFKD.Text := IntToStr(akLen div 2);
  end;

end;

procedure TFormDlgExportCaliper.cbFKDChange(Sender: TObject);
begin
  if cbFKD.ItemIndex in [2,3] then edFKD.Text := '800'
  else edFKD.Text := '682'
end;

class procedure TFormDlgExportCaliper.DoExportCalip(Sender: IAction);
var
  d: Idialog;
begin
  if RegisterDialog.TryGet(EXPORT_DIALOG_CATEGORY, SUB_EXP, d) then (d as IDialog<TDialogResult>).Execute(nil);
end;

function TFormDlgExportCaliper.Execute(Res: TDialogResult): Boolean;
  function getCal: IXMLNode;
   var
    n: IXMLNode;
  begin
   Result := nil;
    for n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
     if n.Attributes[AT_ADDR] = 7 then
      begin
       Result := n.ChildNodes.FindNode(T_RAM);
       if Assigned(Result) and Result.HasAttribute(AT_FILE_NAME) then Exit(Result);
      end;
   raise ENeedDialogException.Create(RS_NoModule);
  end;
 var
  i: Integer;
begin
  TXMLDataSet.Get(getCal, FIDataSet);
  if not Assigned(FIDataSet) then raise ENeedDialogException.Create(RS_No_bd_Calip);
  FXDataSet := FIDataSet.DataSet as TXMLDataSet;
  FXDataSet.Open;
  FXDataSet.DisableControls;
  try
   Setlength(IfFields, Length(FI_FORMAT));
   for I := 0 to High(IfFields) do IfFields[i] := FXDataSet.FieldByName(FXDataSet.XMLSection.ParentNode.NodeName+FI_FORMAT[i].name);
   FXDataSet.First;
   FkadrFirst := IfFields[0].AsInteger;
   FXDataSet.Last;
   FkadrLast := IfFields[0].AsInteger;
   if (FkadrFirst = 1)and (FkadrLast =0) then
   while (FkadrLast = 0) do
    begin
      FXDataSet.Prior;
      FkadrLast := IfFields[0].AsInteger;
    end;
   RangeSelect.Init(FXDataSet.RecordLength, FkadrFirst, FkadrLast, (GContainer as IProjectOptions).DelayStart);
   RangeSelect.Range.SelEnd := RangeSelect.Range.Max;
  finally
   FXDataSet.EnableControls;
  end;
  //RangeSelect.Init(d.RecordLength);
  cbAutoClick(nil);
  IShow;
end;

function TFormDlgExportCaliper.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_Export);
end;

initialization
  RegisterDialog.Add<TFormDlgExportCaliper, Dialog_Export>(EXPORT_DIALOG_CATEGORY, SUB_EXP);
finalization
  RegisterDialog.Remove<TFormDlgExportCaliper>;
end.
