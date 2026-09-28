unit MetrInclin.Temp.DialogPoly;

interface

uses  DockIForm, ExtendIntf, System.TypInfo, RootImpl, PluginAPI, MetrInclin.Temp.FormPoly, MetrInclin.Temp.Stat,
  TrrInclin.Temp.LinModel,TrrInclin.Temp.LinPacked,  TrrInclin.Temp.LinTrainingReport,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,  MetrInclin.Temp.LeaveOneOut,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

  const
   STAT_FMT_N= '%s: %3d %8.2f%s av: %8.3f%s (T:%8.1f  A%8.1f°  Z%8.2f°  V%8.1f°)';
   STAT_FMT =  'Accel: %d %1.2f%% av: %1.3f%%     Magnit: %d %1.2f%% av: %1.3f%%     Ink:   %d %1.2f°av: %1.3f'#$D#$A
              +'Зенит: %d %1.2f°  av: %1.3f°     Азимут: %d %1.2f° av: %1.3f°     Визир: %d %1.2f°av: %1.3f°';
type
  TDialogPoly = class(TDialogIForm, IDialog, IDialog<TFormMetrInclinTP>)
    btnClose: TButton;
    btnRunAmp: TButton;
    btnLS: TButton;
    mmo: TMemo;
    pb: TPanel;
    btnLMZU: TButton;
    chkV: TCheckBox;
    chkZ: TCheckBox;
    chkA: TCheckBox;
    btnClr: TButton;
    btnT: TButton;
    btnKos: TButton;
    btnKosv2: TButton;
    btnClrSe: TButton;
    btCorrVisir: TButton;
    btRunTests: TButton;
    btHuber: TButton;
    btBestHu: TButton;
    bt240: TButton;
    cbW: TCheckBox;
    btLinAll: TButton;
    btLin240: TButton;
    chCosT: TCheckBox;
    btBestHuLin: TButton;
    btLinCrossCompare: TButton;
    btHybridHuber: TButton;
    btCompareTemperatureNodes: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ch5: TCheckBox;
    procedure btnRunAmpClick(Sender: TObject);
    procedure btnLSClick(Sender: TObject);
    procedure btnLMZUClick(Sender: TObject);
    procedure chkVClick(Sender: TObject);
    procedure chkZClick(Sender: TObject);
    procedure chkAClick(Sender: TObject);
    procedure btnClrClick(Sender: TObject);
    procedure btnTClick(Sender: TObject);
    procedure btnKosClick(Sender: TObject);
    procedure btnKosv2Click(Sender: TObject);
    procedure btnClrSeClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btCorrVisirClick(Sender: TObject);
    procedure btRunTestsClick(Sender: TObject);
    procedure btHuberClick(Sender: TObject);
    procedure btBestHuClick(Sender: TObject);
    procedure bt240Click(Sender: TObject);
    procedure btLinAllClick(Sender: TObject);
    procedure btLin240Click(Sender: TObject);
    procedure btBestHuLinClick(Sender: TObject);
    procedure btLinCrossCompareClick(Sender: TObject);
    procedure btHybridHuberClick(Sender: TObject);
    procedure btCompareTemperatureNodesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    owner: TFormMetrInclinTP;
    procedure PrintRes(const Alg: string);
  public
    function GetInfo: PTypeInfo; override;
    function Execute(frm: TFormMetrInclinTP): Boolean;
  end;

implementation

uses  MetrInclin.Temp.MathPoly, LuaInclin.Temp.Poly;

{$R *.dfm}



procedure TDialogPoly.btnCloseClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize('Metrolog', 'TempPoly');
end;

procedure TDialogPoly.btnClrClick(Sender: TObject);
begin
  mmo.Lines.Clear;
end;

procedure TDialogPoly.btnClrSeClick(Sender: TObject);
begin
  TpolyMath.ClearStolError
end;

procedure TDialogPoly.btnTClick(Sender: TObject);
begin
  TpolyMath.RunT;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('T');
end;

procedure TDialogPoly.bt240Click(Sender: TObject);
 var
  MaxMinIndices, SphereIndices: TArray<Integer>;
  Report: TStringList;
  Huber: THuberIrlsOptions;
  Test: TMaxMinSphereTestResult;
begin
  TpolyMath.BuildMaxMinSphereIndices(TpolyMath.InpData.Inpt,  MaxMinIndices, SphereIndices);
  Report := TStringList.Create;
  try
   Huber := THuberIrlsOptions.DefaultHuber;
   Huber.Limit := 1.345;

//   TpolyMath.SetupData.CorStolVisir := True;

   Test := TpolyMath.TestMaxMinOnSphere(
     MaxMinIndices,
     SphereIndices,
     Huber,
     Report);

   mmo.Lines.Assign(Report);
   if Test.Passed then  mmo.Lines.Add('********** Test.Passed ***********')

   //if Test.Passed then
  finally
    Report.Free;
  end;

  // Итоговые коэффициенты
  var Coefficients := Test.Coefficients;

  TpolyMath.ResultToXML(owner.CurrentTrr, Coefficients.G, Coefficients.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('ONLY 240');

end;

procedure TDialogPoly.btBestHuClick(Sender: TObject);
var
  Best: TBestHuberParameters;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
  Best := TpolyMath.SelectBestHuberParameters(
    [1.345,1.5{, 2.0, 2.5, 3.0, 3.5}], cbW.Checked,
    Report);


    mmo.Lines.Assign(Report);
    // либо:
    // Report.SaveToFile('ValidationReport.txt', TEncoding.UTF8);
  finally
    Report.Free;
  end;

  // Выбранное значение
  var HuberK := Best.Huber.Limit;

  // Итоговые коэффициенты
  var Coefficients := Best.FinalCoefficients;

  TpolyMath.ResultToXML(owner.CurrentTrr, Coefficients.G, Coefficients.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('BUBER BEST');
end;

procedure TDialogPoly.btBestHuLinClick(Sender: TObject);
var
  Best: TLinBestHuberParameters;
  Report: TStringList;
  MetricsReport: TStringList;
begin
  Report := TStringList.Create;
  MetricsReport := TStringList.Create;
  try
    Best := TpolyMath.lin_SelectBestHuberParameters(
      [1.345, 1.5, 2.0, 2.25, 2.5, 2.75, 3.0, 3.5],
      True,  // CrossLinear: косоугольность линейная по T
      True,  // BalanceMaxMinSphere: включить групповые веса
      Report
    );

    // Добавляем полные метрики выбранной модели.
    TpolyMath.lin_AllMetricsToStrings(Best.Fit, MetricsReport);
    Report.Add('');
    Report.AddStrings(MetricsReport);

    mmo.Lines.Assign(Report);

    // Выбранное значение:
    // Best.Huber.Limit

    // Коэффициенты выбранной модели:
    // Best.Fit.Coefficients.G
    // Best.Fit.Coefficients.H
  finally
    MetricsReport.Free;
    Report.Free;
  end;
end;

procedure TDialogPoly.btCompareTemperatureNodesClick(Sender: TObject);
var
  Huber: THuberIrlsOptions;
  Comparison: TLinTemperatureNodeComparison;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.BalanceMaxMinSphere := True; // False — без балансировочных весов

    Comparison :=
      TpolyMath.lin_CompareTemperatureNodeModels(
        [10, 8, 7, 6, 5],
        Huber,
        Report);

    mmo.Lines.Assign(Report);

    // Выбранная полностью переобученная модель:
    // Comparison.Variants[Comparison.SelectedIndex].Fit
  finally
    Report.Free;
  end;
end;

procedure TDialogPoly.btCorrVisirClick(Sender: TObject);
begin
  TpolyMath.CorrectVisir
end;
procedure TDialogPoly.btHuberClick(Sender: TObject);
var
  Report: TStringList;
  Models: TArray<TTemperatureModel>;
begin

   Models := [
    TTemperatureModel.Create(1, 1, 1),
    TTemperatureModel.Create(2, 0, 2),
    TTemperatureModel.Create(2, 1, 2),
    TTemperatureModel.Create(2, 2, 2),
    TTemperatureModel.Create(3, 0, 3),
    TTemperatureModel.Create(3, 1, 3),
    TTemperatureModel.Create(4, 0, 4),
    TTemperatureModel.Create(4, 1, 4)
  ];
  TpolyMath.RunTests(Models, THuberIrlsOptions.DefaultHuber);

  Report := TStringList.Create;
  try
    TpolyMath.SummaryModelTestResultsToStrings(Report);

    mmo.Lines.Assign(Report);
    // либо:
    // Report.SaveToFile('ValidationReport.txt', TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;
procedure TDialogPoly.btHybridHuberClick(Sender: TObject);
var
  AccHuber: THuberIrlsOptions;
  Best: TLinHybridHuberSelection;
  Report: TStringList;
  MetricsReport: TStringList;
begin
  Report := TStringList.Create;
  MetricsReport := TStringList.Create;
  try
    // Фиксированные настройки акселерометра G
    AccHuber := THuberIrlsOptions.DefaultHuber;
    AccHuber.Limit := 2.25;
    AccHuber.MaxIterations := 30;
    AccHuber.WeightTolerance := 1E-4;
    AccHuber.BalanceMaxMinSphere := True;

    // Перебирается только Huber k магнитометра
    Best := TpolyMath.lin_SelectHybridMagHuberParameters(
      [1.345, 1.5, 1.75, 2.0, 2.25],
      AccHuber,
      Report
    );

    // Полные метрики выбранного варианта
    TpolyMath.lin_AllMetricsToStrings(
      Best.Fit,
      MetricsReport
    );

    Report.Add('');
    Report.AddStrings(MetricsReport);

    TpolyMath.lin_WorstPointsToStrings(
      Best.Fit,
      Report,
      10
    );

    TpolyMath.lin_MagneticFieldDiagnosticsToStrings(
      Best.Fit,
      Report,
      1.0
    );

    mmo.Lines.Assign(Report);

    // Выбранные значения:
    // Best.AccHuber.Limit
    // Best.MagHuber.Limit
  finally
    MetricsReport.Free;
    Report.Free;
  end;
end;
procedure TDialogPoly.btLin240Click(Sender: TObject);
var
  Model: TLinTemperatureModel;
  Fit: TLinCalibrationResult;
  Huber: THuberIrlsOptions;
  MaxMinIndices, SphereIndices: TArray<Integer>;
  TrainingInputs: TArray<TinclInput>;
  Report: TStringList;
begin



  TpolyMath.BuildMaxMinSphereIndices(
    TpolyMath.InpData.Inpt,
    MaxMinIndices,
    SphereIndices
  );

  Huber := THuberIrlsOptions.DefaultHuber;
  Huber.Limit := 2.25;
  Huber.MaxIterations := 30;
  Huber.WeightTolerance := 1E-4;
  Huber.BalanceMaxMinSphere := True;

  Report := TStringList.Create;
  try

    var Comparison := TGkiLinTrainingReport.Run(
      MaxMinIndices,
      [5, 6, 7, 8, 9, 10],
      Huber,
      Report
    );

    mmo.Lines.Assign(Report);
    var si := if ch5.Checked then 0 else Comparison.SelectedIndex;

    var SelectedFit := Comparison.Variants[
    si
    ].Fit;

    var Pac := TGkiPackedExporter.FromFit(SelectedFit);
    TGkiPackedCodec.SaveToXML(owner.CurrentTrr, Pac);
    owner.RecalcResultAndUpdateTree(False, true);
    PrintRes('Lin 240');
  finally
    Report.Free;
  end;

end;


procedure TDialogPoly.btLinAllClick(Sender: TObject);
var
  Model: TLinTemperatureModel;
  Huber: THuberIrlsOptions;
  Fit: TLinCalibrationResult;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Model := TpolyMath.lin_CreateModel(
      True  // косоугольность линейная по T
    );

    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.WeightTolerance := 1E-4;
    Huber.BalanceMaxMinSphere := True;

    Fit := TpolyMath.lin_RunLS(Model, Huber);

    TpolyMath.lin_AllMetricsToStrings(Fit, Report);

    TpolyMath.lin_WorstPointsToStrings(
      Fit,
      Report,
      10
    );

    TpolyMath.lin_MagneticFieldDiagnosticsToStrings(
      Fit,
      Report,
      1.0  // допуск совпадения A/Z/V, градусы
    );

    var Pac := TGkiPackedExporter.FromFit(Fit);
    TGkiPackedCodec.SaveToXML(owner.CurrentTrr, Pac);
    owner.RecalcResultAndUpdateTree(False);
    PrintRes('Lin All');

    mmo.Lines.Assign(Report);
  finally
    Report.Free;
  end;
end;

procedure TDialogPoly.btLinCrossCompareClick(Sender: TObject);
var
  Huber: THuberIrlsOptions;
  Comparison: TLinCrossModelComparison;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.WeightTolerance := 1E-4;
    Huber.BalanceMaxMinSphere := True;

    Comparison := TpolyMath.lin_CompareCrossModels(
      Huber,
      Report
    );

    // Диагностика новой 30-коэффициентной модели
    TpolyMath.lin_WorstPointsToStrings(
      Comparison.FiveNodeFit,
      Report,
      10
    );

    TpolyMath.lin_MagneticFieldDiagnosticsToStrings(
      Comparison.FiveNodeFit,
      Report,
      1.0
    );

    mmo.Lines.Assign(Report);
  finally
    Report.Free;
  end;
end;




procedure TDialogPoly.btRunTestsClick(Sender: TObject);
var
  Report: TStringList;
  Models: TArray<TTemperatureModel>;
begin

   Models := [
    TTemperatureModel.Create(1, 1, 1),
    TTemperatureModel.Create(2, 0, 2),
    TTemperatureModel.Create(2, 1, 2),
    TTemperatureModel.Create(2, 2, 2),
    TTemperatureModel.Create(3, 0, 3),
    TTemperatureModel.Create(3, 1, 3),
    TTemperatureModel.Create(4, 0, 4),
    TTemperatureModel.Create(4, 1, 4)
  ];
  TpolyMath.RunTests(Models, THuberIrlsOptions.OrdinaryLeastSquares);

  Report := TStringList.Create;
  try
    TpolyMath.SummaryModelTestResultsToStrings(Report);

    mmo.Lines.Assign(Report);
    // либо:
    // Report.SaveToFile('ValidationReport.txt', TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;
procedure TDialogPoly.Button1Click(Sender: TObject);
var
  Huber: THuberIrlsOptions;
  Comparison: TLinReducedFiveCrossComparison;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.WeightTolerance := 1E-4;
    Huber.BalanceMaxMinSphere := True;

    Comparison :=
      TpolyMath.lin_CompareReducedFiveNodeCrossModels(
        [10, 8, 7, 6],
        Huber,
        Report
      );

    mmo.Lines.Assign(Report);

    // Comparison.SelectedIndex:
    // -1 = победила базовая модель
    //  0 = 10 основных + 5 cross
    //  1 =  8 основных + 5 cross
    //  2 =  7 основных + 5 cross
    //  3 =  6 основных + 5 cross
  finally
    Report.Free;
  end;
end;
procedure TDialogPoly.Button2Click(Sender: TObject);
var
  Huber: THuberIrlsOptions;
  Comparison: TLinZenithGridComparison;
  Report: TStringList;
  SelectedFit: TLinCalibrationResult;
begin
  Report := TStringList.Create;
  try
    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.WeightTolerance := 1E-4;
    Huber.BalanceMaxMinSphere := True;

    Comparison :=
      TpolyMath.lin_CompareZenithPriorityModels(
        [6, 6, 7, 7],  // main
        [5, 6, 5, 7],  // cross
        Huber,
        Report
      );

    SelectedFit :=
      Comparison.Variants[
        Comparison.SelectedIndex
      ].Fit;

    // Худшая строка, включая Zenith
    TpolyMath.lin_WorstPointsToStrings(
      SelectedFit,
      Report,
      10
    );

    mmo.Lines.Assign(Report);
  finally
    Report.Free;
  end;
end;
procedure TDialogPoly.Button3Click(Sender: TObject);
var
  Huber: THuberIrlsOptions;
  Comparison: TLinZenithGridComparison;
  SelectedFit: TLinCalibrationResult;
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Huber := THuberIrlsOptions.DefaultHuber;
    Huber.Limit := 2.25;
    Huber.MaxIterations := 30;
    Huber.WeightTolerance := 1E-4;
    Huber.BalanceMaxMinSphere := True;

    Comparison :=
      TpolyMath.lin_CompareTargetedZenithModels(
        Huber,
        Report
      );

    SelectedFit :=
      Comparison.Variants[
        Comparison.SelectedIndex
      ].Fit;

    TpolyMath.lin_WorstPointsToStrings(
      SelectedFit,
      Report,
      10
    );

    mmo.Lines.Assign(Report);
  finally
    Report.Free;
  end;
end;
procedure TDialogPoly.btnKosClick(Sender: TObject);
begin
  TpolyMath.RunKoso;
  TpolyMath.KosoToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(true);
  PrintRes('KOSO');
end;

procedure TDialogPoly.btnKosv2Click(Sender: TObject);
begin
  TpolyMath.RunKosoV2;
  TpolyMath.KosoToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(true);
  PrintRes('KOSO V2');
end;

procedure TDialogPoly.btnLMZUClick(Sender: TObject);
begin
  TpolyMath.RunZ;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(false);
  PrintRes('LMZU');
end;

procedure TDialogPoly.btnLSClick(Sender: TObject);
begin
   TpolyMath.RunLS;
   TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
   owner.RecalcResultAndUpdateTree(False);
   PrintRes('LS');
end;

procedure TDialogPoly.btnRunAmpClick(Sender: TObject);
begin
  TpolyMath.RunAmp;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('AMP');
end;


procedure TDialogPoly.chkAClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolMagnit := chkA.Checked;
end;

procedure TDialogPoly.chkVClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolVisir := chkV.Checked;
end;

procedure TDialogPoly.chkZClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolZenit := chkZ.Checked;
end;

function TDialogPoly.Execute(frm: TFormMetrInclinTP): Boolean;
begin
  Result := True;
  owner := frm;
  IShow;
end;

function TDialogPoly.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_Text_Init);
end;

procedure TDialogPoly.PrintRes(const Alg: string);
 const
  SE = 'incl: %7.3f     azi: %7.3f   viz: %7.3f '+#$D#$A+
       'Zen : %7.3f  AziZen: %7.1f'    ;
begin
  mmo.Lines.Add('**************'+Alg+'***************');
  var s := 'Correction:';
  if chkV.Checked then s := s+' Visir';
  if chkZ.Checked then s := s+' Zenit';
  if chkA.Checked then s := s+' Magnit';
  if s <> 'Correction:' then mmo.Lines.Add(s);

  mmo.Lines.Add(TpolyMath.EStatToStrN(0,'Accel      ','%', STAT_FMT_N, 100/RES_AMP));
  mmo.Lines.Add(TpolyMath.EStatToStrN(1,'Magnit     ','%', STAT_FMT_N, 100/RES_AMP));
  mmo.Lines.Add(TpolyMath.EStatToStrN(2,'Наклон     ','°', STAT_FMT_N));
  mmo.Lines.Add(TpolyMath.EStatToStrN(3,'Зенит      ','°', STAT_FMT_N));
  mmo.Lines.Add(TpolyMath.EStatToStrN(4,'Азимут     ','°', STAT_FMT_N));
  mmo.Lines.Add(TpolyMath.EStatToStrN(5,'отклонитель','°', STAT_FMT_N));
//  mmo.Lines.Add(TpolyMath.EStatToStr(STAT_FMT));
  mmo.Lines.Add('------------ошибка стола-------------');
  var e := TpolyMath.eStol;
  mmo.Lines.Add(Format(SE,[e.cNakl,e.cAzi,e.cVis,e.cZenA, e.cZenAng]));
  mmo.Lines.Add('');
end;


initialization
  RegisterDialog.Add<TDialogPoly, Dialog_Text_Init>('Metrolog', 'TempPoly');
finalization
  RegisterDialog.Remove<TDialogPoly>;
end.
