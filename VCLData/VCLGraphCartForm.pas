unit VCLGraphCartForm;

interface

uses Container, ExtendIntf, Actns, tools, DeviceIntf, PluginAPI,  debug_except, Parser, VCL.CustomDataForm, DockIForm,

  Xml.XMLIntf,  math,  themes,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Series, Vcl.Menus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RootImpl, CustomPlot, TeEngine, TeeProcs, Chart, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.ComCtrls;



 {$IFDEF ENG_VERSION}
  const
   C_CaptCartForm ='Cart chart';
   C_MenuView ='Visualization windows';
   C_Memu_Show='Show';
{$ELSE}
  const
   C_CaptCartForm ='График Картографа';
   C_MenuView ='Окна визуализации';
   C_Memu_Show='Показать';
{$ENDIF}

  METROL_MESSAGE = WM_APP + 100;
  METROL_SAVE_MESSAGE = WM_APP + 101;
  METROL_SAVE_OK_MESSAGE = WM_APP + 102;

  SCALES_CHART: array[0..3] of Double = (1.0, 57295.7795130823, 1.0, 57295.7795130823);

type
  PCartRecEmpty = ^TCartRecEmpty;
  TCartRecEmpty = packed record
    adr: byte;
    len: Word;
  end;

  CrtModes = (cmNone, cmInduc, cmCart);

  TCartAction = class(TICustomAction);
  TGraphCartForm = class(TCustomFormData)
    Panel: TPanel;
    Chart0: TChart;
    Splitter2: TSplitter;
    Chart2: TChart;
    Splitter1: TSplitter;
    Chart1: TChart;
    Chart3: TChart;
    Splitter3: TSplitter;
    Splitter0: TSplitter;
    cb400R: TCheckBox;
    cb400F: TCheckBox;
    cb2000R: TCheckBox;
    cb2000F: TCheckBox;
    brEq: TButton;
    btClr: TButton;
    btZero: TButton;
    btMetr: TButton;
    StatusBar: TStatusBar;
    procedure cbClick(Sender: TObject);
    procedure brEqClick(Sender: TObject);
    procedure btClrClick(Sender: TObject);
    procedure btZeroClick(Sender: TObject);
    procedure btMetrClick(Sender: TObject);
    procedure btMertrSaveClick(Sender: TObject);
  private
    FBindWorkRes: TWorkEventRes;
    dummis: string;
    FCondition: Integer;
    Idx1,Idx2: integer;
    FMode: CrtModes;
    Ftags: Tarray<IXmlNode>;
    FchannelsCnt: integer;
    FMetrol: TArray<byte>;
    FMetrSave: TMenuItem;
    procedure NMetrEnableClick(Sender: TObject);
    procedure NMetrSaveClick(Sender: TObject);
    procedure cmd13MetrLoad(msg: UINT);
    procedure cmd12MetrSave(mtr: Pbyte; n: Integer);
    procedure MetrolMessage(var Msg: TMessage); message METROL_MESSAGE;
    procedure MetrolSaveMessage(var Msg: TMessage); message METROL_SAVE_MESSAGE;
    procedure MetrolSaveOKMessage(var Msg: TMessage); message METROL_SAVE_OK_MESSAGE;
    procedure SetDestroy(const Value: string);
    function GetCA: TArray<TChart>;
    function GetCS: TArray<TSplitter>;
    type
      sInduc = (idxCond, idxR400, idxF400, idxR2000, idxF2000);
      sCart = (cdxCond, cdxFq, cdxR, cdxF);
      PInducTag = ^TInducTag;
      TInducTag = array [sInduc] of IXmlNode;
      PCartTag = ^TCartTag;
      TCartTag = array [sCart] of IXmlNode;
    const
     MAX_POINTS = 100;
     aInduc = [idxCond, idxR400, idxF400, idxR2000, idxF2000];
     aCart = [cdxFq, cdxR, cdxF];
     NICON = 137;
     INDUC_TAG: array [sInduc] of string  = ('состояние', 'УЭС_400kHz','симметризованные_фазы_400kHz','УЭС_2000kHz', 'симметризованные_фазы_2000kHz');
     CART_TAG: array [sCart] of string  = ('приемник_центральный', 'частота', 'УЭС','симметризованные_фазы');

    class var FShowAction: IAction;
    procedure SetBindWorkRes(const Value: TWorkEventRes);
    function InducTag: PInducTag;
    function CartTag: PCartTag;
    procedure UpdateMode;
    function GetDevice: IDevice;
    procedure UpdateChartHeight;
    class function TestTags(n:IXmlNode; const a: array of string; var tags: Tarray<IXmlNode>): boolean; static;
    class procedure CreateForm(Sender: TObject);
    class procedure DestroyForm();
    property CA: TArray<TChart> read GetCA;
    property CS: TArray<TSplitter> read GetCS;
  protected
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
  public
    [StaticAction(C_MenuView, C_Memu_Show, NICON, '0:'+C_Memu_Show,'',False,False,0,True, True)]
    class procedure DoUpdate(Sender: IAction);
    property C_BindWorkRes: TWorkEventRes read FBindWorkRes write SetBindWorkRes;
    property C_RemoveDevice: string read dummis write SetDestroy;
    property C_Project: string read dummis write SetDestroy;
  end;


implementation

{$R *.dfm}


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
    c.Title.Font.Color := ColorCorrect(clBlue);
    Axcolor(C.Axes.Bottom);
    Axcolor(C.Axes.Left);
    C.Legend.Color := clThBorder;
    C.Legend.Font.Color := clThWindowTextNormal;
    C.Legend.Frame.Color := clThWindowTextDisabled;
    C.Legend.Gradient.Visible := False;
   end;
end;

{ TGraphCartForm }

class function TGraphCartForm.TestTags(n: IXmlNode; const a: array of string; var tags: Tarray<IXmlNode>): boolean;
begin
  tags := [];
  for var t in a do
   begin
    var x: IXmlNode;
    if not FindInDevNode(n, T_WRK, t, x ) then exit(false);
    tags :=  tags + [x];
   end;
  Result := True;
end;

{$REGION 'манипулирование формой'}

class function TGraphCartForm.ClassIcon: Integer;
begin
   Result := NICON;
end;

class procedure TGraphCartForm.CreateForm(Sender: TObject);
 var
  gdf: TGraphCartForm;
begin
  var f := GetUniqueForm('GlobalGraphCartForm');
  gdf := TGraphCartForm(f);
  (GContainer as ITabFormProvider).Tab(f);
  (GContainer as IMainScreen).Changed;
  gdf.UpdateChartHeight;
end;

class procedure TGraphCartForm.DestroyForm;
 var
  ii: IInterface;
begin
  if GContainer.TryGetInstance('GlobalGraphCartForm', ii, false) then
   begin
    (GContainer as IMainScreen).Changed;
    (GlobalCore as IFormEnum).Remove(ii as Iform);
   end;
  if Assigned(FShowAction) then
   begin
    (GContainer as IActionProvider).HideInBar(0, TGraphCartForm.FShowAction);
    FShowAction := nil;
   end;
end;

class procedure TGraphCartForm.DoUpdate(Sender: IAction);
  function IsFindCart: boolean;
   var
    ts: Tarray<IXmlNode>;
  begin
    Result := False;
    for var n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
       if (n.Attributes[AT_ADDR] = 6) and (TestTags(n,  INDUC_TAG, ts) or TestTags(n,  CART_TAG,ts)) then Exit(true);
  end;
 var
  xa: TCartAction;
begin
  if IsFindCart then
   begin
    xa := TCartAction.CreateUser(ActionAttribute.Create(C_CaptCartForm, C_MenuView, NICON, '0:'+C_Memu_Show+'.'+C_MenuView+':0'));
    xa.OnExecute := CreateForm;
    FShowAction := xa as IAction;
    FShowAction.DefaultShow;
   end
  else if Assigned(FShowAction) then
   begin
    (GContainer as IActionProvider).HideInBar(0, TGraphCartForm.FShowAction);
    FShowAction := nil;
   end;
end;

procedure TGraphCartForm.SetDestroy(const Value: string);
begin
  DestroyForm();
end;

{$ENDREGION 'манипулирование формой'}


function TGraphCartForm.GetDevice: IDevice;
begin
  if Fmode <> cmNone then
   begin
    var n := Ftags[0];
    while Assigned(n) do
     begin
      var s := n.NodeName;
      if s.Contains('DeviceBur') then exit((GlobalCore as IDeviceEnum).Get(s));
      n := n.ParentNode;
     end;
   end;
  Result := nil;
end;

procedure TGraphCartForm.cmd12MetrSave(mtr: Pbyte; n: Integer);
 var
  d: ILowLevelDeviceIO;
  a: Tarray<Byte>;
begin
  d := GetDevice as ILowLevelDeviceIO;
  SetLength(a, n + 3);
  PCartRecEmpty(a).adr := $12;
  PCartRecEmpty(a).len := n+5;
  move(mtr^, a[3], n);
  d.SendROW(a, n+3,  procedure(p: Pointer; n: integer)
  begin
    PostMessage(Self.Handle, METROL_SAVE_OK_MESSAGE, n, n);
  end, 2047);
end;

procedure TGraphCartForm.MetrolSaveOKMessage(var Msg: TMessage);
begin
  if Msg.WParam = 3 then MessageDlg('метрология из файла записана в картограф', mtInformation, [mbOk], 0)
  else MessageDlg('Ошибка записи метрологии', mtError, [mbOk], 0)
end;

procedure TGraphCartForm.cmd13MetrLoad(msg: UINT);
 var
  d: ILowLevelDeviceIO;
  r: TCartRecEmpty;
begin
  d := GetDevice as ILowLevelDeviceIO;
  r.adr := $13;
  r.len := 5;
  d.SendROW(@r, 3,  procedure(p: Pointer; n: integer)
  begin
    if (n = 1003) or (n = 243) then
     begin
      SetLength(FMetrol, n-3);
      move(Pbyte(p)[3], FMetrol[0], n-3);
      PostMessage(Self.Handle, msg, 100, 0);
     end;
  end, 2047);
end;


procedure TGraphCartForm.MetrolMessage(var Msg: TMessage);
begin
  with TSaveDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   DefaultExt := 'bin';
   Options := Options + [ofOverwritePrompt, ofPathMustExist];
   Filter := 'File (*.bin)|*.bin';
   if Execute(Handle) then with TFileStream.Create(FileName, fmCreate) do
    try
     Write(FMetrol, Length(FMetrol));
    finally
     Free;
    end;
  finally
   Free;
  end;
end;

procedure TGraphCartForm.MetrolSaveMessage(var Msg: TMessage);
 var
  me: IManagerEx;
begin
  with TOpenDialog.Create(nil) do
  try
   if Supports(GContainer, IManagerEx, me) then 
    InitialDir := me.GetProjectDirectory
   else 
    InitialDir := ExtractFilePath(ParamStr(0));
   Options := Options + [ofPathMustExist, ofFileMustExist, ofEnableSizing];
   DefaultExt := 'bin';
   Filter := 'File (*.bin)|*.bin';
   if Execute() then with TFileStream.Create(FileName, fmOpenRead) do
    try
     var a : array [0..2000] of Byte; 
     var n := Read(a[0], Length(a));
     if n = Length(FMetrol) then
      begin
       for var i := 0 to n-1 do if FMetrol[i] <> a[i] then
        begin
         if MessageDlg('Файл и метрология разные. Записать?', mtConfirmation, mbOKCancel, 0) = mrOk then cmd12MetrSave(@a[0], n);
         exit;
        end;
       MessageDlg('Файл и метрология одинаковы', mtInformation, [mbOk], 0);
      end
      else raise ENeedDialogException.Createfmt('Длина метрологии %d не равна файлу %d',[Length(FMetrol), n]);
    finally
     Free;
    end;
  finally
   Free;
  end;
end;

procedure TGraphCartForm.Loaded;
begin
  inherited;
  AddToNCMenu('Разрешить изменение метрологии', NMetrEnableClick, 0, 0);
  FMetrSave := AddToNCMenu('Програмировать метрологию...', NMetrSaveClick, 10);
  btZero.Visible := false;
  btMetr.Visible := false;
  FMetrSave.Visible := False;
  FCondition := 255;
  for var c in CA do PatchTeeCart(c);
  UpdateMode;
  var d := GetDevice;
  if Assigned(d) then Bind('C_BindWorkRes', d, ['S_WorkEventInfo']);
  Bind('C_Project', GlobalCore as IManager, ['S_ProjectChange']);
  Bind('C_RemoveDevice', GlobalCore as IDeviceEnum, ['S_AfterRemove']);
end;

procedure TGraphCartForm.SetBindWorkRes(const Value: TWorkEventRes);
  procedure UpdateSeriesTitle(cfq: Byte; const Charts: TArray<TChart>);
  begin
    for var c in Charts do
      for var i := 0 to c.SeriesList.Count-1 do
       c.SeriesList[i].Title := format('T%d (%d)',[i+1, (cfq shr i) and 1]);
  end;
  procedure AddDataToChart(c: TChart; idx: Integer; tg: IXmlNode; Scale: Double = 1);
  begin
   var d := TPars.ArrayStrToArray(tg.Attributes[AT_VALUE]);
   for var i := 0 to c.SeriesList.Count-1 do
    begin
     var s := c.SeriesList[i];
     s.AddXY(idx, (d[i])*Scale);
     if s.Count > MAX_POINTS then
      begin
       s.Delete(0);
       c.BottomAxis.Automatic := True;
      end;
     c.LeftAxis.Automatic := True;
    end;
  end;
begin
  var cond : integer := Ftags[0].Attributes[AT_VALUE];
  if FCondition <> cond then
   begin
    FCondition := cond;
    UpdateSeriesTitle(cond shr 8, [Chart0,Chart1]); // 400
    UpdateSeriesTitle(cond, [Chart2,Chart3]); // 2000
   end;

  if Fmode = cmInduc then
   begin
    inc(idx1);
    for var i := 0 to 3 do AddDataToChart(CA[i], idx1, Ftags[i+1], SCALES_CHART[i]);
   end
  else if Fmode = cmCart then
   begin
    var fq := CartTag[cdxFq].Attributes[AT_VALUE];
    if fq = 401 then
     begin
       inc(idx1);
       AddDataToChart(Chart0, idx1, CartTag[cdxR]);
       AddDataToChart(Chart1, idx1, CartTag[cdxF], 57295.7795130823);
     end
    else if fq = 2000 then
     begin
       inc(idx2);
       AddDataToChart(Chart2, idx2, CartTag[cdxR]);
       AddDataToChart(Chart3, idx2, CartTag[cdxF], 57295.7795130823);
     end
   end;
end;

procedure TGraphCartForm.UpdateChartHeight;
 var
  lastVis: TChart;
begin
  var visCnt := 0;
  for var c in CA do if c.Visible then
   begin
    Inc(visCnt);
    lastVis := c;
   end;
  if visCnt = 0 then exit;

  for var c in CA do c.Align := alTop;

  var h := (ClientHeight - Panel.Height) div visCnt - Splitter0.Height;
  var top := Panel.Height;
  for var I := 0 to High(CA) do if CA[i].Visible then
   begin
    CS[i].Top := top;
    Inc(top, Splitter0.Height);
    CA[i].Top := top;
    CA[i].Height := h;
    Inc(top, h);
   end;

   lastVis.Align := alClient;
end;

procedure TGraphCartForm.UpdateMode;
 procedure CorSeriColor(s: TChartSeries);
 begin
   var cl := ColorToRGB(s.SeriesColor);
   var clR := GetRValue(cl);
   var clG := GetGValue(cl);
   var clB := GetBValue(cl);
   var max := Max(Max(clR, clG), clB);
   var d := 255 - max;
   s.SeriesColor := RGB(clR+d, clG+d, clB+d);
 end;
 procedure SetInfo(root: IXMLNode);
  var
   tgs: Tarray<IXmlNode>;
 begin
  if TestTags(root,  ['информация'], tgs) then
    Caption := 'Тест Картографа ' + tgs[0].ChildNodes[T_DEV].Attributes[AT_VALUE];
 end;
begin
  Fmode := cmNone;
  try
    for var n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
     if (n.Attributes[AT_ADDR] = 6) then
      if  TestTags(n,  INDUC_TAG, Ftags) then
       begin
        Fmode := cmInduc;
        FchannelsCnt := InducTag[idxR400].Attributes[AT_ARRAY];
        for var idx in aInduc do
         InducTag[idx] :=  InducTag[idx].ChildNodes[T_DEV];
        SetInfo(n);
        exit;
       end
     else if TestTags(n,  CART_TAG, Ftags) then
      begin
        Fmode := cmCart;
        FchannelsCnt := CartTag[cdxR].Attributes[AT_ARRAY];
        CartTag[cdxCond] := CartTag[cdxCond].ChildNodes['condition'].ChildNodes[T_DEV];
        for var cdx in aCart do
         CartTag[cdx] :=  CartTag[cdx].ChildNodes[T_DEV];
        SetInfo(n);
        exit;
      end
  finally
    for var c in CA do
     begin
      c.SeriesList.Clear;
      c.BottomAxis.SetMinMax(0, MAX_POINTS);
      for var I := 1 to FchannelsCnt do c.AddSeries(TLineSeries).Title := 'T'+i.ToString;
     end;
    if CurrentThemeIsDark then
     for var c in CA do
      for var s in c.SeriesList do CorSeriColor(s);
  end;
end;

procedure TGraphCartForm.btMertrSaveClick(Sender: TObject);
begin
  cmd13MetrLoad(METROL_SAVE_MESSAGE);
end;
procedure TGraphCartForm.btMetrClick(Sender: TObject);
begin
  cmd13MetrLoad(METROL_MESSAGE);
end;
procedure TGraphCartForm.NMetrEnableClick(Sender: TObject);
begin
  btZero.Visible := TMenuItem(Sender).Checked;
  btMetr.Visible := TMenuItem(Sender).Checked;
  FMetrSave.Visible := TMenuItem(Sender).Checked;
end;
procedure TGraphCartForm.NMetrSaveClick(Sender: TObject);
begin
  cmd13MetrLoad(METROL_SAVE_MESSAGE);
end;

procedure TGraphCartForm.btZeroClick(Sender: TObject);
 var
  d: ILowLevelDeviceIO;
  r: TCartRecEmpty;
begin
  d := GetDevice as ILowLevelDeviceIO;
  r.adr := $1A;
  r.len := 5;
  d.SendROW(@r, 3, procedure(p: Pointer; n: integer)
  begin
    if n <> 3 then raise ENeedDialogException.Create('Команда 0 не выполнена');
  end, 2047);
end;
procedure TGraphCartForm.brEqClick(Sender: TObject);
begin
  UpdateChartHeight;
end;
procedure TGraphCartForm.cbClick(Sender: TObject);
begin
  var cb := TCheckBox(Sender);
  CA[cb.Tag].Visible := cb.Checked;
  CS[cb.Tag].Visible := cb.Checked;
  UpdateChartHeight;
end;
function TGraphCartForm.GetCA: TArray<TChart>;
begin
  Result := [Chart0,Chart1,Chart2,Chart3];
end;
function TGraphCartForm.GetCS: TArray<TSplitter>;
begin
  Result := [Splitter0,Splitter1,Splitter2,Splitter3];
end;
function TGraphCartForm.InducTag: PInducTag;
begin
 Result := PInducTag(@Ftags[0]);
end;
procedure TGraphCartForm.btClrClick(Sender: TObject);
begin
  for var c in CA do
   begin
    for var s in c.SeriesList do s.Clear;
    c.BottomAxis.SetMinMax(0, MAX_POINTS);
   end;
  idx1 := 0;
  idx2 := 0;
end;
function TGraphCartForm.CartTag: PCartTag;
begin
  Result := PCartTag(@Ftags[0])
end;


initialization
  RegisterClass(TGraphCartForm);
  TRegister.AddType<TGraphCartForm, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TGraphCartForm>;
end.
