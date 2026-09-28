unit TrrInclin.Temp.LinPacked;

interface

uses
  System.SysUtils, System.Math, System.Variants, Xml.XMLIntf,
  Vector, TrrInclin.Temp.PolyModel;
//  MetrInclin.Temp.Stat, MetrInclin.Temp.MathPoly;

const
  GKI_PACKED_MIN_NODES = 5;
  GKI_PACKED_MAX_NODES = 10;
  GKI_PACKED_MAX_COEFFICIENTS = 2 * GKI_PACKED_MAX_NODES + 4;
  GKI_PACKED_AXIS_COUNT = 3;
  GKI_PACKED_BINARY_SIZE = 626;

type
  TGkiPackedNodes = array[0..GKI_PACKED_MAX_NODES - 1] of Single;
  TGkiPackedAxisCoefficients =
    array[0..GKI_PACKED_MAX_COEFFICIENTS - 1] of Single;
  TGkiPackedSensorCoefficients =
    array[0..GKI_PACKED_AXIS_COUNT - 1] of TGkiPackedAxisCoefficients;

  { Binary format shared with gki_piecewise_linear_model.h.
    All multibyte fields are little-endian. Unused nodes and coefficients
    are zero. }
  TGkiPackedLinearModel = packed record
    NodeCount: Byte;
    CoefficientCount: Byte;
    AccScale: Single;
    MagScale: Single;
    Nodes: TGkiPackedNodes;
    Acc: TGkiPackedSensorCoefficients;
    Mag: TGkiPackedSensorCoefficients;
    class function Default: TGkiPackedLinearModel; static;
  end;

  TGkiPackedCodec = class
  public
    class procedure SaveToXML(Root: IXMLNode;
      const Model: TGkiPackedLinearModel); static;
    class function LoadFromXML(Root: IXMLNode):
      TGkiPackedLinearModel; static;
  end;

  { PC implementation of the same calculation as the AVR class.
    Raw values are sensor ADC/count values.  Corrected vectors use the same
    normalized units as TLinTemperatureModel.lin_FindAxis. }
  TGkiPackedCorrector = class
  private
    FModel: TGkiPackedLinearModel;
    procedure CorrectSensor(Temperature: Single; const Raw: TVector3;
      Scale: Single; const Coefficients: TGkiPackedSensorCoefficients;
      out Corrected: TVector3);
  public
    constructor Create(const Model: TGkiPackedLinearModel);
    class function LoadFromXML(Root: IXMLNode):
      TGkiPackedCorrector; static;
    procedure CorrectAccelerometer(Temperature: Single;
      const Raw: TVector3; out Corrected: TVector3);
    procedure CorrectMagnetometer(Temperature: Single;
      const Raw: TVector3; out Corrected: TVector3);
    procedure CorrectAll(Temperature: Single;
      const RawG, RawH: TVector3; out CorrectedG, CorrectedH: TVector3);
    property Model: TGkiPackedLinearModel read FModel;
  end;

implementation

const
  GkiAxisNames: array[0..GKI_PACKED_AXIS_COUNT - 1] of string =
    ('X', 'Y', 'Z');

class function TGkiPackedLinearModel.Default:
  TGkiPackedLinearModel;
const
  DefaultNodes: array[0..9] of Single =
    (-1000, -500, 0, 500, 1000,0,0,0,0,0);
begin
  FillChar(Result, SizeOf(Result), 0);

  Result.NodeCount := 5;
  Result.CoefficientCount := 14; // 2*5 + 4

  Result.AccScale := 1;
  Result.MagScale := 1;

  for var I := 0 to 9 do
    Result.Nodes[I] := DefaultNodes[I];

  for var Axis := 0 to 2 do
    for var Node := 0 to 4 do
    begin
      { Raw / Scale * Diagonal = Raw }
      Result.Acc[Axis][Node] := Result.AccScale;
      Result.Mag[Axis][Node] := Result.MagScale;
    end;
  for var Axis := 0 to 2 do
    for var Node := 5 to 9 do
    begin
      { Raw / Scale * Diagonal = Raw }
      Result.Acc[Axis][Node] := 0;
      Result.Mag[Axis][Node] := 0;
    end;

  { ќстальные коэффициенты уже равны нулю:
      [5..8]  Ч cross constant/slope;
      [9..13] Ч offsets. }
end;
function GkiInvariantFormatSettings: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := #0;
end;

function GkiFloatArrayToText(const Values: array of Single;
  Count: Integer): string;
var
  Parts: TArray<string>;
  FS: TFormatSettings;
begin
  if (Count < 0) or (Count > Length(Values)) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Invalid XML value count: %d', [Count]);
  FS := GkiInvariantFormatSettings;
  SetLength(Parts, Count);
  for var I := 0 to Count - 1 do
    Parts[I] := FloatToStr(Values[I], FS);
  Result := string.Join(' ', Parts);
end;

function GkiTextToFloatArray(const Text, FieldName: string;
  ExpectedCount: Integer): TArray<Single>;
var
  Parts: TArray<string>;
  FS: TFormatSettings;
  Value: Double;
begin
  Parts := Text.Split([' ', #9, #10, #13],
    TStringSplitOptions.ExcludeEmpty);
  if Length(Parts) < ExpectedCount then
    raise EArgumentException.CreateFmt(
      '%s contains %d values, expected %d',
      [FieldName, Length(Parts), ExpectedCount]);
  FS := GkiInvariantFormatSettings;
  SetLength(Result, ExpectedCount);
  for var I := 0 to ExpectedCount - 1 do
  begin
    if not TryStrToFloat(Parts[I], Value, FS) then
      raise EArgumentException.CreateFmt(
        '%s value %d is not a number: %s',
        [FieldName, I + 1, Parts[I]]);
    Result[I] := Value;
  end;
end;

function GkiAttributeText(const Node: IXMLNode;
  const AttributeName: string): string;
begin
  Result := VarToStr(Node.Attributes[AttributeName]);
end;

function GkiResolveLinNode(const Root: IXMLNode;
  CreateIfMissing: Boolean): IXMLNode;
begin
  if not Assigned(Root) then
    raise EArgumentNilException.Create('Root');
  if SameText(string(Root.NodeName), 'Lin') then
    Exit(Root);
  Result := Root.ChildNodes.FindNode('Lin');
  if not Assigned(Result) and CreateIfMissing then
    Result := Root.AddChild('Lin');
  if not Assigned(Result) then
    raise EArgumentException.Create('XML node Lin was not found');
end;

function GkiResolveSensorNode(const Lin: IXMLNode;
  const SensorName: string; CreateIfMissing: Boolean): IXMLNode;
begin
  Result := Lin.ChildNodes.FindNode(SensorName);
  if not Assigned(Result) and CreateIfMissing then
    Result := Lin.AddChild(SensorName);
  if not Assigned(Result) then
    raise EArgumentException.CreateFmt(
      'XML node Lin.%s was not found', [SensorName]);
end;

class procedure TGkiPackedCodec.SaveToXML(Root: IXMLNode;
  const Model: TGkiPackedLinearModel);

  procedure SaveSensor(const Node: IXMLNode;
    const Coefficients: TGkiPackedSensorCoefficients);
  begin
    for var Axis := 0 to GKI_PACKED_AXIS_COUNT - 1 do
      Node.Attributes[GkiAxisNames[Axis]] :=
        GkiFloatArrayToText(Coefficients[Axis],
          24);
  end;

var
  Lin: IXMLNode;
  FS: TFormatSettings;
begin
  Lin := GkiResolveLinNode(Root, True);
  FS := GkiInvariantFormatSettings;
  Lin.Attributes['NodeCount'] := IntToStr(Model.NodeCount);
  Lin.Attributes['CoefficientCount'] :=
    IntToStr(Model.CoefficientCount);
  Lin.Attributes['AccScale'] := FloatToStr(Model.AccScale, FS);
  Lin.Attributes['MagScale'] := FloatToStr(Model.MagScale, FS);
  Lin.Attributes['Nodes'] := GkiFloatArrayToText(Model.Nodes,
    10);

  SaveSensor(GkiResolveSensorNode(Lin, 'accel', True), Model.Acc);
  SaveSensor(GkiResolveSensorNode(Lin, 'magnit', True), Model.Mag);
end;

class function TGkiPackedCodec.LoadFromXML(Root: IXMLNode):
  TGkiPackedLinearModel;

  procedure LoadSensor(const Node: IXMLNode;
    var Coefficients: TGkiPackedSensorCoefficients);
  begin
    for var Axis := 0 to GKI_PACKED_AXIS_COUNT - 1 do
    begin
      var Values := GkiTextToFloatArray(
        GkiAttributeText(Node, GkiAxisNames[Axis]),
        'Lin.' + string(Node.NodeName) + '.' + GkiAxisNames[Axis],
        Result.CoefficientCount);
      for var I := 0 to Result.CoefficientCount - 1 do
        Coefficients[Axis][I] := Values[I];
    end;
  end;

var
  Lin: IXMLNode;
  FS: TFormatSettings;
  Scale: Double;
  NodeCount, CoefficientCount: Integer;
begin
  Result := Default(TGkiPackedLinearModel);
  Lin := GkiResolveLinNode(Root, False);
  NodeCount := StrToInt(GkiAttributeText(Lin, 'NodeCount'));
  CoefficientCount := StrToInt(
    GkiAttributeText(Lin, 'CoefficientCount'));
  if (NodeCount < GKI_PACKED_MIN_NODES) or
     (NodeCount > GKI_PACKED_MAX_NODES) then
    raise EArgumentException.CreateFmt(
      'Lin.NodeCount must be %d..%d, got %d',
      [GKI_PACKED_MIN_NODES, GKI_PACKED_MAX_NODES, NodeCount]);
  if CoefficientCount <> 2 * NodeCount + 4 then
    raise EArgumentException.CreateFmt(
      'Lin.CoefficientCount must be %d for %d nodes, got %d',
      [2 * NodeCount + 4, NodeCount, CoefficientCount]);
  Result.NodeCount := NodeCount;
  Result.CoefficientCount := CoefficientCount;

  FS := GkiInvariantFormatSettings;
  if not TryStrToFloat(GkiAttributeText(Lin, 'AccScale'), Scale, FS) then
    raise EArgumentException.Create('Lin.AccScale is not a number');
  Result.AccScale := Scale;
  if not TryStrToFloat(GkiAttributeText(Lin, 'MagScale'), Scale, FS) then
    raise EArgumentException.Create('Lin.MagScale is not a number');
  Result.MagScale := Scale;

  var NodeValues := GkiTextToFloatArray(
    GkiAttributeText(Lin, 'Nodes'), 'Lin.Nodes', Result.NodeCount);
  for var I := 0 to Result.NodeCount - 1 do
    Result.Nodes[I] := NodeValues[I];

  LoadSensor(GkiResolveSensorNode(Lin, 'accel', False), Result.Acc);
  LoadSensor(GkiResolveSensorNode(Lin, 'magnit', False), Result.Mag);
end;


constructor TGkiPackedCorrector.Create(
  const Model: TGkiPackedLinearModel);
begin
  inherited Create;
  FModel := Model;
end;

class function TGkiPackedCorrector.LoadFromXML(
  Root: IXMLNode): TGkiPackedCorrector;
begin
  Result := TGkiPackedCorrector.Create(
    TGkiPackedCodec.LoadFromXML(Root));
end;

procedure TGkiPackedCorrector.CorrectSensor(Temperature: Single;
  const Raw: TVector3; Scale: Single;
  const Coefficients: TGkiPackedSensorCoefficients;
  out Corrected: TVector3);
const
  FirstCrossAxis: array[0..2] of Integer = (1, 0, 0);
  SecondCrossAxis: array[0..2] of Integer = (2, 2, 1);
var
  LeftNode, RightNode, NodeCount, OffsetIndex: Integer;
  U, Tau, Diagonal, Offset, FirstCross, SecondCross: Single;
begin
  if IsNan(Temperature) or IsInfinite(Temperature) then
    raise EArgumentException.Create('Temperature is not finite');
  NodeCount := FModel.NodeCount;
  if Temperature <= FModel.Nodes[0] then
  begin
    LeftNode := 0;
    RightNode := 0;
    U := 0;
  end
  else if Temperature >= FModel.Nodes[NodeCount - 1] then
  begin
    LeftNode := NodeCount - 1;
    RightNode := LeftNode;
    U := 0;
  end
  else
  begin
    LeftNode := 0;
    while Temperature > FModel.Nodes[LeftNode + 1] do
      Inc(LeftNode);
    RightNode := LeftNode + 1;
    U := (Temperature - FModel.Nodes[LeftNode]) /
      (FModel.Nodes[RightNode] - FModel.Nodes[LeftNode]);
  end;

  Tau := 2 * (Temperature - FModel.Nodes[0]) /
    (FModel.Nodes[NodeCount - 1] - FModel.Nodes[0]) - 1;
  Tau := EnsureRange(Tau, -1.0, 1.0);
  OffsetIndex := NodeCount + 4;

  for var Axis := 0 to GKI_PACKED_AXIS_COUNT - 1 do
  begin
    if LeftNode = RightNode then
    begin
      Diagonal := Coefficients[Axis][LeftNode];
      Offset := Coefficients[Axis][OffsetIndex + LeftNode];
    end
    else
    begin
      Diagonal := Coefficients[Axis][LeftNode] * (1 - U) +
        Coefficients[Axis][RightNode] * U;
      Offset := Coefficients[Axis][OffsetIndex + LeftNode] * (1 - U) +
        Coefficients[Axis][OffsetIndex + RightNode] * U;
    end;
    FirstCross := Coefficients[Axis][NodeCount] +
      Coefficients[Axis][NodeCount + 1] * Tau;
    SecondCross := Coefficients[Axis][NodeCount + 2] +
      Coefficients[Axis][NodeCount + 3] * Tau;
    Corrected.V[Axis] :=
      Raw.V[Axis] / Scale * Diagonal +
      Raw.V[FirstCrossAxis[Axis]] / Scale * FirstCross +
      Raw.V[SecondCrossAxis[Axis]] / Scale * SecondCross + Offset;
  end;
end;

procedure TGkiPackedCorrector.CorrectAccelerometer(Temperature: Single;
  const Raw: TVector3; out Corrected: TVector3);
begin
  CorrectSensor(Temperature, Raw, FModel.AccScale,
    FModel.Acc, Corrected);
end;

procedure TGkiPackedCorrector.CorrectMagnetometer(Temperature: Single;
  const Raw: TVector3; out Corrected: TVector3);
begin
  CorrectSensor(Temperature, Raw, FModel.MagScale,
    FModel.Mag, Corrected);
end;

procedure TGkiPackedCorrector.CorrectAll(Temperature: Single;
  const RawG, RawH: TVector3; out CorrectedG, CorrectedH: TVector3);
begin
  CorrectAccelerometer(Temperature, RawG, CorrectedG);
  CorrectMagnetometer(Temperature, RawH, CorrectedH);
end;

end.
