unit TrrInclin.Temp.LinModel;

interface

uses  TrrInclin.Temp.LinPacked,
  System.SysUtils, System.Math, System.Generics.Collections,
  Vector, TrrInclin.Temp.PolyModel, MetrInclin.Temp.Stat;

type
  { One real acquisition interval.  Min/Max are obtained from the used
    measurement rows of one SetNo. }
  TLinTemperatureRange = record
    SetNo: Integer;
    MinTemperature: Double;
    MaxTemperature: Double;
    Count: Integer;
  end;

  { Continuous piecewise-linear temperature model.

    For each output axis the coefficient layout is:
      [diagonal value at every temperature node]
      [first cross-axis coefficient: constant, global linear pair,
       or one value at every cross-temperature node]
      [second cross-axis coefficient: constant, global linear pair,
       or one value at every cross-temperature node]
      [zero-offset value at every temperature node]

    Only the two neighbouring node values are active for a measurement row.
    Outside the measured interval the nearest endpoint value is held. }
  TLinTemperatureModel = record
    TemperatureNodes: TArray<Double>;
    CrossTemperatureNodes: TArray<Double>;
    CrossLinear: Boolean;
    CrossPiecewise: Boolean;
    class function lin_Create(const ANodes: array of Double;
      ACrossLinear: Boolean = False): TLinTemperatureModel; static;
    class function lin_CreatePiecewiseCross(
      const ANodes: array of Double): TLinTemperatureModel; static;
    class function lin_CreatePiecewiseCrossAt(
      const ANodes, ACrossNodes: array of Double):
      TLinTemperatureModel; static;
    class function lin_FromInputs(const Inputs: TArray<TinclInput>;
      ACrossLinear: Boolean = False): TLinTemperatureModel; static;
    class function lin_FromInputsPiecewiseCross(
      const Inputs: TArray<TinclInput>): TLinTemperatureModel; static;
    class function lin_FromInputsFiveNodeCross(
      const Inputs: TArray<TinclInput>): TLinTemperatureModel; static;
    procedure lin_Validate;
    function lin_NodeCount: Integer;
    function lin_CrossNodeCount: Integer;
    function lin_CrossCoeffCount: Integer;
    function lin_CoeffCount: Integer;
    function lin_OffsetIndex: Integer;
    function lin_CreateBasis(Temperature: Double): TArray<Double>;
    function lin_CreateCrossBasis(Temperature: Double): TArray<Double>;
    function lin_CreateAxisRow(Temperature: Double; const Raw: TVector3;
      OutputAxis: SetVector; Scale: Double): TArray<Double>;
    procedure lin_FindAxis(const Coefficients: TVArray<Double>;
      Temperature: Double; const Raw: TVector3; Scale: Double;
      out Corrected: TVector3);
  end;

function lin_Contains(const Source, Value: string;
  IgnoreCase: Boolean = True): Boolean;
function lin_BuildTemperatureRanges(const Inputs: TArray<TinclInput>):
  TArray<TLinTemperatureRange>;
function lin_BuildTemperatureNodes(const Inputs: TArray<TinclInput>):
  TArray<Double>;
function lin_BuildTemperatureCenters(const Inputs: TArray<TinclInput>):
  TArray<Double>;
{ Build 5..10 main temperature nodes for five acquisition SetNo ranges.
  The narrowest ranges are replaced first by their real mean temperature;
  wider ranges retain separate Min/Max boundary nodes. }
function lin_BuildReducedTemperatureNodes(
  const Inputs: TArray<TinclInput>; TargetNodeCount: Integer):
  TArray<Double>;
function lin_CopyTemperatureModel(const Source: TLinTemperatureModel):
  TLinTemperatureModel;

implementation


function lin_Contains(const Source, Value: string;
  IgnoreCase: Boolean): Boolean;
begin
  if IgnoreCase then
    Result := System.Pos(AnsiUpperCase(Value),
      AnsiUpperCase(Source)) > 0
  else
    Result := System.Pos(Value, Source) > 0;
end;

function lin_BuildTemperatureCenters(const Inputs: TArray<TinclInput>):
  TArray<Double>;
type
  TLinTemperatureAccumulator = record
    Sum: Double;
    Count: Integer;
  end;
var
  Accumulators: TDictionary<Integer, TLinTemperatureAccumulator>;
  Accumulator: TLinTemperatureAccumulator;
  Centers: TList<Double>;
  Swap: Double;
begin
  if Length(Inputs) = 0 then
    raise EArgumentException.Create(
      'lin_BuildTemperatureCenters: Inputs is empty');
  Accumulators := TDictionary<Integer,
    TLinTemperatureAccumulator>.Create;
  try
    for var Input in Inputs do
    begin
      if (Input.SetNo < 0) or lin_Contains(Input.Info, 'NotUse') then
        Continue;
      if IsNan(Input.T) or IsInfinite(Input.T) then
        raise EArgumentException.CreateFmt(
          'lin_BuildTemperatureCenters: non-finite temperature in step %d',
          [Input.Step]);
      if not Accumulators.TryGetValue(Input.SetNo, Accumulator) then
        Accumulator := Default(TLinTemperatureAccumulator);
      Accumulator.Sum := Accumulator.Sum + Input.T;
      Inc(Accumulator.Count);
      Accumulators.AddOrSetValue(Input.SetNo, Accumulator);
    end;

    Centers := TList<Double>.Create;
    try
      for var Pair in Accumulators do
        if Pair.Value.Count > 0 then
          Centers.Add(Pair.Value.Sum / Pair.Value.Count);
      Result := Centers.ToArray;
    finally
      Centers.Free;
    end;
  finally
    Accumulators.Free;
  end;

  for var I := 0 to High(Result) - 1 do
    for var J := I + 1 to High(Result) do
      if Result[J] < Result[I] then
      begin
        Swap := Result[I];
        Result[I] := Result[J];
        Result[J] := Swap;
      end;
  if Length(Result) < 2 then
    raise EInvalidOpException.Create(
      'lin_BuildTemperatureCenters requires at least two SetNo values');
  for var I := 1 to High(Result) do
    if Result[I] <= Result[I - 1] then
      raise EInvalidOpException.Create(
        'lin_BuildTemperatureCenters produced duplicate centers');
end;

function lin_BuildTemperatureRanges(const Inputs: TArray<TinclInput>):
  TArray<TLinTemperatureRange>;
var
  Ranges: TDictionary<Integer, TLinTemperatureRange>;
  Range, SwapRange: TLinTemperatureRange;
begin
  if Length(Inputs) = 0 then
    raise EArgumentException.Create(
      'lin_BuildTemperatureRanges: Inputs is empty');

  Ranges := TDictionary<Integer, TLinTemperatureRange>.Create;
  try
    for var Input in Inputs do
    begin
      if (Input.SetNo < 0) or lin_Contains(Input.Info, 'NotUse') then
        Continue;
      if IsNan(Input.T) or IsInfinite(Input.T) then
        raise EArgumentException.CreateFmt(
          'lin_BuildTemperatureRanges: non-finite temperature in step %d',
          [Input.Step]);

      if not Ranges.TryGetValue(Input.SetNo, Range) then
      begin
        Range := Default(TLinTemperatureRange);
        Range.SetNo := Input.SetNo;
        Range.MinTemperature := Input.T;
        Range.MaxTemperature := Input.T;
      end
      else
      begin
        Range.MinTemperature := Min(Range.MinTemperature, Input.T);
        Range.MaxTemperature := Max(Range.MaxTemperature, Input.T);
      end;
      Inc(Range.Count);
      Ranges.AddOrSetValue(Input.SetNo, Range);
    end;

    Result := Ranges.Values.ToArray;
  finally
    Ranges.Free;
  end;

  if Length(Result) < 2 then
    raise EInvalidOpException.Create(
      'lin_BuildTemperatureRanges requires at least two SetNo ranges');

  for var I := 0 to High(Result) - 1 do
    for var J := I + 1 to High(Result) do
      if Result[J].MinTemperature < Result[I].MinTemperature then
      begin
        SwapRange := Result[I];
        Result[I] := Result[J];
        Result[J] := SwapRange;
      end;
end;

function lin_BuildReducedTemperatureNodes(
  const Inputs: TArray<TinclInput>; TargetNodeCount: Integer):
  TArray<Double>;
var
  Ranges: TArray<TLinTemperatureRange>;
  Centers: TArray<Double>;
  MergeRange: TArray<Boolean>;
  Nodes: TList<Double>;
  MergeCount, BestIndex: Integer;
  BestWidth, Width, Swap: Double;
begin
  Ranges := lin_BuildTemperatureRanges(Inputs);
  Centers := lin_BuildTemperatureCenters(Inputs);
  if Length(Ranges) <> Length(Centers) then
    raise EInvalidOpException.Create(
      'lin_BuildReducedTemperatureNodes: range/center count mismatch');
  if (TargetNodeCount < Length(Ranges)) or
     (TargetNodeCount > 2 * Length(Ranges)) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'TargetNodeCount must be in %d..%d',
      [Length(Ranges), 2 * Length(Ranges)]);

  SetLength(MergeRange, Length(Ranges));
  MergeCount := 2 * Length(Ranges) - TargetNodeCount;
  for var MergeNo := 1 to MergeCount do
  begin
    BestIndex := -1;
    BestWidth := MaxDouble;
    for var I := 0 to High(Ranges) do
      if not MergeRange[I] then
      begin
        Width := Ranges[I].MaxTemperature - Ranges[I].MinTemperature;
        if (BestIndex < 0) or (Width < BestWidth) then
        begin
          BestIndex := I;
          BestWidth := Width;
        end;
      end;
    if BestIndex < 0 then
      raise EInvalidOpException.Create(
        'lin_BuildReducedTemperatureNodes: no range to merge');
    MergeRange[BestIndex] := True;
  end;

  Nodes := TList<Double>.Create;
  try
    for var I := 0 to High(Ranges) do
      if MergeRange[I] then
        Nodes.Add(Centers[I])
      else
      begin
        Nodes.Add(Ranges[I].MinTemperature);
        Nodes.Add(Ranges[I].MaxTemperature);
      end;
    Result := Nodes.ToArray;
  finally
    Nodes.Free;
  end;

  for var I := 0 to High(Result) - 1 do
    for var J := I + 1 to High(Result) do
      if Result[J] < Result[I] then
      begin
        Swap := Result[I];
        Result[I] := Result[J];
        Result[J] := Swap;
      end;
  if Length(Result) <> TargetNodeCount then
    raise EInvalidOpException.CreateFmt(
      'lin_BuildReducedTemperatureNodes produced %d nodes, expected %d',
      [Length(Result), TargetNodeCount]);
end;

function lin_BuildTemperatureNodes(const Inputs: TArray<TinclInput>):
  TArray<Double>;
const
  MergeTolerance = 1E-9;
var
  Ranges: TArray<TLinTemperatureRange>;
  Nodes: TList<Double>;
  Swap: Double;
begin
  Ranges := lin_BuildTemperatureRanges(Inputs);
  Nodes := TList<Double>.Create;
  try
    for var Range in Ranges do
    begin
      Nodes.Add(Range.MinTemperature);
      Nodes.Add(Range.MaxTemperature);
    end;
    Result := Nodes.ToArray;
  finally
    Nodes.Free;
  end;

  for var I := 0 to High(Result) - 1 do
    for var J := I + 1 to High(Result) do
      if Result[J] < Result[I] then
      begin
        Swap := Result[I];
        Result[I] := Result[J];
        Result[J] := Swap;
      end;

  Nodes := TList<Double>.Create;
  try
    for var Node in Result do
      if (Nodes.Count = 0) or
         (Abs(Node - Nodes[Nodes.Count - 1]) > MergeTolerance) then
        Nodes.Add(Node);
    Result := Nodes.ToArray;
  finally
    Nodes.Free;
  end;

  if Length(Result) < 2 then
    raise EInvalidOpException.Create(
      'lin_BuildTemperatureNodes produced fewer than two nodes');
end;

function lin_CopyTemperatureModel(const Source: TLinTemperatureModel):
  TLinTemperatureModel;
begin
  Result := Source;
  Result.TemperatureNodes := Copy(Source.TemperatureNodes, 0,
    Length(Source.TemperatureNodes));
  Result.CrossTemperatureNodes := Copy(Source.CrossTemperatureNodes, 0,
    Length(Source.CrossTemperatureNodes));
end;

{ TLinTemperatureModel }

class function TLinTemperatureModel.lin_Create(
  const ANodes: array of Double; ACrossLinear: Boolean):
  TLinTemperatureModel;
begin
  Result := Default(TLinTemperatureModel);
  SetLength(Result.TemperatureNodes, Length(ANodes));
  for var I := 0 to High(ANodes) do
    Result.TemperatureNodes[I] := ANodes[I];
  Result.CrossTemperatureNodes := nil;
  Result.CrossLinear := ACrossLinear;
  Result.CrossPiecewise := False;
  Result.lin_Validate;
end;

class function TLinTemperatureModel.lin_CreatePiecewiseCross(
  const ANodes: array of Double): TLinTemperatureModel;
begin
  Result := lin_CreatePiecewiseCrossAt(ANodes, ANodes);
end;

class function TLinTemperatureModel.lin_CreatePiecewiseCrossAt(
  const ANodes, ACrossNodes: array of Double): TLinTemperatureModel;
begin
  Result := lin_Create(ANodes, False);
  SetLength(Result.CrossTemperatureNodes, Length(ACrossNodes));
  for var I := 0 to High(ACrossNodes) do
    Result.CrossTemperatureNodes[I] := ACrossNodes[I];
  Result.CrossPiecewise := True;
  Result.lin_Validate;
end;

class function TLinTemperatureModel.lin_FromInputs(
  const Inputs: TArray<TinclInput>; ACrossLinear: Boolean):
  TLinTemperatureModel;
begin
  Result := lin_Create(lin_BuildTemperatureNodes(Inputs), ACrossLinear);
end;

class function TLinTemperatureModel.lin_FromInputsPiecewiseCross(
  const Inputs: TArray<TinclInput>): TLinTemperatureModel;
begin
  Result := lin_CreatePiecewiseCross(
    lin_BuildTemperatureNodes(Inputs));
end;

class function TLinTemperatureModel.lin_FromInputsFiveNodeCross(
  const Inputs: TArray<TinclInput>): TLinTemperatureModel;
begin
  var CrossNodes := lin_BuildTemperatureCenters(Inputs);
  if Length(CrossNodes) <> 5 then
    raise EInvalidOpException.CreateFmt(
      'lin_FromInputsFiveNodeCross expected five SetNo centers, got %d',
      [Length(CrossNodes)]);
  Result := lin_CreatePiecewiseCrossAt(
    lin_BuildTemperatureNodes(Inputs),
    CrossNodes);
end;

procedure TLinTemperatureModel.lin_Validate;
begin
  if CrossLinear and CrossPiecewise then
    raise EArgumentException.Create(
      'lin_Validate: cross model cannot be both linear and piecewise');
  if Length(TemperatureNodes) < 2 then
    raise EArgumentException.Create(
      'lin_Validate: at least two temperature nodes are required');
  for var I := 0 to High(TemperatureNodes) do
  begin
    if IsNan(TemperatureNodes[I]) or IsInfinite(TemperatureNodes[I]) then
      raise EArgumentException.CreateFmt(
        'lin_Validate: TemperatureNodes[%d] is not finite', [I]);
    if (I > 0) and
       (TemperatureNodes[I] <= TemperatureNodes[I - 1]) then
      raise EArgumentException.CreateFmt(
        'lin_Validate: nodes %d and %d are not strictly increasing',
        [I - 1, I]);
  end;
  if CrossPiecewise then
  begin
    if Length(CrossTemperatureNodes) < 2 then
      raise EArgumentException.Create(
        'lin_Validate: piecewise cross model requires at least two nodes');
    for var I := 0 to High(CrossTemperatureNodes) do
    begin
      if IsNan(CrossTemperatureNodes[I]) or
         IsInfinite(CrossTemperatureNodes[I]) then
        raise EArgumentException.CreateFmt(
          'lin_Validate: CrossTemperatureNodes[%d] is not finite', [I]);
      if (I > 0) and
         (CrossTemperatureNodes[I] <= CrossTemperatureNodes[I - 1]) then
        raise EArgumentException.CreateFmt(
          'lin_Validate: cross nodes %d and %d are not increasing',
          [I - 1, I]);
    end;
  end
  else if Length(CrossTemperatureNodes) <> 0 then
    raise EArgumentException.Create(
      'lin_Validate: non-piecewise model cannot have cross nodes');
end;

function TLinTemperatureModel.lin_NodeCount: Integer;
begin
  Result := Length(TemperatureNodes);
end;

function TLinTemperatureModel.lin_CrossNodeCount: Integer;
begin
  if CrossPiecewise then
    Result := Length(CrossTemperatureNodes)
  else
    Result := 0;
end;

function TLinTemperatureModel.lin_CrossCoeffCount: Integer;
begin
  if CrossPiecewise then
    Result := lin_CrossNodeCount
  else if CrossLinear then
    Result := 2
  else
    Result := 1;
end;

function TLinTemperatureModel.lin_CoeffCount: Integer;
begin
  Result := 2 * lin_NodeCount + 2 * lin_CrossCoeffCount;
end;

function TLinTemperatureModel.lin_OffsetIndex: Integer;
begin
  Result := lin_NodeCount + 2 * lin_CrossCoeffCount;
end;

function TLinTemperatureModel.lin_CreateBasis(
  Temperature: Double): TArray<Double>;
var
  LeftIndex: Integer;
  U: Double;
begin
  lin_Validate;
  if IsNan(Temperature) or IsInfinite(Temperature) then
    raise EArgumentException.Create(
      'lin_CreateBasis: Temperature is not finite');

  SetLength(Result, lin_NodeCount);
  if Temperature <= TemperatureNodes[0] then
  begin
    Result[0] := 1.0;
    Exit;
  end;
  if Temperature >= TemperatureNodes[High(TemperatureNodes)] then
  begin
    Result[High(Result)] := 1.0;
    Exit;
  end;

  LeftIndex := 0;
  while (LeftIndex < High(TemperatureNodes)) and
        (Temperature > TemperatureNodes[LeftIndex + 1]) do
    Inc(LeftIndex);
  U := (Temperature - TemperatureNodes[LeftIndex]) /
    (TemperatureNodes[LeftIndex + 1] - TemperatureNodes[LeftIndex]);
  Result[LeftIndex] := 1.0 - U;
  Result[LeftIndex + 1] := U;
end;

function TLinTemperatureModel.lin_CreateCrossBasis(
  Temperature: Double): TArray<Double>;
var
  LeftIndex: Integer;
  U: Double;
begin
  lin_Validate;
  if not CrossPiecewise then
    raise EInvalidOpException.Create(
      'lin_CreateCrossBasis requires CrossPiecewise=True');
  if IsNan(Temperature) or IsInfinite(Temperature) then
    raise EArgumentException.Create(
      'lin_CreateCrossBasis: Temperature is not finite');

  SetLength(Result, lin_CrossNodeCount);
  if Temperature <= CrossTemperatureNodes[0] then
  begin
    Result[0] := 1.0;
    Exit;
  end;
  if Temperature >= CrossTemperatureNodes[
    High(CrossTemperatureNodes)] then
  begin
    Result[High(Result)] := 1.0;
    Exit;
  end;

  LeftIndex := 0;
  while (LeftIndex < High(CrossTemperatureNodes)) and
        (Temperature > CrossTemperatureNodes[LeftIndex + 1]) do
    Inc(LeftIndex);
  U := (Temperature - CrossTemperatureNodes[LeftIndex]) /
    (CrossTemperatureNodes[LeftIndex + 1] -
     CrossTemperatureNodes[LeftIndex]);
  Result[LeftIndex] := 1.0 - U;
  Result[LeftIndex + 1] := U;
end;

function TLinTemperatureModel.lin_CreateAxisRow(Temperature: Double;
  const Raw: TVector3; OutputAxis: SetVector; Scale: Double): TArray<Double>;
var
  Basis, CrossBasis: TArray<Double>;
  FirstCrossAxis, SecondCrossAxis: SetVector;
  CrossCount, FirstCrossIndex, SecondCrossIndex, OffsetIndex: Integer;
  Tau: Double;
begin
  lin_Validate;
  if IsNan(Scale) or IsInfinite(Scale) or IsZero(Scale) then
    raise EArgumentException.Create('lin_CreateAxisRow: invalid Scale');

  case OutputAxis of
    vX:
      begin
        FirstCrossAxis := vY;
        SecondCrossAxis := vZ;
      end;
    vY:
      begin
        FirstCrossAxis := vX;
        SecondCrossAxis := vZ;
      end;
  else
    begin
      FirstCrossAxis := vX;
      SecondCrossAxis := vY;
    end;
  end;

  Basis := lin_CreateBasis(Temperature);
  CrossCount := lin_CrossCoeffCount;
  FirstCrossIndex := lin_NodeCount;
  SecondCrossIndex := FirstCrossIndex + CrossCount;
  OffsetIndex := lin_OffsetIndex;
  SetLength(Result, lin_CoeffCount);

  for var I := 0 to High(Basis) do
  begin
    Result[I] := Raw.V[Integer(OutputAxis)] / Scale * Basis[I];
    Result[OffsetIndex + I] := Basis[I];
  end;

  if CrossPiecewise then
  begin
    CrossBasis := lin_CreateCrossBasis(Temperature);
    for var I := 0 to High(CrossBasis) do
    begin
      Result[FirstCrossIndex + I] :=
        Raw.V[Integer(FirstCrossAxis)] / Scale * CrossBasis[I];
      Result[SecondCrossIndex + I] :=
        Raw.V[Integer(SecondCrossAxis)] / Scale * CrossBasis[I];
    end;
  end
  else
  begin
    Result[FirstCrossIndex] := Raw.V[Integer(FirstCrossAxis)] / Scale;
    Result[SecondCrossIndex] := Raw.V[Integer(SecondCrossAxis)] / Scale;
    if CrossLinear then
    begin
      Tau := 2.0 * (Temperature - TemperatureNodes[0]) /
        (TemperatureNodes[High(TemperatureNodes)] - TemperatureNodes[0]) - 1.0;
      Tau := EnsureRange(Tau, -1.0, 1.0);
      Result[FirstCrossIndex + 1] :=
        Result[FirstCrossIndex] * Tau;
      Result[SecondCrossIndex + 1] :=
        Result[SecondCrossIndex] * Tau;
    end;
  end;
end;

procedure TLinTemperatureModel.lin_FindAxis(
  const Coefficients: TVArray<Double>; Temperature: Double;
  const Raw: TVector3; Scale: Double; out Corrected: TVector3);
begin
  lin_Validate;
  for var Axis in SVectors do
  begin
    if Length(Coefficients[Axis]) <> lin_CoeffCount then
      raise EArgumentException.CreateFmt(
        'lin_FindAxis: axis %s has %d coefficients, expected %d',
        [string(SVectorsNames[Axis]), Length(Coefficients[Axis]),
         lin_CoeffCount]);
    var Row := lin_CreateAxisRow(Temperature, Raw, Axis, Scale);
    var Value := 0.0;
    for var I := 0 to High(Row) do
      Value := Value + Row[I] * Coefficients[Axis][I];
    Corrected.V[Integer(Axis)] := Value;
  end;
end;

end.
