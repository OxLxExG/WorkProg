unit MetrInclin.TrrAndP4;

interface

uses System.SysUtils, Xml.XMLIntf, System.Classes,
     PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, AutoMetr.Inclin, RootImpl,
     LuaInclin.Math, XMLLua.Math, UakiIntf, MetrInclin.CheckForm, MetrInclin.TrrAndP2;

type
  TFormInclinTrrAndP4 = class(TFormInclinTrrAndP2)
  protected
   const
    NICON = 340;
    procedure DoSetupAlg; override;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Поверка и калибровка 480', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;


implementation

uses tools;

{ TFormInclinTrrAndP3 }

class function TFormInclinTrrAndP4.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormInclinTrrAndP4.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclinTrrAndP4.MetrolType: string;
begin
  Result := 'P_4';
end;

procedure TFormInclinTrrAndP4.DoSetupAlg;
begin
  CreateStepsFixZU(30,45,3);
  CreateStepsFixZU(30,45,7);
  CreateStepsFixZU(30,45,30);
  CreateStepsFixZU(30,45,60);
  CreateStepsFixZU(30,45,90);
end;

function TFormInclinTrrAndP4.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 const
  N3   = 12*8 *1;
  N7  =  12*8 *2;
  N30  = 12*8 *3;
  N60  = 12*8 *4;
  N90  = 12*8 *5;
  NMAX = 12*8*5;
begin
  Result := True;
  //UserExecStepUpdateStolAngle(Step, alg, trr);
  if Step = NMAX then
   begin
    if FNewAlg then FindAccel(1, NMAX, alg, trr);
    RefindZen(1, NMAX, alg, trr);
    if FNewAlg then FindMagnit(N3+1,  N90, alg, trr);
    RefindAzi(1, NMAX, alg, trr);
    FNewAlg := False;
    alg.Attributes['ErrZU']  := FindMaxErr(alg, 1, NMAX, 'err_зенит');
    alg.Attributes['ErrAZ5'] := FindMaxErr(alg, 1, N7, 'err_азимут');
    alg.Attributes['ErrAZ']  := FindMaxErr(alg, N7+1, NMAX, 'err_азимут');
   end;
end;

function TFormInclinTrrAndP4.UserSetupAlg(alg: IXMLNode): Boolean;
begin
  Result := True;
  FStep.root := alg;
  FStep.stp := 1;

  FCurAzim := 0; FCurViz := 0;
  FDirAzim := 1; FDirViz := 1;

  DoSetupAlg;
end;

initialization
  RegisterClass(TFormInclinTrrAndP4);
  TRegister.AddType<TFormInclinTrrAndP4, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInclinTrrAndP4>;
end.
