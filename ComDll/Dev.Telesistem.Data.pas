unit Dev.Telesistem.Data;

interface

uses System.SysUtils,  System.Classes, System.TypInfo, System.Rtti, Fibonach, MathIntf, System.Math, Math.Telesistem,
     Xml.XMLIntf, JDtools,
     Actns, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl, RootIntf, SubDevImpl, tools, AVRtypes;


type

  TCustomTeleData = class(TSubDevWithForm<TPriborData>)
  private
    FPorogXY: Integer;
    FPorogZ: Integer;
    FDMetka: Double;
    prbo, prbz, prbao, prba, prbvib: Double;
    procedure SetPorogXY(const Value: Integer);
    procedure SetPorogZ(const Value: Integer);
    procedure SetDMetka(const Value: Double);
    type
     CodeData = (cdMOtk1, cdAX, cdAy, adAz, cdMx, cdMOtk2, cdMy, cdMz,cdDxy, cdDz, cdMOtk3, cdCMD);
  protected
    FFileName: string;
    procedure SetPrbData(tip: TDataType; const Value, Probability: Double);
    function TryGetRoot(var v: Variant; adr: integer): Boolean;
    procedure SetCollection(Value: TCollection); override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
     procedure OnUserRemove; override;
  public
    constructor Create; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
    function GetMetaData: IXMLInfo; virtual;
    function MinPorog: Double;
    property FileName: string read FFileName;
    [DynamicAction('Показать окно Отклонителя', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Отклонителя')]
    procedure DoSetup(Sender: IAction); override;
  published
    [ShowProp('Порог вибрации XY')] property PorogXY: Integer read FPorogXY write SetPorogXY default 10;
    [ShowProp('Порог вибрации Z')]  property PorogZ: Integer read FPorogZ write SetPorogZ default 10;
    [ShowProp('Сдвиг метки отклонителя (º)')]  property DMetka: Double read FDMetka write SetDMetka;
  end;

implementation

{ TCustomTeleData }

uses Dev.Telesistem;

constructor TCustomTeleData.Create;
begin
  FPorogXY := 10;
  FPorogZ := 10;
  inherited;
  InitConst('TOtkForm', 'OtkForm_');
  TDebug.Log('TCustomTeleData.Create;');
end;

procedure TCustomTeleData.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TCustomTeleData.GetCaption: string;
begin
  Result := 'test telesis 1'
end;

function TCustomTeleData.GetCategory: TSubDeviceInfo;
begin
  Result.Category := 'Данные';
  Result.Typ := [sdtUniqe, sdtMastExist];
end;

function TCustomTeleData.GetMetaData: IXMLInfo;
 var
  GDoc: IXMLDocument;
begin
  FFileName := ExtractFilePath(ParamStr(0)) + 'Devices\tst_telesis1.hxml';
  GDoc := NewXDocument();
  GDoc.LoadFromFile(FileName);
  Result := GDoc.DocumentElement;
end;

procedure TCustomTeleData.InputData(Data: Pointer; DataSize: integer);
 var
  v: Variant;
  deltaOtk: Double;
  function cor360(a: Double): double;
  begin
    if a < 0 then Result := a + 360
    else if a >=360 then Result := a - 360
    else Result := a
  end;
begin
  // test for decoder
  if (DataSize <> $12345678) or not TryGetRoot(v,1000) then Exit;
  with TTelesistemDecoder(Data) do
   begin
  case State of
    csFindSP: ;
    csSP: with SPData, SPIndex do
     begin
      v.СП.Уход_тактов.DEV.VALUE := 0;
      v.СП.Амплитуда.DEV.VALUE := SimpleRoundTo(Amp, -1);
      v.СП.Фаза.DEV.VALUE := Faza;
      v.СП.Q_СП.DEV.VALUE := Round(Porog);
     end;
    csCheckSP: with SPData, CheckSPIndex do
     begin
      v.СП.Уход_тактов.DEV.VALUE := Dkadr;
      v.СП.Амплитуда.DEV.VALUE := SimpleRoundTo(Amp, -1);
      v.СП.Фаза.DEV.VALUE := Fazanew;
      v.СП.Q_СП.DEV.VALUE := Round(Porog);
     end;
    csCode: with Codes do
     begin
      case CodeData(CodeCnt-1) of
        cdMOtk1:
         begin
          deltaOtk := v.Inclin.статика.отклонитель.CLC.VALUE - v.Inclin.статика.маг_отклон.CLC.VALUE;
          v.Inclin.маг_отклон1.DEV.VALUE := cor360(CodData[CodeCnt-1].Code + DMetka);
          v.Inclin.маг_отклон1.CLC.VALUE :=  cor360(CodData[CodeCnt-1].Code + deltaOtk + DMetka);
          v.Inclin.Q_маг_отклон1.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          SetPrbData(dtAO, v.Inclin.маг_отклон1.DEV.VALUE, v.Inclin.Q_маг_отклон1.DEV.VALUE);
          SetPrbData(dtOtklonitel, v.Inclin.маг_отклон1.CLC.VALUE, v.Inclin.Q_маг_отклон1.DEV.VALUE);
         end;
        cdAX:
         begin
          v.Inclin.accel.X.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.accel.Q_X.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
         end;
        cdAy:
         begin
          v.Inclin.accel.Y.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.accel.Q_Y.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
         end;
        adAz:
         begin
          v.Inclin.accel.Z.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.accel.Q_Z.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
         end;
        cdMx:
         begin
          v.Inclin.magnit.X.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.magnit.Q_X.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
         end;
        cdMOtk2:
         begin
          deltaOtk := v.Inclin.статика.отклонитель.CLC.VALUE - v.Inclin.статика.маг_отклон.CLC.VALUE;
          v.Inclin.маг_отклон2.DEV.VALUE := cor360(CodData[CodeCnt-1].Code + DMetka);
          v.Inclin.маг_отклон2.CLC.VALUE :=  cor360(CodData[CodeCnt-1].Code + deltaOtk + DMetka);
          v.Inclin.Q_маг_отклон2.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          SetPrbData(dtAO, v.Inclin.маг_отклон2.DEV.VALUE, v.Inclin.Q_маг_отклон2.DEV.VALUE);
          SetPrbData(dtOtklonitel, v.Inclin.маг_отклон2.CLC.VALUE, v.Inclin.Q_маг_отклон2.DEV.VALUE);
         end;
        cdMy:
         begin
          v.Inclin.magnit.Y.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.magnit.Q_Y.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
         end;
        cdMz:
         begin
          v.Inclin.magnit.Z.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.magnit.Q_Z.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          TTelesistem(Owner).ExecMetrology;
          v.Inclin.отклонитель.CLC.VALUE := cor360(v.Inclin.отклонитель.CLC.VALUE + DMetka);
          v.Inclin.маг_отклон.CLC.VALUE := cor360(v.Inclin.маг_отклон.CLC.VALUE + DMetka);

          prbo := Min(v.Inclin.accel.Q_X.DEV.VALUE, v.Inclin.accel.Q_Y.DEV.VALUE);
          prbz := Min(prbo, v.Inclin.accel.Q_Z.DEV.VALUE);

          SetPrbData(dtOtklonitel, v.Inclin.отклонитель.CLC.VALUE, prbo);
          SetPrbData(dtZenit, v.Inclin.зенит.CLC.VALUE, prbz);

          prbao := Min(v.Inclin.magnit.Q_X.DEV.VALUE, v.Inclin.magnit.Q_Y.DEV.VALUE);
          prba := MinValue([prbao, prbz, v.Inclin.magnit.Q_Z.DEV.VALUE]);

          SetPrbData(dtAO, v.Inclin.маг_отклон.CLC.VALUE, prbao);
          SetPrbData(dtAzimut, v.Inclin.азимут.CLC.VALUE, prba);
         end;
        cdDxy:
         begin
          v.Inclin.accel.DXY.DEV.VALUE := (CodData[CodeCnt-1].Code-1292)/2;
          v.Inclin.accel.Q_DXY.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          if v.Inclin.accel.DXY.DEV.VALUE < 0 then v.Inclin.accel.Q_DXY.DEV.VALUE := 0;
         end;
        cdDz:
         begin
          v.Inclin.accel.DZ.DEV.VALUE := CodData[CodeCnt-1].Code-1292;
          v.Inclin.accel.Q_DZ.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          if v.Inclin.accel.DZ.DEV.VALUE < 0 then v.Inclin.accel.Q_DZ.DEV.VALUE := 0;
          prbvib := Min(v.Inclin.accel.Q_DZ.DEV.VALUE, v.Inclin.accel.Q_DXY.DEV.VALUE);
          if (v.Inclin.accel.DXY.DEV.VALUE < PorogXY) and (v.Inclin.accel.DZ.DEV.VALUE < PorogZ) and
          (MinValue([prbo,prbao, prbvib]) > MinPorog) then
           begin
            v.Inclin.статика.отклонитель.CLC.VALUE := v.Inclin.отклонитель.CLC.VALUE;
            v.Inclin.статика.маг_отклон.CLC.VALUE := v.Inclin.маг_отклон.CLC.VALUE;

            SetPrbData(dtOtklonitelZamer, v.Inclin.отклонитель.CLC.VALUE, prbo);
            SetPrbData(dtAOZamer, v.Inclin.маг_отклон.CLC.VALUE, prbao);

            SetPrbData(dtZamerZenit, v.Inclin.зенит.CLC.VALUE, prbz);
            SetPrbData(dtZamerAzimut, v.Inclin.азимут.CLC.VALUE, prba);
           end;
         end;
        cdMOtk3:
         begin
          deltaOtk := v.Inclin.статика.отклонитель.CLC.VALUE - v.Inclin.статика.маг_отклон.CLC.VALUE;
          v.Inclin.маг_отклон3.DEV.VALUE := cor360(CodData[CodeCnt-1].Code + DMetka);
          v.Inclin.маг_отклон3.CLC.VALUE := cor360(CodData[CodeCnt-1].Code + deltaOtk + DMetka);
          v.Inclin.Q_маг_отклон3.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          SetPrbData(dtAO, v.Inclin.маг_отклон3.DEV.VALUE, v.Inclin.Q_маг_отклон3.DEV.VALUE);
          SetPrbData(dtOtklonitel, v.Inclin.маг_отклон3.CLC.VALUE, v.Inclin.Q_маг_отклон3.DEV.VALUE);
         end;
        cdCMD:
         begin
          v.Cmd.DEV.VALUE := CodData[CodeCnt-1].Code;
          v.Q_Cmd.DEV.VALUE := Round(CodData[CodeCnt-1].Porog);
          TTelesistem(Owner).SaveLogData;
         end;
      end;
      TTelesistem(owner).CheckWorkData;
      TTelesistem(owner).Notify('S_WorkEventInfo');
     end;
  end;
   end;
end;

function TCustomTeleData.MinPorog: Double;
begin
  Result := 30;
end;

procedure TCustomTeleData.OnUserRemove;
begin
  inherited;
  TTelesistem(Owner).RemoveMetaData;
end;

procedure TCustomTeleData.SetCollection(Value: TCollection);
begin
  inherited;
  if (Value <> nil) then TTelesistem(Owner).InitMetaData(nil);
end;

procedure TCustomTeleData.SetDMetka(const Value: Double);
begin
  FDMetka := Value;
end;

procedure TCustomTeleData.SetPorogXY(const Value: Integer);
begin
  FPorogXY := Value;
end;

procedure TCustomTeleData.SetPorogZ(const Value: Integer);
begin
  FPorogZ := Value;
end;

procedure TCustomTeleData.SetPrbData(tip: TDataType; const Value, Probability: Double);
begin
  FS_Data.DataType := tip;
  FS_Data.Data := Value;
  FS_Data.Probability := Probability;
  NotifyData;
end;

function TCustomTeleData.TryGetRoot(var v: Variant; adr: integer): Boolean;
 var
  w: IXMLNode;
begin
  Result := False;
  if Assigned(owner) and Assigned(TTelesistem(owner).S_MetaDataInfo.Info) then
   begin
    w := FindWork(TTelesistem(owner).S_MetaDataInfo.Info, adr);
    if Assigned(w) then
     begin
      v := XToVar(w);
      Result := True;
     end;
   end;
end;

initialization
  RegisterClasses([TCustomTeleData]);
  TRegister.AddType<TCustomTeleData, ITelesistem>.LiveTime(ltTransientNamed);
finalization
  GContainer.RemoveModel<TCustomTeleData>;
end.
