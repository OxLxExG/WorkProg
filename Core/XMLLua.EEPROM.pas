unit XMLLua.EEPROM;

interface

 {$M+}

uses  XMLLua, VerySimple.Lua.Lib, tools, Container, debug_except, ExtendIntf,
      Winapi.ActiveX, Xml.XMLDoc, Xml.XMLIntf,
      SysUtils, System.UITypes, System.Generics.Collections, System.Classes, math, System.Variants;

type
  TXMLScriptEEPROM = class
  private
    class constructor Create;
    class destructor Destroy;
  public
    class procedure MetrToEep(Eep, Metr: IXMLNode); overload; static;
  published
    class function MetrToEep(L: lua_State): Integer; overload; cdecl; static;
  end;

implementation

{ TXMLScriptEEPROM }

class constructor TXMLScriptEEPROM.Create;
begin
  TXMLLua.RegisterLuaMethods(TXMLScriptEEPROM);
end;

class destructor TXMLScriptEEPROM.Destroy;
begin

end;

class procedure TXMLScriptEEPROM.MetrToEep(Eep, Metr: IXMLNode);
 var
  metrMetr, EeepMetrRoot: IXMLNode;
begin
   for metrMetr in XEnum(Metr) do
    begin
     EeepMetrRoot := ExecXtree(Eep, function(t: IXMLNode): boolean begin Result := t.NodeName = metrMetr.NodeName end);
     if Assigned(EeepMetrRoot) then
      
    end;

  // проходит дочерние Metr находит ноды в Eep заполняет из Metr Eep
end;

class function TXMLScriptEEPROM.MetrToEep(L: lua_State): Integer;
begin
  Result := 0;
end;

end.
