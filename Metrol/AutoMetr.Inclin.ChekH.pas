unit AutoMetr.Inclin.ChekH;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Vcl.ExtCtrls,
  System.Types, Vcl.Dialogs, System.JSON, IdUDPServer,IdGlobal, IdSocketHandle,
  ExtendIntf, MetrForm,
  Xml.XMLIntf, RootIntf, RootImpl, UakiIntf, Container, DeviceIntf, debug_except,
  tools;

type

  TRemoteData = record
   X,Y,Z: Double;
   FlagError: Boolean;
  end;
  TevTypes=record
   Err,EndErr,Update: TProc<TObject>;
  end;
  TEvents = TDictionary<TObject,TevTypes>;

  TChekH = class
  private
    FErrorFlag: Boolean;
    FWaitFlag: Boolean;
    FUDPServer: TIdUDPServer;
    FEvents: TEvents;
    FCurrentError: Double;
    FRemoteData: TRemoteData;
    FUdpTinoutTimer: TTimer;
    FWaitTimer: TTimer;
    FWireReady: Boolean;
    procedure OnUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OnUdpTimout(Senser: TObject);
    procedure OnWaitTime(Senser: TObject);
    procedure CalcData;
    function CheckError: Boolean;
    procedure SetWaitFlag(const Value: Boolean);
    procedure ResetUdpTinoutTimer();
    procedure ResetWaitTimer;
    property WaitFlag: Boolean read FWaitFlag write SetWaitFlag;
  public
    constructor Create();
    destructor Destroy; override;
    procedure Bind(owner: TObject; events: TevTypes);
    procedure UnBind(owner: TObject);
    property WireReady: Boolean read FWireReady;
    property ErrorFlag: Boolean read FErrorFlag;
    property CurrentError: Double read FCurrentError;
    property CurrenData: TRemoteData read FRemoteData;
  end;

  var
    GChekH: TChekH = nil;


implementation

{ TChekH }

constructor TChekH.Create;
begin
  FEvents := TEvents.Create;
  FUDPServer := TIdUDPServer.Create;
  FUDPServer.DefaultPort := 12345;
  FUDPServer.OnUDPRead := OnUDPRead;
  FUdpTinoutTimer := TTimer.Create(nil);
  FWaitTimer := TTimer.Create(nil);
  FWaitTimer.Enabled := False;
  FWaitTimer.OnTimer := OnWaitTime;
  ResetUdpTinoutTimer;
  FUdpTinoutTimer.OnTimer := OnUdpTimout;
//  FUDPServer.Active := True;
end;

destructor TChekH.Destroy;
begin
  FUDPServer.Active := False;
  FUdpTinoutTimer.Free;
  FWaitTimer.Free;
  FEvents.Free;
  inherited;
end;

procedure TChekH.OnUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
 var
  FJson: TJSONObject;

begin
  ResetUdpTinoutTimer;
  FWireReady := True;
  var sd := BytesToString(AData);
//  try
    FJson := TJSONValue.ParseJSONValue(Sd, False {UseBool}, True {RaiseException}) as TJSONObject;
    try
      FRemoteData.X := FJson.FindValue('X').AsType<string>.ToDouble;
      FRemoteData.Y := FJson.FindValue('Y').AsType<string>.ToDouble;
      FRemoteData.Z := FJson.FindValue('Z').AsType<string>.ToDouble;
      var s := FJson.FindValue('Flag').AsType<string>;
      FRemoteData.FlagError := s = '1';
    finally
      FJson.Free;
    end;
  //except
//    on E: EJSONException do
//      Writeln( E.Message );
 // end;
  for var e in FEvents.Values do if Assigned(e.Update) then e.Update(self);
  CalcData;
  if not FWaitFlag then
   begin
    if CheckError then
     begin
      if not FErrorFlag then
       begin
         FErrorFlag := True;
         WaitFlag := True;
         for var e in FEvents.Values do if Assigned(e.Err) then e.Err(self);
       end;
     end
    else
     begin
      if FErrorFlag then
       begin
         FErrorFlag := False;
         for var e in FEvents.Values do if Assigned(e.EndErr) then e.EndErr(self);
       end;
     end;
   end;
end;

procedure TChekH.Bind(owner: TObject; events: TevTypes);
begin
   FEvents.AddOrSetValue(owner, events);
   FUDPServer.Active := True;
   ResetUdpTinoutTimer;
end;

function TChekH.CheckError: Boolean;
begin
  Result := FRemoteData.FlagError;
  if Result then ResetWaitTimer;
end;

procedure TChekH.OnUdpTimout(Senser: TObject);
begin
  FWireReady := False;
//  if Length(FOnUpdate)>0 then for var e in FOnUpdate do e(self);
end;

procedure TChekH.ResetUdpTinoutTimer;
begin
  FUdpTinoutTimer.Enabled := False;
  FUdpTinoutTimer.Interval := 60_000;
  if FUDPServer.Active then FUdpTinoutTimer.Enabled := True;
end;

procedure TChekH.SetWaitFlag(const Value: Boolean);
begin
  FWaitFlag := Value;
  if FWaitFlag then ResetWaitTimer;
end;

procedure TChekH.UnBind(Owner: TObject);
begin
 if FEvents.ContainsKey(owner) then FEvents.Remove(owner);
 if FEvents.Count = 0 then
  begin
    FUDPServer.Active := False;
    ResetUdpTinoutTimer;
  end;
end;

procedure TChekH.ResetWaitTimer;
begin
  FWaitTimer.Enabled := false;
  FWaitTimer.Interval := 120_000;// //2047*8
  FWaitTimer.Enabled := True;
end;

procedure TChekH.OnWaitTime(Senser: TObject);
begin
  FWaitTimer.Enabled := False;
  FWaitFlag := False;
end;

procedure TChekH.CalcData;
begin

end;

initialization
  GChekH := TChekH.Create;
finalization
  FreeAndNil(GChekH);
end.

