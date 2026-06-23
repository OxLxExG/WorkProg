unit MetrInclin.Temp.Form;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, tools, XMLLua.Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList, Vcl.ExtCtrls, Vcl.StdCtrls,
  MetrForm, Vcl.ComCtrls, AutoMetr.Inclin, RootImpl;

type
  TFormMetrInclinT = class(TFormMetrolog, IAutomatMetrology)
    Tree: TVirtualStringTree;
    lbInfo: TLabel;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FAutomatMetrology: TinclAuto;
    FStolVizir: Double;
    FStolAzimut: Double;
    FStolZenit: Double;
  protected
   const
    NICON = 86;
    procedure Loaded; override;
//    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    procedure DoStartAtt(AttNode: IXMLNode); override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
//    function UserSetupAlg(alg: IXMLNode): Boolean; override;
    class function ClassIcon: Integer; override;
  public
    property StolVizir: Double read FStolVizir;
    property StolZenit: Double read FStolZenit;
    property StolAzimut: Double read FStolAzimut;
    [StaticAction('Метрология Инкл. по Т', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    class function MetrolAttrName: string; override;
    destructor Destroy; override;
    property AutomatMetrology: TinclAuto read FAutomatMetrology implements IAutomatMetrology;
  end;
    TFormMetrInclinT2 = class(TFormMetrInclinT)
    public
    [StaticAction('Метрология Инкл. по Т V2', 'Метрология', 87, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolAttrName: string; override;
    end;
    TFormMetrInclinT3 = class(TFormMetrInclinT)
    public
    [StaticAction('Метрология Инкл. по Т 4 точки', 'Метрология', 87, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
    class function MetrolAttrName: string; override;
    end;
    TFormMetrInclinT4 = class(TFormMetrInclinT)
    public
    [StaticAction('Метрология Инкл. по Т 4 точки (poly)', 'Метрология', 87, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
    class function MetrolAttrName: string; override;
    end;

implementation

{$R *.dfm}

{ TFormMetrInclinT }

class function TFormMetrInclinT.ClassIcon: Integer;
begin
  Result := NICON;
end;

destructor TFormMetrInclinT.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormMetrInclinT.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormMetrInclinT.DoStartAtt(AttNode: IXMLNode);
 var
  n: IXMLNode;
begin
  inherited;
  if TryGetX(AttNode, 'TASK', n) then
   begin
    if n.HasAttribute('Vizir_Stol') then FStolVizir := Double(n.Attributes['Vizir_Stol']);
    if n.HasAttribute('Azimut_Stol') then FStolAzimut := Double(n.Attributes['Azimut_Stol']);
    if n.HasAttribute('Zenit_Stol') then FStolZenit := Double(n.Attributes['Zenit_Stol']);
   end;
end;

procedure TFormMetrInclinT.DoStopAtt(AttNode: IXMLNode);
 var
  v: Variant;
begin
  v := XToVar(AttNode);
  if FAutomatMetrology.UakiExists then
   begin
    v.СТОЛ.азимут := Double(FAutomatMetrology.uaki.Azi.CurrentAngle);
    v.СТОЛ.зенит := Double(FAutomatMetrology.uaki.Zen.CurrentAngle);
    v.СТОЛ.визир := Double(FAutomatMetrology.uaki.Viz.CurrentAngle);
   end
  else
   begin
    v.СТОЛ.азимут := StolAzimut;
    v.СТОЛ.зенит := StolZenit;
    v.СТОЛ.визир := StolVizir;
   end;
  inherited;
end;

procedure TFormMetrInclinT.Loaded;
begin
  FlagNoUpdateFromEtalon := True;
  SetupStepTree(Tree);
  inherited;
  FAutomatMetrology := TinclAuto.Create(Self, AutoReport);
  AttestatPanel.Align := alBottom;
end;

class function TFormMetrInclinT.MetrolAttrName: string;
begin
  Result := 'INKLGK1'
end;

class function TFormMetrInclinT.MetrolMame: string;
begin
  Result := 'Inclin'
end;

class function TFormMetrInclinT.MetrolType: string;
begin
  Result := 'InclTem1'
end;

procedure TFormMetrInclinT.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
end;

procedure TFormMetrInclinT.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
 var
  p: PNodeExData;
  r: IXMLNode;
  i: Integer;
  procedure SetData(const path, attr, fmt: string; Correction: Double = 0);
   var
    V: IXMLNode;
  begin
    if TryGetX(p.XMNode, path, V, attr) then
      if fmt ='%s' then
        CellText := V.NodeValue
      else
        CellText := Format(fmt,[Double(V.NodeValue) + Correction])
    else
         CellText := ''
  end;
begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  case Column of
   0: begin
       r := p.XMNode;
       if r.HasAttribute('STEP') then CellText := r.Attributes['STEP']
       else CellText := 'STEP';
      end;
   1: SetData('T.DEV',     AT_VALUE,     '%7.2f');
   2: SetData('СТОЛ',      'зенит',     '%7.2f');
   3: SetData('СТОЛ',      'азимут',     '%7.1f');
   4: SetData('СТОЛ',      'визир',     '%7.1f');
   5: SetData('accel.X.DEV',      AT_VALUE,     '%7.1f');
   6: SetData('accel.Y.DEV',      AT_VALUE,     '%7.1f');
   7: SetData('accel.Z.DEV',      AT_VALUE,     '%7.1f');
   8: SetData('magnit.X.DEV',     AT_VALUE,     '%7.1f');
   9: SetData('magnit.Y.DEV',     AT_VALUE,     '%7.1f');
   10: SetData('magnit.Z.DEV',     AT_VALUE,    '%7.1f');
   11: SetData('',     'Sensor',     '%s');
   12: SetData('',     'Axis',     '%s');
   13: SetData('',     'Amp',     '%7.1f');
   14: SetData('',     'Dz',     '%7.1f');
  end;
end;

//function TFormMetrInclinT.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
//begin
//  Result := True;
//end;

{function TFormMetrInclinT.UserSetupAlg(alg: IXMLNode): Boolean;
  function AddHG(stp: IXMLNode; const Root: string):Variant;
  begin
    stp := TXMLScriptMath.AddXmlPath(stp, Root);
    TXMLScriptMath.AddXmlPath(stp, 'X.DEV');
    TXMLScriptMath.AddXmlPath(stp, 'Y.DEV');
    TXMLScriptMath.AddXmlPath(stp, 'Z.DEV');
    Result := XToVar(stp);
    Result.X.DEV.VALUE := 0;
    Result.Y.DEV.VALUE := 0;
    Result.Z.DEV.VALUE := 0;
  end;
 const
  NFORT = 12;
  NT = 4;
  procedure AddStep(tmp, stp: Integer;  alg: IXMLNode);
   const
    TINF: array [1..NT] of string = ('21','130','100','21');
    INF: array [1..NFORT] of string = ('Азимут 90 Зенит 90 Gx максимум',
                                                           'Нx максимум',
                                                           'Gy максимум',
                                                           'Hy максимум',
                                                           'Gx минимум',
                                                           'Hx минимум',
                                                           'Gy минимум',
                                                           'Hy минимум',
                                 'Азимут 0 Зенит 0','Зенит 19.5 Нz максимум',
                                 'Зенит 180 Gz минимум','Зенит 160.5 Hz минимум');
   var
    i, step: Integer;
    v: Variant;
    r, t: IXMLNode;
  begin
    step := NFORT*(tmp-1) + stp;
    r := TXMLScriptMath.AddXmlPath(alg, 'STEP' + step.ToString());
    v := XToVar(r);
    v.EXECUTED := False;
    v.STEP := step;
    v.INFO := Format('%d) Темп:%s; %s',[step, TINF[tmp], INF[stp]]);
    for i := 1 to 5 do
     begin
      AddHG(r, Format('Inclin%d.%s.', [i, 'accel']));
      AddHG(r, Format('Inclin%d.%s.', [i, 'magnit']));
      t := TXMLScriptMath.AddXmlPath(r, Format('Inclin%d.T.DEV', [i]));
      t.Attributes[AT_VALUE] := 0;
     end;
  end;
 var
  i,t: Integer;
begin
  Result := True;
   for t := 1 to NT do
    for i := 1 to NFORT do AddStep(t, i, alg);
end;  }

{ TFormMetrInclinT2 }

class procedure TFormMetrInclinT2.DoCreateForm(Sender: IAction);
begin
  inherited;

end;

class function TFormMetrInclinT2.MetrolAttrName: string;
begin
  Result := 'INKLGK2'
end;

{ TFormMetrInclinT3 }

class procedure TFormMetrInclinT3.DoCreateForm(Sender: IAction);
begin
  inherited;

end;

class function TFormMetrInclinT3.MetrolAttrName: string;
begin
    Result := 'INKLGK3'
end;

class function TFormMetrInclinT3.MetrolType: string;
begin
  Result := 'InclTem4point'
end;

{ TFormMetrInclinT4 }

class procedure TFormMetrInclinT4.DoCreateForm(Sender: IAction);
begin
  inherited;

end;

class function TFormMetrInclinT4.MetrolAttrName: string;
begin
  Result := 'INKLGK4'
end;

class function TFormMetrInclinT4.MetrolType: string;
begin
  Result := 'IT4poly'
end;

initialization
  RegisterClass(TFormMetrInclinT);
  RegisterClass(TFormMetrInclinT2);
  RegisterClass(TFormMetrInclinT3);
  TRegister.AddType<TFormMetrInclinT, IForm>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TFormMetrInclinT2, IForm>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TFormMetrInclinT3, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormMetrInclinT>;
  GContainer.RemoveModel<TFormMetrInclinT2>;
  GContainer.RemoveModel<TFormMetrInclinT3>;
end.
