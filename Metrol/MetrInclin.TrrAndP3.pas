unit MetrInclin.TrrAndP3;

interface

uses System.SysUtils, Xml.XMLIntf, System.Classes,
     PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, AutoMetr.Inclin, RootImpl,
     LuaInclin.Math, XMLLua.Math, UakiIntf, MetrInclin.CheckForm, MetrInclin.TrrAndP2;

type
  TFormInclinTrrAndP3 = class(TFormInclinTrrAndP2)
  protected
   const
    NICON = 339;
    procedure DoSetupAlg; override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Поверка и калибровка 436', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;


implementation

{ TFormInclinTrrAndP3 }

class function TFormInclinTrrAndP3.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormInclinTrrAndP3.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclinTrrAndP3.MetrolType: string;
begin
  Result := 'P_3';
end;

procedure TFormInclinTrrAndP3.DoSetupAlg;
begin
  CreateStepsFixZU(30,60,5);
  CreateStepsFixZU(30,60,10);
  CreateStepsFixZU(30,60,30);
  CreateStepsFixZU(30,60,60);
  CreateStepsFixZU(30,60,90);
  CreateStepsFixZU(30,60,120);
end;

function TFormInclinTrrAndP3.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 const
  N5   = 5;
  N10  = 5+72*1;
  N30  = 5+72*2;
  N60  = 5+72*3;
  N90  = 5+72*4;
  N120 = 5+72*5;
  NMAX = 436;
begin
  Result := True;
  //UserExecStepUpdateStolAngle(Step, alg, trr);
  if Step = NMAX then
   begin
    if FNewAlg then FindAccel(1, NMAX, alg, trr);
    RefindZen(1, NMAX, alg, trr);
    if FNewAlg then FindMagnit(N10,  N120-1, alg, trr);
    RefindAzi(1, NMAX, alg, trr);
    FNewAlg := False;
    alg.Attributes['ErrZU']  := FindMaxErr(alg, 1, NMAX, 'err_зенит');
    alg.Attributes['ErrAZ5'] := FindMaxErr(alg, N5, N30-1, 'err_азимут');
    alg.Attributes['ErrAZ']  := FindMaxErr(alg, N30, NMAX, 'err_азимут');
   end;
end;

initialization
  RegisterClass(TFormInclinTrrAndP3);
  TRegister.AddType<TFormInclinTrrAndP3, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInclinTrrAndP3>;
end.
