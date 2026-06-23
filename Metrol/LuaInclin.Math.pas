unit LuaInclin.Math;

interface

 {$M+}

uses  Vector,
      SysUtils, System.Classes, math, System.Variants, Container, RootImpl, System.Generics.Collections, Winapi.ActiveX,
      XMLLua, XMLLua.Math, VerySimple.Lua.Lib,
       tools, debug_except, MathIntf, Xml.XMLIntf, ExtendIntf;

type
  EExportReportException = class(ENeedDialogException);

  TRollData = array[0..35] of Double;
  TResultSolvRoll = record
   D0, Amp, Faza: Double;
   MaxErrIndex: Integer;
   MaxErr, StdNormErr: Double;
   IstData, Noise, Err: TRollData;
  end;

{  ESumDataException = class(EBaseException);

  TAngleSum = class(TIObject, IFindAnyData)
  private
    FCount: Integer;
    FSum: Double;
    FOld: Double;
  protected
    procedure Add(Data: Double);
    procedure Reset;
    function Get: Double;
  end;

  TMedianSum = class(TIObject, IFindAnyData)
  private
    FData: TArray<Double>;
  protected
    procedure Add(Data: Double); virtual;
    procedure Reset;
    function Get: Double; virtual;
  end;

  TAngleMedianSum = class(TMedianSum)
  private
    FData: TArray<Double>;
    FOld: Double;
  protected
    procedure Add(Data: Double); override;
    function Get: Double; override;
  end;}

  IAngleErr = interface
  ['{6392A334-D3E6-417F-BB13-552F64E5C905}']
    procedure CheckStepData(d: Variant);
  end;

  TAzimErr = class(TIObject, IAngleErr)
  private
    ve, vd: PVariant;
    Fi, Fj, FAzimStol, FZenitStol: Integer;
  protected
    procedure CheckStepData(d: Variant);
  public
    constructor Create(DataArr, ErrArr: PVariant; j, i, AzimStol, ZenitStol: Integer);
  end;
  
  TZenErr = class(TIObject, IAngleErr)
  private
    vz: PVariant;
    Fi, FZenitStol: Integer;
  protected
    procedure CheckStepData(d: Variant);
  public
    constructor Create(DataArr: PVariant; i, ZenitStol: Integer);
  end;


  TLMFitting = class
  private
   type
    PXrec = ^TXrec;
    TXrec = record
     m11,m12,m14,m22,m24,dF: Double;
    end;
    PZrec = ^TZrec;
    TZrec = record
     m31, m32, m34: Double;
    end;
   class var
    X, Y, Z: TRollData;
    ZMax, kX, kY, faza0: Double;
    class procedure func_cb_roll(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_z(const k, f: PDoubleArray); static; cdecl;
    class procedure RunZ(m31,m32,m34, Zm: Double);
    class procedure RunRoll(m11,m12,m14,m22,m24,dF: Double);
  public
   type
    TResult = record
      m11, m12, m13, m14: Double;
      m21, m22, m23, m24: Double;
      m31, m32, m33, m34: Double;
      Faza: Double;
    end;
    class procedure Run(AX, AY, AZ: TRollData; ZMaxR, kXR, kYR: Double; out Res: TResult);
  end;


  // Алгоритм Левенберга — Марквардта
  // сначала находим оптимальные поправки зенита для всех точек порерки
  TAngleFtting = class
  public
   type
    PMetr = ^TMetr;
    TMetr = record
    // zenit
     m11,m12, m13, m14,
              m23, m24,
     m31,m32, m33, m34: Double;
    // azimut
     m21: Double;
    // result
     m22: Double;
     procedure Reset;
     procedure AssignTo(v: Variant);
     procedure MulVect(ks: PDoubleArray);
     class operator Explicit(const M: TMetr): TMatrix4;
     class operator Explicit(const M: TMatrix4): TMetr;
     class function LenZu: Integer; static;
     class function LenAzi: Integer; static;
    end;
    TInputRec = record
      gx, gy, gz, hx, hy, hz: Double;
      AziStol, ZenStol, MagAmp: Double;
    end;
    TInput = TArray<TInputRec>;
  private
   class var
   // Дано:
    Inp: TInput;
   // наЙти:
    WeitAzi,WeitZen: Double;
    ZenMetr: TMetr;
    AziMetr: TMetr;
    class procedure func_cb_zen_nostol(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_azi_nostol(const k, f: PDoubleArray); static; cdecl;

    class procedure func_cb_amp_zen(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_amp_azi(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_zen(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_azi(const k, f: PDoubleArray); static; cdecl;
  public
    class procedure RunZ(AInp: TInput; var Res: TMetr; AWeitZen: Double = 0.018);
    class procedure RunA(AInp: TInput; out Res: TMetr; AWeitAzi: Double = 0.03);
    class procedure RunZ_nostol(AInp: TInput; out Res: TMetr);
    class procedure RunA_nostol(AInp: TInput; out Res: TMetr);
  end;

 { TInclinVector = record
   X,Y,Z: Double;
    class operator Multiply(a: TInclinVector; Factor: Double): TInclinVector; static;
  end;}

   TInclPoint = record
    T: double;
    G, H: TVector3;// TInclinVector;
    class operator Implicit(V: Variant): TInclPoint;
   end;

{  TInclinMetr3x4 = record
    m11, m12, m13, m14: Double;
    m21, m22, m23, m24: Double;
    m31, m32, m33, m34: Double;
    class operator Multiply(a: TInclinMetr3x4; v: TInclinVector): TInclinVector; static;
    class function Scale(Factor: Double; matrix: TInclinMetr3x4): TInclinMetr3x4; static;
    function Invert: TInclinMetr3x4;
    procedure AssignTo(v: Variant);
    procedure Default;
  end;}

  TMetrInclinMath = class
  private
    class procedure SetCell(Sheet: Variant; const cel: string; data: string); static;
//    class procedure ExecStepIncl_OLD(stp: Integer; alg, trr: Variant); static;
//    class procedure ExportP1ToCalc(const TrrFile: string; NewTrr: Variant); static;
//    class procedure ExportP2ToCalc(const TrrFile: string; NewTrr: Variant); static;
//    class procedure ExportP3ToCalc(const TrrFile: string; NewTrr: Variant); static;
//    class procedure ExportP4ToCalc(const TrrFile: string; NewTrr: Variant); static;
//    class procedure ExportToInc(const TrrFile: string; NewTrr: Variant); static;
//    class procedure ImportIncFile(const TrrFile: string; NewTrr: Variant); static;
  public
   type
    TConvert = record
      m11, m12, m13, m14: Double;
      m21, m22, m23, m24: Double;
      m31, m32, m33, m34: Double;
      Sx, Sy, Sz: Double;
      Kx, Ky, Kz: Double;
      Kxy, Kxz, Kyx,Kyz, Kzx, Kzy: Double;
    end;
    class constructor Create;
    class destructor Destroy;
//{$IFNDEF USE_LUA_SCRIPT}
//    class procedure Nop; static;
//    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//{$ENDIF}
    class procedure SetupRoll(FirstStep: integer; Zen, Azim: Double; trr: IXMLNode); overload; static;
    class procedure SolvRoll(const Y: TRollData; out rep: TResultSolvRoll); static;
    class function AddStep(Step: integer; const Info: string; trr: IXMLNode): IXMLNode; static;
    class function AddStepAccel(Step: integer; const Info: string; trr: IXMLNode): IXMLNode; static;
    class procedure ExecStepIncl_OLD(stp: Integer; alg, trr: IXMLNode); overload; static;
    class procedure M3x4ToHorizont(mul: Double; var Data: TConvert); static;
    class procedure HorizontToM3x4(mul: Double; var Data: TConvert); static;
    class procedure ExportToInc(const TrrFile: string; XNewTrr: IXMLNode);  overload; static;
    class procedure ExportToIncAccel(const TrrFile: string; XNewTrr: IXMLNode);  overload; static;
    class procedure ShowReportTitle(Rep: IReport; data: Variant); static;
    class procedure ExportP1ToCalc(const TrrFile: string; NewTrr: IXMLNode); overload; static;
    class procedure ExportP2ToCalc(const TrrFile: string; NewTrr: IXMLNode); overload; static;
    class procedure ExportP3ToCalc(const TrrFile: string; NewTrr: IXMLNode); overload; static;
    class procedure ExportP4ToCalc(const TrrFile: string; NewTrr: IXMLNode); overload; static;
    class procedure ImportIncFile(const TrrFile: string; NewTrr: IXMLNode); overload; static;
    class function DeltaAngle(ang: Double): Double; static;
    class function CorrAngle(ang: Double): Double; inline; static;
//    class procedure SumAngle(Root: IXMLNode; ang: Double); static;
//    class function UaAngle(Root: IXMLNode): Double; inline; static;
//    class procedure AddSum<C: TIObject, constructor>(Root: IXMLNode; Data: Double); static;
//    class function GetSum(Root: IXMLNode): Double; inline; static;
    class procedure FindZenViz(incl, trr: Variant); overload; static;
    class procedure FindAzim(incl, trr: Variant); overload; static;
                             // X,Y,Z c metrologieq
    class procedure FindAzim(X,Y,Z, Vizir, Zenit: Double; out Azim, Dip, H: Double); overload; static;
                             // X,Y,Z c metrologieq
    class procedure FindZenViz(X,Y,Z: Double; out Vizir, Zenit: Double); overload; static;

    // обратная залача для тестовых целей
    class function FindXYZ(A, Z, O, I, Amp: Double): TInclPoint; static;
  published
    class function ExecStepIncl_OLD(L: lua_State): Integer; overload; cdecl; static;
    class function ImportIncFile(L: lua_State): Integer; overload; cdecl; static;
    class function ExportToInc(L: lua_State): Integer; overload; cdecl; static;
    class function ExportToIncAccel(L: lua_State): Integer; overload; cdecl; static;
    class function ExportP1ToCalc(L: lua_State): Integer; overload; cdecl; static;
    class function ExportP2ToCalc(L: lua_State): Integer; overload; cdecl; static;   // 64
    class function ExportP3ToCalc(L: lua_State): Integer; overload; cdecl; static;
    class function ExportP4ToCalc(L: lua_State): Integer; overload; cdecl; static;
    class function SetupRoll(L: lua_State): Integer; overload; cdecl; static;
  end;


function GetAxis(stp: Integer; const tip, axis: string; alg: IXMLNode): Double;

procedure Matrix4AssignToVariant(m: TMatrix4; v: Variant);

implementation

function GetAxis(stp: Integer; const tip, axis: string; alg: IXMLNode): Double;
begin
  Result := GetXNode(alg, Format('STEP%d.%s.%s.%s', [stp, tip, axis, T_DEV])).Attributes[AT_VALUE];
end;

{ TMetrInclinMath }

class constructor TMetrInclinMath.Create;
begin
//  {$IFDEF USE_LUA_SCRIPT}
//    XMLLua, XMLLua.Math,
//  {$ELSE}
  TXMLLua.RegisterLuaMethods(TMetrInclinMath);

//  TXmlScriptInner.RegisterMethods([
//  'procedure ExecStepIncl_OLD(stp: Integer; alg, trr: Variant)',
//  'procedure ImportIncFile(const TrrFile: string; NewTrr: Variant)',
//  'procedure ExportToInc(const TrrFile: string; NewTrr: Variant)',
//  'procedure SetupRoll(FirstStep: integer; Zen, Azim: Double; trr: variant)',
//  'procedure ExportP4ToCalc(const TrrFile: string; NewTrr: Variant)',
//  'procedure ExportP3ToCalc(const TrrFile: string; NewTrr: Variant)',
//  'procedure ExportP2ToCalc(const TrrFile: string; NewTrr: Variant)',
//  'procedure ExportP1ToCalc(const TrrFile: string; NewTrr: Variant)'], CallMeth);
//  {$ENDIF}
end;

//{$IFNDEF USE_LUA_SCRIPT}
//class function TMetrInclinMath.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//begin
//  if MethodName = 'SETUPROLL' then  SetupRoll(Params[0], Params[1], Params[2], Params[3])
//  else if MethodName = 'EXECSTEPINCL_OLD' then  ExecStepIncl_OLD(Params[0], Params[1], Params[2])
//  else if MethodName = 'EXPORTTOINC' then  ExportToInc(Params[0], Params[1])
//  else if MethodName = 'IMPORTINCFILE' then  ImportIncFile(Params[0], Params[1])
//  else if MethodName = 'EXPORTP1TOCALC' then  ExportP1ToCalc(Params[0], Params[1])
//  else if MethodName = 'EXPORTP2TOCALC' then  ExportP2ToCalc(Params[0], Params[1])
//  else if MethodName = 'EXPORTP3TOCALC' then  ExportP3ToCalc(Params[0], Params[1])
//  else if MethodName = 'EXPORTP4TOCALC' then  ExportP4ToCalc(Params[0], Params[1])
//end;
//class procedure TMetrInclinMath.Nop;
//begin
//
//end;
//{$ENDIF}

class function TMetrInclinMath.CorrAngle(ang: Double): Double;
begin
  Result := DegNormalize(ang);
end;

class function TMetrInclinMath.DeltaAngle(ang: Double): Double;
begin
  Result := DegNormalize(ang);
  if Result > 180  then Result := Result - 360;
end;

class destructor TMetrInclinMath.Destroy;
begin
end;

class function TMetrInclinMath.AddStep(Step: integer; const Info: string; trr: IXMLNode): IXMLNode;
  function AddHG(stp: IXMLNode; const Root: string):Variant;
  begin
    stp := TXMLScriptMath.AddXmlPath(stp, Root);
    TXMLScriptMath.AddXmlPath(stp, 'X.DEV');
    TXMLScriptMath.AddXmlPath(stp, 'X.CLC');
    TXMLScriptMath.AddXmlPath(stp, 'Y.DEV');
    TXMLScriptMath.AddXmlPath(stp, 'Y.CLC');
    TXMLScriptMath.AddXmlPath(stp, 'Z.DEV');
    TXMLScriptMath.AddXmlPath(stp, 'Z.CLC');
    Result := XToVar(stp);
    Result.X.CLC.VALUE := 0;
    Result.Y.CLC.VALUE := 0;
    Result.Z.CLC.VALUE := 0;
    Result.X.DEV.VALUE := 0;
    Result.Y.DEV.VALUE := 0;
    Result.Z.DEV.VALUE := 0;
  end;
 var
  v: Variant;
begin
  Result := TXMLScriptMath.AddXmlPath(trr, 'STEP'+Step.ToString());
  v := XToVar(Result);
  v.EXECUTED := False;
  v.STEP := Step;
//  s := Format('%d) %s',[Step, Info]);
  v.INFO := Format('%d) %s',[Step, Info]);
  AddHG(Result, 'accel');
  AddHG(Result, 'magnit');
  TXMLScriptMath.AddXmlPath(Result, 'TASK');
end;

class function TMetrInclinMath.AddStepAccel(Step: integer; const Info: string; trr: IXMLNode): IXMLNode;
 var
  v: Variant;
begin
  Result := TXMLScriptMath.AddXmlPath(trr, 'STEP'+Step.ToString());
  v := XToVar(Result);
  v.EXECUTED := False;
  v.STEP := Step;
  v.INFO := Format('%d) %s',[Step, Info]);;
  TXMLScriptMath.AddXmlPath(Result, 'X.DEV');
  TXMLScriptMath.AddXmlPath(Result, 'X.CLC');
  TXMLScriptMath.AddXmlPath(Result, 'Y.DEV');
  TXMLScriptMath.AddXmlPath(Result, 'Y.CLC');
  TXMLScriptMath.AddXmlPath(Result, 'Z.DEV');
  TXMLScriptMath.AddXmlPath(Result, 'Z.CLC');
  v.X.CLC.VALUE := 0;
  v.Y.CLC.VALUE := 0;
  v.Z.CLC.VALUE := 0;
  v.X.DEV.VALUE := 0;
  v.Y.DEV.VALUE := 0;
  v.Z.DEV.VALUE := 0;
end;


class procedure TMetrInclinMath.SetupRoll(FirstStep: integer; Zen, Azim: Double; trr: IXMLNode);
 var
  i: Integer;
  s: Variant;
begin
  s := XToVar(AddStep(FirstStep, Format('Установить Зенит %1.2f, Азимут %1.1f, визирный угол %d градусов.',[Zen, Azim, 0]), trr));
  s.TASK.Vizir_Stol := 0;
  s.TASK.Dalay_Kadr := 5;
  s.TASK.Zenit_Stol := Zen;
  s.TASK.Azimut_Stol := Azim;
  for I := 1 to 35 do
   begin
    s := XToVar(AddStep(FirstStep+i, Format('стол: Установить визирный угол %d градусов.',[i*10]), trr));
    s.TASK.Vizir_Stol := i*10;
    s.TASK.Dalay_Kadr := 5;
   end;
end;

class procedure TMetrInclinMath.ExecStepIncl_OLD(stp: Integer; alg, trr: IXMLNode);
const DDD: TRollData = (611,-1139,-2854,-4478,-5965,-7270,-8359,-9191,-9745,-10003,-9957,
  -9607,-8965,-8053,-6894,-5529,-3992,-2340,-615,1127,2836,4456,5940,
  7247,8327,9160,9713,9967,9921,9572,8934,8024,6870,5508,3980,2324);
  var
   r: TResultSolvRoll;
begin
  SolvRoll(DDD, r);
end;

{type
  TAnonymousThread = class(TThread)
  private
    FProc: TProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const AProc: TProc);
    destructor Destroy; override;
  end;}

{ TAnonymousThread }

{constructor TAnonymousThread.Create(const AProc: TProc);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FProc := AProc;
end;

destructor TAnonymousThread.Destroy;
begin
  inherited;
end;

procedure TAnonymousThread.Execute;
begin
  FProc();
end;}


class procedure TMetrInclinMath.SetCell(Sheet: Variant; const cel: string; data: string);
begin
  Sheet.getCellRangeByName(cel).getCellByPosition(0,0).SetString(data);
end;

class function TMetrInclinMath.SetupRoll(L: lua_State): Integer;
begin
  SetupRoll(lua_tointeger(L,1), lua_tonumber(L,2), lua_tonumber(L,3), TXMLLua.XNode(L,4));
  Result := 0;
end;

class procedure TMetrInclinMath.ShowReportTitle(Rep: IReport; data: Variant);
 const
    OTCHET = 'По зенитному углу, в диапазоне от 0º до 120º  погрешность составляет не более %.2fº.'#$D+
             'По азимутальному углу в  диапазоне от 0º до 360º погрешность составляет не более'#$D+
             '%.1fº - при зенитном угле от 5º  до 10º,'#$D+
             '%.1fº - при зенитном угле от 10º до 120º.'#$D+
             'Инклинометр номер № %s к эксплуатации %s.'#$D'%s';
    NEXT_TRR='Следующую проверку произвести не позднее %s';
   REP_TITLE='Протокол поверки инклинометра № %s';
var
    Sheet: Variant;
    s, nt, sn: string;
begin
  Sheet := Rep.Document.GetSheets.getByIndex(0);

  SetCell(Sheet, 'B8', Data.DevName);
  sn := TVxmlData(Data).Node.ParentNode.ParentNode.ParentNode.Attributes[AT_SERIAL];
  SetCell(Sheet, 'A2', Format(REP_TITLE, [sn]));
  SetCell(Sheet, 'B10', sn);
  SetCell(Sheet, 'B12', Data.Maker);
  SetCell(Sheet, 'B14', Data.UsedStol);
  SetCell(Sheet, 'B16', Data.Category);
  SetCell(Sheet, 'B18', Data.Room);
  SetCell(Sheet, 'B20', Data.TIME_ATT);
  SetCell(Sheet, 'B24', Data.Metrolog);

  if Data.Ready then
   begin
    s := 'готов';
    nt := Format(NEXT_TRR, [string(Data.NextDate)]);
   end
  else
   begin
    s := 'НЕ ГОТОВ !!!';
    nt := ''
   end;
  SetCell(Sheet, 'A28', Format(OTCHET, [Double(Data.ErrZU), Double(Data.ErrAZ5), Double(Data.ErrAZ), sn, s, nt]));
end;

{ TZenErr }

procedure TZenErr.CheckStepData(d: Variant);
begin
  if (Abs(TMetrInclinMath.DeltaAngle(FZenitStol - d.СТОЛ.зенит)) < 2) and (Abs(vz^[1, Fi]) < Abs(d.СТОЛ.err_зенит)) then
   begin 
    vz^[1, Fi] := Double(d.СТОЛ.err_зенит);
    vz^[0, Fi] := Double(d.отклонитель.CLC.VALUE);
   end;
end;

constructor TZenErr.Create(DataArr: PVariant; i, ZenitStol: Integer);
begin
  vz := DataArr;
  Fi := i;
  FZenitStol := ZenitStol;
  vz^[1, i] := 0;
end;

{ TAzimErr }

procedure TAzimErr.CheckStepData(d: Variant);
begin
  if     (Abs(TMetrInclinMath.DeltaAngle(FAzimStol - d.СТОЛ.азимут)) < 10)
     and (Abs(TMetrInclinMath.DeltaAngle(FZenitStol - d.СТОЛ.зенит)) < 2)
     and (Abs(ve^[Fj, Fi]) < Abs(d.СТОЛ.err_азимут)) then
    begin 
     ve^[Fj, Fi] := Double(d.СТОЛ.err_азимут);
     vd^[Fj, Fi] := Double(d.отклонитель.CLC.VALUE);
    end;
end;

constructor TAzimErr.Create(DataArr, ErrArr: PVariant; j, i, AzimStol, ZenitStol: Integer);
begin
  vd := DataArr;
  ve := ErrArr;
  Fi := i;
  Fj := j;
  FAzimStol := AzimStol;
  FZenitStol := ZenitStol;
  ve^[j, i] := 0;
end;

class procedure TMetrInclinMath.ExportP3ToCalc(const TrrFile: string; NewTrr: IXMLNode);
  const
   TBL_ZU_AZ: array[0..5] of Integer = (5,10,30,60,90,120);
   TBL_ZU_ALL: array[0..6] of Integer = (0,5,10,30,60,90,120);
begin
  if not NewTrr.ChildNodes['P_3'].HasAttribute('DevName') or
     not NewTrr.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
     raise EExportReportException.Create('Параметры поверки не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    va, ea, vz: Variant;
    i, j: Integer;
    r: IReport;
    ste: TArray<IAngleErr>;
    ae: IAngleErr;
    Sheet, Range, st: Variant;
  begin
    try
     CoInitialize(nil);
     try
       r := GlobalCore as IReport;
       r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\ReportInclin3.ods');

       vz := VarArrayCreate([0,1, 0,6], varVariant);
       va := VarArrayCreate([0,5, 0,11], varVariant);
       ea := VarArrayCreate([0,5, 0,11], varVariant);

       for i := 0 to 11 do for j := 0 to 5 do CArray.Add<IAngleErr>(ste, TAzimErr.Create(@va, @ea, j, i, i*30, TBL_ZU_AZ[j]));
       for j := 0 to 6 do CArray.Add<IAngleErr>(ste, TZenErr.Create(@vz, j, TBL_ZU_ALL[j]));

       for i := 1 to 436 do
        begin
         st := XToVar(GetXNode(NewTrr, 'P_3.STEP'+i.ToString));
         for ae in ste do ae.CheckStepData(st);
        end;

       Sheet := r.Document.GetSheets.getByIndex(1);
       Range := Sheet.getCellRangeByName('B8:C14');
       Range.setDataArray(vz);
       Range := Sheet.getCellRangeByName('B23:G34');
       Range.setDataArray(va);
       Range := Sheet.getCellRangeByName('B40:G51');
       Range.setDataArray(ea);

       ShowReportTitle(r, XToVar(NewTrr.ChildNodes['P_3']));

       r.SaveAs(TrrFile);
     finally
      CoUnInitialize();
     end;
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

class function TMetrInclinMath.ExportP4ToCalc(L: lua_State): Integer;
begin
  ExportP4ToCalc(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class procedure TMetrInclinMath.ExportP4ToCalc(const TrrFile: string; NewTrr: IXMLNode);
  const
   TBL_ZU_AZ: array[0..5] of Integer = (5,10,30,60,90,120);
   TBL_ZU_ALL: array[0..6] of Integer = (0,5,10,30,60,90,120);
begin
  if not NewTrr.ChildNodes['P_4'].HasAttribute('DevName') or
     not NewTrr.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
     raise EExportReportException.Create('Параметры поверки не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    v: Variant;
    i, j, index_row: Integer;
    r: IReport;
    ste: TArray<IAngleErr>;
    ae: IAngleErr;
    Sheet, Range, st: Variant;
    function Azi_index(idx: integer): Integer;
    begin
      Result := (idx div 8) mod 12;
      if Odd(idx div (8*12)) then Result := 11 - Result;
    end;
    function vizir_index(idx: integer): Integer;
    begin
      Result := idx mod 8;
      if Odd(idx div 8) then Result := 7 - Result
    end;
  begin
    try
     CoInitialize(nil);
     try
       r := GlobalCore as IReport;
       r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\ReportInclin4.ods');

       v := VarArrayCreate([0,8{столбцы}, 0, 479{строки}], varVariant);

       for i := 0 to 479 do
        begin
         { TODO : fund Index Row }
         st := XToVar(GetXNode(NewTrr, 'P_4.STEP'+(i+1).ToString));
                      //zenit       // azimut             //vizir
         index_row := (i div (8*12))*8*12 + Azi_index(i) * 8 + vizir_index(i);
         v[0, index_row] :=  (index_row mod 8) * 45;//st.СТОЛ.отклонитель;
         v[1, index_row] :=  Double(st.СТОЛ.зенит);
         v[2, index_row] :=  Double(st.СТОЛ.азимут);

         v[3, index_row] :=  Double(st.отклонитель.CLC.VALUE);
         v[4, index_row] :=  Double(st.зенит.CLC.VALUE);
         v[5, index_row] :=  Double(st.азимут.CLC.VALUE);

         v[6, index_row] :=  '';//st.СТОЛ.отклонитель;
         v[7, index_row] :=  Double(st.СТОЛ.err_зенит);
         v[8, index_row] :=  Double(st.СТОЛ.err_азимут);
        end;

       Sheet := r.Document.GetSheets.getByIndex(1);
       Range := Sheet.getCellRangeByName('A5:I484');
       Range.setDataArray(v);

       ShowReportTitle(r, XToVar(NewTrr.ChildNodes['P_4']));

       r.SaveAs(TrrFile);
     finally
      CoUnInitialize();
     end;
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

class function TMetrInclinMath.ExportP1ToCalc(L: lua_State): Integer;
begin
  ExportP1ToCalc(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class function TMetrInclinMath.ExportToInc(L: lua_State): Integer;
begin
  ExportToInc(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class function TMetrInclinMath.ExportToIncAccel(L: lua_State): Integer;
begin
  ExportToIncAccel(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;


class procedure TMetrInclinMath.ExportToIncAccel(const TrrFile: string; XNewTrr: IXMLNode);
 var
  Convert: TConvert;
  sernom: Integer;
  NewTrr: Variant;
begin
  NewTrr := XToVar(XNewTrr);
  with Convert, TstringList.Create do
   try
    sernom := TVxmlData(NewTrr).Node.ParentNode.ParentNode.Attributes[AT_SERIAL];
    m11 := NewTrr.m3x4.m11;
    m12 := NewTrr.m3x4.m12;
    m13 := NewTrr.m3x4.m13;
    m14 := NewTrr.m3x4.m14;

    m21 := NewTrr.m3x4.m21;
    m22 := NewTrr.m3x4.m22;
    m23 := NewTrr.m3x4.m23;
    m24 := NewTrr.m3x4.m24;

    m31 := NewTrr.m3x4.m31;
    m32 := NewTrr.m3x4.m32;
    m33 := NewTrr.m3x4.m33;
    m34 := NewTrr.m3x4.m34;

    M3x4ToHorizont(8, Convert);

    Add(Format('%g {Sgx-смещение нуля акселерометра X, дв.ед.} $$*Ink_%d*$$',[sx, sernom]));
    Add(Format('%g {Sgy-смещение нуля акселерометра Y, дв.ед.}',[sy]));
    Add(Format('%g {Sgz-смещение нуля акселерометра Z, дв.ед.}',[sz]));
    Add(Format('%g {Kgx-коэффициент преобразования акселерометра X}',[Kx]));
    Add(Format('%g {Kgy-коэффициент преобразования акселерометра Y}',[Ky]));
    Add(Format('%g {Kgz-коэффициент преобразования акселерометра Z}',[Kz]));
    Add(Format('%g {Axy-угол отклонения оси акселерометра OX в плоскости XOY, град.}', [Kxy]));
    Add(Format('%g {Axz-угол отклонения оси акселерометра OX в плоскости XOZ, град.}', [Kxz]));
    Add(Format('%g {Ayz-угол отклонения оси акселерометра OY в плоскости YOZ, град.}', [Kyz]));
    Add(Format('%g {Azx-угол отклонения оси акселерометра OZ в плоскости XOZ, град.}', [Kzx]));
    Add(Format('%g {Azy-угол отклонения оси акселерометра OZ в плоскости YOZ, град.}', [Kzy]));

    M3x4ToHorizont(1, Convert);

    Add(Format('%g {Shx-смещение нуля феррозонда X, дв.ед.}',[sx]));
    Add(Format('%g {Shy-смещение нуля феррозонда Y, дв.ед.}',[sy]));
    Add(Format('%g {Shz-смещение нуля феррозонда Z, дв.ед.}',[sz]));
    Add(Format('%g {Khx-коэффициент преобразования феррозонда X}',[Kx]));
    Add(Format('%g {Khy-коэффициент преобразования феррозонда Y}',[Ky]));
    Add(Format('%g {Khz-коэффициент преобразования феррозонда Z}',[Kz]));
    Add(Format('%g {Fxy-угол отклонения оси феррозонда OX в плоскости XOY, град.}',[Kxy]));
    Add(Format('%g {Fxz-угол отклонения оси феррозонда OX в плоскости XOZ, град.}',[Kxz]));
    Add(Format('%g {Fyx-угол отклонения оси феррозонда OY в плоскости XOY, град.}',[Kyx]));
    Add(Format('%g {Fyz-угол отклонения оси феррозонда OY в плоскости YOZ, град.}',[Kyz]));
    Add(Format('%g {Fzx-угол отклонения оси феррозонда OZ в плоскости XOZ, град.}',[Kzx]));
    Add(Format('%g {Fzy-угол отклонения оси феррозонда OZ в плоскости YOZ, град.}',[Kzy]));
    SaveToFile(TrrFile);
   finally
    Free;
   end;
end;

class procedure TMetrInclinMath.ExportP2ToCalc(const TrrFile: string; NewTrr: IXMLNode);
  const
   TBL_ZU_AZ: array[0..1] of Integer = (45,90);
   TBL_ZU_ALL: array[0..2] of Integer = (0,45,90);
begin
  if not NewTrr.ChildNodes['P_2'].HasAttribute('DevName') or
     not NewTrr.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
     raise EExportReportException.Create('Параметры поверки не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    va, ea, vz: Variant;
    i, j: Integer;
    r: IReport;
    ste: TArray<IAngleErr>;
    ae: IAngleErr;
    Sheet, Range, st: Variant;
  begin
    try
     CoInitialize(nil);
     try
       r := GlobalCore as IReport;
       r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\ReportInclin2.ods');

       vz := VarArrayCreate([0,1, 0,2], varVariant);
       va := VarArrayCreate([0,1, 0,5], varVariant);
       ea := VarArrayCreate([0,1, 0,5], varVariant);

       for i := 0 to 5 do for j := 0 to 1 do CArray.Add<IAngleErr>(ste, TAzimErr.Create(@va, @ea, j, i, i*60, TBL_ZU_AZ[j]));
       for j := 0 to 2 do CArray.Add<IAngleErr>(ste, TZenErr.Create(@vz, j, TBL_ZU_ALL[j]));

       for i := 1 to 64 do
        begin
         st := XToVar(GetXNode(NewTrr, 'P_2.STEP'+i.ToString));
         for ae in ste do ae.CheckStepData(st);
        end;

       Sheet := r.Document.GetSheets.getByIndex(1);
       Range := Sheet.getCellRangeByName('B8:C10');
       Range.setDataArray(vz);
       Range := Sheet.getCellRangeByName('B19:C24');
       Range.setDataArray(va);
       Range := Sheet.getCellRangeByName('B30:C35');
       Range.setDataArray(ea);

       ShowReportTitle(r, XToVar(NewTrr.ChildNodes['P_2']));

       r.SaveAs(TrrFile);
     finally
      CoUnInitialize();
     end;
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

class function TMetrInclinMath.ExecStepIncl_OLD(L: lua_State): Integer;
begin
  ExecStepIncl_OLD(lua_tointeger(L, 1), TXMLLua.XNode(L, 2), TXMLLua.XNode(L, 3));
  Result := 0;
end;

class function TMetrInclinMath.ExportP3ToCalc(L: lua_State): Integer;
begin
  ExportP3ToCalc(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class procedure TMetrInclinMath.ExportP1ToCalc(const TrrFile: string; NewTrr: IXMLNode);
  const TBL_Z: array[0..3,0..7]of Integer = ((1, 2,3,4,5,6,7,8),
                                             (16, 15,14,13,12,11,10,9),
                                             (17,18,19,20,21,22,23,24),
                                             (32, 31,30,29,28,27,26,25));
        TBL_A: array[0..11,0..3]of Integer = ((80,	57,	56,	33),
                                              (79,	58,	55,	34),
                                              (78,	59,	54,	35),
                                              (77,	60,	53,	36),
                                              (76,	61,	52,	37),
                                              (75,	62,	51,	38),
                                              (74,	63,	50,	39),
                                              (73,	64,	49,	40),
                                              (72,	65,	48,	41),
                                              (71,	66,	47,	42),
                                              (70,	67,	46,	43),
                                              (69,	68,	45,	44));
       TBL_A2: array[0..11,0..1]of Integer = ((104,	81),
                                              (103, 82),
                                              (102, 83),
                                              (101, 84),
                                              (100, 85),
                                              (99,  86),
                                              (98,  87),
                                              (97,  88),
                                              (96,  89),
                                              (95,  90),
                                              (94,  91),
                                              (93,  92));
begin
  if not NewTrr.ChildNodes['P_1'].HasAttribute('DevName') or
     not NewTrr.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
     raise EExportReportException.Create('Параметры поверки не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    v, e, st: Variant;
    i, j: Integer;
    r: IReport;
    Sheet, Range: Variant;
  begin
    try
     CoInitialize(nil);
     try
      r := GlobalCore as IReport;
      r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\ReportInclin1.ods');
      v := VarArrayCreate([0,7, 0,3], varVariant);
      e := VarArrayCreate([0,7, 0,3], varVariant);
      Sheet := r.Document.GetSheets.getByIndex(1);
      for i := 0 to 3 do for j := 0 to 7 do
       begin
        st := XToVar(GetXNode(NewTrr, 'P_1.STEP'+TBL_Z[i,j].ToString));
        v[j, i] := Double(st.зенит.CLC.VALUE);
        e[j, i] := Double(st.СТОЛ.err_зенит);
       end;
      Range := Sheet.getCellRangeByName('B5:I8');
      Range.setDataArray(v);
      Range := Sheet.getCellRangeByName('B14:I17');
      Range.setDataArray(e);

      v := VarArrayCreate([0,3, 0,11], varVariant);
      e := VarArrayCreate([0,3, 0,11], varVariant);
      for i := 0 to 11 do for j := 0 to 3 do
       begin
        st := XToVar(GetXNode(NewTrr, 'P_1.STEP'+TBL_A[i,j].ToString));
        v[j, i] := Double(st.азимут.CLC.VALUE);
        e[j, i] := Double(st.СТОЛ.err_азимут);
       end;
      Range := Sheet.getCellRangeByName('F23:I34');
      Range.setDataArray(v);
      Range := Sheet.getCellRangeByName('F40:I51');
      Range.setDataArray(e);

      v := VarArrayCreate([0,1, 0,11], varVariant);
      e := VarArrayCreate([0,1, 0,11], varVariant);
      for i := 0 to 11 do for j := 0 to 1 do
       begin
        st := XToVar(GetXNode(NewTrr, 'P_1.STEP'+TBL_A2[i,j].ToString));
        v[j, i] := Double(st.азимут.CLC.VALUE);
        e[j, i] := Double(st.СТОЛ.err_азимут);
       end;
      Range := Sheet.getCellRangeByName('B23:C34');
      Range.setDataArray(v);
      Range := Sheet.getCellRangeByName('B40:C51');
      Range.setDataArray(e);

      ShowReportTitle(r,XToVar(GetXNode(NewTrr, 'P_1')));

      r.SaveAs(TrrFile);
     finally
      CoUnInitialize();
     end;
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

class function TMetrInclinMath.ExportP2ToCalc(L: lua_State): Integer;
begin
  ExportP2ToCalc(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class procedure TMetrInclinMath.ImportIncFile(const TrrFile: string; NewTrr: IXMLNode);
 var
  Convert: TConvert;
  ss: TstringList;
  v: Variant;
  n :Integer;
  function dat(): Double;
  begin
    Result := ss[n].Trim.Split([' '])[0].ToDouble;
    inc(n);
  end;
begin
  v := XtoVar(NewTrr.ParentNode);
  ss := TstringList.Create;
  with Convert, ss do
   try
    LoadFromFile(TrrFile);
    n := 0;
    Sx := dat();
    Sy := dat();
    Sz := dat();
    Kx := dat();
    Ky := dat();
    Kz := dat();
    Kxy := dat();
    Kxz := dat();
    Kyx := 0;
    Kyz := dat();
    Kzx := dat();
    Kzy := dat();
    HorizontToM3x4(8, Convert);
    v.accel.m3x4.m11 := m11;
    v.accel.m3x4.m12 := m12;
    v.accel.m3x4.m13 := m13;
    v.accel.m3x4.m14 := m14;

    v.accel.m3x4.m21 := m21;
    v.accel.m3x4.m22 := m22;
    v.accel.m3x4.m23 := m23;
    v.accel.m3x4.m24 := m24;

    v.accel.m3x4.m31 := m31;
    v.accel.m3x4.m32 := m32;
    v.accel.m3x4.m33 := m33;
    v.accel.m3x4.m34 := m34;
    Sx := dat();
    Sy := dat();
    Sz := dat();
    Kx := dat();
    Ky := dat();
    Kz := dat();
    Kxy := dat();
    Kxz := dat();
    Kyx := dat();
    Kyz := dat();
    Kzx := dat();
    Kzy := dat();
    HorizontToM3x4(1, Convert);
    v.magnit.m3x4.m11 := m11;
    v.magnit.m3x4.m12 := m12;
    v.magnit.m3x4.m13 := m13;
    v.magnit.m3x4.m14 := m14;

    v.magnit.m3x4.m21 := m21;
    v.magnit.m3x4.m22 := m22;
    v.magnit.m3x4.m23 := m23;
    v.magnit.m3x4.m24 := m24;

    v.magnit.m3x4.m31 := m31;
    v.magnit.m3x4.m32 := m32;
    v.magnit.m3x4.m33 := m33;
    v.magnit.m3x4.m34 := m34;
   finally
    Free;
   end;
end;

class procedure TMetrInclinMath.ExportToInc(const TrrFile: string; XNewTrr: IXMLNode);
 var
  Convert: TConvert;
  sernom: Integer;
  NewTrr: Variant;
begin
  NewTrr := XToVar(XNewTrr);
  with Convert, TstringList.Create do
   try
    sernom := TVxmlData(NewTrr).Node.ParentNode.ParentNode.Attributes[AT_SERIAL];
    m11 := NewTrr.accel.m3x4.m11;
    m12 := NewTrr.accel.m3x4.m12;
    m13 := NewTrr.accel.m3x4.m13;
    m14 := NewTrr.accel.m3x4.m14;

    m21 := NewTrr.accel.m3x4.m21;
    m22 := NewTrr.accel.m3x4.m22;
    m23 := NewTrr.accel.m3x4.m23;
    m24 := NewTrr.accel.m3x4.m24;

    m31 := NewTrr.accel.m3x4.m31;
    m32 := NewTrr.accel.m3x4.m32;
    m33 := NewTrr.accel.m3x4.m33;
    m34 := NewTrr.accel.m3x4.m34;

    M3x4ToHorizont(8, Convert);

    Add(Format('%g {Sgx-смещение нуля акселерометра X, дв.ед.} Inkl_%d %s %s %s %s %s',[sx, sernom,
                                    NewTrr.P_2.UsedStol,
                                    NewTrr.P_2.Method,
                                    NewTrr.P_2.Plase,
                                    NewTrr.P_2.TIME_ATT,
                                    NewTrr.P_2.Metrolog ]));
    Add(Format('%g {Sgy-смещение нуля акселерометра Y, дв.ед.}',[sy]));
    Add(Format('%g {Sgz-смещение нуля акселерометра Z, дв.ед.}',[sz]));
    Add(Format('%g {Kgx-коэффициент преобразования акселерометра X}',[Kx]));
    Add(Format('%g {Kgy-коэффициент преобразования акселерометра Y}',[Ky]));
    Add(Format('%g {Kgz-коэффициент преобразования акселерометра Z}',[Kz]));
    Add(Format('%g {Axy-угол отклонения оси акселерометра OX в плоскости XOY, град.}', [Kxy]));
    Add(Format('%g {Axz-угол отклонения оси акселерометра OX в плоскости XOZ, град.}', [Kxz]));
    Add(Format('%g {Ayz-угол отклонения оси акселерометра OY в плоскости YOZ, град.}', [Kyz]));
    Add(Format('%g {Azx-угол отклонения оси акселерометра OZ в плоскости XOZ, град.}', [Kzx]));
    Add(Format('%g {Azy-угол отклонения оси акселерометра OZ в плоскости YOZ, град.}', [Kzy]));



    m11 := NewTrr.magnit.m3x4.m11;
    m12 := NewTrr.magnit.m3x4.m12;
    m13 := NewTrr.magnit.m3x4.m13;
    m14 := NewTrr.magnit.m3x4.m14;

    m21 := NewTrr.magnit.m3x4.m21;
    m22 := NewTrr.magnit.m3x4.m22;
    m23 := NewTrr.magnit.m3x4.m23;
    m24 := NewTrr.magnit.m3x4.m24;

    m31 := NewTrr.magnit.m3x4.m31;
    m32 := NewTrr.magnit.m3x4.m32;
    m33 := NewTrr.magnit.m3x4.m33;
    m34 := NewTrr.magnit.m3x4.m34;

    M3x4ToHorizont(1, Convert);

    Add(Format('%g {Shx-смещение нуля феррозонда X, дв.ед.}',[sx]));
    Add(Format('%g {Shy-смещение нуля феррозонда Y, дв.ед.}',[sy]));
    Add(Format('%g {Shz-смещение нуля феррозонда Z, дв.ед.}',[sz]));
    Add(Format('%g {Khx-коэффициент преобразования феррозонда X}',[Kx]));
    Add(Format('%g {Khy-коэффициент преобразования феррозонда Y}',[Ky]));
    Add(Format('%g {Khz-коэффициент преобразования феррозонда Z}',[Kz]));
    Add(Format('%g {Fxy-угол отклонения оси феррозонда OX в плоскости XOY, град.}',[Kxy]));
    Add(Format('%g {Fxz-угол отклонения оси феррозонда OX в плоскости XOZ, град.}',[Kxz]));
    Add(Format('%g {Fyx-угол отклонения оси феррозонда OY в плоскости XOY, град.}',[Kyx]));
    Add(Format('%g {Fyz-угол отклонения оси феррозонда OY в плоскости YOZ, град.}',[Kyz]));
    Add(Format('%g {Fzx-угол отклонения оси феррозонда OZ в плоскости XOZ, град.}',[Kzx]));
    Add(Format('%g {Fzy-угол отклонения оси феррозонда OZ в плоскости YOZ, град.}',[Kzy]));
    Add(NewTrr.P_2.MagField);
    SaveToFile(TrrFile);
   finally
    Free;
   end;
end;

class procedure TMetrInclinMath.FindAzim(incl, trr: Variant);
 var
  os,oc,zs,zc,
  a, zu, o, mo, b,
  x,y,z, Hx, Hy, Hz: Double;

  t,v:IXMLNode;
begin
  t := TVxmlData(trr).Node;
  v := TVxmlData(incl).Node;

  o := DegToRad(incl.отклонитель.CLC.VALUE);
  zu := DegToRad(incl.зенит.CLC.VALUE);

  os := sin(o);
  oc := cos(o);
  zs := sin(zu);
  zc := cos(zu);

  TXMLScriptMath.TrrVect3D3T(t,v,'magnit', x,y,z);
//  TXMLScriptMath.TrrVect3D(TVxmlData(trr.magnit.m3x4).Node, TVxmlData(incl.magnit).Node, x,y,z);//, 1000);
//  x := incl.magnit.X.CLC.VALUE;
//  y := incl.magnit.Y.CLC.VALUE;
//  z := incl.magnit.Z.CLC.VALUE;
  incl.амплит_magnit.CLC.VALUE := TXMLScriptMath.Hypot3D(x, y, z);

  mo := Arctan2(y, -x);

  Hx := (x*oc - y*os)*zc + z*zs;
  Hy :=  x*os + y*oc;
  Hz :=-(x*oc - y*os)*zs + z*zc;

  a := -Arctan2(Hy, Hx);
  b := Arctan2(Hypot(Hx, Hy), Hz);

  incl.азимут.CLC.VALUE      := TXMLScriptMath.RadToDeg360(a);
  incl.маг_отклон.CLC.VALUE  := TXMLScriptMath.RadToDeg360(mo);
  incl.маг_наклон.CLC.VALUE  := TXMLScriptMath.RadToDeg360(b);
end;

class procedure TMetrInclinMath.FindAzim(X,Y,Z, Vizir, Zenit: Double; out Azim, Dip, H: Double);
 var
  os,oc,zs,zc,
  a, zu, o, mo, b,
  Hx, Hy, Hz: Double;
begin
  o := DegToRad(Vizir);
  zu := DegToRad(Zenit);

  os := sin(o);
  oc := cos(o);
  zs := sin(zu);
  zc := cos(zu);

  Hx := (x*oc - y*os)*zc + z*zs;
  Hy :=  x*os + y*oc;
  Hz :=-(x*oc - y*os)*zs + z*zc;

  H := TXMLScriptMath.Hypot3D(x, y, z);

  Azim := TXMLScriptMath.RadToDeg360(-Arctan2(Hy, Hx));
  Dip := TXMLScriptMath.RadToDeg360(Arctan2(Hypot(Hx, Hy), Hz));
end;

class function TMetrInclinMath.FindXYZ(A, Z, O, I, Amp: Double): TInclPoint;
 var
  co, so: Double;
  cz, sz: Double;
  ca, sa: Double;
  ci, si: Double;
begin
  so := Sin(DegToRad(O));
  co := Cos(DegToRad(O));
  sz := Sin(DegToRad(Z));
  cz := Cos(DegToRad(Z));
  sa := Sin(DegToRad(A));
  ca := Cos(DegToRad(A));
  i := 90 - i;
  si := Sin(DegToRad(I));
  ci := Cos(DegToRad(I));
  Result.H.X := -Amp*(ci*(sa*so - ca*co*cz) + co*si*sz);
  Result.H.Y := -Amp*(ci*(co*sa + ca*cz*so) - si*so*sz);
  Result.H.Z :=  Amp*(cz*si + ca*ci*sz);
  Result.G.X := -Amp*co*sz;
  Result.G.Y :=  Amp*so*sz;
  Result.G.Z :=  Amp*cz;
end;

class procedure TMetrInclinMath.FindZenViz(X, Y, Z: Double; out Vizir, Zenit: Double);
begin
  Vizir := TXMLScriptMath.RadToDeg360(Arctan2(y, -x));
  Zenit := TXMLScriptMath.RadToDeg360(Arctan2(Hypot(x, y), z));
end;

class procedure TMetrInclinMath.FindZenViz(incl, trr: Variant);
 var
  o, zu, x,y,z: Double;
  t,v:IXMLNode;
begin
  t := TVxmlData(trr).Node;
  v := TVxmlData(incl).Node;
  TXMLScriptMath.TrrVect3D3T(t,v,'accel',x,y,z);
  //TXMLScriptMath.TrrVect3D(TVxmlData(trr.accel.m3x4).Node, TVxmlData(incl.accel).Node, x, y, z);//, 1000);
//  x := incl.accel.X.CLC.VALUE;
//  y := incl.accel.Y.CLC.VALUE;
//  z := incl.accel.Z.CLC.VALUE;
  incl.амплит_accel.CLC.VALUE := TXMLScriptMath.Hypot3D(x, y, z);

  o := Arctan2(y, -x);
  zu := Arctan2(Hypot(x, y), z);

  incl.зенит.CLC.VALUE       := TXMLScriptMath.RadToDeg360(zu);
  incl.отклонитель.CLC.VALUE := TXMLScriptMath.RadToDeg360(o);
end;

class procedure TMetrInclinMath.HorizontToM3x4(mul: Double; var Data: TConvert);
begin
  with Data do
   begin
    Sx := Sx*mul;
    Sy := Sy*mul;
    Sz := Sz*mul;
    Kxy := DegToRad(Kxy);
    Kxz := DegToRad(Kxz);
    Kyx := DegToRad(Kyx);
    Kyz := DegToRad(Kyz);
    Kzx := DegToRad(Kzx);
    Kzy := DegToRad(Kzy);
    m11 := 1/Kx; m12 := -Kxy/Ky; m13 := Kxz/Kz; m14 := -(Sx/Kx + -Kxy*Sy/Ky + Kxz*Sz/Kz);
    m21 := Kyx/Kx; m22 := 1/Ky; m23 := -Kyz/Kz; m24 := -(Kyx*Sx/Kx + Sy/Ky + -Kyz*Sz/Kz);
    m31 := -Kzx/Kx; m32 := Kzy/Ky; m33 := 1/Kz; m34 := -(-Kzx*Sx/Kx + Kzy*Sy/Ky + Sz/Kz);
   end;
end;

class function TMetrInclinMath.ImportIncFile(L: lua_State): Integer;
begin
  ImportIncFile(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class procedure TMetrInclinMath.M3x4ToHorizont(mul: Double; var Data: TConvert);
 var
  a: array[0..2, 0..2]of Double;
  b: array[0..2] of Double;
  x: PDoubleArray;
  inf: Integer;
  e: IEquations;
begin
 with Data do
  begin
    Kx := 1/m11;
    Ky := 1/m22;
    Kz := 1/m33;
    Kxy := -m12/m22;
    Kxz :=  m13/m33;
    Kyx :=  m21/m11;
    Kyz := -m23/m33;
    Kzx := -m31/m11;
    Kzy :=  m32/m22;
    b[0] := m14;
    b[1] := m24;
    b[2] := m34;
    a[0,0] := -mul/Kx;      a[0, 1] :=  mul/Ky*Kxy; a[0, 2] := -mul/Kz*Kxz;
    a[1,0] := -mul/Kx*Kyx;  a[1, 1] := -mul/Ky;     a[1, 2] :=  mul/Kz*Kyz;
    a[2,0] :=  mul/Kx*Kzx;  a[2, 1] := -mul/Ky*Kzy; a[2, 2] := -mul/Kz;
    EquationsFactory(e);
    CheckMath(e, e.Linear(@a, 3,@b, inf, x));
    sx := x[0];
    sy := x[1];
    sz := x[2];
    Kxy := Kxy*180/pi;
    Kxz := Kxz*180/pi;
    Kyx := Kyx*180/pi;
    Kyz := Kyz*180/pi;
    Kzx := Kzx*180/pi;
    Kzy := Kzy*180/pi;
  end;
end;

class procedure TMetrInclinMath.SolvRoll(const Y: TRollData; out rep: TResultSolvRoll);
 var
  etalon: array[0..35, 0..2] of Double;
  i: Integer;
  ls: ILSFitting;
  r: PSLFittingReport;
  info: Integer;
  c: PDoubleArray;
begin
  for i := 0 to 35 do
   begin
    etalon[i,0] := 1;
    etalon[i,1] := Sin(2*pi*i/36);
    etalon[i,2] := Cos(2*pi*i/36);
   end;
  LSFittingFactory(ls);
  CheckMath(ls, ls.Linear(@Y , @etalon, 36, 3, info, c, r));
  rep.D0 := c[0];
  rep.Amp := Hypot(c[1], c[2]);
  rep.Faza := ArcTan2(c[2], c[1]);
  rep.MaxErrIndex := 0;
  rep.MaxErr := 0;
  for i := 0 to 35 do with rep do
   begin
    IstData[i] := D0 + Amp*sin(2*pi*i/36 + Faza);
    Noise[i] := (Y[i] - IstData[i])*30;
    if Abs(Noise[i]/30) > MaxErr then
     begin
      MaxErr := Abs(Noise[i]/30);
      MaxErrIndex := i*10;
     end;
    Err[i] := IstData[i] + Noise[i];
   end;
  if rep.Amp >0 then rep.StdNormErr := rep.MaxErr/rep.Amp*100;
end;

//class procedure TMetrInclinMath.AddSum<C>(Root: IXMLNode; Data: Double);
// var
//  a: IFindAnyData;
//begin
//  if not XSupport(Root, IFindAnyData, a) then
//   begin
//    if Supports(C.Create(), IFindAnyData, a) then (Root as IOwnIntfXMLNode).Intf := a
//    else raise EBaseException.CreateFmt('XMLNode %s не поддерживает IFindAnyData', [Root.NodeName]);
//   end;
//  a.Add(Data);
//end;

//class function TMetrInclinMath.GetSum(Root: IXMLNode): Double;
// var
//  a: IFindAnyData;
//begin
//  if  XSupport(Root, IFindAnyData, a) then Result := a.Data
//  else raise EBaseException.CreateFmt('XMLNode %s не поддерживает IAngleSum', [Root.NodeName]);
//end;

{class procedure TMetrInclinMath.SumAngle(Root: IXMLNode; ang: Double);
 var
  a: IAngleSum;
begin
  if not XSupport(Root, IAngleSum, a) then
   begin
    a := TAngleSum.Create;
    (Root as IOwnIntfXMLNode).Intf := a;
   end;
  a.Add(ang);
end;

class function TMetrInclinMath.UaAngle(Root: IXMLNode): Double;
 var
  a: IAngleSum;
begin
  if  XSupport(Root, IAngleSum, a) then Result := a.Data
  else raise EBaseException.CreateFmt('XMLNode %s не поддерживает IAngleSum', [Root.NodeName]);
end;}

{ TLMFitting }

class procedure TLMFitting.func_cb_roll(const k, f: PDoubleArray);
 var
  xi,yi,atn,ai, sq: Double;
  i: Integer;
begin
   with PxRec(k)^ do for i := 0 to 35 do
    begin
     xi := m11*X[i] + m12*Y[i] + m14;
     yi :=            m22*Y[i] + m24;
     atn := DegNormalize(RadToDeg(arctan2(yi, -xi) - (Faza0 + dF)));
     ai := i*10;
     sq := TMetrInclinMath.DeltaAngle(ai-atn);
     f[i] := sqr(sq);
     f[i + 36] := Sqr(Hypot(xi, yi) - 1000);
    end;
end;

class procedure TLMFitting.RunRoll(m11, m12, m14, m22, m24, dF: Double);
 var
  e: ILMFitting;
  k: TXrec;
  rep: PLMFittingReport;
  xout: PxRec;
begin
  k.m11 := m11;
  k.m12 := m12;
  k.m14 := m14;
  k.m22 := m22;
  k.m24 := m24;
  k.df := df;
  Faza0 := arctan2(Y[0], -X[0]);
  LMFittingFactory(e);
  CheckMath(e, e.FitV(6, 36*2, PDoubleArray(@k), 0.0001, 0, 0, 0, 0, func_cb_roll, PDoubleArray(xout), rep));
  Faza0 := (xout.dF + Faza0)*180/pi;
end;

class procedure TLMFitting.func_cb_z(const k, f: PDoubleArray);
 var
  zi: Double;
  i: Integer;
  zz: PZRec;
begin
  zz := PZRec(k);
   with zz^ do for i := 0 to 35 do
    begin
     zi := m31*X[i] + m32*Y[i] + (1000-m34)/ZMax*Z[i] + m34;
     f[i] := sqr(zi);
    end;
end;

class procedure TLMFitting.RunZ(m31,m32,m34, Zm: Double);
 var
  e: ILMFitting;
  k: TZrec;
  rep: PLMFittingReport;
  zout: PZRec;
begin
  k.m31 := m31;
  k.m32 := m32;
  k.m34 := m34;
  ZMax := Zm;
  LMFittingFactory(e);
  CheckMath(e, e.FitV(3, 36, PDoubleArray(@k), 0.0001, 0, 0, 0, 0, func_cb_z, PDoubleArray(zout), rep));
end;

class procedure TLMFitting.Run(AX, AY, AZ: TRollData; ZMaxR, kXR, kYR: Double; out Res: TResult);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  xinp: TXrec;
  xout: PXRec;
  zinp: TZrec;
  zout: PZRec;
begin
  X := AX;
  Y := AY;
  Z := AZ;
  ZMax := ZMaxR;
  kX := kXR;
  kY := kYR;

  xinp.m11 := 1;
  xinp.m12 := 0;
  xinp.m14 := 0;
  xinp.m22 := 1;
  xinp.m24 := 0;
  xinp.df  := 0;

  zinp.m31 := 0;
  zinp.m32 := 0;
  zinp.m34 := 0;

  Faza0 := arctan2(Y[0], -X[0]);

  LMFittingFactory(e);
  CheckMath(e, e.FitV(6, 36*2, PDoubleArray(@xinp), 0.000001, 0, 0, 0, 10000, func_cb_roll, PDoubleArray(xout), rep));

  Res.m11 := xout.m11;
  Res.m12 := xout.m12;
  Res.m14 := xout.m14;
  Res.m22 := xout.m22;
  Res.m24 := xout.m24;
  Res.Faza := Faza0 + xout.dF;

  CheckMath(e, e.FitV(3, 36, PDoubleArray(@zinp), 0.000001, 0, 0, 0, 10000, func_cb_z, PDoubleArray(zout), rep));
  Res.m31 := zout.m31;
  Res.m32 := zout.m32;
  Res.m34 := zout.m34;

  Res.m21 := 0;
  Res.m33 := (1000 - Res.m34)/ZMax;
  Res.m13 := -(Res.m11*kX + Res.m14)/ZMax;
  Res.m23 := -(Res.m22*kY + Res.m24)/ZMax;
end;

{ TAngleFtting.TMetr }

procedure TAngleFtting.TMetr.AssignTo(v: Variant);
begin
  v.m3x4.m11 := m11; v.m3x4.m12 := m12; v.m3x4.m13 := m13; v.m3x4.m14 := m14;
  v.m3x4.m21 := m21; v.m3x4.m22 := m22; v.m3x4.m23 := m23; v.m3x4.m24 := m24;
  v.m3x4.m31 := m31; v.m3x4.m32 := m32; v.m3x4.m33 := m33; v.m3x4.m34 := m34;
end;

class operator TAngleFtting.TMetr.Explicit(const M: TMetr): TMatrix4;
begin
  Result.m11 := M.m11; Result.m12 := M.m12; Result.m13 := M.m13; Result.m14 := M.m14;
  Result.m21 := M.m21; Result.m22 := M.m22; Result.m23 := M.m23; Result.m24 := M.m24;
  Result.m31 := M.m31; Result.m32 := M.m32; Result.m33 := M.m33; Result.m34 := M.m34;
  Result.m41 := 0;     Result.m42 := 0;     Result.m43 := 0;     Result.m44 := 1;
end;

class operator TAngleFtting.TMetr.Explicit(const M: TMatrix4): TMetr;
begin
  Result.m11 := M.m11; Result.m12 := M.m12; Result.m13 := M.m13; Result.m14 := M.m14;
  Result.m21 := M.m21; Result.m22 := M.m22; Result.m23 := M.m23; Result.m24 := M.m24;
  Result.m31 := M.m31; Result.m32 := M.m32; Result.m33 := M.m33; Result.m34 := M.m34;
end;

class function TAngleFtting.TMetr.LenAzi: Integer;
begin
  Result := SizeOf(TMetr) div SizeOf(Double) - 1;
end;

class function TAngleFtting.TMetr.LenZu: Integer;
begin
  Result := SizeOf(TMetr) div SizeOf(Double) - 2;
end;

procedure TAngleFtting.TMetr.MulVect(ks: PDoubleArray);
begin
  m11 := m11*ks[0]; m12 := m12*ks[0]; m13 := m13*ks[0]; m14 := m14*ks[0];
  m21 := m21*ks[0]; m22 := m22*ks[0]; m23 := m23*ks[0]; m24 := m24*ks[0];
  m31 := m31*ks[0]; m32 := m32*ks[0]; m33 := m33*ks[0]; m34 := m34*ks[0];
end;

procedure TAngleFtting.TMetr.Reset;
begin
  m11 := 1; m12 := 0; m13 := 0;  m14 := 0;
  m21 := 0; m22 := 1; m23 := 0;  m24 := 0;
  m31 := 0; m32 := 0; m33 := 1;  m34 := 0;
end;

{ TAngleFtting.TZenRec }

{procedure TAngleFtting.TZenRec.Reset;
begin
  m11 := 1; m12 := 0; m13 := 0;  m14 := 0;
                      m23 := 0;  m24 := 0;
  m31 := 0; m32 := 0; m33 := 1;  m34 := 0;
end;}

{ TAngleFtting.TAziRec }

{procedure TAngleFtting.TAziRec.Reset;
begin
  m11 := 1; m12 := 0; m13 := 0;  m14 := 0;
  m21 := 0;           m23 := 0;  m24 := 0;
  m31 := 0; m32 := 0; m33 := 1;  m34 := 0;
end;}

{ TAngleFtting.TResult }

{procedure TAngleFtting.TResult.Assign(ks: TZenRec);
begin
  m11 := ks.m11; m12 := ks.m12; m13 := ks.m13; m14 := ks.m14;
  m21 :=      0; m22 :=      1; m13 := ks.m23; m24 := ks.m24;
  m31 := ks.m31; m32 := ks.m32; m13 := ks.m33; m34 := ks.m34;
end;

procedure TAngleFtting.TResult.Assign(ks: TAziRec);
begin
  m11 := ks.m11; m12 := ks.m12; m13 := ks.m13; m14 := ks.m14;
  m21 := ks.m21; m22 :=      1; m13 := ks.m23; m24 := ks.m24;
  m31 := ks.m31; m32 := ks.m32; m13 := ks.m33; m34 := ks.m34;
end;

procedure TAngleFtting.TResult.MulK(ks: PDoubleArray);
begin
  m11 := m11*ks[0]; m12 := m12*ks[0]; m13 := m13*ks[0]; m14 := m14*ks[0];
  m21 := m21*ks[1]; m22 := m22*ks[1]; m23 := m23*ks[1]; m24 := m24*ks[1];
  m31 := m31*ks[2]; m32 := m32*ks[2]; m13 := m33*ks[2]; m34 := m34*ks[2];
end;    }

{ TAngleFtting }

class procedure TAngleFtting.func_cb_amp_azi(const k, f: PDoubleArray);
 var
  xi,yi,zi: Double;
  i: Integer;
begin
  with AziMetr do for i:= 0 to Length(Inp)-1 do with Inp[i] do
   begin
    xi := (hx*m11 + hy*m12 + hz*m13 + m14) * k[0];
    yi := (hx*m21 + hy     + hz*m23 + m24) * k[0];
    zi := (hx*m31 + hy*m32 + hz*m33 + m34) * k[0];
    f[i] := sqr(1000 - TXMLScriptMath.Hypot3D(xi,yi,zi));
   end;
end;

class procedure TAngleFtting.func_cb_amp_zen(const k, f: PDoubleArray);
 var
  xi,yi,zi: Double;
  i: Integer;
begin
  with ZenMetr do for i:= 0 to Length(Inp)-1 do with Inp[i] do
   begin
    xi := (gx*m11 + gy*m12 + gz*m13 + m14) * k[0];
    yi := (         gy     + gz*m23 + m24) * k[0];
    zi := (gx*m31 + gy*m32 + gz*m33 + m34) * k[0];
    f[i] := sqr(1000 - TXMLScriptMath.Hypot3D(xi,yi,zi));
   end;
end;

class procedure TAngleFtting.func_cb_azi(const k, f: PDoubleArray);
 var
  xi,yi,zi, Hix, Hiy, os, oc, zs, zc, Azi, dang: Double;
  i: Integer;
  procedure UpdateZen;
   var
    o, zu: Double;
    t: TMetr;
    xi,yi,zi: Double;
  begin
    t := ZenMetr;
    with ZenMetr, Inp[i] do
     begin
      xi := gx*m11 + gy*m12 + gz*m13 + m14;
      yi :=          gy*m22 + gz*m23 + m24;
      zi := gx*m31 + gy*m32 + gz*m33 + m34;

      o := Arctan2(yi, -xi);
      zu := Arctan2(Hypot(xi, yi), zi);

      os := sin(o);
      oc := cos(o);
      zs := sin(zu);
      zc := cos(zu);
     end;
  end;
begin
  with PMetr(k)^ do for i:= 0 to Length(Inp)-1 do with Inp[i] do
   begin
    UpdateZen;

    xi := hx*m11 + hy*m12 + hz*m13 + m14;
    yi := hx*m21 + hy*m22 + hz*m23 + m24;
//    yi := hx*m21 + hy     + hz*m23 + m24;
    zi := hx*m31 + hy*m32 + hz*m33 + m34;

    Hix := (xi*oc - yi*os)*zc + zi*zs;
    Hiy :=  xi*os + yi*oc;

    Azi := DegNormalize(RadToDeg(-Arctan2(Hiy, Hix)));

    dang := TMetrInclinMath.DeltaAngle(Azi - AziStol);
    f[i] := sqr(dang);

    f[Length(Inp)+i] := sqr(MagAmp - TXMLScriptMath.Hypot3D(xi,yi,zi))*WeitAzi;
   end;
end;

class procedure TAngleFtting.func_cb_azi_nostol(const k, f: PDoubleArray);
begin

end;

class procedure TAngleFtting.func_cb_zen_nostol(const k, f: PDoubleArray);
 var
  xi,yi,zi: Double;
  i: Integer;
begin
  with PMetr(k)^ do for i:= 0 to Length(Inp)-1 do with Inp[i] do
   begin
    xi := gx*m11 + gy*m12 + gz*m13 + m14;
    yi :=          gy  + gz*m23 + m24;
    zi := gx*m31 + gy*m32 + gz*m33 + m34;
    f[i] := sqr(m21 - TXMLScriptMath.Hypot3D(xi,yi,zi));
   end;
end;

class procedure TAngleFtting.RunZ_nostol(AInp: TInput; out Res: TMetr);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  GIn: TMetr;
  GOut: PMetr;
  k: Double;
//  Aout: PDoubleArray;
//  ain: Double;
begin
  Inp := AInp;
  GIn.Reset;
  with AInp[0] do Gin.m21 := TXMLScriptMath.Hypot3D(gx,gy,gz)*1.001;
  Gin.m22 := 1;
  LMFittingFactory(e);
  CheckMath(e, e.FitV(GIn.LenAzi, Length(Inp), PDoubleArray(@Gin), 0.000001, 0, 0, 0, 10000, func_cb_zen_nostol, PDoubleArray(GOut), rep));
  k := 1000/GOut.m21;
  GOut.m21 := 0;
  GOut.m22 := 1;
  GOut.MulVect(PDoubleArray(@k));
  ZenMetr := GOut^;
  ZenMetr.m21 := 0;
  Res := ZenMetr;
end;

class procedure TAngleFtting.RunA_nostol(AInp: TInput; out Res: TMetr);
begin

end;

class procedure TAngleFtting.func_cb_zen(const k, f: PDoubleArray);
 var
  xi,yi,zi, zu, dang: Double;
  i: Integer;
begin
  with PMetr(k)^ do for i:= 0 to Length(Inp)-1 do with Inp[i] do
   begin
    xi := gx*m11 + gy*m12 + gz*m13 + m14;
    yi :=          gy*m21 + gz*m23 + m24;
//    yi :=          gy     + gz*m23 + m24;
    zi := gx*m31 + gy*m32 + gz*m33 + m34;
    zu := DegNormalize(RadToDeg(arctan2(Hypot(xi, yi), zi)));
    if ZenStol > 180 then
      dang := TMetrInclinMath.DeltaAngle(Zu-(360 - ZenStol))
    else
      dang := TMetrInclinMath.DeltaAngle(Zu-ZenStol);
    f[i] := sqr(dang);
    f[Length(Inp)+i] := sqr(1000 - TXMLScriptMath.Hypot3D(xi,yi,zi))*WeitZen;
   end;
end;

class procedure TAngleFtting.RunZ(AInp: TInput; var Res: TMetr; AWeitZen: Double);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  GIn: TMetr;
  GOut: PMetr;
  Aout: PDoubleArray;
  ain: Double;
begin
  Inp := AInp;
  WeitZen := AWeitZen;
  GIn := Res;
  LMFittingFactory(e);
//  CheckMath(e, e.FitV(Gin.LenZu, Length(Inp), @Gin, 0.000001, 0, 0, 0, 10000, func_cb_zen, PDoubleArray(GOut), rep));
  CheckMath(e, e.FitV(Gin.LenZu+1, Length(Inp)*2, PDoubleArray(@Gin), 0.000001, 0, 0, 0, 100000, func_cb_zen, PDoubleArray(GOut), rep));
  ZenMetr := GOut^;
  ZenMetr.m22 := ZenMetr.m21;
  ZenMetr.m21 := 0;
//  ain := 1;
//  CheckMath(e, e.FitV(1, Length(Inp), @ain, 0.000001, 0, 0, 0, 10000, func_cb_amp_zen, Aout, rep));
//  ZenMetr.MulVect(Aout);
  Res := ZenMetr;
end;

class procedure TAngleFtting.RunA(AInp: TInput; out Res: TMetr; AWeitAzi: Double);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  HIn: TMetr;
  HOut: PMetr;
  Aout: PDoubleArray;
  ain: Double;
begin
  Inp := AInp;
  WeitAzi := AWeitAzi;
  HIn.Reset;
  LMFittingFactory(e);
  CheckMath(e, e.FitV(Hin.LenAzi+1, Length(Inp)*2, PDoubleArray(@Hin), 0.000001, 0, 0, 0, 100000, func_cb_azi, PDoubleArray(HOut), rep));
  AziMetr := HOut^;

{  AziMetr.m22 := 1;
  ain := 1;
  CheckMath(e, e.FitV(1, Length(Inp), @ain, 0.000001, 0, 0, 0, 10000, func_cb_amp_azi, Aout, rep));
  AziMetr.MulVect(Aout);}
  Res := AziMetr;
end;

procedure Matrix4AssignToVariant(m: TMatrix4; v: Variant);
begin
  with m do
   begin
    v.m3x4.m11 := m11; v.m3x4.m12 := m12; v.m3x4.m13 := m13; v.m3x4.m14 := m14;
    v.m3x4.m21 := m21; v.m3x4.m22 := m22; v.m3x4.m23 := m23; v.m3x4.m24 := m24;
    v.m3x4.m31 := m31; v.m3x4.m32 := m32; v.m3x4.m33 := m33; v.m3x4.m34 := m34;
   end;
end;

{ TInclinMetr3x4 }

{procedure TInclinMetr3x4.AssignTo(v: Variant);
begin
  v.m3x4.m11 := m11; v.m3x4.m12 := m12; v.m3x4.m13 := m13; v.m3x4.m14 := m14;
  v.m3x4.m21 := m21; v.m3x4.m22 := m22; v.m3x4.m23 := m23; v.m3x4.m24 := m24;
  v.m3x4.m31 := m31; v.m3x4.m32 := m32; v.m3x4.m33 := m33; v.m3x4.m34 := m34;
end;

procedure TInclinMetr3x4.Default;
begin
  Self := system.default(TInclinMetr3x4);
  m11 := 1;
  m22 := 1;
  m33 := 1;
end;

function TInclinMetr3x4.Invert: TInclinMetr3x4;
begin
  Result.m11 := m22*m33 - m23*m32; Result.m12 := m13*m32 - m12*m33; Result.m13 := m12*m23 - m13*m22;
  Result.m21 := m23*m31 - m21*m33; Result.m22 := m11*m33 - m13*m31; Result.m23 := m13*m21 - m11*m23;
  Result.m31 := m21*m32 - m22*m31; Result.m32 := m12*m31 - m11*m32; Result.m33 := m11*m22 - m12*m21;

  Result.m14 := -(Result.m11*m14 + Result.m12*m24 + Result.m13*m34);
  Result.m24 := -(Result.m21*m14 + Result.m22*m24 + Result.m23*m34);
  Result.m34 := -(Result.m31*m14 + Result.m32*m24 + Result.m33*m34);

  Result := Scale(1/(m11*m22*m33 - m11*m23*m32 - m12*m21*m33 + m12*m23*m31 + m13*m21*m32 - m13*m22*m31), Result);
end;

class operator TInclinMetr3x4.Multiply(a: TInclinMetr3x4; v: TInclinVector): TInclinVector;
begin
  with a, v do
   begin
    Result.X := m11*x + m12*y + m13*z + m14;
    Result.Y := m21*x + m22*y + m23*z + m24;
    Result.Z := m31*x + m32*y + m33*z + m34;
   end;
end;

class function TInclinMetr3x4.Scale(Factor: Double; matrix: TInclinMetr3x4): TInclinMetr3x4;
begin
  with matrix do
   begin
    Result.m11 := m11*Factor; Result.m12 := m12*Factor; Result.m13 := m13*Factor; Result.m14 := m14*Factor;
    Result.m21 := m21*Factor; Result.m22 := m22*Factor; Result.m23 := m23*Factor; Result.m24 := m24*Factor;
    Result.m31 := m31*Factor; Result.m32 := m32*Factor; Result.m33 := m33*Factor; Result.m34 := m34*Factor;
   end;
end;  }

{ TInclinVector }

{class operator TInclinVector.Multiply(a: TInclinVector; Factor: Double): TInclinVector;
begin
  Result.X := a.X*Factor;
  Result.Y := a.Y*Factor;
  Result.Z := a.Z*Factor;
end;}

{ TInclPoint }

class operator TInclPoint.Implicit(V: Variant): TInclPoint;
begin
  Result.G.X := v.accel.X.DEV.VALUE;
  Result.G.y := v.accel.Y.DEV.VALUE;
  Result.G.z := v.accel.Z.DEV.VALUE;
  Result.h.x := v.magnit.X.DEV.VALUE;
  Result.h.y := v.magnit.Y.DEV.VALUE;
  Result.h.z := v.magnit.Z.DEV.VALUE;
  try
   Result.T := v.T.DEV.VALUE;
  except
   Result.T := 32;
  end;
end;

end.
