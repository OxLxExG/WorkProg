unit WlanConn;

interface

uses winapi.Windows, System.SysUtils, System.Classes, System.SyncObjs, NetConn, WlanClass,
     AbstractDev, IdTCPClient, IdGlobal, RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;

type
  // Реализация для Wifi
  EWlanConnectIOException = class(ENetConnectIOException);

  TWlanConnectIO = class(TNetConnectIO, IWlanConnectIO)
  protected
    Fwifi: TWlanConnection;
    procedure Open; override;
    procedure Close; override;
    class function ExtractHost(const Info: string): string; override;
    class function ExtractPort(const Info: string): Word; override;
    class function ExtractSSID(const Info: string): string; virtual;
    class function ExtractPassw(const Info: string): string; virtual;
  public
    constructor Create(); override;
    destructor Destroy; override;
  end;


implementation

uses nduWlanAPI, nduWlanTypes, nduL2cmn;

{ TWlanConnectIO }

constructor TWlanConnectIO.Create;
begin
  inherited;
  FConnectInfo := 'AMKGorizontWiFiUSO 192.168.43.5:5000';
  Fwifi := TWlanConnection.Create;
end;

destructor TWlanConnectIO.Destroy;
begin
  Fwifi.Free;
  inherited;
end;

class function TWlanConnectIO.ExtractHost(const Info: string): string;
 var
  a: TArray<string>;
begin
  Result := '192.168.43.5';
  a := Info.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) = 0 then Exit;
  if Length(a) >= 2 then Result := inherited ExtractHost(a[1])
end;

class function TWlanConnectIO.ExtractPassw(const Info: string): string;
begin

end;

class function TWlanConnectIO.ExtractPort(const Info: string): Word;
 var
  a: TArray<string>;
begin
  Result := 5000;
  a := Info.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) = 0 then Exit;
  if Length(a) >= 2 then Result := inherited ExtractPort(a[1])
end;

class function TWlanConnectIO.ExtractSSID(const Info: string): string;
 var
  a: TArray<string>;
begin
  a := Info.Split([' ']);
  if Length(a) = 0 then Exit('AMKGorizontWiFiUSO');
  Result := a[0];
end;

procedure TWlanConnectIO.Close;
begin
  inherited;
  Fwifi.DisConnect(Fwifi.DefaultInterfaceID);
end;

procedure TWlanConnectIO.Open;
begin
  try
   Fwifi.Connect(Fwifi.DefaultInterfaceID, ExtractSSID(FConnectInfo), '0407112014');
   inherited Open;
  except
   S_Status := S_Status + [iosError];
   raise
  end;
end;

initialization
  RegisterClass(TWlanConnectIO);
  TRegister.AddType<TWlanConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TWlanConnectIO>;
end.


//65 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
//00 00 00 00 00 00 00 34 54
