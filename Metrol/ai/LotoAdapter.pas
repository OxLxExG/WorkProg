unit LotoAdapter;

interface

uses
  System.SysUtils, System.Math,
  TrrInclin.Temp.PolyModel, LuaInclin.Math, Vector,
  MetrInclin.Temp.Stat, MetrInclin.Temp.MathPoly,
  MetrInclin.Temp.LeaveOneOut;

type
  { Адаптер связывает общий механизм валидации с моделью инклинометра.
    Историческое имя класса оставлено для совместимости, но теперь Fit не
    привязан к SetNo и получает явный список обучающих строк. }
  TInclinLotoAdapter = class(TInterfacedObject, IValidationModelAdapter)
  strict private
    FModel: PolyModel;
    FSourceData: TArray<TinclInput>;
    FMagneticInclination: Double;
    FTemperatureMin: Double;
    FTemperatureMax: Double;
    FHuberOptions: THuberIrlsOptions;
    FCorrectVisir: Boolean;
    FFixedCVisEnabled: Boolean;
    FFixedCVis: Double;
    function MetricNames: TArray<string>;
    procedure SetModel(const Model: TTemperatureModel);
    function Fit(const TrainingIndices: TArray<Integer>): IInterface;
    function Errors(const FittedModel: IInterface;
      SourceIndex: Integer): TArray<Double>;
  public
    { Границы температуры определяют единый базис Чебышёва. Они должны быть
      одинаковыми во всех fold'ах и в рабочем алгоритме прибора. }
    constructor Create(const ASourceData: TArray<TinclInput>;
      AMagneticInclination: Double; ATemperatureMin: Double = 19.0;
      ATemperatureMax: Double = 137.0);

    { По умолчанию конструктор оставляет обычный МНК, сохраняя поведение
      существующего кода. Эти методы позволяют явно выбрать робастный режим
      перед передачей адаптера в TValidationRunner. }
    procedure UseOrdinaryLeastSquares;
    procedure UseHuberIRLS; overload;
    procedure UseHuberIRLS(const Options: THuberIrlsOptions); overload;
    { Разрешить коррекцию визира внутри каждого Fit. По умолчанию она
      выключена, поэтому существующие LOTO/LTBO/LOGO тесты не меняются. }
    procedure UseVisirCorrection(Enabled: Boolean = True);
    { Use one externally determined mechanical toolface correction.  This is
      required when two training sets must be compared in exactly the same
      reference frame instead of estimating a different cVis for each fit. }
    procedure UseFixedVisirCorrection(CVis: Double);
  end;

  { Более точное имя для нового кода. }
  TInclinValidationAdapter = TInclinLotoAdapter;

implementation

type
  { Закрытый результат Fit. Общий runner видит только IInterface. }
  IInclinFittedModel = interface
    ['{FE48931B-E7CC-4109-B5A6-9E84DE63E542}']
    function GetPolyResult: TPolyRes;
    function GetKoso: TFindLMKosStol;
    function GetTemperatureMin: Double;
    function GetTemperatureMax: Double;
    function GetMagneticInclination: Double;
  end;

  TInclinFittedModel = class(TInterfacedObject, IInclinFittedModel)
  strict private
    FPolyResult: TPolyRes;
    FKoso: TFindLMKosStol;
    FTemperatureMin: Double;
    FTemperatureMax: Double;
    FMagneticInclination: Double;
  public
    constructor Create(const APolyResult: TPolyRes;
      const AKoso: TFindLMKosStol; ATemperatureMin, ATemperatureMax,
      AMagneticInclination: Double);
    function GetPolyResult: TPolyRes;
    function GetKoso: TFindLMKosStol;
    function GetTemperatureMin: Double;
    function GetTemperatureMax: Double;
    function GetMagneticInclination: Double;
  end;

constructor TInclinFittedModel.Create(const APolyResult: TPolyRes;
  const AKoso: TFindLMKosStol; ATemperatureMin, ATemperatureMax,
  AMagneticInclination: Double);
begin
  inherited Create;
  FPolyResult := APolyResult;
  FKoso := AKoso;
  FTemperatureMin := ATemperatureMin;
  FTemperatureMax := ATemperatureMax;
  FMagneticInclination := AMagneticInclination;
end;

function TInclinFittedModel.GetPolyResult: TPolyRes;
begin
  Result := FPolyResult;
end;

function TInclinFittedModel.GetKoso: TFindLMKosStol;
begin
  Result := FKoso;
end;

function TInclinFittedModel.GetTemperatureMin: Double;
begin
  Result := FTemperatureMin;
end;

function TInclinFittedModel.GetTemperatureMax: Double;
begin
  Result := FTemperatureMax;
end;

function TInclinFittedModel.GetMagneticInclination: Double;
begin
  Result := FMagneticInclination;
end;

{ TInclinLotoAdapter }

constructor TInclinLotoAdapter.Create(
  const ASourceData: TArray<TinclInput>; AMagneticInclination,
  ATemperatureMin, ATemperatureMax: Double);
begin
  inherited Create;
  if Length(ASourceData) = 0 then
    raise EArgumentException.Create('Source data is empty');
  if IsNan(ATemperatureMin) or IsInfinite(ATemperatureMin) or
     IsNan(ATemperatureMax) or IsInfinite(ATemperatureMax) or
     (ATemperatureMax <= ATemperatureMin) then
    raise EArgumentException.Create(
      'ATemperatureMax must be greater than ATemperatureMin');

  FSourceData := Copy(ASourceData, 0, Length(ASourceData));
  FMagneticInclination := AMagneticInclination;
  FTemperatureMin := ATemperatureMin;
  FTemperatureMax := ATemperatureMax;
  FHuberOptions := THuberIrlsOptions.OrdinaryLeastSquares;
  FCorrectVisir := False;
  FFixedCVisEnabled := False;
  FFixedCVis := 0.0;
end;

procedure TInclinLotoAdapter.UseOrdinaryLeastSquares;
begin
  FHuberOptions := THuberIrlsOptions.OrdinaryLeastSquares;
end;

procedure TInclinLotoAdapter.UseHuberIRLS;
begin
  UseHuberIRLS(THuberIrlsOptions.DefaultHuber);
end;

procedure TInclinLotoAdapter.UseHuberIRLS(
  const Options: THuberIrlsOptions);
begin
  Options.Validate;
  if not Options.Enabled then
    raise EArgumentException.Create(
      'UseHuberIRLS requires Options.Enabled=True');
  FHuberOptions := Options;
end;

procedure TInclinLotoAdapter.UseVisirCorrection(Enabled: Boolean);
begin
  FCorrectVisir := Enabled;
  FFixedCVisEnabled := False;
end;

procedure TInclinLotoAdapter.UseFixedVisirCorrection(CVis: Double);
begin
  if IsNan(CVis) or IsInfinite(CVis) then
    raise EArgumentException.Create('CVis must be finite');
  FCorrectVisir := True;
  FFixedCVisEnabled := True;
  FFixedCVis := CVis;
end;

procedure TInclinLotoAdapter.SetModel(const Model: TTemperatureModel);
begin
  if (Model.AxDegree < 0) or (Model.KuDegree < 0) or
     (Model.DzDegree < 0) then
    raise EArgumentOutOfRangeException.Create(
      'Polynomial degrees must be non-negative');

  { Поля копируются явно: приведение двух разных record здесь небезопасно. }
  FModel.ax := Model.AxDegree;
  FModel.ku := Model.KuDegree;
  FModel.dz := Model.DzDegree;
end;

function TInclinLotoAdapter.Fit(
  const TrainingIndices: TArray<Integer>): IInterface;
var
  TrainingData: TArray<TinclInput>;
  SourceIndex: Integer;
  Koso: TFindLMKosStol;
begin
  if Length(TrainingIndices) = 0 then
    raise EArgumentException.Create('TrainingIndices is empty');

  SetLength(TrainingData, Length(TrainingIndices));
  for var I := 0 to High(TrainingIndices) do
  begin
    SourceIndex := TrainingIndices[I];
    if (SourceIndex < 0) or (SourceIndex >= Length(FSourceData)) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'Training SourceIndex=%d is outside 0..%d',
        [SourceIndex, High(FSourceData)]);
    TrainingData[I] := FSourceData[SourceIndex];
  end;

  { Старый код заново находил Tmin/Tmax по TrainingData. При исключении
    очередного fold'а это меняло смысл всех коэффициентов Чебышёва. Здесь
    всегда используются фиксированные эксплуатационные границы. }
  TpolyMath.Init(FModel, FModel, FMagneticInclination, TrainingData,
    FTemperatureMin, FTemperatureMax);

  { Ошибки стола запрещены. Иначе оптимизатор может объяснить температурный
    дрейф датчиков фиктивной поправкой стола.

    RunKoso не вызывается: основная 3x4-модель уже содержит перекрёстные члены,
    а текущая целевая функция RunKoso включает не интересующий нас toolface. }
  TpolyMath.ClearStolError;
  TpolyMath.SetupData.CorStolVisir := FCorrectVisir;
  TpolyMath.SetupData.CorStolZenit := False;
  TpolyMath.SetupData.CorStolMagnit := False;
  { Обычный и робастный режимы используют одну и ту же линейную модель.
    В Huber IRLS меняются только веса обучающих измерений; тестовые строки
    fold'а никогда не участвуют ни в МНК, ни в оценке MAD. }
  if FCorrectVisir then
  begin
    if FFixedCVisEnabled then
      TpolyMath.eStol.cVis := FFixedCVis
    else
      TpolyMath.CorrectVisir(FHuberOptions);
  end;
  TpolyMath.RunLS(FHuberOptions);

  { Нулевые члены TKosUgol соответствуют единичному преобразованию.
    StolError переносит найденную поправку визира в расчёт тестовых строк. }
  Koso := Default(TFindLMKosStol);
  Koso.StolError := TpolyMath.eStol;
  Result := TInclinFittedModel.Create(TpolyMath.Res, Koso,
    FTemperatureMin, FTemperatureMax, FMagneticInclination);
end;

function TInclinLotoAdapter.MetricNames: TArray<string>;
begin
  { Порядок обязан точно совпадать с Errors.

    AzimuthSpatial_deg — пространственное смещение только от ошибки азимута.
    При малых ошибках оно равно sin(Z) * DeltaAzimuth.

    Direction_deg — полный угол между эталонной и вычисленной осями; он не
    имеет особенности в вертикальном положении. }
  Result := [
    'Zenith_deg',
    'Azimuth_deg',
    'AzimuthSpatial_deg',
    'Direction_deg',
    'MagneticInclination_deg',
    'AccelNorm_pct',
    'MagnetNorm_pct'
  ];
end;

function TInclinLotoAdapter.Errors(const FittedModel: IInterface;
  SourceIndex: Integer): TArray<Double>;
var
  Fitted: IInclinFittedModel;
  Input: TinclInput;
  PolyResult: TPolyRes;
  Koso: TFindLMKosStol;
  PowerT: TArray<Double>;
  AccRow, MagRow: RowModel;
  AccCoefficients, MagCoefficients: TArray<Double>;
  Calibrated: TSensorVect;
  Incl: TInclRes;
  RefZenith, RefAzimuth, CalcZenith, CalcAzimuth: Double;
  DeltaAzimuth, CosDirection, CosAzimuthDisplacement: Double;
  SpatialAzimuthError: Double;
  ExpectedAccelNorm, ExpectedMagnetNorm: Double;
begin
  if FittedModel = nil then
    raise EArgumentNilException.Create('FittedModel');
  if (SourceIndex < 0) or (SourceIndex >= Length(FSourceData)) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'SourceIndex=%d is outside 0..%d',
      [SourceIndex, High(FSourceData)]);
  if not Supports(FittedModel, IInclinFittedModel, Fitted) then
    raise EIntfCastError.Create(
      'FittedModel was not created by TInclinLotoAdapter');

  Input := FSourceData[SourceIndex];
  PolyResult := Fitted.GetPolyResult;
  Koso := Fitted.GetKoso;

  { Скрытая строка рассчитывается без повторной подгонки модели. }
  PowerT := FModel.CreatePowerT(Input.T, Fitted.GetTemperatureMin,
    Fitted.GetTemperatureMax, FModel.MaxPowT);
  AccRow := FModel.CreateRow(PowerT, Input.G.V, SCALE_A);
  MagRow := FModel.CreateRow(PowerT, Input.H.V, SCALE_H);
  AccCoefficients := PolyResult.RowG;
  MagCoefficients := PolyResult.RowH;

  FModel.FindAxis(@AccCoefficients[0], AccRow,
    Calibrated[sAcc].X, Calibrated[sAcc].Y, Calibrated[sAcc].Z);
  FModel.FindAxis(@MagCoefficients[0], MagRow,
    Calibrated[sMag].X, Calibrated[sMag].Y, Calibrated[sMag].Z);

  { Сейчас Koso единичный, но путь расчёта готов к будущей постоянной матрице
    несоосности без изменения интерфейса runner'а. }
  Koso.kos[sAcc].Find(Calibrated[sAcc].X,
    Calibrated[sAcc].Y, Calibrated[sAcc].Z);
  Koso.kos[sMag].Find(Calibrated[sMag].X,
    Calibrated[sMag].Y, Calibrated[sMag].Z);

  Incl := Default(TInclRes);
  Incl.Inp := @Input;
  TpolyMath.InpData.MNak := Fitted.GetMagneticInclination;
  TpolyMath.FindInclRes(Calibrated, Koso.StolError, Incl);

  { Представление стола Z>180 переводится в единственное направление сферы. }
  RefZenith := DegNormalize(Input.Zen);
  RefAzimuth := DegNormalize(Input.Azi);
  if RefZenith > 180 then
  begin
    RefZenith := 360 - RefZenith;
    RefAzimuth := DegNormalize(RefAzimuth + 180);
  end;
  CalcZenith := Incl.Zen.Angle;
  CalcAzimuth := Incl.Azi.Angle;
  DeltaAzimuth := TMetrInclinMath.DeltaAngle(CalcAzimuth - RefAzimuth);

  { Точный пространственный угол, создаваемый одной ошибкой азимута. }
  CosAzimuthDisplacement :=
    Sqr(Cos(DegToRad(RefZenith))) +
    Sqr(Sin(DegToRad(RefZenith))) * Cos(DegToRad(DeltaAzimuth));
  CosAzimuthDisplacement := EnsureRange(CosAzimuthDisplacement, -1.0, 1.0);

  { Точный полный угол между двумя направлениями. }
  CosDirection :=
    Cos(DegToRad(RefZenith)) * Cos(DegToRad(CalcZenith)) +
    Sin(DegToRad(RefZenith)) * Sin(DegToRad(CalcZenith)) *
    Cos(DegToRad(DeltaAzimuth));
  CosDirection := EnsureRange(CosDirection, -1.0, 1.0);

  SetLength(Result, 7);
  Result[0] := Incl.Zen.Error;

  { У вертикали обычный азимут физически не определён. NaN маскирует только
    эту метрику; зенит, направление, наклонение и нормы продолжают считаться. }
  if (RefZenith < 5.0) or (RefZenith > 175.0) then
    Result[1] := NaN
  else
    Result[1] := DeltaAzimuth;

  SpatialAzimuthError := RadToDeg(ArcCos(CosAzimuthDisplacement));
  if DeltaAzimuth < 0 then
    SpatialAzimuthError := -SpatialAzimuthError;
  Result[2] := SpatialAzimuthError;
  Result[3] := RadToDeg(ArcCos(CosDirection));

  { Используется соглашение о магнитном угле, уже принятое в FindInclRes и
    VecEtalon. При переходе на знаковый dip от горизонта необходимо синхронно
    изменить и построение эталонного вектора, и эту метрику. }
  Result[4] := TMetrInclinMath.DeltaAngle(
    Incl.Nakl.Angle - Incl.Nakl.CorStol);
  { Norm errors are reported as a relative percentage. Conversion must be
    performed for every source row before aggregation because EtalonMag may
    differ between rows. Positive values mean that the calibrated vector norm
    is too large; negative values mean that it is too small. }
  ExpectedAccelNorm := RES_AMP;
  if IsZero(ExpectedAccelNorm) then
    Result[5] := NaN
  else
    Result[5] := Incl.erAmp[sAcc] / ExpectedAccelNorm * 100.0;

  ExpectedMagnetNorm := RES_AMP * Input.EtalonMag / 1000.0;
  if IsZero(ExpectedMagnetNorm) then
    Result[6] := NaN
  else
    Result[6] := Incl.erAmp[sMag] / ExpectedMagnetNorm * 100.0;
end;

end.
