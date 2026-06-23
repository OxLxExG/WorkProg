unit AutoMetr.Inclin;

interface

uses System.SysUtils, System.Generics.Collections, Vcl.ExtCtrls, System.Types, Vcl.Dialogs,
ExtendIntf, MetrForm, Xml.XMLIntf, RootIntf, RootImpl, UakiIntf, Container, DeviceIntf, debug_except, tools;

type
  TinclAuto = class;
/// движение по к значениям стола
  TGOTask = class
   Owner: TinclAuto;
   ax: IAxis;
   Ang: TAngle;
   FIterDelay: Integer;
   IterCnt: Integer;
   FTolerance: Double;
   procedure Iterate; virtual;
   constructor Create(AOwner: TinclAuto; Angl: TAngle; axs: IAxis; tolerance: Double);
   destructor Destroy; override;
   procedure Start; virtual;
   function CheckAngle(CurAndle: TAngle): Boolean;
  end;

  TGODev = class(TGOTask)
   FpathX, FpathY: string;
   function DevAng: TAngle;
   constructor Create(AOwner: TinclAuto; Angl: TAngle; axs: IAxis; const pathX, pathY: string; tolerance: Double; NIterate: Integer);
   procedure Start(); override;
   procedure Iterate; override;
  end;

  // 1 подождать выполнение заданий стола
  // 2 итерациями найти макс или мин  90 45 и тд
  //
  { TODO :
т.к. нет команды относительного поворота нужно продумать работу алгоритма в районе 0
пока не делаю сложно разработать акуратную работу}
{  TGOMaxMinVIzir = class(TGOTask)
   LastAmp: Double;
   LastAng: TAngle;
   FIsRun: Boolean;
   FIsMax: Integer;
   Fpath: string;
   constructor Create(AOwner: TinclAuto; NewVizir: TAngle; axsVizir: IAxis; const pathXorY: string; IsMax: Boolean);
   function AxisMax: Double;
   procedure Start(); override;
   procedure Iterate; override;
  end;}

  TTaskTemp = class(TGOTask)
   FIsNagrev: Boolean;
   Fuaki: IUaki;
   FTemp: Double;
   Fpath: string;
   constructor Create(AOwner: TinclAuto; const pathT: string; Temp: Double; IsNagrev: Boolean; uaki: IUaki);
   function CurTemp: Double;
   procedure Start(); override;
   procedure Iterate; override;
  end;

  TinclAuto = class(TAutomatMetrology)
  private
   type
    TEndAutomat = (eaNone, eaCreateTask, eaStartTask, eaWaitTask, eaWaitDelay, eaError);
   var
    FErrorTimer: TTimer;
    FTask: TObjectList<TGOTask>;
    Fauto: TEndAutomat;
    FNeedWaitTask: Boolean;
    ErrorHFlag: Boolean;
    NeedRestartAutomatFlag: Boolean;
    Fuaki: IUaki;
    FC_AxisUpdate: Integer;
    FLastErr: string;
    procedure OnErrorTimer(Sender: TObject);
    function GetUaki: IUaki;
    procedure SetC_AxisUpdate(const Value: Integer);
    function AxisReady: Boolean;
    procedure RunAutomat;
    procedure OnErrorH(Sender: TObject);
    procedure OnEndErrorH(Sender: TObject);
  protected
    procedure StartStep(Step: IXMLNode); override;
    procedure KadrEvent(); override;
    procedure Stop(); override;
    procedure DoStop();  override;
  public
    constructor Create(const Controller: IInterface; Rep: TStepMetrologyEvent); reintroduce;
    destructor Destroy; override;
    function UakiExists: Boolean;
    property uaki: IUaki read GetUaki;
    property C_AxisUpdate: Integer read FC_AxisUpdate write SetC_AxisUpdate;
  end;


implementation

uses math, AutoMetr.Inclin.ChekH;

{ TGOTask }

function TGOTask.CheckAngle(CurAndle: TAngle): Boolean;
  function DeltaAngle(a: Double): Double;
  begin
    Result := DegNormalize(a);
    if Result > 180  then Result := Result - 360;
  end;
begin
  Result := Abs(DeltaAngle(Ang - CurAndle)) < FTolerance
end;

constructor TGOTask.Create(AOwner: TinclAuto; Angl: TAngle; axs: IAxis; tolerance: Double);
begin
  Owner := AOwner;
  ax := axs;
  Ang := Angl;
  FTolerance := Tolerance;
  Owner.FTask.Add(self);
end;

destructor TGOTask.Destroy;
begin
  inherited;
end;

procedure TGOTask.Iterate;
begin
  if not CheckAngle(ax.CurrentAngle) then
   begin
    Owner.Fauto := eaError;
    Owner.Report(samError, Format('Угол не получен: надо %1.3f есть %1.3f',[Double(ang), Double(ax.CurrentAngle)]));
    Owner.Error(Format('Угол не получен: надо %1.3f есть %1.3f',[Double(ang), Double(ax.CurrentAngle)]));
   end;
  Owner.FTask.Remove(Self);
end;

procedure TGOTask.Start();
begin
  ax.GotoAngle(Ang);
end;

{ TGODev }

constructor TGODev.Create(AOwner: TinclAuto; Angl: TAngle; axs: IAxis; const pathX, pathY: string; tolerance: Double; NIterate: Integer);
begin
  FpathX := pathX;
  FpathY := pathY;
  IterCnt := NIterate;
  inherited Create(AOwner, Angl, axs, Tolerance);
end;

function TGODev.DevAng: TAngle;
 var
  x, y: IXMLNode;
begin
  if not TryGetX(Owner.FMetr, FpathX + '.CLC', x, 'VALUE') then raise EFormMetrolog.Createfmt('Путь %s не найден', [FpathX]);
  if not TryGetX(Owner.FMetr, FpathY + '.CLC', y, 'VALUE') then raise EFormMetrolog.Createfmt('Путь %s не найден', [FpathY]);
  Result := RadToDeg(ArcTan2(Y.NodeValue, -X.NodeValue));
end;

procedure TGODev.Iterate;
begin
  try
    if IterCnt = 0 then
     begin
      Owner.Fauto := eaError;
      Owner.Report(samError, Format('Угол не получен: надо %1.3f есть %1.3f',[Double(ang), Double(DevAng)]));
      Owner.Error(Format('Угол не получен: надо %1.3f есть %1.3f',[Double(ang), Double(DevAng)]));
      Owner.FTask.Remove(Self)
     end
    else
     begin
//      if not Owner.AxisReady then
//       begin
//        Owner.Report(samRun, 'Оси в движении: '+ Owner.FLastErr);
//        Exit;
//       end;
      if FIterDelay > 0 then
       begin
        Owner.Report(samRun, 'Cтабилизация итерации: '+ FIterDelay.ToString());
        Dec(FIterDelay);
        Exit;
       end;
      Dec(IterCnt);
      if CheckAngle(DevAng) then
       begin
        owner.FNeedWaitTask := False;
        Owner.FTask.Remove(Self);
       end
      else Start;
     end;
  except
   Owner.FTask.Remove(Self);
   raise;
  end;
end;

procedure TGODev.Start();
 var
  a, da: TAngle;
begin
  FIterDelay := owner.FStep.Attributes['Dalay_Kadr'];
  da := DevAng;
  a := ax.CurrentAngle + Ang - da;
  Owner.Report(samRun, Format('Переход с %.1f  на %.1f  приб: %.1f надо: %.1f',[ax.CurrentAngle.Angle, a.Angle, Ang.Angle, da.Angle]));
  ax.GotoAngle(a);
end;


{ TGOMaxMinVIzir }

{function TGOMaxMinVIzir.AxisMax: Double;
 var
  x: IXMLNode;
begin
  if not TryGetX(Owner.FMetr, Fpath, x, 'VALUE') then raise EFormMetrolog.Createfmt('Путь %s не найден', [Fpath]);
  Result := FIsMax * X.NodeValue;
end;

constructor TGOMaxMinVIzir.Create(AOwner: TinclAuto; NewVizir: TAngle; axsVizir: IAxis; const pathXorY: string; IsMax: Boolean);
begin
  Fpath := pathXorY;
  if IsMax then FIsMax := 1 else FIsMax := -1;
  inherited Create(AOwner, NewVizir, axsVizir, 2);
end;

procedure TGOMaxMinVIzir.Iterate;
begin
  if FIsRun then
   begin

   end
  else if Owner.FTask.Count = 1 then
   begin
    FIsRun := True;
    IterCnt := 10;
    LastAmp := AxisMax;
    LastAng := ax.CurrentAngle;
   end;
end;

procedure TGOMaxMinVIzir.Start;
begin
  FIsRun := False;
end;}


{ TTaskTempOst }

constructor TTaskTemp.Create(AOwner: TinclAuto; const pathT: string; Temp: Double; IsNagrev: Boolean; uaki: IUaki);
begin
  Owner := AOwner;
  Fpath := pathT;
  FTemp := Temp;
  Fuaki := uaki;
  FIsNagrev := IsNagrev;
  Owner.FTask.Add(self);
end;

function TTaskTemp.CurTemp: Double;
 var
  x: IXMLNode;
begin
  if not TryGetX(Owner.FMetr, Fpath, x, 'VALUE') then raise EFormMetrolog.Createfmt('Путь %s не найден', [Fpath]);
  Result := x.NodeValue;
end;

procedure TTaskTemp.Iterate;
begin
  Owner.FErrorTimer.Enabled := False;
  Owner.FErrorTimer.Enabled := True;
  if (not FIsNagrev and (CurTemp - FTemp <= 0)) or (FIsNagrev and (CurTemp - FTemp >= 0)) then
   begin
     Fuaki.TenStop;
     Owner.FTask.Remove(Self)
   end
  else
     if FIsNagrev then Owner.Report(samRun, Format('Нагрев от %1.0f до %1.0f',[CurTemp, FTemp]))
      else Owner.Report(samRun, Format('Остывание от %1.0f до %1.0f',[CurTemp, FTemp]));
end;

procedure TTaskTemp.Start;
begin
   if FIsNagrev then Fuaki.TenStart
   else Fuaki.TenStop;
end;

{ TinclAuto }

constructor TinclAuto.Create(const Controller: IInterface; Rep: TStepMetrologyEvent);
 var
  e: TevTypes;
begin
  inherited Create(Controller);
  FErrorTimer := TTimer.Create(nil);
  FErrorTimer.Enabled := False;
  FErrorTimer.Interval := 300000;
  FErrorTimer.OnTimer := OnErrorTimer;
  FTask := TObjectList<TGOTask>.Create();
  Report := Rep;
  e.Err := OnErrorH;
  e.EndErr := OnEndErrorH;
  if Assigned(GChekH) then GChekH.Bind(Self, e);
end;

destructor TinclAuto.Destroy;
begin
 if Assigned(GChekH) then GChekH.UnBind(Self);
  FErrorTimer.Free;
  FTask.Clear;
  FTask.Free;
  inherited;
end;

function TinclAuto.AxisReady: Boolean;
 function chek(ax: IAxis; const Nm: string): Boolean;
 begin
   Result := (ax.Reper = 'M') and (ax.Motor = 's') and ((ax.Error and 3) = 0);
   if not Result then FLastErr := FLastErr + Format('%s(%s%s%x) ',[Nm, ax.Reper, ax.Motor, ax.Error and 3]);
 end;
begin
  FLastErr := '';
  Result := chek(uaki.Azi, 'Азимут') and chek(uaki.Zen, 'Зенит') and chek(uaki.Viz, 'Визир');
end;

function TinclAuto.GetUaki: IUaki;
 var
  de: IDeviceEnum;
  d: IDevice;
begin
  if Assigned(Fuaki) then Exit(Fuaki);
  if Supports(GlobalCore, IDeviceEnum, de) then
   for d in de.Enum() do
    if Supports(d, IUaki, Fuaki) then
     begin
      TBindHelper.Bind(Self, 'C_AxisUpdate', Fuaki, ['S_AxisUpdate']);
      Exit(Fuaki);
     end;
  Result := nil;
  raise EFormMetrolog.Create('Устройство УАК-СИ отсутствует');
end;

procedure TinclAuto.DoStop;
begin
  FErrorTimer.Enabled := False;
  FTask.Clear;
  Fauto := eaNone;
  inherited;
end;

procedure TinclAuto.KadrEvent();
// var
//  i: Integer;
begin
  inherited;
  RunAutomat;
//  for i := FTask.Count-1 downto 0 do if FTask[i].FIterDelay > 0 then Dec(FTask[i].FIterDelay);
//  if (mstAutomat in Owner.State) and (mstAttr in Owner.State) and not AxisReady then
//   begin
//    Report(samError, 'Ошибка осей: '+ FLastErr);
//    Fauto := eaError;
//   end;
//  if (Fauto = eaWaitDelay) and (FDelayKadr > 0) and AxisReady then
//   begin
//    Dec(FDelayKadr);
//    if FDelayKadr = 0 then DoStop;
//   end;
end;

procedure TinclAuto.OnEndErrorH(Sender: TObject);
begin
  ErrorHFlag := false;
  if NeedRestartAutomatFlag then RestartAvtomat('Магнитное поле стабилизировалось');
end;

procedure TinclAuto.OnErrorH(Sender: TObject);
begin
  NeedRestartAutomatFlag :=  mstAutomat in Owner.State;
  ErrorHFlag := true;
  TerminateAvtomat('Магнитное поле неожиданно изменилось');
end;

procedure TinclAuto.OnErrorTimer(Sender: TObject);
begin
  FErrorTimer.Enabled := False;
  Fauto := eaNone;
  FTask.Clear;
  Report(samError, 'Ошибка ожидания завершения комамды');
  Error('Ошибка ожидания завершения комамды');
end;

procedure TinclAuto.RunAutomat;
 procedure AddStol(const arrt: string; axis: IAxis; tol: Double);
 begin
   if not FStep.HasAttribute(arrt) then Exit;
   TGOTask.Create(Self, FStep.Attributes[arrt], axis, tol);
 end;
 function gp(const path: string; def: Variant): Variant;
 begin
   if FStep.HasAttribute(path) then Result := FStep.Attributes[path]
   else Result := def
 end;
  var
   i: Integer;
   a: TAngle;
begin
  case Fauto of
    eaNone: if not ErrorHFlag then Report(samEnd, 'Ожидание следующей команды');
    eaCreateTask:
     if AxisReady then
      begin
       FErrorTimer.Enabled := True;
       Fauto := eaStartTask;
       FKadrEvent := False;
       Report(samRun, 'Ожидание данных с прибора');
       AddStol('Azimut_Stol', uaki.Azi, gp('Azimut_tol', 2));
       AddStol('Zenit_Stol', uaki.Zen, gp('Zenit_tol', 0.2));
       AddStol('Vizir_Stol', uaki.Viz, gp('Vizir_tol', 2));
       if FStep.HasAttribute('Vizir_StolPA') then
        begin
         a := Tangle(FStep.Attributes['Vizir_StolPA']) + Tangle(FStep.ParentNode.ParentNode.Attributes['MagNaklon']);
         TGOTask.Create(Self, a, uaki.Viz, 2);
        end;
       if FStep.HasAttribute('Vizir_StolMA') then
        begin
         a := Tangle(FStep.Attributes['Vizir_StolMA']) - Tangle(FStep.ParentNode.ParentNode.Attributes['MagNaklon']);
         TGOTask.Create(Self, a, uaki.Viz, 2);
        end;
       if FStep.HasAttribute('Zenit_StolPA') then
        begin
         a := Tangle(FStep.Attributes['Zenit_StolPA']) + Tangle(FStep.ParentNode.ParentNode.Attributes['MagNaklon']);
         TGOTask.Create(Self, a, uaki.Zen, 0.2);
        end;
       if FStep.HasAttribute('Temp_Nagr') then
        begin
         TTaskTemp.Create(Self, 'T.DEV', FStep.Attributes['Temp_Nagr'], True, uaki);
        end;
       if FStep.HasAttribute('Temp_Ost') then
        begin
         TTaskTemp.Create(Self, 'T.DEV', FStep.Attributes['Temp_Ost'], False, uaki);
        end;
       if FStep.HasAttribute('Vizir_Dev') then
        begin
         TGODev.Create(Self, FStep.Attributes['Vizir_Dev'], uaki.Viz, 'accel.X', 'accel.Y', gp('Vizir_tol', 0.06), gp('Vizir_NIter', 7));
        end;
       if FStep.HasAttribute('VizirMag_Dev') then
        begin
         TGODev.Create(Self, FStep.Attributes['VizirMag_Dev'], uaki.Viz, 'magnit.X', 'magnit.Y', gp('VizirMag_tol', 0.06), gp('VizirMag_NIter', 7));
        end;
      end
     else Report(samRun, 'Оси не готовы: '+ FLastErr);
    eaStartTask:
     if FKadrEvent then
      begin
       FKadrEvent := False;
       FErrorTimer.Enabled := True;
       Fauto := eaWaitTask;
       FNeedWaitTask := True;
       for i := FTask.Count-1 downto 0 do FTask[i].Start;
      end;
    eaWaitTask:
     if AxisReady then
      begin
       if not FKadrEvent then exit;
       FKadrEvent := False;
       for i := FTask.Count-1 downto 0 do FTask[i].Iterate;
       if FTask.Count = 0 then
        begin
         Fauto := eaWaitDelay;
         FErrorTimer.Enabled := False;
         if FStep.HasAttribute('Dalay_Kadr') then FDelayKadr := FStep.Attributes['Dalay_Kadr']
         else FDelayKadr := 2;
        end
      end
     else Report(samRun, 'Оси в движении: '+ FLastErr);
    eaWaitDelay: if FKadrEvent then
     begin
      FKadrEvent := False;
      if (FDelayKadr = 0) or not FNeedWaitTask then DoStop
      else if AxisReady then
       begin
        Report(samRun, 'Cтабилизация: '+ FDelayKadr.ToString());
        Dec(FDelayKadr);
       end;
     end;
  end;
end;

procedure TinclAuto.SetC_AxisUpdate(const Value: Integer);
begin
  FC_AxisUpdate := Value;
  RunAutomat;
end;

procedure TinclAuto.StartStep(Step: IXMLNode);
begin
  inherited;
  GetUaki;
  Report(samRun, 'Ожидание стауса осей стола, данных прибора');
  FErrorTimer.Enabled := True;
  Fauto := eaCreateTask;
end;

procedure TinclAuto.Stop;
begin
  inherited;
  FErrorTimer.Enabled := False;
  Fauto := eaNone;
  FTask.Clear;
  uaki.Azi.TermimateMoving;
  uaki.Zen.TermimateMoving;
  uaki.Viz.TermimateMoving;
  Report(samUserStop, 'Прервано пользователем');
end;

function TinclAuto.UakiExists: Boolean;
begin
  Result := True;
  try
   uaki;
  except
   Result := False;
  end;
end;

end.
