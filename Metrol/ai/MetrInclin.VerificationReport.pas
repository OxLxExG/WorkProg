unit MetrInclin.VerificationReport;

interface

uses
  System.Classes,
  System.SysUtils,
  MetrInclin.Temp.Stat;

type
  TGkiVerificationMetricKind = (
    vmZenith,
    vmMagneticInclination,
    vmAzimuth,
    vmAccelerometerNorm,
    vmMagnetometerNorm
  );

  TGkiVerificationMetric = record
    Count: Integer;
    MeanAbs: Double;
    Percentile95: Double;
    MaxAbs: Double;
  end;

  TGkiVerificationLimits = record
    Zenith: Double;
    MagneticInclination: Double;
    Azimuth: Double;
    AccelerometerNorm: Double;
    MagnetometerNorm: Double;
    class function Default: TGkiVerificationLimits; static;
  end;

  TGkiVerificationAmplitude = record
    Accel: Double;
    Magnet: Double;
    class function Default: TGkiVerificationAmplitude; static;
  end;

  TGkiVerificationResult = record
    Metrics: array[TGkiVerificationMetricKind] of TGkiVerificationMetric;
  end;

  TGkiVerificationReport = class sealed
  strict private
    class function DeltaAngle(const Value: Double): Double; static;
    class function PassFail(const Value, Limit: Double): string; static;
    class procedure ValidateSample(const Sample: TinclTest;
      const Index: Integer); static;
  public
    class function Calculate(const Tests: TArray<TinclTest>;
      const EtalonMagNaklon: Double;
      const Amplitude: TGkiVerificationAmplitude):
      TGkiVerificationResult; static;

    class procedure ToStrings(const Result: TGkiVerificationResult;
      const EtalonMagNaklon: Double;
      const Amplitude: TGkiVerificationAmplitude;
      const Limits: TGkiVerificationLimits; const OutRes: TStrings); static;

    class function Build(const Tests: TArray<TinclTest>;
      const EtalonMagNaklon: Double; const OutRes: TStrings):
      TGkiVerificationResult; overload; static;

    class function Build(const Tests: TArray<TinclTest>;
      const EtalonMagNaklon: Double;
      const Amplitude: TGkiVerificationAmplitude;
      const Limits: TGkiVerificationLimits; const OutRes: TStrings):
      TGkiVerificationResult; overload; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.Math;

type
  TMetricAccumulator = record
    AbsSum: Double;
    MaxAbs: Double;
    AbsValues: TArray<Double>;
    procedure Add(const Error: Double);
    function Finish: TGkiVerificationMetric;
  end;

{ TGkiVerificationLimits }

class function TGkiVerificationLimits.Default: TGkiVerificationLimits;
begin
  Result.Zenith := 0.150;
  Result.MagneticInclination := 0.200;
  Result.Azimuth := 1.000;
  Result.AccelerometerNorm := 0.300;
  Result.MagnetometerNorm := 0.500;
end;

{ TGkiVerificationAmplitude }

class function TGkiVerificationAmplitude.Default:
  TGkiVerificationAmplitude;
begin
  { Dev.G and Dev.H are amplitudes in instrument units, approximately 10000. }
  Result.Accel := 10000.0;
  Result.Magnet := 10000.0;
end;

{ TMetricAccumulator }

procedure TMetricAccumulator.Add(const Error: Double);
var
  N: Integer;
  A: Double;
begin
  if IsNan(Error) or IsInfinite(Error) then
    Exit;

  A := Abs(Error);
  AbsSum := AbsSum + A;
  if (Length(AbsValues) = 0) or (A > MaxAbs) then
    MaxAbs := A;

  N := Length(AbsValues);
  SetLength(AbsValues, N + 1);
  AbsValues[N] := A;
end;

function TMetricAccumulator.Finish: TGkiVerificationMetric;
var
  P95Index: Integer;
begin
  Result := Default(TGkiVerificationMetric);
  Result.Count := Length(AbsValues);
  if Result.Count = 0 then
  begin
    Result.MeanAbs := NaN;
    Result.Percentile95 := NaN;
    Result.MaxAbs := NaN;
    Exit;
  end;

  TArray.Sort<Double>(AbsValues);
  P95Index := EnsureRange(Ceil(0.95 * Result.Count) - 1,
    0, High(AbsValues));

  Result.MeanAbs := AbsSum / Result.Count;
  Result.Percentile95 := AbsValues[P95Index];
  Result.MaxAbs := MaxAbs;
end;

{ TGkiVerificationReport }

class function TGkiVerificationReport.DeltaAngle(
  const Value: Double): Double;
begin
  Result := Value - 360.0 * Floor(Value / 360.0);
  if Result > 180.0 then
    Result := Result - 360.0;
end;

class function TGkiVerificationReport.PassFail(
  const Value, Limit: Double): string;
begin
  if not (IsNan(Value) or IsInfinite(Value)) and (Value <= Limit) then
    Result := 'PASS'
  else
    Result := 'FAIL';
end;

class procedure TGkiVerificationReport.ValidateSample(
  const Sample: TinclTest; const Index: Integer);

  procedure CheckFinite(const Name: string; const Value: Double);
  begin
    if IsNan(Value) or IsInfinite(Value) then
      raise EArgumentException.CreateFmt(
        'Verification row %d, step %d: %s is not finite',
        [Index, Sample.Step, Name]);
  end;

begin
  CheckFinite('Stol.Azi', Sample.Stol.Azi);
  CheckFinite('Stol.Zen', Sample.Stol.Zen);
  CheckFinite('Stol.EtalonMag', Sample.Stol.EtalonMag);
  CheckFinite('Dev.Azi', Sample.Dev.Azi);
  CheckFinite('Dev.Zen', Sample.Dev.Zen);
  CheckFinite('Dev.G', Sample.Dev.G);
  CheckFinite('Dev.H', Sample.Dev.H);
  CheckFinite('Dev.MagNaklon', Sample.Dev.MagNaklon);

  if Sample.Stol.EtalonMag <= 0 then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Verification row %d, step %d: Stol.EtalonMag must be positive',
      [Index, Sample.Step]);
end;

class function TGkiVerificationReport.Calculate(
  const Tests: TArray<TinclTest>;
  const EtalonMagNaklon: Double;
  const Amplitude: TGkiVerificationAmplitude): TGkiVerificationResult;
var
  Acc: array[TGkiVerificationMetricKind] of TMetricAccumulator;
  RefZenith, CorrectedDevAzimuth, ExpectedMagnetNorm: Double;
begin
  if Length(Tests) = 0 then
    raise EArgumentException.Create('Verification test array is empty');
  if IsNan(EtalonMagNaklon) or IsInfinite(EtalonMagNaklon) then
    raise EArgumentException.Create('EtalonMagNaklon is not finite');
  if IsNan(Amplitude.Accel) or IsInfinite(Amplitude.Accel) or
     (Amplitude.Accel <= 0) then
    raise EArgumentOutOfRangeException.Create(
      'Accelerometer reference amplitude must be finite and positive');
  if IsNan(Amplitude.Magnet) or IsInfinite(Amplitude.Magnet) or
     (Amplitude.Magnet <= 0) then
    raise EArgumentOutOfRangeException.Create(
      'Magnetometer reference amplitude must be finite and positive');

  for var I := 0 to High(Tests) do
  begin
    ValidateSample(Tests[I], I);

    RefZenith := Tests[I].Stol.Zen;
    CorrectedDevAzimuth := Tests[I].Dev.Azi;
    if RefZenith > 180.0 then
    begin
      RefZenith := 360.0 - RefZenith;
      CorrectedDevAzimuth := CorrectedDevAzimuth + 180.0;
    end;

    Acc[vmZenith].Add(DeltaAngle(Tests[I].Dev.Zen - RefZenith));

    { Azimuth is undefined near either vertical. This is the same effective
      Z > 5 degree filter used by the calibration report. }
    if (RefZenith >= 5.0) and (RefZenith <= 175.0) then
      Acc[vmAzimuth].Add(DeltaAngle(
        CorrectedDevAzimuth - Tests[I].Stol.Azi));

    Acc[vmMagneticInclination].Add(DeltaAngle(
      Tests[I].Dev.MagNaklon - EtalonMagNaklon));

    Acc[vmAccelerometerNorm].Add(
      (Tests[I].Dev.G - Amplitude.Accel) /
      Amplitude.Accel * 100.0);

    ExpectedMagnetNorm := Amplitude.Magnet *
      Tests[I].Stol.EtalonMag / 1000.0;
    Acc[vmMagnetometerNorm].Add(
      (Tests[I].Dev.H - ExpectedMagnetNorm) /
      ExpectedMagnetNorm * 100.0);
  end;

  Result := Default(TGkiVerificationResult);
  for var Kind := Low(TGkiVerificationMetricKind) to
    High(TGkiVerificationMetricKind) do
    Result.Metrics[Kind] := Acc[Kind].Finish;
end;

class procedure TGkiVerificationReport.ToStrings(
  const Result: TGkiVerificationResult;
  const EtalonMagNaklon: Double;
  const Amplitude: TGkiVerificationAmplitude;
  const Limits: TGkiVerificationLimits; const OutRes: TStrings);
const
  MetricNames: array[TGkiVerificationMetricKind] of string = (
    'Zenith',
    'Magnetic inclination',
    'Azimuth (Z > 5°)',
    'Accelerometer norm',
    'Magnetometer norm'
  );
  MetricUnits: array[TGkiVerificationMetricKind] of string = (
    '°', '°', '°', '%', '%'
  );
var
  MetricLimits: array[TGkiVerificationMetricKind] of Double;
  M: TGkiVerificationMetric;
  Limit: Double;
begin
  if OutRes = nil then
    raise EArgumentNilException.Create('OutRes');

  MetricLimits[vmZenith] := Limits.Zenith;
  MetricLimits[vmMagneticInclination] := Limits.MagneticInclination;
  MetricLimits[vmAzimuth] := Limits.Azimuth;
  MetricLimits[vmAccelerometerNorm] := Limits.AccelerometerNorm;
  MetricLimits[vmMagnetometerNorm] := Limits.MagnetometerNorm;

  OutRes.BeginUpdate;
  try
    OutRes.Clear;
    OutRes.Add('GKI INSTRUMENT VERIFICATION');
    OutRes.Add(StringOfChar('=', 106));
    OutRes.Add(Format('Reference magnetic inclination: %.6f°',
      [EtalonMagNaklon]));
    OutRes.Add(Format('Reference amplitudes: G=%.6f; H=%.6f '+
      '(H is additionally multiplied by EtalonMag/1000)',
      [Amplitude.Accel, Amplitude.Magnet]));
    OutRes.Add('');
    OutRes.Add('VERIFICATION METRICS');
    OutRes.Add(StringOfChar('-', 106));
    OutRes.Add(Format('%-25s %7s %14s %14s %14s %12s',
      ['Parameter', 'N', 'MeanAbs', 'P95', 'MaxAbs', 'Limit']));

    for var Kind := Low(TGkiVerificationMetricKind) to
      High(TGkiVerificationMetricKind) do
    begin
      M := Result.Metrics[Kind];
      Limit := MetricLimits[Kind];
      OutRes.Add(Format('%-25s %7d %7.3f %-3s %4s '+
        '%7.3f %-3s %4s %7.3f %-3s %4s %6.3f %-3s',
        [MetricNames[Kind], M.Count,
         M.MeanAbs, MetricUnits[Kind], PassFail(M.MeanAbs, Limit),
         M.Percentile95, MetricUnits[Kind],
         PassFail(M.Percentile95, Limit),
         M.MaxAbs, MetricUnits[Kind], PassFail(M.MaxAbs, Limit),
         Limit, MetricUnits[Kind]]));
    end;
  finally
    OutRes.EndUpdate;
  end;
end;

class function TGkiVerificationReport.Build(
  const Tests: TArray<TinclTest>; const EtalonMagNaklon: Double;
  const OutRes: TStrings): TGkiVerificationResult;
begin
  Result := Build(Tests, EtalonMagNaklon,
    TGkiVerificationAmplitude.Default,
    TGkiVerificationLimits.Default, OutRes);
end;

class function TGkiVerificationReport.Build(
  const Tests: TArray<TinclTest>;
  const EtalonMagNaklon: Double;
  const Amplitude: TGkiVerificationAmplitude;
  const Limits: TGkiVerificationLimits; const OutRes: TStrings):
  TGkiVerificationResult;
begin
  Result := Calculate(Tests, EtalonMagNaklon, Amplitude);
  ToStrings(Result, EtalonMagNaklon, Amplitude, Limits, OutRes);
end;

end.
