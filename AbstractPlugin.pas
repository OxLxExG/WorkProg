unit AbstractPlugin;

interface

//test

uses Windows, SysUtils, PluginAPI, System.Generics.Collections, System.Classes, RootImpl, Vcl.Forms, Winapi.Messages;

type
  TAbstractPlugin = class(TIComponent, IPlugin)
  public
    class function GetModuleVersion(var V: TVersion; Instance: THandle): Boolean; static;
  protected
    // IPlugin
    function GetName: String;
    function GetVersion: TVersion;

    class function GetHInstance: THandle; virtual; abstract;
    class function PluginName: string; virtual; abstract;
  end;

implementation

{ TAbstractPlugin }

class function TAbstractPlugin.GetModuleVersion(var V: TVersion; Instance: THandle): Boolean;
var
    fileInformation: PVSFIXEDFILEINFO;
    verlen: Cardinal;
    rs: TResourceStream;
    m: TMemoryStream;
begin
    Result := False;
    //You said zero, but you mean "us"
    if Instance = 0 then Instance := HInstance;

    m := TMemoryStream.Create;
    try
        rs := TResourceStream.CreateFromID(Instance, 1, RT_VERSION);
        try
            m.CopyFrom(rs, rs.Size);
        finally
            rs.Free;
        end;

        m.Position:=0;
        if not VerQueryValue(m.Memory, '\', (*var*)Pointer(fileInformation), (*var*)verlen) then with V do
        begin
          Major := 0;
          Minor := 0;
          Release := 0;
          Build := 0;
          Exit;
        end;
       with V do
        begin
          Major := fileInformation.dwFileVersionMS shr 16;
          Minor := fileInformation.dwFileVersionMS and $FFFF;
          Release := fileInformation.dwFileVersionLS shr 16;
          Build := fileInformation.dwFileVersionLS and $FFFF;
        end;
    finally
        m.Free;
    end;

    Result := True;
end;

function TAbstractPlugin.GetName: String;
begin
  Result := PluginName;
end;

function TAbstractPlugin.GetVersion: TVersion;
begin
  GetModuleVersion(Result, GetHInstance);
end;

end.
