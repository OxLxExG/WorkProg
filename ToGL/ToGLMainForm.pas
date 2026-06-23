unit ToGLMainForm;

interface

uses System.IOUtils, TxtParser, TimeDepthTxtDataSet, MathIntf,  dtglDataSet, DateTimeLasDataSet,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, Data.DB,
  Vcl.Grids, Vcl.DBGrids, DBChart,
  RLDataSet, JvExComCtrls, JvUpDown, TeEngine, Series, TeeProcs, Chart;

type
  TFormMain = class(TForm)
    MainMenu: TMainMenu;
    mFile: TMenuItem;
    mOpenHorozontPB: TMenuItem;
    mOpenTimeDepthtTxt: TMenuItem;
    mOptions: TMenuItem;
    sb: TStatusBar;
    Panel: TPanel;
    Splitter1: TSplitter;
    lbFromPB: TLabel;
    lbToPB: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    lbName: TLabel;
    edPbBegin: TMaskEdit;
    edPbEnd: TMaskEdit;
    Label3: TLabel;
    Label4: TLabel;
    pc: TPageControl;
    db: TTabSheet;
    tshGti: TTabSheet;
    DBGridPB: TDBGrid;
    DBGridGTI: TDBGrid;
    DataSourcePB: TDataSource;
    lbGlu: TLabel;
    DataSourceGTI: TDataSource;
    lbToGlu: TLabel;
    edEndGlu: TMaskEdit;
    edFromGlu: TMaskEdit;
    Label6: TLabel;
    Label7: TLabel;
    lbFromGlu: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    lbDeltaTime: TLabel;
    Label8: TLabel;
    lbEndGluDep: TLabel;
    Label12: TLabel;
    lbFromGluDep: TLabel;
    lbMaxTime: TLabel;
    lbMinTime: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    lbMinDep: TLabel;
    lbMaxDep: TLabel;
    Graph: TTabSheet;
    cbMnem: TComboBox;
    Label5: TLabel;
    Label11: TLabel;
    edScale: TEdit;
    btPbApply: TButton;
    udH: TJvUpDown;
    edH: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    edM: TEdit;
    udM: TJvUpDown;
    udS: TJvUpDown;
    edS: TEdit;
    Label19: TLabel;
    edmS: TEdit;
    Label20: TLabel;
    Label21: TLabel;
    Chart: TChart;
    Series1: TFastLineSeries;
    Series2: TFastLineSeries;
    btApplyGti: TButton;
    Label22: TLabel;
    edAddDepth: TEdit;
    JvUpDown1: TJvUpDown;
    Series3: TFastLineSeries;
    chMonotone: TCheckBox;
    chRemoveSpeed: TCheckBox;
    edSpeed: TEdit;
    lbSpeed: TLabel;
    btFilter: TButton;
    chAverage: TCheckBox;
    edNave: TEdit;
    Label23: TLabel;
    mClearTmp: TMenuItem;
    N1: TMenuItem;
    NTimeDepthtxt: TMenuItem;
    Exit1: TMenuItem;
    Exportgl1file1: TMenuItem;
    btResetFilter: TButton;
    Opeb1: TMenuItem;
    NOpen: TMenuItem;
    N3: TMenuItem;
    NLAS: TMenuItem;
    NLasDT: TMenuItem;
    NLasTime_DateTime: TMenuItem;
    NLasDepth: TMenuItem;
    NZaboyS101: TMenuItem;
    NDolotoS115: TMenuItem;
    cbDelJumps: TCheckBox;
    NFilters: TMenuItem;
    NDelJumps: TMenuItem;
    Series4: TFastLineSeries;
    ppm: TPopupMenu;
    ppRemoveArrea: TMenuItem;
    NFrameTime: TMenuItem;
    N20971521: TMenuItem;
    N41: TMenuItem;
    NLasTime_Date1Time2txt: TMenuItem;
    NDolotoDBTM: TMenuItem;
    DatetimeZbDllas: TMenuItem;
    DateTimeZbDl1: TMenuItem;
    NLasDTTxtDepth: TMenuItem;
    d1: TMenuItem;
    ime1: TMenuItem;
    DatetxtTimetxtZbDllas1: TMenuItem;
    Setup1: TMenuItem;
    lbOutRangeFrom: TLabel;
    lbOutRangeFromDept: TLabel;
    Label26: TLabel;
    lbOutRangeToDept: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    lbOutRangeTo: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label24: TLabel;
    btResetOut: TButton;
    BeginOutputRange1: TMenuItem;
    BeginOutputRange2: TMenuItem;
    Series5: TFastLineSeries;
    DEPTTimezbtslas: TMenuItem;
    D2: TMenuItem;
    ime2: TMenuItem;
    M1: TMenuItem;
    ime3: TMenuItem;
    imeSec1: TMenuItem;
    DEPTTimezbtslasOpeb: TMenuItem;
    N1DTMs15VALUE54mlas1: TMenuItem;
    CartographerAddGl11: TMenuItem;
    N41943041: TMenuItem;
    LAS1: TMenuItem;
    UserDateTimeFormat: TMenuItem;
    t2md1: TMenuItem;
    procedure mOpenHorozontPBClick(Sender: TObject);
    procedure mOpenTimeDepthtTxtClick(Sender: TObject);
    procedure ChartClickSeries(Sender: TCustomChart; Series: TChartSeries; ValueIndex: Integer; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btPbApplyClick(Sender: TObject);
    procedure btApplyGtiClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure chMonotoneClick(Sender: TObject);
    procedure chRemoveSpeedClick(Sender: TObject);
    procedure btFilterClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure btResetFilterClick(Sender: TObject);
    procedure Opeb1Click(Sender: TObject);
    procedure NDelJumpsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ppRemoveArreaClick(Sender: TObject);
    procedure ChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DatetxtTimetxtZbDllas1Click(Sender: TObject);
    procedure Setup1Click(Sender: TObject);
    procedure BeginOutputRange1Click(Sender: TObject);
    procedure BeginOutputRange2Click(Sender: TObject);
    procedure btResetOutClick(Sender: TObject);
    procedure DEPTTimezbtslasOpebClick(Sender: TObject);
    procedure N1DTMs15VALUE54mlas1Click(Sender: TObject);
    procedure CartographerAddGl11Click(Sender: TObject);
    procedure LAS1Click(Sender: TObject);
    procedure UserDateTimeFormatClick(Sender: TObject);
    procedure t2md1Click(Sender: TObject);
  private
    Metadata: TMetaData;
    ds: TPBDataSet;
    dsglu: TDataSet;
    Scale: Double;
    AddDepth: Double;
    OutSelect:  TDateTime;
    AddDateTime: TDateTime;
    OldFirstX, OldlastX: TdateTime;

    x,y: TArray<Double>;
    DjFlt: record
     Shit: Double;
     Time: Double;
    end;
    MouseDown: record
     X, Y: Double;
    end;
    //function GetSplitter(): Char;
    function GetFrameTime(): Double;
    function GetLasDatetimeMnem(): string;
    function GetLasDeptMnem(root: TMenuItem): string;
    procedure FillcbMnem;
    procedure FillGluSeries;
    procedure FillGluXY;
    procedure FillFilterSeries();

    procedure FillPbSeries;
    function FindAddDateTime(): Double;
    procedure InnerGTIOpenDialog(const Ext, Flt, Descript: string; CreateDS: TFunc<string,TdtglDataSet>);
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses Filters, AddGl1toLASForm;

{$R *.dfm}

procedure TFormMain.BeginOutputRange1Click(Sender: TObject);
begin
  lbOutRangeFrom.Caption := DateTimeToStr(OutSelect);
  lbOutRangeFromDept.Caption := AddDepth.ToString;
  Series4.Clear;
  Series5.Clear;
  ppm.AutoPopup := False;
end;

procedure TFormMain.BeginOutputRange2Click(Sender: TObject);
begin
  lbOutRangeTo.Caption := DateTimeToStr(OutSelect);
  lbOutRangeToDept.Caption := AddDepth.ToString;
  Series4.Clear;
  Series5.Clear;
  ppm.AutoPopup := False;
end;

procedure TFormMain.btApplyGtiClick(Sender: TObject);
begin
  FillGluSeries;
end;

procedure TFormMain.btFilterClick(Sender: TObject);
begin
  AddDateTime := FindAddDateTime;
  FillGluXY;
  if cbDelJumps.Checked then DelJumps(x,y,DjFlt.Shit,DjFlt.Time/60/24);
  if chAverage.Checked then Mave(x,y,StrToInt(edNave.Text));
  if chMonotone.Checked then Monotone(x,y)
  else if chRemoveSpeed.Checked then Speed(x,y,StrToFloat(edSpeed.Text));

  FillFilterSeries();
end;

procedure TFormMain.btPbApplyClick(Sender: TObject);
begin
  AddDepth := StrToFloat(edAddDepth.Text);
  Scale := 1/StrToFloat(edScale.Text);
  AddDateTime := FindAddDateTime;
  FillPbSeries;
end;

procedure TFormMain.btResetFilterClick(Sender: TObject);
begin
  SetLength(x, 0);
  SetLength(y, 0);
  OldlastX := 0;
  OldFirstX := 0;
  chAverage.Checked := False;
  chMonotone.Checked := False;
  cbDelJumps.Checked := False;
  chRemoveSpeed.Checked := False;
end;

procedure TFormMain.btResetOutClick(Sender: TObject);
begin
  lbOutRangeFrom.Caption :=  lbFromGlu.Caption;
  lbOutRangeTo.Caption :=  lbToGlu.Caption;
  lbOutRangeFromDept.Caption :=  lbFromGluDep.Caption;
  lbOutRangeToDept.Caption :=  lbEndGluDep.Caption;
  Series4.Clear;
  Series5.Clear;
end;

procedure TFormMain.btSaveClick(Sender: TObject);
type
 Tgl=packed record
  kadr: Integer;
  glsm: Integer;
 end;
 var
 // i:Integer;
  Spline: ISpline;
  tcur: TDateTime;
  tend: TDateTime;
  tg: Tgl;
begin
  with TSaveDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   Options := Options + [ofOverwritePrompt, ofPathMustExist];
//   DefaultExt := 'dtglCorr';
//   Filter := 'Файл (*.dtglCorr)|*.dtglCorr';
   DefaultExt := 'gl1';
   Filter := 'Файл (*.gl1)|*.gl1';
   if Execute(Handle) then
   begin
    if TFile.Exists(FileName) then TFile.Delete(FileName);
    //var add := FindAddDateTime;
    var dds := TTimeDepthTxtDataSet(dsglu);
    var s := TFileStream.Create(FileName, fmCreate);
    try
      if Length(x) = 0 then FillGluXY;
      SplineFactory(Spline);
      CheckMath(Spline, Spline.buld(@x[0], @y[0], Length(x)));
      tcur := x[0];
      tend := x[High(x)];
//      if not Assigned(ds) then
//       begin
//        tcur := dds.DataStart.datetime;
//        tend := dds.DataEnd.datetime;
//        tg.kadr := 0;
//       end
//      else
//       begin
//        tcur := ds.TimeStart;
//        tend := ds.TimeEnd;
//        tg.kadr := ds.KadrFrom-1;
//       end;
      var FrameTime := GetFrameTime;
      while tcur < tend do
       begin
        var sy: Double;
        Spline.get(tcur, sy);
        tg.glsm := Round(sy*100);
        s.Write(tg, SizeOf(Tgl));
        Inc(tg.kadr);
        tcur := tcur + FrameTime;//ds.KADR_TO_TDateTime;
       end;
    finally
     s.Free;
    end;
   end;
  finally
   Free;
  end;
end;

procedure TFormMain.CartographerAddGl11Click(Sender: TObject);
begin
  FormAddGl1ToLAS  := TFormAddGl1ToLAS.Create(Self);
  try
    FormAddGl1ToLAS.ShowModal;
  finally
    FormAddGl1ToLAS.Free;
  end;
end;

procedure TFormMain.ChartClickSeries(Sender: TCustomChart; Series: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
//  if Series = Series1 then
   begin
//    ppRemoveArrea.Visible := True;
    ppm.AutoPopup := True;
    AddDepth := Series.YValue[ValueIndex];
    OutSelect := Series.XValue[ValueIndex];
    edAddDepth.Text := AddDepth.ToString;
    Series4.Clear;
    Series4.AddXY(Chart.Axes.Bottom.minimum,AddDepth);
    Series4.AddXY(Chart.Axes.Bottom.Maximum,AddDepth);
    Series5.Clear;
    Series5.AddXY(OutSelect,Chart.Axes.Left.minimum);
    Series5.AddXY(OutSelect,Chart.Axes.Left.Maximum);
   end;
end;

procedure TFormMain.ChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MouseDown.X := Chart.Axes.Bottom.CalcPosPoint(X);
  MouseDown.Y :=  Chart.Axes.Left.CalcPosPoint(Y);
end;

procedure TFormMain.chMonotoneClick(Sender: TObject);
begin
  if chMonotone.Checked then chRemoveSpeed.Checked := false;
end;

procedure TFormMain.chRemoveSpeedClick(Sender: TObject);
begin
  lbSpeed.Enabled := chRemoveSpeed.Checked;
  edSpeed.Enabled := chRemoveSpeed.Checked;
  if chRemoveSpeed.Checked then chMonotone.Checked := false; 
  
end;

procedure TFormMain.DatetxtTimetxtZbDllas1Click(Sender: TObject);
begin
  InnerGTIOpenDialog('las', 'LAS File (*.las)|*.las', 'Gti Date-Time-zb-depth.Las file',
   function (FileName: string): TdtglDataSet
   begin
     Result := TdatattimeTxtLasDataSet.Create(Self, FileName, 'DATE','TIME', GetLasDeptMnem(NLasDTTxtDepth), mClearTmp.Checked);
   end);
end;

procedure TFormMain.DEPTTimezbtslasOpebClick(Sender: TObject);
begin
  InnerGTIOpenDialog('las', 'LAS File (*.las)|*.las', 'Gti Dept-time-глуб-SecTime.Las file',
   function (FileName: string): TdtglDataSet
   begin
     Result := TDptTimeZaboiSecTime.Create(Self, FileName, 'TIME','','глуб', mClearTmp.Checked);
   end);
end;

procedure TFormMain.N1DTMs15VALUE54mlas1Click(Sender: TObject);
begin
  InnerGTIOpenDialog('las', 'LAS File (*.las)|*.las', '1.DTM,s-15.VALUE54,m.Las file',
   function (FileName: string): TdtglDataSet
    var
     r : TDptTimeZaboiSecTime;
   begin
     r := TDptTimeZaboiSecTime.Create(Self, FileName, 'DTM','','VALUE54', mClearTmp.Checked);
     r.AddingDays := 25569;
     exit(r);
   end);
end;

procedure TFormMain.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.FillcbMnem;
begin
  cbMnem.Items.Clear;
  for var m in Metadata.Data do cbMnem.Items.Add(m.mnem);
end;

procedure TFormMain.FillFilterSeries();
 var
 First, last: TdateTime;
begin
  First := StrToDateTime(edFromGlu.Text);
  last := StrToDateTime(edEndGlu.Text);
  Series3.BeginUpdate;
  Series3.Clear;
  try
    for var I := 0 to High(x) do
      if x[i] < first then Continue
      else if x[i] > last then Break
      else Series3.AddXY(x[i]+AddDateTime,y[i]);//+ AddDepth);
  finally
    Series3.EndUpdate;
  end;

end;

procedure TFormMain.FillGluSeries;
 var
 cur: TfileRecData;
 First, last: TdateTime;
begin
  First := StrToDateTime(edFromGlu.Text);
  last := StrToDateTime(edEndGlu.Text);
  Series1.BeginUpdate;
  dsglu.DisableControls;
  Series1.Clear;
  try
   var dds := TTimeDepthTxtDataSet(dsglu);
   if not dds.IsCursorOpen then raise Exception.Create('Error Data not Open');
   dds.Stream.Seek(0, soBeginning);
    while dds.Stream.Read(cur, SizeOf(TfileRecData)) = SizeOf(TfileRecData) do
     if cur.datetime < first then Continue
     else if cur.datetime > last then Break
     else Series1.AddXY(cur.datetime,cur.depth, DateTimeToStr(cur.datetime));
  finally
   dsglu.EnableControls;
   Series1.EndUpdate;
  end;
  Chart.Repaint;
end;

procedure TFormMain.FillGluXY;
 var
  cur: TfileRecData;
  First, last: TdateTime;
begin
  var dds := TTimeDepthTxtDataSet(dsglu);
  First := StrToDateTime(lbOutRangeFrom.Caption);
  last := StrToDateTime(lbOutRangeTo.Caption);
//  if Length(x) <> dds.RecordCount then
   if (OldFirstX <> First) or  (OldlastX <> last) then
   begin
    SetLength(x, dds.RecordCount);
    SetLength(y, dds.RecordCount);
    dds.Stream.Seek(0, soBeginning);
    var i := 0;
    while dds.Stream.Read(cur, SizeOf(TfileRecData)) = SizeOf(TfileRecData) do
     if (cur.datetime >= First) and (cur.datetime <= last) then
     begin
      x[i] := cur.datetime - AddDateTime;
      y[i] := cur.depth;
      Inc(i);
     end;
    SetLength(x, i);
    SetLength(y, i);
    OldFirstX := First;
    OldlastX := last;
//     if i <> dds.RecordCount then
//     begin
//      Caption := ' ERR i <> dds.RecordCount';
//     end;
   end;

end;

procedure TFormMain.FillPbSeries;
 var
 First, last: TdateTime;
begin
  var mnem := cbMnem.Items[cbMnem.ItemIndex];
  if mnem ='' then exit;
  First := StrToDateTime(edPbBegin.Text);
  last := StrToDateTime(edPbEnd.Text);
  Series2.BeginUpdate;
  ds.DisableControls;
  Series2.Clear;
  try
   ds.First;
   var fdt := ds.FieldByName('DateTime');
   var fdep := ds.FieldByName(mnem);
   while not ds.Eof do
     try
       var t := fdt.AsFloat + AddDateTime;
       var d := fdep.AsFloat;
       if t < first then Continue
       else if t > last then Break
       else Series2.AddXY(t,d * Scale + AddDepth);//, DateTimeToStr(t));
     finally
       ds.Next;
     end;
  finally
   ds.EnableControls;
   Series2.EndUpdate;
  end;
  Chart.Repaint;
end;

function TFormMain.FindAddDateTime: Double;
begin
  var h := StrToInt(edH.Text);
  var m := StrToInt(edM.Text);
  var s := StrToInt(edS.Text);
  var ms := StrToInt(edmS.Text);
  Result := h/24+m/24/60+s/24/60/60+ms/24/60/60/1000;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  DjFlt.Shit := 35;
  DjFlt.Time := 5;
end;

//function TFormMain.GetSplitter: Char;
//begin
//  Result := #32;
//  for var m in mTimeDepthtxtSplitter do if m.Checked then exit(chr(m.Tag));
//end;

procedure TFormMain.mOpenHorozontPBClick(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
  try
    InitialDir := ExtractFilePath(ParamStr(0));
    Options := Options + [ofPathMustExist, ofFileMustExist];
    DefaultExt := 'DEV';
    Filter := 'File device PB (*.DEV)|*.DEV';
    if Assigned(ds) then FreeAndNil(ds);
    if Execute(Handle) then
     begin
      sb.Panels[0].Text := FileName;
      var txtf := TPath.ChangeExtension(FileName, 'txt');
      if not TFile.Exists(txtf) then raise Exception.Createfmt('File metadata %s not exists', [txtf]);
      var ss := TStringList.Create;
      try
       ss.LoadFromFile(txtf);
       Metadata := TMetaData.Create(ss);
       FillcbMnem();
       ds := TPBDataSet.Create(Self,FileName,Metadata);
       lbName.Caption := Format('Adr:%s Inf:%s SN:%s',[Metadata.Options.Values['ADDR'],
                                                     Metadata.Options.Values['INFO'],
                                                     Metadata.Options.Values['SERIAL_NO']]);
      finally
       ss.Free;
      end;
      ds.Open;
      lbFromPB.Caption := DateTimeToStr(ds.TimeStart);
      lbToPB.Caption := DateTimeToStr(ds.TimeEnd);
      edPbBegin.Text := lbFromPB.Caption;
      edPbEnd.Text := lbToPB.Caption;
      if not ds.GoodSize then
       begin
        Caption := 'not GoodSize';
       end;
       DataSourcePB.DataSet := ds;
     end;
  finally
    Free;
  end;
end;

procedure TFormMain.InnerGTIOpenDialog(const Ext, Flt, Descript: string; CreateDS: TFunc<string,TdtglDataSet>);
begin
  with TOpenDialog.Create(nil) do
  try
    InitialDir := ExtractFilePath(ParamStr(0));
    Options := Options + [ofPathMustExist, ofFileMustExist];
    DefaultExt := Ext;
    Filter := Flt;
    if Assigned(dsglu) then FreeAndNil(dsglu);
    if Execute(Handle) then
     begin
      sb.Panels[1].Text := FileName;
      dsglu := CreateDS(FileName);
      dsglu.Open;
      with dsglu as TdtglDataSet do
       begin
        lbFromGlu.Caption := DateTimeToStr(DataStart.datetime);
        edFromGlu.Text := lbFromGlu.Caption;
        lbToGlu.Caption := DateTimeToStr(DataEnd.datetime);
        edEndGlu.Text :=  lbToGlu.Caption;
        lbFromGluDep.Caption := DataStart.depth.ToString;
        lbEndGluDep.Caption := DataEnd.depth.ToString;
        lbDeltaTime.Caption := DeltaTime.ToString;
//        var mx := GetMaxMinDept(StrToDateTime(edFromGlu.Text), StrToDateTime(edEndGlu.Text));
//        lbMaxDep.Caption := mx.max.depth.ToString;
//        lbMinDep.Caption := mx.min.depth.ToString;
//        lbMinTime.Caption := DateTimeToStr(mx.min.datetime);
//        lbMaxTime.Caption := DateTimeToStr(mx.max.datetime);
       end;
      DataSourceGTI.DataSet := dsglu;
      dsglu.First;
      lbGlu.Caption := Descript;
      btResetOutClick(nil);
      //FillGluSeries;
     end;
  finally
    Free;
  end;
end;

procedure TFormMain.LAS1Click(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
  try
    InitialDir := ExtractFilePath(ParamStr(0));
    Options := Options + [ofPathMustExist, ofFileMustExist];
    DefaultExt := 'las';
    Filter := 'LAS File (*.las)|*.las';
//    if Assigned(dsglu) then FreeAndNil(dsglu);
    if Execute(Handle) then
     begin
      sb.Panels[1].Text := FileName;
      var intv :=  GetFrameTime;
      lbName.Caption := 'Las File Kadr Interval= ' + (intv*24*3600).ToString;
      //dsglu := CreateDS(FileName);
//      dsglu.Open;
//      with dsglu as TdtglDataSet do
//       begin
//        lbFromGlu.Caption := DateTimeToStr(DataStart.datetime);
//        edFromGlu.Text := lbFromGlu.Caption;
//        lbToGlu.Caption := DateTimeToStr(DataEnd.datetime);
//        edEndGlu.Text :=  lbToGlu.Caption;
//        lbFromGluDep.Caption := DataStart.depth.ToString;
//        lbEndGluDep.Caption := DataEnd.depth.ToString;
//        lbDeltaTime.Caption := DeltaTime.ToString;
////        var mx := GetMaxMinDept(StrToDateTime(edFromGlu.Text), StrToDateTime(edEndGlu.Text));
////        lbMaxDep.Caption := mx.max.depth.ToString;
////        lbMinDep.Caption := mx.min.depth.ToString;
////        lbMinTime.Caption := DateTimeToStr(mx.min.datetime);
////        lbMaxTime.Caption := DateTimeToStr(mx.max.datetime);
//       end;
//      DataSourceGTI.DataSet := dsglu;
//      dsglu.First;
//      lbGlu.Caption := Descript;
//      btResetOutClick(nil);
      //FillGluSeries;
     end;
  finally
    Free;
  end;
end;

procedure TFormMain.mOpenTimeDepthtTxtClick(Sender: TObject);
begin
  InnerGTIOpenDialog('txt', 'GTI File depth (*.txt)|*.txt', 'Gti time-depth.txt file',
   function (FileName: string): TdtglDataSet
   begin
     var s := UserDateTimeFormat.Caption.Replace('&','');
     if s = 'UserDateTimeFormat...' then s := '';
     Result := TTimeDepthTxtDataSet.Create(Self, FileName, s, mClearTmp.Checked);
   end);
end;

procedure TFormMain.NDelJumpsClick(Sender: TObject);
begin
  var a := [DjFlt.Shit.ToString, DjFlt.Time.ToString];
  if Vcl.Dialogs.InputQuery('Del Jumps Filter Setup',['Min Shift(m)','Max Time(min)'], a) then
   begin
    DjFlt.Shit := a[0].ToDouble;
    DjFlt.Time := a[1].ToDouble;
   end;
end;

function TFormMain.GetFrameTime: Double;
begin
  Result := 2.097152 / 3600 / 24;
  for var m in NFrameTime do if m.Checked then
   begin
    var s := m.Caption.Replace('&','');
    exit(s.ToDouble / 3600 / 24);
   end;
end;

function TFormMain.GetLasDatetimeMnem: string;
begin
  Result := 'nop';
  for var m in NLasDT do if m.Checked then exit(m.Caption.Split([':'])[0]);
end;

function TFormMain.GetLasDeptMnem(root: TMenuItem): string;
begin
  Result := 'nop';
  for var m in root do if m.Checked then exit((m.Caption.Split([':'])[0]).Replace('&',''));
end;

procedure TFormMain.Opeb1Click(Sender: TObject);
begin
  InnerGTIOpenDialog('las', 'LAS File (*.las)|*.las', 'Gti DateTime-depth.Las file',
   function (FileName: string): TdtglDataSet
   begin
     Result := TdtLasDataSet.Create(Self, FileName, GetLasDatetimeMnem,'', GetLasDeptMnem(NLasDepth), mClearTmp.Checked);
   end);
end;

procedure TFormMain.ppRemoveArreaClick(Sender: TObject);
begin
  //ppRemoveArrea.Visible := False;
  ppm.AutoPopup := False;
  if Series4.YValues.Count = 0 then Exit;
  if MouseDown.Y > Series4.YValues[0] then
   begin
     for var i := 0 to High(x) do
      if x[i] >= MouseDown.X then
       begin
        var j := i;
        while (y[j] > Series4.YValues[0]) and (j >= 0) do
         begin
           y[j] := Series4.YValues[0];
           Dec(j);
         end;
        j := i+1;
        while (y[j] > Series4.YValues[0]) and (j <= High(x)) do
         begin
           y[j] := Series4.YValues[0];
           Inc(j);
         end;
         Break;
       end;
   end
   else
    begin
     for var i := 0 to High(x) do
      if x[i] >= MouseDown.X then
       begin
        var j := i;
        while (y[j] < Series4.YValues[0]) and (j >= 0) do
         begin
           y[j] := Series4.YValues[0];
           Dec(j);
         end;
        j := i+1;
        while (y[j] < Series4.YValues[0]) and (j <= High(x)) do
         begin
           y[j] := Series4.YValues[0];
           Inc(j);
         end;
         Break;
       end;
    end;
    Series4.Clear;
    Series5.Clear;
    FillFilterSeries();
end;

procedure TFormMain.Setup1Click(Sender: TObject);
begin
  var t := InputBox('Input time discretesation', 'Time (s)', '8.000');
  TMenuItem(Sender).Caption := t;
end;

procedure TFormMain.t2md1Click(Sender: TObject);
begin
  InnerGTIOpenDialog('t2md', 'XML File (*.t2md)|*.t2md', 'Gti DateTime-depth.XML file',
   function (FileName: string): TdtglDataSet
   begin
     var r := TdtXMLDataSet.Create(Self, FileName,'Data', 'time', 'md', mClearTmp.Checked);
     r.AddingDays := 25569;
     Exit(r);
   end);
end;

procedure TFormMain.UserDateTimeFormatClick(Sender: TObject);
begin
  var t := InputBox('Input Date Time format', 'Date Time', 'dd.mm.yyyy hh:nn:ss');
  TMenuItem(Sender).Caption := t;
end;

end.
