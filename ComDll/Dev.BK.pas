unit Dev.BK;

interface

uses System.SysUtils, System.Classes, tools, Xml.XMLIntf, StolBKIntf, ProtocolBurUnit,
     Vcl.Dialogs, Vcl.Graphics, System.UITypes,
     DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

type
  TDevPultBK = class(TDevice, IDevice, ILowLevelDeviceIO, IPultBK)
  private
   type
    TSendData = packed record
     cmd: Byte;
     BitPorts: Word;
    end;
  protected
   procedure Command(Data: Word; Res: TPultRes);
  public
    constructor Create(); override;
    procedure CheckConnect; override;
  end;

implementation

procedure TDevPultBK.CheckConnect;
begin
  inherited;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolBur) then
   begin
    ConnectIO.FProtocol := TProtocolBur.Create;
   end;
end;

procedure TDevPultBK.Command(Data: Word; Res: TPultRes);
 var
  d: TSendData;
begin
  CheckConnect;
  CheckLocked;
  ConnectOpen;
  d.cmd := 1;
  d.BitPorts := Data;
  SendROW(@d, SizeOf(d), procedure(Data: Pointer; DataSize: integer)
  begin
    if Assigned(Res) then Res((DataSize = SizeOf(d)) and (TSendData(Data^).BitPorts = d.BitPorts));
    ConnectClose;
  end);
end;

constructor TDevPultBK.Create;
begin
  inherited;
  FDName := 'PULT_BK';
  FStatus := dsReady;
end;

initialization
  RegisterClass(TDevPultBK);
  TRegister.AddType<TDevPultBK, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TDevPultBK>;
end.
