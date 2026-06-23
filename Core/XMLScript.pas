unit XMLScript;

interface

uses debug_except, Container, o_iclassesrtti, ExtendIntf, Vcl.Dialogs,
    SysUtils, o_iinterpreter, o_ipascal, Xml.XMLIntf, System.Generics.Collections, System.Classes, System.Variants;

    const
//     MAIN = 'MAIN_METR';
//     SIMP = 'SIMPLE_METR';
     EXEC = 'EXEC_METR';
     SETUP = 'SETUP_METR';
type
  TXmlScriptInner = class(TfsScript, IXMLScript, IInterface)
  private
    type
     TRunScriptRec = record
       TrrRoot: IXMLNode;
       RunRoot: IXMLNode;
       RunFunc: string;
       RunPath: string;
       RunAdr: Integer;
       //V: Variant;
      constructor Create(TrRoot, RnRoot: IXMLNode; const RnPath, RnFuncName: string; Aadr: Integer);
     end;
   var
    FRunScript: TList<TRunScriptRec>;
    FRefCount: Integer;
    class var UserMethods: TDictionary<string, TfsCallMethodEvent>;
    class var GScript: IXMLNode;
    class constructor Create;
    class destructor Destroy;
    function PropGetLines: TStrings;
    procedure PropSetLines(const Value: TStrings);
    procedure AddXML(Aadr: Integer; const RnPath: string; TrRoot, RnRoot: IXMLNode;  Script: IXMLNode; const ScriptAtr: string; const RootPrefix: string = '');
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function _AddRef: Integer; reintroduce; stdcall;
    function _Release: Integer; reintroduce; stdcall;

    function GetScriptRoot: IXMLNode;
    procedure SetScriptRoot(const Value: IXMLNode);
    function  GetErrorMsg: String;
    function  GetErrorPos: String;

    function CallFunction(const Name: String; const Params: array of Variant): Variant; overload;
    procedure ClearLines;

    procedure Execute(); reintroduce; overload;
    procedure Execute(const ExePath: string); overload;
    procedure Execute(const ExePath: string; adr: Integer); overload;

    procedure GetMetrStrings(var Values: TStrings; node: IXMLNode = nil);
    // добавляет метрологию и рассчетные рараметры в XML
    { TODO : Создать две функции установок и выполнения }
    procedure SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure RegisterMethods(const method: array of string; CallMeth: TfsCallMethodEvent);
    class procedure UnRegisterMethods(CallMeth: TfsCallMethodEvent);
  end;

  TXMLScriptFactory = class(TInterfacedObject, IXMLScriptFactory)
  protected
    function GetScriptRoot: IXMLNode;
    function Get(AOwner: TComponent): IXMLScript;
    function ScriptExec(TrrData, Data: IXMLNode; const RootName, Name, Attr: string): Boolean;
  end;

implementation

uses tools;

function TXMLScriptFactory.Get(AOwner: TComponent): IXMLScript;
begin
  Result := TXmlScriptInner.Create(AOwner);
end;

function TXMLScriptFactory.GetScriptRoot: IXMLNode;
begin
  Result :=  TXmlScriptInner.GScript;
end;

function TXMLScriptFactory.ScriptExec(TrrData, Data: IXMLNode; const RootName, Name, Attr: string): Boolean;
 var
  sc: TXmlScriptInner;
  scr: IXMLNode;
begin
  scr := TXmlScriptInner.GScript.ChildNodes.FindNode(RootName);
  if not Assigned(scr) then Exit(False);
  if Name <> '' then scr := GetXNode(scr, 'MODEL.'+ Name);
  if not (Assigned(scr) and scr.HasAttribute(Attr))  then Exit(False);
  sc := TXmlScriptInner.Create(nil);
  try
   sc.AddXML(1,'',TrrData, Data, scr, Attr, RootName);
   sc.Lines.Add('begin');
   sc.Lines.Add('end.');
   Result := sc.Compile;
   if Result then sc.Execute;
  finally
   sc.Free;
  end;
end;


{$REGION 'TXmlScript'}

{ TXmlScript.TAdrFnRec }

function TXmlScriptInner.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
  if GetInterface(IID, Obj) then Exit(S_OK)
end;

function TXmlScriptInner._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TXmlScriptInner._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
//  TDebug.Log('  IForm._Release  %s  %d       ', [Name, Result]);
  if Result = 0 then
    Destroy;
end;

constructor TXmlScriptInner.TRunScriptRec.Create(TrRoot, RnRoot: IXMLNode; const RnPath, RnFuncName: string; Aadr: Integer);
begin
  TrrRoot := TrRoot;
  RunRoot := RnRoot;
  RunPath := RnPath;
  RunFunc := RnFuncName;
  RunAdr := Aadr;
  //V := VarArrayOf([XToVar(RunRoot), XToVar(TrrRoot)]);
end;

{ TXmlScript }

class constructor TXmlScriptInner.Create;
 var
  LDoc: IXMLDocument;
  FFileMet: string;
begin
  LDoc := NewXDocument();
  FFileMet := ExtractFilePath(ParamStr(0))+'Devices\Trr.xml';
  if FileExists(FFileMet) then
   begin
    LDoc.LoadFromFile(FFileMet);
    GScript := LDoc.DocumentElement;
   end
   else GScript := LDoc.AddChild('TRR');
  TDebug.Log('class constructor TXmlScript.Create');
  fsRTTIModules.Add(o_iclassesrtti.TFunctions);
  UserMethods := TDictionary<string, TfsCallMethodEvent>.Create();
end;

class destructor TXmlScriptInner.Destroy;
begin
  UserMethods.Free;
  fsRTTIModules.Remove(TFunctions);
  TDebug.Log('class destructor TXmlScript.Destroy;');
end;

class procedure TXmlScriptInner.RegisterMethods(const method: array of string; CallMeth: TfsCallMethodEvent);
 var
  s: string;
begin
  for s in method do UserMethods.Add(s, CallMeth);
end;

procedure TXmlScriptInner.SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);
 const
  SF = 'SIMPLE_FORMAT';
  MD = 'MODEL';
 var
  sd: IXmlScript;
  adr: Integer;
  mtr: IXMLNode;
//  ExecSetup: Boolean;
  procedure AddAll(dev: IXMLNode; const ExePath: string);
   var
    r: IXMLNode;
  begin
    r := dev.ChildNodes.FindNode(ExePath);
    if not Assigned(r) then Exit;
    ExecXTree(r, procedure(n: IXMLNode)
     var
      s: string;
      sr, mc: IXMLNode;
     procedure AddX(TrRoot, Script: IXMLNode; const RootPrefix: string = '');
     begin
       if ExecSetup then sd.AddXML(adr, ExePath, TrRoot, n, Script, SETUP, RootPrefix);
       ExeSc.AddXml(adr, ExePath, TrRoot, n, Script, EXEC, RootPrefix);
     end;
    begin
      s := n.NodeName;
      sr := GScript.ChildNodes.FindNode(s);
      if Assigned(sr) then
       begin
        mc := mtr.ChildNodes.FindNode(s);
        if not Assigned(mc) then
         begin
          mc := mtr.AddChild(s);
          if n.HasAttribute(AT_METR) then mc.Attributes[AT_METR] := n.Attributes[AT_METR];
         end;
        AddX(mc, sr);
        if n.HasAttribute(AT_METR) then AddX(mc, sr.ChildNodes[MD].ChildNodes[n.Attributes[AT_METR]], s);
       end
      else if n.HasAttribute(AT_METR) then AddX(mtr, GScript.ChildNodes[SF].ChildNodes[MD].ChildNodes[n.Attributes[AT_METR]], SF);
    end);
  end;
 var
  d: IXMLNode;
begin
//  ExecSetup := True;
  ExeSc.ClearLines;
  if ExecSetup then sd := (GContainer as IXMLScriptFactory).Get(nil);
  try
   { TODO : Впроекте V3 работать не будет !!!! будет при правильном node}
   for d in XEnum(node) do if d.HasAttribute(AT_ADDR) then
    begin
     adr := d.Attributes[AT_ADDR];
     mtr := d.ChildNodes.FindNode(T_MTR);
     if not Assigned(mtr) then mtr := d.AddChild(T_MTR);
     AddAll(d, T_WRK);
     AddAll(d, T_RAM);
    end;
   if ExecSetup then
    begin
     sd.Lines.Add('begin');
     sd.Lines.Add('end.');

     if not sd.Compile then MessageDlg('Ошибка компиляции установок-'+sd.ErrorMsg+':'+sd.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);
     sd.Execute; { TODO 5 -cОШИВКА!!! : ОШИБКА заполняется метрология (если есть) значениями по умолчанию!!! }

     //sd.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'GKScriptSetup.txt');
    end;
//    node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'RP45.xml');
    ExeSc.Lines.Add('begin');
    ExeSc.Lines.Add('end.');

//    ExeSc.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'~tst\ExeSc.txt');

    if not ExeSc.Compile then MessageDlg('Ошибка компиляции выполнения-'+ExeSc.ErrorMsg+':'+ExeSc.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);

   // node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'PSKafter.xml');

  finally
   if ExecSetup then sd := nil;
  end;
end;

procedure TXmlScriptInner.SetScriptRoot(const Value: IXMLNode);
begin
  GScript := Value;
end;

class procedure TXmlScriptInner.UnRegisterMethods(CallMeth: TfsCallMethodEvent);
 var
  p: TPair<string, TfsCallMethodEvent>;
begin
  for p in UserMethods.ToArray do if Addr(p.Value) = Addr(CallMeth) then UserMethods.Remove(p.Key);
end;

procedure TXmlScriptInner.AddXML(Aadr: Integer; const RnPath: string; TrRoot, RnRoot: IXMLNode;  Script: IXMLNode; const ScriptAtr: string; const RootPrefix: string = '');
 const
  NL = #$D#$A;
  FUNC_FMT = 'procedure %s(v, t: variant);';
 var
  fs, fn: string;
  function fnd(): Boolean;
   var
    s: string;
  begin
    Result := False;
    for s in Lines do if SameText(s,fn) then Exit(True);
  end;
begin
  if not Assigned(Script) or not Script.HasAttribute(ScriptAtr) then Exit;
  fs := RootPrefix + Script.NodeName + ScriptAtr;
  fn := Format(FUNC_FMT, [fs]);
  if not Fnd() then Lines.Text := Lines.Text + NL + fn + NL + Script.Attributes[ScriptAtr];
  FRunScript.Add(TRunScriptRec.Create(TrRoot, RnRoot, RnPath, fs, AAdr));
end;

function TXmlScriptInner.CallFunction(const Name: String; const Params: array of Variant): Variant;
begin
  Result := CallFunction(Name, VarArrayOf(Params));
end;

procedure TXmlScriptInner.ClearLines;
 var
  r: TRunScriptRec;
  v: TfsCustomVariable;
begin
  Lines.Clear;
  for r in FRunScript do
   begin
    v := Find(r.RunFunc);
    if Assigned(v) then Remove(v);
   end;
  FRunScript.Clear;
end;

constructor TXmlScriptInner.Create(AOwner: TComponent);
 var
  p: TPair<string, TfsCallMethodEvent>;
begin
  inherited Create(AOwner);
  Parent := fsGlobalUnit;
  FRunScript := TList<TRunScriptRec>.Create;

//  TDebug.Log('Count %d',[Count]);

  for p in UserMethods do AddMethod(p.Key, p.Value);

//  TDebug.Log('Count %d',[Count]);
end;

destructor TXmlScriptInner.Destroy;
begin
  FRunScript.Free;
  inherited;
end;

procedure TXmlScriptInner.Execute;
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do CallFunction(p.RunFunc, [XToVar(p.RunRoot), XToVar(p.TrrRoot)]);
end;

procedure TXmlScriptInner.Execute(const ExePath: string);
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do
    if ExePath = p.RunPath then
      CallFunction(p.RunFunc, [XToVar(p.RunRoot), XToVar(p.TrrRoot)]);
end;

procedure TXmlScriptInner.Execute(const ExePath: string; adr: Integer);
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do
   if (p.RunAdr = adr) and (ExePath = p.RunPath) then
    CallFunction(p.RunFunc, [XToVar(p.RunRoot), XToVar(p.TrrRoot)]);
end;

function TXmlScriptInner.GetErrorMsg: String;
begin
  Result := ErrorMsg;
end;

function TXmlScriptInner.GetErrorPos: String;
begin
  Result := ErrorPos;
end;

procedure TXmlScriptInner.GetMetrStrings(var Values: TStrings; node: IXMLNode);
 const
  SF = 'SIMPLE_FORMAT';
  MD = 'MODEL';
 var
  n, t: IXMLNode;
begin
  Values.Clear;
  n := GScript.ChildNodes.FindNode(node.NodeName);
  if Assigned(n) then         for t in XEnum(n.ChildNodes[MD]) do Values.Add(t.NodeName)
  else for t in XEnum(GScript.ChildNodes[SF].ChildNodes[MD]) do Values.Add(t.NodeName)
end;

function TXmlScriptInner.GetScriptRoot: IXMLNode;
begin
  Result := GScript;
end;

function TXmlScriptInner.PropGetLines: TStrings;
begin
  Result := Lines;
end;

procedure TXmlScriptInner.PropSetLines(const Value: TStrings);
begin
  Lines := Value;
end;

{$ENDREGION}

initialization
  TRegister.AddType<TXMLScriptFactory, IXMLScriptFactory>.LiveTime(ltTransient);
finalization
  GContainer.RemoveModel<TXMLScriptFactory>;
end.
