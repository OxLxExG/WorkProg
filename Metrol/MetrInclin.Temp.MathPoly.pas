unit MetrInclin.Temp.MathPoly;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
     TrrInclin.Temp.PolyModel, TrrInclin.Temp.LinModel,
     LuaInclin.Math, Math,  TrrInclin.Temp.LinPacked,
     MathIntf, XMLLua.Math, Vector, MetrInclin.Temp.Stat,
     MetrInclin.Temp.LeaveOneOut;

//   SENS : array[0..1] of string = ('accel', 'magnit');
type


  { Параметры внешнего Huber IRLS над ALGLIB LinearW.

    Важно различать два веса:
      * PointWeight — статистический вес w в сумме w*r^2;
      * множитель ALGLIB — sqrt(w), потому что LinearW минимизирует
        сумму (W*r)^2.

    Один PointWeight назначается всей измерительной точке и одинаково
    применяется к уравнениям X, Y и Z. Так единичный повреждённый замер
    не может выборочно изменить только одну ось. }
  THuberIrlsOptions = record
    Enabled: Boolean;
    MaxIterations: Integer;
    Limit: Double;
    WeightTolerance: Double;
    MinScale: Double;
    { When both acquisition groups are present, their total base weights
      are made equal before applying the per-point Huber weights. }
    BalanceMaxMinSphere: Boolean;
    class function OrdinaryLeastSquares: THuberIrlsOptions; static;
    class function DefaultHuber: THuberIrlsOptions; static;
    procedure Validate;
  end;

  { Диагностика последнего решения одного сенсора.
    PointWeights не удаляют точки и нужны для поиска проблемных температур,
    ориентаций и последовательных участков эксперимента. }
  THuberIrlsDiagnostics = record
    Iterations: Integer;
    Converged: Boolean;
    MaxWeightChange: Double;
    DownWeightedCount: Integer;
    StronglyDownWeightedCount: Integer;
    MinWeight: Double;
    Scale: TVector3;
    BasePointWeights: TArray<Double>;
    PointWeights: TArray<Double>;
    EffectivePointWeights: TArray<Double>;
  end;

  { Диагностика автоматической коррекции визира.

    CorrectVisir подбирает только eStol.cVis. Остальные составляющие модели
    стола не изменяются. Контролируемая величина Yx0 — свободный
    (температурная степень 0) коэффициент примеси X в выход Y
    акселерометра: Res.G[vY][pmA.pYx]. }
  TVisirCorrectionDiagnostics = record
    InitialCVis: Double;
    InitialYx0: Double;
    CorrectedCVis: Double;
    FinalYx0: Double;
    Iterations: Integer;
    Converged: Boolean;
  end;

  { Rules for true spatial LOGO. No scheme below removes isolated random
    rows: every test set is a complete region across all SetNo values. }
  TLogoSpatialOptions = record
    AzimuthSectorWidth: Double;
    ToolfaceStep: Double;
    CheckerboardK: Integer;
    AxialTailFraction: Double;
    MinRowsPerCoefficient: Integer;
    MaxConditionNumber: Double;
    MinRawRangeRatio: Double;
    class function Default: TLogoSpatialOptions; static;
    procedure Validate;
  end;

  { Identifiability of the actual A(T)v+b(T) training matrix. Rank and
    condition are the worst values over X/Y/Z output equations. Raw ranges
    are retained training ranges for G and H; RangeRatio compares them with
    the complete acquisition. }
  TLogoIdentifiability = record
    FoldName: string;
    Accepted: Boolean;
    Reason: string;
    RequiredRank: Integer;
    AccRank: Integer;
    MagRank: Integer;
    AccCondition: Double;
    MagCondition: Double;
    RowsPerCoefficient: Double;
    TemperatureLevelCount: Integer;
    TestZenithFamilyCount: Integer;
    TestAzimuthBinCount: Integer;
    TestToolfaceBinCount: Integer;
    RawMin: TSensorVect;
    RawMax: TSensorVect;
    RangeRatio: TSensorVect;
  end;

  { Полный результат RunTests.

    Folds содержит только принятые разбиения LOTO, LTBO, LOGO и совместного
    stress-теста temperature band OR orientation group. Массивы
    *Analysis содержат также отклонённые кандидаты и причины отклонения.
    FoldResults — результаты каждого fold для каждой модели, Summary —
    агрегированные метрики, раздельные по типу проверки. }
  TValidationTestRun = record
    Samples: TArray<TValidationSample>;
    Models: TArray<TTemperatureModel>;
    Folds: TArray<TValidationFold>;
    LotoAnalysis: TArray<TLotoSeriesAnalysis>;
    LtboAnalysis: TArray<TLtboBandAnalysis>;
    LogoAnalysis: TArray<TLogoGroupAnalysis>;
    LogoIdentifiability: TArray<TLogoIdentifiability>;
    StressIdentifiability: TArray<TLogoIdentifiability>;
    FoldResults: TArray<TValidationFoldResult>;
    Summary: TArray<TValidationSummary>;
  end;

{$REGION 'old'}
//  // x,y,z
//  T3DPoint = array [0..2] of Double;
//   // искомые коэфициенты
//  TVekModel = array[0..3] of Double;
//  //     |k0|
//  //     |k1|     model inclin
//  // K=  |k2|
//  //     |k3|
//
//  TTModel = array[0..3] of Double;
//
//  // Ti = |1,t,tt,ttt|      ti = 25 60 100 125 25
//  TAxisModel = array[0..3] of TVekModel;
//  // модель сенсора в векторном виде
//  // Xэ = (K1 + Xij*K2 +  Yij*K3 +  Zij*K4)*Ti
//  // Yэ = (K5 + Xij*K6 +  Yij*K7 +  Zij*K8)*Ti
//  // Zэ = (K9 + Xij*K10 + Yij*K11 + Zij*K12)*Ti
//  TSensorModel = array[0..2] of TAxisModel;
//  // j - 48 пространственных точек
//  // Az90, Zu90, 8Vis
//  // Az270,Zu90, 8Vis
//  // Az0,  Zu0,  8Vis
//  // Az0,  Zu180,8Vis
//  // Az0,  Zu18, 8Vis
//  // Az0,  Zu198,8Vis
//
//  // 48*5  =240 уравнений
//
//  // делим на три системы уравнений для каждой оси
//
//  // k = 16 неизвестных оа ось
//  // ряд матрицы А измеренные X,Y,Z,t
//  // Э = Xi,Xit,Xitt,Xittt, Yi,Yit,Yitt,Yittt, Zi,Zit,Zitt,Zittt, 1,t,tt,ttt
//  // Э - вектор (X,Y,Z) (делим на три системы уравнений для каждой оси!)
//  TARow = TArray<Double>;
//  // заготовка для НМК по каждой точке (240 строк)
//  // B = A*x
//  // A одинакова для всех осей!
//  TAmatrix = TArray<TARow>;
//  // B => Э => X,Y,Z- зталоны полученные из данных стола А.З.О.Маг.Нак (точка измерения в пространстве при текущей температуре t)
//  // Xetalon,Yetalon,Zetalon: TBVector (делим на три системы уравнений для каждой оси! ARow,A-одинаковые для всех осей!)
//  TBVector = TArray<Double>;
{$ENDREGION}


    PFindLMKosStol = ^TFindLMKosStol;
    TFindLMKosStol = record
      kos: TSensorData<TKosUgol>;
      StolError: TStolError;
    end;

//  TSensRes = record
//   ex,ey,ez,//эталон
//   tx,ty,tz: Double;//тарированные
//   Amp: Double;
//  end;
  TPolyRes = record
     G, H: TVArray<Double>;
     function RowH :TArray<Double>;
     function RowG :TArray<Double>;
     procedure toArray(var r: array of Double);
     procedure fromArray(r: array of Double);
     function ArrayLen: Integer;
    end;

  { Independent result of the piecewise-linear calculation.  It does not
    overwrite the active polynomial Res, so both models can be compared on
    exactly the same source snapshot. }
  TLinCalibrationResult = record
    { Model is always the accelerometer model.  MagModel is used when
      SeparateSensorModels=True; otherwise Model is shared by G and H. }
    Model: TLinTemperatureModel;
    MagModel: TLinTemperatureModel;
    SeparateSensorModels: Boolean;
    Coefficients: TPolyRes;
    Diagnostics: TSensorData<THuberIrlsDiagnostics>;
    TrainingIndices: TArray<Integer>;
    AccRank: Integer;
    MagRank: Integer;
    AccCondition: Double;
    MagCondition: Double;
    StolError: TStolError;
    AccHuber: THuberIrlsOptions;
    MagHuber: THuberIrlsOptions;
  end;

  TLinAllMetricsResult = record
    Calculated: TArray<TInclRes>;
    Metrics: TArray<TValidationMetric>;
  end;

  { One fitted main-temperature grid.  Cross-axis coefficients remain
    global-linear in temperature, so only the amplitude and zero-offset
    temperature-node count changes between candidates. }
  TLinTemperatureNodeVariantResult = record
    RequestedNodeCount: Integer;
    Model: TLinTemperatureModel;
    Fit: TLinCalibrationResult;
    Metrics: TLinAllMetricsResult;
    Converged: Boolean;
    MaxAbsPassCount: Integer;
    NormalizedMaxError: Double;
  end;

  TLinTemperatureNodeComparison = record
    Variants: TArray<TLinTemperatureNodeVariantResult>;
    SelectedIndex: Integer;
  end;

  { Transitional models: the main amplitude/offset grid is reduced while
    both cross-axis terms use the same five SetNo temperature centers for G
    and H.  Baseline is the current 10-node/global-linear-cross model.
    SelectedIndex=-1 means that Baseline won; otherwise it indexes Variants. }
  TLinReducedFiveCrossComparison = record
    Baseline: TLinTemperatureNodeVariantResult;
    Variants: TArray<TLinTemperatureNodeVariantResult>;
    SelectedIndex: Integer;
  end;

  { One main-grid/cross-grid pair evaluated with Zenith as the primary
    controlled metric.  The same Model is always fitted to G and H. }
  TLinZenithGridVariantResult = record
    ModelName: string;
    MainNodeCount: Integer;
    CrossNodeCount: Integer;
    Model: TLinTemperatureModel;
    Fit: TLinCalibrationResult;
    Metrics: TLinAllMetricsResult;
    Converged: Boolean;
    ZenithMaxAbs: Double;
    ZenithPass: Boolean;
    OtherMaxAbsPassCount: Integer;
    MaxAbsPassCount: Integer;
    NormalizedMaxError: Double;
  end;

  TLinZenithGridComparison = record
    Variants: TArray<TLinZenithGridVariantResult>;
    SelectedIndex: Integer;
  end;

  { Same data and Huber options, three cross-axis temperature structures. }
  TLinCrossModelComparison = record
    LinearFit: TLinCalibrationResult;
    FiveNodeFit: TLinCalibrationResult;
    PiecewiseFit: TLinCalibrationResult;
    LinearMetrics: TLinAllMetricsResult;
    FiveNodeMetrics: TLinAllMetricsResult;
    PiecewiseMetrics: TLinAllMetricsResult;
  end;

  { One Huber boundary checked on the complete input by the piecewise-linear
    temperature model.  The five MaxAbs fields use the same order and limits
    as lin_AllMetricsToStrings. }
  TLinHuberKCandidateResult = record
    Limit: Double;
    Converged: Boolean;
    MaxAbsPassCount: Integer;
    ZenithMaxAbs: Double;
    MagneticInclinationMaxAbs: Double;
    AzimuthMaxAbs: Double;
    AccelerometerNormMaxAbs: Double;
    MagnetometerNormMaxAbs: Double;
    MagneticInclinationPass: Boolean;
    MagnetometerNormPass: Boolean;
    NormalizedMaxError: Double;
    Selected: Boolean;
  end;

  { Result of selecting Huber k for the piecewise-linear model. }
  TLinBestHuberParameters = record
    Model: TLinTemperatureModel;
    Huber: THuberIrlsOptions;
    Candidates: TArray<TLinHuberKCandidateResult>;
    SelectedIndex: Integer;
    Fit: TLinCalibrationResult;
    AllMetrics: TLinAllMetricsResult;
  end;

  TLinHybridHuberSelection = record
    AccHuber: THuberIrlsOptions;
    MagHuber: THuberIrlsOptions;
    Candidates: TArray<TLinHuberKCandidateResult>;
    SelectedIndex: Integer;
    Fit: TLinCalibrationResult;
    AllMetrics: TLinAllMetricsResult;
  end;

  { Один кандидат при автоматическом выборе границы Huber. Значения PASS
    считаются по 20 проверкам: четыре вида validation x пять допусков. }
  THuberKCandidateResult = record
    Limit: Double;
    EvaluatedCount: Integer;
    MeanAbsPassCount: Integer;
    P95PassCount: Integer;
    MaxAbsPassCount: Integer;
    NormalizedError: Double;
    Complete: Boolean;
  end;

  { Результат выбора Huber для зафиксированной модели 2:1:2.
    Validation содержит fold-результаты победившего кандидата, а
    FinalCoefficients и FinalDiagnostics получены повторным обучением на
    полном исходном наборе после окончания cross-validation. }
  TBestHuberParameters = record
    Model: TTemperatureModel;
    Huber: THuberIrlsOptions;
    Candidates: TArray<THuberKCandidateResult>;
    Validation: TValidationTestRun;
    FinalCoefficients: TPolyRes;
    FinalDiagnostics: TSensorData<THuberIrlsDiagnostics>;
    FinalStolError: TStolError;
    VisirDiagnostics: TVisirCorrectionDiagnostics;
    { Итоговая проверка выбранного k после обучения и проверки на всех
      исходных строках. Строки являются внутривыборочными. }
    FinalAllFoldResult: TValidationFoldResult;
  end;

  { Контроль достаточности экстремальной сетки alg_logo2.lua.
    Коэффициенты 2:1:2 обучаются только по строкам G/H max/min, а итоговые
    метрики вычисляются по объединению max/min и "Сфера". }
  TMaxMinSpherePointDiagnostic = record
    MetricIndex: Integer;
    MetricName: string;
    SourceIndex: Integer;
    SetNo: Integer;
    Step: Integer;
    Info: string;
    Temperature: Double;
    EtalonAzi: Double;
    EtalonZen: Double;
    EtalonVis: Double;
    EtalonMag: Double;
    G: TVector3;
    H: TVector3;
    SignedError: Double;
    AbsError: Double;
    Limit: Double;
    ExpectedNorm: Double;
    CalculatedNorm: Double;
  end;

  TMaxMinSphereTestResult = record
    Model: TTemperatureModel;
    Huber: THuberIrlsOptions;
    Identifiability: TLogoIdentifiability;
    FoldResult: TValidationFoldResult;
    Coefficients: TPolyRes;
    Diagnostics: TSensorData<THuberIrlsDiagnostics>;
    StolError: TStolError;
    VisirDiagnostics: TVisirCorrectionDiagnostics;
    WorstPoints: TArray<TMaxMinSpherePointDiagnostic>;
    MagnetNormExceedances: TArray<TMaxMinSpherePointDiagnostic>;
    WithoutVisirFoldResult: TValidationFoldResult;
    WithVisirFoldResult: TValidationFoldResult;
    VisirComparisonAvailable: Boolean;
    VisirComparisonError: string;
    { Direct experiment requested for the acquisition program.  Both fits
      use the same source snapshot, temperature basis, Huber options and
      fixed cVis, and both are finally evaluated on all source rows. }
    AllRowsFoldResult: TValidationFoldResult;
    RepeatMaxMinFoldResult: TValidationFoldResult;
    TrainingSetComparisonAvailable: Boolean;
    TrainingSetComparisonError: string;
    MaxMinRepeatMaxDelta: Double;
    MaxMinRepeatReproducible: Boolean;
    Passed: Boolean;
  end;

   PFindLMKosStolV2 = ^TFindLMKosStolV2;
   TFindLMKosStolv2 = record
    ks: TFindLMKosStol;
    t: array[0..1000] of Double;
    function Len:Integer;
   end;

  TpolyMath = class
  private
    class procedure SetupKoso(Bl,bh: PFindLMKosStol);

    class procedure RunLsT(pm: PolyModel; idxs: TArray<Integer>; sns: SetSetsor; vec: SetVector; var Res: TArray<Double>);

    class procedure RunLsSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
    class procedure RunHuberLsSensor(pm: PolyModel;
      const data: TArray<RowModel>; sns: SetSetsor;
      const Options: THuberIrlsOptions; var SensorRes: TVArray<Double>;
      out Diagnostics: THuberIrlsDiagnostics);
    class procedure RunLMSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
    class var LMAmpData : record
      m: PolyModel;
      bl, bh: TArray<Double>; //n
      kBegin: TArray<Double>; //n
      d: TArray<RowModel>;  //m
    end;
    class var KorrTVectors: TArray<TSensorVect>;
    class procedure KorrTVectors_int();
    class var IsKosoV2: Boolean;
//    class procedure func_cb_ZY_StolZ(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_koso(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_amp(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_zen(const k, f: PDoubleArray); static; cdecl;
  public

    { Углы стола в разных температурных сериях могут отличаться из-за
      округления при чтении XML. Две строки считаются одной ориентацией,
      когда Azi, Zen и Vis совпадают с этим циклическим допуском. }
    const DefaultOrientationTolerance = 0.5;

    class var eStol: TStolError;

   // class var EtalonData : TArray<TSensorVect>;

    class var InpData : record
      pmA, pmH: PolyModel;
      MNak: Double;
      Tmin,Tmax: Double;
      Inpt: TArray<TinclInput>;
    end;

    class var SetupData : record
      CorStolVisir,
      CorStolZenit,
      CorStolMagnit: Boolean;
    end;
    class var KosRes:  TFindLMKosStol;
//    class var KosResv2:  TFindLMKosStolv2;

    class var mag, acc: TArray<RowModel>;

    class var InclRes: Tarray<TInclRes>;

    class var Res: TPolyRes;

    { Результаты IRLS для акселерометра и магнитометра соответственно.
      При обычном RunLS поля сбрасываются, чтобы старая диагностика не была
      ошибочно принята за результат текущего запуска. }
    class var HuberDiagnostics: TSensorData<THuberIrlsDiagnostics>;

    { Результат последнего вызова CorrectVisir. Поле особенно полезно для
      протокола тарировки: по нему видно, какое изменение визира было внесено
      и насколько близко к нулю удалось привести Yx степени 0. }
    class var VisirDiagnostics: TVisirCorrectionDiagnostics;

    { Результат последнего RunTests. Функция одновременно возвращает эту же
      запись, поэтому вызывающий код может выбрать удобный способ доступа. }
    class var TestResults: TValidationTestRun;

    { Normal application path: determine the temperature limits from Inp.
      Validation must use the overload below, because every fold has a
      different training range and must nevertheless share one basis. }
    class procedure Init(pmA,pmH: PolyModel; Naklon: Double;
      Inp: TArray<TinclInput>); overload;

    { Validation path: use fixed temperature normalization limits.
      For example, pass 19 and 137 for every LOTO/LTBO/LOGO fold. }
    class procedure Init(pmA,pmH: PolyModel; Naklon: Double;
      Inp: TArray<TinclInput>; FixedTMin, FixedTMax: Double); overload;
    class procedure RunAmp;
    class procedure RunLS; overload;
    class procedure RunLS(const Huber: THuberIrlsOptions); overload;

    { Piecewise-linear temperature model.  Every function belonging to this
      path starts with lin_.  The overload without TrainingIndices fits all
      rows from the latest Init. }
    class function lin_CreateModel(
      CrossLinear: Boolean = False): TLinTemperatureModel;
    class function lin_CreatePiecewiseCrossModel:
      TLinTemperatureModel;
    class function lin_CreateFiveNodeCrossModel:
      TLinTemperatureModel;
    { Build a 5..10-node main-temperature model.  The narrowest measured
      SetNo ranges are represented by their actual mean temperature first;
      the wider ranges retain separate Min/Max nodes. }
    class function lin_CreateReducedNodeModel(
      NodeCount: Integer; CrossLinear: Boolean = True):
      TLinTemperatureModel;
    { Main amplitude/offset grid has NodeCount nodes; both cross-axis
      coefficients are piecewise-linear at the five real SetNo centers. }
    class function lin_CreateReducedFiveNodeCrossModel(
      NodeCount: Integer): TLinTemperatureModel;
    { Independently reduce the main amplitude/offset and cross-axis grids.
      When both counts are equal the two grids are exactly aligned. }
    class function lin_CreateReducedCrossNodeModel(
      MainNodeCount, CrossNodeCount: Integer): TLinTemperatureModel;
    { Targeted 7/8-node main grids: omit the lower boundary of the middle
      SetNo range, but retain both its real center and upper boundary.
      Cross-axis terms remain on the five real SetNo centers. }
    class function lin_CreateTargetedZenithModel(
      MainNodeCount: Integer): TLinTemperatureModel;
    class function lin_RunLS(const Model: TLinTemperatureModel;
      const Huber: THuberIrlsOptions): TLinCalibrationResult; overload;
    class function lin_RunLS(const Model: TLinTemperatureModel;
      const TrainingIndices: TArray<Integer>;
      const Huber: THuberIrlsOptions): TLinCalibrationResult; overload;
    class function lin_RunSensorModels(
      const AccModel, MagModel: TLinTemperatureModel;
      const TrainingIndices: TArray<Integer>;
      const AccHuber, MagHuber: THuberIrlsOptions):
      TLinCalibrationResult;
    class function lin_RunHybridFiveNode(
      const AccHuber, MagHuber: THuberIrlsOptions):
      TLinCalibrationResult;
    class function lin_CalculateAll(
      const Fit: TLinCalibrationResult): TLinAllMetricsResult;
    class procedure lin_AllMetricsToStrings(
      const Fit: TLinCalibrationResult; OutRes: TStrings);
    class function lin_SelectBestHuberParameters(
      const HuberKValues: array of Double;
      CrossLinear, BalanceMaxMinSphere: Boolean;
      OutRes: TStrings): TLinBestHuberParameters;
    { Append the exact worst source row for every controlled ALL metric.
      For magnetic inclination and magnetometer norm also append the worst
      rows and the neighbouring Steps from the same temperature series. }
    class procedure lin_WorstPointsToStrings(
      const Fit: TLinCalibrationResult; OutRes: TStrings;
      SameSeriesCount: Integer = 10);
    { Diagnose whether magnetic-inclination errors look like a constant
      manually entered reference offset or like a field change with
      temperature/orientation.  This procedure only reports evidence; it
      does not change InpData.MNak or refit the model. }
    class procedure lin_MagneticFieldDiagnosticsToStrings(
      const Fit: TLinCalibrationResult; OutRes: TStrings;
      OrientationTolerance: Double = 1.0);
    class function lin_CompareCrossModels(
      const Huber: THuberIrlsOptions;
      OutRes: TStrings): TLinCrossModelComparison;
    class function lin_CompareTemperatureNodeModels(
      const NodeCounts: array of Integer;
      const Huber: THuberIrlsOptions;
      OutRes: TStrings): TLinTemperatureNodeComparison;
    class function lin_CompareReducedFiveNodeCrossModels(
      const MainNodeCounts: array of Integer;
      const Huber: THuberIrlsOptions;
      OutRes: TStrings): TLinReducedFiveCrossComparison;
    { Compare parallel MainNodeCounts/CrossNodeCounts pairs.  Selection
      priority is Zenith pass, minimum Zenith MaxAbs, other strict PASS,
      normalized error, then fewer coefficients. }
    class function lin_CompareZenithPriorityModels(
      const MainNodeCounts, CrossNodeCounts: array of Integer;
      const Huber: THuberIrlsOptions;
      OutRes: TStrings): TLinZenithGridComparison;
    class function lin_CompareTargetedZenithModels(
      const Huber: THuberIrlsOptions;
      OutRes: TStrings): TLinZenithGridComparison;
    class function lin_SelectHybridMagHuberParameters(
      const MagHuberKValues: array of Double;
      const AccHuber: THuberIrlsOptions;
      OutRes: TStrings): TLinHybridHuberSelection;

    { Создать и выполнить все пригодные проверки:
        * LOTO — исключение каждой температурной серии SetNo;
        * LTBO — рекомендуемые температурные полосы с embargo;
        * LOGO — исключение каждой группы ориентации;
        * STRESS — test = temperature band OR orientation group,
          train = NOT band AND NOT group.

      Данные берутся из последнего Init. LOGO использует целые азимутальные
      секторы, группы toolface, распределённые checkerboard-группы и осевые
      области Gx/Gy/Gz max/min. TinclInput.Step не используется. Перед
      запуском spatial fold проверяются ранг, обусловленность, температурная
      обеспеченность и сохранённые диапазоны всех сырых осей. Перегрузка без
      Models проверяет текущую модель pmA/pmH. }
    class function BuildValidationSamples(
      OrientationTolerance: Double = DefaultOrientationTolerance):
      TArray<TValidationSample>;
    class function RunTests: TValidationTestRun; overload;
    class function RunTests(
      const Huber: THuberIrlsOptions): TValidationTestRun; overload;
    class function RunTests(const Models: TArray<TTemperatureModel>;
      const Huber: THuberIrlsOptions): TValidationTestRun; overload;
    class function RunTests(const Models: TArray<TTemperatureModel>;
      const Huber: THuberIrlsOptions;
      const LogoOptions: TLogoSpatialOptions): TValidationTestRun; overload;

    { Сформировать читаемый текстовый отчёт по результату последнего RunTests.
      Перед заполнением OutRes очищается. Отчёт содержит сводные метрики,
      результаты каждого fold и диагностику принятых/отклонённых кандидатов
      LOTO, LTBO и LOGO. }
    class procedure TestResultsToStrings(OutRes: TStrings);

    { Краткий протокол приёмки по результату последнего RunTests.
      Для каждого вида проверки выводятся худшие по fold значения MeanAbs,
      P95 и MaxAbs, допуск, отдельные PASS/FAIL и названия худших fold.
      Общий результат определяется по строгому критерию MaxAbs. Допуски:
      зенит 0.15°, магнитное наклонение 0.20°, азимут 1.00°
      (метрика определена вне вертикальной области), нормы G/H 0.30/0.50 %. }
    class procedure SummaryTestResultsToStrings(OutRes: TStrings);

    { Краткое сравнение всех проверенных моделей и выбор лучшей.
      Для каждой модели подсчитываются прохождения MeanAbs, P95 и MaxAbs
      по всем сочетаниям вида проверки и контролируемого параметра.
      Модели ранжируются сначала по MeanAbs PASS, затем по P95 PASS и
      MaxAbs PASS; при равенстве выбирается меньшая нормированная ошибка. }
    class procedure SummaryModelTestResultsToStrings(OutRes: TStrings);

    { Подобрать границу Huber для уже выбранной структуры 2:1:2.
      Каждый Limit проверяется на одинаковом наборе LOTO/LTBO/LOGO/STRESS.
      Приоритет: минимальный нормированный индекс ошибки, затем MeanAbs,
      P95 и MaxAbs PASS. После выбора модель заново обучается на всех
      исходных строках. TestResults получает validation победителя.
      Старая перегрузка включает баланс MAX/MIN/SPHERE по умолчанию. }
    class function SelectBestHuberParameters(
      const HuberKValues: array of Double; OutRes: TStrings):
      TBestHuberParameters; overload;
    class function SelectBestHuberParameters(
      const HuberKValues: array of Double;
      BalanceMaxMinSphere: Boolean; OutRes: TStrings):
      TBestHuberParameters; overload;

    { Обучить HUBER 2:1:2 только на G/H max/min и проверить на "Сфере".
      Индексы являются нулевыми SourceIndex в массиве последнего Init.
      Массивы не должны пересекаться. Коррекция визира применяется, если
      SetupData.CorStolVisir=True. Рабочее состояние TpolyMath сохраняется. }
    class function TestMaxMinOnSphere(
      const MaxMinIndices, SphereIndices: TArray<Integer>;
      const Huber: THuberIrlsOptions; OutRes: TStrings):
      TMaxMinSphereTestResult;

    { Построить индексы непосредственно по TinclInput.Info.
      Для каждой строки Info должна содержать "Сфера" либо "=max"/"=min". }
    class procedure BuildMaxMinSphereIndices(
      const Inputs: TArray<TinclInput>;
      out MaxMinIndices, SphereIndices: TArray<Integer>);

    { Подобрать eStol.cVis так, чтобы постоянный коэффициент Yx
      акселерометра стал приблизительно равен нулю.

      Вызывать после Init и до окончательного RunLS. Вариант без параметров
      использует обычный МНК. Если итоговая тарировка выполняется Huber IRLS,
      следует вызвать одноимённую перегрузку с теми же настройками Huber.

      Возвращаемое значение совпадает с новым eStol.cVis, градусы. }
    class function CorrectVisir: Double; overload;
    class function CorrectVisir(
      const Huber: THuberIrlsOptions): Double; overload;
    class procedure RunZ;
//    class procedure RunXYAndStolZ(arz: TArray<Integer>);
    class procedure RunT;
    class procedure RunKoso;
    class procedure RunKosoV2;
    class procedure ClearStolError;

    class procedure KosoFindInkl(ivec: Integer; const koso: TFindLMKosStol; var Incl: TInclRes);
    class procedure FindInclRes(const vec: TSensorVect; const eS: TStolError; var Incl: TInclRes);
  end;

  TGkiPackedExporter = class
  public
    class function FromFit(const Fit: TLinCalibrationResult;
      AccScale, MagScale: Double): TGkiPackedLinearModel; overload;
    class function FromFit(const Fit: TLinCalibrationResult):
      TGkiPackedLinearModel; overload;
  end;


procedure VecExtract(vec: TSensorVect; var ax,ay,az,hx,hy,hz: Double);
function VecCollect(ax,ay,az,hx,hy,hz: Double): TSensorVect;


implementation

uses
  LotoAdapter;

type
  TStringContainsHelper = record helper for string
    function Contains(const Value: string;
      IgnoreCase: Boolean = True): Boolean;
  end;

  { Представитель группы ориентации. Все три угла циклические: например,
    359.9 и 0.1 градуса должны попасть в одну группу. }
  TOrientationKey = record
    Azi: Double;
    Zen: Double;
    Vis: Double;
  end;

function TStringContainsHelper.Contains(const Value: string;
  IgnoreCase: Boolean): Boolean;
begin
  if IgnoreCase then
  begin
    var V, S: string;
    V := AnsiUpperCase(Value);
    S := AnsiUpperCase(Self);
    Result := System.Pos(V, S) > 0;
  end
  else
    { Calling Contains(Value) here would resolve to this helper again because
      IgnoreCase has a default value and would recurse indefinitely. }
    Result := System.Pos(Value, Self) > 0;
end;

function CopyPolyResult(const Source: TPolyRes): TPolyRes;
begin
  for var Axis in SVectors do
  begin
    Result.G[Axis] := Copy(Source.G[Axis], 0, Length(Source.G[Axis]));
    Result.H[Axis] := Copy(Source.H[Axis], 0, Length(Source.H[Axis]));
  end;
end;

function CopyHuberDiagnostic(
  const Source: THuberIrlsDiagnostics): THuberIrlsDiagnostics;
begin
  Result := Source;
  Result.BasePointWeights := Copy(Source.BasePointWeights, 0,
    Length(Source.BasePointWeights));
  Result.PointWeights := Copy(Source.PointWeights, 0,
    Length(Source.PointWeights));
  Result.EffectivePointWeights := Copy(Source.EffectivePointWeights, 0,
    Length(Source.EffectivePointWeights));
end;

function OrientationAngleDistance(const A, B: Double): Double;
begin
  Result := Abs(TMetrInclinMath.DeltaAngle(A - B));
end;

function NormalizeAngle360(const Value: Double): Double;
begin
  Result := Value - Floor(Value / 360.0) * 360.0;
  if Result < 0 then
    Result := Result + 360.0;
  if Result >= 360.0 then
    Result := 0.0;
end;

{ TLogoSpatialOptions }

class function TLogoSpatialOptions.Default: TLogoSpatialOptions;
begin
  Result.AzimuthSectorWidth := 60.0;
  Result.ToolfaceStep := 72.0;
  Result.CheckerboardK := 5;
  Result.AxialTailFraction := 0.05;
  Result.MinRowsPerCoefficient := 5;
  Result.MaxConditionNumber := 1E8;
  Result.MinRawRangeRatio := 0.50;
end;

procedure TLogoSpatialOptions.Validate;
begin
  if IsNan(AzimuthSectorWidth) or IsInfinite(AzimuthSectorWidth) or
     (AzimuthSectorWidth <= 0) or (AzimuthSectorWidth > 180) then
    raise EArgumentOutOfRangeException.Create(
      'AzimuthSectorWidth must be finite and in 0..180 degrees');
  if IsNan(ToolfaceStep) or IsInfinite(ToolfaceStep) or
     (ToolfaceStep <= 0) or (ToolfaceStep > 180) then
    raise EArgumentOutOfRangeException.Create(
      'ToolfaceStep must be finite and in 0..180 degrees');
  if (CheckerboardK < 3) or (CheckerboardK > 32) then
    raise EArgumentOutOfRangeException.Create(
      'CheckerboardK must be in 3..32');
  if IsNan(AxialTailFraction) or IsInfinite(AxialTailFraction) or
     (AxialTailFraction <= 0) or (AxialTailFraction >= 0.25) then
    raise EArgumentOutOfRangeException.Create(
      'AxialTailFraction must be finite and in 0..0.25');
  if MinRowsPerCoefficient < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinRowsPerCoefficient must be at least one');
  if IsNan(MaxConditionNumber) or IsInfinite(MaxConditionNumber) or
     (MaxConditionNumber <= 1) then
    raise EArgumentOutOfRangeException.Create(
      'MaxConditionNumber must be finite and greater than one');
  if IsNan(MinRawRangeRatio) or IsInfinite(MinRawRangeRatio) or
     (MinRawRangeRatio <= 0) or (MinRawRangeRatio > 1) then
    raise EArgumentOutOfRangeException.Create(
      'MinRawRangeRatio must be finite and in 0..1');
end;

{ THuberIrlsOptions }

class function THuberIrlsOptions.OrdinaryLeastSquares: THuberIrlsOptions;
begin
  Result := Default(THuberIrlsOptions);
  Result.Enabled := False;
end;

class function THuberIrlsOptions.DefaultHuber: THuberIrlsOptions;
begin
  Result := Default(THuberIrlsOptions);
  Result.Enabled := True;
  Result.MaxIterations := 4;

  { 1.345 обычно применяют к одному нормально распределённому остатку.
    Здесь проверяется длина нормированного трёхмерного остатка, поэтому
    начальная граница 2.5 подавляет явные выбросы, не штрафуя основную массу
    корректных векторных измерений. }
  Result.Limit := 2.5;
  Result.WeightTolerance := 1E-3;
  Result.MinScale := 1E-12;
end;

procedure THuberIrlsOptions.Validate;
begin
  if not Enabled then
    Exit;
  if MaxIterations < 1 then
    raise EArgumentOutOfRangeException.Create(
      'Huber MaxIterations must be at least 1');
  if IsNan(Limit) or IsInfinite(Limit) or (Limit <= 0) then
    raise EArgumentOutOfRangeException.Create(
      'Huber Limit must be finite and positive');
  if IsNan(WeightTolerance) or IsInfinite(WeightTolerance) or
     (WeightTolerance <= 0) then
    raise EArgumentOutOfRangeException.Create(
      'Huber WeightTolerance must be finite and positive');
  if IsNan(MinScale) or IsInfinite(MinScale) or (MinScale <= 0) then
    raise EArgumentOutOfRangeException.Create(
      'Huber MinScale must be finite and positive');
end;

function Median(const Values: TArray<Double>): Double;
var
  Sorted: TArray<Double>;
  N: Integer;
begin
  N := Length(Values);
  if N = 0 then
    raise EArgumentException.Create('Median: input is empty');

  Sorted := Copy(Values, 0, N);
  TArray.Sort<Double>(Sorted);
  if Odd(N) then
    Result := Sorted[N div 2]
  else
    Result := 0.5 * (Sorted[N div 2 - 1] + Sorted[N div 2]);
end;

function RobustScaleMAD(const Values: TArray<Double>;
  const MinScale: Double): Double;
var
  Center: Double;
  Deviations: TArray<Double>;
begin
  Center := Median(Values);
  SetLength(Deviations, Length(Values));
  for var I := 0 to High(Values) do
    Deviations[I] := Abs(Values[I] - Center);

  { Коэффициент 1.4826 делает MAD согласованной оценкой sigma для
    одномерного нормального распределения. Ограничение снизу не позволяет
    делить на ноль при почти точном совпадении одной из координат. }
  Result := Max(1.4826 * Median(Deviations), MinScale);
end;

procedure lin_DesignRankAndCondition(const Model: TLinTemperatureModel;
  const SourceData: TArray<TinclInput>;
  const TrainingIndices: TArray<Integer>; Sensor: SetSetsor;
  out MinimumRank: Integer; out WorstCondition: Double);
const
  RelativeEigenTolerance = 1E-10;
var
  Design: TVArray<Double>;
  Gram: TArray<TArray<Double>>;
  Norms: TArray<Double>;
  Row, ColumnCount, P, Q, Iteration, MaximumIterations: Integer;
  EigenValue, MaximumEigen, MinimumEigen: Double;
  C, S, Tau, JacobiT, App, Aqq, Apq, Value,
    MaximumOffDiagonal: Double;
begin
  Model.lin_Validate;
  ColumnCount := Model.lin_CoeffCount;
  MinimumRank := ColumnCount;
  WorstCondition := 0;
  for var Axis in SVectors do
    SetLength(Design[Axis], Length(TrainingIndices) * ColumnCount);

  for Row := 0 to High(TrainingIndices) do
  begin
    var SourceIndex := TrainingIndices[Row];
    if (SourceIndex < 0) or (SourceIndex >= Length(SourceData)) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'lin_DesignRankAndCondition: SourceIndex=%d is invalid',
        [SourceIndex]);
    var Raw: TVector3;
    var Scale: Double;
    if Sensor = sAcc then
    begin
      Raw := SourceData[SourceIndex].G;
      Scale := SCALE_A;
    end
    else
    begin
      Raw := SourceData[SourceIndex].H;
      Scale := SCALE_H;
    end;
    for var Axis in SVectors do
    begin
      var AxisRow := Model.lin_CreateAxisRow(
        SourceData[SourceIndex].T, Raw, Axis, Scale);
      for var J := 0 to ColumnCount - 1 do
        Design[Axis][Row * ColumnCount + J] := AxisRow[J];
    end;
  end;

  for var Axis in SVectors do
  begin
    SetLength(Norms, ColumnCount);
    SetLength(Gram, ColumnCount);
    for P := 0 to ColumnCount - 1 do
    begin
      SetLength(Gram[P], ColumnCount);
      Norms[P] := 0;
      for Row := 0 to High(TrainingIndices) do
        Norms[P] := Norms[P] +
          Sqr(Design[Axis][Row * ColumnCount + P]);
      Norms[P] := Sqrt(Norms[P]);
    end;

    for P := 0 to ColumnCount - 1 do
      for Q := P to ColumnCount - 1 do
      begin
        Value := 0;
        if (Norms[P] > 0) and (Norms[Q] > 0) then
          for Row := 0 to High(TrainingIndices) do
            Value := Value +
              Design[Axis][Row * ColumnCount + P] *
              Design[Axis][Row * ColumnCount + Q] /
              (Norms[P] * Norms[Q]);
        Gram[P][Q] := Value;
        Gram[Q][P] := Value;
      end;

    MaximumIterations := 100 * ColumnCount * ColumnCount;
    for Iteration := 0 to MaximumIterations - 1 do
    begin
      MaximumOffDiagonal := 0;
      P := 0;
      Q := 0;
      for var I := 0 to ColumnCount - 2 do
        for var J := I + 1 to ColumnCount - 1 do
          if Abs(Gram[I][J]) > MaximumOffDiagonal then
          begin
            MaximumOffDiagonal := Abs(Gram[I][J]);
            P := I;
            Q := J;
          end;
      if MaximumOffDiagonal <= 1E-14 then
        Break;

      App := Gram[P][P];
      Aqq := Gram[Q][Q];
      Apq := Gram[P][Q];
      Tau := (Aqq - App) / (2 * Apq);
      if Tau >= 0 then
        JacobiT := 1 / (Tau + Sqrt(1 + Sqr(Tau)))
      else
        JacobiT := -1 / (-Tau + Sqrt(1 + Sqr(Tau)));
      C := 1 / Sqrt(1 + Sqr(JacobiT));
      S := JacobiT * C;

      for var K := 0 to ColumnCount - 1 do
        if (K <> P) and (K <> Q) then
        begin
          var Akp := Gram[K][P];
          var Akq := Gram[K][Q];
          Gram[K][P] := C * Akp - S * Akq;
          Gram[P][K] := Gram[K][P];
          Gram[K][Q] := S * Akp + C * Akq;
          Gram[Q][K] := Gram[K][Q];
        end;
      Gram[P][P] := App - JacobiT * Apq;
      Gram[Q][Q] := Aqq + JacobiT * Apq;
      Gram[P][Q] := 0;
      Gram[Q][P] := 0;
    end;

    MaximumEigen := 0;
    for P := 0 to ColumnCount - 1 do
      MaximumEigen := Max(MaximumEigen, Gram[P][P]);
    MinimumEigen := MaxDouble;
    var Rank := 0;
    for P := 0 to ColumnCount - 1 do
    begin
      EigenValue := Max(0.0, Gram[P][P]);
      if EigenValue > MaximumEigen * RelativeEigenTolerance then
      begin
        Inc(Rank);
        MinimumEigen := Min(MinimumEigen, EigenValue);
      end;
    end;
    MinimumRank := Min(MinimumRank, Rank);
    if (Rank < ColumnCount) or (MinimumEigen = MaxDouble) or
       (MinimumEigen <= 0) then
      WorstCondition := MaxDouble
    else
      WorstCondition := Max(WorstCondition,
        Sqrt(MaximumEigen / MinimumEigen));
  end;
end;

procedure lin_AddMetricError(var Metric: TValidationMetric;
  Error: Double; SourceIndex: Integer);
var
  N: Integer;
  A: Double;
begin
  if IsNan(Error) or IsInfinite(Error) then
    Exit;
  A := Abs(Error);
  if (Metric.Count = 0) or (A > Metric.MaxAbs) then
  begin
    Metric.MaxAbs := A;
    Metric.PeakSigned := Error;
    Metric.PeakSourceIndex := SourceIndex;
  end;
  Metric.SignedSum := Metric.SignedSum + Error;
  Metric.AbsSum := Metric.AbsSum + A;
  Metric.SquareSum := Metric.SquareSum + Sqr(Error);
  N := Length(Metric.AbsValues);
  SetLength(Metric.AbsValues, N + 1);
  Metric.AbsValues[N] := A;
  SetLength(Metric.ErrorPoints, N + 1);
  Metric.ErrorPoints[N].SourceIndex := SourceIndex;
  Metric.ErrorPoints[N].SignedError := Error;
  Inc(Metric.Count);
end;

procedure lin_FinalizeMetric(var Metric: TValidationMetric);
var
  P95Index: Integer;
begin
  if Metric.Count = 0 then
  begin
    Metric.MeanSigned := NaN;
    Metric.MeanAbs := NaN;
    Metric.RMS := NaN;
    Metric.Percentile95 := NaN;
    Exit;
  end;
  Metric.MeanSigned := Metric.SignedSum / Metric.Count;
  Metric.MeanAbs := Metric.AbsSum / Metric.Count;
  Metric.RMS := Sqrt(Metric.SquareSum / Metric.Count);
  TArray.Sort<Double>(Metric.AbsValues);
  P95Index := EnsureRange(Ceil(0.95 * Metric.Count) - 1,
    0, High(Metric.AbsValues));
  Metric.Percentile95 := Metric.AbsValues[P95Index];
end;

function lin_PassFail(Value, Limit: Double): string;
begin
  if Value <= Limit then
    Result := 'PASS'
  else
    Result := 'FAIL';
end;

function VecCollect(ax,ay,az,hx,hy,hz: Double): TSensorVect;
begin
  Result[sAcc].X := ax;
  Result[sAcc].Y := ay;
  Result[sAcc].z := az;
  Result[sMag].X := hx;
  Result[sMag].Y := hy;
  Result[sMag].z := hz;
end;

procedure VecExtract(vec: TSensorVect; var ax,ay,az,hx,hy,hz: Double);
begin
  ax := vec[sAcc].X;
  ay := vec[sAcc].Y;
  az := vec[sAcc].Z;
  hx := vec[sMag].X;
  hy := vec[sMag].Y;
  hz := vec[sMag].Z;
end;




{ TpolyMath }


class procedure TpolyMath.Init(pmA, pmH: PolyModel; Naklon: Double;
  Inp: TArray<TinclInput>);
var
  DataTMin, DataTMax: Double;
begin
  if Length(Inp) = 0 then
    raise EArgumentException.Create('TpolyMath.Init: input is empty');

  DataTMin := MaxDouble;
  DataTMax := -MaxDouble;
  for var Item in Inp do
  begin
    DataTMin := Min(DataTMin, Item.T);
    DataTMax := Max(DataTMax, Item.T);
  end;

  Init(pmA, pmH, Naklon, Inp, DataTMin, DataTMax);
end;

class procedure TpolyMath.Init(pmA, pmH: PolyModel; Naklon: Double;
  Inp: TArray<TinclInput>; FixedTMin, FixedTMax: Double);
var
  pwt: Integer;
begin
  if Length(Inp) = 0 then
    raise EArgumentException.Create('TpolyMath.Init: input is empty');
  if IsNan(FixedTMin) or IsInfinite(FixedTMin) or
     IsNan(FixedTMax) or IsInfinite(FixedTMax) or
     (FixedTMax <= FixedTMin) then
    raise EArgumentException.Create(
      'TpolyMath.Init: FixedTMax must be greater than FixedTMin');

  InpData.pmA := pmA;
  InpData.pmH := pmH;
  InpData.MNak := Naklon;
  InpData.Inpt := Inp;
  InpData.Tmin := FixedTMin;
  InpData.Tmax := FixedTMax;

  SetLength(acc, Length(inp));
  SetLength(mag, Length(inp));

  pwt := pmH.MaxPowT; if pmA.MaxPowT > pwt then pwt := pmA.MaxPowT;

  for var i := 0 to High(inp) do
   begin
    var atA := pmA.CreatePowerT(Inp[i].t,InpData.Tmin,InpData.Tmax, pwt);
    var atH := pmH.CreatePowerT(Inp[i].t,InpData.Tmin,InpData.Tmax, pwt);
    acc[i] := pmA.CreateRow(atA, Inp[i].G.V, SCALE_A);
    mag[i] := pmH.CreateRow(atH, Inp[i].H.V, SCALE_H);
   end;
end;


class procedure TpolyMath.RunLsSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
 var
  e: IEquations;
  info: Integer;
  x: PDoubleArray;
  R2: Double;
  n: Integer;
  k: Integer;
  cx: IDoubleMatrix;
  aaa: TVArray<Double>;
  bbb: TVArray<Double>;
begin
  //for var i := 0 to 2 do SetLength(aaa[i], Length(acc)*InpData.pmA.KoeffCnt);
  for var i := 0 to High(data) do
   begin
    var a := pm.RowToArrays(data[i]);
    var b := InclRes[i].etaSens[sns].V;
    //var b := EtalonData[i][sns].V;
    for var vk in SVectors do
     begin
      aaa[vk] := aaa[vk] + a[vk];
      bbb[vk] := bbb[vk] + [b[Integer(vk)]];
     end;
   end;
  EquationsFactory(e);
  for var vk in SVectors do
   begin
    CheckMath(e, e.LinearLS(@aaa[vk][0], Length(data), pm.KoeffCnt, @bbb[vk][0], info, x, R2, n, k, cx));
    SetLength(Res[vk], pm.KoeffCnt);
    for var I := 0 to pm.KoeffCnt-1 do Res[vk][i] := x[i];
   end;
end;

class procedure TpolyMath.RunHuberLsSensor(pm: PolyModel;
  const data: TArray<RowModel>; sns: SetSetsor;
  const Options: THuberIrlsOptions; var SensorRes: TVArray<Double>;
  out Diagnostics: THuberIrlsDiagnostics);
var
  LS: ILSFitting;
  Design: TVArray<Double>;
  Target: TVArray<Double>;
  Residual: TVArray<Double>;
  BaseWeight: TArray<Double>;
  HuberWeight: TArray<Double>;
  EffectiveWeight: TArray<Double>;
  AlglibWeight: TArray<Double>;
  NewWeight: Double;
  Q, Change: Double;
  Iter: Integer;

  procedure InitializeBaseWeights;
  var
    MaxMinCount, SphereCount, ClassifiedCount: Integer;
    MaxMinWeight, SphereWeight: Double;
    Name: string;
  begin
    for var I := 0 to High(BaseWeight) do
      BaseWeight[I] := 1.0;
    if not Options.BalanceMaxMinSphere then
      Exit;
    if Length(InpData.Inpt) <> Length(data) then
      raise EInvalidOpException.Create(
        'Balanced Huber weights require aligned input and sensor rows');

    MaxMinCount := 0;
    SphereCount := 0;
    for var I := 0 to High(InpData.Inpt) do
    begin
      Name := Trim(InpData.Inpt[I].Info);
      if Name.Contains('сфера', True) then
        Inc(SphereCount)
      else if Name.Contains('=max', True) or Name.Contains('=min', True) then
        Inc(MaxMinCount);
    end;

    { A one-group training fold needs no balancing.  With both groups,
      keep the average base weight equal to one and make their totals equal. }
    if (MaxMinCount = 0) or (SphereCount = 0) then
      Exit;
    ClassifiedCount := MaxMinCount + SphereCount;
    MaxMinWeight := ClassifiedCount / (2.0 * MaxMinCount);
    SphereWeight := ClassifiedCount / (2.0 * SphereCount);
    for var I := 0 to High(InpData.Inpt) do
    begin
      Name := Trim(InpData.Inpt[I].Info);
      if Name.Contains('сфера', True) then
        BaseWeight[I] := SphereWeight
      else if Name.Contains('=max', True) or Name.Contains('=min', True) then
        BaseWeight[I] := MaxMinWeight;
    end;
  end;

  procedure SolveWithCurrentWeights;
  var
    Info: Integer;
    Coefficients: PDoubleArray;
    Report: PSLFittingReport;
  begin
    { ALGLIB возводит переданный множитель в квадрат внутри целевой
      функции. Поэтому статистический Huber-вес w преобразуется в sqrt(w). }
    for var I := 0 to High(HuberWeight) do
    begin
      EffectiveWeight[I] := BaseWeight[I] * HuberWeight[I];
      AlglibWeight[I] := Sqrt(EffectiveWeight[I]);
    end;

    for var Axis in SVectors do
    begin
      CheckMath(LS, LS.LinearW(
        @Target[Axis][0], @AlglibWeight[0], @Design[Axis][0],
        Length(data), pm.KoeffCnt, Info, Coefficients, Report));
      if Info <= 0 then
        raise EMatLabException.CreateFmt(
          'ALGLIB LinearW failed for axis %s: info=%d',
          [string(SVectorsNames[Axis]), Info]);

      SetLength(SensorRes[Axis], pm.KoeffCnt);
      for var J := 0 to pm.KoeffCnt - 1 do
        SensorRes[Axis][J] := Coefficients[J];
    end;
  end;

  procedure CalculateResidualsAndScales;
  var
    Predicted: Double;
  begin
    for var Axis in SVectors do
      for var I := 0 to High(data) do
      begin
        Predicted := 0;
        for var J := 0 to pm.KoeffCnt - 1 do
          Predicted := Predicted +
            Design[Axis][I * pm.KoeffCnt + J] * SensorRes[Axis][J];
        Residual[Axis][I] := Target[Axis][I] - Predicted;
      end;

    Diagnostics.Scale.X := RobustScaleMAD(Residual[vX], Options.MinScale);
    Diagnostics.Scale.Y := RobustScaleMAD(Residual[vY], Options.MinScale);
    Diagnostics.Scale.Z := RobustScaleMAD(Residual[vZ], Options.MinScale);
  end;

begin
  Options.Validate;
  if not Options.Enabled then
    raise EArgumentException.Create(
      'RunHuberLsSensor requires Enabled=True');
  if Length(data) = 0 then
    raise EArgumentException.Create('RunHuberLsSensor: data is empty');

  Diagnostics := Default(THuberIrlsDiagnostics);
  SetLength(BaseWeight, Length(data));
  SetLength(HuberWeight, Length(data));
  SetLength(EffectiveWeight, Length(data));
  SetLength(AlglibWeight, Length(data));
  for var Axis in SVectors do
  begin
    SetLength(Residual[Axis], Length(data));
    Design[Axis] := [];
    Target[Axis] := [];
  end;

  { Матрица модели различается для выходных X, Y и Z, но веса измерений
    общие. Эталоны берутся из тех же InclRes, что и в обычном RunLS. }
  for var I := 0 to High(data) do
  begin
    var Rows := pm.RowToArrays(data[I]);
    var Reference := InclRes[I].etaSens[sns].V;
    HuberWeight[I] := 1.0;
    for var Axis in SVectors do
    begin
      Design[Axis] := Design[Axis] + Rows[Axis];
      Target[Axis] := Target[Axis] + [Reference[Integer(Axis)]];
    end;
  end;

  InitializeBaseWeights;

  LSFittingFactory(LS);
  Diagnostics.Converged := False;

  for Iter := 0 to Options.MaxIterations - 1 do
  begin
    SolveWithCurrentWeights;
    CalculateResidualsAndScales;

    Diagnostics.MaxWeightChange := 0;
    for var I := 0 to High(data) do
    begin
      Q := Sqrt(
        Sqr(Residual[vX][I] / Diagnostics.Scale.X) +
        Sqr(Residual[vY][I] / Diagnostics.Scale.Y) +
        Sqr(Residual[vZ][I] / Diagnostics.Scale.Z));

      if Q <= Options.Limit then
        NewWeight := 1.0
      else
        NewWeight := Options.Limit / Q;

      Change := Abs(NewWeight - HuberWeight[I]);
      Diagnostics.MaxWeightChange := Max(
        Diagnostics.MaxWeightChange, Change);
      HuberWeight[I] := NewWeight;
    end;

    Diagnostics.Iterations := Iter + 1;
    if Diagnostics.MaxWeightChange < Options.WeightTolerance then
    begin
      Diagnostics.Converged := True;
      Break;
    end;
  end;

  { После последнего пересчёта весов обязательно решаем задачу ещё раз.
    Иначе возвращённые коэффициенты соответствовали бы предыдущим весам. }
  SolveWithCurrentWeights;
  CalculateResidualsAndScales;

  Diagnostics.BasePointWeights := Copy(BaseWeight, 0, Length(BaseWeight));
  Diagnostics.PointWeights := Copy(HuberWeight, 0, Length(HuberWeight));
  Diagnostics.EffectivePointWeights := Copy(EffectiveWeight, 0,
    Length(EffectiveWeight));
  Diagnostics.MinWeight := 1.0;
  for var I := 0 to High(HuberWeight) do
  begin
    Diagnostics.MinWeight := Min(Diagnostics.MinWeight, HuberWeight[I]);
    if HuberWeight[I] < 1.0 - 1E-12 then
      Inc(Diagnostics.DownWeightedCount);
    if HuberWeight[I] < 0.5 then
      Inc(Diagnostics.StronglyDownWeightedCount);
  end;
end;

class procedure TpolyMath.RunLsT(pm: PolyModel; idxs: TArray<Integer>; sns: SetSetsor; vec: SetVector; var Res: TArray<Double>);
 var
  e: IEquations;
  info: Integer;
  x: PDoubleArray;
  R2: Double;
  n: Integer;
  k: Integer;
  cx: IDoubleMatrix;
  row: Tarray<RowModel>;
  aa: TArray<Double>;
  bb: TArray<Double>;
  pax: Integer;
  function RowToArrays(r: RowModel): TArray<Double>;
   begin
     Result := r.axs[vec] + r.dzs;
   end;
begin
  aa := [];
  bb := [];
  if sns = sAcc then row := acc else row := mag;
  for var i in idxs do
   begin
    var a := RowToArrays(row[i]);
    var b := InclRes[i].etaSens[sns].V[Integer(vec)];
    aa := aa + a;
    bb := bb + [b];
   end;
   EquationsFactory(e);
   CheckMath(e, e.LinearLS(@aa[0], Length(idxs), pm.AxCnt + pm.DzCnt, @bb[0], info, x, R2, n, k, cx));
   SetLength(Res, pm.KoeffCnt);
   for var I := 0 to High(Res) do Res[i]:= 0;
   case vec of
     vX: pax := pm.pXX;
     vY: pax := pm.pYY;
     vZ: pax := pm.pZZ;
   end;
   for var I := 0 to pm.AxCnt-1 do Res[pax+i] := x[i];
   for var I := 0 to pm.DzCnt-1 do Res[pm.pD+i] := x[pm.AxCnt+i];
end;

class procedure TpolyMath.RunT;
 var
  arrz, arrx, arry: TArray<Integer>;
  hrrz, hrrx, hrry: TArray<Integer>;
//  Res: TArray<Double>;
begin
 var n := InpData.MNak;
 for var ix := 0 to High(InpData.Inpt) do
  begin
    var i := InpData.Inpt[ix];
    if (i.Zen < 1) or (i.Zen > 359) or (Abs(i.Zen-180)<1) then arrz := arrz + [ix];
    if (Abs(i.Zen-90)<1) then
     begin
      if (i.Vis < 2) or (i.Vis > 358) or (Abs(i.Vis-180) < 4) then arrx := arrx + [ix];
      if (Abs(i.Vis-90) < 2) or (Abs(i.Vis-270) < 2) then arry := arry + [ix];
      if (Abs(i.Azi-90)<1) then
       begin
        if (Abs(i.Vis-n) < 1) or (Abs(i.Vis-180-n) < 1) then hrrx := hrrx + [ix];
        if (Abs(i.Vis-n-90) < 1) or (Abs(i.Vis-270-n) < 1) then hrry := hrry + [ix];
       end;
      if (Abs(i.Azi-270)<1) then
       begin
        if (Abs(i.Vis+n) < 2) or(Abs((i.Vis+n-360)) < 2) or (Abs(i.Vis-180+n) < 2) then hrrx := hrrx + [ix];
        if (Abs(i.Vis+n-90) < 1) or (Abs(i.Vis-270+n) < 1) then hrry := hrry + [ix];
       end
     end;
    if (abs(i.Zen - n) < 1) or (Abs(i.Zen - n -180)<1) then hrrz := hrrz + [ix];
  end;
  RunLsT(InpData.pmA,arrx,sAcc,vX, Res.G[vX]);
  RunLsT(InpData.pmA,arry,sAcc,vY, Res.G[vY]);
  RunLsT(InpData.pmA,arrz,sAcc,vZ, Res.G[vZ]);
  RunLsT(InpData.pmH,hrrx,sMag,vX, Res.H[vX]);
  RunLsT(InpData.pmH,hrry,sMag,vY, Res.H[vY]);
  RunLsT(InpData.pmH,hrrz,sMag,vZ, Res.H[vZ]);

//  RunXYAndStolZ(arrz);
end;

//class procedure TpolyMath.RunXYAndStolZ(arz: TArray<Integer>);
// var
//  e: ILMFitting;
//  xout, kb: PDoubleArray;
//  Rep: PLMFittingReport;
//
//begin
//   SetLength(arz, 8);
//   LMFittingFactory(e);
//   CheckMath(e, e.FitV(4, Length(arz)*3, @kb, 0.000001, 0, 0, 0, 100000, func_cb_ZY_StolZ, xout, rep));
//end;

function ResToVarray(xout: PDoubleArray; KoeffCnt: integer): TVArray<Double>;
begin
   var n := 0;
   for var vk in SVectors do
    begin
     SetLength(Result[vk], KoeffCnt);
     for var I := 0 to KoeffCnt-1 do
      begin
       Result[vk][i] := xout[n]; Inc(n);
      end;
    end;
end;

class procedure TpolyMath.RunZ;
 var
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
  bl,bh: TArray<Double>;
begin
   LMFittingFactory(e);
   var kb := Res.G[vx] + Res.G[vY]+ Res.G[vZ];
   var kc := InpData.pmA.KoeffCnt;
   var YxIdx := InpData.pmA.KyIdx;
   SetLength(bl,kc*3);
   SetLength(bh,kc*3);
   for var I := 0 to High(bl) do
    begin
     var Span := Max(Abs(kb[i]), 1.0);
     bl[i] := kb[i] - Span;
     bh[i] := kb[i] + Span;
    end;
   bl[YxIdx] := kb[YxIdx];
   bh[YxIdx] := kb[YxIdx];


   CheckMath(e, e.FitVB(Length(kb), Length(acc)*2, @kb[0],@bl[0],@bh[0], 0.0000000001, 0, 0,0, 100000, func_cb_zen, xout, rep));
   Res.G := ResToVarray(xout, InpData.pmA.KoeffCnt);
end;

class procedure TpolyMath.RunLMSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
 var
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  var YxIdx := pm.KyIdx;
  with LMAmpData do
  begin
   m:= pm;
   d := data;
   SetLength(bl,m.KoeffCnt*3);
   SetLength(bh,m.KoeffCnt*3);
   kBegin := Res[vx] + Res[vY]+ Res[vZ];
   for var I := 0 to High(bl) do
    begin
     var Span := Max(Abs(kBegin[i])*4, 1.0);
     bl[i] := kBegin[i] - Span;
     bh[i] := kBegin[i] + Span;
    end;
   bl[YxIdx] := kBegin[YxIdx];
   bh[YxIdx] := kBegin[YxIdx];
   LMFittingFactory(e);
   CheckMath(e, e.FitVB(Length(kBegin), Length(d), @kBegin[0], @bl[0],@bh[0], 0.000001, 0, 0, 0, 10000, func_cb_amp, xout, rep));
   Res := ResToVarray(xout, m.KoeffCnt);
  end;
end;

class function TpolyMath.CorrectVisir: Double;
begin
  Result := CorrectVisir(THuberIrlsOptions.OrdinaryLeastSquares);
end;

class function TpolyMath.CorrectVisir(
  const Huber: THuberIrlsOptions): Double;
const
  { Эти же пределы ранее использовались в SetupKoso для cVis.
    Ограничение не позволяет компенсировать большой ошибкой визира дефект
    данных или неверную модель акселерометра. }
  MinCVis = -10.0;
  MaxCVis =  10.0;

  { Yx является безразмерным коэффициентом перекрёстной чувствительности.
    Для практической коррекции достаточно приблизить его к нулю до 1E-6. }
  YxTolerance = 1E-6;
  CVisTolerance = 1E-8;
  MaxBisectionIterations = 48;
var
  SavedInclRes: TArray<TInclRes>;
  TrialRes: TVArray<Double>;
  TrialDiagnostics: THuberIrlsDiagnostics;
  OriginalCVis: Double;
  LeftCVis, RightCVis, MidCVis: Double;
  LeftYx0, RightYx0, MidYx0: Double;

  function EvaluateYx0(const CandidateCVis: Double): Double;
  var
    TrialStol: TStolError;
  begin
    { cVis влияет на эталонные векторы через TinclInput.VecEtalon.
      Поэтому для каждой пробной поправки заново строятся эталоны, после
      чего решается только задача акселерометра. Магнитометр для условия
      Yx0=0 не нужен и намеренно не пересчитывается. }
    TrialStol := eStol;
    TrialStol.cVis := CandidateCVis;

    SetLength(InclRes, Length(InpData.Inpt));
    for var I := 0 to High(InpData.Inpt) do
      InclRes[I].etaSens := InpData.Inpt[I].VecEtalon(
        RES_AMP, InpData.MNak, TrialStol);

    TrialRes := Default(TVArray<Double>);
    if Huber.Enabled then
      RunHuberLsSensor(InpData.pmA, acc, sAcc, Huber, TrialRes,
        TrialDiagnostics)
    else
      RunLsSensor(InpData.pmA, acc, sAcc, TrialRes);

    { В массиве коэффициентов отдельной оси индекс pYx указывает начало
      температурного полинома Yx; первый элемент и есть степень 0. }
    Result := TrialRes[vY][InpData.pmA.pYx];
  end;

begin
  Huber.Validate;
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TpolyMath.CorrectVisir must be called after TpolyMath.Init');
  if Length(acc) <> Length(InpData.Inpt) then
    raise EInvalidOpException.Create(
      'TpolyMath.CorrectVisir: accelerator rows are not initialized');

  VisirDiagnostics := Default(TVisirCorrectionDiagnostics);
  OriginalCVis := eStol.cVis;
  VisirDiagnostics.InitialCVis := OriginalCVis;

  { Внутренние пробные решения используют общее поле InclRes, поскольку
    существующие решатели получают эталоны из него. Сохраняем его состояние,
    чтобы CorrectVisir не подменял результаты ранее выполненного RunLS. }
  SavedInclRes := Copy(InclRes, 0, Length(InclRes));
  try
    VisirDiagnostics.InitialYx0 := EvaluateYx0(OriginalCVis);
    if Abs(VisirDiagnostics.InitialYx0) <= YxTolerance then
    begin
      VisirDiagnostics.CorrectedCVis := OriginalCVis;
      VisirDiagnostics.FinalYx0 := VisirDiagnostics.InitialYx0;
      VisirDiagnostics.Converged := True;
      Exit(OriginalCVis);
    end;

    { Для гарантированной и предсказуемой сходимости используется деление
      отрезка пополам. Сначала обязательно проверяем, что внутри допустимого
      диапазона действительно есть смена знака Yx0. }
    LeftCVis := MinCVis;
    RightCVis := MaxCVis;
    LeftYx0 := EvaluateYx0(LeftCVis);
    RightYx0 := EvaluateYx0(RightCVis);

    if LeftYx0 * RightYx0 > 0 then
    begin
      { При отсутствии корня eStol не изменяется. Это важнее, чем молча
        принять ближайшую границу и скрыть систематическую ошибку модели. }
      VisirDiagnostics.CorrectedCVis := OriginalCVis;
      VisirDiagnostics.FinalYx0 := VisirDiagnostics.InitialYx0;
      raise EInvalidOpException.CreateFmt(
        'TpolyMath.CorrectVisir: Yx0 has no zero in %.1f..%.1f° '
        + '(Yx0(left)=%.8g, Yx0(right)=%.8g)',
        [MinCVis, MaxCVis, LeftYx0, RightYx0]);
    end;

    MidCVis := OriginalCVis;
    MidYx0 := VisirDiagnostics.InitialYx0;
    for var Iter := 1 to MaxBisectionIterations do
    begin
      MidCVis := 0.5 * (LeftCVis + RightCVis);
      MidYx0 := EvaluateYx0(MidCVis);
      VisirDiagnostics.Iterations := Iter;

      if (Abs(MidYx0) <= YxTolerance) or
         (RightCVis - LeftCVis <= CVisTolerance) then
      begin
        VisirDiagnostics.Converged := Abs(MidYx0) <= YxTolerance;
        Break;
      end;

      if LeftYx0 * MidYx0 <= 0 then
      begin
        RightCVis := MidCVis;
        RightYx0 := MidYx0;
      end
      else
      begin
        LeftCVis := MidCVis;
        LeftYx0 := MidYx0;
      end;
    end;

    VisirDiagnostics.CorrectedCVis := MidCVis;
    VisirDiagnostics.FinalYx0 := MidYx0;
    if not VisirDiagnostics.Converged then
      raise EInvalidOpException.CreateFmt(
        'TpolyMath.CorrectVisir did not reach Yx0 tolerance: '
        + 'cVis=%.10g°, Yx0=%.10g', [MidCVis, MidYx0]);

    { Записываем поправку только после успешной сходимости. Последующий
      RunLS заново построит эталоны уже с найденным значением cVis. }
    eStol.cVis := MidCVis;
    Result := MidCVis;
  finally
    InclRes := SavedInclRes;
  end;
end;

class procedure TpolyMath.RunLS;
begin
  { Старая сигнатура намеренно сохраняет прежнее поведение. Робастный режим
    включается только явным вызовом перегрузки с DefaultHuber. }
  RunLS(THuberIrlsOptions.OrdinaryLeastSquares);
end;

class procedure TpolyMath.RunLS(const Huber: THuberIrlsOptions);
begin
  Huber.Validate;
  SetLength(InclRes, Length(InpData.Inpt));

  for var i := 0 to High(InpData.Inpt) do
    InclRes[i].etaSens := InpData.Inpt[i].VecEtalon(
      RES_AMP, InpData.MNak, eStol);

  HuberDiagnostics[sAcc] := Default(THuberIrlsDiagnostics);
  HuberDiagnostics[sMag] := Default(THuberIrlsDiagnostics);

  if Huber.Enabled then
  begin
    { Акселерометр и магнитометр получают независимые веса: выброс одного
      сенсора не должен автоматически штрафовать корректный второй сенсор. }
    RunHuberLsSensor(InpData.pmA, acc, sAcc, Huber, Res.G,
      HuberDiagnostics[sAcc]);
    RunHuberLsSensor(InpData.pmH, mag, sMag, Huber, Res.H,
      HuberDiagnostics[sMag]);
  end
  else
  begin
    RunLsSensor(InpData.pmA, acc, sAcc, Res.G);
    RunLsSensor(InpData.pmH, mag, sMag, Res.H);
  end;
end;

class function TpolyMath.lin_CreateModel(
  CrossLinear: Boolean): TLinTemperatureModel;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateModel must be called after TpolyMath.Init');
  Result := TLinTemperatureModel.lin_FromInputs(
    InpData.Inpt, CrossLinear);
end;

class function TpolyMath.lin_CreatePiecewiseCrossModel:
  TLinTemperatureModel;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreatePiecewiseCrossModel must be called after TpolyMath.Init');
  Result := TLinTemperatureModel.lin_FromInputsPiecewiseCross(
    InpData.Inpt);
end;

class function TpolyMath.lin_CreateFiveNodeCrossModel:
  TLinTemperatureModel;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateFiveNodeCrossModel must be called after TpolyMath.Init');
  Result := TLinTemperatureModel.lin_FromInputsFiveNodeCross(
    InpData.Inpt);
end;

class function TpolyMath.lin_CreateReducedNodeModel(
  NodeCount: Integer; CrossLinear: Boolean): TLinTemperatureModel;
var
  Nodes: TArray<Double>;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateReducedNodeModel must be called after TpolyMath.Init');
  Nodes := lin_BuildReducedTemperatureNodes(InpData.Inpt, NodeCount);
  Result := TLinTemperatureModel.lin_Create(Nodes, CrossLinear);
end;

class function TpolyMath.lin_CreateReducedFiveNodeCrossModel(
  NodeCount: Integer): TLinTemperatureModel;
var
  MainNodes, CrossNodes: TArray<Double>;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateReducedFiveNodeCrossModel must be called after '+
      'TpolyMath.Init');
  MainNodes := lin_BuildReducedTemperatureNodes(
    InpData.Inpt, NodeCount);
  CrossNodes := lin_BuildTemperatureCenters(InpData.Inpt);
  if Length(CrossNodes) <> 5 then
    raise EInvalidOpException.CreateFmt(
      'lin_CreateReducedFiveNodeCrossModel expected five SetNo '+
      'centers, got %d', [Length(CrossNodes)]);
  Result := TLinTemperatureModel.lin_CreatePiecewiseCrossAt(
    MainNodes, CrossNodes);
end;

class function TpolyMath.lin_CreateReducedCrossNodeModel(
  MainNodeCount, CrossNodeCount: Integer): TLinTemperatureModel;
var
  MainNodes, CrossNodes: TArray<Double>;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateReducedCrossNodeModel must be called after '+
      'TpolyMath.Init');
  MainNodes := lin_BuildReducedTemperatureNodes(
    InpData.Inpt, MainNodeCount);
  if CrossNodeCount = MainNodeCount then
    CrossNodes := Copy(MainNodes, 0, Length(MainNodes))
  else
    CrossNodes := lin_BuildReducedTemperatureNodes(
      InpData.Inpt, CrossNodeCount);
  Result := TLinTemperatureModel.lin_CreatePiecewiseCrossAt(
    MainNodes, CrossNodes);
end;

class function TpolyMath.lin_CreateTargetedZenithModel(
  MainNodeCount: Integer): TLinTemperatureModel;
var
  Ranges: TArray<TLinTemperatureRange>;
  Centers, MainNodes: TArray<Double>;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CreateTargetedZenithModel must be called after '+
      'TpolyMath.Init');
  if (MainNodeCount <> 7) and (MainNodeCount <> 8) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Targeted Zenith main-node count must be 7 or 8, got %d',
      [MainNodeCount]);

  Ranges := lin_BuildTemperatureRanges(InpData.Inpt);
  Centers := lin_BuildTemperatureCenters(InpData.Inpt);
  if (Length(Ranges) <> 5) or (Length(Centers) <> 5) then
    raise EInvalidOpException.CreateFmt(
      'lin_CreateTargetedZenithModel expected five SetNo ranges, '+
      'got ranges=%d centers=%d',
      [Length(Ranges), Length(Centers)]);

  SetLength(MainNodes, MainNodeCount);
  MainNodes[0] := Centers[0];
  MainNodes[1] := Centers[1];
  MainNodes[2] := Centers[2];
  MainNodes[3] := Ranges[2].MaxTemperature;
  if MainNodeCount = 7 then
  begin
    MainNodes[4] := Centers[3];
    MainNodes[5] := Ranges[4].MinTemperature;
    MainNodes[6] := Ranges[4].MaxTemperature;
  end
  else
  begin
    MainNodes[4] := Ranges[3].MinTemperature;
    MainNodes[5] := Ranges[3].MaxTemperature;
    MainNodes[6] := Ranges[4].MinTemperature;
    MainNodes[7] := Ranges[4].MaxTemperature;
  end;

  Result := TLinTemperatureModel.lin_CreatePiecewiseCrossAt(
    MainNodes, Centers);
end;

class function TpolyMath.lin_RunLS(const Model: TLinTemperatureModel;
  const Huber: THuberIrlsOptions): TLinCalibrationResult;
var
  TrainingIndices: TArray<Integer>;
begin
  SetLength(TrainingIndices, Length(InpData.Inpt));
  for var I := 0 to High(TrainingIndices) do
    TrainingIndices[I] := I;
  Result := lin_RunLS(Model, TrainingIndices, Huber);
end;

class function TpolyMath.lin_RunLS(const Model: TLinTemperatureModel;
  const TrainingIndices: TArray<Integer>;
  const Huber: THuberIrlsOptions): TLinCalibrationResult;
begin
  Result := lin_RunSensorModels(Model, Model, TrainingIndices,
    Huber, Huber);
end;

class function TpolyMath.lin_RunSensorModels(
  const AccModel, MagModel: TLinTemperatureModel;
  const TrainingIndices: TArray<Integer>;
  const AccHuber, MagHuber: THuberIrlsOptions): TLinCalibrationResult;
var
  References: TArray<TSensorVect>;

  procedure lin_FitSensor(Sensor: SetSetsor;
    const SensorModel: TLinTemperatureModel;
    const SensorHuber: THuberIrlsOptions;
    var SensorCoefficients: TVArray<Double>;
    out Diagnostics: THuberIrlsDiagnostics);
  var
    LS: ILSFitting;
    Design, Target, Residual: TVArray<Double>;
    BaseWeight, HuberWeight, EffectiveWeight,
      AlglibWeight: TArray<Double>;
    ColumnCount, Iteration: Integer;

    procedure lin_InitializeBaseWeights;
    var
      MaxMinCount, SphereCount, ClassifiedCount: Integer;
      MaxMinWeight, SphereWeight: Double;
    begin
      for var I := 0 to High(BaseWeight) do
        BaseWeight[I] := 1.0;
      if not SensorHuber.BalanceMaxMinSphere then
        Exit;

      MaxMinCount := 0;
      SphereCount := 0;
      for var I := 0 to High(TrainingIndices) do
      begin
        var Info := InpData.Inpt[TrainingIndices[I]].Info;
        if lin_Contains(Info, 'сфера') then
          Inc(SphereCount)
        else if lin_Contains(Info, '=max') or
                lin_Contains(Info, '=min') then
          Inc(MaxMinCount);
      end;
      if (MaxMinCount = 0) or (SphereCount = 0) then
        Exit;

      ClassifiedCount := MaxMinCount + SphereCount;
      MaxMinWeight := ClassifiedCount / (2.0 * MaxMinCount);
      SphereWeight := ClassifiedCount / (2.0 * SphereCount);
      for var I := 0 to High(TrainingIndices) do
      begin
        var Info := InpData.Inpt[TrainingIndices[I]].Info;
        if lin_Contains(Info, 'сфера') then
          BaseWeight[I] := SphereWeight
        else if lin_Contains(Info, '=max') or
                lin_Contains(Info, '=min') then
          BaseWeight[I] := MaxMinWeight;
      end;
    end;

    procedure lin_SolveWithCurrentWeights;
    var
      Info: Integer;
      Coefficients: PDoubleArray;
      Report: PSLFittingReport;
    begin
      for var I := 0 to High(HuberWeight) do
      begin
        EffectiveWeight[I] := BaseWeight[I] * HuberWeight[I];
        AlglibWeight[I] := Sqrt(EffectiveWeight[I]);
      end;

      for var Axis in SVectors do
      begin
        CheckMath(LS, LS.LinearW(
          @Target[Axis][0], @AlglibWeight[0], @Design[Axis][0],
          Length(TrainingIndices), ColumnCount, Info,
          Coefficients, Report));
        if Info <= 0 then
          raise EMatLabException.CreateFmt(
            'lin_RunLS LinearW failed for sensor %d axis %s: info=%d',
            [Ord(Sensor), string(SVectorsNames[Axis]), Info]);
        SetLength(SensorCoefficients[Axis], ColumnCount);
        for var J := 0 to ColumnCount - 1 do
          SensorCoefficients[Axis][J] := Coefficients[J];
      end;
    end;

    procedure lin_CalculateResidualsAndScales;
    begin
      for var Axis in SVectors do
        for var I := 0 to High(TrainingIndices) do
        begin
          var Predicted := 0.0;
          for var J := 0 to ColumnCount - 1 do
            Predicted := Predicted +
              Design[Axis][I * ColumnCount + J] *
              SensorCoefficients[Axis][J];
          Residual[Axis][I] := Target[Axis][I] - Predicted;
        end;

      if SensorHuber.Enabled then
      begin
        Diagnostics.Scale.X := RobustScaleMAD(
          Residual[vX], SensorHuber.MinScale);
        Diagnostics.Scale.Y := RobustScaleMAD(
          Residual[vY], SensorHuber.MinScale);
        Diagnostics.Scale.Z := RobustScaleMAD(
          Residual[vZ], SensorHuber.MinScale);
      end;
    end;

  begin
    ColumnCount := SensorModel.lin_CoeffCount;
    Diagnostics := Default(THuberIrlsDiagnostics);
    SetLength(BaseWeight, Length(TrainingIndices));
    SetLength(HuberWeight, Length(TrainingIndices));
    SetLength(EffectiveWeight, Length(TrainingIndices));
    SetLength(AlglibWeight, Length(TrainingIndices));
    for var Axis in SVectors do
    begin
      SetLength(Design[Axis], Length(TrainingIndices) * ColumnCount);
      SetLength(Target[Axis], Length(TrainingIndices));
      SetLength(Residual[Axis], Length(TrainingIndices));
    end;

    for var I := 0 to High(TrainingIndices) do
    begin
      var SourceIndex := TrainingIndices[I];
      var Raw: TVector3;
      var Scale: Double;
      if Sensor = sAcc then
      begin
        Raw := InpData.Inpt[SourceIndex].G;
        Scale := SCALE_A;
      end
      else
      begin
        Raw := InpData.Inpt[SourceIndex].H;
        Scale := SCALE_H;
      end;

      HuberWeight[I] := 1.0;
      for var Axis in SVectors do
      begin
        var AxisRow := SensorModel.lin_CreateAxisRow(
          InpData.Inpt[SourceIndex].T, Raw, Axis, Scale);
        for var J := 0 to ColumnCount - 1 do
          Design[Axis][I * ColumnCount + J] := AxisRow[J];
        Target[Axis][I] :=
          References[SourceIndex][Sensor].V[Integer(Axis)];
      end;
    end;

    lin_InitializeBaseWeights;
    LSFittingFactory(LS);
    if SensorHuber.Enabled then
    begin
      for Iteration := 0 to SensorHuber.MaxIterations - 1 do
      begin
        lin_SolveWithCurrentWeights;
        lin_CalculateResidualsAndScales;
        Diagnostics.MaxWeightChange := 0;
        for var I := 0 to High(TrainingIndices) do
        begin
          var Q := Sqrt(
            Sqr(Residual[vX][I] / Diagnostics.Scale.X) +
            Sqr(Residual[vY][I] / Diagnostics.Scale.Y) +
            Sqr(Residual[vZ][I] / Diagnostics.Scale.Z));
          var NewWeight: Double;
          if Q <= SensorHuber.Limit then
            NewWeight := 1.0
          else
            NewWeight := SensorHuber.Limit / Q;
          Diagnostics.MaxWeightChange := Max(
            Diagnostics.MaxWeightChange,
            Abs(NewWeight - HuberWeight[I]));
          HuberWeight[I] := NewWeight;
        end;
        Diagnostics.Iterations := Iteration + 1;
        if Diagnostics.MaxWeightChange < SensorHuber.WeightTolerance then
        begin
          Diagnostics.Converged := True;
          Break;
        end;
      end;
      lin_SolveWithCurrentWeights;
      lin_CalculateResidualsAndScales;
    end
    else
    begin
      lin_SolveWithCurrentWeights;
      Diagnostics.Converged := True;
    end;

    Diagnostics.BasePointWeights := Copy(BaseWeight, 0,
      Length(BaseWeight));
    Diagnostics.PointWeights := Copy(HuberWeight, 0,
      Length(HuberWeight));
    Diagnostics.EffectivePointWeights := Copy(EffectiveWeight, 0,
      Length(EffectiveWeight));
    Diagnostics.MinWeight := 1.0;
    for var I := 0 to High(HuberWeight) do
    begin
      Diagnostics.MinWeight := Min(Diagnostics.MinWeight,
        HuberWeight[I]);
      if HuberWeight[I] < 1.0 - 1E-12 then
        Inc(Diagnostics.DownWeightedCount);
      if HuberWeight[I] < 0.5 then
        Inc(Diagnostics.StronglyDownWeightedCount);
    end;
  end;

begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_RunSensorModels must be called after TpolyMath.Init');
  if Length(TrainingIndices) = 0 then
    raise EArgumentException.Create(
      'lin_RunSensorModels: TrainingIndices is empty');
  AccModel.lin_Validate;
  MagModel.lin_Validate;
  AccHuber.Validate;
  MagHuber.Validate;

  Result := Default(TLinCalibrationResult);
  Result.Model := lin_CopyTemperatureModel(AccModel);
  Result.MagModel := lin_CopyTemperatureModel(MagModel);
  Result.SeparateSensorModels :=
    (AccModel.lin_CoeffCount <> MagModel.lin_CoeffCount) or
    (AccModel.CrossLinear <> MagModel.CrossLinear) or
    (AccModel.CrossPiecewise <> MagModel.CrossPiecewise);
  Result.AccHuber := AccHuber;
  Result.MagHuber := MagHuber;
  Result.TrainingIndices := Copy(TrainingIndices, 0,
    Length(TrainingIndices));
  Result.StolError := eStol;
  for var SourceIndex in TrainingIndices do
    if (SourceIndex < 0) or (SourceIndex >= Length(InpData.Inpt)) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'lin_RunSensorModels: SourceIndex=%d is invalid', [SourceIndex]);

  SetLength(References, Length(InpData.Inpt));
  for var I := 0 to High(InpData.Inpt) do
    References[I] := InpData.Inpt[I].VecEtalon(
      RES_AMP, InpData.MNak, Result.StolError);

  lin_DesignRankAndCondition(AccModel, InpData.Inpt,
    TrainingIndices, sAcc, Result.AccRank, Result.AccCondition);
  lin_DesignRankAndCondition(MagModel, InpData.Inpt,
    TrainingIndices, sMag, Result.MagRank, Result.MagCondition);
  if Result.AccRank < AccModel.lin_CoeffCount then
    raise EInvalidOpException.CreateFmt(
      'lin_RunSensorModels: accelerometer rank %d is less than required %d',
      [Result.AccRank, AccModel.lin_CoeffCount]);
  if Result.MagRank < MagModel.lin_CoeffCount then
    raise EInvalidOpException.CreateFmt(
      'lin_RunSensorModels: magnetometer rank %d is less than required %d',
      [Result.MagRank, MagModel.lin_CoeffCount]);

  lin_FitSensor(sAcc, AccModel, AccHuber, Result.Coefficients.G,
    Result.Diagnostics[sAcc]);
  lin_FitSensor(sMag, MagModel, MagHuber, Result.Coefficients.H,
    Result.Diagnostics[sMag]);
end;

class function TpolyMath.lin_RunHybridFiveNode(
  const AccHuber, MagHuber: THuberIrlsOptions):
  TLinCalibrationResult;
begin
  var TrainingIndices: TArray<Integer>;
  SetLength(TrainingIndices, Length(InpData.Inpt));
  for var I := 0 to High(TrainingIndices) do
    TrainingIndices[I] := I;
  Result := lin_RunSensorModels(lin_CreateModel(True),
    lin_CreateFiveNodeCrossModel, TrainingIndices,
    AccHuber, MagHuber);
end;

class function TpolyMath.lin_CalculateAll(
  const Fit: TLinCalibrationResult): TLinAllMetricsResult;
const
  MetricCount = 7;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CalculateAll must be called after TpolyMath.Init');
  Fit.Model.lin_Validate;
  if Fit.SeparateSensorModels then
    Fit.MagModel.lin_Validate;
  Result := Default(TLinAllMetricsResult);
  SetLength(Result.Calculated, Length(InpData.Inpt));
  SetLength(Result.Metrics, MetricCount);

  for var I := 0 to High(InpData.Inpt) do
  begin
    var Corrected: TSensorVect;
    Fit.Model.lin_FindAxis(Fit.Coefficients.G,
      InpData.Inpt[I].T, InpData.Inpt[I].G, SCALE_A,
      Corrected[sAcc]);
    if Fit.SeparateSensorModels then
      Fit.MagModel.lin_FindAxis(Fit.Coefficients.H,
        InpData.Inpt[I].T, InpData.Inpt[I].H, SCALE_H,
        Corrected[sMag])
    else
      Fit.Model.lin_FindAxis(Fit.Coefficients.H,
        InpData.Inpt[I].T, InpData.Inpt[I].H, SCALE_H,
        Corrected[sMag]);

    Result.Calculated[I] := Default(TInclRes);
    Result.Calculated[I].Inp := @InpData.Inpt[I];
    FindInclRes(Corrected, Fit.StolError, Result.Calculated[I]);
    var Incl := Result.Calculated[I];

    lin_AddMetricError(Result.Metrics[0], Incl.Zen.Error, I);
    var RefZenith := DegNormalize(InpData.Inpt[I].Zen);
    if RefZenith > 180.0 then
      RefZenith := 360.0 - RefZenith;
    if (RefZenith >= 5.0) and (RefZenith <= 175.0) then
      lin_AddMetricError(Result.Metrics[1], Incl.Azi.Error, I);
    lin_AddMetricError(Result.Metrics[2], Incl.Otk.Error, I);
    lin_AddMetricError(Result.Metrics[3], Incl.Nakl.Error, I);
    lin_AddMetricError(Result.Metrics[4],
      TMetrInclinMath.DeltaAngle(
        Incl.Nakl.Angle - Incl.Nakl.CorStol), I);
    lin_AddMetricError(Result.Metrics[5],
      Incl.erAmp[sAcc] / RES_AMP * 100.0, I);
    var ExpectedMagnetNorm := RES_AMP *
      InpData.Inpt[I].EtalonMag / 1000.0;
    if not IsZero(ExpectedMagnetNorm) then
      lin_AddMetricError(Result.Metrics[6],
        Incl.erAmp[sMag] / ExpectedMagnetNorm * 100.0, I);
  end;

  for var I := 0 to High(Result.Metrics) do
    lin_FinalizeMetric(Result.Metrics[I]);
end;

class procedure TpolyMath.lin_AllMetricsToStrings(
  const Fit: TLinCalibrationResult; OutRes: TStrings);
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5°)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string =
    ('°', '°', '°', '%', '%');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_CrossModelName(
    const Model: TLinTemperatureModel): string;
  begin
    if Model.CrossPiecewise then
      Result := Format('piecewise-linear T (%d nodes)',
        [Model.lin_CrossNodeCount])
    else if Model.CrossLinear then
      Result := 'linear T'
    else
      Result := 'constant';
  end;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  var AllMetrics := lin_CalculateAll(Fit);
  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI PIECEWISE-LINEAR TEMPERATURE MODEL');
    OutRes.Add(StringOfChar('=', 106));
    if Fit.SeparateSensorModels then
      OutRes.Add(Format('Training rows: %d; G coefficients/axis: %d; '+
        'G cross: %s; H coefficients/axis: %d; H cross: %s',
        [Length(Fit.TrainingIndices), Fit.Model.lin_CoeffCount,
         lin_CrossModelName(Fit.Model), Fit.MagModel.lin_CoeffCount,
         lin_CrossModelName(Fit.MagModel)]))
    else
      OutRes.Add(Format('Training rows: %d; nodes: %d; '+
        'coefficients/output axis: %d; cross model: %s',
        [Length(Fit.TrainingIndices), Fit.Model.lin_NodeCount,
         Fit.Model.lin_CoeffCount, lin_CrossModelName(Fit.Model)]));
    var NodeLine := 'Temperature nodes, °C:';
    for var Node in Fit.Model.TemperatureNodes do
      NodeLine := NodeLine + Format(' %.6f', [Node]);
    OutRes.Add(NodeLine);
    if Fit.Model.CrossPiecewise then
    begin
      NodeLine := 'Cross temperature nodes, °C:';
      for var Node in Fit.Model.CrossTemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
      OutRes.Add(NodeLine);
    end;
    if Fit.SeparateSensorModels and Fit.MagModel.CrossPiecewise then
    begin
      NodeLine := 'H cross temperature nodes, °C:';
      for var Node in Fit.MagModel.CrossTemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
      OutRes.Add(NodeLine);
    end;
    var MagCoeffCount := Fit.Model.lin_CoeffCount;
    if Fit.SeparateSensorModels then
      MagCoeffCount := Fit.MagModel.lin_CoeffCount;
    OutRes.Add(Format('Rank: G=%d/%d; H=%d/%d; '+
      'condition: G=%.6g; H=%.6g',
      [Fit.AccRank, Fit.Model.lin_CoeffCount,
       Fit.MagRank, MagCoeffCount,
       Fit.AccCondition, Fit.MagCondition]));
    OutRes.Add(Format('Huber G: iterations=%d; converged=%s; '+
      'down-weighted=%d; min weight=%.6g',
      [Fit.Diagnostics[sAcc].Iterations,
       BoolToStr(Fit.Diagnostics[sAcc].Converged, True),
       Fit.Diagnostics[sAcc].DownWeightedCount,
       Fit.Diagnostics[sAcc].MinWeight]));
    OutRes.Add(Format('Huber H: iterations=%d; converged=%s; '+
      'down-weighted=%d; min weight=%.6g',
      [Fit.Diagnostics[sMag].Iterations,
       BoolToStr(Fit.Diagnostics[sMag].Converged, True),
       Fit.Diagnostics[sMag].DownWeightedCount,
       Fit.Diagnostics[sMag].MinWeight]));
    OutRes.Add(Format('Huber limits: kG=%.6g; kH=%.6g',
      [Fit.AccHuber.Limit, Fit.MagHuber.Limit]));
    OutRes.Add('');
    OutRes.Add('ALL-ROW METRICS');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
      ['Parameter', 'N', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));
    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := AllMetrics.Metrics[
        ControlledMetricIndex[ControlledIndex]];
      OutRes.Add(Format('%-25s %7d %7.3f %-3s %4s '+
        '%7.3f %-3s %4s %7.3f %-3s %4s %6.3f %-3s',
        [ControlledMetricName[ControlledIndex], Metric.Count,
         Metric.MeanAbs, ControlledMetricUnit[ControlledIndex],
         lin_PassFail(Metric.MeanAbs,
           ControlledMetricLimit[ControlledIndex]),
         Metric.Percentile95, ControlledMetricUnit[ControlledIndex],
         lin_PassFail(Metric.Percentile95,
           ControlledMetricLimit[ControlledIndex]),
         Metric.MaxAbs, ControlledMetricUnit[ControlledIndex],
         lin_PassFail(Metric.MaxAbs,
           ControlledMetricLimit[ControlledIndex]),
         ControlledMetricLimit[ControlledIndex],
         ControlledMetricUnit[ControlledIndex]]));
    end;
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_SelectBestHuberParameters(
  const HuberKValues: array of Double;
  CrossLinear, BalanceMaxMinSphere: Boolean;
  OutRes: TStrings): TLinBestHuberParameters;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function lin_PassFailText(Value, Limit: Double): string;
  begin
    if Value <= Limit then
      Result := 'PASS'
    else
      Result := 'FAIL';
  end;

  function lin_BuildCandidate(
    const Fit: TLinCalibrationResult;
    const Metrics: TLinAllMetricsResult;
    Limit: Double): TLinHuberKCandidateResult;
  begin
    Result := Default(TLinHuberKCandidateResult);
    Result.Limit := Limit;
    Result.Converged := Fit.Diagnostics[sAcc].Converged and
      Fit.Diagnostics[sMag].Converged;

    if Length(Metrics.Metrics) <= ControlledMetricIndex[
      ControlledMetricCount - 1] then
      raise EInvalidOpException.Create(
        'lin_SelectBestHuberParameters: incomplete ALL metrics');

    Result.ZenithMaxAbs := Metrics.Metrics[0].MaxAbs;
    Result.MagneticInclinationMaxAbs := Metrics.Metrics[4].MaxAbs;
    Result.AzimuthMaxAbs := Metrics.Metrics[1].MaxAbs;
    Result.AccelerometerNormMaxAbs := Metrics.Metrics[5].MaxAbs;
    Result.MagnetometerNormMaxAbs := Metrics.Metrics[6].MaxAbs;
    Result.MagneticInclinationPass :=
      Result.MagneticInclinationMaxAbs <= ControlledMetricLimit[1];
    Result.MagnetometerNormPass :=
      Result.MagnetometerNormMaxAbs <= ControlledMetricLimit[4];

    Result.NormalizedMaxError := 0;
    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := Metrics.Metrics[ControlledMetricIndex[I]];
      if Metric.Count = 0 then
        raise EInvalidOpException.CreateFmt(
          'lin_SelectBestHuberParameters: metric %d is empty', [I]);
      if Metric.MaxAbs <= ControlledMetricLimit[I] then
        Inc(Result.MaxAbsPassCount);
      Result.NormalizedMaxError := Result.NormalizedMaxError +
        Metric.MaxAbs / ControlledMetricLimit[I];
    end;
    Result.NormalizedMaxError := Result.NormalizedMaxError /
      ControlledMetricCount;
  end;

  function lin_IsBetter(const A,
    B: TLinHuberKCandidateResult): Boolean;
  begin
    { A non-converged IRLS result is never allowed to beat a converged one. }
    if A.Converged <> B.Converged then
      Exit(A.Converged);

    { The new model was introduced specifically to keep the H norm below
      0.5 percent.  Treat this as a hard selection constraint. }
    if A.MagnetometerNormPass <> B.MagnetometerNormPass then
      Exit(A.MagnetometerNormPass);

    { Then solve the remaining strict failure: magnetic inclination. }
    if A.MagneticInclinationPass <> B.MagneticInclinationPass then
      Exit(A.MagneticInclinationPass);
    if not SameValue(A.MagneticInclinationMaxAbs,
      B.MagneticInclinationMaxAbs, 1E-12) then
      Exit(A.MagneticInclinationMaxAbs <
        B.MagneticInclinationMaxAbs);

    if A.MaxAbsPassCount <> B.MaxAbsPassCount then
      Exit(A.MaxAbsPassCount > B.MaxAbsPassCount);
    if not SameValue(A.NormalizedMaxError,
      B.NormalizedMaxError, 1E-12) then
      Exit(A.NormalizedMaxError < B.NormalizedMaxError);

    { With indistinguishable metrics prefer weaker down-weighting. }
    Result := A.Limit > B.Limit;
  end;

var
  CandidateFit: TLinCalibrationResult;
  CandidateMetrics: TLinAllMetricsResult;
  CandidateHuber: THuberIrlsOptions;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_SelectBestHuberParameters must be called after TpolyMath.Init');
  if Length(HuberKValues) = 0 then
    raise EArgumentException.Create('HuberKValues must not be empty');

  Result := Default(TLinBestHuberParameters);
  Result.SelectedIndex := -1;
  Result.Model := lin_CreateModel(CrossLinear);
  SetLength(Result.Candidates, Length(HuberKValues));

  for var I := 0 to High(HuberKValues) do
  begin
    if IsNan(HuberKValues[I]) or IsInfinite(HuberKValues[I]) or
       (HuberKValues[I] <= 0) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'HuberKValues[%d] must be finite and positive', [I]);

    CandidateHuber := THuberIrlsOptions.DefaultHuber;
    CandidateHuber.Limit := HuberKValues[I];
    CandidateHuber.MaxIterations := 30;
    CandidateHuber.WeightTolerance := 1E-4;
    CandidateHuber.BalanceMaxMinSphere := BalanceMaxMinSphere;
    CandidateHuber.Validate;

    CandidateFit := lin_RunLS(Result.Model, CandidateHuber);
    CandidateMetrics := lin_CalculateAll(CandidateFit);
    Result.Candidates[I] := lin_BuildCandidate(CandidateFit,
      CandidateMetrics, CandidateHuber.Limit);

    if (Result.SelectedIndex < 0) or
       lin_IsBetter(Result.Candidates[I],
         Result.Candidates[Result.SelectedIndex]) then
    begin
      Result.SelectedIndex := I;
      Result.Huber := CandidateHuber;
      Result.Fit := CandidateFit;
      Result.AllMetrics := CandidateMetrics;
    end;
  end;

  if Result.SelectedIndex < 0 then
    raise EInvalidOpException.Create(
      'lin_SelectBestHuberParameters: no candidate was evaluated');
  Result.Candidates[Result.SelectedIndex].Selected := True;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('PIECEWISE-LINEAR HUBER k SELECTION');
    OutRes.Add(StringOfChar('=', 122));
    OutRes.Add('Ranking: converged; H norm PASS; magnetic inclination '+
      'PASS/min MaxAbs; total MaxAbs PASS; normalized MaxAbs.');
    OutRes.Add(Format('Cross terms linear by T: %s; '+
      'balanced MAX/MIN/SPHERE weights: %s; '+
      'MaxIterations=30; tolerance=1E-4',
      [lin_YesNo(CrossLinear), lin_YesNo(BalanceMaxMinSphere)]));
    OutRes.Add('');
    OutRes.Add(Format('%-9s %-9s %-8s %-11s %-11s %-11s '+
      '%-11s %-11s %-7s %-10s %-8s',
      ['Huber k', 'Converged', 'Passes', 'Zen Max', 'MagInc Max',
       'Azi Max', 'G norm Max', 'H norm Max', 'H norm',
       'Error idx', 'Selected']));
    OutRes.Add(StringOfChar('-', 122));

    for var Candidate in Result.Candidates do
      OutRes.Add(Format('%-9.3g %-9s %3d/5    %-11.3f %-11.3f '+
        '%-11.3f %-11.3f %-11.3f %-7s %-10.4f %-8s',
        [Candidate.Limit, lin_YesNo(Candidate.Converged),
         Candidate.MaxAbsPassCount, Candidate.ZenithMaxAbs,
         Candidate.MagneticInclinationMaxAbs,
         Candidate.AzimuthMaxAbs,
         Candidate.AccelerometerNormMaxAbs,
         Candidate.MagnetometerNormMaxAbs,
         lin_PassFailText(Candidate.MagnetometerNormMaxAbs, 0.50),
         Candidate.NormalizedMaxError,
         lin_YesNo(Candidate.Selected)]));

    OutRes.Add('');
    OutRes.Add(Format('Selected Huber k: %.6g',
      [Result.Huber.Limit]));
    OutRes.Add(Format('Selected magnetic inclination MaxAbs: '+
      '%.6f deg  %s (limit 0.200000 deg)',
      [Result.Candidates[Result.SelectedIndex].
         MagneticInclinationMaxAbs,
       lin_PassFailText(Result.Candidates[Result.SelectedIndex].
         MagneticInclinationMaxAbs, 0.20)]));
    OutRes.Add(Format('Selected magnetometer norm MaxAbs: '+
      '%.6f %%  %s (limit 0.500000 %%)',
      [Result.Candidates[Result.SelectedIndex].MagnetometerNormMaxAbs,
       lin_PassFailText(Result.Candidates[Result.SelectedIndex].
         MagnetometerNormMaxAbs, 0.50)]));
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.lin_WorstPointsToStrings(
  const Fit: TLinCalibrationResult; OutRes: TStrings;
  SameSeriesCount: Integer);
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string =
    ('deg', 'deg', 'deg', '%', '%');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_WeightsText(SourceIndex: Integer;
    Sensor: SetSetsor): string;
  begin
    Result := 'not-trained';
    for var I := 0 to High(Fit.TrainingIndices) do
      if Fit.TrainingIndices[I] = SourceIndex then
      begin
        if I >= Length(Fit.Diagnostics[Sensor].PointWeights) then
          Exit('n/a');
        var PointWeight := Fit.Diagnostics[Sensor].PointWeights[I];
        var BaseWeight := NaN;
        var EffectiveWeight := NaN;
        if I < Length(Fit.Diagnostics[Sensor].BasePointWeights) then
          BaseWeight := Fit.Diagnostics[Sensor].BasePointWeights[I];
        if I < Length(Fit.Diagnostics[Sensor].EffectivePointWeights) then
          EffectiveWeight :=
            Fit.Diagnostics[Sensor].EffectivePointWeights[I];
        Result := Format('point=%.6g base=%.6g effective=%.6g',
          [PointWeight, BaseWeight, EffectiveWeight]);
        Exit;
      end;
  end;

  function lin_AcquisitionGroup(const Input: TinclInput): string;
  begin
    if lin_Contains(Input.Info, 'sphere') or
       lin_Contains(Input.Info, 'сфера') then
      Result := 'SPHERE'
    else if lin_Contains(Input.Info, '=max') or
            lin_Contains(Input.Info, '=min') then
      Result := 'MAX/MIN'
    else
      Result := 'OTHER';
  end;

  procedure lin_SwapErrorPoint(var A, B: TValidationErrorPoint);
  begin
    var Temp := A;
    A := B;
    B := Temp;
  end;

  procedure lin_AddSeriesDetails(const Metric: TValidationMetric;
    const MetricName, UnitName: string; Limit: Double);
  var
    SeriesByError, SeriesByStep: TArray<TValidationErrorPoint>;
    PeakInput, Input: TinclInput;
    N, AboveLimitCount, PeakPosition, FirstPosition,
    LastPosition, PrintCount: Integer;
    Diagnosis: string;
  begin
    if (Metric.Count = 0) or (Metric.PeakSourceIndex < 0) or
       (Metric.PeakSourceIndex >= Length(InpData.Inpt)) then
      Exit;
    PeakInput := InpData.Inpt[Metric.PeakSourceIndex];
    SetLength(SeriesByError, 0);
    AboveLimitCount := 0;

    for var ErrorPoint in Metric.ErrorPoints do
      if (ErrorPoint.SourceIndex >= 0) and
         (ErrorPoint.SourceIndex < Length(InpData.Inpt)) and
         (InpData.Inpt[ErrorPoint.SourceIndex].SetNo = PeakInput.SetNo) then
      begin
        N := Length(SeriesByError);
        SetLength(SeriesByError, N + 1);
        SeriesByError[N] := ErrorPoint;
        if Abs(ErrorPoint.SignedError) > Limit then
          Inc(AboveLimitCount);
      end;

    SeriesByStep := Copy(SeriesByError, 0, Length(SeriesByError));
    for var I := 0 to High(SeriesByError) - 1 do
      for var J := I + 1 to High(SeriesByError) do
        if Abs(SeriesByError[J].SignedError) >
           Abs(SeriesByError[I].SignedError) then
          lin_SwapErrorPoint(SeriesByError[I], SeriesByError[J]);

    if AboveLimitCount <= 1 then
      Diagnosis := 'isolated outlier candidate'
    else
      Diagnosis := 'series/systematic effect';
    OutRes.Add(Format('  same SetNo=%d: rows=%d; above limit=%d; %s',
      [PeakInput.SetNo, Length(SeriesByError), AboveLimitCount,
       Diagnosis]));
    OutRes.Add('  worst rows of the same SetNo:');
    PrintCount := Min(SameSeriesCount, Length(SeriesByError));
    for var I := 0 to PrintCount - 1 do
    begin
      Input := InpData.Inpt[SeriesByError[I].SourceIndex];
      OutRes.Add(Format('    source=%d step=%d T=%8.3f '+
        'signed=%.6f %-3s abs=%.6f %-3s HuberH={%s}',
        [SeriesByError[I].SourceIndex, Input.Step, Input.T,
         SeriesByError[I].SignedError, UnitName,
         Abs(SeriesByError[I].SignedError), UnitName,
         lin_WeightsText(SeriesByError[I].SourceIndex, sMag)]));
    end;

    for var I := 0 to High(SeriesByStep) - 1 do
      for var J := I + 1 to High(SeriesByStep) do
        if InpData.Inpt[SeriesByStep[J].SourceIndex].Step <
           InpData.Inpt[SeriesByStep[I].SourceIndex].Step then
          lin_SwapErrorPoint(SeriesByStep[I], SeriesByStep[J]);

    PeakPosition := -1;
    for var I := 0 to High(SeriesByStep) do
      if SeriesByStep[I].SourceIndex = Metric.PeakSourceIndex then
      begin
        PeakPosition := I;
        Break;
      end;
    if PeakPosition >= 0 then
    begin
      FirstPosition := Max(0, PeakPosition - 2);
      LastPosition := Min(High(SeriesByStep), PeakPosition + 2);
      OutRes.Add(Format('  neighbouring Steps around peak %s:',
        [MetricName]));
      for var I := FirstPosition to LastPosition do
      begin
        Input := InpData.Inpt[SeriesByStep[I].SourceIndex];
        OutRes.Add(Format('    source=%d step=%d T=%8.3f '+
          'A=%7.2f Z=%7.2f V=%7.2f signed=%.6f %s',
          [SeriesByStep[I].SourceIndex, Input.Step, Input.T,
           Input.Azi, Input.Zen, Input.Vis,
           SeriesByStep[I].SignedError, UnitName]));
      end;
    end;
  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if SameSeriesCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'SameSeriesCount must be at least 1');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_WorstPointsToStrings must be called after TpolyMath.Init');
  Fit.Model.lin_Validate;

  var AllMetrics := lin_CalculateAll(Fit);
  OutRes.BeginUpdate;
  try
    OutRes.Add('');
    OutRes.Add('PIECEWISE-LINEAR WORST SOURCE ROWS');
    OutRes.Add(StringOfChar('=', 112));

    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var MetricIndex := ControlledMetricIndex[ControlledIndex];
      if MetricIndex >= Length(AllMetrics.Metrics) then
        Continue;
      var Metric := AllMetrics.Metrics[MetricIndex];
      if (Metric.Count = 0) or (Metric.PeakSourceIndex < 0) or
         (Metric.PeakSourceIndex >= Length(InpData.Inpt)) then
        Continue;
      var Input := InpData.Inpt[Metric.PeakSourceIndex];

      OutRes.Add(Format('%s: source=%d; step=%d; SetNo=%d; group=%s',
        [ControlledMetricName[ControlledIndex], Metric.PeakSourceIndex,
         Input.Step, Input.SetNo, lin_AcquisitionGroup(Input)]));
      OutRes.Add(Format('  signed=%.9f %s; abs=%.9f %s; '+
        'limit=%.6f %s; %s',
        [Metric.PeakSigned, ControlledMetricUnit[ControlledIndex],
         Metric.MaxAbs, ControlledMetricUnit[ControlledIndex],
         ControlledMetricLimit[ControlledIndex],
         ControlledMetricUnit[ControlledIndex],
         lin_PassFail(Metric.MaxAbs,
           ControlledMetricLimit[ControlledIndex])]));
      OutRes.Add(Format('  T=%.6f; A=%.6f; Z=%.6f; V=%.6f; '+
        'EtalonMag=%.12g',
        [Input.T, Input.Azi, Input.Zen, Input.Vis,
         Input.EtalonMag]));
      OutRes.Add(Format('  raw G=(%.12g, %.12g, %.12g); '+
        'raw H=(%.12g, %.12g, %.12g)',
        [Input.G.X, Input.G.Y, Input.G.Z,
         Input.H.X, Input.H.Y, Input.H.Z]));
      OutRes.Add(Format('  HuberG={%s}; HuberH={%s}',
        [lin_WeightsText(Metric.PeakSourceIndex, sAcc),
         lin_WeightsText(Metric.PeakSourceIndex, sMag)]));
      OutRes.Add(Format('  Info="%s"', [Input.Info]));

      if MetricIndex = 6 then
      begin
        var ExpectedNorm := RES_AMP * Input.EtalonMag / 1000.0;
        var CalculatedNorm := ExpectedNorm *
          (1.0 + Metric.PeakSigned / 100.0);
        OutRes.Add(Format('  expected H norm=%.12g; '+
          'calculated H norm=%.12g',
          [ExpectedNorm, CalculatedNorm]));
      end;

      if (MetricIndex = 4) or (MetricIndex = 6) then
        lin_AddSeriesDetails(Metric,
          ControlledMetricName[ControlledIndex],
          ControlledMetricUnit[ControlledIndex],
          ControlledMetricLimit[ControlledIndex]);
      OutRes.Add('');
    end;
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.lin_MagneticFieldDiagnosticsToStrings(
  const Fit: TLinCalibrationResult; OutRes: TStrings;
  OrientationTolerance: Double);
const
  MagneticInclinationMetricIndex = 4;
  MagnetometerNormMetricIndex = 6;
  ReferenceOffsetThreshold = 0.02;
  SeriesVariationThreshold = 0.05;

  function lin_FindSignedError(const Metric: TValidationMetric;
    SourceIndex: Integer; out Error: Double): Boolean;
  begin
    for var ErrorPoint in Metric.ErrorPoints do
      if ErrorPoint.SourceIndex = SourceIndex then
      begin
        Error := ErrorPoint.SignedError;
        Exit(True);
      end;
    Error := NaN;
    Result := False;
  end;

  procedure lin_SwapErrorPoint(var A, B: TValidationErrorPoint);
  begin
    var Temp := A;
    A := B;
    B := Temp;
  end;

var
  AllMetrics: TLinAllMetricsResult;
  InclMetric, NormMetric: TValidationMetric;
  SetNos: TList<Integer>;
  InclValues, OrientationPoints: TArray<TValidationErrorPoint>;
  SetMedians: TArray<Double>;
  GlobalMedian, CorrectedMeanAbs, CorrectedMaxAbs: Double;
  MinSetMedian, MaxSetMedian: Double;
  SumIncl, SumNorm, SumIncl2, SumNorm2, SumProduct: Double;
  Correlation, Denominator: Double;
  PairCount: Integer;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_MagneticFieldDiagnosticsToStrings must be called after Init');
  if IsNan(OrientationTolerance) or IsInfinite(OrientationTolerance) or
     (OrientationTolerance <= 0) or (OrientationTolerance >= 180) then
    raise EArgumentOutOfRangeException.Create(
      'OrientationTolerance must be finite and in 0..180 degrees');
  Fit.Model.lin_Validate;

  AllMetrics := lin_CalculateAll(Fit);
  if Length(AllMetrics.Metrics) <= MagnetometerNormMetricIndex then
    raise EInvalidOpException.Create(
      'lin_MagneticFieldDiagnosticsToStrings: incomplete ALL metrics');
  InclMetric := AllMetrics.Metrics[MagneticInclinationMetricIndex];
  NormMetric := AllMetrics.Metrics[MagnetometerNormMetricIndex];
  if (InclMetric.Count = 0) or (NormMetric.Count = 0) then
    raise EInvalidOpException.Create(
      'lin_MagneticFieldDiagnosticsToStrings: empty magnetic metrics');

  SetLength(InclValues, Length(InclMetric.ErrorPoints));
  for var I := 0 to High(InclMetric.ErrorPoints) do
    InclValues[I] := InclMetric.ErrorPoints[I];
  var ValuesOnly: TArray<Double>;
  SetLength(ValuesOnly, Length(InclValues));
  for var I := 0 to High(InclValues) do
    ValuesOnly[I] := InclValues[I].SignedError;
  GlobalMedian := Median(ValuesOnly);

  CorrectedMeanAbs := 0;
  CorrectedMaxAbs := 0;
  for var ErrorPoint in InclMetric.ErrorPoints do
  begin
    var CorrectedError := ErrorPoint.SignedError - GlobalMedian;
    CorrectedMeanAbs := CorrectedMeanAbs + Abs(CorrectedError);
    CorrectedMaxAbs := Max(CorrectedMaxAbs, Abs(CorrectedError));
  end;
  CorrectedMeanAbs := CorrectedMeanAbs / InclMetric.Count;

  SetNos := TList<Integer>.Create;
  try
    for var ErrorPoint in InclMetric.ErrorPoints do
      if (ErrorPoint.SourceIndex >= 0) and
         (ErrorPoint.SourceIndex < Length(InpData.Inpt)) and
         not SetNos.Contains(InpData.Inpt[ErrorPoint.SourceIndex].SetNo) then
        SetNos.Add(InpData.Inpt[ErrorPoint.SourceIndex].SetNo);
    SetNos.Sort;
    SetLength(SetMedians, SetNos.Count);

    OutRes.BeginUpdate;
    try
      OutRes.Add('');
      OutRes.Add('MAGNETIC FIELD / MANUAL INCLINATION DIAGNOSTICS');
      OutRes.Add(StringOfChar('=', 118));
      OutRes.Add(Format('Entered magnetic inclination: %.9f deg',
        [InpData.MNak]));
      OutRes.Add(Format('Global signed errors: mean=%.9f deg; '+
        'median=%.9f deg; MeanAbs=%.9f deg; MaxAbs=%.9f deg',
        [InclMetric.MeanSigned, GlobalMedian, InclMetric.MeanAbs,
         InclMetric.MaxAbs]));
      OutRes.Add(Format('Robust reference candidate: %.9f deg '+
        '(entered + median signed error)',
        [InpData.MNak + GlobalMedian]));
      OutRes.Add(Format('Diagnostic-only errors after subtracting median: '+
        'MeanAbs=%.9f deg; MaxAbs=%.9f deg',
        [CorrectedMeanAbs, CorrectedMaxAbs]));
      OutRes.Add('The candidate above is not applied automatically.');
      OutRes.Add('');
      OutRes.Add(Format('%-7s %6s %10s %12s %12s %12s %12s '+
        '%12s %12s',
        ['SetNo', 'N', 'Mean T', 'Incl mean', 'Incl median',
         'Incl MeanAbs', 'Incl MaxAbs', 'Hnorm mean', 'Hnorm MaxAbs']));
      OutRes.Add(StringOfChar('-', 118));

      MinSetMedian := MaxDouble;
      MaxSetMedian := -MaxDouble;
      for var SetIndex := 0 to SetNos.Count - 1 do
      begin
        var SetNo := SetNos[SetIndex];
        var SetIncl, SetNorm: TArray<Double>;
        var SumT, SumSetIncl, SumSetAbsIncl,
            SetMaxIncl, SumSetNorm, SetMaxNorm: Double;
        SumT := 0;
        SumSetIncl := 0;
        SumSetAbsIncl := 0;
        SetMaxIncl := 0;
        SumSetNorm := 0;
        SetMaxNorm := 0;
        SetLength(SetIncl, 0);
        SetLength(SetNorm, 0);

        for var ErrorPoint in InclMetric.ErrorPoints do
          if (ErrorPoint.SourceIndex >= 0) and
             (ErrorPoint.SourceIndex < Length(InpData.Inpt)) and
             (InpData.Inpt[ErrorPoint.SourceIndex].SetNo = SetNo) then
          begin
            var N := Length(SetIncl);
            SetLength(SetIncl, N + 1);
            SetIncl[N] := ErrorPoint.SignedError;
            SumT := SumT + InpData.Inpt[ErrorPoint.SourceIndex].T;
            SumSetIncl := SumSetIncl + ErrorPoint.SignedError;
            SumSetAbsIncl := SumSetAbsIncl + Abs(ErrorPoint.SignedError);
            SetMaxIncl := Max(SetMaxIncl, Abs(ErrorPoint.SignedError));
            var NormError: Double;
            if lin_FindSignedError(NormMetric,
              ErrorPoint.SourceIndex, NormError) then
            begin
              N := Length(SetNorm);
              SetLength(SetNorm, N + 1);
              SetNorm[N] := NormError;
              SumSetNorm := SumSetNorm + NormError;
              SetMaxNorm := Max(SetMaxNorm, Abs(NormError));
            end;
          end;

        if Length(SetIncl) = 0 then
          Continue;
        SetMedians[SetIndex] := Median(SetIncl);
        MinSetMedian := Min(MinSetMedian, SetMedians[SetIndex]);
        MaxSetMedian := Max(MaxSetMedian, SetMedians[SetIndex]);
        var NormMean := NaN;
        if Length(SetNorm) > 0 then
          NormMean := SumSetNorm / Length(SetNorm);
        OutRes.Add(Format('%-7d %6d %10.3f %12.6f %12.6f '+
          '%12.6f %12.6f %12.6f %12.6f',
          [SetNo, Length(SetIncl), SumT / Length(SetIncl),
           SumSetIncl / Length(SetIncl), SetMedians[SetIndex],
           SumSetAbsIncl / Length(SetIncl), SetMaxIncl,
           NormMean, SetMaxNorm]));
      end;

      OutRes.Add('');
      OutRes.Add(Format('SetNo median range: %.9f .. %.9f deg; '+
        'span=%.9f deg',
        [MinSetMedian, MaxSetMedian, MaxSetMedian - MinSetMedian]));

      SumIncl := 0;
      SumNorm := 0;
      SumIncl2 := 0;
      SumNorm2 := 0;
      SumProduct := 0;
      PairCount := 0;
      for var ErrorPoint in InclMetric.ErrorPoints do
      begin
        var NormError: Double;
        if lin_FindSignedError(NormMetric,
          ErrorPoint.SourceIndex, NormError) then
        begin
          SumIncl := SumIncl + ErrorPoint.SignedError;
          SumNorm := SumNorm + NormError;
          SumIncl2 := SumIncl2 + Sqr(ErrorPoint.SignedError);
          SumNorm2 := SumNorm2 + Sqr(NormError);
          SumProduct := SumProduct + ErrorPoint.SignedError * NormError;
          Inc(PairCount);
        end;
      end;
      Denominator := Sqrt(Max(0.0,
        (PairCount * SumIncl2 - Sqr(SumIncl)) *
        (PairCount * SumNorm2 - Sqr(SumNorm))));
      if (PairCount >= 2) and (Denominator > 0) then
        Correlation := (PairCount * SumProduct - SumIncl * SumNorm) /
          Denominator
      else
        Correlation := NaN;
      OutRes.Add(Format('Correlation(signed inclination error, '+
        'signed H-norm error): r=%.6f; N=%d',
        [Correlation, PairCount]));

      OutRes.Add('');
      OutRes.Add('EVIDENCE:');
      if Abs(GlobalMedian) >= ReferenceOffsetThreshold then
        OutRes.Add('  * Non-zero global median supports a possible '+
          'manual reference offset.')
      else
        OutRes.Add('  * Global median is small; a constant manual '+
          'reference offset is not the main effect.');
      if (MaxSetMedian - MinSetMedian) >= SeriesVariationThreshold then
        OutRes.Add('  * SetNo medians vary materially: field/model '+
          'dependence on temperature or acquisition series is present.')
      else
        OutRes.Add('  * SetNo medians are close: a common reference '+
          'offset is more plausible than series-dependent field change.');
      if (not IsNan(Correlation)) and (Abs(Correlation) >= 0.5) then
        OutRes.Add('  * Inclination and H-norm errors are correlated: '+
          'the external field vector may change in magnitude and direction.')
      else
        OutRes.Add('  * Inclination and H-norm errors are weakly '+
          'correlated: field rotation without a large norm change remains '+
          'possible.');

      var PeakSource := InclMetric.PeakSourceIndex;
      if (PeakSource >= 0) and (PeakSource < Length(InpData.Inpt)) then
      begin
        var PeakInput := InpData.Inpt[PeakSource];
        SetLength(OrientationPoints, 0);
        for var ErrorPoint in InclMetric.ErrorPoints do
          if (ErrorPoint.SourceIndex >= 0) and
             (ErrorPoint.SourceIndex < Length(InpData.Inpt)) and
             (OrientationAngleDistance(
                InpData.Inpt[ErrorPoint.SourceIndex].Azi,
                PeakInput.Azi) <= OrientationTolerance) and
             (OrientationAngleDistance(
                InpData.Inpt[ErrorPoint.SourceIndex].Zen,
                PeakInput.Zen) <= OrientationTolerance) and
             (OrientationAngleDistance(
                InpData.Inpt[ErrorPoint.SourceIndex].Vis,
                PeakInput.Vis) <= OrientationTolerance) then
          begin
            var N := Length(OrientationPoints);
            SetLength(OrientationPoints, N + 1);
            OrientationPoints[N] := ErrorPoint;
          end;

        for var I := 0 to High(OrientationPoints) - 1 do
          for var J := I + 1 to High(OrientationPoints) do
            if InpData.Inpt[OrientationPoints[J].SourceIndex].T <
               InpData.Inpt[OrientationPoints[I].SourceIndex].T then
              lin_SwapErrorPoint(OrientationPoints[I],
                OrientationPoints[J]);

        OutRes.Add('');
        OutRes.Add(Format('SAME ORIENTATION AS WORST INCLINATION '+
          '(tolerance %.3f deg):', [OrientationTolerance]));
        OutRes.Add(Format('Reference A=%.3f Z=%.3f V=%.3f; '+
          'peak source=%d',
          [PeakInput.Azi, PeakInput.Zen, PeakInput.Vis, PeakSource]));
        OutRes.Add(Format('%-7s %-7s %-7s %-10s %-14s %-14s',
          ['source', 'step', 'SetNo', 'T', 'Incl error',
           'Hnorm error']));
        for var ErrorPoint in OrientationPoints do
        begin
          var Input := InpData.Inpt[ErrorPoint.SourceIndex];
          var NormError: Double;
          if not lin_FindSignedError(NormMetric,
            ErrorPoint.SourceIndex, NormError) then
            NormError := NaN;
          OutRes.Add(Format('%-7d %-7d %-7d %-10.3f %-14.6f '+
            '%-14.6f',
            [ErrorPoint.SourceIndex, Input.Step, Input.SetNo, Input.T,
             ErrorPoint.SignedError, NormError]));
        end;
      end;
    finally
      OutRes.EndUpdate;
    end;
  finally
    SetNos.Free;
  end;
end;

class function TpolyMath.lin_CompareTemperatureNodeModels(
  const NodeCounts: array of Integer;
  const Huber: THuberIrlsOptions;
  OutRes: TStrings): TLinTemperatureNodeComparison;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_PassCount(const Metrics: TLinAllMetricsResult): Integer;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      if Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs <=
         ControlledMetricLimit[I] then
        Inc(Result);
  end;

  function lin_NormalizedError(
    const Metrics: TLinAllMetricsResult): Double;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      Result := Result +
        Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs /
        ControlledMetricLimit[I];
    Result := Result / ControlledMetricCount;
  end;

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function lin_IsBetter(const Candidate, Current:
    TLinTemperatureNodeVariantResult): Boolean;
  const
    ErrorTolerance = 1E-12;
  begin
    if Candidate.Converged <> Current.Converged then
      Exit(Candidate.Converged);
    if Candidate.MaxAbsPassCount <> Current.MaxAbsPassCount then
      Exit(Candidate.MaxAbsPassCount > Current.MaxAbsPassCount);
    if Abs(Candidate.NormalizedMaxError -
       Current.NormalizedMaxError) > ErrorTolerance then
      Exit(Candidate.NormalizedMaxError < Current.NormalizedMaxError);
    Result := Candidate.Model.lin_CoeffCount <
      Current.Model.lin_CoeffCount;
  end;

var
  Variant: TLinTemperatureNodeVariantResult;
  NodeLine: string;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CompareTemperatureNodeModels must be called after TpolyMath.Init');
  if Length(NodeCounts) = 0 then
    raise EArgumentException.Create('NodeCounts is empty');
  Huber.Validate;

  Result := Default(TLinTemperatureNodeComparison);
  Result.SelectedIndex := -1;
  SetLength(Result.Variants, Length(NodeCounts));
  for var I := 0 to High(NodeCounts) do
  begin
    for var J := 0 to I - 1 do
      if NodeCounts[J] = NodeCounts[I] then
        raise EArgumentException.CreateFmt(
          'NodeCounts contains duplicate value %d', [NodeCounts[I]]);

    Variant := Default(TLinTemperatureNodeVariantResult);
    Variant.RequestedNodeCount := NodeCounts[I];
    Variant.Model := lin_CreateReducedNodeModel(NodeCounts[I], True);
    Variant.Fit := lin_RunLS(Variant.Model, Huber);
    Variant.Metrics := lin_CalculateAll(Variant.Fit);
    Variant.Converged :=
      Variant.Fit.Diagnostics[sAcc].Converged and
      Variant.Fit.Diagnostics[sMag].Converged;
    Variant.MaxAbsPassCount := lin_PassCount(Variant.Metrics);
    Variant.NormalizedMaxError := lin_NormalizedError(
      Variant.Metrics);
    Result.Variants[I] := Variant;
    if (Result.SelectedIndex < 0) or
       lin_IsBetter(Result.Variants[I],
         Result.Variants[Result.SelectedIndex]) then
      Result.SelectedIndex := I;
  end;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('MAIN TEMPERATURE NODE COMPARISON');
    OutRes.Add(StringOfChar('=', 126));
    OutRes.Add(Format('Rows=%d; cross-axis model=global linear T; '+
      'Huber enabled=%s; k=%.6g; iterations=%d; tolerance=%.6g; '+
      'balanced=%s',
      [Length(InpData.Inpt), lin_YesNo(Huber.Enabled), Huber.Limit,
       Huber.MaxIterations, Huber.WeightTolerance,
       lin_YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('Reduction rule: replace the narrowest SetNo '+
      'Min/Max ranges by their real mean temperature first.');
    OutRes.Add('Outside the first/last node the nearest endpoint '+
      'coefficient is held constant.');
    OutRes.Add('');

    for var I := 0 to High(Result.Variants) do
    begin
      NodeLine := Format('%d nodes:',
        [Result.Variants[I].RequestedNodeCount]);
      for var Node in Result.Variants[I].Model.TemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
      OutRes.Add(NodeLine);
    end;

    OutRes.Add('');
    OutRes.Add(Format('%5s %7s %11s %11s %14s %14s %10s '+
      '%8s %12s %9s',
      ['Nodes', 'Coeff', 'Rank G', 'Rank H', 'Condition G',
       'Condition H', 'Converged', 'PASS', 'Norm error',
       'Selected']));
    OutRes.Add(StringOfChar('-', 112));
    for var I := 0 to High(Result.Variants) do
      with Result.Variants[I] do
        OutRes.Add(Format('%5d %7d %4d/%-6d %4d/%-6d '+
          '%14.6g %14.6g %10s %4d/5 %12.6f %9s',
          [RequestedNodeCount, Model.lin_CoeffCount,
           Fit.AccRank, Model.lin_CoeffCount,
           Fit.MagRank, Model.lin_CoeffCount,
           Fit.AccCondition, Fit.MagCondition, lin_YesNo(Converged),
           MaxAbsPassCount, NormalizedMaxError,
           lin_YesNo(I = Result.SelectedIndex)]));

    OutRes.Add('');
    OutRes.Add(Format('%-24s %8s %8s',
      ['Parameter', 'Limit', 'MaxAbs by node count']));
    OutRes.Add(StringOfChar('-', 126));
    for var MetricNo := 0 to ControlledMetricCount - 1 do
    begin
      NodeLine := Format('%-24s %8.3f',
        [ControlledMetricName[MetricNo],
         ControlledMetricLimit[MetricNo]]);
      for var I := 0 to High(Result.Variants) do
      begin
        var Metric := Result.Variants[I].Metrics.Metrics[
          ControlledMetricIndex[MetricNo]];
        NodeLine := NodeLine + Format('  %2dn=%9.4f %s',
          [Result.Variants[I].RequestedNodeCount, Metric.MaxAbs,
           lin_PassFail(Metric.MaxAbs,
             ControlledMetricLimit[MetricNo])]);
      end;
      OutRes.Add(NodeLine);
    end;

    OutRes.Add('');
    OutRes.Add(Format('SELECTED: %d main temperature nodes, '+
      '%d coefficients per axis.',
      [Result.Variants[Result.SelectedIndex].RequestedNodeCount,
       Result.Variants[Result.SelectedIndex].Model.lin_CoeffCount]));
    OutRes.Add('Selection order: converged fit; most strict MaxAbs '+
      'PASS; lowest normalized MaxAbs error; fewer coefficients.');
    OutRes.Add('Warning: these are ALL-row in-sample metrics. '+
      'Confirm the selected grid with held-out validation before use.');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_CompareReducedFiveNodeCrossModels(
  const MainNodeCounts: array of Integer;
  const Huber: THuberIrlsOptions;
  OutRes: TStrings): TLinReducedFiveCrossComparison;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function lin_Evaluate(const Model: TLinTemperatureModel;
    RequestedNodeCount: Integer): TLinTemperatureNodeVariantResult;
  begin
    Result := Default(TLinTemperatureNodeVariantResult);
    Result.RequestedNodeCount := RequestedNodeCount;
    Result.Model := Model;
    Result.Fit := lin_RunLS(Model, Huber);
    Result.Metrics := lin_CalculateAll(Result.Fit);
    Result.Converged :=
      Result.Fit.Diagnostics[sAcc].Converged and
      Result.Fit.Diagnostics[sMag].Converged;
    Result.MaxAbsPassCount := 0;
    Result.NormalizedMaxError := 0;
    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := Result.Metrics.Metrics[ControlledMetricIndex[I]];
      if Metric.MaxAbs <= ControlledMetricLimit[I] then
        Inc(Result.MaxAbsPassCount);
      Result.NormalizedMaxError := Result.NormalizedMaxError +
        Metric.MaxAbs / ControlledMetricLimit[I];
    end;
    Result.NormalizedMaxError :=
      Result.NormalizedMaxError / ControlledMetricCount;
  end;

  function lin_IsBetter(const Candidate, Current:
    TLinTemperatureNodeVariantResult): Boolean;
  const
    ErrorTolerance = 1E-12;
  begin
    if Candidate.Converged <> Current.Converged then
      Exit(Candidate.Converged);
    if Candidate.MaxAbsPassCount <> Current.MaxAbsPassCount then
      Exit(Candidate.MaxAbsPassCount > Current.MaxAbsPassCount);
    if Abs(Candidate.NormalizedMaxError -
       Current.NormalizedMaxError) > ErrorTolerance then
      Exit(Candidate.NormalizedMaxError < Current.NormalizedMaxError);
    Result := Candidate.Model.lin_CoeffCount <
      Current.Model.lin_CoeffCount;
  end;

  procedure lin_AddVariantRow(const Name, CrossName: string;
    const Variant: TLinTemperatureNodeVariantResult;
    Selected: Boolean);
  begin
    OutRes.Add(Format('%-9s %5d %-9s %7d %4d/%-6d %4d/%-6d '+
      '%12.6g %12.6g %9s %4d/5 %11.6f %8s',
      [Name, Variant.Model.lin_NodeCount, CrossName,
       Variant.Model.lin_CoeffCount,
       Variant.Fit.AccRank, Variant.Model.lin_CoeffCount,
       Variant.Fit.MagRank, Variant.Model.lin_CoeffCount,
       Variant.Fit.AccCondition, Variant.Fit.MagCondition,
       lin_YesNo(Variant.Converged), Variant.MaxAbsPassCount,
       Variant.NormalizedMaxError, lin_YesNo(Selected)]));
  end;

var
  Best: TLinTemperatureNodeVariantResult;
  NodeLine, MetricLine, SelectedName: string;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CompareReducedFiveNodeCrossModels must be called after '+
      'TpolyMath.Init');
  if Length(MainNodeCounts) = 0 then
    raise EArgumentException.Create('MainNodeCounts is empty');
  Huber.Validate;

  Result := Default(TLinReducedFiveCrossComparison);
  Result.Baseline := lin_Evaluate(lin_CreateModel(True),
    Length(lin_BuildTemperatureNodes(InpData.Inpt)));
  Result.SelectedIndex := -1;
  Best := Result.Baseline;
  SetLength(Result.Variants, Length(MainNodeCounts));

  for var I := 0 to High(MainNodeCounts) do
  begin
    for var J := 0 to I - 1 do
      if MainNodeCounts[J] = MainNodeCounts[I] then
        raise EArgumentException.CreateFmt(
          'MainNodeCounts contains duplicate value %d',
          [MainNodeCounts[I]]);
    Result.Variants[I] := lin_Evaluate(
      lin_CreateReducedFiveNodeCrossModel(MainNodeCounts[I]),
      MainNodeCounts[I]);
    if lin_IsBetter(Result.Variants[I], Best) then
    begin
      Best := Result.Variants[I];
      Result.SelectedIndex := I;
    end;
  end;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('REDUCED MAIN GRID + FIVE-NODE CROSS COMPARISON');
    OutRes.Add(StringOfChar('=', 138));
    OutRes.Add(Format('Rows=%d; Huber enabled=%s; k=%.6g; '+
      'iterations=%d; tolerance=%.6g; balanced=%s',
      [Length(InpData.Inpt), lin_YesNo(Huber.Enabled), Huber.Limit,
       Huber.MaxIterations, Huber.WeightTolerance,
       lin_YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('Baseline: original main grid + global-linear '+
      'cross-axis terms.');
    OutRes.Add('Candidates: reduced main amplitude/offset grid + '+
      'the same five-node piecewise-linear cross model for G and H.');
    OutRes.Add('');

    NodeLine := 'Five cross nodes, deg C:';
    if Length(Result.Variants) > 0 then
      for var Node in Result.Variants[0].Model.CrossTemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
    OutRes.Add(NodeLine);

    NodeLine := 'Baseline main nodes:';
    for var Node in Result.Baseline.Model.TemperatureNodes do
      NodeLine := NodeLine + Format(' %.6f', [Node]);
    OutRes.Add(NodeLine);
    for var I := 0 to High(Result.Variants) do
    begin
      NodeLine := Format('%d main nodes:',
        [Result.Variants[I].RequestedNodeCount]);
      for var Node in Result.Variants[I].Model.TemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
      OutRes.Add(NodeLine);
    end;

    OutRes.Add('');
    OutRes.Add(Format('%-9s %5s %-9s %7s %11s %11s %12s %12s '+
      '%9s %8s %11s %8s',
      ['Model', 'Main', 'Cross', 'Coeff', 'Rank G', 'Rank H',
       'Condition G', 'Condition H', 'Converged', 'PASS',
       'Norm error', 'Selected']));
    OutRes.Add(StringOfChar('-', 138));
    lin_AddVariantRow('baseline', 'linear T', Result.Baseline,
      Result.SelectedIndex < 0);
    for var I := 0 to High(Result.Variants) do
      lin_AddVariantRow(Format('%dn+5c',
        [Result.Variants[I].RequestedNodeCount]), '5 nodes',
        Result.Variants[I], Result.SelectedIndex = I);

    OutRes.Add('');
    OutRes.Add(Format('%-24s %8s %s',
      ['Parameter', 'Limit', 'MaxAbs by model']));
    OutRes.Add(StringOfChar('-', 138));
    for var MetricNo := 0 to ControlledMetricCount - 1 do
    begin
      var BaselineMetric := Result.Baseline.Metrics.Metrics[
        ControlledMetricIndex[MetricNo]];
      MetricLine := Format('%-24s %8.3f  base=%9.4f %s',
        [ControlledMetricName[MetricNo],
         ControlledMetricLimit[MetricNo], BaselineMetric.MaxAbs,
         lin_PassFail(BaselineMetric.MaxAbs,
           ControlledMetricLimit[MetricNo])]);
      for var I := 0 to High(Result.Variants) do
      begin
        var Metric := Result.Variants[I].Metrics.Metrics[
          ControlledMetricIndex[MetricNo]];
        MetricLine := MetricLine + Format('  %2dn+5c=%9.4f %s',
          [Result.Variants[I].RequestedNodeCount, Metric.MaxAbs,
           lin_PassFail(Metric.MaxAbs,
             ControlledMetricLimit[MetricNo])]);
      end;
      OutRes.Add(MetricLine);
    end;

    OutRes.Add('');
    if Result.SelectedIndex < 0 then
      SelectedName := Format('baseline (%d main nodes, global-linear '+
        'cross, %d coefficients per axis)',
        [Result.Baseline.Model.lin_NodeCount,
         Result.Baseline.Model.lin_CoeffCount])
    else
      SelectedName := Format('%d main nodes + five cross nodes, '+
        '%d coefficients per axis',
        [Result.Variants[Result.SelectedIndex].Model.lin_NodeCount,
         Result.Variants[Result.SelectedIndex].Model.lin_CoeffCount]);
    OutRes.Add('SELECTED: ' + SelectedName + '.');
    OutRes.Add('Selection order: converged fit; most strict MaxAbs '+
      'PASS; lowest normalized MaxAbs error; fewer coefficients.');
    OutRes.Add('Warning: these are ALL-row in-sample metrics. '+
      'Confirm the selected structure with held-out validation before use.');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_CompareZenithPriorityModels(
  const MainNodeCounts, CrossNodeCounts: array of Integer;
  const Huber: THuberIrlsOptions;
  OutRes: TStrings): TLinZenithGridComparison;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function lin_Evaluate(MainCount, CrossCount: Integer):
    TLinZenithGridVariantResult;
  begin
    Result := Default(TLinZenithGridVariantResult);
    Result.ModelName := Format('%d+%d', [MainCount, CrossCount]);
    Result.MainNodeCount := MainCount;
    Result.CrossNodeCount := CrossCount;
    Result.Model := lin_CreateReducedCrossNodeModel(
      MainCount, CrossCount);
    Result.Fit := lin_RunLS(Result.Model, Huber);
    Result.Metrics := lin_CalculateAll(Result.Fit);
    Result.Converged :=
      Result.Fit.Diagnostics[sAcc].Converged and
      Result.Fit.Diagnostics[sMag].Converged;
    Result.ZenithMaxAbs := Result.Metrics.Metrics[
      ControlledMetricIndex[0]].MaxAbs;
    Result.ZenithPass :=
      Result.ZenithMaxAbs <= ControlledMetricLimit[0];
    Result.OtherMaxAbsPassCount := 0;
    Result.MaxAbsPassCount := 0;
    Result.NormalizedMaxError := 0;
    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := Result.Metrics.Metrics[ControlledMetricIndex[I]];
      if Metric.MaxAbs <= ControlledMetricLimit[I] then
      begin
        Inc(Result.MaxAbsPassCount);
        if I > 0 then
          Inc(Result.OtherMaxAbsPassCount);
      end;
      Result.NormalizedMaxError := Result.NormalizedMaxError +
        Metric.MaxAbs / ControlledMetricLimit[I];
    end;
    Result.NormalizedMaxError :=
      Result.NormalizedMaxError / ControlledMetricCount;
  end;

  function lin_IsBetter(const Candidate, Current:
    TLinZenithGridVariantResult): Boolean;
  const
    ErrorTolerance = 1E-12;
  begin
    if Candidate.Converged <> Current.Converged then
      Exit(Candidate.Converged);
    if Candidate.ZenithPass <> Current.ZenithPass then
      Exit(Candidate.ZenithPass);
    if Abs(Candidate.ZenithMaxAbs - Current.ZenithMaxAbs) >
       ErrorTolerance then
      Exit(Candidate.ZenithMaxAbs < Current.ZenithMaxAbs);
    if Candidate.OtherMaxAbsPassCount <>
       Current.OtherMaxAbsPassCount then
      Exit(Candidate.OtherMaxAbsPassCount >
        Current.OtherMaxAbsPassCount);
    if Abs(Candidate.NormalizedMaxError -
       Current.NormalizedMaxError) > ErrorTolerance then
      Exit(Candidate.NormalizedMaxError <
        Current.NormalizedMaxError);
    Result := Candidate.Model.lin_CoeffCount <
      Current.Model.lin_CoeffCount;
  end;

var
  MainLine, CrossLine, MetricLine: string;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CompareZenithPriorityModels must be called after '+
      'TpolyMath.Init');
  if Length(MainNodeCounts) = 0 then
    raise EArgumentException.Create('Node-count arrays are empty');
  if Length(MainNodeCounts) <> Length(CrossNodeCounts) then
    raise EArgumentException.CreateFmt(
      'Main/Cross node-count array length mismatch: %d <> %d',
      [Length(MainNodeCounts), Length(CrossNodeCounts)]);
  Huber.Validate;

  Result := Default(TLinZenithGridComparison);
  Result.SelectedIndex := -1;
  SetLength(Result.Variants, Length(MainNodeCounts));
  for var I := 0 to High(MainNodeCounts) do
  begin
    for var J := 0 to I - 1 do
      if (MainNodeCounts[J] = MainNodeCounts[I]) and
         (CrossNodeCounts[J] = CrossNodeCounts[I]) then
        raise EArgumentException.CreateFmt(
          'Duplicate main/cross pair %d+%d',
          [MainNodeCounts[I], CrossNodeCounts[I]]);
    Result.Variants[I] := lin_Evaluate(
      MainNodeCounts[I], CrossNodeCounts[I]);
    if (Result.SelectedIndex < 0) or
       lin_IsBetter(Result.Variants[I],
         Result.Variants[Result.SelectedIndex]) then
      Result.SelectedIndex := I;
  end;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('ZENITH-PRIORITY MAIN/CROSS GRID COMPARISON');
    OutRes.Add(StringOfChar('=', 142));
    OutRes.Add(Format('Rows=%d; Huber enabled=%s; k=%.6g; '+
      'iterations=%d; tolerance=%.6g; balanced=%s',
      [Length(InpData.Inpt), lin_YesNo(Huber.Enabled), Huber.Limit,
       Huber.MaxIterations, Huber.WeightTolerance,
       lin_YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('The same complete model is fitted independently to G '+
      'and H; no G/H structural hybrid is used.');
    OutRes.Add('Equal main/cross counts use exactly the same '+
      'temperature-node array.');
    OutRes.Add('');

    for var I := 0 to High(Result.Variants) do
    begin
      MainLine := Format('%d+%d main nodes:',
        [Result.Variants[I].MainNodeCount,
         Result.Variants[I].CrossNodeCount]);
      for var Node in Result.Variants[I].Model.TemperatureNodes do
        MainLine := MainLine + Format(' %.6f', [Node]);
      OutRes.Add(MainLine);

      CrossLine := Format('%d+%d cross nodes:',
        [Result.Variants[I].MainNodeCount,
         Result.Variants[I].CrossNodeCount]);
      for var Node in Result.Variants[I].Model.CrossTemperatureNodes do
        CrossLine := CrossLine + Format(' %.6f', [Node]);
      OutRes.Add(CrossLine);
    end;

    OutRes.Add('');
    OutRes.Add(Format('%7s %7s %7s %11s %11s %12s %12s %9s '+
      '%10s %8s %11s %8s',
      ['Main', 'Cross', 'Coeff', 'Rank G', 'Rank H',
       'Condition G', 'Condition H', 'Converged', 'Zenith',
       'PASS', 'Norm error', 'Selected']));
    OutRes.Add(StringOfChar('-', 142));
    for var I := 0 to High(Result.Variants) do
      with Result.Variants[I] do
        OutRes.Add(Format('%7d %7d %7d %4d/%-6d %4d/%-6d '+
          '%12.6g %12.6g %9s %10.6f %4d/5 %11.6f %8s',
          [MainNodeCount, CrossNodeCount, Model.lin_CoeffCount,
           Fit.AccRank, Model.lin_CoeffCount,
           Fit.MagRank, Model.lin_CoeffCount,
           Fit.AccCondition, Fit.MagCondition, lin_YesNo(Converged),
           ZenithMaxAbs, MaxAbsPassCount, NormalizedMaxError,
           lin_YesNo(I = Result.SelectedIndex)]));

    OutRes.Add('');
    OutRes.Add(Format('%-24s %8s %s',
      ['Parameter', 'Limit', 'MaxAbs by main+cross nodes']));
    OutRes.Add(StringOfChar('-', 142));
    for var MetricNo := 0 to ControlledMetricCount - 1 do
    begin
      MetricLine := Format('%-24s %8.3f',
        [ControlledMetricName[MetricNo],
         ControlledMetricLimit[MetricNo]]);
      for var I := 0 to High(Result.Variants) do
      begin
        var Metric := Result.Variants[I].Metrics.Metrics[
          ControlledMetricIndex[MetricNo]];
        MetricLine := MetricLine + Format('  %dn+%dc=%9.4f %s',
          [Result.Variants[I].MainNodeCount,
           Result.Variants[I].CrossNodeCount, Metric.MaxAbs,
           lin_PassFail(Metric.MaxAbs,
             ControlledMetricLimit[MetricNo])]);
      end;
      OutRes.Add(MetricLine);
    end;

    OutRes.Add('');
    with Result.Variants[Result.SelectedIndex] do
      OutRes.Add(Format('SELECTED: %d main + %d cross nodes, '+
        '%d coefficients per axis; Zenith MaxAbs=%.6f deg.',
        [MainNodeCount, CrossNodeCount, Model.lin_CoeffCount,
         ZenithMaxAbs]));
    OutRes.Add('Selection order: converged fit; Zenith PASS; '+
      'minimum Zenith MaxAbs; most other strict PASS; lowest '+
      'normalized MaxAbs error; fewer coefficients.');
    OutRes.Add('Warning: these are ALL-row in-sample metrics. '+
      'Confirm the selected structure with held-out validation before use.');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_CompareTargetedZenithModels(
  const Huber: THuberIrlsOptions;
  OutRes: TStrings): TLinZenithGridComparison;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function lin_Evaluate(const Name: string;
    const Model: TLinTemperatureModel): TLinZenithGridVariantResult;
  begin
    Result := Default(TLinZenithGridVariantResult);
    Result.ModelName := Name;
    Result.MainNodeCount := Model.lin_NodeCount;
    Result.CrossNodeCount := Model.lin_CrossNodeCount;
    Result.Model := Model;
    Result.Fit := lin_RunLS(Model, Huber);
    Result.Metrics := lin_CalculateAll(Result.Fit);
    Result.Converged :=
      Result.Fit.Diagnostics[sAcc].Converged and
      Result.Fit.Diagnostics[sMag].Converged;
    Result.ZenithMaxAbs := Result.Metrics.Metrics[
      ControlledMetricIndex[0]].MaxAbs;
    Result.ZenithPass :=
      Result.ZenithMaxAbs <= ControlledMetricLimit[0];
    Result.OtherMaxAbsPassCount := 0;
    Result.MaxAbsPassCount := 0;
    Result.NormalizedMaxError := 0;
    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := Result.Metrics.Metrics[ControlledMetricIndex[I]];
      if Metric.MaxAbs <= ControlledMetricLimit[I] then
      begin
        Inc(Result.MaxAbsPassCount);
        if I > 0 then
          Inc(Result.OtherMaxAbsPassCount);
      end;
      Result.NormalizedMaxError := Result.NormalizedMaxError +
        Metric.MaxAbs / ControlledMetricLimit[I];
    end;
    Result.NormalizedMaxError :=
      Result.NormalizedMaxError / ControlledMetricCount;
  end;

  function lin_IsBetter(const Candidate, Current:
    TLinZenithGridVariantResult): Boolean;
  const
    ErrorTolerance = 1E-12;
  begin
    if Candidate.Converged <> Current.Converged then
      Exit(Candidate.Converged);
    if Candidate.ZenithPass <> Current.ZenithPass then
      Exit(Candidate.ZenithPass);
    if Abs(Candidate.ZenithMaxAbs - Current.ZenithMaxAbs) >
       ErrorTolerance then
      Exit(Candidate.ZenithMaxAbs < Current.ZenithMaxAbs);
    if Candidate.OtherMaxAbsPassCount <>
       Current.OtherMaxAbsPassCount then
      Exit(Candidate.OtherMaxAbsPassCount >
        Current.OtherMaxAbsPassCount);
    if Abs(Candidate.NormalizedMaxError -
       Current.NormalizedMaxError) > ErrorTolerance then
      Exit(Candidate.NormalizedMaxError <
        Current.NormalizedMaxError);
    Result := Candidate.Model.lin_CoeffCount <
      Current.Model.lin_CoeffCount;
  end;

var
  MainLine, CrossLine, MetricLine: string;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CompareTargetedZenithModels must be called after '+
      'TpolyMath.Init');
  Huber.Validate;

  Result := Default(TLinZenithGridComparison);
  Result.SelectedIndex := -1;
  SetLength(Result.Variants, 4);
  Result.Variants[0] := lin_Evaluate('standard-6+5',
    lin_CreateReducedCrossNodeModel(6, 5));
  Result.Variants[1] := lin_Evaluate('standard-8+5',
    lin_CreateReducedCrossNodeModel(8, 5));
  Result.Variants[2] := lin_Evaluate('target-7+5',
    lin_CreateTargetedZenithModel(7));
  Result.Variants[3] := lin_Evaluate('target-8+5',
    lin_CreateTargetedZenithModel(8));

  for var I := 0 to High(Result.Variants) do
    if (Result.SelectedIndex < 0) or
       lin_IsBetter(Result.Variants[I],
         Result.Variants[Result.SelectedIndex]) then
      Result.SelectedIndex := I;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('TARGETED ZENITH MAIN-GRID COMPARISON');
    OutRes.Add(StringOfChar('=', 144));
    OutRes.Add(Format('Rows=%d; Huber enabled=%s; k=%.6g; '+
      'iterations=%d; tolerance=%.6g; balanced=%s',
      [Length(InpData.Inpt), lin_YesNo(Huber.Enabled), Huber.Limit,
       Huber.MaxIterations, Huber.WeightTolerance,
       lin_YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('Target rule: in the middle SetNo range keep its '+
      'real center and upper boundary, omit its lower boundary.');
    OutRes.Add('Cross grid: five real SetNo centers; the same '+
      'complete model structure is used for G and H.');
    OutRes.Add('');

    for var I := 0 to High(Result.Variants) do
    begin
      MainLine := Result.Variants[I].ModelName + ' main nodes:';
      for var Node in Result.Variants[I].Model.TemperatureNodes do
        MainLine := MainLine + Format(' %.6f', [Node]);
      OutRes.Add(MainLine);
      CrossLine := Result.Variants[I].ModelName + ' cross nodes:';
      for var Node in Result.Variants[I].Model.CrossTemperatureNodes do
        CrossLine := CrossLine + Format(' %.6f', [Node]);
      OutRes.Add(CrossLine);
    end;

    OutRes.Add('');
    OutRes.Add(Format('%-16s %5s %5s %7s %11s %11s %12s %12s '+
      '%9s %10s %8s %11s %8s',
      ['Model', 'Main', 'Cross', 'Coeff', 'Rank G', 'Rank H',
       'Condition G', 'Condition H', 'Converged', 'Zenith',
       'PASS', 'Norm error', 'Selected']));
    OutRes.Add(StringOfChar('-', 144));
    for var I := 0 to High(Result.Variants) do
      with Result.Variants[I] do
        OutRes.Add(Format('%-16s %5d %5d %7d %4d/%-6d '+
          '%4d/%-6d %12.6g %12.6g %9s %10.6f %4d/5 '+
          '%11.6f %8s',
          [ModelName, MainNodeCount, CrossNodeCount,
           Model.lin_CoeffCount, Fit.AccRank, Model.lin_CoeffCount,
           Fit.MagRank, Model.lin_CoeffCount,
           Fit.AccCondition, Fit.MagCondition, lin_YesNo(Converged),
           ZenithMaxAbs, MaxAbsPassCount, NormalizedMaxError,
           lin_YesNo(I = Result.SelectedIndex)]));

    OutRes.Add('');
    OutRes.Add(Format('%-24s %8s %s',
      ['Parameter', 'Limit', 'MaxAbs by model']));
    OutRes.Add(StringOfChar('-', 144));
    for var MetricNo := 0 to ControlledMetricCount - 1 do
    begin
      MetricLine := Format('%-24s %8.3f',
        [ControlledMetricName[MetricNo],
         ControlledMetricLimit[MetricNo]]);
      for var I := 0 to High(Result.Variants) do
      begin
        var Metric := Result.Variants[I].Metrics.Metrics[
          ControlledMetricIndex[MetricNo]];
        MetricLine := MetricLine + Format('  %s=%9.4f %s',
          [Result.Variants[I].ModelName, Metric.MaxAbs,
           lin_PassFail(Metric.MaxAbs,
             ControlledMetricLimit[MetricNo])]);
      end;
      OutRes.Add(MetricLine);
    end;

    OutRes.Add('');
    with Result.Variants[Result.SelectedIndex] do
      OutRes.Add(Format('SELECTED: %s, %d coefficients per axis; '+
        'Zenith MaxAbs=%.6f deg.',
        [ModelName, Model.lin_CoeffCount, ZenithMaxAbs]));
    OutRes.Add('Selection order: converged fit; Zenith PASS; '+
      'minimum Zenith MaxAbs; most other strict PASS; lowest '+
      'normalized MaxAbs error; fewer coefficients.');
    OutRes.Add('Warning: these are ALL-row in-sample metrics. '+
      'Confirm the selected structure with held-out validation before use.');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_CompareCrossModels(
  const Huber: THuberIrlsOptions;
  OutRes: TStrings): TLinCrossModelComparison;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith', 'Magnetic inclination', 'Azimuth (Z > 5 deg)',
    'Accelerometer norm', 'Magnetometer norm');
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string =
    ('deg', 'deg', 'deg', '%', '%');
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_PassCount(const Metrics: TLinAllMetricsResult): Integer;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      if Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs <=
         ControlledMetricLimit[I] then
        Inc(Result);
  end;

  function lin_NormalizedMaxError(
    const Metrics: TLinAllMetricsResult): Double;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      Result := Result +
        Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs /
        ControlledMetricLimit[I];
    Result := Result / ControlledMetricCount;
  end;

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_CompareCrossModels must be called after TpolyMath.Init');
  Huber.Validate;

  var LinearModel := lin_CreateModel(True);
  var FiveNodeModel := lin_CreateFiveNodeCrossModel;
  var PiecewiseModel := lin_CreatePiecewiseCrossModel;
  Result := Default(TLinCrossModelComparison);
  Result.LinearFit := lin_RunLS(LinearModel, Huber);
  Result.FiveNodeFit := lin_RunLS(FiveNodeModel, Huber);
  Result.PiecewiseFit := lin_RunLS(PiecewiseModel, Huber);
  Result.LinearMetrics := lin_CalculateAll(Result.LinearFit);
  Result.FiveNodeMetrics := lin_CalculateAll(Result.FiveNodeFit);
  Result.PiecewiseMetrics := lin_CalculateAll(Result.PiecewiseFit);

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('CROSS-AXIS TEMPERATURE MODEL COMPARISON');
    OutRes.Add(StringOfChar('=', 132));
    OutRes.Add(Format('Rows=%d; nodes=%d; Huber enabled=%s; '+
      'k=%.6g; iterations=%d; tolerance=%.6g; balanced=%s',
      [Length(InpData.Inpt), LinearModel.lin_NodeCount,
       lin_YesNo(Huber.Enabled), Huber.Limit, Huber.MaxIterations,
       Huber.WeightTolerance,
       lin_YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('');
    var CrossNodeLine := 'Five cross nodes, deg C:';
    for var Node in FiveNodeModel.CrossTemperatureNodes do
      CrossNodeLine := CrossNodeLine + Format(' %.6f', [Node]);
    OutRes.Add(CrossNodeLine);
    OutRes.Add('');
    OutRes.Add(Format('%-25s %8s %10s %10s %14s %14s %10s',
      ['Model', 'Coeff', 'Rank G', 'Rank H', 'Condition G',
       'Condition H', 'Converged']));
    OutRes.Add(StringOfChar('-', 96));
    OutRes.Add(Format('%-25s %8d %4d/%-5d %4d/%-5d '+
      '%14.6g %14.6g %10s',
      ['cross global linear T', LinearModel.lin_CoeffCount,
       Result.LinearFit.AccRank, LinearModel.lin_CoeffCount,
       Result.LinearFit.MagRank, LinearModel.lin_CoeffCount,
       Result.LinearFit.AccCondition, Result.LinearFit.MagCondition,
       lin_YesNo(Result.LinearFit.Diagnostics[sAcc].Converged and
         Result.LinearFit.Diagnostics[sMag].Converged)]));
    OutRes.Add(Format('%-25s %8d %4d/%-5d %4d/%-5d '+
      '%14.6g %14.6g %10s',
      ['cross piecewise T, 5', FiveNodeModel.lin_CoeffCount,
       Result.FiveNodeFit.AccRank, FiveNodeModel.lin_CoeffCount,
       Result.FiveNodeFit.MagRank, FiveNodeModel.lin_CoeffCount,
       Result.FiveNodeFit.AccCondition,
       Result.FiveNodeFit.MagCondition,
       lin_YesNo(Result.FiveNodeFit.Diagnostics[sAcc].Converged and
         Result.FiveNodeFit.Diagnostics[sMag].Converged)]));
    OutRes.Add(Format('%-25s %8d %4d/%-5d %4d/%-5d '+
      '%14.6g %14.6g %10s',
      ['cross piecewise T, 10', PiecewiseModel.lin_CoeffCount,
       Result.PiecewiseFit.AccRank, PiecewiseModel.lin_CoeffCount,
       Result.PiecewiseFit.MagRank, PiecewiseModel.lin_CoeffCount,
       Result.PiecewiseFit.AccCondition,
       Result.PiecewiseFit.MagCondition,
       lin_YesNo(Result.PiecewiseFit.Diagnostics[sAcc].Converged and
         Result.PiecewiseFit.Diagnostics[sMag].Converged)]));
    OutRes.Add('');
    OutRes.Add(Format('%-23s %6s %11s %11s %11s '+
      '%11s %11s %11s %8s',
      ['Parameter', 'N', 'Lin Mean', '5n Mean', '10n Mean',
       'Lin Max', '5n Max', '10n Max', 'Limit']));
    OutRes.Add(StringOfChar('-', 112));

    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var LinearMetric := Result.LinearMetrics.Metrics[
        ControlledMetricIndex[I]];
      var FiveNodeMetric := Result.FiveNodeMetrics.Metrics[
        ControlledMetricIndex[I]];
      var PiecewiseMetric := Result.PiecewiseMetrics.Metrics[
        ControlledMetricIndex[I]];
      OutRes.Add(Format('%-23s %6d %11.4f %11.4f %11.4f '+
        '%11.4f %11.4f %11.4f %8.3f %-3s',
        [ControlledMetricName[I], LinearMetric.Count,
         LinearMetric.MeanAbs, FiveNodeMetric.MeanAbs,
         PiecewiseMetric.MeanAbs, LinearMetric.MaxAbs,
         FiveNodeMetric.MaxAbs, PiecewiseMetric.MaxAbs,
         ControlledMetricLimit[I], ControlledMetricUnit[I]]));
      OutRes.Add(Format('  MaxAbs: linear=%s; 5-node=%s; '+
        '10-node=%s; delta5=%.6f %s; delta10=%.6f %s',
        [lin_PassFail(LinearMetric.MaxAbs, ControlledMetricLimit[I]),
         lin_PassFail(FiveNodeMetric.MaxAbs,
           ControlledMetricLimit[I]),
         lin_PassFail(PiecewiseMetric.MaxAbs, ControlledMetricLimit[I]),
         FiveNodeMetric.MaxAbs - LinearMetric.MaxAbs,
         ControlledMetricUnit[I],
         PiecewiseMetric.MaxAbs - LinearMetric.MaxAbs,
         ControlledMetricUnit[I]]));
    end;

    var LinearPassCount := lin_PassCount(Result.LinearMetrics);
    var FiveNodePassCount := lin_PassCount(Result.FiveNodeMetrics);
    var PiecewisePassCount := lin_PassCount(Result.PiecewiseMetrics);
    var LinearError := lin_NormalizedMaxError(Result.LinearMetrics);
    var FiveNodeError := lin_NormalizedMaxError(
      Result.FiveNodeMetrics);
    var PiecewiseError := lin_NormalizedMaxError(
      Result.PiecewiseMetrics);
    OutRes.Add('');
    OutRes.Add(Format('Strict MaxAbs PASS: linear=%d/5; '+
      '5-node=%d/5; 10-node=%d/5',
      [LinearPassCount, FiveNodePassCount, PiecewisePassCount]));
    OutRes.Add(Format('Normalized MaxAbs error: linear=%.6f; '+
      '5-node=%.6f; 10-node=%.6f',
      [LinearError, FiveNodeError, PiecewiseError]));

    var BestName := 'global-linear';
    var BestPassCount := LinearPassCount;
    var BestError := LinearError;
    if (FiveNodePassCount > BestPassCount) or
       ((FiveNodePassCount = BestPassCount) and
        (FiveNodeError < BestError)) then
    begin
      BestName := 'piecewise 5-node';
      BestPassCount := FiveNodePassCount;
      BestError := FiveNodeError;
    end;
    if (PiecewisePassCount > BestPassCount) or
       ((PiecewisePassCount = BestPassCount) and
        (PiecewiseError < BestError)) then
      BestName := 'piecewise 10-node';
    OutRes.Add(Format('ALL-ROW RESULT: %s cross model is best by '+
      'strict PASS count, then normalized MaxAbs error.', [BestName]));
    OutRes.Add('Warning: ALL-row metrics are in-sample. A 30/40-'+
      'coefficient model must also pass held-out validation before '+
      'production use.');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.lin_SelectHybridMagHuberParameters(
  const MagHuberKValues: array of Double;
  const AccHuber: THuberIrlsOptions;
  OutRes: TStrings): TLinHybridHuberSelection;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double =
    (0.15, 0.20, 1.00, 0.30, 0.50);

  function lin_BuildCandidate(const Fit: TLinCalibrationResult;
    const Metrics: TLinAllMetricsResult;
    Limit: Double): TLinHuberKCandidateResult;
  begin
    Result := Default(TLinHuberKCandidateResult);
    Result.Limit := Limit;
    Result.Converged := Fit.Diagnostics[sAcc].Converged and
      Fit.Diagnostics[sMag].Converged;
    Result.ZenithMaxAbs := Metrics.Metrics[0].MaxAbs;
    Result.MagneticInclinationMaxAbs := Metrics.Metrics[4].MaxAbs;
    Result.AzimuthMaxAbs := Metrics.Metrics[1].MaxAbs;
    Result.AccelerometerNormMaxAbs := Metrics.Metrics[5].MaxAbs;
    Result.MagnetometerNormMaxAbs := Metrics.Metrics[6].MaxAbs;
    Result.MagneticInclinationPass :=
      Result.MagneticInclinationMaxAbs <= ControlledMetricLimit[1];
    Result.MagnetometerNormPass :=
      Result.MagnetometerNormMaxAbs <= ControlledMetricLimit[4];
    Result.NormalizedMaxError := 0;
    for var I := 0 to ControlledMetricCount - 1 do
    begin
      var Metric := Metrics.Metrics[ControlledMetricIndex[I]];
      if Metric.Count = 0 then
        raise EInvalidOpException.CreateFmt(
          'lin_SelectHybridMagHuberParameters: metric %d is empty', [I]);
      if Metric.MaxAbs <= ControlledMetricLimit[I] then
        Inc(Result.MaxAbsPassCount);
      Result.NormalizedMaxError := Result.NormalizedMaxError +
        Metric.MaxAbs / ControlledMetricLimit[I];
    end;
    Result.NormalizedMaxError := Result.NormalizedMaxError /
      ControlledMetricCount;
  end;

  function lin_IsBetter(const A,
    B: TLinHuberKCandidateResult): Boolean;
  begin
    if A.Converged <> B.Converged then
      Exit(A.Converged);
    if A.MaxAbsPassCount <> B.MaxAbsPassCount then
      Exit(A.MaxAbsPassCount > B.MaxAbsPassCount);
    if not SameValue(A.NormalizedMaxError,
      B.NormalizedMaxError, 1E-12) then
      Exit(A.NormalizedMaxError < B.NormalizedMaxError);
    Result := A.Limit > B.Limit;
  end;

  function lin_YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'lin_SelectHybridMagHuberParameters must be called after Init');
  if Length(MagHuberKValues) = 0 then
    raise EArgumentException.Create(
      'MagHuberKValues must not be empty');
  AccHuber.Validate;
  if not AccHuber.Enabled then
    raise EArgumentException.Create(
      'lin_SelectHybridMagHuberParameters requires AccHuber.Enabled=True');

  Result := Default(TLinHybridHuberSelection);
  Result.AccHuber := AccHuber;
  Result.SelectedIndex := -1;
  SetLength(Result.Candidates, Length(MagHuberKValues));

  for var I := 0 to High(MagHuberKValues) do
  begin
    if IsNan(MagHuberKValues[I]) or
       IsInfinite(MagHuberKValues[I]) or
       (MagHuberKValues[I] <= 0) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'MagHuberKValues[%d] must be finite and positive', [I]);
    var MagHuber := AccHuber;
    MagHuber.Enabled := True;
    MagHuber.Limit := MagHuberKValues[I];
    MagHuber.Validate;
    var Fit := lin_RunHybridFiveNode(AccHuber, MagHuber);
    var Metrics := lin_CalculateAll(Fit);
    Result.Candidates[I] := lin_BuildCandidate(Fit, Metrics,
      MagHuber.Limit);

    if (Result.SelectedIndex < 0) or
       lin_IsBetter(Result.Candidates[I],
         Result.Candidates[Result.SelectedIndex]) then
    begin
      Result.SelectedIndex := I;
      Result.MagHuber := MagHuber;
      Result.Fit := Fit;
      Result.AllMetrics := Metrics;
    end;
  end;

  if Result.SelectedIndex < 0 then
    raise EInvalidOpException.Create(
      'lin_SelectHybridMagHuberParameters: no candidate evaluated');
  Result.Candidates[Result.SelectedIndex].Selected := True;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('HYBRID G24 / H30 HUBER kH SELECTION');
    OutRes.Add(StringOfChar('=', 132));
    OutRes.Add(Format('G: global-linear cross, coeff=24, kG=%.6g; '+
      'H: piecewise 5-node cross, coeff=30; '+
      'MaxIterations=%d; tolerance=%.6g; balanced=%s',
      [AccHuber.Limit, AccHuber.MaxIterations,
       AccHuber.WeightTolerance,
       lin_YesNo(AccHuber.BalanceMaxMinSphere)]));
    OutRes.Add('Ranking: converged; highest strict MaxAbs PASS count; '+
      'lowest normalized MaxAbs error; larger kH on exact tie.');
    OutRes.Add('');
    OutRes.Add(Format('%-8s %-9s %-8s %-11s %-11s %-11s '+
      '%-11s %-11s %-10s %-8s',
      ['kH', 'Converged', 'Passes', 'Zen Max', 'MagInc Max',
       'Azi Max', 'G norm Max', 'H norm Max', 'Error idx',
       'Selected']));
    OutRes.Add(StringOfChar('-', 132));
    for var Candidate in Result.Candidates do
      OutRes.Add(Format('%-8.3g %-9s %3d/5    %-11.4f %-11.4f '+
        '%-11.4f %-11.4f %-11.4f %-10.6f %-8s',
        [Candidate.Limit, lin_YesNo(Candidate.Converged),
         Candidate.MaxAbsPassCount, Candidate.ZenithMaxAbs,
         Candidate.MagneticInclinationMaxAbs,
         Candidate.AzimuthMaxAbs,
         Candidate.AccelerometerNormMaxAbs,
         Candidate.MagnetometerNormMaxAbs,
         Candidate.NormalizedMaxError,
         lin_YesNo(Candidate.Selected)]));
    OutRes.Add('');
    OutRes.Add(Format('Selected: kG=%.6g; kH=%.6g; strict PASS=%d/5',
      [Result.AccHuber.Limit, Result.MagHuber.Limit,
       Result.Candidates[Result.SelectedIndex].MaxAbsPassCount]));
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.BuildValidationSamples(
  OrientationTolerance: Double): TArray<TValidationSample>;
var
  Representatives: TList<TOrientationKey>;
  Key: TOrientationKey;
  GroupNo: Integer;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TpolyMath.BuildValidationSamples must be called after TpolyMath.Init');
  if IsNan(OrientationTolerance) or IsInfinite(OrientationTolerance) or
     (OrientationTolerance <= 0) or (OrientationTolerance >= 180) then
    raise EArgumentOutOfRangeException.Create(
      'OrientationTolerance must be finite and in the range 0..180 degrees');

  SetLength(Result, Length(InpData.Inpt));
  Representatives := TList<TOrientationKey>.Create;
  try
    for var I := 0 to High(InpData.Inpt) do
    begin
      if IsNan(InpData.Inpt[I].Azi) or
         IsInfinite(InpData.Inpt[I].Azi) or
         IsNan(InpData.Inpt[I].Zen) or
         IsInfinite(InpData.Inpt[I].Zen) or
         IsNan(InpData.Inpt[I].Vis) or
         IsInfinite(InpData.Inpt[I].Vis) then
        raise EArgumentException.CreateFmt(
          'Source row %d has a non-finite Azi, Zen or Vis angle', [I]);

      GroupNo := -1;
      for var J := 0 to Representatives.Count - 1 do
      begin
        Key := Representatives[J];
        if (OrientationAngleDistance(InpData.Inpt[I].Azi, Key.Azi) <=
              OrientationTolerance) and
           (OrientationAngleDistance(InpData.Inpt[I].Zen, Key.Zen) <=
              OrientationTolerance) and
           (OrientationAngleDistance(InpData.Inpt[I].Vis, Key.Vis) <=
              OrientationTolerance) then
        begin
          GroupNo := J + 1;
          Break;
        end;
      end;

      if GroupNo < 0 then
      begin
        Key.Azi := InpData.Inpt[I].Azi;
        Key.Zen := InpData.Inpt[I].Zen;
        Key.Vis := InpData.Inpt[I].Vis;
        GroupNo := Representatives.Add(Key) + 1;
      end;

      Result[I] := TValidationSample.Create(
        InpData.Inpt[I].SetNo,
        InpData.Inpt[I].T,
        I,
        GroupNo);
    end;
  finally
    Representatives.Free;
  end;
end;

procedure DesignRankAndCondition(const Model: PolyModel;
  const SourceData: TArray<TinclInput>;
  const TrainingIndices: TArray<Integer>; Sensor: SetSetsor;
  TemperatureMin, TemperatureMax: Double;
  out MinimumRank: Integer; out WorstCondition: Double);
const
  RelativeEigenTolerance = 1E-10;
var
  Design: TVArray<Double>;
  Gram: TArray<TArray<Double>>;
  Norms: TArray<Double>;
  EigenValue, MaximumEigen, MinimumEigen: Double;
  Row, ColumnCount, P, Q, Iteration, MaximumIterations: Integer;
  C, S, Tau, T, App, Aqq, Apq, Value, MaximumOffDiagonal: Double;
begin
  ColumnCount := Model.KoeffCnt;
  MinimumRank := ColumnCount;
  WorstCondition := 0;

  for var Axis in SVectors do
    SetLength(Design[Axis], Length(TrainingIndices) * ColumnCount);

  for Row := 0 to High(TrainingIndices) do
  begin
    var SourceIndex := TrainingIndices[Row];
    var PowerT := Model.CreatePowerT(SourceData[SourceIndex].T,
      TemperatureMin, TemperatureMax, Model.MaxPowT);
    var Raw: TVector3;
    var Scale: Double;
    if Sensor = sAcc then
    begin
      Raw := SourceData[SourceIndex].G;
      Scale := SCALE_A;
    end
    else
    begin
      Raw := SourceData[SourceIndex].H;
      Scale := SCALE_H;
    end;
    var Rows := Model.RowToArrays(Model.CreateRow(PowerT, Raw.V, Scale));
    for var Axis in SVectors do
      for var J := 0 to ColumnCount - 1 do
        Design[Axis][Row * ColumnCount + J] := Rows[Axis][J];
  end;

  for var Axis in SVectors do
  begin
    SetLength(Norms, ColumnCount);
    SetLength(Gram, ColumnCount);
    for P := 0 to ColumnCount - 1 do
    begin
      SetLength(Gram[P], ColumnCount);
      Norms[P] := 0;
      for Row := 0 to High(TrainingIndices) do
        Norms[P] := Norms[P] +
          Sqr(Design[Axis][Row * ColumnCount + P]);
      Norms[P] := Sqrt(Norms[P]);
    end;

    for P := 0 to ColumnCount - 1 do
      for Q := P to ColumnCount - 1 do
      begin
        Value := 0;
        if (Norms[P] > 0) and (Norms[Q] > 0) then
          for Row := 0 to High(TrainingIndices) do
            Value := Value +
              Design[Axis][Row * ColumnCount + P] *
              Design[Axis][Row * ColumnCount + Q] /
              (Norms[P] * Norms[Q]);
        Gram[P][Q] := Value;
        Gram[Q][P] := Value;
      end;

    { Symmetric Jacobi eigensolver for the small column-normalized Gram
      matrix. Column normalization makes the reported condition number a
      collinearity diagnostic rather than a consequence of engineering units. }
    MaximumIterations := 100 * ColumnCount * ColumnCount;
    for Iteration := 0 to MaximumIterations - 1 do
    begin
      MaximumOffDiagonal := 0;
      P := 0;
      Q := 0;
      for var I := 0 to ColumnCount - 2 do
        for var J := I + 1 to ColumnCount - 1 do
          if Abs(Gram[I][J]) > MaximumOffDiagonal then
          begin
            MaximumOffDiagonal := Abs(Gram[I][J]);
            P := I;
            Q := J;
          end;
      if MaximumOffDiagonal <= 1E-14 then
        Break;

      App := Gram[P][P];
      Aqq := Gram[Q][Q];
      Apq := Gram[P][Q];
      Tau := (Aqq - App) / (2 * Apq);
      if Tau >= 0 then
        T := 1 / (Tau + Sqrt(1 + Sqr(Tau)))
      else
        T := -1 / (-Tau + Sqrt(1 + Sqr(Tau)));
      C := 1 / Sqrt(1 + Sqr(T));
      S := T * C;

      for var K := 0 to ColumnCount - 1 do
        if (K <> P) and (K <> Q) then
        begin
          var Akp := Gram[K][P];
          var Akq := Gram[K][Q];
          Gram[K][P] := C * Akp - S * Akq;
          Gram[P][K] := Gram[K][P];
          Gram[K][Q] := S * Akp + C * Akq;
          Gram[Q][K] := Gram[K][Q];
        end;
      Gram[P][P] := App - T * Apq;
      Gram[Q][Q] := Aqq + T * Apq;
      Gram[P][Q] := 0;
      Gram[Q][P] := 0;
    end;

    MaximumEigen := 0;
    for P := 0 to ColumnCount - 1 do
      MaximumEigen := Max(MaximumEigen, Gram[P][P]);
    MinimumEigen := MaxDouble;
    var Rank := 0;
    for P := 0 to ColumnCount - 1 do
    begin
      EigenValue := Max(0.0, Gram[P][P]);
      if EigenValue > MaximumEigen * RelativeEigenTolerance then
      begin
        Inc(Rank);
        MinimumEigen := Min(MinimumEigen, EigenValue);
      end;
    end;
    MinimumRank := Min(MinimumRank, Rank);
    if (Rank < ColumnCount) or (MinimumEigen = MaxDouble) or
       (MinimumEigen <= 0) then
      WorstCondition := MaxDouble
    else
      WorstCondition := Max(WorstCondition,
        Sqrt(MaximumEigen / MinimumEigen));
  end;
end;

function CheckLogoIdentifiability(const Fold: TValidationFold;
  const Model: PolyModel; const SourceData: TArray<TinclInput>;
  TemperatureMin, TemperatureMax: Double;
  const Options: TLogoSpatialOptions): TLogoIdentifiability;
var
  FullMin, FullMax: TSensorVect;
  TemperatureLevels: TDictionary<Integer, Byte>;
  TestZeniths, TestAzimuths, TestToolfaces: TDictionary<Integer, Byte>;
begin
  Result := Default(TLogoIdentifiability);
  Result.FoldName := Fold.Name;
  Result.RequiredRank := Model.KoeffCnt;
  Result.RowsPerCoefficient := Length(Fold.TrainingIndices) /
    Max(1, Model.KoeffCnt);

  for var Sensor in [sAcc, sMag] do
    for var Axis in SVectors do
    begin
      FullMin[Sensor].V[Integer(Axis)] := MaxDouble;
      FullMax[Sensor].V[Integer(Axis)] := -MaxDouble;
      Result.RawMin[Sensor].V[Integer(Axis)] := MaxDouble;
      Result.RawMax[Sensor].V[Integer(Axis)] := -MaxDouble;
    end;

  for var Input in SourceData do
    for var Axis in SVectors do
    begin
      FullMin[sAcc].V[Integer(Axis)] := Min(
        FullMin[sAcc].V[Integer(Axis)], Input.G.V[Integer(Axis)]);
      FullMax[sAcc].V[Integer(Axis)] := Max(
        FullMax[sAcc].V[Integer(Axis)], Input.G.V[Integer(Axis)]);
      FullMin[sMag].V[Integer(Axis)] := Min(
        FullMin[sMag].V[Integer(Axis)], Input.H.V[Integer(Axis)]);
      FullMax[sMag].V[Integer(Axis)] := Max(
        FullMax[sMag].V[Integer(Axis)], Input.H.V[Integer(Axis)]);
    end;

  TemperatureLevels := TDictionary<Integer, Byte>.Create;
  TestZeniths := TDictionary<Integer, Byte>.Create;
  TestAzimuths := TDictionary<Integer, Byte>.Create;
  TestToolfaces := TDictionary<Integer, Byte>.Create;
  try
    for var SourceIndex in Fold.TrainingIndices do
    begin
      var Input := SourceData[SourceIndex];
      var TemperatureKey: Integer;
      if Input.SetNo >= 0 then
        TemperatureKey := Input.SetNo
      else
        TemperatureKey := Round(Input.T);
      if not TemperatureLevels.ContainsKey(TemperatureKey) then
        TemperatureLevels.Add(TemperatureKey, 0);

      for var Axis in SVectors do
      begin
        Result.RawMin[sAcc].V[Integer(Axis)] := Min(
          Result.RawMin[sAcc].V[Integer(Axis)], Input.G.V[Integer(Axis)]);
        Result.RawMax[sAcc].V[Integer(Axis)] := Max(
          Result.RawMax[sAcc].V[Integer(Axis)], Input.G.V[Integer(Axis)]);
        Result.RawMin[sMag].V[Integer(Axis)] := Min(
          Result.RawMin[sMag].V[Integer(Axis)], Input.H.V[Integer(Axis)]);
        Result.RawMax[sMag].V[Integer(Axis)] := Max(
          Result.RawMax[sMag].V[Integer(Axis)], Input.H.V[Integer(Axis)]);
      end;
    end;
    Result.TemperatureLevelCount := TemperatureLevels.Count;
    for var SourceIndex in Fold.TestIndices do
    begin
      var Input := SourceData[SourceIndex];
      var Key := Trunc(NormalizeAngle360(Input.Zen) / 180.0);
      if not TestZeniths.ContainsKey(Key) then
        TestZeniths.Add(Key, 0);
      Key := Trunc(NormalizeAngle360(Input.Azi) / 60.0);
      if not TestAzimuths.ContainsKey(Key) then
        TestAzimuths.Add(Key, 0);
      Key := Round(NormalizeAngle360(Input.Vis) / 72.0) mod 5;
      if not TestToolfaces.ContainsKey(Key) then
        TestToolfaces.Add(Key, 0);
    end;
    Result.TestZenithFamilyCount := TestZeniths.Count;
    Result.TestAzimuthBinCount := TestAzimuths.Count;
    Result.TestToolfaceBinCount := TestToolfaces.Count;
  finally
    TestToolfaces.Free;
    TestAzimuths.Free;
    TestZeniths.Free;
    TemperatureLevels.Free;
  end;

  for var Sensor in [sAcc, sMag] do
    for var Axis in SVectors do
    begin
      var FullRange := FullMax[Sensor].V[Integer(Axis)] -
        FullMin[Sensor].V[Integer(Axis)];
      if FullRange > 0 then
        Result.RangeRatio[Sensor].V[Integer(Axis)] :=
          (Result.RawMax[Sensor].V[Integer(Axis)] -
           Result.RawMin[Sensor].V[Integer(Axis)]) / FullRange
      else
        Result.RangeRatio[Sensor].V[Integer(Axis)] := 0;
    end;

  DesignRankAndCondition(Model, SourceData, Fold.TrainingIndices, sAcc,
    TemperatureMin, TemperatureMax, Result.AccRank, Result.AccCondition);
  DesignRankAndCondition(Model, SourceData, Fold.TrainingIndices, sMag,
    TemperatureMin, TemperatureMax, Result.MagRank, Result.MagCondition);

  Result.Accepted := False;
  if Result.RowsPerCoefficient < Options.MinRowsPerCoefficient then
    Result.Reason := Format('rows/coefficient %.2f; required %.2f',
      [Result.RowsPerCoefficient, Double(Options.MinRowsPerCoefficient)])
  else if Result.TemperatureLevelCount < Model.MaxPowT + 1 then
    Result.Reason := Format('temperature levels %d; required %d',
      [Result.TemperatureLevelCount, Model.MaxPowT + 1])
  else if (Pos('Checkerboard', Fold.Name) > 0) and
          ((Result.TestZenithFamilyCount < 2) or
           (Result.TestAzimuthBinCount < 2) or
           (Result.TestToolfaceBinCount < 2)) then
    Result.Reason := Format(
      'checkerboard coverage Z/A/V=%d/%d/%d; each requires at least 2',
      [Result.TestZenithFamilyCount, Result.TestAzimuthBinCount,
       Result.TestToolfaceBinCount])
  else if Result.AccRank < Result.RequiredRank then
    Result.Reason := Format('accelerometer rank %d; required %d',
      [Result.AccRank, Result.RequiredRank])
  else if Result.MagRank < Result.RequiredRank then
    Result.Reason := Format('magnetometer rank %d; required %d',
      [Result.MagRank, Result.RequiredRank])
  else if Result.AccCondition > Options.MaxConditionNumber then
    Result.Reason := Format('accelerometer condition %.6g exceeds %.6g',
      [Result.AccCondition, Options.MaxConditionNumber])
  else if Result.MagCondition > Options.MaxConditionNumber then
    Result.Reason := Format('magnetometer condition %.6g exceeds %.6g',
      [Result.MagCondition, Options.MaxConditionNumber])
  else
  begin
    Result.Accepted := True;
    for var Sensor in [sAcc, sMag] do
      for var Axis in SVectors do
        if Result.RangeRatio[Sensor].V[Integer(Axis)] <
           Options.MinRawRangeRatio then
        begin
          Result.Accepted := False;
          var SensorName: string;
          if Sensor = sAcc then
            SensorName := 'G'
          else
            SensorName := 'H';
          Result.Reason := Format('%s%s raw range retained %.1f%%; required %.1f%%',
            [SensorName,
             string(SVectorsNames[Axis]),
             100 * Result.RangeRatio[Sensor].V[Integer(Axis)],
             100 * Options.MinRawRangeRatio]);
          Break;
        end;
    if Result.Accepted then
      Result.Reason := 'accepted';
  end;
end;

function BuildSpatialLogoFolds(const BaseSamples: TArray<TValidationSample>;
  const SourceData: TArray<TinclInput>; const Options: TLogoSpatialOptions;
  out CombinedAnalysis: TArray<TLogoGroupAnalysis>): TArray<TValidationFold>;
var
  Samples: TArray<TValidationSample>;
  Folds: TList<TValidationFold>;
  Analyses: TList<TLogoGroupAnalysis>;
  BuildOptions: TLogoBuildOptions;
  FullMin, FullMax: TVector3;

  procedure AppendScheme(const SchemeName: string;
    const GroupLabels: TArray<string>; OnlyGroup: Integer);
  var
    SchemeFolds: TArray<TValidationFold>;
    SchemeAnalysis: TArray<TLogoGroupAnalysis>;
    FoldIndex: Integer;
  begin
    SchemeFolds := TValidationFoldBuilder.AnalyzeOrientationGroups(
      Samples, BuildOptions, SchemeAnalysis);
    FoldIndex := 0;
    for var I := 0 to High(SchemeAnalysis) do
    begin
      var GroupNo := SchemeAnalysis[I].OrientationGroup;
      if (GroupNo >= 0) and (GroupNo < Length(GroupLabels)) then
        SchemeAnalysis[I].GroupName := SchemeName + ': ' +
          GroupLabels[GroupNo]
      else
        SchemeAnalysis[I].GroupName := Format('%s: group %d',
          [SchemeName, GroupNo]);

      if SchemeAnalysis[I].Accepted then
      begin
        if (FoldIndex > High(SchemeFolds)) then
          raise EInvalidOpException.Create(
            'Internal LOGO fold/analysis order mismatch');
        SchemeFolds[FoldIndex].Name := 'LOGO ' +
          SchemeAnalysis[I].GroupName;
        if (OnlyGroup < 0) or (GroupNo = OnlyGroup) then
        begin
          Folds.Add(SchemeFolds[FoldIndex]);
          Analyses.Add(SchemeAnalysis[I]);
        end;
        Inc(FoldIndex);
      end
      else if (OnlyGroup < 0) or (GroupNo = OnlyGroup) then
        Analyses.Add(SchemeAnalysis[I]);
    end;
  end;

begin
  Options.Validate;
  Samples := Copy(BaseSamples, 0, Length(BaseSamples));
  Folds := TList<TValidationFold>.Create;
  Analyses := TList<TLogoGroupAnalysis>.Create;
  try
    BuildOptions := TLogoBuildOptions.Default;
    BuildOptions.MinTestCount := 2;
    var KnownSeries := TDictionary<Integer, Byte>.Create;
    try
      for var Sample in BaseSamples do
        if (Sample.SetNo >= 0) and not KnownSeries.ContainsKey(Sample.SetNo) then
          KnownSeries.Add(Sample.SetNo, 0);
      { A spatial region is valid only when it is represented in every known
        temperature series. Otherwise the holdout mixes spatial absence with
        a temperature-series imbalance. }
      BuildOptions.MinTestSeriesCount := Max(2, KnownSeries.Count);
    finally
      KnownSeries.Free;
    end;
    BuildOptions.MinTrainingGroupCount := 2;

    { Six complete azimuth sectors, immediately across both zeniths,
      all toolfaces, temperatures and acquisition series. }
    var SectorCount := Round(360.0 / Options.AzimuthSectorWidth);
    var Labels: TArray<string>;
    SetLength(Labels, SectorCount);
    for var GroupNo := 0 to SectorCount - 1 do
      Labels[GroupNo] := Format('A=%.0f..%.0f°',
        [GroupNo * Options.AzimuthSectorWidth,
         (GroupNo + 1) * Options.AzimuthSectorWidth]);
    for var I := 0 to High(Samples) do
      Samples[I].OrientationGroup := Min(SectorCount - 1,
        Trunc(NormalizeAngle360(SourceData[I].Azi) /
          Options.AzimuthSectorWidth));
    AppendScheme('AziSector', Labels, -1);

    { Recommended V=0/72, V=144, V=216/288 folds. Values are assigned to
      the nearest nominal toolface, so small table-setting errors do not split
      a spatial region. }
    Labels := ['V=0/72°', 'V=144°', 'V=216/288°'];
    var ToolfaceCount := Max(1, Round(360.0 / Options.ToolfaceStep));
    for var I := 0 to High(Samples) do
    begin
      var ToolfaceIndex := Round(
        NormalizeAngle360(SourceData[I].Vis) / Options.ToolfaceStep) mod
        ToolfaceCount;
      if ToolfaceCount = 5 then
        case ToolfaceIndex of
          0, 1: Samples[I].OrientationGroup := 0;
          2: Samples[I].OrientationGroup := 1;
        else
          Samples[I].OrientationGroup := 2;
        end
      else
        Samples[I].OrientationGroup := ToolfaceIndex mod 3;
    end;
    AppendScheme('Toolface', Labels, -1);

    { Distributed checkerboard. The second zenith family changes index_Z,
      while azimuth and toolface use their nominal acquisition indices. }
    SetLength(Labels, Options.CheckerboardK);
    for var GroupNo := 0 to Options.CheckerboardK - 1 do
      Labels[GroupNo] := Format('(iA+2*iV+iZ) mod %d = %d',
        [Options.CheckerboardK, GroupNo]);
    for var I := 0 to High(Samples) do
    begin
      var IndexA := Trunc(NormalizeAngle360(SourceData[I].Azi) /
        Options.AzimuthSectorWidth);
      var IndexV := Round(NormalizeAngle360(SourceData[I].Vis) /
        Options.ToolfaceStep) mod ToolfaceCount;
      var IndexZ := Trunc(NormalizeAngle360(SourceData[I].Zen) / 180.0);
      Samples[I].OrientationGroup :=
        (IndexA + 2 * IndexV + IndexZ) mod Options.CheckerboardK;
    end;
    AppendScheme('Checkerboard', Labels, -1);

    { Six accelerometer axial regions. Each threshold is computed globally,
      and every matching row at every temperature is removed together. }
    for var Axis in SVectors do
    begin
      FullMin.V[Integer(Axis)] := MaxDouble;
      FullMax.V[Integer(Axis)] := -MaxDouble;
      for var Input in SourceData do
      begin
        FullMin.V[Integer(Axis)] := Min(FullMin.V[Integer(Axis)],
          Input.G.V[Integer(Axis)]);
        FullMax.V[Integer(Axis)] := Max(FullMax.V[Integer(Axis)],
          Input.G.V[Integer(Axis)]);
      end;

      for var IsMaximum := 0 to 1 do
      begin
        var Threshold: Double;
        if IsMaximum = 1 then
          Threshold := FullMax.V[Integer(Axis)] -
            Options.AxialTailFraction *
            (FullMax.V[Integer(Axis)] - FullMin.V[Integer(Axis)])
        else
          Threshold := FullMin.V[Integer(Axis)] +
            Options.AxialTailFraction *
            (FullMax.V[Integer(Axis)] - FullMin.V[Integer(Axis)]);
        { First select physical poses, then remove every occurrence of those
          poses. A temperature-dependent raw drift is therefore unable to
          leave a near-duplicate axial orientation in training. }
        var AxialPoses := TDictionary<Integer, Byte>.Create;
        try
          for var I := 0 to High(Samples) do
            if ((IsMaximum = 1) and
                (SourceData[I].G.V[Integer(Axis)] >= Threshold)) or
               ((IsMaximum = 0) and
                (SourceData[I].G.V[Integer(Axis)] <= Threshold)) then
              if not AxialPoses.ContainsKey(
                 BaseSamples[I].OrientationGroup) then
                AxialPoses.Add(BaseSamples[I].OrientationGroup, 0);

          for var I := 0 to High(Samples) do
            if AxialPoses.ContainsKey(BaseSamples[I].OrientationGroup) then
              Samples[I].OrientationGroup := 0
            else
              Samples[I].OrientationGroup := 1;
        finally
          AxialPoses.Free;
        end;

        BuildOptions.MinTrainingGroupCount := 1;
        var TailName: string;
        if IsMaximum = 1 then
          TailName := 'max'
        else
          TailName := 'min';
        Labels := [Format('G%s %s %.1f%% tail',
          [string(SVectorsNames[Axis]),
           TailName,
           100 * Options.AxialTailFraction]), 'remaining sphere'];
        AppendScheme('Axial', Labels, 0);
        BuildOptions.MinTrainingGroupCount := 2;
      end;
    end;

    Result := Folds.ToArray;
    CombinedAnalysis := Analyses.ToArray;
  finally
    Analyses.Free;
    Folds.Free;
  end;
end;

function BuildUnionStressFold(const Samples: TArray<TValidationSample>;
  const BandFold, OrientationFold: TValidationFold): TValidationFold;
var
  BandTraining, OrientationTraining, TestRows:
    TDictionary<Integer, Byte>;
  Training, Test: TList<Integer>;
begin
  { This is intentionally a union holdout:

      test  = temperature band OR orientation group
      train = NOT temperature band AND NOT orientation group

    Intersecting the two training sets implements the second expression.
    Unioning the two test sets implements the first. LTBO embargo rows outside
    the orientation group stay excluded from both sets. }
  BandTraining := TDictionary<Integer, Byte>.Create;
  OrientationTraining := TDictionary<Integer, Byte>.Create;
  TestRows := TDictionary<Integer, Byte>.Create;
  Training := TList<Integer>.Create;
  Test := TList<Integer>.Create;
  try
    for var SourceIndex in BandFold.TrainingIndices do
      if not BandTraining.ContainsKey(SourceIndex) then
        BandTraining.Add(SourceIndex, 0);
    for var SourceIndex in OrientationFold.TrainingIndices do
      if not OrientationTraining.ContainsKey(SourceIndex) then
        OrientationTraining.Add(SourceIndex, 0);

    for var SourceIndex in BandFold.TestIndices do
      if not TestRows.ContainsKey(SourceIndex) then
      begin
        TestRows.Add(SourceIndex, 0);
        Test.Add(SourceIndex);
      end;
    for var SourceIndex in OrientationFold.TestIndices do
      if not TestRows.ContainsKey(SourceIndex) then
      begin
        TestRows.Add(SourceIndex, 0);
        Test.Add(SourceIndex);
      end;

    for var Sample in Samples do
      if BandTraining.ContainsKey(Sample.SourceIndex) and
         OrientationTraining.ContainsKey(Sample.SourceIndex) and
         not TestRows.ContainsKey(Sample.SourceIndex) then
        Training.Add(Sample.SourceIndex);

    Result := Default(TValidationFold);
    Result.Kind := vkLeaveTemperatureBandOrOrientationOut;
    Result.Name := Format('STRESS UNION (%s) OR (%s)',
      [BandFold.Name, OrientationFold.Name]);
    Result.TrainingIndices := Training.ToArray;
    Result.TestIndices := Test.ToArray;
    Result.TestTemperatureMin := MaxDouble;
    Result.TestTemperatureMax := -MaxDouble;
    for var SourceIndex in Result.TestIndices do
    begin
      if (SourceIndex < 0) or (SourceIndex >= Length(Samples)) or
         (Samples[SourceIndex].SourceIndex <> SourceIndex) then
        raise EInvalidOpException.CreateFmt(
          'Stress fold requires dense SourceIndex mapping; invalid index %d',
          [SourceIndex]);
      Result.TestTemperatureMin := Min(Result.TestTemperatureMin,
        Samples[SourceIndex].Temperature);
      Result.TestTemperatureMax := Max(Result.TestTemperatureMax,
        Samples[SourceIndex].Temperature);
    end;
  finally
    Test.Free;
    Training.Free;
    TestRows.Free;
    OrientationTraining.Free;
    BandTraining.Free;
  end;
end;

class function TpolyMath.RunTests: TValidationTestRun;
begin
  Result := RunTests(THuberIrlsOptions.OrdinaryLeastSquares);
end;

class function TpolyMath.RunTests(
  const Huber: THuberIrlsOptions): TValidationTestRun;
var
  Models: TArray<TTemperatureModel>;
begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TpolyMath.RunTests must be called after TpolyMath.Init');

  { TInclinValidationAdapter применяет одну и ту же структуру температурной
    модели к обоим сенсорам. Не следует молча подменять одну из двух моделей,
    если рабочая конфигурация использует разные степени. }
  if (InpData.pmA.ax <> InpData.pmH.ax) or
     (InpData.pmA.ku <> InpData.pmH.ku) or
     (InpData.pmA.dz <> InpData.pmH.dz) then
    raise EInvalidOpException.Create(
      'TpolyMath.RunTests requires equal pmA and pmH polynomial degrees');

  SetLength(Models, 1);
  Models[0] := TTemperatureModel.Create(
    InpData.pmA.ax, InpData.pmA.ku, InpData.pmA.dz);
  Result := RunTests(Models, Huber);
end;

class function TpolyMath.RunTests(
  const Models: TArray<TTemperatureModel>;
  const Huber: THuberIrlsOptions): TValidationTestRun;
begin
  Result := RunTests(Models, Huber, TLogoSpatialOptions.Default);
end;

class function TpolyMath.RunTests(
  const Models: TArray<TTemperatureModel>;
  const Huber: THuberIrlsOptions;
  const LogoOptions: TLogoSpatialOptions): TValidationTestRun;
var
  AllFolds: TList<TValidationFold>;
  LotoFolds, LtboFolds, LogoFolds, CandidateLogoFolds,
  StressFolds:
    TArray<TValidationFold>;
  AcceptedLogo, AcceptedStress: TList<TValidationFold>;
  Conditioning, StressConditioning: TList<TLogoIdentifiability>;
  MaxModel: PolyModel;
  Runner: TValidationRunner;
  AdapterObject: TInclinValidationAdapter;
  Adapter: IValidationModelAdapter;

  SavedPmA, SavedPmH: PolyModel;
  SavedMNak, SavedTMin, SavedTMax: Double;
  SavedInput: TArray<TinclInput>;
  SavedAcc, SavedMag: TArray<RowModel>;
  SavedInclRes: TArray<TInclRes>;
  SavedRes: TPolyRes;
  SavedEStol: TStolError;
  SavedKosRes: TFindLMKosStol;
  SavedHuberDiagnostics: TSensorData<THuberIrlsDiagnostics>;
  SavedVisirDiagnostics: TVisirCorrectionDiagnostics;
  SavedCorStolVisir, SavedCorStolZenit, SavedCorStolMagnit: Boolean;

  procedure AppendFolds(const Source: TArray<TValidationFold>);
  begin
    for var Fold in Source do
      AllFolds.Add(Fold);
  end;

begin
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TpolyMath.RunTests must be called after TpolyMath.Init');
  if Length(Models) = 0 then
    raise EArgumentException.Create(
      'TpolyMath.RunTests requires at least one temperature model');
  for var CandidateModel in Models do
    if (CandidateModel.AxDegree < 0) or
       (CandidateModel.KuDegree < 0) or
       (CandidateModel.DzDegree < 0) then
      raise EArgumentOutOfRangeException.Create(
        'Temperature model degrees must be non-negative');
  Huber.Validate;
  LogoOptions.Validate;

  Result := Default(TValidationTestRun);
  Result.Models := Copy(Models, 0, Length(Models));
  Result.Samples := BuildValidationSamples(DefaultOrientationTolerance);

  { Каждый построитель анализирует фактические данные и возвращает только
    пригодные fold'ы. Диагностика сохраняется даже для отклонённых
    кандидатов, поэтому отсутствие конкретной полосы или группы не теряется. }
  LotoFolds := TValidationFoldBuilder.LeaveSeriesOut(
    Result.Samples, Result.LotoAnalysis);
  LtboFolds := TValidationFoldBuilder.LeaveRecommendedTemperatureBandsOut(
    Result.Samples, Result.LtboAnalysis);
  CandidateLogoFolds := BuildSpatialLogoFolds(Result.Samples,
    InpData.Inpt, LogoOptions, Result.LogoAnalysis);

  { Folds are shared by all candidate models, therefore the check uses the
    component-wise largest requested model. Any nested simpler model then has
    no more columns and cannot silently rescue an underdetermined large one. }
  MaxModel := Default(PolyModel);
  for var CandidateModel in Models do
  begin
    MaxModel.ax := Max(MaxModel.ax, CandidateModel.AxDegree);
    MaxModel.ku := Max(MaxModel.ku, CandidateModel.KuDegree);
    MaxModel.dz := Max(MaxModel.dz, CandidateModel.DzDegree);
  end;
  AcceptedLogo := TList<TValidationFold>.Create;
  Conditioning := TList<TLogoIdentifiability>.Create;
  try
    for var Fold in CandidateLogoFolds do
    begin
      var Check := CheckLogoIdentifiability(Fold, MaxModel,
        InpData.Inpt, InpData.Tmin, InpData.Tmax, LogoOptions);
      Conditioning.Add(Check);
      if Check.Accepted then
        AcceptedLogo.Add(Fold);
    end;
    LogoFolds := AcceptedLogo.ToArray;
    Result.LogoIdentifiability := Conditioning.ToArray;
  finally
    Conditioning.Free;
    AcceptedLogo.Free;
  end;

  { Combined stress folds use the UNION of the two hidden conditions. The
    test set therefore contains the complete temperature band plus the
    complete spatial region at all other temperatures. Only rows outside both
    conditions can train the model. This is deliberately stronger than a
    rectangular intersection holdout. }
  AcceptedStress := TList<TValidationFold>.Create;
  StressConditioning := TList<TLogoIdentifiability>.Create;
  try
    for var BandFold in LtboFolds do
      for var OrientationFold in LogoFolds do
      begin
        var StressFold := BuildUnionStressFold(Result.Samples,
          BandFold, OrientationFold);
        var Check := CheckLogoIdentifiability(StressFold, MaxModel,
          InpData.Inpt, InpData.Tmin, InpData.Tmax, LogoOptions);
        StressConditioning.Add(Check);
        if Check.Accepted then
          AcceptedStress.Add(StressFold);
      end;
    StressFolds := AcceptedStress.ToArray;
    Result.StressIdentifiability := StressConditioning.ToArray;
  finally
    StressConditioning.Free;
    AcceptedStress.Free;
  end;

  AllFolds := TList<TValidationFold>.Create;
  try
    AppendFolds(LotoFolds);
    AppendFolds(LtboFolds);
    AppendFolds(LogoFolds);
    AppendFolds(StressFolds);
    Result.Folds := AllFolds.ToArray;
  finally
    AllFolds.Free;
  end;

  if Length(Result.Folds) = 0 then
    raise EInvalidOpException.Create(
      'TpolyMath.RunTests: no usable validation folds were created');

  { Adapter использует глобальные рабочие поля TpolyMath для каждой подгонки.
    Сохраняем их до запуска и восстанавливаем в finally, чтобы после тестов
    приложение продолжало видеть исходную инициализацию и её результат. }
  SavedPmA := InpData.pmA;
  SavedPmH := InpData.pmH;
  SavedMNak := InpData.MNak;
  SavedTMin := InpData.Tmin;
  SavedTMax := InpData.Tmax;
  SavedInput := Copy(InpData.Inpt, 0, Length(InpData.Inpt));
  SavedAcc := Copy(acc, 0, Length(acc));
  SavedMag := Copy(mag, 0, Length(mag));
  SavedInclRes := Copy(InclRes, 0, Length(InclRes));
  SavedRes := CopyPolyResult(Res);
  SavedEStol := eStol;
  SavedKosRes := KosRes;
  SavedHuberDiagnostics[sAcc] :=
    CopyHuberDiagnostic(HuberDiagnostics[sAcc]);
  SavedHuberDiagnostics[sMag] :=
    CopyHuberDiagnostic(HuberDiagnostics[sMag]);
  SavedVisirDiagnostics := VisirDiagnostics;
  SavedCorStolVisir := SetupData.CorStolVisir;
  SavedCorStolZenit := SetupData.CorStolZenit;
  SavedCorStolMagnit := SetupData.CorStolMagnit;

  Runner := TValidationRunner.Create;
  try
    AdapterObject := TInclinValidationAdapter.Create(
      SavedInput, SavedMNak, SavedTMin, SavedTMax);
    Adapter := AdapterObject;
    if Huber.Enabled then
      AdapterObject.UseHuberIRLS(Huber)
    else
      AdapterObject.UseOrdinaryLeastSquares;

    Result.FoldResults := Runner.Run(
      Result.Samples, Result.Folds, Result.Models, Adapter);
    Result.Summary := Runner.Summarize(Result.FoldResults, Result.Models);
  finally
    Runner.Free;

    InpData.pmA := SavedPmA;
    InpData.pmH := SavedPmH;
    InpData.MNak := SavedMNak;
    InpData.Tmin := SavedTMin;
    InpData.Tmax := SavedTMax;
    InpData.Inpt := SavedInput;
    acc := SavedAcc;
    mag := SavedMag;
    InclRes := SavedInclRes;
    Res := SavedRes;
    eStol := SavedEStol;
    KosRes := SavedKosRes;
    HuberDiagnostics[sAcc] := SavedHuberDiagnostics[sAcc];
    HuberDiagnostics[sMag] := SavedHuberDiagnostics[sMag];
    VisirDiagnostics := SavedVisirDiagnostics;
    SetupData.CorStolVisir := SavedCorStolVisir;
    SetupData.CorStolZenit := SavedCorStolZenit;
    SetupData.CorStolMagnit := SavedCorStolMagnit;
  end;

  TestResults := Result;
end;

class procedure TpolyMath.TestResultsToStrings(OutRes: TStrings);
const
  MetricNames: array[0..6] of string = (
    'Zenith, °',
    'Azimuth, °',
    'Azimuth spatial, °',
    'Direction, °',
    'Magnetic inclination, °',
    'Accelerometer norm, %',
    'Magnetometer norm, %'
  );

  function ValidationKindName(Kind: TValidationKind): string;
  begin
    case Kind of
      vkLeaveSeriesOut:
        Result := 'LOTO - leave temperature series out';
      vkLeaveTemperatureBandOut:
        Result := 'LTBO - leave temperature band out';
      vkLeaveOrientationGroupOut:
        Result := 'LOGO - leave orientation group out';
      vkLeaveTemperatureBandOrOrientationOut:
        Result := 'STRESS - temperature band OR orientation group out';
    else
      Result := 'Unknown validation kind';
    end;
  end;

  function MetricName(Index: Integer): string;
  begin
    if (Index >= Low(MetricNames)) and (Index <= High(MetricNames)) then
      Result := MetricNames[Index]
    else
      Result := Format('Metric %d', [Index + 1]);
  end;

  function FloatText(Value: Double): string;
  begin
    if IsNan(Value) then
      Result := 'n/a'
    else if IsInfinite(Value) then
      Result := 'infinity'
    else
      Result := FormatFloat('0.000000', Value);
  end;

  function TemperatureRange(Minimum, Maximum: Double): string;
  begin
    if (Minimum = MaxDouble) or (Maximum = -MaxDouble) or
       IsNan(Minimum) or IsNan(Maximum) then
      Result := 'n/a'
    else
      Result := Format('%.2f..%.2f C', [Minimum, Maximum]);
  end;

  function AcceptanceText(Accepted: Boolean): string;
  begin
    if Accepted then
      Result := 'ACCEPTED'
    else
      Result := 'REJECTED';
  end;

  procedure AddSeparator;
  begin
    OutRes.Add(StringOfChar('-', 112));
  end;

  procedure AddMetrics(const Title: string;
    const Metrics: TArray<TValidationMetric>);
  begin
    OutRes.Add(Title);
    OutRes.Add(Format('  %-26s %7s %12s %12s %12s %12s %12s %8s',
      ['Metric', 'N', 'MeanAbs', 'RMS', 'P95', 'MaxAbs', 'Peak', 'Row']));

    if Length(Metrics) = 0 then
    begin
      OutRes.Add('  n/a');
      Exit;
    end;

    for var I := 0 to High(Metrics) do
      if Metrics[I].Count = 0 then
        OutRes.Add(Format('  %-26s %7d %12s %12s %12s %12s %12s %8s',
          [MetricName(I), 0, 'n/a', 'n/a', 'n/a', 'n/a', 'n/a', 'n/a']))
      else
        OutRes.Add(Format('  %-26s %7d %12s %12s %12s %12s %12s %8d',
          [MetricName(I), Metrics[I].Count,
           FloatText(Metrics[I].MeanAbs), FloatText(Metrics[I].RMS),
           FloatText(Metrics[I].Percentile95),
           FloatText(Metrics[I].MaxAbs),
           FloatText(Metrics[I].PeakSigned),
           Metrics[I].PeakSourceIndex]));
  end;

  procedure AddAnalysis;
  begin
    OutRes.Add('FOLD BUILD ANALYSIS');
    AddSeparator;

    OutRes.Add('LOTO series');
    if Length(TestResults.LotoAnalysis) = 0 then
      OutRes.Add('  n/a')
    else
      for var LotoItem in TestResults.LotoAnalysis do
        OutRes.Add(Format(
          '  SetNo=%d  %s  test=%d  train=%d  train series=%d  '+
          'test T=%s  train T=%s  below=%d  above=%d  unknown excluded=%d  %s',
          [LotoItem.SetNo, AcceptanceText(LotoItem.Accepted),
           LotoItem.TestCount, LotoItem.TrainingCount,
           LotoItem.TrainingSeriesCount,
           TemperatureRange(LotoItem.TestTemperatureMin,
             LotoItem.TestTemperatureMax),
           TemperatureRange(LotoItem.TrainingTemperatureMin,
             LotoItem.TrainingTemperatureMax),
           LotoItem.TrainingCountBelow, LotoItem.TrainingCountAbove,
           LotoItem.UnknownSeriesExcludedCount, LotoItem.Reason]));

    OutRes.Add('');
    OutRes.Add('LTBO bands');
    if Length(TestResults.LtboAnalysis) = 0 then
      OutRes.Add('  n/a')
    else
      for var LtboItem in TestResults.LtboAnalysis do
        OutRes.Add(Format(
          '  [%.2f..%.2f) C  %s  test=%d  embargo=%d  '+
          'train below=%d  train above=%d  %s',
          [LtboItem.Candidate.BandLow, LtboItem.Candidate.BandHigh,
           AcceptanceText(LtboItem.Accepted),
           LtboItem.TestCount, LtboItem.EmbargoCount,
           LtboItem.TrainingCountBelow, LtboItem.TrainingCountAbove,
           LtboItem.Reason]));

    OutRes.Add('');
    OutRes.Add('LOGO spatial regions');
    if Length(TestResults.LogoAnalysis) = 0 then
      OutRes.Add('  n/a')
    else
      for var LogoItem in TestResults.LogoAnalysis do
        OutRes.Add(Format(
          '  %s  %s  test=%d  test series=%d  train=%d  '+
          'train groups=%d  test T=%s  ungrouped excluded=%d  %s',
          [LogoItem.GroupName,
           AcceptanceText(LogoItem.Accepted),
           LogoItem.TestCount, LogoItem.TestSeriesCount,
           LogoItem.TrainingCount, LogoItem.TrainingGroupCount,
           TemperatureRange(LogoItem.TestTemperatureMin,
             LogoItem.TestTemperatureMax),
           LogoItem.UngroupedExcludedCount, LogoItem.Reason]));

    OutRes.Add('');
    OutRes.Add('LOGO identifiability of A(T)v+b(T)');
    if Length(TestResults.LogoIdentifiability) = 0 then
      OutRes.Add('  n/a')
    else
      for var Check in TestResults.LogoIdentifiability do
      begin
        OutRes.Add(Format(
          '  %s  %s  rank G/H=%d/%d of %d  cond G/H=%.6g/%.6g  '+
          'rows/coef=%.2f  T levels=%d  test Z/A/V=%d/%d/%d  %s',
          [Check.FoldName, AcceptanceText(Check.Accepted),
           Check.AccRank, Check.MagRank, Check.RequiredRank,
           Check.AccCondition, Check.MagCondition,
           Check.RowsPerCoefficient, Check.TemperatureLevelCount,
           Check.TestZenithFamilyCount, Check.TestAzimuthBinCount,
           Check.TestToolfaceBinCount,
           Check.Reason]));
        OutRes.Add(Format(
          '    G range: X %.6g..%.6g (%.1f%%), Y %.6g..%.6g (%.1f%%), '+
          'Z %.6g..%.6g (%.1f%%)',
          [Check.RawMin[sAcc].X, Check.RawMax[sAcc].X,
           100 * Check.RangeRatio[sAcc].X,
           Check.RawMin[sAcc].Y, Check.RawMax[sAcc].Y,
           100 * Check.RangeRatio[sAcc].Y,
           Check.RawMin[sAcc].Z, Check.RawMax[sAcc].Z,
           100 * Check.RangeRatio[sAcc].Z]));
        OutRes.Add(Format(
          '    H range: X %.6g..%.6g (%.1f%%), Y %.6g..%.6g (%.1f%%), '+
          'Z %.6g..%.6g (%.1f%%)',
          [Check.RawMin[sMag].X, Check.RawMax[sMag].X,
           100 * Check.RangeRatio[sMag].X,
           Check.RawMin[sMag].Y, Check.RawMax[sMag].Y,
           100 * Check.RangeRatio[sMag].Y,
           Check.RawMin[sMag].Z, Check.RawMax[sMag].Z,
           100 * Check.RangeRatio[sMag].Z]));
      end;

    OutRes.Add('');
    OutRes.Add('STRESS union: temperature band OR orientation group');
    OutRes.Add('  test = band OR group; train = NOT band AND NOT group');
    if Length(TestResults.StressIdentifiability) = 0 then
      OutRes.Add('  n/a')
    else
      for var Check in TestResults.StressIdentifiability do
      begin
        OutRes.Add(Format(
          '  %s  %s  rank G/H=%d/%d of %d  cond G/H=%.6g/%.6g  '+
          'rows/coef=%.2f  T levels=%d  test Z/A/V=%d/%d/%d  %s',
          [Check.FoldName, AcceptanceText(Check.Accepted),
           Check.AccRank, Check.MagRank, Check.RequiredRank,
           Check.AccCondition, Check.MagCondition,
           Check.RowsPerCoefficient, Check.TemperatureLevelCount,
           Check.TestZenithFamilyCount, Check.TestAzimuthBinCount,
           Check.TestToolfaceBinCount, Check.Reason]));
        OutRes.Add(Format(
          '    G retained ranges: X %.1f%%, Y %.1f%%, Z %.1f%%;  '+
          'H retained ranges: X %.1f%%, Y %.1f%%, Z %.1f%%',
          [100 * Check.RangeRatio[sAcc].X,
           100 * Check.RangeRatio[sAcc].Y,
           100 * Check.RangeRatio[sAcc].Z,
           100 * Check.RangeRatio[sMag].X,
           100 * Check.RangeRatio[sMag].Y,
           100 * Check.RangeRatio[sMag].Z]));
      end;
  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI VALIDATION TEST RESULTS');
    OutRes.Add(Format('Samples: %d    Models: %d    Accepted folds: %d    '+
      'Fold results: %d',
      [Length(TestResults.Samples), Length(TestResults.Models),
       Length(TestResults.Folds), Length(TestResults.FoldResults)]));

    if Length(TestResults.Summary) = 0 then
    begin
      OutRes.Add('');
      OutRes.Add('No test results. Call TpolyMath.RunTests first.');
      Exit;
    end;

    OutRes.Add('');
    OutRes.Add('SUMMARY');
    AddSeparator;
    for var ModelSummary in TestResults.Summary do
    begin
      OutRes.Add(Format('Model %s', [ModelSummary.Model.Name]));
      for var KindSummary in ModelSummary.ByKind do
      begin
        OutRes.Add('');
        OutRes.Add(ValidationKindName(KindSummary.Kind));
        AddMetrics('All test rows', KindSummary.Metrics);
        AddMetrics('Interpolation rows', KindSummary.InterpolationMetrics);
        AddMetrics('Extrapolation rows', KindSummary.ExtrapolationMetrics);
      end;
      OutRes.Add('');
      AddSeparator;
    end;

    OutRes.Add('');
    OutRes.Add('FOLD DETAILS');
    AddSeparator;
    for var FoldResult in TestResults.FoldResults do
    begin
      OutRes.Add(Format('%s    Model %s',
        [FoldResult.FoldName, FoldResult.Model.Name]));
      OutRes.Add(Format(
        '  %s  train=%d, test=%d (interpolation=%d, extrapolation=%d)',
        [ValidationKindName(FoldResult.Kind), FoldResult.TrainingCount,
         FoldResult.TestCount, FoldResult.InterpolationTestCount,
         FoldResult.ExtrapolationTestCount]));
      OutRes.Add(Format('  Temperature: train %s; test %s',
        [TemperatureRange(FoldResult.TrainingTemperatureMin,
           FoldResult.TrainingTemperatureMax),
         TemperatureRange(FoldResult.TestTemperatureMin,
           FoldResult.TestTemperatureMax)]));
      AddMetrics('All test rows', FoldResult.Metrics);
      AddMetrics('Interpolation rows', FoldResult.InterpolationMetrics);
      AddMetrics('Extrapolation rows', FoldResult.ExtrapolationMetrics);
      OutRes.Add('');
    end;

    AddAnalysis;
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.SummaryTestResultsToStrings(OutRes: TStrings);
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith',
    'Magnetic inclination',
    'Azimuth (Z > 5°)',
    'Accelerometer norm',
    'Magnetometer norm'
  );
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string = (
    '°', '°', '°', '%', '%'
  );
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double = (
    0.15, 0.20, 1.00, 0.30, 0.50
  );

  function SameModel(const A, B: TTemperatureModel): Boolean;
  begin
    Result := (A.AxDegree = B.AxDegree) and
              (A.KuDegree = B.KuDegree) and
              (A.DzDegree = B.DzDegree);
  end;

  function ShortKindName(Kind: TValidationKind): string;
  begin
    case Kind of
      vkLeaveSeriesOut:
        Result := 'LOTO - leave temperature series out';
      vkLeaveTemperatureBandOut:
        Result := 'LTBO - leave temperature band out';
      vkLeaveOrientationGroupOut:
        Result := 'LOGO - leave orientation group out';
      vkLeaveTemperatureBandOrOrientationOut:
        Result := 'STRESS - temperature band OR orientation group out';
    else
      Result := 'Unknown validation kind';
    end;
  end;

  function FoldCount(const Model: TTemperatureModel;
    Kind: TValidationKind): Integer;
  begin
    Result := 0;
    for var FoldResult in TestResults.FoldResults do
      if SameModel(FoldResult.Model, Model) and (FoldResult.Kind = Kind) then
        Inc(Result);
  end;

  function WorstFoldStatistic(const Model: TTemperatureModel;
    Kind: TValidationKind; MetricIndex, StatisticIndex: Integer;
    out WorstValue: Double; out WorstText: string): Boolean;
  var
    Value: Double;
    WorstName: string;
    WorstRow: Integer;
  begin
    Result := False;
    WorstValue := 0;
    WorstText := 'n/a';
    WorstName := '';
    WorstRow := -1;

    for var FoldResult in TestResults.FoldResults do
      if SameModel(FoldResult.Model, Model) and
         (FoldResult.Kind = Kind) and
         (MetricIndex >= 0) and
         (MetricIndex < Length(FoldResult.Metrics)) and
         (FoldResult.Metrics[MetricIndex].Count > 0) then
      begin
        case StatisticIndex of
          0: Value := FoldResult.Metrics[MetricIndex].MeanAbs;
          1: Value := FoldResult.Metrics[MetricIndex].Percentile95;
          2: Value := FoldResult.Metrics[MetricIndex].MaxAbs;
        else
          Value := 0;
        end;

        if (not Result) or (Value > WorstValue) then
        begin
          Result := True;
          WorstValue := Value;
          WorstName := FoldResult.FoldName;
          if StatisticIndex = 2 then
            WorstRow := FoldResult.Metrics[MetricIndex].PeakSourceIndex
          else
            WorstRow := -1;
        end;
      end;

    if Result then
      if WorstRow >= 0 then
        WorstText := Format('%s, row %d', [WorstName, WorstRow])
      else
        WorstText := WorstName;
  end;

  function PassFail(Value, Limit: Double): string;
  begin
    if Value <= Limit then
      Result := 'PASS'
    else
      Result := 'FAIL';
  end;

  function StatusText(Failed, Complete, HasData: Boolean): string;
  begin
    if not HasData then
      Result := 'NO DATA'
    else if Failed then
      Result := 'FAIL'
    else if not Complete then
      Result := 'INCOMPLETE'
    else
      Result := 'PASS';
  end;

var
  AnyModelData: Boolean;
  AllModelsComplete: Boolean;
  AnyModelFailed: Boolean;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI VALIDATION - ACCEPTANCE SUMMARY');
    OutRes.Add(StringOfChar('=', 132));
    OutRes.Add('Shown values: worst MeanAbs, P95 and MaxAbs among individual folds.');
    OutRes.Add('Overall acceptance criterion: MaxAbs <= limit for every test row.');
    OutRes.Add('Azimuth is evaluated only where it is physically defined '+
      '(the adapter excludes the vertical region).');
    OutRes.Add(Format('Samples: %d    Models: %d    Accepted folds: %d',
      [Length(TestResults.Samples), Length(TestResults.Models),
       Length(TestResults.Folds)]));

    if Length(TestResults.Summary) = 0 then
    begin
      OutRes.Add('');
      OutRes.Add('NO DATA - call TpolyMath.RunTests first.');
      Exit;
    end;

    AnyModelData := False;
    AllModelsComplete := True;
    AnyModelFailed := False;

    for var ModelSummary in TestResults.Summary do
    begin
      var ModelHasData := False;
      var ModelComplete := True;
      var ModelFailed := False;

      OutRes.Add('');
      OutRes.Add(Format('MODEL %s', [ModelSummary.Model.Name]));
      OutRes.Add(StringOfChar('-', 132));

      for var KindSummary in ModelSummary.ByKind do
      begin
        var KindFoldCount := FoldCount(ModelSummary.Model, KindSummary.Kind);
        var KindHasData := False;
        var KindComplete := KindFoldCount > 0;
        var KindFailed := False;

        OutRes.Add(Format('%s    folds: %d',
          [ShortKindName(KindSummary.Kind), KindFoldCount]));
        OutRes.Add(Format('  %-25s %7s %19s %19s %19s %12s',
          ['Parameter', 'N', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));
        OutRes.Add(Format('  %-25s %7s %19s %19s %19s %12s',
          ['', '', 'value/result', 'value/result', 'value/result', '']));

        for var ControlledIndex := 0 to ControlledMetricCount - 1 do
        begin
          var MetricIndex := ControlledMetricIndex[ControlledIndex];
          if (KindFoldCount = 0) or
             (MetricIndex >= Length(KindSummary.Metrics)) or
             (KindSummary.Metrics[MetricIndex].Count = 0) then
          begin
            KindComplete := False;
            OutRes.Add(Format('  %-25s %7s %19s %19s %19s %8.3f %-3s',
              [ControlledMetricName[ControlledIndex], '0', 'n/a', 'n/a',
               'n/a', ControlledMetricLimit[ControlledIndex],
               ControlledMetricUnit[ControlledIndex]]));
            Continue;
          end;

          var WorstMeanAbs, WorstP95, WorstMaxAbs: Double;
          var WorstMeanAbsText, WorstP95Text, WorstMaxAbsText: string;
          var HasMeanAbs := WorstFoldStatistic(ModelSummary.Model,
            KindSummary.Kind, MetricIndex, 0, WorstMeanAbs,
            WorstMeanAbsText);
          var HasP95 := WorstFoldStatistic(ModelSummary.Model,
            KindSummary.Kind, MetricIndex, 1, WorstP95, WorstP95Text);
          var HasMaxAbs := WorstFoldStatistic(ModelSummary.Model,
            KindSummary.Kind, MetricIndex, 2, WorstMaxAbs,
            WorstMaxAbsText);

          if not (HasMeanAbs and HasP95 and HasMaxAbs) then
          begin
            KindComplete := False;
            OutRes.Add(Format('  %-25s %7s %19s %19s %19s %8.3f %-3s',
              [ControlledMetricName[ControlledIndex], '0', 'n/a', 'n/a',
               'n/a', ControlledMetricLimit[ControlledIndex],
               ControlledMetricUnit[ControlledIndex]]));
            Continue;
          end;

          KindHasData := True;
          var MetricFailed :=
            WorstMaxAbs > ControlledMetricLimit[ControlledIndex];
          if MetricFailed then
            KindFailed := True;

          OutRes.Add(Format(
            '  %-25s %7d %8.3f %-3s %-6s %8.3f %-3s %-6s '+
            '%8.3f %-3s %-6s %8.3f %-3s',
            [ControlledMetricName[ControlledIndex],
             KindSummary.Metrics[MetricIndex].Count,
             WorstMeanAbs, ControlledMetricUnit[ControlledIndex],
             PassFail(WorstMeanAbs, ControlledMetricLimit[ControlledIndex]),
             WorstP95, ControlledMetricUnit[ControlledIndex],
             PassFail(WorstP95, ControlledMetricLimit[ControlledIndex]),
             WorstMaxAbs, ControlledMetricUnit[ControlledIndex],
             PassFail(WorstMaxAbs, ControlledMetricLimit[ControlledIndex]),
             ControlledMetricLimit[ControlledIndex],
             ControlledMetricUnit[ControlledIndex]]));
          OutRes.Add(Format('    worst MeanAbs: %s', [WorstMeanAbsText]));
          OutRes.Add(Format('    worst P95:     %s', [WorstP95Text]));
          OutRes.Add(Format('    worst MaxAbs:  %s', [WorstMaxAbsText]));
        end;

        OutRes.Add(Format('  %-25s %s', ['TEST RESULT:',
          StatusText(KindFailed, KindComplete, KindHasData)]));
        OutRes.Add('');

        if KindHasData then
          ModelHasData := True;
        if not KindComplete then
          ModelComplete := False;
        if KindFailed then
          ModelFailed := True;
      end;

      OutRes.Add(Format('MODEL RESULT: %s',
        [StatusText(ModelFailed, ModelComplete, ModelHasData)]));
      OutRes.Add(StringOfChar('=', 132));

      if ModelHasData then
        AnyModelData := True;
      if not ModelComplete then
        AllModelsComplete := False;
      if ModelFailed then
        AnyModelFailed := True;
    end;

    OutRes.Add('');
    OutRes.Add(Format('OVERALL RESULT: %s',
      [StatusText(AnyModelFailed, AllModelsComplete, AnyModelData)]));
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.SummaryModelTestResultsToStrings(
  OutRes: TStrings);
const
  ControlledMetricCount = 5;
  ExpectedKindCount = 4;
  ExpectedCheckCount = ControlledMetricCount * ExpectedKindCount;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith',
    'Magnetic inclination',
    'Azimuth (Z > 5°)',
    'Accelerometer norm',
    'Magnetometer norm'
  );
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string = (
    '°', '°', '°', '%', '%'
  );
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double = (
    0.15, 0.20, 1.00, 0.30, 0.50
  );
type
  TModelScore = record
    Model: TTemperatureModel;
    EvaluatedCount: Integer;
    MeanAbsPassCount: Integer;
    P95PassCount: Integer;
    MaxAbsPassCount: Integer;
    NormalizedErrorSum: Double;
    Complete: Boolean;
  end;

  function SameModel(const A, B: TTemperatureModel): Boolean;
  begin
    Result := (A.AxDegree = B.AxDegree) and
              (A.KuDegree = B.KuDegree) and
              (A.DzDegree = B.DzDegree);
  end;

  function KindName(Kind: TValidationKind): string;
  begin
    case Kind of
      vkLeaveSeriesOut: Result := 'LOTO';
      vkLeaveTemperatureBandOut: Result := 'LTBO';
      vkLeaveOrientationGroupOut: Result := 'LOGO';
      vkLeaveTemperatureBandOrOrientationOut: Result := 'STRESS';
    else
      Result := 'UNKNOWN';
    end;
  end;

  function WorstFoldValues(const Model: TTemperatureModel;
    Kind: TValidationKind; MetricIndex: Integer;
    out MeanAbs, P95, MaxAbs: Double): Boolean;
  begin
    Result := False;
    MeanAbs := 0;
    P95 := 0;
    MaxAbs := 0;

    for var FoldResult in TestResults.FoldResults do
      if SameModel(FoldResult.Model, Model) and
         (FoldResult.Kind = Kind) and
         (MetricIndex >= 0) and
         (MetricIndex < Length(FoldResult.Metrics)) and
         (FoldResult.Metrics[MetricIndex].Count > 0) then
      begin
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].MeanAbs > MeanAbs) then
          MeanAbs := FoldResult.Metrics[MetricIndex].MeanAbs;
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].Percentile95 > P95) then
          P95 := FoldResult.Metrics[MetricIndex].Percentile95;
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].MaxAbs > MaxAbs) then
          MaxAbs := FoldResult.Metrics[MetricIndex].MaxAbs;
        Result := True;
      end;
  end;

  function BuildScore(const ModelSummary: TValidationSummary): TModelScore;
  begin
    Result.Model := ModelSummary.Model;
    Result.EvaluatedCount := 0;
    Result.MeanAbsPassCount := 0;
    Result.P95PassCount := 0;
    Result.MaxAbsPassCount := 0;
    Result.NormalizedErrorSum := 0;

    for var KindSummary in ModelSummary.ByKind do
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MeanAbs, P95, MaxAbs: Double;
        if not WorstFoldValues(ModelSummary.Model, KindSummary.Kind,
          ControlledMetricIndex[ControlledIndex], MeanAbs, P95, MaxAbs) then
          Continue;

        Inc(Result.EvaluatedCount);
        if MeanAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.MeanAbsPassCount);
        if P95 <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.P95PassCount);
        if MaxAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.MaxAbsPassCount);

        Result.NormalizedErrorSum := Result.NormalizedErrorSum +
          MeanAbs / ControlledMetricLimit[ControlledIndex] +
          P95 / ControlledMetricLimit[ControlledIndex] +
          MaxAbs / ControlledMetricLimit[ControlledIndex];
      end;

    Result.Complete := Result.EvaluatedCount = ExpectedCheckCount;
  end;

  function NormalizedError(const Score: TModelScore): Double;
  begin
    if Score.EvaluatedCount = 0 then
      Result := Infinity
    else
      Result := Score.NormalizedErrorSum / (3 * Score.EvaluatedCount);
  end;

  function IsBetter(const A, B: TModelScore): Boolean;
  begin
    if A.Complete <> B.Complete then
      Exit(A.Complete);
    if A.MeanAbsPassCount <> B.MeanAbsPassCount then
      Exit(A.MeanAbsPassCount > B.MeanAbsPassCount);
    if A.P95PassCount <> B.P95PassCount then
      Exit(A.P95PassCount > B.P95PassCount);
    if A.MaxAbsPassCount <> B.MaxAbsPassCount then
      Exit(A.MaxAbsPassCount > B.MaxAbsPassCount);
    if not SameValue(NormalizedError(A), NormalizedError(B), 1E-12) then
      Exit(NormalizedError(A) < NormalizedError(B));
    Result := CompareText(A.Model.Name, B.Model.Name) < 0;
  end;

  function PassCountText(PassCount, CheckCount: Integer): string;
  begin
    Result := Format('%d/%d', [PassCount, CheckCount]);
  end;

  function DecisionText(const Score: TModelScore; IsBest: Boolean): string;
  begin
    if Score.EvaluatedCount = 0 then
      Result := 'NO DATA'
    else if not Score.Complete then
      Result := 'INCOMPLETE'
    else if IsBest then
      Result := 'BEST'
    else
      Result := '';
  end;

var
  Scores: TArray<TModelScore>;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI VALIDATION - BEST MODEL SELECTION');
    OutRes.Add(StringOfChar('=', 104));
    OutRes.Add('Ranking: MeanAbs PASS, then P95 PASS, then MaxAbs PASS; '+
      'tie-breaker: lowest normalized error.');
    OutRes.Add(Format('Checks per complete model: %d '+
      '(%d test kinds x %d parameters).',
      [ExpectedCheckCount, ExpectedKindCount, ControlledMetricCount]));

    if Length(TestResults.Summary) = 0 then
    begin
      OutRes.Add('');
      OutRes.Add('NO DATA - call TpolyMath.RunTests first.');
      Exit;
    end;

    SetLength(Scores, Length(TestResults.Summary));
    for var I := 0 to High(TestResults.Summary) do
      Scores[I] := BuildScore(TestResults.Summary[I]);

    for var I := 1 to High(Scores) do
    begin
      var Current := Scores[I];
      var J := I - 1;
      while (J >= 0) and IsBetter(Current, Scores[J]) do
      begin
        Scores[J + 1] := Scores[J];
        Dec(J);
      end;
      Scores[J + 1] := Current;
    end;

    OutRes.Add('');
    OutRes.Add('MODEL RANKING');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add(Format('%-5s %-12s %-11s %-13s %-13s %-13s %-13s %-12s',
      ['Rank', 'Model', 'Coverage', 'MeanAbs PASS', 'P95 PASS',
       'MaxAbs PASS', 'Error index', 'Decision']));

    for var I := 0 to High(Scores) do
      OutRes.Add(Format('%-5d %-12s %-11s %-13s %-13s %-13s %-13.3f %-12s',
        [I + 1, Scores[I].Model.Name,
         PassCountText(Scores[I].EvaluatedCount, ExpectedCheckCount),
         PassCountText(Scores[I].MeanAbsPassCount,
           Scores[I].EvaluatedCount),
         PassCountText(Scores[I].P95PassCount, Scores[I].EvaluatedCount),
         PassCountText(Scores[I].MaxAbsPassCount,
           Scores[I].EvaluatedCount),
         NormalizedError(Scores[I]), DecisionText(Scores[I], I = 0)]));

    if Scores[0].EvaluatedCount = 0 then
    begin
      OutRes.Add('');
      OutRes.Add('BEST MODEL: n/a - no evaluated metrics.');
      Exit;
    end;

    OutRes.Add('');
    if Scores[0].Complete then
      OutRes.Add(Format('BEST MODEL: %s', [Scores[0].Model.Name]))
    else
      OutRes.Add(Format('PRELIMINARY BEST MODEL: %s (incomplete data)',
        [Scores[0].Model.Name]));
    OutRes.Add(Format('Reason: MeanAbs %s, P95 %s, MaxAbs %s; '+
      'normalized error index %.3f.',
      [PassCountText(Scores[0].MeanAbsPassCount,
         Scores[0].EvaluatedCount),
       PassCountText(Scores[0].P95PassCount, Scores[0].EvaluatedCount),
       PassCountText(Scores[0].MaxAbsPassCount,
         Scores[0].EvaluatedCount), NormalizedError(Scores[0])]));

    OutRes.Add('');
    OutRes.Add('BEST MODEL BY TEST KIND');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add(Format('%-10s %-13s %-13s %-13s %-12s',
      ['Test', 'MeanAbs PASS', 'P95 PASS', 'MaxAbs PASS', 'Checks']));
    for var Kind := Low(TValidationKind) to High(TValidationKind) do
    begin
      var MeanPass := 0;
      var P95Pass := 0;
      var MaxPass := 0;
      var CheckCount := 0;
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MeanAbs, P95, MaxAbs: Double;
        if not WorstFoldValues(Scores[0].Model, Kind,
          ControlledMetricIndex[ControlledIndex], MeanAbs, P95, MaxAbs) then
          Continue;
        Inc(CheckCount);
        if MeanAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(MeanPass);
        if P95 <= ControlledMetricLimit[ControlledIndex] then
          Inc(P95Pass);
        if MaxAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(MaxPass);
      end;
      OutRes.Add(Format('%-10s %-13s %-13s %-13s %-12s',
        [KindName(Kind), PassCountText(MeanPass, CheckCount),
         PassCountText(P95Pass, CheckCount),
         PassCountText(MaxPass, CheckCount),
         PassCountText(CheckCount, ControlledMetricCount)]));
    end;

    OutRes.Add('');
    OutRes.Add('MEANABS LIMIT EXCEEDANCES OF BEST MODEL');
    OutRes.Add(StringOfChar('-', 104));
    var FailureCount := 0;
    for var ModelSummary in TestResults.Summary do
      if SameModel(ModelSummary.Model, Scores[0].Model) then
        for var KindSummary in ModelSummary.ByKind do
          for var ControlledIndex := 0 to ControlledMetricCount - 1 do
          begin
            var MeanAbs, P95, MaxAbs: Double;
            if WorstFoldValues(Scores[0].Model, KindSummary.Kind,
              ControlledMetricIndex[ControlledIndex], MeanAbs, P95,
              MaxAbs) and
               (MeanAbs > ControlledMetricLimit[ControlledIndex]) then
            begin
              Inc(FailureCount);
              OutRes.Add(Format('  %-8s %-25s %8.3f %-3s > %8.3f %-3s',
                [KindName(KindSummary.Kind),
                 ControlledMetricName[ControlledIndex], MeanAbs,
                 ControlledMetricUnit[ControlledIndex],
                 ControlledMetricLimit[ControlledIndex],
                 ControlledMetricUnit[ControlledIndex]]));
            end;
          end;
    if FailureCount = 0 then
      OutRes.Add('  none');
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.BuildMaxMinSphereIndices(
  const Inputs: TArray<TinclInput>;
  out MaxMinIndices, SphereIndices: TArray<Integer>);
var
  MaxMin, Sphere: TList<Integer>;
  Name: string;
begin
  if Length(Inputs) = 0 then
    raise EArgumentException.Create('Inputs is empty');

  MaxMin := TList<Integer>.Create;
  Sphere := TList<Integer>.Create;
  try
    for var I := 0 to High(Inputs) do
    begin
      Name := Trim(Inputs[I].Info);
      if Name.Contains('сфера', True) then
        Sphere.Add(I)
      else if Name.Contains('=max', True) or Name.Contains('=min', True) then
        MaxMin.Add(I);
    end;
    MaxMinIndices := MaxMin.ToArray;
    SphereIndices := Sphere.ToArray;
  finally
    Sphere.Free;
    MaxMin.Free;
  end;

  if Length(MaxMinIndices) = 0 then
    raise EInvalidOpException.Create(
      'No G/H max/min rows were found in TinclInput.Info');
  if Length(SphereIndices) = 0 then
    raise EInvalidOpException.Create(
      'No Sphere rows were found in TinclInput.Info');
end;

class function TpolyMath.TestMaxMinOnSphere(
  const MaxMinIndices, SphereIndices: TArray<Integer>;
  const Huber: THuberIrlsOptions; OutRes: TStrings):
  TMaxMinSphereTestResult;
const
  ControlledMetricCount = 5;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith',
    'Magnetic inclination',
    'Azimuth (Z > 5°)',
    'Accelerometer norm',
    'Magnetometer norm'
  );
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string = (
    '°', '°', '°', '%', '%'
  );
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double = (
    0.15, 0.20, 1.00, 0.30, 0.50
  );
var
  Samples: TArray<TValidationSample>;
  Fold, AllFold: TValidationFold;
  Folds, ComparisonFolds: TArray<TValidationFold>;
  AllTrainingIndices: TArray<Integer>;
  ComparisonHuber: THuberIrlsOptions;
  Models: TArray<TTemperatureModel>;
  FoldResults: TArray<TValidationFoldResult>;
  Model: PolyModel;
  Options: TLogoSpatialOptions;
  Runner: TValidationRunner;
  AdapterObject: TInclinValidationAdapter;
  Adapter: IValidationModelAdapter;

  SavedPmA, SavedPmH: PolyModel;
  SavedMNak, SavedTMin, SavedTMax: Double;
  SavedInput: TArray<TinclInput>;
  SavedAcc, SavedMag: TArray<RowModel>;
  SavedInclRes: TArray<TInclRes>;
  SavedRes: TPolyRes;
  SavedEStol: TStolError;
  SavedKosRes: TFindLMKosStol;
  SavedHuberDiagnostics: TSensorData<THuberIrlsDiagnostics>;
  SavedVisirDiagnostics: TVisirCorrectionDiagnostics;
  SavedTestResults: TValidationTestRun;
  SavedCorStolVisir, SavedCorStolZenit, SavedCorStolMagnit: Boolean;

  function YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  function PassFail(Value, Limit: Double): string;
  begin
    if Value <= Limit then
      Result := 'PASS'
    else
      Result := 'FAIL';
  end;

  function BuildOverlappingFold(const ATrainingIndices,
    ATestIndices: TArray<Integer>; const AName: string): TValidationFold;
  begin
    { This is deliberately not BuildExplicitFold: the final verification
      evaluates all calibration rows, including rows used for fitting. }
    Result := Default(TValidationFold);
    Result.Kind := vkLeaveOrientationGroupOut;
    Result.Name := AName;
    Result.TrainingIndices := Copy(ATrainingIndices, 0,
      Length(ATrainingIndices));
    Result.TestIndices := Copy(ATestIndices, 0, Length(ATestIndices));
    Result.TestTemperatureMin := MaxDouble;
    Result.TestTemperatureMax := -MaxDouble;
    for var SourceIndex in ATestIndices do
    begin
      Result.TestTemperatureMin := Min(Result.TestTemperatureMin,
        Samples[SourceIndex].Temperature);
      Result.TestTemperatureMax := Max(Result.TestTemperatureMax,
        Samples[SourceIndex].Temperature);
    end;
  end;

  function MetricDelta(const A, B: TValidationMetric): Double;
  begin
    if A.Count <> B.Count then
      Exit(MaxDouble);
    if A.Count = 0 then
      Exit(0.0);
    Result := Max(Abs(A.MeanSigned - B.MeanSigned),
      Max(Abs(A.MeanAbs - B.MeanAbs),
      Max(Abs(A.RMS - B.RMS),
      Max(Abs(A.Percentile95 - B.Percentile95),
          Abs(A.MaxAbs - B.MaxAbs)))));
  end;

  function FilterMetricBySetNo(const Source: TValidationMetric;
    SetNo: Integer): TValidationMetric;
  var
    Values: TArray<Double>;
    A: Double;
    N, P95Index: Integer;
  begin
    Result := Default(TValidationMetric);
    for var ErrorPoint in Source.ErrorPoints do
      if (ErrorPoint.SourceIndex >= 0) and
         (ErrorPoint.SourceIndex < Length(SavedInput)) and
         (SavedInput[ErrorPoint.SourceIndex].SetNo = SetNo) then
      begin
        A := Abs(ErrorPoint.SignedError);
        if (Result.Count = 0) or (A > Result.MaxAbs) then
        begin
          Result.MaxAbs := A;
          Result.PeakSigned := ErrorPoint.SignedError;
          Result.PeakSourceIndex := ErrorPoint.SourceIndex;
        end;
        Result.SignedSum := Result.SignedSum + ErrorPoint.SignedError;
        Result.AbsSum := Result.AbsSum + A;
        Result.SquareSum := Result.SquareSum +
          Sqr(ErrorPoint.SignedError);
        N := Length(Values);
        SetLength(Values, N + 1);
        Values[N] := A;
        Inc(Result.Count);
      end;

    if Result.Count = 0 then
    begin
      Result.MeanSigned := NaN;
      Result.MeanAbs := NaN;
      Result.RMS := NaN;
      Result.Percentile95 := NaN;
      Exit;
    end;
    Result.MeanSigned := Result.SignedSum / Result.Count;
    Result.MeanAbs := Result.AbsSum / Result.Count;
    Result.RMS := Sqrt(Result.SquareSum / Result.Count);
    TArray.Sort<Double>(Values);
    P95Index := EnsureRange(Ceil(0.95 * Length(Values)) - 1,
      0, High(Values));
    Result.Percentile95 := Values[P95Index];
  end;

  function MakePointDiagnostic(AMetricIndex: Integer;
    const AMetricName: string; ASourceIndex: Integer; ASignedError,
    ALimit: Double): TMaxMinSpherePointDiagnostic;
  var
    Input: TinclInput;
  begin
    Result := Default(TMaxMinSpherePointDiagnostic);
    Result.MetricIndex := AMetricIndex;
    Result.MetricName := AMetricName;
    Result.SourceIndex := ASourceIndex;
    Result.SignedError := ASignedError;
    Result.AbsError := Abs(ASignedError);
    Result.Limit := ALimit;
    Result.ExpectedNorm := NaN;
    Result.CalculatedNorm := NaN;

    if (ASourceIndex < 0) or (ASourceIndex >= Length(SavedInput)) then
      Exit;
    Input := SavedInput[ASourceIndex];
    Result.Info := Input.Info;
    Result.SetNo := Input.SetNo;
    Result.Step := Input.Step;
    Result.Temperature := Input.T;
    Result.EtalonAzi := Input.Azi;
    Result.EtalonZen := Input.Zen;
    Result.EtalonVis := Input.Vis;
    Result.EtalonMag := Input.EtalonMag;
    Result.G := Input.G;
    Result.H := Input.H;

    case AMetricIndex of
      5: Result.ExpectedNorm := RES_AMP;
      6: Result.ExpectedNorm := RES_AMP * Input.EtalonMag / 1000.0;
    end;
    if not IsNan(Result.ExpectedNorm) then
      Result.CalculatedNorm := Result.ExpectedNorm *
        (1.0 + ASignedError / 100.0);
  end;

  procedure CollectPointDiagnostics;
  var
    Exceedances: TList<TMaxMinSpherePointDiagnostic>;
    Diagnostic, SwapDiagnostic: TMaxMinSpherePointDiagnostic;
    Metric: TValidationMetric;
  begin
    SetLength(Result.WorstPoints, ControlledMetricCount);
    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var MetricIndex := ControlledMetricIndex[ControlledIndex];
      if (MetricIndex >= Length(Result.FoldResult.Metrics)) or
         (Result.FoldResult.Metrics[MetricIndex].Count = 0) then
        Continue;
      Metric := Result.FoldResult.Metrics[MetricIndex];
      Result.WorstPoints[ControlledIndex] := MakePointDiagnostic(
        MetricIndex, ControlledMetricName[ControlledIndex],
        Metric.PeakSourceIndex, Metric.PeakSigned,
        ControlledMetricLimit[ControlledIndex]);
    end;

    Exceedances := TList<TMaxMinSpherePointDiagnostic>.Create;
    try
      if 6 < Length(Result.FoldResult.Metrics) then
      begin
        Metric := Result.FoldResult.Metrics[6];
        for var ErrorPoint in Metric.ErrorPoints do
          if Abs(ErrorPoint.SignedError) > 0.50 then
          begin
            Diagnostic := MakePointDiagnostic(6, 'Magnetometer norm',
              ErrorPoint.SourceIndex, ErrorPoint.SignedError, 0.50);
            Exceedances.Add(Diagnostic);
          end;
      end;
      Result.MagnetNormExceedances := Exceedances.ToArray;
    finally
      Exceedances.Free;
    end;

    { Keep the most severe rows first, which makes the report immediately
      useful even when many points cross the strict limit. }
    for var I := 0 to High(Result.MagnetNormExceedances) - 1 do
      for var J := I + 1 to High(Result.MagnetNormExceedances) do
        if Result.MagnetNormExceedances[J].AbsError >
           Result.MagnetNormExceedances[I].AbsError then
        begin
          SwapDiagnostic := Result.MagnetNormExceedances[I];
          Result.MagnetNormExceedances[I] :=
            Result.MagnetNormExceedances[J];
          Result.MagnetNormExceedances[J] := SwapDiagnostic;
        end;
  end;

  function MagneticHuberWeightText(ASourceIndex: Integer;
    const Diagnostics: THuberIrlsDiagnostics): string;
  begin
    Result := 'test-only';
    for var I := 0 to High(MaxMinIndices) do
      if MaxMinIndices[I] = ASourceIndex then
      begin
        if (I < Length(Diagnostics.PointWeights)) then
          Result := Format('%.6g',
            [Diagnostics.PointWeights[I]])
        else
          Result := 'n/a';
        Exit;
      end;
  end;

  function AcquisitionGroup(ASourceIndex: Integer): string;
  begin
    if (ASourceIndex < 0) or (ASourceIndex >= Length(SavedInput)) then
      Exit('UNKNOWN');
    if SavedInput[ASourceIndex].Info.Contains('сфера', True) then
      Result := 'SPHERE'
    else if SavedInput[ASourceIndex].Info.Contains('=max', True) or
            SavedInput[ASourceIndex].Info.Contains('=min', True) then
      Result := 'MAX/MIN'
    else
      Result := 'OTHER';
  end;

  procedure AddMagneticWorstSeries(AMetricIndex: Integer;
    const AMetricName, AUnit: string; ALimit: Double);
  var
    Metric: TValidationMetric;
    SeriesPoints: TArray<TValidationErrorPoint>;
    OrientationPoints: TArray<TValidationErrorPoint>;
    PeakInput, Input: TinclInput;
    N, ExceedCount, OrientationExceedCount, PrintCount: Integer;
    Swap: TValidationErrorPoint;
    Diagnosis: string;
  begin
    if (AMetricIndex < 0) or
       (AMetricIndex >= Length(Result.FoldResult.Metrics)) then
      Exit;
    Metric := Result.FoldResult.Metrics[AMetricIndex];
    if (Metric.Count = 0) or (Metric.PeakSourceIndex < 0) or
       (Metric.PeakSourceIndex >= Length(SavedInput)) then
      Exit;

    PeakInput := SavedInput[Metric.PeakSourceIndex];
    OutRes.Add(Format('%s: source=%d; step=%d; SetNo=%d; group=%s',
      [AMetricName, Metric.PeakSourceIndex, PeakInput.Step,
       PeakInput.SetNo, AcquisitionGroup(Metric.PeakSourceIndex)]));
    OutRes.Add(Format('  signed=%.6f %s; abs=%.6f %s; limit=%.6f %s; '+
      'HuberH=%s',
      [Metric.PeakSigned, AUnit, Metric.MaxAbs, AUnit, ALimit, AUnit,
       MagneticHuberWeightText(Metric.PeakSourceIndex,
         Result.Diagnostics[sMag])]));
    OutRes.Add(Format('  T=%.3f; A=%.3f°; Z=%.3f°; V=%.3f°; '+
      'EtalonMag=%.10g',
      [PeakInput.T, PeakInput.Azi, PeakInput.Zen, PeakInput.Vis,
       PeakInput.EtalonMag]));
    OutRes.Add(Format('  raw H=(%.12g, %.12g, %.12g); Info="%s"',
      [PeakInput.H.X, PeakInput.H.Y, PeakInput.H.Z, PeakInput.Info]));
    if AMetricIndex = 6 then
    begin
      var ExpectedNorm := RES_AMP * PeakInput.EtalonMag / 1000.0;
      var CalculatedNorm := ExpectedNorm *
        (1.0 + Metric.PeakSigned / 100.0);
      OutRes.Add(Format('  expected norm=%.12g; calculated norm=%.12g',
        [ExpectedNorm, CalculatedNorm]));
    end;

    SetLength(SeriesPoints, 0);
    ExceedCount := 0;
    for var ErrorPoint in Metric.ErrorPoints do
      if (ErrorPoint.SourceIndex >= 0) and
         (ErrorPoint.SourceIndex < Length(SavedInput)) and
         (SavedInput[ErrorPoint.SourceIndex].SetNo = PeakInput.SetNo) then
      begin
        N := Length(SeriesPoints);
        SetLength(SeriesPoints, N + 1);
        SeriesPoints[N] := ErrorPoint;
        if Abs(ErrorPoint.SignedError) > ALimit then
          Inc(ExceedCount);
      end;

    for var I := 0 to High(SeriesPoints) - 1 do
      for var J := I + 1 to High(SeriesPoints) do
        if Abs(SeriesPoints[J].SignedError) >
           Abs(SeriesPoints[I].SignedError) then
        begin
          Swap := SeriesPoints[I];
          SeriesPoints[I] := SeriesPoints[J];
          SeriesPoints[J] := Swap;
        end;

    if ExceedCount <= 1 then
      Diagnosis := 'ISOLATED OUTLIER CANDIDATE'
    else
      Diagnosis := 'SERIES/SYSTEMATIC EFFECT';
    OutRes.Add(Format('  same SetNo: rows=%d; above limit=%d; diagnosis=%s',
      [Length(SeriesPoints), ExceedCount, Diagnosis]));
    OutRes.Add('  worst rows of the same SetNo:');
    PrintCount := Min(10, Length(SeriesPoints));
    for var I := 0 to PrintCount - 1 do
    begin
      Input := SavedInput[SeriesPoints[I].SourceIndex];
      OutRes.Add(Format('    source=%d step=%d T=%7.3f '+
        'error=%.6f %s group=%-7s H=(%.8g, %.8g, %.8g)',
        [SeriesPoints[I].SourceIndex, Input.Step, Input.T,
         SeriesPoints[I].SignedError, AUnit,
         AcquisitionGroup(SeriesPoints[I].SourceIndex),
         Input.H.X, Input.H.Y, Input.H.Z]));
    end;

    SetLength(OrientationPoints, 0);
    OrientationExceedCount := 0;
    for var ErrorPoint in Metric.ErrorPoints do
      if (ErrorPoint.SourceIndex >= 0) and
         (ErrorPoint.SourceIndex < Length(SavedInput)) and
         (ErrorPoint.SourceIndex <> Metric.PeakSourceIndex) and
         (SavedInput[ErrorPoint.SourceIndex].SetNo <> PeakInput.SetNo) and
         (OrientationAngleDistance(
            SavedInput[ErrorPoint.SourceIndex].Azi, PeakInput.Azi) <= 1.0) and
         (OrientationAngleDistance(
            SavedInput[ErrorPoint.SourceIndex].Zen, PeakInput.Zen) <= 1.0) and
         (OrientationAngleDistance(
            SavedInput[ErrorPoint.SourceIndex].Vis, PeakInput.Vis) <= 1.0) then
      begin
        N := Length(OrientationPoints);
        SetLength(OrientationPoints, N + 1);
        OrientationPoints[N] := ErrorPoint;
        if Abs(ErrorPoint.SignedError) > ALimit then
          Inc(OrientationExceedCount);
      end;

    for var I := 0 to High(OrientationPoints) - 1 do
      for var J := I + 1 to High(OrientationPoints) do
        if SavedInput[OrientationPoints[J].SourceIndex].T <
           SavedInput[OrientationPoints[I].SourceIndex].T then
        begin
          Swap := OrientationPoints[I];
          OrientationPoints[I] := OrientationPoints[J];
          OrientationPoints[J] := Swap;
        end;

    OutRes.Add(Format('  same orientation in other SetNo (±1°): '+
      'rows=%d; above limit=%d',
      [Length(OrientationPoints), OrientationExceedCount]));
    PrintCount := Min(12, Length(OrientationPoints));
    for var I := 0 to PrintCount - 1 do
    begin
      Input := SavedInput[OrientationPoints[I].SourceIndex];
      OutRes.Add(Format('    source=%d step=%d SetNo=%d T=%7.3f '+
        'error=%.6f %s A=%.2f° Z=%.2f° V=%.2f°',
        [OrientationPoints[I].SourceIndex, Input.Step, Input.SetNo, Input.T,
         OrientationPoints[I].SignedError, AUnit,
         Input.Azi, Input.Zen, Input.Vis]));
    end;
    OutRes.Add('');
  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TestMaxMinOnSphere must be called after TpolyMath.Init');
  if Length(MaxMinIndices) = 0 then
    raise EArgumentException.Create('MaxMinIndices must not be empty');
  if Length(SphereIndices) = 0 then
    raise EArgumentException.Create('SphereIndices must not be empty');
  Huber.Validate;

  Result := Default(TMaxMinSphereTestResult);
  Result.Model := TTemperatureModel.Create(2, 1, 2);
  Result.Huber := Huber;
  Samples := BuildValidationSamples(DefaultOrientationTolerance);

  SetLength(AllTrainingIndices,
    Length(MaxMinIndices) + Length(SphereIndices));
  for var I := 0 to High(MaxMinIndices) do
    AllTrainingIndices[I] := MaxMinIndices[I];
  for var I := 0 to High(SphereIndices) do
    AllTrainingIndices[Length(MaxMinIndices) + I] := SphereIndices[I];
  Fold := BuildOverlappingFold(MaxMinIndices, AllTrainingIndices,
    'MAX/MIN -> ALL ROWS');
  AllFold := BuildOverlappingFold(AllTrainingIndices, AllTrainingIndices,
    'ALL ROWS -> ALL ROWS (IN-SAMPLE)');

  Model := Default(PolyModel);
  Model.ax := Result.Model.AxDegree;
  Model.ku := Result.Model.KuDegree;
  Model.dz := Result.Model.DzDegree;
  Options := TLogoSpatialOptions.Default;
  Result.Identifiability := CheckLogoIdentifiability(Fold, Model,
    InpData.Inpt, InpData.Tmin, InpData.Tmax, Options);

  SetLength(Folds, 1);
  Folds[0] := Fold;
  SetLength(Models, 1);
  Models[0] := Result.Model;

  SavedPmA := InpData.pmA;
  SavedPmH := InpData.pmH;
  SavedMNak := InpData.MNak;
  SavedTMin := InpData.Tmin;
  SavedTMax := InpData.Tmax;
  SavedInput := Copy(InpData.Inpt, 0, Length(InpData.Inpt));
  SavedAcc := Copy(acc, 0, Length(acc));
  SavedMag := Copy(mag, 0, Length(mag));
  SavedInclRes := Copy(InclRes, 0, Length(InclRes));
  SavedRes := CopyPolyResult(Res);
  SavedEStol := eStol;
  SavedKosRes := KosRes;
  SavedHuberDiagnostics[sAcc] :=
    CopyHuberDiagnostic(HuberDiagnostics[sAcc]);
  SavedHuberDiagnostics[sMag] :=
    CopyHuberDiagnostic(HuberDiagnostics[sMag]);
  SavedVisirDiagnostics := VisirDiagnostics;
  SavedTestResults := TestResults;
  SavedCorStolVisir := SetupData.CorStolVisir;
  SavedCorStolZenit := SetupData.CorStolZenit;
  SavedCorStolMagnit := SetupData.CorStolMagnit;

  Runner := TValidationRunner.Create;
  try
    AdapterObject := TInclinValidationAdapter.Create(SavedInput,
      SavedMNak, SavedTMin, SavedTMax);
    Adapter := AdapterObject;
    if Huber.Enabled then
      AdapterObject.UseHuberIRLS(Huber)
    else
      AdapterObject.UseOrdinaryLeastSquares;
    AdapterObject.UseVisirCorrection(SavedCorStolVisir);

    FoldResults := nil;
    FoldResults := Runner.Run(Samples, Folds, Models, Adapter);
    if Length(FoldResults) <> 1 then
      raise EInvalidOpException.CreateFmt(
        'TestMaxMinOnSphere expected one result, got %d',
        [Length(FoldResults)]);

    Result.FoldResult := FoldResults[0];
    Result.Coefficients := CopyPolyResult(Res);
    Result.Diagnostics[sAcc] :=
      CopyHuberDiagnostic(HuberDiagnostics[sAcc]);
    Result.Diagnostics[sMag] :=
      CopyHuberDiagnostic(HuberDiagnostics[sMag]);
    Result.StolError := eStol;
    Result.VisirDiagnostics := VisirDiagnostics;

    if SavedCorStolVisir then
      Result.WithVisirFoldResult := Result.FoldResult
    else
      Result.WithoutVisirFoldResult := Result.FoldResult;
    CollectPointDiagnostics;

    Result.Passed := Result.Identifiability.Accepted;
    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var MetricIndex := ControlledMetricIndex[ControlledIndex];
      if (MetricIndex >= Length(Result.FoldResult.Metrics)) or
         (Result.FoldResult.Metrics[MetricIndex].Count = 0) or
         (Result.FoldResult.Metrics[MetricIndex].MaxAbs >
            ControlledMetricLimit[ControlledIndex]) then
        Result.Passed := False;
    end;

    { Run the same split once more with the opposite visir setting.  This is
      diagnostic only: coefficients, strict result and worst points above
      always belong to the setting requested through SetupData.CorStolVisir. }
    try
      Adapter := nil;
      AdapterObject := TInclinValidationAdapter.Create(SavedInput,
        SavedMNak, SavedTMin, SavedTMax);
      Adapter := AdapterObject;
      if Huber.Enabled then
        AdapterObject.UseHuberIRLS(Huber)
      else
        AdapterObject.UseOrdinaryLeastSquares;
      AdapterObject.UseVisirCorrection(not SavedCorStolVisir);
      FoldResults := nil;
      FoldResults := Runner.Run(Samples, Folds, Models, Adapter);
      if Length(FoldResults) <> 1 then
        raise EInvalidOpException.CreateFmt(
          'Visir comparison expected one result, got %d',
          [Length(FoldResults)]);
      if SavedCorStolVisir then
        Result.WithoutVisirFoldResult := FoldResults[0]
      else
        Result.WithVisirFoldResult := FoldResults[0];
      Result.VisirComparisonAvailable := True;
    except
      on E: Exception do
      begin
        Result.VisirComparisonAvailable := False;
        Result.VisirComparisonError := E.ClassName + ': ' + E.Message;
      end;
    end;

    { Repeat the 240-row fit and then fit all 540 rows from fresh adapter
      instances.  Both runs use the cVis obtained by the primary max/min fit,
      so the training-set comparison cannot be contaminated by estimating a
      different mechanical rotation. }
    try
      SetLength(ComparisonFolds, 2);
      ComparisonFolds[0] := Fold;
      ComparisonFolds[0].Name := 'MAX/MIN REPEAT -> SPHERE';
      ComparisonFolds[1] := AllFold;

      Adapter := nil;
      AdapterObject := TInclinValidationAdapter.Create(SavedInput,
        SavedMNak, SavedTMin, SavedTMax);
      Adapter := AdapterObject;
      if Huber.Enabled then
      begin
        ComparisonHuber := Huber;
        ComparisonHuber.BalanceMaxMinSphere := True;
        AdapterObject.UseHuberIRLS(ComparisonHuber);
      end
      else
        AdapterObject.UseOrdinaryLeastSquares;
      if SavedCorStolVisir then
        AdapterObject.UseFixedVisirCorrection(Result.StolError.cVis)
      else
        AdapterObject.UseVisirCorrection(False);

      FoldResults := nil;
      FoldResults := Runner.Run(Samples, ComparisonFolds, Models, Adapter);
      if Length(FoldResults) <> 2 then
        raise EInvalidOpException.CreateFmt(
          'Training-set comparison expected two results, got %d',
          [Length(FoldResults)]);

      Result.RepeatMaxMinFoldResult := FoldResults[0];
      Result.AllRowsFoldResult := FoldResults[1];
      Result.MaxMinRepeatMaxDelta := 0.0;
      if Length(Result.FoldResult.Metrics) <>
         Length(Result.RepeatMaxMinFoldResult.Metrics) then
        Result.MaxMinRepeatMaxDelta := MaxDouble
      else
        for var MetricIndex := 0 to High(Result.FoldResult.Metrics) do
          Result.MaxMinRepeatMaxDelta := Max(
            Result.MaxMinRepeatMaxDelta,
            MetricDelta(Result.FoldResult.Metrics[MetricIndex],
              Result.RepeatMaxMinFoldResult.Metrics[MetricIndex]));
      Result.MaxMinRepeatReproducible :=
        Result.MaxMinRepeatMaxDelta <= 1E-10;
      Result.TrainingSetComparisonAvailable := True;
    except
      on E: Exception do
      begin
        Result.TrainingSetComparisonAvailable := False;
        Result.TrainingSetComparisonError := E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    Runner.Free;
    Adapter := nil;

    InpData.pmA := SavedPmA;
    InpData.pmH := SavedPmH;
    InpData.MNak := SavedMNak;
    InpData.Tmin := SavedTMin;
    InpData.Tmax := SavedTMax;
    InpData.Inpt := SavedInput;
    acc := SavedAcc;
    mag := SavedMag;
    InclRes := SavedInclRes;
    Res := SavedRes;
    eStol := SavedEStol;
    KosRes := SavedKosRes;
    HuberDiagnostics[sAcc] := SavedHuberDiagnostics[sAcc];
    HuberDiagnostics[sMag] := SavedHuberDiagnostics[sMag];
    VisirDiagnostics := SavedVisirDiagnostics;
    TestResults := SavedTestResults;
    SetupData.CorStolVisir := SavedCorStolVisir;
    SetupData.CorStolZenit := SavedCorStolZenit;
    SetupData.CorStolMagnit := SavedCorStolMagnit;
  end;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI HUBER 2:1:2 - MAX/MIN TRAINING, ALL ROWS TEST');
    OutRes.Add(StringOfChar('=', 104));
    OutRes.Add(Format('Training max/min: %d rows    All rows test: %d rows',
      [Length(MaxMinIndices), Length(AllTrainingIndices)]));
    if Huber.Enabled then
      OutRes.Add(Format('Fit: HUBER, k=%.6g', [Huber.Limit]))
    else
      OutRes.Add('Fit: ordinary least squares');
    OutRes.Add(Format('Visir correction: %s',
      [YesNo(SavedCorStolVisir)]));
    OutRes.Add('');
    OutRes.Add('IDENTIFIABILITY OF MAX/MIN TRAINING SET');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add(Format('Required rank: %d; G rank: %d; H rank: %d',
      [Result.Identifiability.RequiredRank,
       Result.Identifiability.AccRank,
       Result.Identifiability.MagRank]));
    OutRes.Add(Format('G condition: %.6g; H condition: %.6g; rows/coefficient: %.2f',
      [Result.Identifiability.AccCondition,
       Result.Identifiability.MagCondition,
       Result.Identifiability.RowsPerCoefficient]));
    OutRes.Add(Format('Temperature levels: %d; accepted: %s',
      [Result.Identifiability.TemperatureLevelCount,
       YesNo(Result.Identifiability.Accepted)]));
    if not Result.Identifiability.Accepted then
      OutRes.Add('Reason: ' + Result.Identifiability.Reason);

    OutRes.Add('');
    OutRes.Add('INDEPENDENT ALL METRICS');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
      ['Parameter', 'N', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));
    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var MetricIndex := ControlledMetricIndex[ControlledIndex];
      if (MetricIndex >= Length(Result.FoldResult.Metrics)) or
         (Result.FoldResult.Metrics[MetricIndex].Count = 0) then
        OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
          [ControlledMetricName[ControlledIndex], '0', 'n/a', 'n/a',
           'n/a', 'NO DATA']))
      else
      begin
        var Metric := Result.FoldResult.Metrics[MetricIndex];
        OutRes.Add(Format('%-25s %7d %7.3f %-3s %4s '+
          '%7.3f %-3s %4s %7.3f %-3s %4s %6.3f %-3s',
          [ControlledMetricName[ControlledIndex], Metric.Count,
           Metric.MeanAbs, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.MeanAbs, ControlledMetricLimit[ControlledIndex]),
           Metric.Percentile95, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.Percentile95,
             ControlledMetricLimit[ControlledIndex]),
           Metric.MaxAbs, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.MaxAbs, ControlledMetricLimit[ControlledIndex]),
           ControlledMetricLimit[ControlledIndex],
           ControlledMetricUnit[ControlledIndex]]));
      end;
    end;

    OutRes.Add('');
    OutRes.Add('VISIR CORRECTION COMPARISON ON THE SAME ALL ROWS');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add('Diagnostic only: cVis defines the mechanical reference '+
      'frame and is not selected by azimuth improvement.');
    OutRes.Add(Format('%-25s %11s %11s %11s %11s %11s %11s',
      ['Parameter', 'Mean no', 'P95 no', 'Max no',
       'Mean yes', 'P95 yes', 'Max yes']));
    if Result.VisirComparisonAvailable then
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MetricIndex := ControlledMetricIndex[ControlledIndex];
        if (MetricIndex < Length(Result.WithoutVisirFoldResult.Metrics)) and
           (MetricIndex < Length(Result.WithVisirFoldResult.Metrics)) and
           (Result.WithoutVisirFoldResult.Metrics[MetricIndex].Count > 0) and
           (Result.WithVisirFoldResult.Metrics[MetricIndex].Count > 0) then
        begin
          var MetricNo :=
            Result.WithoutVisirFoldResult.Metrics[MetricIndex];
          var MetricYes :=
            Result.WithVisirFoldResult.Metrics[MetricIndex];
          OutRes.Add(Format('%-25s %11.3f %11.3f %11.3f '+
            '%11.3f %11.3f %11.3f',
            [ControlledMetricName[ControlledIndex],
             MetricNo.MeanAbs, MetricNo.Percentile95, MetricNo.MaxAbs,
             MetricYes.MeanAbs, MetricYes.Percentile95, MetricYes.MaxAbs]));
        end;
      end
    else
      OutRes.Add('comparison unavailable: ' + Result.VisirComparisonError);

    OutRes.Add('');
    OutRes.Add('TRAINING SET EXPERIMENT ON THE SAME ALL ROWS');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add('Both fits are verified on all rows; rows used for fitting '+
      'are therefore in-sample.');
    if Result.TrainingSetComparisonAvailable then
    begin
      OutRes.Add(Format('Training rows: MAX/MIN=%d; ALL=%d; '+
        'common all-rows evaluation=%d',
        [Length(MaxMinIndices), Length(AllTrainingIndices),
         Length(AllTrainingIndices)]));
      OutRes.Add(Format('Fixed cVis for both fits: %.10g°',
        [Result.StolError.cVis]));
      if Huber.Enabled then
        OutRes.Add('ALL fit group weights: MAX/MIN total = SPHERE total');
      OutRes.Add(Format('MAX/MIN repeat max metric delta: %.3g; '+
        'reproducible at 1E-10: %s',
        [Result.MaxMinRepeatMaxDelta,
         YesNo(Result.MaxMinRepeatReproducible)]));
      OutRes.Add(Format('%-25s %-9s %5s %11s %11s %11s %11s %11s',
        ['Parameter', 'Fit', 'N', 'MeanSigned', 'MeanAbs', 'RMS',
         'P95', 'MaxAbs']));
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MetricIndex := ControlledMetricIndex[ControlledIndex];
        if (MetricIndex < Length(Result.RepeatMaxMinFoldResult.Metrics)) and
           (MetricIndex < Length(Result.AllRowsFoldResult.Metrics)) then
        begin
          var Metric240 :=
            Result.RepeatMaxMinFoldResult.Metrics[MetricIndex];
          var MetricAll := Result.AllRowsFoldResult.Metrics[MetricIndex];
          OutRes.Add(Format('%-25s %-9s %5d %11.4f %11.4f '+
            '%11.4f %11.4f %11.4f',
            [ControlledMetricName[ControlledIndex], 'MAX/MIN',
             Metric240.Count, Metric240.MeanSigned, Metric240.MeanAbs,
             Metric240.RMS, Metric240.Percentile95, Metric240.MaxAbs]));
          OutRes.Add(Format('%-25s %-9s %5d %11.4f %11.4f '+
            '%11.4f %11.4f %11.4f',
            ['', 'ALL', MetricAll.Count, MetricAll.MeanSigned,
             MetricAll.MeanAbs, MetricAll.RMS, MetricAll.Percentile95,
             MetricAll.MaxAbs]));
        end;
      end;

      OutRes.Add('');
      OutRes.Add('BY TEMPERATURE SERIES (ALL ROWS)');
      OutRes.Add(Format('%-6s %13s %-9s %-25s %5s %9s %9s %9s %9s %9s',
        ['SetNo', 'T range', 'Fit', 'Parameter', 'N', 'MeanSign',
         'MeanAbs', 'RMS', 'P95', 'MaxAbs']));
      var SetNos := TList<Integer>.Create;
      try
        for var SourceIndex in AllTrainingIndices do
          if not SetNos.Contains(SavedInput[SourceIndex].SetNo) then
            SetNos.Add(SavedInput[SourceIndex].SetNo);
        SetNos.Sort;
        for var SetNo in SetNos do
        begin
          var SeriesTMin := MaxDouble;
          var SeriesTMax := -MaxDouble;
          for var SourceIndex in AllTrainingIndices do
            if SavedInput[SourceIndex].SetNo = SetNo then
            begin
              SeriesTMin := Min(SeriesTMin,
                SavedInput[SourceIndex].T);
              SeriesTMax := Max(SeriesTMax,
                SavedInput[SourceIndex].T);
            end;
          for var ControlledIndex := 0 to ControlledMetricCount - 1 do
          begin
            var MetricIndex := ControlledMetricIndex[ControlledIndex];
            if (MetricIndex >=
                Length(Result.RepeatMaxMinFoldResult.Metrics)) or
               (MetricIndex >= Length(Result.AllRowsFoldResult.Metrics)) then
              Continue;
            var Series240 := FilterMetricBySetNo(
              Result.RepeatMaxMinFoldResult.Metrics[MetricIndex], SetNo);
            var SeriesAll := FilterMetricBySetNo(
              Result.AllRowsFoldResult.Metrics[MetricIndex], SetNo);
            if Series240.Count = 0 then
              Continue;
            OutRes.Add(Format('%-6d %6.1f..%-6.1f %-9s %-25s %5d '+
              '%9.4f %9.4f '+
              '%9.4f %9.4f %9.4f',
              [SetNo, SeriesTMin, SeriesTMax, 'MAX/MIN',
               ControlledMetricName[ControlledIndex],
               Series240.Count, Series240.MeanSigned, Series240.MeanAbs,
               Series240.RMS, Series240.Percentile95, Series240.MaxAbs]));
            OutRes.Add(Format('%-6s %13s %-9s %-25s %5d %9.4f %9.4f '+
              '%9.4f %9.4f %9.4f',
              ['', '', 'ALL', '', SeriesAll.Count, SeriesAll.MeanSigned,
               SeriesAll.MeanAbs, SeriesAll.RMS, SeriesAll.Percentile95,
               SeriesAll.MaxAbs]));
          end;
        end;
      finally
        SetNos.Free;
      end;
    end
    else
      OutRes.Add('comparison unavailable: ' +
        Result.TrainingSetComparisonError);

    OutRes.Add('');
    OutRes.Add('240 MODEL - MAGNETIC WORST-ROW INVESTIGATION');
    OutRes.Add(StringOfChar('-', 104));
    OutRes.Add('The peak row is compared with the worst rows from the same '+
      'SetNo. HuberH is available only for MAX/MIN training rows.');
    AddMagneticWorstSeries(4, 'Magnetic inclination', '°',
      ControlledMetricLimit[1]);
    AddMagneticWorstSeries(6, 'Magnetometer norm', '%',
      ControlledMetricLimit[4]);

    OutRes.Add('');
    OutRes.Add('WORST ROW FOR EACH CONTROLLED PARAMETER');
    OutRes.Add(StringOfChar('-', 104));
    for var Diagnostic in Result.WorstPoints do
    begin
      if Diagnostic.MetricName = '' then
        Continue;
      OutRes.Add(Format('%s: source=%d; step=%d; SetNo=%d; '+
        'error=%.6f; limit=%.6f; T=%.3f; Info="%s"',
        [Diagnostic.MetricName, Diagnostic.SourceIndex,
         Diagnostic.Step, Diagnostic.SetNo, Diagnostic.SignedError,
         Diagnostic.Limit, Diagnostic.Temperature, Diagnostic.Info]));
      OutRes.Add(Format('  G=(%.10g, %.10g, %.10g); '+
        'H=(%.10g, %.10g, %.10g)',
        [Diagnostic.G.X, Diagnostic.G.Y, Diagnostic.G.Z,
         Diagnostic.H.X, Diagnostic.H.Y, Diagnostic.H.Z]));
      if not IsNan(Diagnostic.ExpectedNorm) then
        OutRes.Add(Format('  expected norm=%.10g; calculated norm=%.10g',
          [Diagnostic.ExpectedNorm, Diagnostic.CalculatedNorm]));
      OutRes.Add('  Huber weight=n/a (final all-row evaluation)');
    end;

    OutRes.Add('');
    OutRes.Add(Format('MAGNETOMETER NORM EXCEEDANCES (> %.3f%%): %d',
      [ControlledMetricLimit[4], Length(Result.MagnetNormExceedances)]));
    OutRes.Add(StringOfChar('-', 104));
    if Length(Result.MagnetNormExceedances) = 0 then
      OutRes.Add('none')
    else
      for var Diagnostic in Result.MagnetNormExceedances do
        OutRes.Add(Format('source=%d; step=%d; error=%.6f%%; T=%.3f; '+
          'expected=%.10g; calculated=%.10g; Info="%s"',
          [Diagnostic.SourceIndex, Diagnostic.Step, Diagnostic.SignedError,
           Diagnostic.Temperature, Diagnostic.ExpectedNorm,
           Diagnostic.CalculatedNorm, Diagnostic.Info]));

    OutRes.Add('');
    if SavedCorStolVisir then
      OutRes.Add(Format('Visir cVis: %.10g -> %.10g°; converged=%s',
        [Result.VisirDiagnostics.InitialCVis,
         Result.VisirDiagnostics.CorrectedCVis,
         YesNo(Result.VisirDiagnostics.Converged)]));
    if Result.Passed then
      OutRes.Add('STRICT RESULT BY MAXABS: PASS')
    else
      OutRes.Add('STRICT RESULT BY MAXABS: FAIL');
  finally
    OutRes.EndUpdate;
  end;
end;

class function TpolyMath.SelectBestHuberParameters(
  const HuberKValues: array of Double; OutRes: TStrings):
  TBestHuberParameters;
begin
  Result := SelectBestHuberParameters(HuberKValues, True, OutRes);
end;

class function TpolyMath.SelectBestHuberParameters(
  const HuberKValues: array of Double;
  BalanceMaxMinSphere: Boolean; OutRes: TStrings):
  TBestHuberParameters;
const
  ControlledMetricCount = 5;
  ExpectedKindCount = 4;
  ExpectedCheckCount = ControlledMetricCount * ExpectedKindCount;
  ControlledMetricIndex: array[0..ControlledMetricCount - 1] of Integer =
    (0, 4, 1, 5, 6);
  ControlledMetricName: array[0..ControlledMetricCount - 1] of string = (
    'Zenith',
    'Magnetic inclination',
    'Azimuth (Z > 5°)',
    'Accelerometer norm',
    'Magnetometer norm'
  );
  ControlledMetricUnit: array[0..ControlledMetricCount - 1] of string = (
    '°', '°', '°', '%', '%'
  );
  ControlledMetricLimit: array[0..ControlledMetricCount - 1] of Double = (
    0.15, 0.20, 1.00, 0.30, 0.50
  );

  function KindName(Kind: TValidationKind): string;
  begin
    case Kind of
      vkLeaveSeriesOut: Result := 'LOTO';
      vkLeaveTemperatureBandOut: Result := 'LTBO';
      vkLeaveOrientationGroupOut: Result := 'LOGO';
      vkLeaveTemperatureBandOrOrientationOut: Result := 'STRESS';
    else
      Result := 'UNKNOWN';
    end;
  end;

  function WorstFoldValues(const Validation: TValidationTestRun;
    Kind: TValidationKind; MetricIndex: Integer;
    out MeanAbs, P95, MaxAbs: Double): Boolean;
  begin
    Result := False;
    MeanAbs := 0;
    P95 := 0;
    MaxAbs := 0;

    for var FoldResult in Validation.FoldResults do
      if (FoldResult.Kind = Kind) and
         (MetricIndex >= 0) and
         (MetricIndex < Length(FoldResult.Metrics)) and
         (FoldResult.Metrics[MetricIndex].Count > 0) then
      begin
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].MeanAbs > MeanAbs) then
          MeanAbs := FoldResult.Metrics[MetricIndex].MeanAbs;
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].Percentile95 > P95) then
          P95 := FoldResult.Metrics[MetricIndex].Percentile95;
        if (not Result) or
           (FoldResult.Metrics[MetricIndex].MaxAbs > MaxAbs) then
          MaxAbs := FoldResult.Metrics[MetricIndex].MaxAbs;
        Result := True;
      end;
  end;

  function BuildCandidateScore(const Validation: TValidationTestRun;
    Limit: Double): THuberKCandidateResult;
  var
    ErrorSum: Double;
  begin
    Result := Default(THuberKCandidateResult);
    Result.Limit := Limit;
    ErrorSum := 0;

    for var Kind := Low(TValidationKind) to High(TValidationKind) do
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MeanAbs, P95, MaxAbs: Double;
        if not WorstFoldValues(Validation, Kind,
          ControlledMetricIndex[ControlledIndex], MeanAbs, P95, MaxAbs) then
          Continue;

        Inc(Result.EvaluatedCount);
        if MeanAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.MeanAbsPassCount);
        if P95 <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.P95PassCount);
        if MaxAbs <= ControlledMetricLimit[ControlledIndex] then
          Inc(Result.MaxAbsPassCount);

        ErrorSum := ErrorSum +
          MeanAbs / ControlledMetricLimit[ControlledIndex] +
          P95 / ControlledMetricLimit[ControlledIndex] +
          MaxAbs / ControlledMetricLimit[ControlledIndex];
      end;

    Result.Complete := Result.EvaluatedCount = ExpectedCheckCount;
    if Result.EvaluatedCount = 0 then
      Result.NormalizedError := Infinity
    else
      Result.NormalizedError := ErrorSum / (3 * Result.EvaluatedCount);
  end;

  function IsBetter(const A, B: THuberKCandidateResult): Boolean;
  begin
    if A.Complete <> B.Complete then
      Exit(A.Complete);
    if not SameValue(A.NormalizedError, B.NormalizedError, 1E-12) then
      Exit(A.NormalizedError < B.NormalizedError);
    if A.MeanAbsPassCount <> B.MeanAbsPassCount then
      Exit(A.MeanAbsPassCount > B.MeanAbsPassCount);
    if A.P95PassCount <> B.P95PassCount then
      Exit(A.P95PassCount > B.P95PassCount);
    if A.MaxAbsPassCount <> B.MaxAbsPassCount then
      Exit(A.MaxAbsPassCount > B.MaxAbsPassCount);
    { При полностью одинаковом качестве выбираем большую границу: она
      меньше изменяет корректные строки и ближе к обычному МНК. }
    Result := A.Limit > B.Limit;
  end;

  function PassFail(Value, Limit: Double): string;
  begin
    if Value <= Limit then
      Result := 'PASS'
    else
      Result := 'FAIL';
  end;

  function YesNo(Value: Boolean): string;
  begin
    if Value then
      Result := 'yes'
    else
      Result := 'no';
  end;

  procedure AddCoefficientLines(const SensorName: string;
    const Coefficients: TVArray<Double>);
  begin
    for var Axis in SVectors do
    begin
      var Line := Format('  %s%s = [',
        [SensorName, string(SVectorsNames[Axis])]);
      for var I := 0 to High(Coefficients[Axis]) do
      begin
        if I > 0 then
          Line := Line + ', ';
        Line := Line + Format('%.12g', [Coefficients[Axis][I]]);
      end;
      OutRes.Add(Line + ']');
    end;
  end;

var
  ModelArray: TArray<TTemperatureModel>;
  CandidateValidation, BestValidation, SavedTestResults: TValidationTestRun;
  CandidateOptions, BestOptions: THuberIrlsOptions;
  BestIndex: Integer;
  FinalModel: PolyModel;
  SavedPmA, SavedPmH: PolyModel;
  SavedMNak, SavedTMin, SavedTMax: Double;
  SavedInput: TArray<TinclInput>;
  SavedAcc, SavedMag: TArray<RowModel>;
  SavedInclRes: TArray<TInclRes>;
  SavedRes: TPolyRes;
  SavedEStol: TStolError;
  SavedKosRes: TFindLMKosStol;
  SavedHuberDiagnostics: TSensorData<THuberIrlsDiagnostics>;
  SavedVisirDiagnostics: TVisirCorrectionDiagnostics;
  SavedCorStolVisir, SavedCorStolZenit, SavedCorStolMagnit: Boolean;
  FinalSamples: TArray<TValidationSample>;
  FinalIndices: TArray<Integer>;
  FinalFolds: TArray<TValidationFold>;
  FinalFoldResults: TArray<TValidationFoldResult>;
  FinalRunner: TValidationRunner;
  FinalAdapterObject: TInclinValidationAdapter;
  FinalAdapter: IValidationModelAdapter;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'SelectBestHuberParameters must be called after TpolyMath.Init');
  if Length(HuberKValues) = 0 then
    raise EArgumentException.Create('HuberKValues must not be empty');

  Result := Default(TBestHuberParameters);
  Result.Model := TTemperatureModel.Create(2, 1, 2);
  SetLength(ModelArray, 1);
  ModelArray[0] := Result.Model;
  SetLength(Result.Candidates, Length(HuberKValues));
  SavedTestResults := TestResults;
  BestIndex := -1;

  try
    for var I := 0 to High(HuberKValues) do
    begin
      if IsNan(HuberKValues[I]) or IsInfinite(HuberKValues[I]) or
         (HuberKValues[I] <= 0) then
        raise EArgumentOutOfRangeException.CreateFmt(
          'HuberKValues[%d] must be finite and positive', [I]);

      CandidateOptions := THuberIrlsOptions.DefaultHuber;
      CandidateOptions.Limit := HuberKValues[I];
      CandidateOptions.BalanceMaxMinSphere := BalanceMaxMinSphere;
      CandidateOptions.Validate;
      CandidateValidation := RunTests(ModelArray, CandidateOptions);
      Result.Candidates[I] := BuildCandidateScore(CandidateValidation,
        CandidateOptions.Limit);

      if BestIndex < 0 then
      begin
        BestIndex := I;
        BestOptions := CandidateOptions;
        BestValidation := CandidateValidation;
      end;
      if (BestIndex <> I) and
         IsBetter(Result.Candidates[I], Result.Candidates[BestIndex]) then
      begin
        BestIndex := I;
        BestOptions := CandidateOptions;
        BestValidation := CandidateValidation;
      end;
    end;
  except
    TestResults := SavedTestResults;
    raise;
  end;

  if BestIndex < 0 then
  begin
    TestResults := SavedTestResults;
    raise EInvalidOpException.Create(
      'No Huber candidate produced evaluable validation metrics');
  end;
  if Result.Candidates[BestIndex].EvaluatedCount = 0 then
  begin
    TestResults := SavedTestResults;
    raise EInvalidOpException.Create(
      'No Huber candidate produced evaluable validation metrics');
  end;

  Result.Huber := BestOptions;
  Result.Validation := BestValidation;

  { RunTests сохраняет рабочее состояние. Теперь явно перестраиваем строки
    для 2:1:2 и оцениваем окончательные коэффициенты на полном наборе. }
  SavedPmA := InpData.pmA;
  SavedPmH := InpData.pmH;
  SavedMNak := InpData.MNak;
  SavedTMin := InpData.Tmin;
  SavedTMax := InpData.Tmax;
  SavedInput := Copy(InpData.Inpt, 0, Length(InpData.Inpt));
  SavedAcc := Copy(acc, 0, Length(acc));
  SavedMag := Copy(mag, 0, Length(mag));
  SavedInclRes := Copy(InclRes, 0, Length(InclRes));
  SavedRes := CopyPolyResult(Res);
  SavedEStol := eStol;
  SavedKosRes := KosRes;
  SavedHuberDiagnostics[sAcc] :=
    CopyHuberDiagnostic(HuberDiagnostics[sAcc]);
  SavedHuberDiagnostics[sMag] :=
    CopyHuberDiagnostic(HuberDiagnostics[sMag]);
  SavedVisirDiagnostics := VisirDiagnostics;
  SavedCorStolVisir := SetupData.CorStolVisir;
  SavedCorStolZenit := SetupData.CorStolZenit;
  SavedCorStolMagnit := SetupData.CorStolMagnit;

  try
    FinalModel := Default(PolyModel);
    FinalModel.ax := Result.Model.AxDegree;
    FinalModel.ku := Result.Model.KuDegree;
    FinalModel.dz := Result.Model.DzDegree;
    Init(FinalModel, FinalModel, SavedMNak, SavedInput,
      SavedTMin, SavedTMax);
    ClearStolError;
    KosRes := Default(TFindLMKosStol);
    SetupData.CorStolVisir := SavedCorStolVisir;
    SetupData.CorStolZenit := False;
    SetupData.CorStolMagnit := False;

    { Коррекция визира должна выполняться на полном исходном наборе тем же
      Huber-параметром, который победил в cross-validation. CorrectVisir
      изменяет eStol.cVis и намеренно не подменяет Res, поэтому после неё
      обязательно заново решаем обе сенсорные модели. }
    VisirDiagnostics := Default(TVisirCorrectionDiagnostics);
    if SetupData.CorStolVisir then
      CorrectVisir(BestOptions);
    RunLS(BestOptions);

    Result.FinalCoefficients := CopyPolyResult(Res);
    Result.FinalDiagnostics[sAcc] :=
      CopyHuberDiagnostic(HuberDiagnostics[sAcc]);
    Result.FinalDiagnostics[sMag] :=
      CopyHuberDiagnostic(HuberDiagnostics[sMag]);
    Result.FinalStolError := eStol;
    Result.VisirDiagnostics := VisirDiagnostics;

    { Выбранный Huber повторно обучается на полном наборе и проверяется на
      тех же строках. Это техническая итоговая проверка ALL -> ALL, а не
      независимая оценка обобщающей способности. }
    FinalSamples := BuildValidationSamples(DefaultOrientationTolerance);
    SetLength(FinalIndices, Length(FinalSamples));
    for var I := 0 to High(FinalSamples) do
      FinalIndices[I] := FinalSamples[I].SourceIndex;

    SetLength(FinalFolds, 1);
    FinalFolds[0] := Default(TValidationFold);
    FinalFolds[0].Kind := vkLeaveOrientationGroupOut;
    FinalFolds[0].Name := 'ALL ROWS -> ALL ROWS (IN-SAMPLE)';
    FinalFolds[0].TrainingIndices := Copy(FinalIndices, 0,
      Length(FinalIndices));
    FinalFolds[0].TestIndices := Copy(FinalIndices, 0,
      Length(FinalIndices));
    FinalFolds[0].TestTemperatureMin := SavedTMin;
    FinalFolds[0].TestTemperatureMax := SavedTMax;

    FinalRunner := TValidationRunner.Create;
    try
      FinalAdapterObject := TInclinValidationAdapter.Create(SavedInput,
        SavedMNak, SavedTMin, SavedTMax);
      FinalAdapter := FinalAdapterObject;
      FinalAdapterObject.UseHuberIRLS(BestOptions);
      if SavedCorStolVisir then
        FinalAdapterObject.UseFixedVisirCorrection(
          Result.FinalStolError.cVis)
      else
        FinalAdapterObject.UseVisirCorrection(False);

      FinalFoldResults := nil;
      FinalFoldResults := FinalRunner.Run(FinalSamples, FinalFolds,
        ModelArray, FinalAdapter);
      if Length(FinalFoldResults) <> 1 then
        raise EInvalidOpException.CreateFmt(
          'Final all-row verification expected one result, got %d',
          [Length(FinalFoldResults)]);
      Result.FinalAllFoldResult := FinalFoldResults[0];
    finally
      FinalAdapter := nil;
      FinalRunner.Free;
    end;

    { SelectBestHuberParameters оставляет итоговую модель активной, но не
      должен менять выбранные пользователем флаги коррекции. }
    SetupData.CorStolVisir := SavedCorStolVisir;
    SetupData.CorStolZenit := SavedCorStolZenit;
    SetupData.CorStolMagnit := SavedCorStolMagnit;
  except
    InpData.pmA := SavedPmA;
    InpData.pmH := SavedPmH;
    InpData.MNak := SavedMNak;
    InpData.Tmin := SavedTMin;
    InpData.Tmax := SavedTMax;
    InpData.Inpt := SavedInput;
    acc := SavedAcc;
    mag := SavedMag;
    InclRes := SavedInclRes;
    Res := SavedRes;
    eStol := SavedEStol;
    KosRes := SavedKosRes;
    HuberDiagnostics[sAcc] := SavedHuberDiagnostics[sAcc];
    HuberDiagnostics[sMag] := SavedHuberDiagnostics[sMag];
    VisirDiagnostics := SavedVisirDiagnostics;
    SetupData.CorStolVisir := SavedCorStolVisir;
    SetupData.CorStolZenit := SavedCorStolZenit;
    SetupData.CorStolMagnit := SavedCorStolMagnit;
    TestResults := SavedTestResults;
    raise;
  end;

  { Публичный последний validation-результат обязан соответствовать
    выбранному k, а не последнему элементу входного массива. }
  TestResults := BestValidation;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI VALIDATION - HUBER 2:1:2 PARAMETER SELECTION');
    OutRes.Add(StringOfChar('=', 106));
    OutRes.Add('Ranking: lowest normalized error, then MeanAbs/P95/MaxAbs PASS counts.');
    OutRes.Add('Exact tie: larger k (less down-weighting) wins.');
    OutRes.Add(Format('Balanced MAX/MIN/SPHERE weights: %s',
      [YesNo(BalanceMaxMinSphere)]));
    OutRes.Add(Format('Samples: %d    Accepted folds: %d    Candidates: %d',
      [Length(BestValidation.Samples), Length(BestValidation.Folds),
       Length(Result.Candidates)]));
    OutRes.Add('');
    OutRes.Add('CANDIDATE COMPARISON');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('%-10s %-11s %-14s %-12s %-14s %-14s %-10s',
      ['Huber k', 'Coverage', 'MeanAbs PASS', 'P95 PASS', 'MaxAbs PASS',
       'Error index', 'Selected']));
    for var I := 0 to High(Result.Candidates) do
      OutRes.Add(Format('%-10.4g %5d/%-5d %6d/%-7d %4d/%-7d '+
        '%6d/%-7d %-14.3f %-10s',
        [Result.Candidates[I].Limit,
         Result.Candidates[I].EvaluatedCount, ExpectedCheckCount,
         Result.Candidates[I].MeanAbsPassCount,
         Result.Candidates[I].EvaluatedCount,
         Result.Candidates[I].P95PassCount,
         Result.Candidates[I].EvaluatedCount,
         Result.Candidates[I].MaxAbsPassCount,
         Result.Candidates[I].EvaluatedCount,
         Result.Candidates[I].NormalizedError,
         YesNo(I = BestIndex)]));

    OutRes.Add('');
    OutRes.Add(Format('SELECTED: HUBER %s, k = %.6g',
      [Result.Model.Name, Result.Huber.Limit]));
    OutRes.Add(Format('Score: MeanAbs %d/%d, P95 %d/%d, MaxAbs %d/%d; index %.3f.',
      [Result.Candidates[BestIndex].MeanAbsPassCount,
       Result.Candidates[BestIndex].EvaluatedCount,
       Result.Candidates[BestIndex].P95PassCount,
       Result.Candidates[BestIndex].EvaluatedCount,
       Result.Candidates[BestIndex].MaxAbsPassCount,
       Result.Candidates[BestIndex].EvaluatedCount,
       Result.Candidates[BestIndex].NormalizedError]));

    OutRes.Add('');
    OutRes.Add('SELECTED CANDIDATE BY TEST');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('%-8s %-25s %18s %18s %18s %10s',
      ['Test', 'Parameter', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));
    for var Kind := Low(TValidationKind) to High(TValidationKind) do
      for var ControlledIndex := 0 to ControlledMetricCount - 1 do
      begin
        var MeanAbs, P95, MaxAbs: Double;
        if WorstFoldValues(BestValidation, Kind,
          ControlledMetricIndex[ControlledIndex], MeanAbs, P95, MaxAbs) then
          OutRes.Add(Format('%-8s %-25s %8.3f %-3s %-6s '+
            '%8.3f %-3s %-6s %8.3f %-3s %-6s %6.3f %-3s',
            [KindName(Kind), ControlledMetricName[ControlledIndex],
             MeanAbs, ControlledMetricUnit[ControlledIndex],
             PassFail(MeanAbs, ControlledMetricLimit[ControlledIndex]),
             P95, ControlledMetricUnit[ControlledIndex],
             PassFail(P95, ControlledMetricLimit[ControlledIndex]),
             MaxAbs, ControlledMetricUnit[ControlledIndex],
             PassFail(MaxAbs, ControlledMetricLimit[ControlledIndex]),
             ControlledMetricLimit[ControlledIndex],
             ControlledMetricUnit[ControlledIndex]]));
      end;

    OutRes.Add('');
    OutRes.Add('FINAL FIT ON ALL SAMPLES');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('Accelerometer: iterations=%d, converged=%s, down-weighted=%d, min weight=%.6g',
      [Result.FinalDiagnostics[sAcc].Iterations,
       YesNo(Result.FinalDiagnostics[sAcc].Converged),
       Result.FinalDiagnostics[sAcc].DownWeightedCount,
       Result.FinalDiagnostics[sAcc].MinWeight]));
    OutRes.Add(Format('Magnetometer:  iterations=%d, converged=%s, down-weighted=%d, min weight=%.6g',
      [Result.FinalDiagnostics[sMag].Iterations,
       YesNo(Result.FinalDiagnostics[sMag].Converged),
       Result.FinalDiagnostics[sMag].DownWeightedCount,
       Result.FinalDiagnostics[sMag].MinWeight]));
    OutRes.Add(Format('Temperature basis: Tmin=%.6g C, Tmax=%.6g C',
      [InpData.Tmin, InpData.Tmax]));

    OutRes.Add('');
    OutRes.Add('INDEPENDENT ALL METRICS');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
      ['Parameter', 'N', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));
    for var ControlledIndex := 0 to ControlledMetricCount - 1 do
    begin
      var MetricIndex := ControlledMetricIndex[ControlledIndex];
      if (MetricIndex >= Length(Result.FinalAllFoldResult.Metrics)) or
         (Result.FinalAllFoldResult.Metrics[MetricIndex].Count = 0) then
        OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
          [ControlledMetricName[ControlledIndex], '0', 'n/a', 'n/a',
           'n/a', 'NO DATA']))
      else
      begin
        var Metric := Result.FinalAllFoldResult.Metrics[MetricIndex];
        OutRes.Add(Format('%-25s %7d %7.3f %-3s %4s '+
          '%7.3f %-3s %4s %7.3f %-3s %4s %6.3f %-3s',
          [ControlledMetricName[ControlledIndex], Metric.Count,
           Metric.MeanAbs, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.MeanAbs,
             ControlledMetricLimit[ControlledIndex]),
           Metric.Percentile95, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.Percentile95,
             ControlledMetricLimit[ControlledIndex]),
           Metric.MaxAbs, ControlledMetricUnit[ControlledIndex],
           PassFail(Metric.MaxAbs,
             ControlledMetricLimit[ControlledIndex]),
           ControlledMetricLimit[ControlledIndex],
           ControlledMetricUnit[ControlledIndex]]));
      end;
    end;

    OutRes.Add('');
    OutRes.Add('VISIR CORRECTION');
    OutRes.Add(StringOfChar('-', 106));
    if SavedCorStolVisir then
    begin
      OutRes.Add(Format('cVis: %.10g -> %.10g°; Yx0: %.10g -> %.10g',
        [Result.VisirDiagnostics.InitialCVis,
         Result.VisirDiagnostics.CorrectedCVis,
         Result.VisirDiagnostics.InitialYx0,
         Result.VisirDiagnostics.FinalYx0]));
      OutRes.Add(Format('Iterations: %d; converged=%s',
        [Result.VisirDiagnostics.Iterations,
         YesNo(Result.VisirDiagnostics.Converged)]));
    end
    else
      OutRes.Add('disabled (SetupData.CorStolVisir=False)');

    OutRes.Add('');
    OutRes.Add('FINAL COEFFICIENTS');
    OutRes.Add(StringOfChar('-', 106));
    AddCoefficientLines('G', Result.FinalCoefficients.G);
    AddCoefficientLines('H', Result.FinalCoefficients.H);
  finally
    OutRes.EndUpdate;
  end;
end;

class procedure TpolyMath.RunAmp;
begin
  RunLMSensor(InpData.pmA, acc, sAcc, Res.G);
  RunLMSensor(InpData.pmH, mag, sMag, Res.H);
end;

class procedure TpolyMath.SetupKoso(Bl, bh: PFindLMKosStol);
begin
  bl^ := Default(TFindLMKosStol);
  bh^ := Default(TFindLMKosStol);
  for var i := 0 to TKosUgol.Length-1 do
   begin
    bl.kos[sAcc].V[i] := -1;
    bh.kos[sAcc].V[i] :=  1;
    bl.kos[sMag].V[i] := -1;
    bh.kos[sMag].V[i] :=  1;
   end;
  bh.kos[sAcc].Yx := 0;
  bl.kos[sAcc].Yx := 0;

  if SetupData.CorStolZenit then
   begin
    bl.StolError.cZenA := -0.2;
    bh.StolError.cZenA :=  0.2;
    bl.StolError.cZenAng := -90;
    bh.StolError.cZenAng :=  90;
   end;
  if SetupData.CorStolVisir then
   begin
    bl.StolError.cVis := -10;
    bh.StolError.cVis :=  10;
   end;

  if SetupData.CorStolMagnit then
   begin
    bl.StolError.cAzi := -1;
    bh.StolError.cAzi :=  1;

    bl.StolError.cNakl := -1;
    bh.StolError.cNakl :=  1;
   end;

end;


class procedure TpolyMath.KorrTVectors_int;
begin
  SetLength(KorrTVectors, Length(acc));
  for var i:= 0 to High(acc) do
   begin
     var r: TSensorVect;
     InpData.pmA.FindAxis(@Res.RowG[0], Acc[i], r[sAcc].X, r[sAcc].Y, r[sAcc].Z);
     InpData.pmH.FindAxis(@Res.RowH[0], Mag[i], r[sMag].X, r[sMag].Y, r[sMag].Z);
     KorrTVectors[i] := r;
   end;

end;

// k - 6+6 koso + 5 stol
// f zenErr, AziErr, AmpAer, ampHer Nakl;
class procedure TpolyMath.RunKoso;
 var
  bl,bh,kb: TFindLMKosStol;
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  IsKosoV2 := False;
  SetupKoso(@Bl,@bh);

  KorrTVectors_int;

  kb := Default(TFindLMKosStol);

  LMFittingFactory(e);
  var lenk := SizeOf(TFindLMKosStol) div SizeOf(Double);
  var lenf := Length(InpData.Inpt)*6;
  CheckMath(e, e.FitVB(lenk, lenf, @kb, @bl, @bh, 0.0001, 0, 0, 0, 100000, func_cb_koso, xout, rep));

  KosRes := PFindLMKosStol(xout)^;
  eStol := KosRes.StolError;
end;

class procedure TpolyMath.RunKosoV2;
 var
  bl,bh,kb: TFindLMKosStolV2;
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  SetLength(KorrTVectors, Length(acc));
  IsKosoV2 := True;

  SetupKoso(@Bl.ks,@bh.ks);

  Res.toArray(bl.t);
  Res.toArray(bh.t);
  for var I := 0 to Res.ArrayLen-1 do
   if i <> InpData.pmA.KyIdx then
   begin
    bl.t[i] := bl.t[i]-0.02;
    bh.t[i] := bh.t[i]+0.02;
   end;

  kb.ks := KosRes;// Default(TFindLMKosStol);
  Res.toArray(kb.t);

  LMFittingFactory(e);
  var lenk := SizeOf(TFindLMKosStol) div SizeOf(Double) + InpData.pmA.KoeffCnt*3 + InpData.pmH.KoeffCnt*3;
  var lenf := Length(InpData.Inpt)*6;
  CheckMath(e, e.FitVB(lenk, lenf, @kb, @bl, @bh, 0.00001, 0, 0, 0, 100000, func_cb_koso, xout, rep));

  KosRes := PFindLMKosStolV2(xout)^.ks;
  Res.fromArray(PFindLMKosStolV2(xout)^.t);
  eStol := KosRes.StolError;
//  KorrTVectors_int;
end;


class procedure TpolyMath.KosoFindInkl(ivec: Integer; const koso: TFindLMKosStol; var Incl: TInclRes);
 var
   ax, ay, az, x, y, z: Double;
begin

  VecExtract(KorrTVectors[ivec], ax, ay, az, x, y, z);
  koso.kos[sAcc].Find(ax, ay, az);
  koso.kos[sMag].Find(x, y, z);
  FindInclRes(VecCollect(ax, ay, az, x, y, z), koso.StolError, incl);
end;

class procedure TpolyMath.ClearStolError;
begin
  eStol := Default(TStolError);
end;

class procedure TpolyMath.FindInclRes(const vec: TSensorVect; const eS: TStolError; var Incl: TInclRes);
 var
  mo,hx,hy,hz,a,b,
  o,zu, os,oc,zs,zc,
  ax, ay, az, x, y, z: Double;
  sA,sZ,sO,sN: Double;
begin
  VecExtract(vec, ax, ay, az, x, y, z);

  o := Arctan2(ay, -ax);
  zu := Arctan2(Hypot(ax, ay), az);

  os := sin(o);
  oc := cos(o);
  zs := sin(zu);
  zc := cos(zu);

  Hx := (x*oc - y*os)*zc + z*zs;
  Hy :=  x*os + y*oc;
  Hz :=-(x*oc - y*os)*zs + z*zc;

  a := -Arctan2(Hy, Hx);
  b := Arctan2(Hypot(Hx, Hy), Hz);

  Incl.Amp[sAcc] := TXMLScriptMath.Hypot3D(ax, ay, az);
  Incl.Amp[sMag] := TXMLScriptMath.Hypot3D(x, y, z);
  Incl.MO := Arctan2(y, -x);
  Incl.zen := TXMLScriptMath.RadToDeg360(zu);
  Incl.otk := TXMLScriptMath.RadToDeg360(o);
  Incl.azi := TXMLScriptMath.RadToDeg360(a);
  Incl.Nakl := TXMLScriptMath.RadToDeg360(b);

  sA := Incl.inp.Azi;
  sZ := Incl.inp.Zen;
  sO := Incl.inp.Vis;
  sN := InpData.MNak;
  eS.Correct(sA,sZ,sO,sN);
  Incl.azi.CorStol := sA;
  Incl.zen.CorStol := sZ;
  Incl.otk.CorStol := sO;
  Incl.Nakl.CorStol := sN;

  Incl.Azi.Error := TAziStat.FindErr(incl);
  Incl.Zen.Error := TZenStat.FindErr(incl);
  Incl.Otk.Error := TotkStat.FindErr(incl);
  Incl.Nakl.Error := TInclStat.FindErr(incl);

  Incl.etaSens := Incl.inp.VecEtalon(RES_AMP,InpData.MNak, eS);

  Incl.trrSens[sAcc] := TVector3.Create(ax,ay,az);
  Incl.trrSens[sMag] := TVector3.Create(x,y,z);
  Incl.errSens[sAcc] := Incl.trrSens[sAcc] - Incl.etaSens[sAcc];
  Incl.errSens[sMag] := Incl.trrSens[sMag] - Incl.etaSens[sMag];

//  Incl.etaAmpH := RES_AMP * Inp.EtalonMag/1000;

  incl.erAmp[sAcc] := TAccStat.FindErr(incl);
  incl.erAmp[sMag] := TMagStat.FindErr(incl);
end;

class procedure TpolyMath.func_cb_amp(const k, f: PDoubleArray);
 var
  x,y,z: Double;
begin
  with LMAmpData do
  for var i := 0 to High(d) do
   begin
    m.FindAxis(k, d[i], x,y,z);
    f[i] := RES_AMP - TXMLScriptMath.Hypot3D(x,y,z);
   end;
end;


class procedure TpolyMath.func_cb_koso(const k, f: PDoubleArray);
  var
   zen: Double;
   vec: TSensorVect;
   Res: TInclRes;
begin
  with PFindLMKosStol(k)^ do
  for var i := 0 to High(InpData.Inpt) do
  begin
    if IsKosoV2 then
     with PFindLMKosStolV2(k)^ do
      begin
       InpData.pmA.FindAxisNoKoso(@t[0], Acc[i], vec[sAcc].X, vec[sAcc].Y, vec[sAcc].Z);
       InpData.pmH.FindAxisNoKoso(@t[InpData.pmA.KoeffCnt*3], Mag[i], vec[sMag].X, vec[sMag].Y, vec[sMag].Z);
      end
    else
     begin
      vec := KorrTVectors[i];
     end;

    kos[sAcc].Find(vec[sAcc].X,vec[sAcc].Y,vec[sAcc].Z);
    kos[sMag].Find(vec[sMag].X,vec[sMag].Y,vec[sMag].Z);

    Res.Inp := @InpData.Inpt[i];
    FindInclRes(vec, StolError, Res);
    f[i*6+0] := Res.Zen.Error;
    f[i*6+1] := Res.erAmp[sAcc];
    f[i*6+2] := Res.erAmp[sMag];
    f[i*6+3] := Res.Azi.Error;
    f[i*6+4] := Res.Nakl.Error;
    f[i*6+5] := Res.Otk.Error/10;

    zen := Res.Zen;
    if Zen > 170 then zen := zen - 180;
    if Abs(zen) < 5 then
      begin
//       f[i*6+0] := 0;
       f[i*6+3] := 0;
       f[i*6+5] := 0;
      end;
  end;
end;

class procedure TpolyMath.func_cb_zen(const k, f: PDoubleArray);
begin
  with InpData do for var i := 0 to High(acc) do
   begin
    var x,y,z, dang: Double;
    pmA.FindAxis(k, acc[i], x,y,z);
    var zu := DegNormalize(RadToDeg(arctan2(Hypot(x, y), z)));
    if Inpt[i].Zen > 180 then
      dang := TMetrInclinMath.DeltaAngle(Zu-(360 - Inpt[i].Zen))
    else
      dang := TMetrInclinMath.DeltaAngle(Zu-Inpt[i].Zen);

    f[i*2] := dang;
    f[i*2+1] := (RES_AMP - TXMLScriptMath.Hypot3D(x,y,z))*Sqrt(10);
   end;
end;


//class procedure TpolyMath.func_cb_ZY_StolZ(const k, f: PDoubleArray);
//begin
//
//end;


{ TPolyRes }

function TPolyRes.ArrayLen: Integer;
begin
  Result := Length(G[vX])*3 + Length(H[vX])*3;
end;

procedure TPolyRes.fromArray(r: array of Double);
begin
  var ka := TpolyMath.InpData.pmA.KoeffCnt;
  for var I := 0 to High(G[vX]) do
   begin
    G[vX][i] := r[i];
    G[vY][i] := r[ka+i];
    G[vZ][i] := r[ka*2+i];
   end;
  var kh := TpolyMath.InpData.pmh.KoeffCnt;
  for var I := 0 to High(H[vX]) do
   begin
    H[vX][i] := r[ka*3 + i];
    H[vY][i] := r[ka*3 + kh + i];
    H[vZ][i] := r[ka*3 + kh*2 + i];
   end;
end;

function TPolyRes.RowG: TArray<Double>;
begin
  Result := G[vx] + G[vY] + G[vz];
end;

function TPolyRes.RowH: TArray<Double>;
begin
  Result := H[vx] + H[vY] + H[vz];
end;

procedure TPolyRes.toArray(var r: array of Double);
 var
  idx: Integer;
begin
  idx := 0;
  for var k in RowG do
   begin
    r[idx] := k; inc(idx);
   end;
  for var k in  RowH do
   begin
    r[idx] := k; inc(idx);
   end;
end;

{ TFindLMKosStolv2 }

function TFindLMKosStolv2.Len: Integer;
begin
  Result := SizeOf(TFindLMKosStol) div SizeOf(Double) +
  TpolyMath.InpData.pmA.KoeffCnt*3 + TpolyMath.InpData.pmH.KoeffCnt*3;
end;

class function TGkiPackedExporter.FromFit(
  const Fit: TLinCalibrationResult; AccScale, MagScale: Double):
  TGkiPackedLinearModel;
var
  NodeCount, CoefficientCount: Integer;
begin
  Fit.Model.lin_Validate;
  if Fit.SeparateSensorModels then
    raise EArgumentException.Create(
      'Packed v1 requires one shared G/H model structure');
  if not Fit.Model.CrossLinear or Fit.Model.CrossPiecewise then
    raise EArgumentException.Create(
      'Packed v1 supports only cross model: global linear T');

  NodeCount := Fit.Model.lin_NodeCount;
  if (NodeCount < GKI_PACKED_MIN_NODES) or
     (NodeCount > GKI_PACKED_MAX_NODES) then
    raise EArgumentException.CreateFmt(
      'Packed v1 supports %d..%d nodes, got %d',
      [GKI_PACKED_MIN_NODES, GKI_PACKED_MAX_NODES, NodeCount]);
  CoefficientCount := Fit.Model.lin_CoeffCount;
  if CoefficientCount <> 2 * NodeCount + 4 then
    raise EArgumentException.CreateFmt(
      'Unexpected coefficient layout: %d coefficients for %d nodes',
      [CoefficientCount, NodeCount]);
  if IsNan(AccScale) or IsInfinite(AccScale) or (AccScale <= 0) or
     IsNan(MagScale) or IsInfinite(MagScale) or (MagScale <= 0) then
    raise EArgumentException.Create('Sensor scales must be positive');

  Result := Default(TGkiPackedLinearModel);
  Result.NodeCount := NodeCount;
  Result.CoefficientCount := CoefficientCount;
  Result.AccScale := AccScale;
  Result.MagScale := MagScale;
  for var I := 0 to NodeCount - 1 do
    Result.Nodes[I] := Fit.Model.TemperatureNodes[I];

  for var Axis in SVectors do
  begin
    if Length(Fit.Coefficients.G[Axis]) <> CoefficientCount then
      raise EArgumentException.CreateFmt(
        'G axis %d has %d coefficients, expected %d',
        [Ord(Axis), Length(Fit.Coefficients.G[Axis]), CoefficientCount]);
    if Length(Fit.Coefficients.H[Axis]) <> CoefficientCount then
      raise EArgumentException.CreateFmt(
        'H axis %d has %d coefficients, expected %d',
        [Ord(Axis), Length(Fit.Coefficients.H[Axis]), CoefficientCount]);
    for var I := 0 to CoefficientCount - 1 do
    begin
      Result.Acc[Ord(Axis)][I] := Fit.Coefficients.G[Axis][I];
      Result.Mag[Ord(Axis)][I] := Fit.Coefficients.H[Axis][I];
    end;
  end;
end;

class function TGkiPackedExporter.FromFit(
  const Fit: TLinCalibrationResult): TGkiPackedLinearModel;
begin
  Result := FromFit(Fit, SCALE_A, SCALE_H);
end;


end.
