unit DevBurLowLevel;

interface

uses  tools, System.IOUtils, RootIntf, ProtocolBurUnit,
  Winapi.Windows, System.SysUtils, System.Classes, CPort, CRC16, Vcl.ExtCtrls, System.Variants, Xml.XMLIntf, Xml.XMLDoc,
  Generics.Collections,  Vcl.Forms, Vcl.Dialogs,Vcl.Controls, Actns,
  DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;


type

 TDeviceBurLow = class(TDevice, IDevice, ILowLevelDeviceIO)
  private
    function GetSerialQe: TProtocolBur;
 public
   procedure CheckConnect(); override;
   procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
   property SerialQe: TProtocolBur read GetSerialQe;
 end;

implementation

{ TDeviceBur }

procedure TDeviceBurLow.CheckConnect;
begin
  inherited CheckConnect;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolBur) then
   begin
    ConnectIO.FProtocol := TProtocolBur.Create;
   end;
end;

function TDeviceBurLow.GetSerialQe: TProtocolBur;
begin
  Result := TProtocolBur(ConnectIO.FProtocol);
end;

procedure TDeviceBurLow.SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
begin
  CheckConnect;  //низkоуровневая функция без особых проверок
  CheckLocked;
  ConnectOpen();
  try
   SerialQe.Add(procedure(qe: integer)
   begin
     inherited;
   end);
  except
   SerialQe.Clear;
   raise;
  end;
end;

initialization
  RegisterClass(TDeviceBurLow);
  TRegister.AddType<TDeviceBurLow, IDevice>.LiveTime(ltSingletonNamed)
finalization
  GContainer.RemoveModel<TDeviceBurLow>;
end.
