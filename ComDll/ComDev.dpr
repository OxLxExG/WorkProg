// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library ComDev;

{$INCLUDE global.inc}

uses
  System.TypInfo,
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Xml.XMLIntf,
  DeviceIntf,
  UakiIntf,
  StolGKIntf,
  StolBKIntf,
  System.Generics.Collections,
  PluginAPI,
  AbstractPlugin,
  tools,
  Container,
  AbstractDev in 'AbstractDev.pas',
  DevPsk in 'DevPsk.pas',
  DevBur in 'DevBur.pas',
  RestConn in 'RestConn.pas',
  WlanConn in 'WlanConn.pas',
  UDPBinConn in 'UDPBinConn.pas',
  DevUaki in 'DevUaki.pas',
  Dev.Telesistem in 'Dev.Telesistem.pas',
  SubDevImpl in 'SubDevImpl.pas',
  Dev.Telesistem.Decoder in 'Dev.Telesistem.Decoder.pas',
  Dev.StolGK in 'Dev.StolGK.pas',
  Dev.Telesistem.Shum in 'Dev.Telesistem.Shum.pas',
  Dev.Telesistem.Data in 'Dev.Telesistem.Data.pas',
  DevUaki2 in 'DevUaki2.pas',
  Dev.GLUSonic in 'Dev.GLUSonic.pas',
  Dev.BK in 'Dev.BK.pas',
  Dev.TelesisRetr2 in 'Dev.TelesisRetr2.pas',
  MicroSDConn in 'MicroSDConn.pas',
  NetConn in 'NetConn.pas',
  DevHorizontM in 'DevHorizontM.pas',
  DevBurLowLevel in 'DevBurLowLevel.pas',
  UDPConn in 'UDPConn.pas',
  DevUakiCom in 'DevUakiCom.pas',
  DevUakiNet in 'DevUakiNet.pas',
  ProtocolBurUnit in 'ProtocolBurUnit.pas',
  Dev.Bur.pipe in 'Dev.Bur.pipe.pas';

{$R *.res}
resourcestring
  RS_COM_connection = 'Соединение по Ком Порту';
  RS_UDP_connection='Соединение по UDP';
  RS_HTTP_connection='Соединение по HTTP';
  RS_UT_connection='Соединение по UDP (текстовое UAKI)';
  RS_WF_connection= 'Соединение по WiFi';
  RS_ETH_connection='Соединение по Ethernet';
  RS_Eadr='Устройство с адресом >250 может быть только одно';
  RS_BADadr='Устройство с неверным адресом';

type
 TComDevPlugin = class(TAbstractPlugin, IGetDevice, IGetConnectIO)
 protected
   function  Device(const Addrs: TAddressArray; const DeviceName, ModulesNames: string): IDevice;
   procedure EnmDevices(GetDevicesCB: TGetDevicesCB);
   procedure IGetDevice.Enum = EnmDevices;
   procedure IGetConnectIO.Enum = EnumConnect;
   procedure EnumConnect(GetConnectIOCB: TGetConnectIOCB);
   function  ConnectIO(ConnectID: Integer): IConnectIO;

   function IsManualCreate(ConnectID: Integer): Boolean;
   function GetConnectInfo(ConnectID: Integer): TArray<string>;

   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
   destructor Destroy; override;
 end;

{ TComDevPlugin }

procedure TComDevPlugin.EnumConnect(GetConnectIOCB: TGetConnectIOCB);
begin
  GetConnectIOCB(1, 'ComPort', RS_COM_connection);
  {$IFNDEF ENG_VERSION}
  GetConnectIOCB(2, 'NetPort', RS_ETH_connection);
  GetConnectIOCB(3, 'WlanPort',RS_WF_connection);
  GetConnectIOCB(4, 'UDP', RS_UT_connection);
  GetConnectIOCB(5, 'Rest', RS_HTTP_connection);
  {$ENDIF}
  GetConnectIOCB(6, 'UDPPort', RS_UDP_connection);
 // GetConnectIOCB(5, 'MicroSD', 'Чтение памяти с SD карты');
end;

function TComDevPlugin.ConnectIO(ConnectID: Integer): IConnectIO;
begin
  case ConnectID of
  {$IFNDEF ENG_VERSION}
   2:  Result := TNetConnectIO.Create();
   3:  Result := TWlanConnectIO.Create();
   4:  Result := TUDPConnectIO.Create();
   5:  Result := TRestConnectIO.Create();
  {$ENDIF}
   6:  Result := TUDPBinConnectIO.Create();
 //  5:  Result := TMicroSDConnectIO.Create();
  else Result := TComConnectIO.Create();
  end;
end;

procedure TComDevPlugin.EnmDevices(GetDevicesCB: TGetDevicesCB);
begin
  EnumDevices(GetDevicesCB);
end;

function TComDevPlugin.GetConnectInfo(ConnectID: Integer): TArray<string>;
begin
  case ConnectID of
  {$IFNDEF ENG_VERSION}
   2:  Result := TNetConnectIO.Enum();
   3:  Result := TWlanConnectIO.Enum();
   4:  Result := TUDPConnectIO.Enum();
   5:  Result := TRestConnectIO.Enum();
  {$ENDIF}
   6:  Result := TUDPBinConnectIO.Enum();
  else Result := TComConnectIO.Enum();
  end;
end;

function TComDevPlugin.IsManualCreate(ConnectID: Integer): Boolean;
begin
  Result := ConnectID in [2,3,4,5,6];
end;

class function TComDevPlugin.GetHInstance: THandle;
begin
  Result := HInstance;
end;

class function TComDevPlugin.PluginName: string;
begin
  Result := 'Устройства Ввода-Выода и Приборы';
end;

destructor TComDevPlugin.Destroy;
begin
  OutputDebugString(PChar('ComDevPlugin.Destroy '));
  inherited;
end;

function TComDevPlugin.Device(const Addrs: TAddressArray; const DeviceName, ModulesNames: string): IDevice;
 var
  a: Integer;
  adr: TAddressArray;
begin
  Result := nil;
  adr := Addrs;
  TArray.Sort<Integer>(adr);
  if Length(Adr) > 1 then for a in Adr do if A > 250 then raise EDeviceException.Create(RS_Eadr);
  if Length(Adr) >= 1 then
   begin
    if Adr[0] = $FFFF then Result := TDeviceBurLow.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = 1100 then Result := TUso.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = 1101 then Result := TGlu.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_UAKI then Result := TDevUaki.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_UAKI_COM then Result := TDevUakiCom.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_UAKI_NET then Result := TDevUakiNet.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_UAKI2 then Result := TDevUaki2.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_STOL_GK then Result := TStolGK.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = ADR_PULT_BK then Result := TDevPultBK.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if Adr[0] = 1111 then Result := TGluSonic.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (Adr[0] > 1101) and (adr[0] < 1200) then  Result := TPskStd.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (Adr[0] > 1200) and (adr[0] < 1300) then  Result := TDeviceHM.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (adr[0] = 1000) then Result := TTelesistem.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (adr[0] = 1001) then Result := TTelesisRetr.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (adr[0] = 1002) then Result := TTelesis1ware.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
    else if (adr[0] > 250) then raise EDeviceException.Create(RS_BADadr)

    else Result := TDeviceBur.CreateWithAddr(Adr, DeviceName, ModulesNames) as IDevice
   end
//  else Result := TViewRamDevice.CreateWithAddr(nil, Adr);
end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<TComDevPlugin, IPlugin, IGetDevice, IGetConnectIO>.LiveTime(ltSingleton);
  Result := TypeInfo(TComDevPlugin);
end;

procedure Done;
begin
  GContainer.RemoveModel<TComDevPlugin>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

begin
end.
