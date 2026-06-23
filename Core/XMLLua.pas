unit XMLLua;

interface

uses
      System.SysUtils, System.Variants, Winapi.Windows, System.Rtti,  System.Generics.Collections, System.Classes,
      Xml.XMLIntf, Xml.XMLDoc, VerySimple.Lua, VerySimple.Lua.Lib, dialogs,  System.IOUtils,
      debug_except, ExtendIntf, Container;

    const
//     MAIN = 'MAIN_METR';
//     SIMP = 'SIMPLE_METR';
     EXEC = 'EXEC_METR';
     SETUP = 'SETUP_METR';
type
  ELuaException = class(EBaseException);
  TXMLLua = class(TVerySimpleLua, IXMLScript)
  private
    procedure InnerAddAll(dev, Mtr: IXMLNode; adr: Integer; const ExePath: string; ExeSc, SetupDev: IXmlScript);
    type
     TRunScriptRec = record
       TrrRoot: IXMLNode;
       RunRoot: IXMLNode;
       RunFunc: string;
       RunPath: string;
       RunAdr: Integer;
       metr: string;
       //V: Variant;
      constructor Create(TrRoot, RnRoot: IXMLNode; const RnPath, RnFuncName: string; Aadr: Integer; metr: string = '');
     end;
   var
    FRunScript: TArray<TRunScriptRec>;
    FLines: TStrings;
    FLastError: string;
    FErrorPos: string;
    class var GlobalFunctions: Tlist<TClass>;
    class var GScript: IXMLNode;
    class constructor Create;
    class destructor Destroy;
    class procedure CreateXMLMetatable(L: lua_State); static;
    class function GetXMLNode(L: lua_State): Integer; cdecl; static;
    class function SetXMLNode(L: lua_State): Integer; cdecl; static;

//    class function InerAddMetrology(root: IXMLNode; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): IXMLNode; static;
   // procedure AddXML(Aadr: Integer; const RnPath: string; TrRoot, RnRoot: IXMLNode;  Script: IXMLNode; const ScriptAtr: string; const RootPrefix: string = '');
    procedure TrrExec(rr: TRunScriptRec);
 protected
    function LuaErrorPaser(const LuaErr: string): string;
    procedure DoError(Msg: String); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Open; override;
    class procedure CheckFunction(L: lua_State; const FuncName: string); static; inline;
//    class procedure CallXMLFunc(L: lua_State; const FuncName: string; arg1: IXMLNode; x2: IXMLNode = nil; x3: IXMLNode = nil); static;
    class procedure PushXmlToTable(L: lua_State; Node: IXMLNode); static; inline;
    class function XNode(L: lua_State; index: Integer): IXMLNode; static; inline;
    class procedure RegisterLuaMethods(const LuaMethClass: TClass); static;
    class function GetRegisteredLuaMethodsNames: string; static;
    // lua functions this published methods are automatically added
    // to the lua function table if called with TLua.Create(True) or Create()

  //private
    function GetScriptRoot: IXMLNode;
    procedure SetScriptRoot(const Value: IXMLNode);
    function PropGetLines: TStrings;
    procedure PropSetLines(const Value: TStrings);
    function  GetErrorMsg: String;
    function  GetErrorPos: String;
  //public
    procedure AddXML(Aadr: Integer; const RnPath: string; TrRoot, RnRoot: IXMLNode;  Script: IXMLNode; const ScriptAtr: string; const RootPrefix: string = '');
    procedure ClearLines;
    function Compile: Boolean;
    function CallFunction(const Name: String; const Params: TArray<Variant>; Nres: Integer = 0): TArray<Variant>;
    procedure Execute(); overload;
    procedure Execute(const ExePath: string); overload;
    procedure Execute(const ExePath: string; adr: Integer); overload;
    procedure GetMetrStrings(var Values: TStrings; node: IXMLNode = nil);
    procedure SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);
    /// <summary>
    /// Вызывается при удачном чтении метаданных устройства
    ///  обновляет данные скрипта выполнения прибора, вынолняет локальный скрипт установки
    /// </summary>
    /// <param name="node"> Корневой элемент прибора или устройства </param>
    ///
    /// <param name="adr">адрес устройства</param>
    ///
    /// <param name="ExeSc"> Глобальный скрипт выполнения прибора</param>
    procedure UpdateExecRunSetupMetr(node: IXMLNode;  adr: Integer; ExeSc: IXmlScript);
  end;

implementation

uses tools;

procedure TXMLLua.ClearLines;
begin
  Close;
  FLines.Clear;
  SetLength(FRunScript, 0);
end;

function TXMLLua.Compile: Boolean;
begin
//  Close;
  Open;
  FLastError :='';
  FErrorPos :='';
//  Result := Report(LuaState, loadString(FLines.Text)) = LUA_OK;
  Result := dochunk(LuaState, loadString(FLines.Text)) = LUA_OK;
end;

class constructor TXMLLua.Create;
 var
  LDoc: IXMLDocument;
  FFileMet: string;
begin
  LDoc := NewXDocument();
  FFileMet := ExtractFilePath(ParamStr(0))+'Devices\TrrLua.xml';
  if FileExists(FFileMet) then
   begin
    LDoc.LoadFromFile(FFileMet);
    GScript := LDoc.DocumentElement;
   end
   else GScript := LDoc.AddChild('TRR');
  TDebug.Log('class constructor TXMLLua.Create');
  GlobalFunctions := Tlist<TClass>.Create;
end;

class destructor TXMLLua.Destroy;
begin
  GlobalFunctions.DisposeOf;
end;

procedure TXMLLua.Execute;
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do TrrExec(p);
end;

procedure TXMLLua.Execute(const ExePath: string);
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do
    if ExePath = p.RunPath then TrrExec(p);
end;

procedure TXMLLua.Execute(const ExePath: string; adr: Integer);
 var
  p: TRunScriptRec;
begin
  for p in FRunScript do
   if (p.RunAdr = adr) and (ExePath = p.RunPath) then TrrExec(p);
end;

procedure TXMLLua.TrrExec(rr: TRunScriptRec);
 var
  m: TMarshaller;
begin
  try
  CheckFunction(LuaState, rr.RunFunc);
  PushXmlToTable(LuaState, rr.RunRoot);
  PushXmlToTable(LuaState, rr.TrrRoot);
  lua_pushstring(LuaState, m.AsAnsi(rr.RunPath).ToPointer);
  lua_pushinteger(LuaState, rr.RunAdr);
  lua_pushstring(LuaState, m.AsAnsi(rr.metr).ToPointer);
  if Report(LuaState, DoCall(LuaState, 5, 0)) <> LUA_OK then
   begin
    raise ELuaException.Create(FLastError);
   end;
  except
    if Assigned(TDebug.ExeptionEvent) then TDebug.ExeptionEvent( '[Debuglog] Error TrrExec',
       format(': func: %s path: %s adr: %d  %s',[rr.RunFunc, rr.RunPath, rr.RunAdr, FLastError]), #$D#$A);
    raise;
  end;
end;

class procedure TXMLLua.RegisterLuaMethods(const LuaMethClass: TClass);
begin
  GlobalFunctions.Add(LuaMethClass);
end;

function TXMLLua.GetErrorMsg: String;
begin
  Result :=  FLastError
end;

function TXMLLua.GetErrorPos: String;
begin
  Result :=  FErrorPos
end;

procedure TXMLLua.GetMetrStrings(var Values: TStrings; node: IXMLNode);
 const
  SF = 'SIMPLE_FORMAT';
  MD = 'MODEL';
 var
  n, t: IXMLNode;
begin
  Values.Clear;
  n := GScript.ChildNodes.FindNode(node.NodeName);
  if Assigned(n) then for t in XEnum(n.ChildNodes[MD]) do Values.Add(t.NodeName)
  else for t in XEnum(GScript.ChildNodes[SF].ChildNodes[MD]) do Values.Add(t.NodeName)
end;

class function TXMLLua.GetRegisteredLuaMethodsNames: string;
 var
  c: TClass;
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LContext := TRttiContext.Create;
  try
  Result := '';
  for c in GlobalFunctions do
   begin
    LType := LContext.GetType(c);
    for LMethod in LType.GetMethods do
      if ValidMethod(LMethod) then Result := Result+ ' '+ LMethod.Name;
   end;
  finally
    LContext.Free;
  end;
  Result := Result.Trim;
end;

function TXMLLua.GetScriptRoot: IXMLNode;
begin
  Result := GScript;
end;

procedure TXMLLua.Open;
 var
  c: TClass;
begin
  if Opened then Exit;
  inherited Open;
  for c in GlobalFunctions do RegisterFunctions(LuaState, c);
  CreateXMLMetatable(LuaState);
end;

constructor TXMLLua.Create;
begin
  inherited;
  LibraryPath :=IncludeTrailingPathDelimiter(TPath.GetLibraryPath) + LUA_LIBRARY;
//  FilePath := TPath.GetDocumentsPath + PathDelim; Dofile
  FLines := TStringList.Create;
//  Open;
end;

class procedure TXMLLua.CreateXMLMetatable(L: lua_State);
begin
  lua_createtable(L, 0, 2); //+1
  lua_pushcfunction(L, GetXMLNode);//+2
  lua_setfield(L, -2, '__index'); //+1
  lua_pushcfunction(L, SetXMLNode); //+2
  lua_setfield(L, -2, '__newindex');//+1
  lua_setglobal(L, '__MetaTable'); //0
end;

destructor TXMLLua.Destroy;
begin
  FLines.Free;
end;

function TXMLLua.LuaErrorPaser(const LuaErr: string): string;
 var
  s,d,vr: string;
  i,j,n: Integer;
begin
  Result := '';
  i := LuaErr.IndexOf(']:');
  j := LuaErr.IndexOf(':',i+2);
  if i>=0 then
   begin
    inc(i,2);
    s := LuaErr.Substring(i, j-i);
    d := LuaErr.Substring(j+1);
    i := d.IndexOf(chr(39));
    j := d.IndexOf(chr(39),i+1);
    vr := d.Substring(i+1, j-i-1);
    if not vr.IsEmpty and not s.IsEmpty then
     begin
      n := s.ToInteger();
      i := FLines[n-1].IndexOf(vr);
//      pos := SendEditor(SCI_PositionFromLIne, n-1,0);
//      IndicatorFillRange(pos+i, Length(vr));
      Result := Format('%d:%d:%d',[n,i, Length(vr)]);
     end;
   end;
end;

procedure TXMLLua.DoError(Msg: String);
begin
  FLastError := Msg;
  FErrorPos := LuaErrorPaser(Msg);
end;

procedure TXMLLua.AddXML(Aadr: Integer; const RnPath: string; TrRoot, RnRoot, Script: IXMLNode; const ScriptAtr, RootPrefix: string);
 const
  NL = #$D#$A;
  FUNC_FMT = 'function %s(v, t, run_path, run_address, metr)'; //'procedure %s(v, t: variant);';
 var
  fs, fn, mtr: string;
  function fnd(): Boolean;
   var
    s: string;
  begin
    Result := False;
    for s in FLines do if SameText(s,fn) then Exit(True);
  end;
  function ChekStr(const inp: string): string;
   const
    SSinp: TArray<string> = ['ИКН','ГК','АГК','ННК','ВИК','Глубиномер','ГГКП', 'БКС', 'БК'];
    SSout: TArray<string> = ['IKN','GK','AGK','NNK','VIK','Glu',       'GGKP', 'BKS', 'BK'];
   var
    i: Integer;
  begin
    Result := inp;
    for i := 0 to High(SSinp) do if SameText(inp, SSinp[i]) then Exit(SSout[i]);
  end;
begin
  if not Assigned(Script) or not Script.HasAttribute(ScriptAtr) then Exit;
  fs := ChekStr(RootPrefix) +'_' + ChekStr(Script.NodeName) +'_'+ ScriptAtr;
  fn := Format(FUNC_FMT, [fs]);
  if not Fnd() then
   begin
    FLines.Text := FLines.Text + NL + fn + NL + Script.Attributes[ScriptAtr]+ NL + 'end'+NL +NL;
   end;
 //TDebug.Log('TrRoot.NodeName %s, RnRoot.NodeName %s',[GetPathXNode(TrRoot), GetPathXNode(RnRoot)]);
  mtr := '';
  if RnRoot.HasAttribute(AT_METR) then mtr := RnRoot.Attributes[AT_METR];
  FRunScript := FRunScript + [TRunScriptRec.Create(TrRoot, RnRoot, RnPath, fs, AAdr, mtr)];
end;

procedure TXMLLua.InnerAddAll(dev, Mtr: IXMLNode; adr: Integer; const ExePath: string; ExeSc, SetupDev: IXmlScript);
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
     if Assigned(SetupDev) then SetupDev.AddXML(adr, ExePath, TrRoot, n, Script, SETUP, RootPrefix);
     ExeSc.AddXml(adr, ExePath, TrRoot, n, Script, EXEC, RootPrefix);
   end;
   const
    SF = 'SIMPLE_FORMAT';
    MD = 'MODEL';
  begin
    try
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
    else if n.HasAttribute(AT_METR) then
     AddX(mtr, GScript.ChildNodes[SF].ChildNodes[MD].ChildNodes[n.Attributes[AT_METR]], SF);
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end);
end;

procedure TXMLLua.UpdateExecRunSetupMetr(node: IXMLNode; adr: Integer; ExeSc: IXmlScript);
 var
  sd: IXmlScript;
  mtr, dev: IXMLNode;
begin
  if node.HasAttribute(AT_ADDR) then dev := node
  else dev := FindDev(node, adr);
  if not Assigned(dev) then raise ELuaException.CreateFmt('нет устройства в проекте %d', [adr]);
  mtr := dev.ChildNodes.FindNode(T_MTR);
  if not Assigned(mtr) then mtr := dev.AddChild(T_MTR);
  sd := (GContainer as IXMLScriptFactory).Get(nil);
  InnerAddAll(dev, mtr, adr, T_WRK, ExeSc, sd);
  InnerAddAll(dev, mtr, adr, T_RAM, ExeSc, sd);
  InnerAddAll(dev, mtr, adr, T_EEPROM, ExeSc, sd);
  if not sd.Compile then MessageDlg('Ошибка компиляции установок-'+sd.ErrorMsg+':'+sd.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);
  sd.Execute; { TODO 5 -cОШИВКА!!! : ОШИБКА заполняется метрология (если есть) значениями по умолчанию!!!
см todo Устройство из нескольких приб}
  if not ExeSc.Compile then  MessageDlg('Ошибка компиляции выполнения-'+ExeSc.ErrorMsg+':'+ExeSc.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);
end;

procedure TXMLLua.SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);
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
     AddAll(d, T_EEPROM);
    end;
   if ExecSetup then
    begin
//    sd.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'LuaScriptSetup.txt');

     if not sd.Compile then MessageDlg('Ошибка компиляции установок-'+sd.ErrorMsg+':'+sd.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);
     sd.Execute; { TODO 5 -cОШИВКА!!! : ОШИБКА заполняется метрология (если есть) значениями по умолчанию!!!
см todo Устройство из нескольких приб}
     //sd.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'GKScriptSetup.txt');
    end;
//      ExeSc.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'LuaScriptExec.txt');

    if not ExeSc.Compile then
      MessageDlg('Ошибка компиляции выполнения-'+ExeSc.ErrorMsg+':'+ExeSc.ErrorPos+ExeSc.Lines.Text, TMsgDlgType.mtError, [mbOK], 0);

   // node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'PSKafter.xml');

  finally
   if ExecSetup then sd := nil;
  end;
end;

procedure TXMLLua.SetScriptRoot(const Value: IXMLNode);
begin
  GScript := Value;
end;

class function TXMLLua.SetXMLNode(L: lua_State): Integer;
 var
  Node: IXMLNode;
  name: string;
begin
  lua_getfield(L, 1,'__UserData');
  Node := IXMLNode(lua_touserdata(L, -1));
  name := string(lua_tolstring(L, 2, nil));
  case lua_type(L, 3) of
   //LUA_TNIL: Node.Attributes[name] := nil;
   LUA_TBOOLEAN: Node.Attributes[name] := Boolean(lua_toboolean(L, 3));
   LUA_TNUMBER: Node.Attributes[name] := lua_tonumber(L, 3);
   LUA_TSTRING: Node.Attributes[name] := string(lua_tostring(L, 3));
   else raise ELuaException.Createfmt('Error Message %s[%s] %s %d',[node.NodeName,name,string(lua_typename(L, 3)), lua_type(L, 3)]);
  end;
  lua_settop(L, 0);
  Result := 0;
 // writeln(node.NodeName+'[', name+'] := ', Node.Attributes[name])
end;

class function TXMLLua.GetXMLNode(L: lua_State): Integer;
 var
  Node, r: IXMLNode;
  name: string;
  n: Double;
  m: TMarshaller;
begin
  lua_getfield(L, 1,'__UserData');
  Node := IXMLNode(lua_touserdata(L, -1));
  name := string(lua_tolstring(L, 2, nil));
  lua_settop(L, 0);
  if Node.HasAttribute(name) then
   if TryStrToFloat(Node.Attributes[name], n) then lua_pushnumber(L, n)
   else
     lua_pushstring(L, m.AsAnsi(string(Node.Attributes[name])).ToPointer)
  else
   begin
    r := node.ChildNodes.FindNode(name);
    if not Assigned(r) then raise ELuaException.Createfmt('XML Node [%s] не имеет дочерней [%s]',[GetPathXNode(Node), name]);
    PushXmlToTable(L, r);
   end;
  Result := 1;
end;

function TXMLLua.CallFunction(const Name: String; const Params: TArray<Variant>; Nres: Integer = 0): TArray<Variant>;
 var
  v: Variant;
  m: TMarshaller;
  i: Integer;
begin
  CheckFunction(LuaState, Name);
  for v in Params do
   begin
    case TVarData(V).VType of
     varSmallint, varInteger, varCurrency, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64:
        lua_pushinteger(LuaState, lua_Integer(V));
     varSingle, varDouble, varDate:
        lua_pushnumber(LuaState, lua_Number(V));
     varString, varUString, varOleStr:
        lua_pushstring(LuaState, m.AsAnsi(string(V)).ToPointer);
     varNull,varEmpty,varUnknown:
        lua_pushnil(LuaState);
     else if TVarData(V).VType = XMLVariantType then PushXmlToTable(LuaState, TVxmlData(V).Node)
     else raise ELuaException.Createfmt('Тип аргумента %d Вариант не опознан',[TVarData(V).VType]);
    end;
   end;
  if Report(LuaState, DoCall(LuaState, Length(Params), Nres)) <> LUA_OK then
   begin
    raise ELuaException.Create(FLastError);
   end;
  SetLength(Result, Nres);
  for i := 1 to Nres do
  case lua_type(LuaState, -i) of
   LUA_TNIL: Result[i-1] := Null;
   LUA_TBOOLEAN: Result[i-1] := Boolean(lua_toboolean(LuaState, -i));
   LUA_TNUMBER: Result[i-1] := lua_tonumber(LuaState, -i);
   LUA_TSTRING: Result[i-1] := string(lua_tostring(LuaState, -i));
   else raise ELuaException.Createfmt('TXMLLua.CallFunction Error lua_type: [%s]',[string(lua_typename(LuaState, -i))]);
  end;
  lua_pop(LuaState, Nres);
end;

class procedure TXMLLua.CheckFunction(L: lua_State; const FuncName: string);
var
  Marshall: TMarshaller;
begin
  lua_getglobal(L, Marshall.AsAnsi(FuncName).ToPointer); // name of the function
  if not lua_isfunction(L, -1) then
   begin
    lua_pop(L, Lua_GetTop(L));
    raise ELuaException.Createfmt('LUA функция [%s] не найдена',[FuncName]);
   end;
end;

function TXMLLua.PropGetLines: TStrings;
begin
  Result := FLines;
end;

procedure TXMLLua.PropSetLines(const Value: TStrings);
begin
  FLines.Assign(Value);
end;

class procedure TXMLLua.PushXmlToTable(L: lua_State; Node: IXMLNode);
//function __UserToTable(u)
//        local t = {__UserData = u}
//        setmetatable(t, __MetaTable)
//        return t;
//end;
begin
  lua_createtable(L, 0, 1); // push new table +1
  lua_pushlightuserdata(L, Pointer(Node)); //+2
  lua_setfield(L, -2, '__UserData'); // +1 pTable["__UserData"] = XMLNode
  lua_getglobal(L, '__MetaTable');   //+2
  lua_setmetatable(L, -2); // metatable //+1
end;

class function TXMLLua.XNode(L: lua_State; index: Integer): IXMLNode;
begin
  lua_getfield(L, index,'__UserData');
  Result := IXMLNode(lua_touserdata(L, -1));
end;

type
  TLuaScriptFactory = class(TInterfacedObject, IXMLScriptFactory)
  protected
    function GetScriptRoot: IXMLNode;
    function Get(AOwner: TComponent): IXMLScript;
    function ScriptExec(TrrData, Data: IXMLNode; const RootName, Name, Attr: string): Boolean;
  end;

{ TXMLScriptFactory }

function TLuaScriptFactory.Get(AOwner: TComponent): IXMLScript;
begin
  Result := TXMLLua.Create;
end;

function TLuaScriptFactory.GetScriptRoot: IXMLNode;
begin
  Result :=  TXMLLua.GScript;
end;

function TLuaScriptFactory.ScriptExec(TrrData, Data: IXMLNode; const RootName, Name, Attr: string): Boolean;
 var
  sc: TXMLLua;
  scr, scrm: IXMLNode;
begin
  scr := TXMLLua.GScript.ChildNodes.FindNode(RootName);
  if not Assigned(scr) then Exit(False); { TODO : MODEL. or MODELTRR. add to Name }
  if Name <> '' then
   begin
    scrm := GetXNode(scr, 'MODEL.'+ Name);
    if not Assigned(scrm) then scrm := GetXNode(scr, 'TRR_MODEL.'+ Name);
    scr := scrm;
   end;

  if not (Assigned(scr) and scr.HasAttribute(Attr))  then Exit(False);
  sc := TXMLLua.Create;
  try
   sc.AddXML(1,'',TrrData, Data, scr, Attr, RootName);
   Result := sc.Compile;
   if Result then sc.Execute;
  finally
   sc.Free;
  end;
end;

{ TXMLLua.TRunScriptRec }

constructor TXMLLua.TRunScriptRec.Create(TrRoot, RnRoot: IXMLNode; const RnPath, RnFuncName: string; Aadr: Integer; metr: string);
begin
  TrrRoot := TrRoot;
  RunRoot := RnRoot;
  RunPath := RnPath;
  RunFunc := RnFuncName;
  RunAdr := Aadr;
  Self.metr := metr;
end;

initialization
  TRegister.AddType<TLuaScriptFactory, IXMLScriptFactory>.LiveTime(ltTransient);
finalization
  GContainer.RemoveModel<TLuaScriptFactory>;
end.
