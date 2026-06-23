unit Dev.Telesistem.Shum;

interface

uses System.SysUtils,  System.Classes, System.TypInfo, System.Rtti, Fibonach, MathIntf, System.Math, Math.Telesistem, JDtools,
     Actns, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl, RootIntf, SubDevImpl, tools,
     Dev.Telesistem;

implementation

type
  TTelesistemShum = class(TFltBPF)
  private
    FKAmp: Double;
    procedure SetKAmp(const Value: Double);
  protected
    Fshum: TArray<Double>;
    procedure DoOutputData(Data: Pointer; DataSize: integer); override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
    function GetCaption: string; override;
  public
    constructor Create; override;
    [DynamicAction('Показать генератор шума <I> ', '<I>', 52, '0:Телесистема.<I>', 'ШУМ')]
    procedure DoSetup(Sender: IAction); override;
    property Shum: TArray<Double> read FShum;
  published
    [ShowProp('Коэффициент амплитуды шума')] property KAmp: Double read FKAmp write SetKAmp;
  end;

{ TTelesistemShum }


constructor TTelesistemShum.Create;
 var
  m: Integer;
begin
  FKAmp := 1;
  inherited;
  FNCH(9, 17);
  m := FFT_AMP_LEN div 4;
  FBCH(Round(m-m/1.7), Round(m-m/3));
end;

procedure TTelesistemShum.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TTelesistemShum.GetCaption: string;
begin
  Result := 'генератор шума';
end;

procedure TTelesistemShum.InputData(Data: Pointer; DataSize: integer);
 var
  d: PDoubleArray;
  i: Integer;
  s: array[0..USO_LEN-1] of Double;
begin
  while Length(Fshum) < DataSize do
   begin
    for i := 0 to USO_LEN-1 do s[i] := Random($FFFF)/$FFFF*5*FKAmp;
    inherited InputData(@s[0], USO_LEN);
   end;

  FS_Data.FifoData.Add(Data, DataSize);
  FS_Data.FifoFShum.Add(@Fshum[0], DataSize);

  d := PDoubleArray(Data);
  for i := 0 to DataSize-1 do d[i] := d[i] + Fshum[i];

  NotifyData;
  if Assigned(FChildSubDevice) then FChildSubDevice.InputData(d, DataSize);
//  inherited DoOutputData(d, DataSize);

  Delete(Fshum, 0, DataSize);
end;

procedure TTelesistemShum.SetKAmp(const Value: Double);
begin
  if FKAmp <> Value then
   begin
    FKAmp := Value;
    Owner.PubChange;
   end;
end;

procedure TTelesistemShum.DoOutputData(Data: Pointer; DataSize: integer);
 var
  lold: Integer;
begin
  lold := Length(Fshum);
  SetLength(Fshum, lold + DataSize);
  Move(Data^, Fshum[lold], DataSize*Sizeof(Double));
end;

initialization
  RegisterClass(TTelesistemShum);
  TRegister.AddType<TTelesistemShum, ITelesistem>.LiveTime(ltTransientNamed);
finalization
  GContainer.RemoveModel<TTelesistemShum>;
end.
