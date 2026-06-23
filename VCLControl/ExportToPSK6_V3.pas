unit ExportToPSK6_V3;

interface

{$INCLUDE global.inc}

uses DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, RootIntf, debug_except, Actns, Container, tools,
  Xml.XMLIntf, DataSetIntf, XMLDataSet,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Data.DB, System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Mask, JvExMask, JvToolEdit, VCLFrameRangeSelect;

{$IFDEF ENG_VERSION}
  const
   C_CaptMBKForm ='-MBK...';
   C_Memu_Export1='Export';
   C_Memu_Export2='0:File.Export|1:2';
{$ELSE}
  const
   C_CaptMBKForm ='-МБК...';
   C_Memu_Export1='Экспорт';
   C_Memu_Export2='0:Файл.Экспорт|1:2';
{$ENDIF}

const
  MBKPB_END_IF:PAnsiChar = '#1#14  ';
  DEVS_END_IF: array[3..6] of PAnsiChar = ('*Ink_%d','*GK_%d','*NNK_%d','*BK_%d');
type
    TFileFormatPSK6 = Record
      Dep: Integer;                    //Время
      Par: Array [0..61] of Integer;   //формат K-6
    end;
    TRecMap = record
     ix: Integer;
     name: string;
     k: Double;
    end;


  TFormExportToPSK6_V3 = class(TDockIForm)
    od: TJvFilenameEdit;
    btStart: TButton;
    btTerminate: TButton;
    btExit: TButton;
    Progress: TProgressBar;
    RangeSelect: TFrameRangeSelect;
    sb: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure btExitClick(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure btTerminateClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
   type
    TFldRec = record
     FieldName: string;
     k: Double;
     Index: Integer;
    end;
    TcheckRec = record
     //adr: Integer;
     Checked: Boolean;
     ModulName: string;
     Table: TXMLDataSet;
     IdName: string;
     FirstKadr, LastKadr: Integer;
     FirstKadrID, LastKadrID: Integer;
     Data: TArray<TFldRec>;
    end;
  protected
    function Priority: Integer; override;
  private
    FIStat: IStatistic;
    FbadData: Boolean;
    rams: TArray<IDataSet>;
    acr: TArray<TCheckRec>;
    Fterminate: Boolean;
    FSerials: AnsiString;
    procedure StRec(ix: IdataSet; const drm: array of TRecMap; var d: TcheckRec);
    procedure UpdateControls(FlagEna: Boolean);
    function GetProjectRams: TArray<IDataSet>;
//    function GetMaxID(const rams: TArray<IDataSet>): Integer;
    procedure Close;
//    procedure Next;
    procedure Open;
    procedure RecNo(Kadr: Integer);
  public
   [StaticAction(C_CaptMBKForm, C_Memu_Export1, 226, C_Memu_Export2)]
   class procedure DoExportPSK6(Sender: IAction);
  end;

  resourcestring
        RS_EmptyFileName='пустое имя файла';
        RS_Run='работа';
        RS_terminate='прервано';
        RS_end='конец';
        RS_Err='ошибка';
        RS_ErrDataStruct='Неверная структура данных';
        RS_MameIdFrame='Ммя: %s ID: %d КадрID: %d';
        RS_Mbk_None='Какие-либо данные для экспорта в МБК отсутствуют !!!';


implementation

{$R *.dfm}

uses System.Math;

//'electro.БК.B.I0.DEV'

const

//{8}   FS_Import.CLList.Add('Gx,мВ');
//{9}   FS_Import.CLList.Add('Gy,мВ');
//{10}  FS_Import.CLList.Add('Gz,мВ');
//{11}  FS_Import.CLList.Add('Hx,мВ');
//{12}  FS_Import.CLList.Add('Hy,мВ');
//{13}  FS_Import.CLList.Add('Hz,мВ');

{  RM_INCL: array[0..5]of TRecMap =(
    (ix:8;  name:'Inclin.accel.X.CLC'; k:10),
    (ix:9;  name:'Inclin.accel.Y.CLC'; k:10),
    (ix:10; name:'Inclin.accel.Z.CLC'; k:10),
    (ix:11; name:'Inclin.magnit.X.CLC'; k:10),
    (ix:12; name:'Inclin.magnit.Y.CLC'; k:10),
    (ix:13; name:'Inclin.magnit.Z.CLC'; k:10));//}


  RM_INCL: array[0..5]of TRecMap =(
    (ix:8;  name:'Inclin.accel.X.DEV'; k:10000),
    (ix:9;  name:'Inclin.accel.Y.DEV'; k:10000),
    (ix:10; name:'Inclin.accel.Z.DEV'; k:10000),
    (ix:11; name:'Inclin.magnit.X.DEV'; k:10000),
    (ix:12; name:'Inclin.magnit.Y.DEV'; k:10000),
    (ix:13; name:'Inclin.magnit.Z.DEV'; k:10000));//}


//{14}  FS_Import.CLList.Add('ГК,имп/2c');
//{15}  FS_Import.CLList.Add('ННКт-25,имп/2c');
//{16}  FS_Import.CLList.Add('ННКт-50,имп/2c');
//{17}  FS_Import.CLList.Add('НГК,имп/2c');

  RM_GK: array[0..0]of TRecMap =(
    (ix:14;  name:'ГК.гк.DEV'; k:1)
  );
  RM_NNK: array[0..2]of TRecMap =(
    (ix:15;  name:'ННК.нк1.DEV'; k:1),
    (ix:16;  name:'ННК.нк2.DEV'; k:1),
    (ix:17;  name:'ННК.нгк.DEV'; k:1)
  );

//{0}   FS_Import.CLList.Add('Gz1');
//{1}   FS_Import.CLList.Add('Gz2');
//{2}   FS_Import.CLList.Add('Gz3');
//{3}   FS_Import.CLList.Add('Gz4');
//{4}   FS_Import.CLList.Add('Gz5');
//{5}   FS_Import.CLList.Add('Gz6');
//{6}   FS_Import.CLList.Add('Ток,мВ');
//{7}   FS_Import.CLList.Add('PS1,мВ');

//{30}  FS_Import.CLList.Add('U0'); //-БК
//{31}  FS_Import.CLList.Add('I10');//-смещение
//{32}  FS_Import.CLList.Add('I20');//-смещение
//{33}  FS_Import.CLList.Add('I11');//-БК 1
//{34}  FS_Import.CLList.Add('I21');//-БК 1
//{35}  FS_Import.CLList.Add('I12');//-БК 2
//{36}  FS_Import.CLList.Add('I22');//-БК 2
//{37}  FS_Import.CLList.Add('I13');//-БК 3
//{38}  FS_Import.CLList.Add('I23');//-БК 3
//{39}  FS_Import.CLList.Add('I14');//-БК 4
//{40}  FS_Import.CLList.Add('I24');//-БК 4
//{41}  FS_Import.CLList.Add('I15');//-БК 5
//{42}  FS_Import.CLList.Add('I25');//-БК 5
//{43}  FS_Import.CLList.Add('I16');//-БК 6
//{44}  FS_Import.CLList.Add('I26');//-БК 6

//{51}  FS_Import.CLList.Add('PS2,мВ');

//{53}  FS_Import.CLList.Add('dPS,мВ');


  RM_BK : array[0..24]of TRecMap =(
    (ix:31;  name:'electro.БК.B.I0.DEV'; k:1),
    (ix:33;  name:'electro.БК.B.I1.DEV'; k:1),
    (ix:35;  name:'electro.БК.B.I2.DEV'; k:1),
    (ix:37;  name:'electro.БК.B.I3.DEV'; k:1),
    (ix:39;  name:'electro.БК.B.I4.DEV'; k:1),
    (ix:41;  name:'electro.БК.B.I5.DEV'; k:1),
    (ix:43;  name:'electro.БК.B.I6.DEV'; k:1),
    (ix:32;  name:'electro.БК.H.I0.DEV'; k:1),
    (ix:34;  name:'electro.БК.H.I1.DEV'; k:1),
    (ix:36;  name:'electro.БК.H.I2.DEV'; k:1),
    (ix:38;  name:'electro.БК.H.I3.DEV'; k:1),
    (ix:40;  name:'electro.БК.H.I4.DEV'; k:1),
    (ix:42;  name:'electro.БК.H.I5.DEV'; k:1),
    (ix:44;  name:'electro.БК.H.I6.DEV'; k:1),
    (ix:30;  name:'electro.БК.U0.DEV'; k:1),
    (ix:0;  name:'electro.КС.точно.Z1.DEV'; k:1),
    (ix:1;  name:'electro.КС.точно.Z2.DEV'; k:1),
    (ix:2;  name:'electro.КС.точно.Z3.DEV'; k:1),
    (ix:3;  name:'electro.КС.точно.Z4.DEV'; k:1),
    (ix:4;  name:'electro.КС.точно.Z5.DEV'; k:1),
    (ix:5;  name:'electro.КС.точно.Z6.DEV'; k:1),
    (ix:6;  name:'electro.КС.I.DEV'; k:1),
    (ix:7;  name:'electro.ПС.Z1.DEV'; k:1),
    (ix:51;  name:'electro.ПС.Z2.DEV'; k:1),
    (ix:53;  name:'electro.ПС.DPS.DEV'; k:1));

//function TFormExportToPSK6_V3.GetMaxID(const rams: TArray<IDataSet>): Integer;
// var
//  d: IDataSet;
//begin
//  Result := 0;
//  for d in rams do if Assigned(d) then
//   begin
//    d.DataSet.Open;
//    Result := Max(Result, d.DataSet.RecordCount);
//    d.DataSet.Close;
//   end;
//end;

function TFormExportToPSK6_V3.GetProjectRams(): TArray<IDataSet>;
 var
  i: Integer;
  r, n, d, s: IXMLNode;
  adv: TArray<IXMLNode>;
  function GreateIDS(adr: Integer; const rms: array of TRecMap): IDataSet;
   var
    n: IXMLNode;
    function ContainsRM: Boolean;
     var
      rm: TRecMap;
      dummy: IXMLNode;
    begin
      for rm in rms do if not tools.TryGetX(n, rm.name, dummy) then Exit(False);
      Result := True;
      FSerials := FSerials + AnsiString(Format(DEVS_END_IF[adr],[Integer(n.ParentNode.Attributes[AT_SERIAL])]));
    end;
  begin
    Result := nil;
    for n in adv do // if n.ParentNode.Attributes[AT_ADDR] = adr then
     begin
      TXMLDataSet.Get(n, Result, false);
      if Assigned(Result) and ContainsRM then
       begin

         Exit(Result);
       end;
     end;
    Result := nil;
  end;
begin
  r := (GContainer as IALLMetaDataFactory).Get.Get.DocumentElement;
  if r.NodeName = 'PROJECT' then r := r.ChildNodes.FindNode('DEVICES');
   for n in XEnum(r) do
    begin
     for d in XEnum(n) do if d.HasAttribute(AT_ADDR) and (Integer(d.Attributes[AT_ADDR]) in [3,4,5,6]) then
     begin
      s := d.ChildNodes.FindNode(T_RAM);
      if Assigned(s) and s.HasAttribute(AT_FILE_NAME) then adv := adv + [s];
     end;
    end;
   //TODO: adv - массив секций RAM памяти возможны с одинаковыми адресами необходимо создасть диалог выбора
  FSerials := '$$';
  Result := Result + [GreateIDS(3, RM_INCL)];
  Result := Result + [GreateIDS(4, RM_GK)];
  Result := Result + [GreateIDS(5, RM_NNK)];
  Result := Result + [GreateIDS(6, RM_BK)];
  FSerials := FSerials + '*$$';
  // если нет нужного адреса устройства то Result[i] = nil;
end;

{ TFormExportToPSK6 }

procedure TFormExportToPSK6_V3.btExitClick(Sender: TObject);
begin
  Close_ItemClick(Self);
end;

procedure TFormExportToPSK6_V3.Open();
var
  d: IDataSet;
begin
  for d in rams do if Assigned(d) then d.DataSet.Open;
end;

procedure TFormExportToPSK6_V3.RecNo(Kadr: Integer);
 var
  i: Integer;
begin
  for i := 0 to High(rams) do if Assigned(rams[i]) and (Kadr >= acr[i].FirstKadr) and (Kadr <= acr[i].LastKadr) then
    rams[i].DataSet.RecNo := Kadr - acr[i].FirstKadr + 1;;
end;

procedure TFormExportToPSK6_V3.Close;
 var
  d: IDataSet;
begin
  for d in rams do if Assigned(d) then d.DataSet.Close;
end;

//procedure TFormExportToPSK6_V3.Next;
// var
//  d: IDataSet;
//begin
//  for d in rams do if Assigned(d) then d.DataSet.Next;
//end;

procedure TFormExportToPSK6_V3.btStartClick(Sender: TObject);
 var
  v: Variant;
  i: integer;
  sql, s: string;
  r: TCheckRec;
  Alias: char;
  f: TFldRec;
  flds: TArray<string>;
  LeftOuterJoins: TArray<string>;
  rmax, rmin: Integer;
  emax, emin: Integer;
  umax, umin: Integer;
 const
  N_REC_READ = 10000;
begin
  /// начало и конец
  umax := RangeSelect.kadr.last;// StrToInt(.Text);
  umin := RangeSelect.kadr.first;// StrToInt(edFrom.Text);
   Fterminate := False;
   UpdateControls(False);
   //sb.
   TThread.CreateAnonymousThread(procedure
    var
     f: TFileStream;
     d: TFileFormatPSK6;
     frm, n: Integer;
     cr: TCheckRec;
     fr: TFldRec;
     fld: TField;
     dfloat: Double;
     newPos: Integer;
     function InKadrRange(curKadr: Integer; cr: TCheckRec): Boolean;
     begin
      Result := (curKadr <= cr.LastKadr) and (curKadr <= cr.LastKadr)

     end;
     procedure UpdateSb4(const s: string);
     begin
       TThread.Synchronize(nil, procedure
        begin
          sb.Panels[4].Text := s;
        end);
     end;
   begin
     try
      if od.FileName <> '' then
       begin
        if TFile.Exists(od.FileName) then TFile.Delete(od.FileName);
        f := TFileStream.Create(od.FileName, fmCreate);
       end
      else
       begin
        UpdateControls(True);
        UpdateSb4(RS_EmptyFileName);
        Exit;
       end;
       try
          Open;
          try
           FIStat := TStatisticCreate.Create((umax-umin)*SizeOf(d));
           UpdateSb4(RS_Run);
           for frm := umin to umax do
            begin
               RecNo(frm);
               d.Dep := frm+1;
               for cr in acr do if cr.Checked then for fr in cr.Data do
                begin
                 fld := cr.Table.FieldByName(fr.FieldName);
                 try
                  if Assigned(fld) and not fld.isNull and (frm <= cr.LastKadr) and (frm >= cr.FirstKadr) then
                  // if fld is TFloatField then
                    begin
                     // dfloat := cr.Table.FieldByName(fr.FieldName).AsFloat * fr.k;
                     dfloat := fld.AsFloat * fr.k;
                     if (dfloat < LongInt.MaxValue) and (dfloat > LongInt.MinValue)  then d.Par[fr.Index] := Round(dfloat)
                     else d.Par[fr.Index] := 0;
                    end
                  // else d.Par[fr.Index] := fld.AsInteger //d.Par[fr.Index] := cr.Table.FieldByName(fr.FieldName).AsInteger
                  else  d.Par[fr.Index] := 0;
                 except
                  d.Par[fr.Index] := 0;
                 end;
                end;

               f.Write(d, SizeOf(d));

               FIStat.UpdateAdd(SizeOf(d));

               if Fterminate then
                begin
                 UpdateSb4(RS_terminate);
                 Exit;
                end;

               if (umax - umin) > 0 then newPos := Round((frm - umin)/(umax - umin)*100)
               else newPos := 0;
               if (Progress.Position <> newPos) then TThread.Synchronize(nil, procedure
                begin
                  Progress.Position := newPos;
                  TStatisticCreate.UpdateStandardStatusBar(sb, FIStat.Statistic);
                end);
            end;
            f.Write(Fserials[1], Length(Fserials));
            f.Write(MBKPB_END_IF[0], 7);
            UpdateSb4(RS_end);
          finally
           Close;
          end;
       finally
        f.Free;
        UpdateControls(True);
       end;
     except
      on E: Exception do
       begin
        UpdateSb4(RS_Err);
        TDebug.DoException(E);
       end;
     end;
   end).Start();
end;

procedure TFormExportToPSK6_V3.btTerminateClick(Sender: TObject);
begin
  Fterminate := True;
end;

class procedure TFormExportToPSK6_V3.DoExportPSK6(Sender: IAction);
begin
  GetUniqueForm('GlobalFormExportToPSK6_V3');
end;

procedure TFormExportToPSK6_V3.FormCreate(Sender: TObject);
 var
  i, lc, fc: Integer;
 function CheckKadrID(kdr, kdrid: integer): boolean;
 begin
   if kdr <> kdrid then
    begin
     Result := False;
     if Assigned(TDebug.ExeptionEvent) then TDebug.ExeptionEvent(RS_ErrDataStruct,
        Format(RS_MameIdFrame, [acr[i].IdName, kdrid, kdr]), '');
    end
   else Result := True;
 end;
begin
  GetDockClient.EnableDock := False;
  rams := GetProjectRams;
  /// инициализация имен
  SetLength(acr, 4);
//  acr[0].adr := 3;
//  acr[1].adr := 4;
//  acr[2].adr := 5;
//  acr[3].adr := 6;
  StRec(rams[0], RM_INCL, acr[0]);
  StRec(rams[1], RM_GK,   acr[1]);
  StRec(rams[2], RM_NNK,  acr[2]);
  StRec(rams[3], RM_BK,   acr[3]);
  /// инициализация имен Ranger
  Open;
  lc := 1;
  fc := Integer.MaxValue;
  for I := 0 to High(rams) do if Assigned(rams[i]) then
   begin
    rams[i].DataSet.First;
    acr[i].FirstKadr := rams[i].DataSet.FieldByName(acr[i].IdName).AsInteger;
    acr[i].FirstKadrID := rams[i].DataSet.FieldByName('ID').AsInteger;
    if not CheckKadrID(acr[i].FirstKadr, acr[i].FirstKadrID) then acr[i].FirstKadr := acr[i].FirstKadrID;
    fc := Min(fc, acr[i].FirstKadr);
    rams[i].DataSet.Last;
    acr[i].LastKadr := rams[i].DataSet.FieldByName(acr[i].IdName).AsInteger;
    acr[i].LastKadrID := rams[i].DataSet.FieldByName('ID').AsInteger;
    if not CheckKadrID(acr[i].LastKadr, acr[i].LastKadrID) then acr[i].LastKadr := acr[i].LastKadrID;
    lc := max(lc, acr[i].LastKadr);
   end;
  if fc > lc then
   begin
//    RangeSelect.Init(1, 0, 1, (GContainer as IProjectOptions).DelayStart);
    FbadData := True;
    raise ENeedDialogException.Create(RS_Mbk_None);
   end;
  RangeSelect.Init(1, fc, lc, (GContainer as IProjectOptions).DelayStart);
end;

procedure TFormExportToPSK6_V3.FormShow(Sender: TObject);
begin
  if FbadData then btExitClick(Self);
end;

function TFormExportToPSK6_V3.Priority: Integer;
begin
  Result := PRIORITY_NoStore;
end;

procedure TFormExportToPSK6_V3.StRec(ix: IdataSet; const drm: array of TRecMap; var d: TcheckRec);
 var
  i: Integer;
  ds: TXMLDataSet;
begin
  d.Checked := False;
  if not Assigned(ix) then Exit;
  ds := TXMLDataSet(ix.DataSet);
  SetLength(d.Data, Length(drm));
  d.Table := ds;
  d.ModulName := ds.XMLSection.ParentNode.NodeName;
  d.IdName := d.ModulName +'.время.DEV'; //если проблемма с кадрами 'ID'
  for I := 0 to High(drm) do
   begin
    d.Data[i].FieldName := d.ModulName+'.' + drm[i].name;
    d.Data[i].k := drm[i].k;
    d.Data[i].Index := drm[i].ix;
   end;
  d.Checked := True;
end;

procedure TFormExportToPSK6_V3.UpdateControls(FlagEna: Boolean);
begin
  RangeSelect.Enabled := FlagEna;
  btStart.Enabled := FlagEna;
  btExit.Enabled := FlagEna;
  NCanClose := FlagEna;
end;

initialization
  RegisterClass(TFormExportToPSK6_V3);
  TRegister.AddType<TFormExportToPSK6_V3, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormExportToPSK6_V3>;
end.
