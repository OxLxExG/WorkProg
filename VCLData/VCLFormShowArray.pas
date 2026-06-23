unit VCLFormShowArray;

interface

uses  DeviceIntf, PluginAPI, ExtendIntf, RootImpl, debug_except, DockIForm, RootIntf, Container, Actns, GR32_VectorUtils,
  Vcl.Menus, System.Generics.Collections,  JDtools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, TeEngine, Series, Vcl.ExtCtrls, TeeProcs, Chart;

type
  TFormShowArray = class;
  TZSeries = class(TLineSeries)
  protected
    procedure Loaded; override;
  public
    FsaForm: TFormShowArray;
    FLenArray: Integer;
    FLineCount: Integer;
    FclR, FclG, FclB: Byte;
    class function New(ASaForm: TFormShowArray; const ATitle: string): TZSeries;
    procedure AddZArray(const AArray: string);
    procedure UpdateDept(deptcnt: Integer);
  end;

  TFormShowArray = class(TDockIForm)
    ChartCode: TChart;
    procedure ChartCodeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  private
    FDataDevice: string;
    FBindWorkRes: TWorkEventRes;
    FXMLPath: string;
    N3DMenu: TMenuItem;
    NZoomMenu: TMenuItem;
    FDept: Integer;
    FProcX: Integer;
    FProcY: Integer;
    procedure SetBindWorkRes(const Value: TWorkEventRes);
    procedure SetRemoveDevice(const Value: string);
    function SetBind: IDevice;
    procedure UpdateLegend(Root: IXMLNode);
    procedure NPropClick(Sender: TObject);
    procedure NZoomClick(Sender: TObject);
    procedure NSaveToFileClick(Sender: TObject);
    procedure SetD3View(const Value: boolean);
    function GetD3View: boolean;
    procedure SetDept(const Value: Integer);
    function GetLegend: boolean;
    procedure SetLegend(const Value: boolean);
  protected
    procedure InitializeNewForm; override;
    procedure Loaded; override;
  public
    FVX, FVY: Double;
    clR, clG, clB: Byte;
    procedure UpdateVXY;
    destructor Destroy; override;
    class procedure Execute(Addr: Integer; const ADataDevice, AXMLPath: string);
    property C_BindWorkRes: TWorkEventRes read FBindWorkRes write SetBindWorkRes;
    property C_RemoveDevice: string read FDataDevice write SetRemoveDevice;
  published
    property DataDevice: string read FDataDevice write FDataDevice;
    property XMLPath: string read FXMLPath write FXMLPath;
    [ShowProp('Legend')] property Legend: boolean read GetLegend write SetLegend;
    [ShowProp('3D View')] property D3View: boolean read GetD3View write SetD3View;
    [ShowProp('Depth')] property Dept: Integer read FDept write SetDept default 10;
    [ShowProp('Shift by X %')] property ProcX: Integer read FProcX write FProcX default 10;
    [ShowProp('Shift by Y %')] property ProcY: Integer read FProcY write FProcY default 30;
  end;

implementation

{$R *.dfm}

uses tools, Parser, math;


procedure PatchTeeCart(c: TChart);
 procedure Axcolor(a: TChartAxis);
 begin
    a.Axis.Color := clThWindowTextDisabled;          // Цвет самой линии оси
    a.Ticks.Color := clThWindowTextDisabled;         // Цвет основных делений
    a.LabelsFont.Color := clThWindowTextDisabled;   // Цвет текста подписей
    a.Title.Font.Color := clThWindowTextDisabled;//    Painter.BackgroundColor := clThBkg;
    a.Grid.Color := clThBorder;
 end;
begin
  if CurrentThemeIsDark then
   begin
    C.Color := clThBkg;
    Axcolor(C.Axes.Bottom);
    Axcolor(C.Axes.Left);
    C.Legend.Color := clThBorder;
    C.Legend.Font.Color := clThWindowTextNormal;
    C.Legend.Frame.Color := clThWindowTextDisabled;
    C.Legend.Gradient.Visible := False;
   end;
end;


{ TFormShowArray }

function TFormShowArray.SetBind: IDevice;
 var
  de: IDeviceEnum;
begin
  if FDataDevice = '' then Exit;
  Result := nil;
  if Supports(GlobalCore, IDeviceEnum, de) then
   begin
    Bind('C_RemoveDevice', de, ['S_BeforeRemove']);
    Result := de.Get(FDataDevice);
    if Assigned(Result) then Bind('C_BindWorkRes',Result, ['S_WorkEventInfo']);
   end;
end;

procedure TFormShowArray.ChartCodeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
 var
  s: TChartSeries;
  SeriesIndex: Integer;
begin
  for s in ChartCode.SeriesList do
   begin
    SeriesIndex := s.Clicked(X, Y);
    ChartCode.ShowHint := SeriesIndex <> -1;
    if ChartCode.ShowHint then
     ChartCode.Hint:='X='+FormatFloat('#.00',s.XScreenToValue(X)) +' Y='+FormatFloat('#.00',s.YScreenToValue(y)) + ' : '+s.ValueMarkText[SeriesIndex+1];
   end;
end;

destructor TFormShowArray.Destroy;
begin
  inherited;
end;

class procedure TFormShowArray.Execute(Addr: Integer; const ADataDevice, AXMLPath: string);
 var
  f: TFormShowArray;
  d: IDevice;
begin
  f := CreateUser();
  (GContainer as IFormEnum).Add(f as Iform);
  f.DataDevice := ADataDevice;
  f.XMLPath := AXMLPath;
  f.Caption := AXMLPath;
  d := f.SetBind;
  f.UpdateLegend(FindWork((d as IDataDevice).GetMetaData.Info, Addr));// d.Addrs[0]));
  f.IShow;
end;

function TFormShowArray.GetD3View: boolean;
begin
  Result := N3DMenu.Checked
end;

function TFormShowArray.GetLegend: boolean;
begin
  Result := ChartCode.Legend.Visible;
end;

procedure TFormShowArray.InitializeNewForm;
begin
  inherited;
  NZoomMenu := AddToNCMenu('Zoom Allow', NZoomClick, 0, 2);
  N3DMenu := AddToNCMenu('3D View', nil, 0, 2);
  AddToNCMenu('Properties...', NPropClick, 0);
  AddToNCMenu('Save to file...', NSaveToFileClick);
  FDept := 10;
  FVX := 1;
  FVY := 1;
  FProcX := 10;
  FProcY := 30;
end;

procedure TFormShowArray.Loaded;
 var
  s: TChartSeries;
  cl: TColor;
begin
  inherited;
  PatchTeeCart(ChartCode);
  cl := ColorToRGB(ChartCode.Color);
  clR := GetRValue(cl);
  clG := GetGValue(cl);
  clB := GetBValue(cl);
  for s in ChartCode.SeriesList do TZSeries(s).FsaForm := Self;
  SetBind;
end;

procedure TFormShowArray.NPropClick(Sender: TObject);
 var
  d: IDialog;
begin
  if RegisterDialog.TryGet<Dialog_EditViewParameters>(d) then (d as IDialog<TFormShowArray>).Execute(Self);
end;

type
 Tdatrec = record
   nam: string;
   dat: TArray<string>;
   constructor Create(const anam: string; const adat :string);
 end;

constructor Tdatrec.Create(const anam, adat: string);
begin
  nam := anam;
  dat := adat.Split([' '], TStringSplitOptions.ExcludeEmpty);
end;


procedure TFormShowArray.NSaveToFileClick(Sender: TObject);
 var
  ass: TArray<Tdatrec>;
  fs: TFormatSettings;
  function AssLen: Integer;
   var
    i: Tdatrec;
  begin
    Result := Length(ass[0].dat);
    for i in ass do Result := Min(Result, Length(i.Dat));
  end;
  function CreateTitle: string;
   var
    i: Tdatrec;
  begin
    Result := 'Index';
    for i in ass do Result := Result+';'+i.nam;
  end;
  function GetS(idx: Integer): TArray<string>;
   var
    i: Tdatrec;
  begin
    Result := [];
    for i in ass do Result := Result + [StrToFloat(i.Dat[idx]).ToString(fs)];
  end;
 var
  n: IXMLNode;
  s: TChartSeries;
  i: Integer;
  ss: TStrings;
  //dsold: Char;
begin
  with TSaveDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   DefaultExt := 'csv';
   Options := Options + [ofOverwritePrompt, ofPathMustExist];
   Filter := 'File (*.csv)|*.csv';
   if Execute(Handle) then
    begin
     for s in ChartCode.SeriesList do
       if TryGetX(FBindWorkRes.Work, s.Title+'.'+T_DEV, n, AT_VALUE)
         and (n.NodeValue <> null)
           and (n.NodeValue <> '') then ass := ass + [Tdatrec.Create(s.Title, n.NodeValue)];
     ss := TStringList.Create;
     fs := FormatSettings;
     fs.DecimalSeparator := (GlobalCore as Iproject).DecimalSeparator;
     try
      ss.Add(CreateTitle);
      for i := 0 to AssLen-1 do ss.Add(i.ToString+';'+string.Join(';', GetS(i)));
      ss.SaveToFile(FileName);
     finally
      ss.Free;
     end;
    end;
  finally
   Free;
  end;
end;

procedure TFormShowArray.NZoomClick(Sender: TObject);
begin
   ChartCode.AllowZoom := NZoomMenu.Checked;
end;

procedure TFormShowArray.SetBindWorkRes(const Value: TWorkEventRes);
 var
  n: IXMLNode;
  s: TChartSeries;
begin
  FBindWorkRes := Value;
  for s in ChartCode.SeriesList do s.BeginUpdate;
  try
   for s in ChartCode.SeriesList do
     if TryGetX(FBindWorkRes.Work, s.Title+'.'+T_DEV, n, AT_VALUE)
       and (n.NodeValue <> null)
         and (n.NodeValue <> '') then TZSeries(s).AddZArray(n.NodeValue);
  finally
   for s in ChartCode.SeriesList do s.EndUpdate;
  end;
  UpdateVXY;
end;

procedure TFormShowArray.SetD3View(const Value: boolean);
begin
  N3DMenu.Checked := Value;
end;

procedure TFormShowArray.SetDept(const Value: Integer);
 var
  s: TChartSeries;
begin
  FDept := Value;
  if csLoading in ComponentState then Exit;
  for s in ChartCode.SeriesList do s.BeginUpdate;
  try
   for s in ChartCode.SeriesList do TZSeries(s).UpdateDept(Value);
  finally
   for s in ChartCode.SeriesList do s.EndUpdate;
  end;
end;

procedure TFormShowArray.SetLegend(const Value: boolean);
begin
  if Assigned(ChartCode) then
    ChartCode.Legend.Visible := not ChartCode.Legend.Visible;
end;

procedure TFormShowArray.SetRemoveDevice(const Value: string);
begin
  if DataDevice = Value then
   begin
    (GContainer as IMainScreen).Changed;
    (GlobalCore as IFormEnum).Remove(Self as Iform);
   end;
end;

procedure TFormShowArray.UpdateLegend(Root: IXMLNode);
 var
  X: IXMLNode;
begin
  if TryGetX(root, XMLPath, X) then ExecXTree(X, procedure (n: IXMLNode)
  begin
    if n.HasAttribute(AT_ARRAY) then TZSeries.New(Self, GetPathXNode(n, True));
  end);
end;

procedure TFormShowArray.UpdateVXY;
 var
  dx, dy: double;
begin
  if ChartCode.Axes.Left.Items.Count >=2 then
    dy := Abs(ChartCode.Axes.Left.Items[1].Value - ChartCode.Axes.Left.Items[0].Value)
  else
    dy := 1;
  if ChartCode.Axes.Bottom.Items.Count >=2 then
    dx := Abs(ChartCode.Axes.Bottom.Items[1].Value - ChartCode.Axes.Bottom.Items[0].Value)
  else
    dx := 1;
  FVY := dy * (FProcY)/100;
  FVX := dx * (FProcX)/100;
end;

{ TZSeries }

procedure TZSeries.AddZArray(const AArray: string);
 var
  a: TArray<Double>;
  i,j,ccnt: Integer;
  c: TColor;
  function DecColor(n, dep: Integer): TColor;
   var
    r, g, b: Byte;
  begin
    r := FsaForm.clR + MulDiv(n, FclR - FsaForm.clR, dep);
    g := FsaForm.clG + MulDiv(n, FclG - FsaForm.clG, dep);
    b := FsaForm.clB + MulDiv(n, FclB - FsaForm.clB, dep);
    Result := RGB(r, g, b);
  end;
begin
  a := TPars.ArrayStrToArray(AArray);
  FLenArray := Length(a)+1;
  if FsaForm.D3View then
   begin
    UpdateDept(FsaForm.Dept-1);
    for I := 0 to Count-1 do
     begin
      XValue[i] := XValue[i] + FsaForm.FVX;
      YValue[i] := YValue[i] + FsaForm.FVY;
     end;
    ccnt := (Count div FLenArray);
    for I := 0 to ccnt-1 do
     begin
      c := DecColor(i+1, ccnt);
      for j := i*FLenArray to i*FLenArray+FLenArray-1-1 do ValueColor[j] := c;
//      ColorRange(ValuesList[0], i*FLenArray, FLenArray-1, c);
     end;
   end
  else
   begin
    Clear;
    FLineCount := 0;
   end;
  for i := 0 to FLenArray-2 do AddXY(i, a[i]);
  AddNullXY(0,0);
  Inc(FLineCount);
end;

procedure TZSeries.Loaded;
 var
  cl: TColor;
begin
  inherited;
  cl := ColorToRGB(Color);
  FclR := GetRValue(cl);
  FclG := GetGValue(cl);
  FclB := GetBValue(cl);
end;

class function TZSeries.New(ASaForm: TFormShowArray; const ATitle: string): TZSeries;
begin
  Result := TZSeries(ASaForm.ChartCode.AddSeries(TZSeries));
  with Result do
   begin
    FsaForm := ASaForm;
    Title := ATitle;
    XValues.Order := TChartListOrder.loNone;
    TreatNulls := tnDontPaint;
   end;
end;

procedure TZSeries.UpdateDept(deptcnt: Integer);
begin
  while FLineCount > deptcnt do
   begin
    Delete(0, FLenArray);
    Dec(FLineCount);
   end;
end;

{ Tdatrec }

initialization
  RegisterClasses([TFormShowArray, TZSeries]);
  TRegister.AddType<TFormShowArray, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormShowArray>;
end.
