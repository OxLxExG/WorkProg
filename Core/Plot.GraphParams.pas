unit Plot.GraphParams;

interface

uses SysUtils, Classes, Plot, RootImpl, debug_except, LAS, LasImpl, Container, System.Variants,JDtools;

type
  TGraphParamArrayArrayVariant = class(TGraphParam)
  protected
    FRecordCount, FXIndex: Integer;
    FMinY, FMaxY: Double;
    function  GetData: TArray<TArray<Variant>>; virtual; abstract;
    procedure UpdateMinMaxY(var MinY, MaxY: Double); override; // internal TCustomPlotDB
    function RecordCount: Integer; override; // internal RecalcScale
    function CheckEOFandGetXY(var X,Y: Double; GoToFirst: Boolean = false): Boolean; override; // internal RecalcScale
  public
    procedure UpdateFields; virtual; abstract;
  end;

  TGraphParamLAS = class(TGraphParamArrayArrayVariant)
  protected
    FFileName: string;
    FXName: string;
    FYName: string;
    function  GetData: TArray<TArray<Variant>>; override;
  public
    procedure UpdateFields; override;
    class function Exists(Params: TGraphParams; const LasFile, AXName: string): boolean;
    [ShowProp('Источник данных Y', True)] property YFiedName: string read FYName;
  published
    [ShowProp('Источник данных X', True)] property XName: string read FXName write FXName;
    [ShowProp('LAS файл', True)] property FileName: string read FFileName write FFileName;
  end;

  TGraphParamStrings = class(TGraphParamArrayArrayVariant)
  private
    FData: TStringList;
    FVData: TArray<TArray<Variant>>;
  protected
    function  GetData: TArray<TArray<Variant>>; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure UpdateFields; override;
    class function Exists(Params: TGraphParams; const ATitle: string): boolean;
  published
    property Data: TStringList read FData write FData;
  end;

implementation

uses Math;

{$REGION 'TGraphParamArray'}

{ TGraphParamArray }

function TGraphParamArrayArrayVariant.CheckEOFandGetXY(var X, Y: Double; GoToFirst: Boolean): Boolean;
  {$J+}
 const
  I: Integer=0;
  D: TArray<TArray<Variant>> = nil;
 {$J-}
  procedure ApplyData;
  begin
    if VarisNull(D[i, FXIndex]) then X := NULL_VALL
    else X := D[i, FXIndex];
    Y := D[i, 0];
  end;
begin
  if FRecordCount = 0 then UpdateFields;
  if Plot.Mirror = 1 then
   begin
    if GoToFirst then
     begin
      I := 0;
      D := GetData;//GetLasDoc(FFileName).Data.Items;
      if Length(d) = 0 then Exit(False);
      ApplyData;
      Inc(i);
      if Length(d) = i then Exit(False);
      Exit(True);
     end;
    ApplyData;
    Inc(i);
    Result := I>=Length(D);
   end
  else
   begin
    if GoToFirst then
     begin
      I := FRecordCount;
      D := GetData;//GetLasDoc(FFileName).Data.Items;
      if Length(d) = 0 then Exit(False);
      ApplyData;
      Dec(i);
      if Length(d) = i then Exit(False);
      Exit(True);
     end;
    ApplyData;
    Dec(i);
    Result := I<0;
   end;
  if Result then D := nil;
end;

function TGraphParamArrayArrayVariant.RecordCount: Integer;
begin
  if FRecordCount = 0 then UpdateFields;
  Result := FRecordCount;
end;

procedure TGraphParamArrayArrayVariant.UpdateMinMaxY(var MinY, MaxY: Double);
begin
  UpdateFields;
  MinY := Min(MinY, FMinY);
  MaxY := Max(MaxY, FMaxY);
end;

{$ENDREGION}

{ TGraphParamLAS }

class function TGraphParamLAS.Exists(Params: TGraphParams; const LasFile, AXName: string): boolean;
 var
  p: TGraphParam;
begin
  Result := False;
  for p in Params do if p is TGraphParamLAS then with TGraphParamLAS(p) do
   if SameText(FileName, LasFile) and SameText(XName, AXName) then Exit(True);
end;

function TGraphParamLAS.GetData: TArray<TArray<Variant>>;
begin
  Result := GetLasDoc(FFileName, lsenANSI).Data.Items;
end;

procedure TGraphParamLAS.UpdateFields;
 var
  ld: ILasDoc;
  Mnm: TArray<string>;
  i: Integer;
begin
  ld := GetLasDoc(FileName, lsenANSI);
  FRecordCount := Length(ld.Data.Items);
  FMinY := ld.Data.Items[0, 0];
  FMaxY := ld.Data.Items[FRecordCount-1, 0];
  Mnm := ld.Curve.Mnems;
  FYName := Mnm[0];
  Title := ld.Curve.Items[FXName].Description;
  if Title ='' then Title := FXName;
  EUnit := ld.Curve.Items[FXName].Units;
  for i := 0 to Length(Mnm)-1 do if Mnm[i] = FXName then
   begin
    FXIndex := i;
    Break;
   end;
end;

{ TGraphParamStrings }

constructor TGraphParamStrings.Create(Collection: TCollection);
begin
  inherited;
  FData := TStringList.Create;
  FXIndex := 1;
end;

destructor TGraphParamStrings.Destroy;
begin
  FData.Free;
  inherited;
end;

class function TGraphParamStrings.Exists(Params: TGraphParams; const ATitle: string): boolean;
 var
  p: TGraphParam;
begin
  Result := False;
  for p in Params do if p is TGraphParamStrings then if SameText(p.Title, ATitle) then Exit(True);
end;

function TGraphParamStrings.GetData: TArray<TArray<Variant>>;
begin
  Result := FVData;
end;

procedure TGraphParamStrings.UpdateFields;
  function GetArray(const ast : string): TArray<Variant>;
    function VarFromString(const sData: string): Variant;
    begin
      if sData = '' then Result := Null
      else Result := sData.ToDouble();
    end;
   var
    a: TArray<string>;
  begin
    a := ast.Split([';']);
    SetLength(Result , 2);
    Result[0] := VarFromString(a[0]);
    Result[1] := VarFromString(a[1]);
  end;
 var
  i: integer;
begin
  FRecordCount := FData.Count;
  if FRecordCount = 0 then Exit;
  SetLength(FVData, FRecordCount);
  for i := 0 to FRecordCount-1 do FVData[i] := GetArray(FData[i]);
end;

initialization
  RegisterClasses([TGraphParamLAS, TGraphParamStrings]);
end.
