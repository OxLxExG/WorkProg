unit MetrInclin.Temp.LeaveOneOut;

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections;

type
  TTemperatureModel = record
    AxDegree: Integer;
    KuDegree: Integer;
    DzDegree: Integer;
    class function Create(AAx, AKu, ADz: Integer): TTemperatureModel; static;
    function Name: string;
  end;

  TLotoSample = record
    Temperature: Double;
    SourceIndex: Integer;
    class function Create(ATemperature: Double; ASourceIndex: Integer): TLotoSample; static;
  end;

  TLotoMetric = record
    MaxAbs: Double;
    MeanAbs: Double;
    PeakSigned: Double;
    PeakSourceIndex: Integer;
    Count: Integer;
  end;

  TLotoFoldResult = record
    Model: TTemperatureModel;
    ExcludedTemperature: Double;
    IsExtrapolation: Boolean;
    TrainingCount: Integer;
    TestCount: Integer;
    Metrics: TArray<TLotoMetric>;
  end;

  TLotoSummary = record
    Model: TTemperatureModel;
    Interpolation: TArray<TLotoMetric>;
    Extrapolation: TArray<TLotoMetric>;
  end;

  { The fitted object is deliberately opaque to the runner. }
  ILotoModelAdapter = interface
    ['{BD547408-CC9B-421C-A127-02CF9B15E647}']
    function MetricNames: TArray<string>;
    function Fit(const Model: TTemperatureModel;
      const TrainingSourceIndices: TArray<Integer>): IInterface;
    function Errors(const FittedModel: IInterface;
      SourceIndex: Integer): TArray<Double>;
  end;

  TLotoRunner = class
  strict private
    FTemperatureTolerance: Double;
    function SameTemperature(A, B: Double): Boolean;
    procedure AddError(var Metric: TLotoMetric; Error: Double;
      SourceIndex: Integer);
    procedure MergeMetric(var Target: TLotoMetric;
      const Source: TLotoMetric);
  public
    constructor Create(ATemperatureTolerance: Double = 0.05);
    function Run(const Samples: TArray<TLotoSample>;
      const Models: TArray<TTemperatureModel>;
      const Adapter: ILotoModelAdapter): TArray<TLotoFoldResult>;
    function Summarize(const Folds: TArray<TLotoFoldResult>;
      const Models: TArray<TTemperatureModel>): TArray<TLotoSummary>;
  end;

implementation

class function TTemperatureModel.Create(AAx, AKu, ADz: Integer): TTemperatureModel;
begin
  Result.AxDegree := AAx;
  Result.KuDegree := AKu;
  Result.DzDegree := ADz;
end;

function TTemperatureModel.Name: string;
begin
  Result := Format('%d:%d:%d', [AxDegree, KuDegree, DzDegree]);
end;

class function TLotoSample.Create(ATemperature: Double;
  ASourceIndex: Integer): TLotoSample;
begin
  Result.Temperature := ATemperature;
  Result.SourceIndex := ASourceIndex;
end;

constructor TLotoRunner.Create(ATemperatureTolerance: Double);
begin
  inherited Create;
  if ATemperatureTolerance < 0 then
    raise EArgumentOutOfRangeException.Create('Temperature tolerance must be non-negative');
  FTemperatureTolerance := ATemperatureTolerance;
end;

function TLotoRunner.SameTemperature(A, B: Double): Boolean;
begin
  Result := Abs(A - B) <= FTemperatureTolerance;
end;

procedure TLotoRunner.AddError(var Metric: TLotoMetric; Error: Double;
  SourceIndex: Integer);
var
  A: Double;
begin
  if IsNan(Error) or IsInfinite(Error) then
    raise EInvalidOpException.CreateFmt('Invalid error for source row %d', [SourceIndex]);
  A := Abs(Error);
  if (Metric.Count = 0) or (A > Metric.MaxAbs) then
  begin
    Metric.MaxAbs := A;
    Metric.PeakSigned := Error;
    Metric.PeakSourceIndex := SourceIndex;
  end;
  Metric.MeanAbs := Metric.MeanAbs + A;
  Inc(Metric.Count);
end;

procedure TLotoRunner.MergeMetric(var Target: TLotoMetric;
  const Source: TLotoMetric);
var
  Total: Integer;
begin
  if Source.Count = 0 then
    Exit;
  if (Target.Count = 0) or (Source.MaxAbs > Target.MaxAbs) then
  begin
    Target.MaxAbs := Source.MaxAbs;
    Target.PeakSigned := Source.PeakSigned;
    Target.PeakSourceIndex := Source.PeakSourceIndex;
  end;
  Total := Target.Count + Source.Count;
  Target.MeanAbs :=
    (Target.MeanAbs * Target.Count + Source.MeanAbs * Source.Count) / Total;
  Target.Count := Total;
end;

function TLotoRunner.Run(const Samples: TArray<TLotoSample>;
  const Models: TArray<TTemperatureModel>;
  const Adapter: ILotoModelAdapter): TArray<TLotoFoldResult>;
var
  Temperatures: TList<Double>;
  Train, Test: TList<Integer>;
  MetricCount, FoldIndex: Integer;
  MinT, MaxT, HeldT: Double;
  Fitted: IInterface;
  Err: TArray<Double>;
begin
  if Adapter = nil then
    raise EArgumentNilException.Create('Adapter');
  if Length(Samples) = 0 then
    raise EArgumentException.Create('LOTO requires at least one sample');

  MetricCount := Length(Adapter.MetricNames);
  if MetricCount = 0 then
    raise EArgumentException.Create('Adapter must expose at least one metric');

  Temperatures := TList<Double>.Create;
  Train := TList<Integer>.Create;
  Test := TList<Integer>.Create;
  try
    MinT := Samples[0].Temperature;
    MaxT := MinT;
    for var S in Samples do
    begin
      MinT := Min(MinT, S.Temperature);
      MaxT := Max(MaxT, S.Temperature);
      var Found := False;
      for var T in Temperatures do
        if SameTemperature(S.Temperature, T) then
        begin
          Found := True;
          Break;
        end;
      if not Found then
        Temperatures.Add(S.Temperature);
    end;
    Temperatures.Sort;
    if Temperatures.Count < 3 then
      raise EArgumentException.Create('LOTO requires at least three temperature series');

    SetLength(Result, Length(Models) * Temperatures.Count);
    FoldIndex := 0;
    for var Model in Models do
      for HeldT in Temperatures do
      begin
        Train.Clear;
        Test.Clear;
        for var S in Samples do
          if SameTemperature(S.Temperature, HeldT) then
            Test.Add(S.SourceIndex)
          else
            Train.Add(S.SourceIndex);

        if Test.Count = 0 then
          raise EInvalidOpException.Create('Internal error: empty excluded series');
        Fitted := Adapter.Fit(Model, Train.ToArray);
        if Fitted = nil then
          raise EInvalidOpException.CreateFmt('Fit returned nil for %s at T=%g',
            [Model.Name, HeldT]);

        Result[FoldIndex].Model := Model;
        Result[FoldIndex].ExcludedTemperature := HeldT;
        Result[FoldIndex].IsExtrapolation :=
          SameTemperature(HeldT, MinT) or SameTemperature(HeldT, MaxT);
        Result[FoldIndex].TrainingCount := Train.Count;
        Result[FoldIndex].TestCount := Test.Count;
        SetLength(Result[FoldIndex].Metrics, MetricCount);

        for var SourceIndex in Test do
        begin
          Err := Adapter.Errors(Fitted, SourceIndex);
          if Length(Err) <> MetricCount then
            raise EInvalidOpException.CreateFmt(
              'Adapter returned %d errors; expected %d for source row %d',
              [Length(Err), MetricCount, SourceIndex]);
          for var M := 0 to MetricCount - 1 do
            AddError(Result[FoldIndex].Metrics[M], Err[M], SourceIndex);
        end;
        for var M := 0 to MetricCount - 1 do
          Result[FoldIndex].Metrics[M].MeanAbs :=
            Result[FoldIndex].Metrics[M].MeanAbs /
            Result[FoldIndex].Metrics[M].Count;
        Inc(FoldIndex);
      end;
  finally
    Test.Free;
    Train.Free;
    Temperatures.Free;
  end;
end;

function TLotoRunner.Summarize(const Folds: TArray<TLotoFoldResult>;
  const Models: TArray<TTemperatureModel>): TArray<TLotoSummary>;
begin
  SetLength(Result, Length(Models));
  for var I := 0 to High(Models) do
  begin
    Result[I].Model := Models[I];
    for var Fold in Folds do
      if (Fold.Model.AxDegree = Models[I].AxDegree) and
         (Fold.Model.KuDegree = Models[I].KuDegree) and
         (Fold.Model.DzDegree = Models[I].DzDegree) then
      begin
        if Length(Result[I].Interpolation) = 0 then
        begin
          SetLength(Result[I].Interpolation, Length(Fold.Metrics));
          SetLength(Result[I].Extrapolation, Length(Fold.Metrics));
        end;
        for var M := 0 to High(Fold.Metrics) do
          if Fold.IsExtrapolation then
            MergeMetric(Result[I].Extrapolation[M], Fold.Metrics[M])
          else
            MergeMetric(Result[I].Interpolation[M], Fold.Metrics[M]);
      end;
  end;
end;

end.
