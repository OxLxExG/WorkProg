unit Dev.GLUSonic;

interface

uses System.SysUtils, System.Classes, tools, Xml.XMLIntf,DevPsk, Parser,
     Vcl.Dialogs, Vcl.Graphics, System.UITypes,
     StolGKIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;
 type
  TGluSonic = class;
  TProtocolGluSonic = class(TAbstractProtocol)
   type
    PInnerSP = ^TInnerSP;
    TInnerSP = packed record
      M0, M1, Takt0, Takt1, KU1, KU2: Word;
      function IsSp: Boolean;
    end;
  private
    FWorkLen: integer;
    FGluSonic: TGluSonic;
    FSPIndex: Integer;
    function TestSP(Sender: TAbstractConnectIO): Boolean;
  protected
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
    procedure EventRxChar(Sender: TAbstractConnectIO); override;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $200); override;
  public
    constructor Create(GluSonic: TGluSonic);
  end;

  TGluSonic = class(TAbstractPsk, IDataDevice, INotifyBeforeRemove)
  protected
    procedure Start(AIConnectIO: IConnectIO);
    procedure Stop(AIConnectIO: IConnectIO);
    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false);
    procedure Loaded; override;
    function CanClose: Boolean; override;
    procedure BeforeRemove();
  public
    procedure CheckConnect(); override;
  end;


implementation

{ TProtocolTelesis }

constructor TProtocolGluSonic.Create(GluSonic: TGluSonic);
begin
  FGluSonic := GluSonic;
  FWorkLen := Integer(FindWork(FGluSonic.FMetaDataInfo.Info, 111).Attributes[AT_SIZE]);
end;

procedure TProtocolGluSonic.EventRxChar(Sender: TAbstractConnectIO);
 var
  i: Integer;
  a: TArray<Byte>;
  dl: Integer;
begin
  with Sender do
   begin
    FTimerRxTimeOut.Enabled := False;
    try
     if TestSP(Sender) then
      begin
       try
        SetLength(a, FWorkLen);
        for i := 0 to FWorkLen div 2 - 1 do PSmallInt(@a[i*2])^ := Swap(PSmallInt(@FInput[i*2 + FSPIndex])^);
        if Assigned(FEventReceiveData) then FEventReceiveData(@a[0], FWorkLen);
       finally
        dl := FSPIndex + FWorkLen div 2;
        if FSPIndex <> 16384 then TDebug.Log(FSPIndex.ToString());
        Dec(FICount, dl);
        Move(FInput[dl], FInput[0], dl);
       end;
      end;
    finally
     FTimerRxTimeOut.Enabled := True;
    end;
   end;
end;

procedure TProtocolGluSonic.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  try
   FGluSonic.Stop(Sender as IConnectIO);
  finally
   FGluSonic.Start(Sender as IConnectIO);
  end;
end;

procedure TGluSonic.Start(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) then
   try
    CheckLocked();
    CheckConnect;
    AIConnectIO.ConnectInfo := AIConnectIO.ConnectInfo+ ';800000';
    ConnectOpen;
    ConnectLock;
    ConnectIO.Send(Self, -1, procedure(Data: Pointer; DataSize: integer)
     var
      ip: IProjectData;
      ix: IProjectDataFile;
    begin
      TPars.SetPsk(FWorkEventInfo.Work, Data);
      FWorkEventInfo.DevAdr := FAddressArray[0];
      try
       FExeMetr.Execute(T_WRK);
       if Supports(GlobalCore, IProjectData, ip) then
            ip.SaveLogData(Self as IDevice, FWorkEventInfo.DevAdr, FWorkEventInfo.Work, False)
       else if Supports(GlobalCore, IProjectDataFile, ix) then
            ix.SaveLogData(Self as IDevice, FWorkEventInfo.DevAdr, FWorkEventInfo.Work, Data, DataSize);
      finally
       Notify('S_WorkEventInfo');
      end;
    end, 4000);
    S_Status := dsData;
   except
    on E: Exception do
     begin
      TDebug.DoException(E);
      ConnectIO.FTimerRxTimeOut.Enabled := True;
     end;
   end;
end;

procedure TGluSonic.Stop(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) then
   begin  //дл€ мен€            .. дл€ всех
    ConnectIO.FTimerRxTimeOut.Enabled := False;
    S_Status := dsReady;
    if not IsConnectLocked then ConnectUnLock();
    if AIConnectIO.IsOpen then IConnect.Close;
    AIConnectIO.ConnectInfo := ';';
   end;
end;

{ TProtocolGluSonic.TInnerSP }

function TProtocolGluSonic.TInnerSP.IsSp: Boolean;
begin
  Result :=  (M0 = 0) and (M1 = $FFFF)
         and ((Takt0 and $00FF) = $0080) and ((Takt1 and $00FF) = $0080)
//         and ((KU1 and $F0FF) = 0) and ((KU2 and $F0FF) = 0)
end;

function TProtocolGluSonic.TestSP(Sender: TAbstractConnectIO): Boolean;
 var
  i: Integer;
begin
  Result := False;
  with Sender do for i := 0 to FICount-FWorkLen-1 do if PInnerSP(@FInput[i]).IsSp() then
   begin
    FSPIndex := i;
    Exit(True)
   end;
end;

procedure TProtocolGluSonic.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
begin

end;

{ TGluSonic }

procedure TGluSonic.BeforeRemove;
begin
  inherited;
  try
   Stop(IConnect);
  except
   on E: Exception do TDebug.DoException(E);
  end;
end;

function TGluSonic.CanClose: Boolean;
begin
  Result := True;
  try
   Stop(IConnect);
   // ессли произошла перезагрузка экрана то через 10 сек вкл прибор
   ConnectIO.FTimerRxTimeOut.Enabled := True;
  except
   on E: Exception do TDebug.DoException(E);
  end;
end;

procedure TGluSonic.CheckConnect;
begin
  if not Assigned(IConnect) then raise EDeviceException.Create(RS_NoConnect);
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolGluSonic) then
   begin
    ConnectIO.FProtocol := TProtocolGluSonic.Create(Self);
   end;
end;

procedure TGluSonic.Loaded;
begin
  inherited;
  FWorkEventInfo.Work := FindWork(FMetaDataInfo.Info, FAddressArray[0]);
  FWorkEventInfo.DevAdr := FAddressArray[0];
  Start(IConnect);
end;

procedure TGluSonic.ReadWork(ev: TWorkEvent; StdOnly: Boolean);
begin
  raise EBaseException.Create('ReadWork неподдерживаетс€');
end;

initialization
  RegisterClass(TGluSonic);
  TRegister.AddType<TGluSonic, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TGluSonic>;
end.
