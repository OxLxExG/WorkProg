unit TrrInclin.Temp.LinTrainingReport;

interface

uses
  System.SysUtils, System.Classes,
  TrrInclin.Temp.LinModel,
  MetrInclin.Temp.Stat, MetrInclin.Temp.MathPoly;

type
  TGkiLinTrainingReport = class
  public
    { Fits every requested main-node count on TrainingIndices, evaluates all
      candidates on all current InpData rows, selects with Zenith priority,
      and appends the complete diagnostics for the selected fit. }
    class function Run(const TrainingIndices: TArray<Integer>;
      const NodeCounts: array of Integer;
      const Huber: THuberIrlsOptions; OutRes: TStrings):
      TLinTemperatureNodeComparison; static;
  end;

implementation

class function TGkiLinTrainingReport.Run(
  const TrainingIndices: TArray<Integer>;
  const NodeCounts: array of Integer;
  const Huber: THuberIrlsOptions; OutRes: TStrings):
  TLinTemperatureNodeComparison;
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
  ErrorTolerance = 1E-12;
var
  TrainingInputs: TArray<TinclInput>;
  Variant: TLinTemperatureNodeVariantResult;
  Details: TStringList;
  NodeLine, MetricLine: string;

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

  function MaxAbsPassCount(
    const Metrics: TLinAllMetricsResult): Integer;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      if Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs <=
         ControlledMetricLimit[I] then
        Inc(Result);
  end;

  function OtherMaxAbsPassCount(
    const Metrics: TLinAllMetricsResult): Integer;
  begin
    Result := 0;
    for var I := 1 to ControlledMetricCount - 1 do
      if Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs <=
         ControlledMetricLimit[I] then
        Inc(Result);
  end;

  function NormalizedMaxError(
    const Metrics: TLinAllMetricsResult): Double;
  begin
    Result := 0;
    for var I := 0 to ControlledMetricCount - 1 do
      Result := Result +
        Metrics.Metrics[ControlledMetricIndex[I]].MaxAbs /
        ControlledMetricLimit[I];
    Result := Result / ControlledMetricCount;
  end;



  function IsBetter(
  const Candidate,
        Current: TLinTemperatureNodeVariantResult
): Boolean;
const
  ZenithTieTolerance = 0.005;
  AzimuthTieTolerance = 0.005;
  AccNormTieTolerance = 0.005;
var
  CandidateZenith, CurrentZenith: Double;
  CandidateAzimuth, CurrentAzimuth: Double;
  CandidateAccNorm, CurrentAccNorm: Double;
  CandidatePass, CurrentPass: Boolean;
  CandidateOtherPass, CurrentOtherPass: Integer;
begin
  { 1. Сходимость. }
  if Candidate.Converged <> Current.Converged then
    Exit(Candidate.Converged);

  { 2. Zenith PASS. }
  CandidateZenith := Candidate.Metrics.Metrics[0].MaxAbs;
  CurrentZenith := Current.Metrics.Metrics[0].MaxAbs;

  CandidatePass := CandidateZenith <= 0.150;
  CurrentPass := CurrentZenith <= 0.150;

  if CandidatePass <> CurrentPass then
    Exit(CandidatePass);

  { 3. Существенная разница Zenith. }
  if Abs(CandidateZenith - CurrentZenith) >
     ZenithTieTolerance then
    Exit(CandidateZenith < CurrentZenith);

  { 4. Azimuth — второй приоритет. }
  CandidateAzimuth := Candidate.Metrics.Metrics[1].MaxAbs;
  CurrentAzimuth := Current.Metrics.Metrics[1].MaxAbs;

  CandidatePass := CandidateAzimuth <= 1.000;
  CurrentPass := CurrentAzimuth <= 1.000;

  if CandidatePass <> CurrentPass then
    Exit(CandidatePass);

  if Abs(CandidateAzimuth - CurrentAzimuth) >
     AzimuthTieTolerance then
    Exit(CandidateAzimuth < CurrentAzimuth);

  { 5. Норма акселерометра — третий приоритет. }
  CandidateAccNorm := Candidate.Metrics.Metrics[5].MaxAbs;
  CurrentAccNorm := Current.Metrics.Metrics[5].MaxAbs;

  CandidatePass := CandidateAccNorm <= 0.300;
  CurrentPass := CurrentAccNorm <= 0.300;

  if CandidatePass <> CurrentPass then
    Exit(CandidatePass);

  if Abs(CandidateAccNorm - CurrentAccNorm) >
     AccNormTieTolerance then
    Exit(CandidateAccNorm < CurrentAccNorm);

  { 6. Остальные допуски. }
  CandidateOtherPass := OtherMaxAbsPassCount(Candidate.Metrics);
  CurrentOtherPass := OtherMaxAbsPassCount(Current.Metrics);

  if CandidateOtherPass <> CurrentOtherPass then
    Exit(CandidateOtherPass > CurrentOtherPass);

  { 7. Общий индекс. }
  if Abs(Candidate.NormalizedMaxError -
         Current.NormalizedMaxError) > ErrorTolerance then
    Exit(Candidate.NormalizedMaxError <
         Current.NormalizedMaxError);

  { 8. Более простая модель. }
  Result :=
    Candidate.Model.lin_CoeffCount <
    Current.Model.lin_CoeffCount;
end;



//  function IsBetter(const Candidate,
//    Current: TLinTemperatureNodeVariantResult): Boolean;
//  var
//    CandidateZenith, CurrentZenith: Double;
//    CandidateZenithPass, CurrentZenithPass: Boolean;
//    CandidateOtherPass, CurrentOtherPass: Integer;
//  begin
//    if Candidate.Converged <> Current.Converged then
//      Exit(Candidate.Converged);
//
//    CandidateZenith := Candidate.Metrics.Metrics[0].MaxAbs;
//    CurrentZenith := Current.Metrics.Metrics[0].MaxAbs;
//    CandidateZenithPass := CandidateZenith <= ControlledMetricLimit[0];
//    CurrentZenithPass := CurrentZenith <= ControlledMetricLimit[0];
//    if CandidateZenithPass <> CurrentZenithPass then
//      Exit(CandidateZenithPass);
//    if Abs(CandidateZenith - CurrentZenith) > ErrorTolerance then
//      Exit(CandidateZenith < CurrentZenith);
//
//    CandidateOtherPass := OtherMaxAbsPassCount(Candidate.Metrics);
//    CurrentOtherPass := OtherMaxAbsPassCount(Current.Metrics);
//    if CandidateOtherPass <> CurrentOtherPass then
//      Exit(CandidateOtherPass > CurrentOtherPass);
//    if Abs(Candidate.NormalizedMaxError -
//       Current.NormalizedMaxError) > ErrorTolerance then
//      Exit(Candidate.NormalizedMaxError < Current.NormalizedMaxError);
//    Result := Candidate.Model.lin_CoeffCount <
//      Current.Model.lin_CoeffCount;
//  end;

begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');
  if Length(TpolyMath.InpData.Inpt) = 0 then
    raise EInvalidOpException.Create(
      'TGkiLinTrainingReport.Run must be called after TpolyMath.Init');
  if Length(TrainingIndices) = 0 then
    raise EArgumentException.Create('TrainingIndices is empty');
  if Length(NodeCounts) = 0 then
    raise EArgumentException.Create('NodeCounts is empty');
  Huber.Validate;

  SetLength(TrainingInputs, Length(TrainingIndices));
  for var I := 0 to High(TrainingIndices) do
  begin
    if (TrainingIndices[I] < 0) or
       (TrainingIndices[I] >= Length(TpolyMath.InpData.Inpt)) then
      raise EArgumentOutOfRangeException.CreateFmt(
        'TrainingIndices[%d]=%d is outside 0..%d',
        [I, TrainingIndices[I], High(TpolyMath.InpData.Inpt)]);
    TrainingInputs[I] := TpolyMath.InpData.Inpt[TrainingIndices[I]];
  end;

  Result := Default(TLinTemperatureNodeComparison);
  Result.SelectedIndex := -1;
  SetLength(Result.Variants, Length(NodeCounts));

  for var CandidateIndex := 0 to High(NodeCounts) do
  begin
    for var PreviousIndex := 0 to CandidateIndex - 1 do
      if NodeCounts[PreviousIndex] = NodeCounts[CandidateIndex] then
        raise EArgumentException.CreateFmt(
          'NodeCounts contains duplicate value %d',
          [NodeCounts[CandidateIndex]]);

    Variant := Default(TLinTemperatureNodeVariantResult);
    Variant.RequestedNodeCount := NodeCounts[CandidateIndex];
    Variant.Model := TLinTemperatureModel.lin_Create(
      lin_BuildReducedTemperatureNodes(
        TrainingInputs, Variant.RequestedNodeCount),
      True);
    Variant.Fit := TpolyMath.lin_RunLS(
      Variant.Model, TrainingIndices, Huber);
    Variant.Metrics := TpolyMath.lin_CalculateAll(Variant.Fit);
    Variant.Converged :=
      Variant.Fit.Diagnostics[sAcc].Converged and
      Variant.Fit.Diagnostics[sMag].Converged;
    Variant.MaxAbsPassCount := MaxAbsPassCount(Variant.Metrics);
    Variant.NormalizedMaxError := NormalizedMaxError(Variant.Metrics);
    Result.Variants[CandidateIndex] := Variant;

    if (Result.SelectedIndex < 0) or
       IsBetter(Result.Variants[CandidateIndex],
         Result.Variants[Result.SelectedIndex]) then
      Result.SelectedIndex := CandidateIndex;
  end;

  if Result.SelectedIndex < 0 then
    raise EInvalidOpException.Create('No node candidate was evaluated');

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI TRAINING-NODE COMPARISON');
    OutRes.Add(StringOfChar('=', 138));
    OutRes.Add(Format('Training rows: %d; evaluation rows: %d; '+
      'cross model: linear T; Huber kG=%.6g; kH=%.6g; '+
      'MaxIterations=%d; tolerance=%.6g; balanced=%s',
      [Length(TrainingIndices), Length(TpolyMath.InpData.Inpt),
       Huber.Limit, Huber.Limit, Huber.MaxIterations,
       Huber.WeightTolerance, YesNo(Huber.BalanceMaxMinSphere)]));
    OutRes.Add('Node construction: Min/Max ranges and centers are '+
      'calculated only from the training rows.');
    OutRes.Add('Ranking: converged; Zenith PASS; minimum Zenith MaxAbs; '+
      'other strict PASS; normalized MaxAbs; fewer coefficients.');
    OutRes.Add('');

    OutRes.Add('TEMPERATURE NODES');
    OutRes.Add(StringOfChar('-', 138));
    for var I := 0 to High(Result.Variants) do
    begin
      NodeLine := Format('%2d nodes:',
        [Result.Variants[I].RequestedNodeCount]);
      for var Node in Result.Variants[I].Model.TemperatureNodes do
        NodeLine := NodeLine + Format(' %.6f', [Node]);
      OutRes.Add(NodeLine);
    end;
    OutRes.Add('');

    OutRes.Add('MODEL SUMMARY');
    OutRes.Add(StringOfChar('-', 138));
    OutRes.Add(Format('%5s %6s %10s %10s %13s %13s %10s '+
      '%7s %11s %11s %9s',
      ['Nodes', 'Coeff', 'Rank G', 'Rank H', 'Condition G',
       'Condition H', 'Converged', 'PASS', 'Zen Max',
       'Error idx', 'Selected']));
    for var I := 0 to High(Result.Variants) do
      with Result.Variants[I] do
        OutRes.Add(Format('%5d %6d %4d/%-5d %4d/%-5d '+
          '%13.6g %13.6g %10s %3d/5  %11.6f %11.6f %9s',
          [RequestedNodeCount, Model.lin_CoeffCount,
           Fit.AccRank, Model.lin_CoeffCount,
           Fit.MagRank, Model.lin_CoeffCount,
           Fit.AccCondition, Fit.MagCondition,
           YesNo(Converged), MaxAbsPassCount,
           Metrics.Metrics[0].MaxAbs, NormalizedMaxError,
           YesNo(I = Result.SelectedIndex)]));
    OutRes.Add('');

    OutRes.Add('MAXABS BY NODE COUNT');
    OutRes.Add(StringOfChar('-', 138));
    OutRes.Add(Format('%-25s %8s %s',
      ['Parameter', 'Limit', 'Candidate values']));
    for var MetricNo := 0 to ControlledMetricCount - 1 do
    begin
      MetricLine := Format('%-25s %7.3f %-3s',
        [ControlledMetricName[MetricNo],
         ControlledMetricLimit[MetricNo],
         ControlledMetricUnit[MetricNo]]);
      for var I := 0 to High(Result.Variants) do
      begin
        var Metric := Result.Variants[I].Metrics.Metrics[
          ControlledMetricIndex[MetricNo]];
        MetricLine := MetricLine + Format('  %2dn=%8.4f %-4s',
          [Result.Variants[I].RequestedNodeCount,
           Metric.MaxAbs,
           PassFail(Metric.MaxAbs,
             ControlledMetricLimit[MetricNo])]);
      end;
      OutRes.Add(MetricLine);
    end;

    OutRes.Add('');
    with Result.Variants[Result.SelectedIndex] do
    begin
      OutRes.Add(Format('SELECTED: %d nodes; %d coefficients/output '+
        'axis; Zenith MaxAbs=%.6f deg; strict MaxAbs PASS=%d/5; '+
        'normalized error=%.6f.',
        [RequestedNodeCount, Model.lin_CoeffCount,
         Metrics.Metrics[0].MaxAbs, MaxAbsPassCount,
         NormalizedMaxError]));
    end;

    Details := TStringList.Create;
    try
      TpolyMath.lin_AllMetricsToStrings(
        Result.Variants[Result.SelectedIndex].Fit, Details);
      TpolyMath.lin_WorstPointsToStrings(
        Result.Variants[Result.SelectedIndex].Fit, Details);
      TpolyMath.lin_MagneticFieldDiagnosticsToStrings(
        Result.Variants[Result.SelectedIndex].Fit, Details);
      OutRes.Add('');
      OutRes.AddStrings(Details);
    finally
      Details.Free;
    end;
  finally
    OutRes.EndUpdate;
  end;
end;

end.
