unit MicroSDConn;

interface

uses System.SysUtils, System.Classes,
     AbstractDev, RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;

type
  EMicroSDConnectIOException = class(EConnectIOException);
  TMicroSDConnectIO = class(TAbstractConnectIO, ImicroSDConnectIO)
  protected
    procedure Open; override;
    procedure Close; override;
  public
    procedure Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
    class function Enum: TArray<string>; override;
  end;


implementation

{ TMicroSDConnectIO }

procedure TMicroSDConnectIO.Close;
begin
  inherited;

end;

class function TMicroSDConnectIO.Enum: TArray<string>;
begin
  Result := ['A:', 'B:', 'C:'];
end;

procedure TMicroSDConnectIO.Open;
begin
  inherited;

end;

procedure TMicroSDConnectIO.Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
 var
  b: array[0..$200]of Byte;
  a: AnsiString;
begin
  if Assigned(FProtocol) then
   begin
    if not Assigned(Data) then raise EMicroSDConnectIOException.Create('Data not initialized');
    FEventReceiveData := Event;
    if WaitTime >= 0 then FTimerRxTimeOut.Interval := WaitTime
    else FTimerRxTimeOut.Interval := FComWait;
    Move(Data^,b[0], Cnt);
    FProtocol.TxChar(Self, @b[0], Cnt);
    FTimerRxTimeOut.Enabled := True;
    CheckOpen;
    //if Cnt > 0 then FCom.Write(b[0], cnt);
//    if Assigned(FIOEventString) then
//     begin
//      SetString(a, PAnsiChar(@b[0]), cnt);
//      FIOEventString(iosTx, string(a));
//     end
//    else
    if Assigned(FIOEvent) then FIOEvent(iosTx, @b[0], cnt);
   end
  else raise EMicroSDConnectIOException.Create(RS_SendData);
end;

initialization
  RegisterClass(TMicroSDConnectIO);
  TRegister.AddType<TMicroSDConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TMicroSDConnectIO>;
end.
