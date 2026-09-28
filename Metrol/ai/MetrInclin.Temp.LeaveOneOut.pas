unit MetrInclin.Temp.LeaveOneOut;

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections;

type
  { Degrees of the temperature polynomials used by one candidate model.
    The runner does not interpret these values. It only passes the selected
    model to IValidationModelAdapter.SetModel before fitting every fold. }
  TTemperatureModel = record
    AxDegree: Integer;
    KuDegree: Integer;
    DzDegree: Integer;
    class function Create(AAx, AKu, ADz: Integer): TTemperatureModel; static;
    function Name: string;
  end;

  { A validation scheme describes WHY a group of rows was hidden.

    vkLeaveSeriesOut
      A complete temperature acquisition series is hidden (classic LOTO).

    vkLeaveTemperatureBandOut
      All rows in a temperature interval are hidden (LTBO).

    vkLeaveOrientationGroupOut
      A spatial group of orientations is hidden. }
  TValidationKind = (
    vkLeaveSeriesOut,
    vkLeaveTemperatureBandOut,
    vkLeaveOrientationGroupOut,

    { Strict combined stress test. The test set is the UNION of a complete
      temperature band and a complete spatial group. Training contains only
      rows satisfying neither condition. }
    vkLeaveTemperatureBandOrOrientationOut
  );

  { Lightweight description of one source row.

    SourceIndex is the stable index understood by the model adapter. The
    runner never assumes that SourceIndex equals the position in Samples.

    OrientationGroup is prepared by the caller. For example, orientations can
    be divided by zenith rings, by equal-area spherical cells, or by a stable
    hash of the reference (azimuth, zenith, toolface) tuple. A value below zero
    means that the row does not participate in spatial folds. }
  TValidationSample = record
    SetNo: Integer;
    Temperature: Double;
    SourceIndex: Integer;
    OrientationGroup: Integer;
    class function Create(ASetNo: Integer; ATemperature: Double;
      ASourceIndex: Integer; AOrientationGroup: Integer = -1):
      TValidationSample; static;
  end;

  { One explicit train/test split.

    The important design rule is that the adapter receives TrainingIndices
    and therefore does not need to know whether the fold came from LOTO, LTBO,
    or spatial validation. }
  TValidationFold = record
    Kind: TValidationKind;
    Name: string;
    TrainingIndices: TArray<Integer>;
    TestIndices: TArray<Integer>;
    TestTemperatureMin: Double;
    TestTemperatureMax: Double;
  end;

  { Candidate temperature interval for LTBO analysis.

    Bounds use the same convention as the remaining validation code:
    BandLow is inclusive and BandHigh is exclusive, [BandLow, BandHigh). }
  TLtboBandCandidate = record
    BandLow: Double;
    BandHigh: Double;
    Name: string;
    class function Create(ALow, AHigh: Double;
      const AName: string = ''): TLtboBandCandidate; static;
  end;

  { Rules used when candidate LTBO intervals are checked against real data.

    EmbargoWidth removes measurements immediately adjacent to both test-band
    boundaries. These rows are neither training nor test rows.

    RequireTrainingOnBothSides keeps LTBO an interpolation test. If it is
    False, a boundary interval can be accepted, but that fold is then a
    temperature extrapolation experiment and should be reported separately. }
  TLtboBuildOptions = record
    EmbargoWidth: Double;
    MinTestCount: Integer;
    MinTrainingCountPerSide: Integer;
    RequireTrainingOnBothSides: Boolean;
    class function Default: TLtboBuildOptions; static;
  end;

  TLtboBandDecision = (
    lbdAccepted,
    lbdTooFewTestRows,
    lbdNoTrainingRows,
    lbdTooFewTrainingRowsBelow,
    lbdTooFewTrainingRowsAbove
  );

  { Diagnostic result for every requested candidate interval.

    Analysis has one item per candidate even when no fold was created. This
    makes physical gaps such as 65..75 C visible instead of silently hiding
    them from the validation report. }
  TLtboBandAnalysis = record
    Candidate: TLtboBandCandidate;
    Decision: TLtboBandDecision;
    Reason: string;
    TestCount: Integer;
    EmbargoCount: Integer;
    TrainingCountBelow: Integer;
    TrainingCountAbove: Integer;
    function Accepted: Boolean;
  end;

  { Rules for leave-orientation-group-out (LOGO) validation.

    A test fold contains every row of one OrientationGroup at every available
    temperature and in every acquisition series. Thus the fitted model has
    never seen the hidden spatial region.

    Rows with OrientationGroup < 0 cannot be checked for spatial leakage.
    By default they are excluded from both training and test sets. Set
    IncludeUngroupedInTraining only when the caller can guarantee that these
    rows do not belong to the hidden orientation group. }
  TLogoBuildOptions = record
    MinTestCount: Integer;
    MinTestSeriesCount: Integer;
    MinTrainingCount: Integer;
    MinTrainingGroupCount: Integer;
    IncludeUngroupedInTraining: Boolean;
    class function Default: TLogoBuildOptions; static;
  end;

  TLogoGroupDecision = (
    lgdAccepted,
    lgdTooFewTestRows,
    lgdTooFewTestSeries,
    lgdTooFewTrainingRows,
    lgdTooFewTrainingGroups
  );

  { One diagnostic item is returned for every non-negative group found in the
    input. Rejected groups are therefore visible to the report instead of
    silently disappearing from validation. }
  TLogoGroupAnalysis = record
    { Human-readable spatial region. The numeric id is only unique inside one
      grouping scheme, while GroupName also identifies the scheme. }
    GroupName: string;
    OrientationGroup: Integer;
    Decision: TLogoGroupDecision;
    Reason: string;
    TestCount: Integer;
    TestSeriesCount: Integer;
    TrainingCount: Integer;
    TrainingGroupCount: Integer;
    UngroupedExcludedCount: Integer;
    TestTemperatureMin: Double;
    TestTemperatureMax: Double;
    function Accepted: Boolean;
  end;

  { Rules for leave-one-temperature-series-out (LOTO) validation.

    Every non-negative SetNo is treated as one indivisible acquisition
    series. All its rows form the test set; no row of that SetNo may remain in
    training, irrespective of its temperature or orientation.

    Rows with SetNo < 0 have unknown series membership. They are excluded by
    default because they could belong to the hidden series. Enable
    IncludeUnknownSeriesInTraining only when the caller can prove otherwise. }
  TLotoBuildOptions = record
    MinTestCount: Integer;
    MinTrainingCount: Integer;
    MinTrainingSeriesCount: Integer;
    IncludeUnknownSeriesInTraining: Boolean;
    class function Default: TLotoBuildOptions; static;
  end;

  TLotoSeriesDecision = (
    lsdAccepted,
    lsdTooFewTestRows,
    lsdTooFewTrainingRows,
    lsdTooFewTrainingSeries
  );

  { One item is returned for every known SetNo, including rejected series.
    Counts below/above use the actual test-temperature interval. They are
    diagnostic only: an edge series is a legitimate extrapolation test and is
    therefore not rejected merely because one of these counts is zero. }
  TLotoSeriesAnalysis = record
    SetNo: Integer;
    Decision: TLotoSeriesDecision;
    Reason: string;
    TestCount: Integer;
    TrainingCount: Integer;
    TrainingSeriesCount: Integer;
    UnknownSeriesExcludedCount: Integer;
    TrainingCountBelow: Integer;
    TrainingCountAbove: Integer;
    TestTemperatureMin: Double;
    TestTemperatureMax: Double;
    TrainingTemperatureMin: Double;
    TrainingTemperatureMax: Double;
    function Accepted: Boolean;
  end;

  { One signed error retained together with its source row.  Keeping this
    mapping makes it possible to diagnose every threshold exceedance instead
    of reporting only an anonymous percentile or maximum. }
  TValidationErrorPoint = record
    SourceIndex: Integer;
    SignedError: Double;
  end;

  { Aggregated values for one error metric.

    NaN returned by the adapter means "metric is not defined for this row".
    This is useful for azimuth near the vertical. Such a row is ignored only
    for that metric; all other metrics are still accumulated. }
  TValidationMetric = record
    MaxAbs: Double;
    MeanSigned: Double;
    MeanAbs: Double;
    RMS: Double;
    Percentile95: Double;
    PeakSigned: Double;
    PeakSourceIndex: Integer;
    Count: Integer;

    { Internal accumulators are kept in the record so summaries can merge
      folds without losing the correct MeanAbs and RMS denominators. }
    SignedSum: Double;
    AbsSum: Double;
    SquareSum: Double;
    AbsValues: TArray<Double>;
    ErrorPoints: TArray<TValidationErrorPoint>;
  end;

  { Results for one model and one fold.

    Metrics contains every test row. InterpolationMetrics and
    ExtrapolationMetrics additionally split rows point-by-point relative to
    the actual temperature range of the training rows. This is more accurate
    than labelling an entire series from its mean temperature. }
  TValidationFoldResult = record
    Model: TTemperatureModel;
    Kind: TValidationKind;
    FoldName: string;
    TrainingCount: Integer;
    TestCount: Integer;
    InterpolationTestCount: Integer;
    ExtrapolationTestCount: Integer;
    TrainingTemperatureMin: Double;
    TrainingTemperatureMax: Double;
    TestTemperatureMin: Double;
    TestTemperatureMax: Double;
    Metrics: TArray<TValidationMetric>;
    InterpolationMetrics: TArray<TValidationMetric>;
    ExtrapolationMetrics: TArray<TValidationMetric>;
  end;

  { Summary for one candidate model. The three validation kinds are deliberately
    not mixed: a good LOTO result must not hide a bad LTBO, spatial, or
    combined temperature-band OR orientation-group result. }
  TValidationKindSummary = record
    Kind: TValidationKind;
    Metrics: TArray<TValidationMetric>;
    InterpolationMetrics: TArray<TValidationMetric>;
    ExtrapolationMetrics: TArray<TValidationMetric>;
  end;

  TValidationSummary = record
    Model: TTemperatureModel;
    ByKind: TArray<TValidationKindSummary>;
  end;

  { The fitted object is deliberately opaque to the runner.

    Fit receives the exact training rows. Errors evaluates one source row and
    returns errors in exactly the same order as MetricNames.

    Errors may return NaN for a metric which is physically undefined at the
    current orientation. It must never return Infinity. }
  IValidationModelAdapter = interface
    ['{A97D83D6-E359-47B4-9F6A-E44C5EAC8D37}']
    function MetricNames: TArray<string>;
    procedure SetModel(const Model: TTemperatureModel);
    function Fit(const TrainingIndices: TArray<Integer>): IInterface;
    function Errors(const FittedModel: IInterface;
      SourceIndex: Integer): TArray<Double>;
  end;

  { Creates the three independent families of train/test splits. }
  TValidationFoldBuilder = class
  strict private
    class procedure ValidateSamples(const Samples: TArray<TValidationSample>);
      static;
    class function BuildFold(const Samples: TArray<TValidationSample>;
      const TestIndices: TArray<Integer>; AKind: TValidationKind;
      const AName: string): TValidationFold; static;
  public
    { Builds a fold from explicit, disjoint training and test SourceIndex
      arrays. The method validates unknown and duplicate indices. }
    class function BuildExplicitFold(
      const Samples: TArray<TValidationSample>;
      const TrainingIndices, TestIndices: TArray<Integer>;
      AKind: TValidationKind; const AName: string): TValidationFold; static;

    { Analyzes the actual SetNo distribution and creates only usable LOTO
      folds. A complete series is hidden across all of its temperatures and
      orientations. Edge-temperature series remain valid because the runner
      reports interpolation and extrapolation separately. }
    class function AnalyzeSeries(
      const Samples: TArray<TValidationSample>;
      const Options: TLotoBuildOptions;
      out Analysis: TArray<TLotoSeriesAnalysis>): TArray<TValidationFold>;
      static;

    { Recommended LOTO settings plus diagnostics for every known series. }
    class function LeaveSeriesOut(
      const Samples: TArray<TValidationSample>;
      out Analysis: TArray<TLotoSeriesAnalysis>): TArray<TValidationFold>;
      overload; static;

    { Compatibility overload. It uses TLotoBuildOptions.Default and discards
      diagnostics. }
    class function LeaveSeriesOut(
      const Samples: TArray<TValidationSample>): TArray<TValidationFold>;
      overload; static;

    { Legacy low-level helper for one exact band. Upper bound is exclusive.
      It does not apply an embargo or density checks. Prefer
      AnalyzeTemperatureBands for production LTBO validation. }
    class function LeaveTemperatureBandOut(
      const Samples: TArray<TValidationSample>; BandLow, BandHigh: Double;
      const AName: string = ''): TValidationFold; static;

    { Legacy low-level fixed-width sweep. Empty bands are omitted, but sparse
      bands, boundary extrapolation and embargo are not checked. Prefer
      AnalyzeTemperatureBands for production LTBO validation. }
    class function LeaveTemperatureBandsOut(
      const Samples: TArray<TValidationSample>; FirstLow, LastHigh,
      BandWidth: Double): TArray<TValidationFold>; static;

    { Returns the four physically useful candidate bands proposed for the
      current acquisition program. AnalyzeTemperatureBands still validates
      them against Samples; no candidate is accepted merely because it occurs
      in this list. }
    class function RecommendedTemperatureBands:
      TArray<TLtboBandCandidate>; static;

    { Analyzes candidate bands against the actual temperature distribution and
      creates only statistically usable LTBO folds.

      Test rows:       BandLow <= T < BandHigh
      Lower embargo:   BandLow-EmbargoWidth <= T < BandLow
      Upper embargo:   BandHigh <= T < BandHigh+EmbargoWidth
      Training rows:   all remaining rows

      The returned Analysis explains why each rejected candidate was skipped. }
    class function AnalyzeTemperatureBands(
      const Samples: TArray<TValidationSample>;
      const Candidates: TArray<TLtboBandCandidate>;
      const Options: TLtboBuildOptions;
      out Analysis: TArray<TLtboBandAnalysis>): TArray<TValidationFold>;
      static;

    { Convenience overload for the current data: recommended bands, 2 C
      embargo and the remaining defaults from TLtboBuildOptions.Default. }
    class function LeaveRecommendedTemperatureBandsOut(
      const Samples: TArray<TValidationSample>;
      out Analysis: TArray<TLtboBandAnalysis>): TArray<TValidationFold>;
      static;

    { Analyzes the actual group distribution and creates only usable spatial
      folds. For a group G:

        test      = all rows with OrientationGroup = G;
        training  = all rows with another non-negative group;
        excluded  = rows with OrientationGroup < 0 (by default).

      The whole group is hidden across all temperatures and SetNo values. }
    class function AnalyzeOrientationGroups(
      const Samples: TArray<TValidationSample>;
      const Options: TLogoBuildOptions;
      out Analysis: TArray<TLogoGroupAnalysis>): TArray<TValidationFold>;
      static;

    { Recommended LOGO settings plus diagnostics for every source group. }
    class function LeaveOrientationGroupsOut(
      const Samples: TArray<TValidationSample>;
      out Analysis: TArray<TLogoGroupAnalysis>): TArray<TValidationFold>;
      overload; static;

    { Compatibility overload. It uses TLogoBuildOptions.Default and discards
      diagnostics. New code should normally call the overload above. }
    class function LeaveOrientationGroupsOut(
      const Samples: TArray<TValidationSample>): TArray<TValidationFold>;
      overload; static;
  end;

  { Common runner for LOTO, LTBO and spatial validation. }
  TValidationRunner = class
  strict private
    procedure AddError(var Metric: TValidationMetric; Error: Double;
      SourceIndex: Integer);
    procedure FinalizeMetric(var Metric: TValidationMetric);
    procedure MergeMetric(var Target: TValidationMetric;
      const Source: TValidationMetric);
    class function SameModel(const A, B: TTemperatureModel): Boolean; static;
  public
    function Run(const Samples: TArray<TValidationSample>;
      const Folds: TArray<TValidationFold>;
      const Models: TArray<TTemperatureModel>;
      const Adapter: IValidationModelAdapter): TArray<TValidationFoldResult>;

    function Summarize(const FoldResults: TArray<TValidationFoldResult>;
      const Models: TArray<TTemperatureModel>): TArray<TValidationSummary>;
  end;

  { Compatibility aliases. Existing declarations can be migrated gradually,
    but calls to Fit and Run must use the new explicit-index signatures. }
  TLotoSample = TValidationSample;
  TLotoMetric = TValidationMetric;
  TLotoFoldResult = TValidationFoldResult;
  TLotoSummary = TValidationSummary;
  ILotoModelAdapter = IValidationModelAdapter;
  TLotoRunner = TValidationRunner;

implementation

class function TTemperatureModel.Create(AAx, AKu,
  ADz: Integer): TTemperatureModel;
begin
  Result.AxDegree := AAx;
  Result.KuDegree := AKu;
  Result.DzDegree := ADz;
end;

function TTemperatureModel.Name: string;
begin
  Result := Format('%d:%d:%d', [AxDegree, KuDegree, DzDegree]);
end;

class function TLtboBandCandidate.Create(ALow, AHigh: Double;
  const AName: string): TLtboBandCandidate;
begin
  Result.BandLow := ALow;
  Result.BandHigh := AHigh;
  Result.Name := AName;
end;

class function TLtboBuildOptions.Default: TLtboBuildOptions;
begin
  { Ten rows prevent a nearly empty interval from being called a validation
    fold. The same minimum is required below and above the band, so a fold is
    not accepted because of one accidental boundary measurement. Raise these
    values when one complete orientation program contains more observations. }
  Result.EmbargoWidth := 2.0;
  Result.MinTestCount := 10;
  Result.MinTrainingCountPerSide := 10;
  Result.RequireTrainingOnBothSides := True;
end;

function TLtboBandAnalysis.Accepted: Boolean;
begin
  Result := Decision = lbdAccepted;
end;

class function TLogoBuildOptions.Default: TLogoBuildOptions;
begin
  { Usually one orientation is measured once in each temperature series.
    Therefore ten rows is not a valid universal minimum: a normal experiment
    with five series has only five rows in one LOGO test group. Two rows plus
    the independent MinTestSeriesCount=2 requirement reject a singleton while
    accepting an orientation repeated across temperature series. }
  Result.MinTestCount := 2;
  Result.MinTestSeriesCount := 2;
  Result.MinTrainingCount := 20;
  Result.MinTrainingGroupCount := 2;
  Result.IncludeUngroupedInTraining := False;
end;

function TLogoGroupAnalysis.Accepted: Boolean;
begin
  Result := Decision = lgdAccepted;
end;

class function TLotoBuildOptions.Default: TLotoBuildOptions;
begin
  { Ten test rows avoid reporting a series represented by only a few repeated
    samples. Two remaining independent series and twenty rows provide a
    minimal meaningful fit. Increase these limits when one acquisition series
    contains a complete and substantially larger orientation program. }
  Result.MinTestCount := 10;
  Result.MinTrainingCount := 20;
  Result.MinTrainingSeriesCount := 2;
  Result.IncludeUnknownSeriesInTraining := False;
end;

function TLotoSeriesAnalysis.Accepted: Boolean;
begin
  Result := Decision = lsdAccepted;
end;

class function TValidationSample.Create(ASetNo: Integer; ATemperature: Double;
  ASourceIndex, AOrientationGroup: Integer): TValidationSample;
begin
  Result.SetNo := ASetNo;
  Result.Temperature := ATemperature;
  Result.SourceIndex := ASourceIndex;
  Result.OrientationGroup := AOrientationGroup;
end;

class procedure TValidationFoldBuilder.ValidateSamples(
  const Samples: TArray<TValidationSample>);
var
  Seen: TDictionary<Integer, Byte>;
  S: TValidationSample;
begin
  if Length(Samples) = 0 then
    raise EArgumentException.Create('Validation requires at least one sample');

  Seen := TDictionary<Integer, Byte>.Create;
  try
    for S in Samples do
    begin
      if S.SourceIndex < 0 then
        raise EArgumentOutOfRangeException.CreateFmt(
          'SourceIndex=%d must be non-negative', [S.SourceIndex]);
      if IsNan(S.Temperature) or IsInfinite(S.Temperature) then
        raise EInvalidOpException.CreateFmt(
          'Invalid temperature for source row %d', [S.SourceIndex]);
      if Seen.ContainsKey(S.SourceIndex) then
        raise EArgumentException.CreateFmt(
          'Duplicate SourceIndex=%d', [S.SourceIndex]);
      Seen.Add(S.SourceIndex, 0);
    end;
  finally
    Seen.Free;
  end;
end;

class function TValidationFoldBuilder.BuildFold(
  const Samples: TArray<TValidationSample>;
  const TestIndices: TArray<Integer>; AKind: TValidationKind;
  const AName: string): TValidationFold;
var
  TestSet: TDictionary<Integer, Byte>;
  Training: TList<Integer>;
  TestTemperatureFound: Boolean;
  S: TValidationSample;
  SourceIndex: Integer;
begin
  if Length(TestIndices) = 0 then
    raise EArgumentException.CreateFmt('%s: test set is empty', [AName]);

  TestSet := TDictionary<Integer, Byte>.Create;
  Training := TList<Integer>.Create;
  try
    for SourceIndex in TestIndices do
    begin
      if TestSet.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: duplicate test SourceIndex=%d', [AName, SourceIndex]);
      TestSet.Add(SourceIndex, 0);
    end;

    Result.Kind := AKind;
    Result.Name := AName;
    Result.TestIndices := Copy(TestIndices, 0, Length(TestIndices));
    Result.TestTemperatureMin := MaxDouble;
    Result.TestTemperatureMax := -MaxDouble;
    TestTemperatureFound := False;

    for S in Samples do
      if TestSet.ContainsKey(S.SourceIndex) then
      begin
        Result.TestTemperatureMin := Min(Result.TestTemperatureMin,
          S.Temperature);
        Result.TestTemperatureMax := Max(Result.TestTemperatureMax,
          S.Temperature);
        TestTemperatureFound := True;
      end
      else
        Training.Add(S.SourceIndex);

    if not TestTemperatureFound then
      raise EArgumentException.CreateFmt(
        '%s: test indices do not occur in Samples', [AName]);
    if Training.Count = 0 then
      raise EArgumentException.CreateFmt('%s: training set is empty', [AName]);

    Result.TrainingIndices := Training.ToArray;
  finally
    Training.Free;
    TestSet.Free;
  end;
end;

class function TValidationFoldBuilder.BuildExplicitFold(
  const Samples: TArray<TValidationSample>;
  const TrainingIndices, TestIndices: TArray<Integer>;
  AKind: TValidationKind; const AName: string): TValidationFold;
var
  Known, TrainingSet, TestSet: TDictionary<Integer, Byte>;
  S: TValidationSample;
  SourceIndex: Integer;
begin
  if Length(TrainingIndices) = 0 then
    raise EArgumentException.CreateFmt('%s: training set is empty', [AName]);
  if Length(TestIndices) = 0 then
    raise EArgumentException.CreateFmt('%s: test set is empty', [AName]);

  Known := TDictionary<Integer, Byte>.Create;
  TrainingSet := TDictionary<Integer, Byte>.Create;
  TestSet := TDictionary<Integer, Byte>.Create;
  try
    for S in Samples do
      Known.Add(S.SourceIndex, 0);

    for SourceIndex in TrainingIndices do
    begin
      if not Known.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: unknown training SourceIndex=%d', [AName, SourceIndex]);
      if TrainingSet.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: duplicate training SourceIndex=%d', [AName, SourceIndex]);
      TrainingSet.Add(SourceIndex, 0);
    end;

    for SourceIndex in TestIndices do
    begin
      if not Known.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: unknown test SourceIndex=%d', [AName, SourceIndex]);
      if TestSet.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: duplicate test SourceIndex=%d', [AName, SourceIndex]);
      if TrainingSet.ContainsKey(SourceIndex) then
        raise EArgumentException.CreateFmt(
          '%s: SourceIndex=%d occurs in both training and test sets',
          [AName, SourceIndex]);
      TestSet.Add(SourceIndex, 0);
    end;

    Result.Kind := AKind;
    Result.Name := AName;
    Result.TrainingIndices := Copy(TrainingIndices, 0,
      Length(TrainingIndices));
    Result.TestIndices := Copy(TestIndices, 0, Length(TestIndices));
    Result.TestTemperatureMin := MaxDouble;
    Result.TestTemperatureMax := -MaxDouble;

    for S in Samples do
      if TestSet.ContainsKey(S.SourceIndex) then
      begin
        Result.TestTemperatureMin := Min(Result.TestTemperatureMin,
          S.Temperature);
        Result.TestTemperatureMax := Max(Result.TestTemperatureMax,
          S.Temperature);
      end;
  finally
    TestSet.Free;
    TrainingSet.Free;
    Known.Free;
  end;
end;

class function TValidationFoldBuilder.AnalyzeSeries(
  const Samples: TArray<TValidationSample>;
  const Options: TLotoBuildOptions;
  out Analysis: TArray<TLotoSeriesAnalysis>): TArray<TValidationFold>;
var
  Sets: TList<Integer>;
  Folds: TList<TValidationFold>;
  Training, Test: TList<Integer>;
  TrainingSets: TDictionary<Integer, Byte>;
  S: TValidationSample;
  SetNo: Integer;
  Item: TLotoSeriesAnalysis;
begin
  ValidateSamples(Samples);

  if Options.MinTestCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTestCount must be at least one');
  if Options.MinTrainingCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingCount must be at least one');
  if Options.MinTrainingSeriesCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingSeriesCount must be at least one');

  Sets := TList<Integer>.Create;
  Folds := TList<TValidationFold>.Create;
  Training := TList<Integer>.Create;
  Test := TList<Integer>.Create;
  TrainingSets := TDictionary<Integer, Byte>.Create;
  try
    for S in Samples do
      if (S.SetNo >= 0) and not Sets.Contains(S.SetNo) then
        Sets.Add(S.SetNo);
    Sets.Sort;

    if Sets.Count < 2 then
      raise EArgumentException.Create(
        'Leave-series-out requires at least two series');

    SetLength(Analysis, Sets.Count);
    for var I := 0 to Sets.Count - 1 do
    begin
      SetNo := Sets[I];
      Training.Clear;
      Test.Clear;
      TrainingSets.Clear;
      Item := Default(TLotoSeriesAnalysis);
      Item.SetNo := SetNo;
      Item.TestTemperatureMin := MaxDouble;
      Item.TestTemperatureMax := -MaxDouble;
      Item.TrainingTemperatureMin := MaxDouble;
      Item.TrainingTemperatureMax := -MaxDouble;

      for S in Samples do
        if S.SetNo = SetNo then
        begin
          Test.Add(S.SourceIndex);
          Inc(Item.TestCount);
          Item.TestTemperatureMin := Min(Item.TestTemperatureMin,
            S.Temperature);
          Item.TestTemperatureMax := Max(Item.TestTemperatureMax,
            S.Temperature);
        end
        else if S.SetNo >= 0 then
        begin
          Training.Add(S.SourceIndex);
          Inc(Item.TrainingCount);
          Item.TrainingTemperatureMin := Min(Item.TrainingTemperatureMin,
            S.Temperature);
          Item.TrainingTemperatureMax := Max(Item.TrainingTemperatureMax,
            S.Temperature);
          if not TrainingSets.ContainsKey(S.SetNo) then
            TrainingSets.Add(S.SetNo, 0);
        end
        else if Options.IncludeUnknownSeriesInTraining then
        begin
          Training.Add(S.SourceIndex);
          Inc(Item.TrainingCount);
          Item.TrainingTemperatureMin := Min(Item.TrainingTemperatureMin,
            S.Temperature);
          Item.TrainingTemperatureMax := Max(Item.TrainingTemperatureMax,
            S.Temperature);
        end
        else
          Inc(Item.UnknownSeriesExcludedCount);

      Item.TrainingSeriesCount := TrainingSets.Count;
      for S in Samples do
        if (S.SetNo <> SetNo) and
           ((S.SetNo >= 0) or Options.IncludeUnknownSeriesInTraining) then
        begin
          if S.Temperature < Item.TestTemperatureMin then
            Inc(Item.TrainingCountBelow);
          if S.Temperature > Item.TestTemperatureMax then
            Inc(Item.TrainingCountAbove);
        end;

      if Item.TestCount < Options.MinTestCount then
      begin
        Item.Decision := lsdTooFewTestRows;
        Item.Reason := Format('test rows: %d; required: %d',
          [Item.TestCount, Options.MinTestCount]);
      end
      else if Item.TrainingCount < Options.MinTrainingCount then
      begin
        Item.Decision := lsdTooFewTrainingRows;
        Item.Reason := Format('training rows: %d; required: %d',
          [Item.TrainingCount, Options.MinTrainingCount]);
      end
      else if Item.TrainingSeriesCount < Options.MinTrainingSeriesCount then
      begin
        Item.Decision := lsdTooFewTrainingSeries;
        Item.Reason := Format('remaining training series: %d; required: %d',
          [Item.TrainingSeriesCount, Options.MinTrainingSeriesCount]);
      end
      else
      begin
        Item.Decision := lsdAccepted;
        Item.Reason := 'accepted';
        Folds.Add(BuildExplicitFold(Samples, Training.ToArray, Test.ToArray,
          vkLeaveSeriesOut, Format('LOTO SetNo=%d', [SetNo])));
      end;

      Analysis[I] := Item;
    end;

    Result := Folds.ToArray;
  finally
    TrainingSets.Free;
    Test.Free;
    Training.Free;
    Folds.Free;
    Sets.Free;
  end;
end;

class function TValidationFoldBuilder.LeaveSeriesOut(
  const Samples: TArray<TValidationSample>;
  out Analysis: TArray<TLotoSeriesAnalysis>): TArray<TValidationFold>;
var
  Options: TLotoBuildOptions;
begin
  Options := TLotoBuildOptions.Default;
  Result := AnalyzeSeries(Samples, Options, Analysis);
end;

class function TValidationFoldBuilder.LeaveSeriesOut(
  const Samples: TArray<TValidationSample>): TArray<TValidationFold>;
var
  Analysis: TArray<TLotoSeriesAnalysis>;
begin
  Result := LeaveSeriesOut(Samples, Analysis);
end;

class function TValidationFoldBuilder.LeaveTemperatureBandOut(
  const Samples: TArray<TValidationSample>; BandLow, BandHigh: Double;
  const AName: string): TValidationFold;
var
  Test: TList<Integer>;
  S: TValidationSample;
  FoldName: string;
begin
  ValidateSamples(Samples);
  if IsNan(BandLow) or IsInfinite(BandLow) or
     IsNan(BandHigh) or IsInfinite(BandHigh) or
     (BandHigh <= BandLow) then
    raise EArgumentException.Create(
      'Temperature band must satisfy finite BandLow < BandHigh');

  if AName <> '' then
    FoldName := AName
  else
    FoldName := Format('LTBO [%.3f, %.3f)', [BandLow, BandHigh]);

  Test := TList<Integer>.Create;
  try
    for S in Samples do
      if (S.Temperature >= BandLow) and (S.Temperature < BandHigh) then
        Test.Add(S.SourceIndex);
    Result := BuildFold(Samples, Test.ToArray,
      vkLeaveTemperatureBandOut, FoldName);
  finally
    Test.Free;
  end;
end;

class function TValidationFoldBuilder.LeaveTemperatureBandsOut(
  const Samples: TArray<TValidationSample>; FirstLow, LastHigh,
  BandWidth: Double): TArray<TValidationFold>;
var
  Folds: TList<TValidationFold>;
  Test: TList<Integer>;
  LowT, HighT: Double;
  S: TValidationSample;
begin
  ValidateSamples(Samples);
  if IsNan(BandWidth) or IsInfinite(BandWidth) or (BandWidth <= 0) then
    raise EArgumentException.Create('BandWidth must be finite and positive');
  if LastHigh <= FirstLow then
    raise EArgumentException.Create('LastHigh must be greater than FirstLow');

  Folds := TList<TValidationFold>.Create;
  Test := TList<Integer>.Create;
  try
    LowT := FirstLow;
    while LowT < LastHigh do
    begin
      HighT := Min(LowT + BandWidth, LastHigh);
      Test.Clear;
      for S in Samples do
        if (S.Temperature >= LowT) and (S.Temperature < HighT) then
          Test.Add(S.SourceIndex);

      { Empty physical gaps are not validation folds: there is nothing to test. }
      if Test.Count > 0 then
        Folds.Add(BuildFold(Samples, Test.ToArray,
          vkLeaveTemperatureBandOut,
          Format('LTBO [%.3f, %.3f)', [LowT, HighT])));
      LowT := HighT;
    end;
    Result := Folds.ToArray;
  finally
    Test.Free;
    Folds.Free;
  end;
end;

class function TValidationFoldBuilder.RecommendedTemperatureBands:
  TArray<TLtboBandCandidate>;
begin
  SetLength(Result, 4);
  Result[0] := TLtboBandCandidate.Create(82.0, 88.0, 'LTBO 82-88 C');
  Result[1] := TLtboBandCandidate.Create(88.0, 94.0, 'LTBO 88-94 C');
  Result[2] := TLtboBandCandidate.Create(110.0, 120.0, 'LTBO 110-120 C');
  Result[3] := TLtboBandCandidate.Create(120.0, 130.0, 'LTBO 120-130 C');
end;

class function TValidationFoldBuilder.AnalyzeTemperatureBands(
  const Samples: TArray<TValidationSample>;
  const Candidates: TArray<TLtboBandCandidate>;
  const Options: TLtboBuildOptions;
  out Analysis: TArray<TLtboBandAnalysis>): TArray<TValidationFold>;
var
  Folds: TList<TValidationFold>;
  Training, Test: TList<Integer>;
  Candidate: TLtboBandCandidate;
  S: TValidationSample;
  FoldName: string;
  LowerEmbargo, UpperEmbargo: Double;
  Item: TLtboBandAnalysis;
begin
  ValidateSamples(Samples);

  if IsNan(Options.EmbargoWidth) or IsInfinite(Options.EmbargoWidth) or
     (Options.EmbargoWidth < 0) then
    raise EArgumentException.Create(
      'EmbargoWidth must be finite and non-negative');
  if Options.MinTestCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTestCount must be at least one');
  if Options.MinTrainingCountPerSide < 0 then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingCountPerSide must be non-negative');
  if Options.RequireTrainingOnBothSides and
     (Options.MinTrainingCountPerSide < 1) then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingCountPerSide must be at least one when training on both sides is required');

  SetLength(Analysis, Length(Candidates));
  Folds := TList<TValidationFold>.Create;
  Training := TList<Integer>.Create;
  Test := TList<Integer>.Create;
  try
    for var CandidateIndex := 0 to High(Candidates) do
    begin
      Candidate := Candidates[CandidateIndex];
      if IsNan(Candidate.BandLow) or IsInfinite(Candidate.BandLow) or
         IsNan(Candidate.BandHigh) or IsInfinite(Candidate.BandHigh) or
         (Candidate.BandHigh <= Candidate.BandLow) then
        raise EArgumentException.CreateFmt(
          'Candidate %d must satisfy finite BandLow < BandHigh',
          [CandidateIndex]);

      Training.Clear;
      Test.Clear;
      Item := Default(TLtboBandAnalysis);
      Item.Candidate := Candidate;
      LowerEmbargo := Candidate.BandLow - Options.EmbargoWidth;
      UpperEmbargo := Candidate.BandHigh + Options.EmbargoWidth;

      for S in Samples do
      begin
        if (S.Temperature >= Candidate.BandLow) and
           (S.Temperature < Candidate.BandHigh) then
        begin
          Test.Add(S.SourceIndex);
          Inc(Item.TestCount);
        end
        else if ((S.Temperature >= LowerEmbargo) and
                 (S.Temperature < Candidate.BandLow)) or
                ((S.Temperature >= Candidate.BandHigh) and
                 (S.Temperature < UpperEmbargo)) then
          Inc(Item.EmbargoCount)
        else
        begin
          Training.Add(S.SourceIndex);
          if S.Temperature < LowerEmbargo then
            Inc(Item.TrainingCountBelow)
          else if S.Temperature >= UpperEmbargo then
            Inc(Item.TrainingCountAbove);
        end;
      end;

      if Item.TestCount < Options.MinTestCount then
      begin
        Item.Decision := lbdTooFewTestRows;
        Item.Reason := Format('test rows: %d; required: %d',
          [Item.TestCount, Options.MinTestCount]);
      end
      else if (Item.TrainingCountBelow + Item.TrainingCountAbove) = 0 then
      begin
        Item.Decision := lbdNoTrainingRows;
        Item.Reason := 'no training rows remain after test band and embargo';
      end
      else if Options.RequireTrainingOnBothSides and
              (Item.TrainingCountBelow <
               Options.MinTrainingCountPerSide) then
      begin
        Item.Decision := lbdTooFewTrainingRowsBelow;
        Item.Reason := Format('training rows below band and embargo: %d; required: %d',
          [Item.TrainingCountBelow, Options.MinTrainingCountPerSide]);
      end
      else if Options.RequireTrainingOnBothSides and
              (Item.TrainingCountAbove <
               Options.MinTrainingCountPerSide) then
      begin
        Item.Decision := lbdTooFewTrainingRowsAbove;
        Item.Reason := Format('training rows above band and embargo: %d; required: %d',
          [Item.TrainingCountAbove, Options.MinTrainingCountPerSide]);
      end
      else
      begin
        Item.Decision := lbdAccepted;
        Item.Reason := 'accepted';
        if Candidate.Name <> '' then
          FoldName := Candidate.Name
        else
          FoldName := Format('LTBO [%.3f, %.3f)',
            [Candidate.BandLow, Candidate.BandHigh]);
        FoldName := Format('%s, embargo %.3f C',
          [FoldName, Options.EmbargoWidth]);
        Folds.Add(BuildExplicitFold(Samples, Training.ToArray, Test.ToArray,
          vkLeaveTemperatureBandOut, FoldName));
      end;

      Analysis[CandidateIndex] := Item;
    end;

    Result := Folds.ToArray;
  finally
    Test.Free;
    Training.Free;
    Folds.Free;
  end;
end;

class function TValidationFoldBuilder.LeaveRecommendedTemperatureBandsOut(
  const Samples: TArray<TValidationSample>;
  out Analysis: TArray<TLtboBandAnalysis>): TArray<TValidationFold>;
var
  Options: TLtboBuildOptions;
begin
  Options := TLtboBuildOptions.Default;
  Result := AnalyzeTemperatureBands(Samples,
    RecommendedTemperatureBands, Options, Analysis);
end;

class function TValidationFoldBuilder.AnalyzeOrientationGroups(
  const Samples: TArray<TValidationSample>;
  const Options: TLogoBuildOptions;
  out Analysis: TArray<TLogoGroupAnalysis>): TArray<TValidationFold>;
var
  Groups: TList<Integer>;
  Folds: TList<TValidationFold>;
  Training, Test: TList<Integer>;
  TestSeries, TrainingGroups: TDictionary<Integer, Byte>;
  S: TValidationSample;
  GroupNo: Integer;
  Item: TLogoGroupAnalysis;
begin
  ValidateSamples(Samples);

  if Options.MinTestCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTestCount must be at least one');
  if Options.MinTestSeriesCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTestSeriesCount must be at least one');
  if Options.MinTrainingCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingCount must be at least one');
  if Options.MinTrainingGroupCount < 1 then
    raise EArgumentOutOfRangeException.Create(
      'MinTrainingGroupCount must be at least one');

  Groups := TList<Integer>.Create;
  Folds := TList<TValidationFold>.Create;
  Training := TList<Integer>.Create;
  Test := TList<Integer>.Create;
  TestSeries := TDictionary<Integer, Byte>.Create;
  TrainingGroups := TDictionary<Integer, Byte>.Create;
  try
    for S in Samples do
      if (S.OrientationGroup >= 0) and
         not Groups.Contains(S.OrientationGroup) then
        Groups.Add(S.OrientationGroup);
    Groups.Sort;

    if Groups.Count < 2 then
      raise EArgumentException.Create(
        'Spatial validation requires at least two orientation groups');

    SetLength(Analysis, Groups.Count);
    for var GroupIndex := 0 to Groups.Count - 1 do
    begin
      GroupNo := Groups[GroupIndex];
      Training.Clear;
      Test.Clear;
      TestSeries.Clear;
      TrainingGroups.Clear;
      Item := Default(TLogoGroupAnalysis);
      Item.OrientationGroup := GroupNo;
      Item.GroupName := Format('Group=%d', [GroupNo]);
      Item.TestTemperatureMin := MaxDouble;
      Item.TestTemperatureMax := -MaxDouble;

      for S in Samples do
      begin
        if S.OrientationGroup = GroupNo then
        begin
          Test.Add(S.SourceIndex);
          Inc(Item.TestCount);
          Item.TestTemperatureMin := Min(Item.TestTemperatureMin,
            S.Temperature);
          Item.TestTemperatureMax := Max(Item.TestTemperatureMax,
            S.Temperature);
          { Negative SetNo means that the acquisition series is unknown and
            must not satisfy the independent-series requirement. }
          if (S.SetNo >= 0) and not TestSeries.ContainsKey(S.SetNo) then
            TestSeries.Add(S.SetNo, 0);
        end
        else if S.OrientationGroup >= 0 then
        begin
          Training.Add(S.SourceIndex);
          Inc(Item.TrainingCount);
          if not TrainingGroups.ContainsKey(S.OrientationGroup) then
            TrainingGroups.Add(S.OrientationGroup, 0);
        end
        else if Options.IncludeUngroupedInTraining then
        begin
          Training.Add(S.SourceIndex);
          Inc(Item.TrainingCount);
        end
        else
          Inc(Item.UngroupedExcludedCount);
      end;

      Item.TestSeriesCount := TestSeries.Count;
      Item.TrainingGroupCount := TrainingGroups.Count;

      if Item.TestCount < Options.MinTestCount then
      begin
        Item.Decision := lgdTooFewTestRows;
        Item.Reason := Format('test rows: %d; required: %d',
          [Item.TestCount, Options.MinTestCount]);
      end
      else if Item.TestSeriesCount < Options.MinTestSeriesCount then
      begin
        Item.Decision := lgdTooFewTestSeries;
        Item.Reason := Format('test series: %d; required: %d',
          [Item.TestSeriesCount, Options.MinTestSeriesCount]);
      end
      else if Item.TrainingCount < Options.MinTrainingCount then
      begin
        Item.Decision := lgdTooFewTrainingRows;
        Item.Reason := Format('training rows: %d; required: %d',
          [Item.TrainingCount, Options.MinTrainingCount]);
      end
      else if Item.TrainingGroupCount < Options.MinTrainingGroupCount then
      begin
        Item.Decision := lgdTooFewTrainingGroups;
        Item.Reason := Format('remaining training groups: %d; required: %d',
          [Item.TrainingGroupCount, Options.MinTrainingGroupCount]);
      end
      else
      begin
        Item.Decision := lgdAccepted;
        Item.Reason := 'accepted';
        Folds.Add(BuildExplicitFold(Samples, Training.ToArray, Test.ToArray,
          vkLeaveOrientationGroupOut,
          Format('LOGO OrientationGroup=%d', [GroupNo])));
      end;

      Analysis[GroupIndex] := Item;
    end;

    Result := Folds.ToArray;
  finally
    TrainingGroups.Free;
    TestSeries.Free;
    Test.Free;
    Training.Free;
    Folds.Free;
    Groups.Free;
  end;
end;

class function TValidationFoldBuilder.LeaveOrientationGroupsOut(
  const Samples: TArray<TValidationSample>;
  out Analysis: TArray<TLogoGroupAnalysis>): TArray<TValidationFold>;
var
  Options: TLogoBuildOptions;
begin
  Options := TLogoBuildOptions.Default;
  Result := AnalyzeOrientationGroups(Samples, Options, Analysis);
end;

class function TValidationFoldBuilder.LeaveOrientationGroupsOut(
  const Samples: TArray<TValidationSample>): TArray<TValidationFold>;
var
  Analysis: TArray<TLogoGroupAnalysis>;
begin
  Result := LeaveOrientationGroupsOut(Samples, Analysis);
end;

procedure TValidationRunner.AddError(var Metric: TValidationMetric;
  Error: Double; SourceIndex: Integer);
var
  A: Double;
  N: Integer;
begin
  { NaN is an explicit "not applicable" value, for example masked azimuth. }
  if IsNan(Error) then
    Exit;
  if IsInfinite(Error) then
    raise EInvalidOpException.CreateFmt(
      'Infinite error for source row %d', [SourceIndex]);

  A := Abs(Error);
  if (Metric.Count = 0) or (A > Metric.MaxAbs) then
  begin
    Metric.MaxAbs := A;
    Metric.PeakSigned := Error;
    Metric.PeakSourceIndex := SourceIndex;
  end;

  Metric.AbsSum := Metric.AbsSum + A;
  Metric.SignedSum := Metric.SignedSum + Error;
  Metric.SquareSum := Metric.SquareSum + Sqr(Error);
  N := Length(Metric.AbsValues);
  SetLength(Metric.AbsValues, N + 1);
  Metric.AbsValues[N] := A;
  SetLength(Metric.ErrorPoints, N + 1);
  Metric.ErrorPoints[N].SourceIndex := SourceIndex;
  Metric.ErrorPoints[N].SignedError := Error;
  Inc(Metric.Count);
end;

procedure TValidationRunner.FinalizeMetric(var Metric: TValidationMetric);
var
  Sorted: TArray<Double>;
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

  Sorted := Copy(Metric.AbsValues);
  TArray.Sort<Double>(Sorted);
  P95Index := Ceil(0.95 * Length(Sorted)) - 1;
  P95Index := EnsureRange(P95Index, 0, High(Sorted));
  Metric.Percentile95 := Sorted[P95Index];
end;

procedure TValidationRunner.MergeMetric(var Target: TValidationMetric;
  const Source: TValidationMetric);
var
  OldLength: Integer;
begin
  if Source.Count = 0 then
    Exit;

  if (Target.Count = 0) or (Source.MaxAbs > Target.MaxAbs) then
  begin
    Target.MaxAbs := Source.MaxAbs;
    Target.PeakSigned := Source.PeakSigned;
    Target.PeakSourceIndex := Source.PeakSourceIndex;
  end;

  Target.SignedSum := Target.SignedSum + Source.SignedSum;
  Target.AbsSum := Target.AbsSum + Source.AbsSum;
  Target.SquareSum := Target.SquareSum + Source.SquareSum;
  Inc(Target.Count, Source.Count);

  OldLength := Length(Target.AbsValues);
  SetLength(Target.AbsValues, OldLength + Length(Source.AbsValues));
  if Length(Source.AbsValues) > 0 then
    Move(Source.AbsValues[0], Target.AbsValues[OldLength],
      Length(Source.AbsValues) * SizeOf(Double));

  OldLength := Length(Target.ErrorPoints);
  SetLength(Target.ErrorPoints, OldLength + Length(Source.ErrorPoints));
  if Length(Source.ErrorPoints) > 0 then
    Move(Source.ErrorPoints[0], Target.ErrorPoints[OldLength],
      Length(Source.ErrorPoints) * SizeOf(TValidationErrorPoint));
end;

class function TValidationRunner.SameModel(const A,
  B: TTemperatureModel): Boolean;
begin
  Result := (A.AxDegree = B.AxDegree) and
            (A.KuDegree = B.KuDegree) and
            (A.DzDegree = B.DzDegree);
end;

function TValidationRunner.Run(const Samples: TArray<TValidationSample>;
  const Folds: TArray<TValidationFold>;
  const Models: TArray<TTemperatureModel>;
  const Adapter: IValidationModelAdapter): TArray<TValidationFoldResult>;
var
  SampleByIndex: TDictionary<Integer, TValidationSample>;
  MetricNames: TArray<string>;
  Fitted: IInterface;
  Errors: TArray<Double>;
  FoldResultIndex: Integer;
  TrainingMin, TrainingMax: Double;
  IsExtrapolation: Boolean;
  S: TValidationSample;
begin
  { Delphi may pass the caller's existing dynamic-array storage as the hidden
    function result.  Clear it before SetLength, otherwise managed fields in
    reused TValidationFoldResult elements retain metrics from earlier runs. }
  Result := nil;

  if Adapter = nil then
    raise EArgumentNilException.Create('Adapter');
  if Length(Samples) = 0 then
    raise EArgumentException.Create('Validation requires at least one sample');
  if Length(Folds) = 0 then
    raise EArgumentException.Create('Validation requires at least one fold');
  if Length(Models) = 0 then
    raise EArgumentException.Create('Validation requires at least one model');

  MetricNames := Adapter.MetricNames;
  if Length(MetricNames) = 0 then
    raise EArgumentException.Create(
      'Adapter must expose at least one metric');

  SampleByIndex := TDictionary<Integer, TValidationSample>.Create;
  try
    for S in Samples do
    begin
      if SampleByIndex.ContainsKey(S.SourceIndex) then
        raise EArgumentException.CreateFmt(
          'Duplicate SourceIndex=%d', [S.SourceIndex]);
      SampleByIndex.Add(S.SourceIndex, S);
    end;

    SetLength(Result, Length(Models) * Length(Folds));
    FoldResultIndex := 0;

    for var Model in Models do
    begin
      Adapter.SetModel(Model);
      for var Fold in Folds do
      begin
        Result[FoldResultIndex] := Default(TValidationFoldResult);

        if Length(Fold.TrainingIndices) = 0 then
          raise EArgumentException.CreateFmt(
            '%s: training set is empty', [Fold.Name]);
        if Length(Fold.TestIndices) = 0 then
          raise EArgumentException.CreateFmt(
            '%s: test set is empty', [Fold.Name]);

        TrainingMin := MaxDouble;
        TrainingMax := -MaxDouble;
        for var SourceIndex in Fold.TrainingIndices do
        begin
          if not SampleByIndex.TryGetValue(SourceIndex, S) then
            raise EArgumentException.CreateFmt(
              '%s: unknown training SourceIndex=%d',
              [Fold.Name, SourceIndex]);
          TrainingMin := Min(TrainingMin, S.Temperature);
          TrainingMax := Max(TrainingMax, S.Temperature);
        end;

        Fitted := Adapter.Fit(Fold.TrainingIndices);
        if Fitted = nil then
          raise EInvalidOpException.CreateFmt(
            'Fit returned nil for model %s, fold %s',
            [Model.Name, Fold.Name]);

        Result[FoldResultIndex].Model := Model;
        Result[FoldResultIndex].Kind := Fold.Kind;
        Result[FoldResultIndex].FoldName := Fold.Name;
        Result[FoldResultIndex].TrainingCount :=
          Length(Fold.TrainingIndices);
        Result[FoldResultIndex].TestCount := Length(Fold.TestIndices);
        Result[FoldResultIndex].TrainingTemperatureMin := TrainingMin;
        Result[FoldResultIndex].TrainingTemperatureMax := TrainingMax;
        Result[FoldResultIndex].TestTemperatureMin :=
          Fold.TestTemperatureMin;
        Result[FoldResultIndex].TestTemperatureMax :=
          Fold.TestTemperatureMax;
        SetLength(Result[FoldResultIndex].Metrics, Length(MetricNames));
        SetLength(Result[FoldResultIndex].InterpolationMetrics,
          Length(MetricNames));
        SetLength(Result[FoldResultIndex].ExtrapolationMetrics,
          Length(MetricNames));

        for var SourceIndex in Fold.TestIndices do
        begin
          if not SampleByIndex.TryGetValue(SourceIndex, S) then
            raise EArgumentException.CreateFmt(
              '%s: unknown test SourceIndex=%d', [Fold.Name, SourceIndex]);

          Errors := Adapter.Errors(Fitted, SourceIndex);
          if Length(Errors) <> Length(MetricNames) then
            raise EInvalidOpException.CreateFmt(
              'Adapter returned %d errors; expected %d for source row %d',
              [Length(Errors), Length(MetricNames), SourceIndex]);

          IsExtrapolation := (S.Temperature < TrainingMin) or
                            (S.Temperature > TrainingMax);
          if IsExtrapolation then
            Inc(Result[FoldResultIndex].ExtrapolationTestCount)
          else
            Inc(Result[FoldResultIndex].InterpolationTestCount);

          for var MetricIndex := 0 to High(Errors) do
          begin
            AddError(Result[FoldResultIndex].Metrics[MetricIndex],
              Errors[MetricIndex], SourceIndex);
            if IsExtrapolation then
              AddError(Result[FoldResultIndex].ExtrapolationMetrics[MetricIndex],
                Errors[MetricIndex], SourceIndex)
            else
              AddError(Result[FoldResultIndex].InterpolationMetrics[MetricIndex],
                Errors[MetricIndex], SourceIndex);
          end;
        end;

        for var MetricIndex := 0 to High(MetricNames) do
        begin
          FinalizeMetric(Result[FoldResultIndex].Metrics[MetricIndex]);
          FinalizeMetric(
            Result[FoldResultIndex].InterpolationMetrics[MetricIndex]);
          FinalizeMetric(
            Result[FoldResultIndex].ExtrapolationMetrics[MetricIndex]);
        end;

        Inc(FoldResultIndex);
      end;
    end;
  finally
    SampleByIndex.Free;
  end;
end;

function TValidationRunner.Summarize(
  const FoldResults: TArray<TValidationFoldResult>;
  const Models: TArray<TTemperatureModel>): TArray<TValidationSummary>;
var
  SummaryKind: TValidationKind;
  KindIndex: Integer;
begin
  SetLength(Result, Length(Models));
  for var ModelIndex := 0 to High(Models) do
  begin
    Result[ModelIndex].Model := Models[ModelIndex];
    SetLength(Result[ModelIndex].ByKind,
      Ord(High(TValidationKind)) - Ord(Low(TValidationKind)) + 1);

    for SummaryKind := Low(TValidationKind) to High(TValidationKind) do
    begin
      KindIndex := Ord(SummaryKind) - Ord(Low(TValidationKind));
      Result[ModelIndex].ByKind[KindIndex].Kind := SummaryKind;

      for var FoldResult in FoldResults do
        if SameModel(FoldResult.Model, Models[ModelIndex]) and
           (FoldResult.Kind = SummaryKind) then
        begin
          if Length(Result[ModelIndex].ByKind[KindIndex].Metrics) = 0 then
          begin
            SetLength(Result[ModelIndex].ByKind[KindIndex].Metrics,
              Length(FoldResult.Metrics));
            SetLength(Result[ModelIndex].ByKind[KindIndex].InterpolationMetrics,
              Length(FoldResult.Metrics));
            SetLength(Result[ModelIndex].ByKind[KindIndex].ExtrapolationMetrics,
              Length(FoldResult.Metrics));
          end;

          for var MetricIndex := 0 to High(FoldResult.Metrics) do
          begin
            MergeMetric(
              Result[ModelIndex].ByKind[KindIndex].Metrics[MetricIndex],
              FoldResult.Metrics[MetricIndex]);
            MergeMetric(
              Result[ModelIndex].ByKind[KindIndex].InterpolationMetrics[MetricIndex],
              FoldResult.InterpolationMetrics[MetricIndex]);
            MergeMetric(
              Result[ModelIndex].ByKind[KindIndex].ExtrapolationMetrics[MetricIndex],
              FoldResult.ExtrapolationMetrics[MetricIndex]);
          end;
        end;

      for var MetricIndex := 0 to
        High(Result[ModelIndex].ByKind[KindIndex].Metrics) do
      begin
        FinalizeMetric(
          Result[ModelIndex].ByKind[KindIndex].Metrics[MetricIndex]);
        FinalizeMetric(
          Result[ModelIndex].ByKind[KindIndex].InterpolationMetrics[MetricIndex]);
        FinalizeMetric(
          Result[ModelIndex].ByKind[KindIndex].ExtrapolationMetrics[MetricIndex]);
      end;
    end;
  end;
end;

end.
