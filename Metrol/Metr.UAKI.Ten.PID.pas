unit Metr.UAKI.Ten.PID;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,  System.StrUtils,

  TeEngine, Series, TeeProcs, Chart, PID,

  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, UakiIntf, RootImpl, Vcl.Mask,
  JvExMask, JvToolEdit,
  Xml.XMLIntf, tools, Vcl.Buttons;

type
  TPIDdata = record
    time: TDateTime;
    pw,tten,tinc: Double;
    function asPidPoint: TPidPoint;
  end;

  TFormPIDsetup = class(TCustomFontIForm)
    Timer: TTimer;
    Panel1: TPanel;
    odr: TJvFilenameEdit;
    edT: TEdit;
    btStart: TButton;
    lbTincl: TLabel;
    lbPower: TLabel;
    lbT: TLabel;
    Label6: TLabel;
    Label5: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edKp: TEdit;
    Label7: TLabel;
    edKi: TEdit;
    Label8: TLabel;
    edKd: TEdit;
    Chart: TChart;
    srsPower: TLineSeries;
    srsTten: TLineSeries;
    srsTincl: TLineSeries;
    Find: TButton;
    srsFind: TPointSeries;
    edFrom: TEdit;
    edTo: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    edDk: TEdit;
    Label11: TLabel;
    srsDD: TLineSeries;
    srsResampl: TLineSeries;
    Label12: TLabel;
    edSred: TEdit;
    Label13: TLabel;
    edSredY: TEdit;
    srsdY: TLineSeries;
    srsResZ: TLineSeries;
    edInt: TEdit;
    Label2: TLabel;
    edIntPID: TEdit;
    Label1: TLabel;
    btStartPID: TButton;
    btStopPID: TButton;
    Label14: TLabel;
    edUstT: TEdit;
    Label15: TLabel;
    odw: TJvFilenameEdit;
    TimerPID: TTimer;
    Find2: TButton;
    Find3: TButton;
    Find4: TButton;
    FindCoon: TButton;
    sbStart: TSpeedButton;
    procedure btStartClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edIntChange(Sender: TObject);
    procedure FindClick(Sender: TObject);
    procedure btStartPIDClick(Sender: TObject);
    procedure btStopPIDClick(Sender: TObject);
    procedure odwAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure TimerPIDTimer(Sender: TObject);
    procedure edUstTKeyPress(Sender: TObject; var Key: Char);
    procedure sbStartClick(Sender: TObject);
  private
    Fpid: Tpid;
    FlagFindPw: Boolean;
    pwOff, pwOnn, Stab: TPIDdata;
    Fdat: TArray<TPIDdata>;
    Ftime: TArray<Double>;
    Ftinc: TArray<Double>;
    Ftime_resample: TArray<Double>;
    Ftinc_resample: TArray<Double>;
    FddTime: TArray<Double>;
    FdY: TArray<Double>;
    Fzinger: TArray<Double>;
    Ftinc0: Double;
    FStream: TStreamWriter;
    FTempNode: IXMLNode;
    FC_TenUpdate: Integer;
    FBinded: Boolean;
    procedure SetTenTower(pw: Double);
    procedure UpdetePIDControl(Ena: Boolean);
    function GetUaki: IUaki;
    procedure SetC_TenUpdate(const Value: Integer);
    procedure UpdateScreen;
    procedure UpdateChart(const FileName: string);
    function GetInclinT: Double;
    procedure CreateWriter(const fileName: string);
  protected
    FlagStart: Boolean;
    procedure Loaded; override;
   const
    NICON = 273;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('УАК-СИ-PID-setup', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    property Uaki: IUaki read GetUaki;
    property InclinT: Double read GetInclinT;
    property C_TenUpdate: Integer read FC_TenUpdate write SetC_TenUpdate;
  end;

//var
//  FormPIDsetup: TFormPIDsetup;

implementation

uses PatchCart;

{$R *.dfm}

{ TFormPIDsetup }

procedure TFormPIDsetup.SetTenTower(pw: Double);
 var
  v: IUaki;
begin
  v := Uaki;
  var t := Round(pw);
  if t > 0 then
    begin
     // btStart.Caption := 'Stop';
      v.TenPower[0] := t;
      v.TenPower[1] := t;
      v.TenPower[2] := t;
      v.TenStart;
    end
   else
    begin
     // btStart.Caption := 'Start';
      v.TenPower[0] := 0;
      v.TenPower[1] := 0;
      v.TenPower[2] := 0;
      v.TenStop;
    end;
end;

procedure TFormPIDsetup.sbStartClick(Sender: TObject);
begin
  FlagStart := sbStart.Down;
end;

procedure TFormPIDsetup.btStartClick(Sender: TObject);
begin
  SetTenTower(StrToFloat(edT.Text));
end;

procedure TFormPIDsetup.TimerTimer(Sender: TObject);
 var
  pw, tinc, tten: Double;
  Time: Double;
begin
   var v := Uaki;
   if Length(v.Temperature) > 0 then tten := v.Temperature[2]
   else tten := -0.0;
   Time := Frac(Now);
   pw := v.TenPower[0];
   tinc := InclinT;
   srsPower.AddXY(Time*24, pw);
   srsTten.AddXY(Time*24, tten);
   srsTincl.AddXY(Time*24, tinc);
   if Assigned(FStream) and FlagStart then FStream.WriteLine(Format('%s;%f;%f;%f',[TimeToStr(Time), pw, tten, tinc]));
end;

procedure TFormPIDsetup.UpdetePIDControl(Ena: Boolean);
begin
  Find.Enabled := Ena;
  Find2.Enabled := Ena;
  Find3.Enabled := Ena;
  Find4.Enabled := Ena;
  FindCoon.Enabled := Ena;
  edDk.Enabled := Ena;
  edSred.Enabled := Ena;
  edSredY.Enabled := Ena;
  edKp.Enabled := Ena;
  edKd.Enabled := Ena;
  edKi.Enabled := Ena;
  edIntPID.Enabled := Ena;
 // edUstT.Enabled := Ena;
  edT.Enabled := Ena;
  btStart.Enabled := Ena;
  btStartPID.Enabled := Ena;
  btStopPID.Enabled := not Ena;
end;

procedure TFormPIDsetup.btStartPIDClick(Sender: TObject);
begin
  var IntMin := StrToFloat(edIntPID.Text);//min
  TimerPID.Interval := Round(IntMin*60*1000);//ms
  UpdetePIDControl(False);
  Fpid := Tpid.Create(StrToFloat(edKp.Text), StrToFloat(edKi.Text), StrToFloat(edKd.Text),
                       IntMin/60{час}, Uaki.TenPower[0]);
  Fpid.Setpoint := StrToFloat(edUstT.Text);
  TimerPID.Enabled := True;
end;

procedure TFormPIDsetup.TimerPIDTimer(Sender: TObject);
begin
  Fpid.Run(InclinT);
  edT.Text := Round(Fpid.output).ToString;
  SetTenTower(Fpid.output);
end;

procedure TFormPIDsetup.btStopPIDClick(Sender: TObject);
begin
  TimerPID.Enabled := False;
  UpdetePIDControl(True);
  if Assigned(Fpid) then FreeAndNil(Fpid);
end;

class function TFormPIDsetup.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormPIDsetup.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUakiPIDSetupForm');
end;

procedure TFormPIDsetup.edIntChange(Sender: TObject);
begin
  var t := StrToIntDef(edInt.Text,0);
  if t >= 1000 then Timer.Interval := t;
end;

procedure TFormPIDsetup.edUstTKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #$D then
   begin
    Key := #0;
    if Assigned(Fpid) then Fpid.Setpoint := StrToFloat(edUstT.Text);
   end;
end;

procedure TFormPIDsetup.FindClick(Sender: TObject);
 var
  r: TStreamReader;
  w: TStreamWriter;
  p: TPIDdata;
  opw, otinc: Double;
  Ffirst: Boolean;
  y,x: array [0..8] of Double;
begin
// if Assigned(FStream) then
 // begin
 //  FreeAndNil(FStream);
   SetLength(Fdat, 0);
   SetLength(Ftime, 0);
   SetLength(Ftinc, 0);
   opw := -10000;
   otinc:= -10000;
   Ffirst:= True;
   FlagFindPw := True;
   srsFind.Clear;
   UpdateChart(odr.FileName);
    r := TStreamReader.Create(odr.FileName, TEncoding.UTF8);
    w := TStreamWriter.Create(odr.FileName+'.csv');
    try
      repeat
       var s := r.ReadLine;
       var a := s.Split([';']);
       if Length(a) = 4 then
        begin
         p.time := StrToTime(a[0])*24;
         p.pw := a[1].ToDouble;
         p.tten := a[2].ToDouble;
         p.tinc := a[3].ToDouble;
         if (opw <> p.pw) or (otinc<>p.tinc) then
          begin
           w.WriteLine(s);
           otinc := p.tinc;
           opw := p.pw;
           Fdat := Fdat + [p];
          // if (p.time >= StrToFloat(edFrom.Text)) and (p.time <= StrToFloat(edTo.Text)) then
            begin
             if Ffirst then
              begin
               Ffirst := False;
               Ftinc0 := p.tinc;
               pwOff := p;
               Stab := p;
              end;
             Ftime := Ftime + [p.time];
             Ftinc := Ftinc + [p.tinc];
            end;

           srsFind.AddXY(p.time,p.tinc);
          end;

          if Stab.tinc < p.tinc then Stab := p;

          if FlagFindPw then
           if pwOff.pw = p.pw then pwOff := p
           else
            begin
             pwOnn := p;
             FlagFindPw := False;
            end;

        end;
      until r.EndOfStream;
    finally
      r.Free;
      w.Free;
    end;

    const DELTA_TIME = 0.01;
    const SCALE_DD = 0.5;
    const SCALE_D = 1;
    var N := -(Ftime[0] - Ftime[High(Ftime)]) / DELTA_TIME;
    SetLength(Ftime_resample, Trunc(N));
   for var i := 0 to High(Ftime_resample) do Ftime_resample[i] := Ftime[0] + i*DELTA_TIME;

   Resample(Ftime, Ftinc, Ftime_resample, Ftinc_resample);

   srsResampl.Clear;
   srsResampl.AddArray(Ftime_resample, Ftinc_resample);

    var dk :=StrToInt(edDk.Text);
    var serdDD := StrToInt(edSred.Text);
    var serdY := StrToInt(edSredY.Text);
    ddY(Ftinc_resample, DELTA_TIME, SCALE_DD, dk, serdDD, serdY, FddTime);

    srsDD.Clear;
    srsDD.AddArray(Ftime_resample, FddTime);

    ddY(Ftinc_resample, DELTA_TIME, SCALE_D, dk, serdDD, serdY, FdY, True);

    srsDy.Clear;
    srsDy.AddArray(Ftime_resample, FdY);

    var kp, ki, kd: Double;

    SetLength(Fzinger, 0);

    if Sender = Find then PID_ZieglerNichols(Ftime_resample, Ftinc_resample, FdY, FddTime, SCALE_D, SCALE_DD,
    pwOff.asPidPoint, pwOnn.asPidPoint, Stab.asPidPoint,
    Fzinger, kp, ki, kd)

    else if Sender = Find3 then PID_ZieglerNichols(Ftime_resample, Ftinc_resample, FdY, FddTime, SCALE_D, SCALE_DD,
    pwOff.asPidPoint, pwOnn.asPidPoint, Stab.asPidPoint,
    Fzinger, kp, ki, kd, true)

    else if Sender = Find4 then PID_CohenCoon(Ftime_resample, Ftinc_resample, FdY, FddTime, SCALE_D, SCALE_DD,
    pwOff.asPidPoint, pwOnn.asPidPoint, Stab.asPidPoint,
    Fzinger, kp, ki, kd, lambda)

    else if Sender = FindCoon then PID_CohenCoon(Ftime_resample, Ftinc_resample, FdY, FddTime, SCALE_D, SCALE_DD,
    pwOff.asPidPoint, pwOnn.asPidPoint, Stab.asPidPoint,
    Fzinger, kp, ki, kd, coon)

    else PID_CohenCoon(Ftime_resample, Ftinc_resample, FdY, FddTime, SCALE_D, SCALE_DD,
    pwOff.asPidPoint, pwOnn.asPidPoint, Stab.asPidPoint,
    Fzinger, kp, ki, kd);

    edKp.Text := kp.ToString(ffGeneral,3,7);
    edKi.Text := ki.ToString(ffGeneral,3,7);
    edKd.Text := kd.ToString(ffGeneral,3,7);

    srsResZ.Clear;
    srsResZ.AddArray(Ftime_resample, Fzinger);

    //CreateWriter(odw.FileName);
 // end;
end;

procedure TFormPIDsetup.FormDestroy(Sender: TObject);
begin
  if Assigned(FStream) then FreeAndNil(FStream);
end;

function TFormPIDsetup.GetInclinT: Double;
begin
  if not Assigned(FTempNode) then
   begin
    for var n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
     if {(n.Attributes[AT_ADDR] = 3) and} TryGetX(n,'WRK.Inclin.T.DEV', FTempNode, AT_VALUE) then
       Break;
   end;
   if Assigned(FTempNode) then
     Result := Double(FTempNode.NodeValue)
   else
     Result := 0;
end;

function TFormPIDsetup.GetUaki: IUaki;
 var
  de: IDeviceEnum;
  d: IDevice;
begin
  Result := nil;
  if Supports(GlobalCore, IDeviceEnum, de) then
    for d in de.Enum() do if Supports(d, IUaki, Result) then
     begin
      if not FBinded then
       begin
        Bind('C_TenUpdate', d, ['S_TenUpdate']);
        FBinded := True;
       end;
      Exit(d as IUaki);
     end;
   raise ENeedDialogException.Create('УАКСИ не найдено !');
end;

procedure TFormPIDsetup.Loaded;
begin
  inherited;
  CreateWriter(odw.FileName);
  UpdateScreen;

//    SetLength(FddTime, 0);
//    srsDD.Clear;
//
//    SetLength(Ftinc,101);
//    SetLength(Ftime,101);
//    for var I := 0 to 100 do
//     begin
//       Ftime[i]:= i-50;
//       Ftinc[i]:= (Ftime[i]*Ftime[i]*Ftime[i])/6;
//     end;
//
//    for var I := 4 to 100-5 do
//     begin
//       var ddy := dir2xy9(@Ftinc[i-4], @Ftime[i-4]);
//       FddTime := FddTime + [ddy];
//       srsDD.AddXY(Ftime[i], ddy);
//     end;
  PatchTeeCart(chart);

end;

procedure TFormPIDsetup.odwAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
  CreateWriter(AName);
end;

procedure TFormPIDsetup.CreateWriter(const fileName: string);
begin
  if fileName <> '' then
   begin
    if Assigned(FStream) then FreeAndNil(FStream);
    try
     UpdateChart(fileName);
    finally
     FStream := TStreamWriter.Create(fileName, True, TEncoding.UTF8);
    end;
   end;
end;

procedure TFormPIDsetup.SetC_TenUpdate(const Value: Integer);
begin
  FC_TenUpdate := Value;
  UpdateScreen;
end;


procedure TFormPIDsetup.UpdateChart(const FileName: string);
 var
  r: TStreamReader;
  Time,pw,tinc,tten: Double;
begin
  srsPower.Clear;
  srsTten.Clear;
  srsTincl.Clear;
  if not fileExists(FileName) then Exit;
  r := TStreamReader.Create(FileName, TEncoding.UTF8);
  try
    repeat
     var a := r.ReadLine.Split([';']);
     if Length(a) = 4 then
      begin
       Time := StrToTime(a[0])*24;
       pw := a[1].ToDouble;
       tten := a[2].ToDouble;
       tinc := a[3].ToDouble;
       srsPower.AddXY(Time, pw);
       srsTten.AddXY(Time, tten);
       srsTincl.AddXY(Time, tinc);
      end;
    until r.EndOfStream;
  finally
    r.Free;
  end;
end;

procedure TFormPIDsetup.UpdateScreen;
 var
  v: IUaki;
begin
  v := Uaki;
  lbT.Caption := '';
  for var a in uaki.Temperature do lbT.Caption := lbT.Caption + Format('%6.2f ',[a]);
  lbPower.Caption := Format('%-6d %-6d %-6d',[v.TenPower[0],v.TenPower[1],v.TenPower[2]]);
  lbTincl.Caption := InclinT.ToString(ffFixed, 6, 2);
end;


{ TPIDdata }

function TPIDdata.asPidPoint: TPidPoint;
begin
  Result.time := time;
  Result.inp := pw;
  Result.outp := tinc;
end;

initialization
  RegisterClass(TFormPIDsetup);
  TRegister.AddType<TFormPIDsetup, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormPIDsetup>;
end.
