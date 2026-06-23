unit Dev.StolGK;

interface

uses System.SysUtils, System.Classes, tools, Xml.XMLIntf,
     Vcl.Dialogs, Vcl.Graphics, System.UITypes,
     StolGKIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

type
  TScenaData = record
    cmd: AnsiString;
    Wait2: Integer;
    constructor Init(ACmd: AnsiString; AWait2: Integer);
  end;

  EStolGKException = class(EBaseException);
  TReceiveStrRef = reference to procedure(Data: AnsiString);
  TStolGK = class(TDevice, IDevice, IStolGK)
  private
    FRunCmd: AnsiString;
    FRunRes: TStolRes;
    FStatusStol: TStatusStol;
    FPosition: Integer;
    XMLCommand: IXMLNode;
    FScenna: Tarray<TScenaData>;
    FS_Actuator: Boolean;
    procedure StartComm;
    procedure StopComm;
    procedure DoEvent(ev: TStolRes; es: TEventStol; const Errinfo: AnsiString); inline;
    procedure ScennaBegin();
    procedure Add(const Cmd: AnsiString; WaitTime2: Integer = 0);
    procedure ScennaRun(Event: TStolRes; SetPos: Boolean; Position: integer);
    procedure SetPosition(const Value: Integer);
    procedure SetS_Actuator(const Value: Boolean);
    procedure SetStatusStol(const Value: TStatusStol);
  protected
    function Commands: TArray<string>;
    procedure Stop(Res: TStolRes);
    procedure Run(const Cmd: string; Res: TStolRes);
    procedure Actuator(Open: Boolean; Res: TStolRes);

    function GetPosition: Integer;
    function GetStatusStol: TStatusStol;

    procedure SetConnect(AIConnectIO: IConnectIO); override;

    procedure Send(const Cmd: AnsiString; Event: TStolRes; WaitTime1: Integer = -1); overload;
    procedure Send(const Cmd: AnsiString; WaitTime1, WaitTime2: Integer;  Event: TStolRes); overload;
  public
    constructor Create(); override;
    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); override;
//    destructor Destroy; override;
    procedure CheckConnect(); override;
    property S_Actuator: Boolean read FS_Actuator write SetS_Actuator;
    property S_Position: Integer read FPosition write SetPosition;
    property S_StatusStol: TStatusStol read FStatusStol write SetStatusStol;
  end;


implementation

{ TScenaData }

constructor TScenaData.Init(ACmd: AnsiString; AWait2: Integer);
begin
  cmd := ACmd;
  Wait2 := AWait2;
end;

{ TStolGK }

constructor TStolGK.Create;
 var
  LDoc: IXMLDocument;
begin
  inherited;
  LDoc := NewXDocument();
  LDoc.LoadFromFile(ExtractFilePath(ParamStr(0))+'Devices\StolGkCommands.xml');
  XMLCommand := LDoc.DocumentElement;
  FDName := 'STOL_GK';
  FStatus := dsReady;
    ///
//    S_StatusStol := FStatusStol + [ssSync];
//    S_Position := 979;
    ///
end;

constructor TStolGK.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  inherited;
  TRegister.AddType<TStolGK>.AddInstance(Name, Self as IInterface);
end;

procedure TStolGK.DoEvent(ev: TStolRes; es: TEventStol; const Errinfo: AnsiString);
begin
  if Assigned(ev) then ev(es, Errinfo);
end;

function TStolGK.Commands: TArray<string>;
 var
  i: Integer;
begin
  SetLength(Result, XMLCommand.ChildNodes.Count);
  for i := 0 to XMLCommand.ChildNodes.Count-1 do Result[i] :=  XMLCommand.ChildNodes[i].NodeName;
end;

function TStolGK.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TStolGK.GetStatusStol: TStatusStol;
begin
  Result := FStatusStol;
end;


procedure TStolGK.SetConnect(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) and not Supports(AIConnectIO, IComPortConnectIO) then
    raise EConnectIOException.CreateFmt('%s не COM соединение. Возможно только COM соединение!',[AIConnectIO.ConnectInfo]);
  inherited;
end;

procedure TStolGK.SetPosition(const Value: Integer);
begin
  if FPosition <> Value then
   begin
    FPosition := Value;
    Notify('S_Position');
   end;
end;

procedure TStolGK.SetStatusStol(const Value: TStatusStol);
begin
  if FStatusStol <> Value then
   begin
    FStatusStol := Value;
    Notify('S_StatusStol');
   end;
end;

procedure TStolGK.SetS_Actuator(const Value: Boolean);
begin
  if FS_Actuator <> Value then
   begin
    FS_Actuator := Value;
    Notify('S_Actuator');
   end;
end;

procedure TStolGK.Actuator(Open: Boolean; Res: TStolRes);
  var
   s: AnsiString;
begin
  if ssRun in FStatusStol then raise EStolGKException.CreateFmt('Идет выполнение комады %s',[string(FRunCmd)]);
  if Open then s := 'SF4*' else  s := 'CF4*';
  StartComm;
  Send(s, procedure (es: TEventStol; const ans: AnsiString)
  begin
    if es = esTerminateCmd then DoEvent(Res, es, ans)
    else
     begin
      StopComm;
      if (es = esEndCmd) and (Ans <> s+'E10*') then DoEvent(Res, esErrCmd, s)
      else
       begin
        DoEvent(Res, es, ans);
        S_Actuator := Open;
       end;
     end
  end);
end;

procedure TStolGK.ScennaBegin;
begin
  SetLength(FScenna, 0);
end;

procedure TStolGK.Add(const Cmd: AnsiString; WaitTime2: Integer);
begin
  CArray.Add<TScenaData>(FScenna, TScenaData.Init(Cmd, WaitTime2));
end;

procedure TStolGK.ScennaRun(Event: TStolRes; SetPos: Boolean; Position: integer);
 var
  recur: TStolRes;
  i: Integer;
begin
  if Length(FScenna) = 0 then
   begin
    DoEvent(Event, esEndCmd, 'Нет задания');
    Exit;
   end;
  recur := procedure (e: TEventStol; const s: AnsiString)
   var
    st: AnsiString;
  begin
    if i >= 0 then with FScenna[i] do
     case e of
      esEndCmd:
       begin
        // actuator binding
        if s = 'CF4*E10*' then S_Actuator := False
        else if s = 'SF4*E10*' then S_Actuator := True;

        if Wait2 = 0 then st := cmd + 'E10*' else st := 'E14*';
        if s <> st then
         begin
          if Wait2 <> 0 then S_StatusStol := FStatusStol - [ssSync];
          StopComm;
          DoEvent(Event, esErrCmd, cmd + '|' + s);
          Exit;
         end
        else if i = Length(FScenna)-1 then
         begin
          if SetPos then
           begin
            S_Position := Position;
            S_StatusStol := FStatusStol + [ssSync];
           end;
          StopComm;
          DoEvent(Event, esEndCmd, cmd + '|' + s);
          Exit;
         end
       end;
      esTerminateCmd, esWait:
       begin
        DoEvent(Event, e, cmd + '|' + s);
        Exit;
       end;
      esErrCmd, esTimeOut:
       begin
        if Wait2 <> 0 then S_StatusStol := FStatusStol - [ssSync];
        StopComm;
        DoEvent(Event, e, cmd + '|' + s);
        Exit;
       end;
     end;
    inc(i);
    S_StatusStol := FStatusStol - [ssRun];
    if FScenna[i].Wait2 = 0 then Send(FScenna[i].cmd, recur, 300)
    else Send(FScenna[i].cmd, 300, FScenna[i].Wait2, recur);
  end;
  i := -1;
  StartComm;
  recur(esEndCmd, '');
end;

procedure TStolGK.CheckConnect;
begin
  inherited;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolPsk) then
   begin
    ConnectIO.FProtocol := TProtocolPsk.Create;
   end;
end;

procedure TStolGK.StartComm;
begin
  CheckConnect;
  CheckLocked;
  if not IConnect.IsOpen() then
   begin
    var s := IConnect.ConnectInfo;
    if not s.Contains(';9600;2') then
      IConnect.ConnectInfo := IConnect.ConnectInfo+ ';9600;2';
   end;
  ConnectOpen();
  ConnectLock;
  TComConnectIO(ConnectIO).AsString := True;
end;

procedure TStolGK.StopComm;
begin
  S_StatusStol := FStatusStol - [ssRun];
  ConnectUnLock;
  ConnectClose();
  //IConnect.ConnectInfo := IConnect.ConnectInfo+ ';;';
end;

procedure TStolGK.Send(const Cmd: AnsiString; Event: TStolRes; WaitTime1: Integer = -1);
 var
  e: TReceiveDataRef;
begin
  e := procedure(p: Pointer; n: integer)
   var
    a: AnsiString;
  begin
    if n = -1 then DoEvent(Event, esTimeOut, '')
    else if n >= (Length(Cmd)+4) then
     begin
      SetString(a, PAnsiChar(p), n);
      DoEvent(Event, esEndCmd, a);
     end
    else
     begin
      ConnectIO.FTimerRxTimeOut.Enabled := True;
      ConnectIO.FEventReceiveData := e;
     end
  end;
  ConnectIO.FICount := 0;
  if ssRun in FStatusStol then
   begin
    S_StatusStol := FStatusStol - [ssSync];
    DoEvent(FRunRes, esTerminateCmd, FRunCmd);
   end;
  S_StatusStol := FStatusStol + [ssRun];
  FRunCmd := Cmd;
  ConnectIO.Send(@Cmd[1], Length(Cmd), e, WaitTime1);
end;

procedure TStolGK.Send(const Cmd: AnsiString; WaitTime1, WaitTime2: Integer;  Event: TStolRes);
begin
  Send(Cmd, procedure(ev: TEventStol; const Data: AnsiString)
   var
    e: TReceiveDataRef;
  begin
    if  ev = esEndCmd then
     if Cmd+'E10*' = Data then
       try
        DoEvent(Event, esWait, Data)
       finally
        //(ConnectIO as IdebugIO).IOEventString(iosTimeOut, '===ev===');
        ConnectIO.FTimerRxTimeOut.Enabled := False;
        ConnectIO.FTimerRxTimeOut.Interval := WaitTime2;
        ConnectIO.FICount := 0;
        e := procedure(p: Pointer; n: integer)
         var
          a: AnsiString;
        begin
          if n = -1 then DoEvent(Event, esTimeOut, '')
          else if n >= 4 then
           begin
            ConnectIO.FTimerRxTimeOut.Enabled := False;
            SetString(a, PAnsiChar(p), n);
            DoEvent(Event, esEndCmd, a)
           end
          else ConnectIO.FEventReceiveData := e;
        end;
        ConnectIO.FEventReceiveData := e;
        ConnectIO.FTimerRxTimeOut.Enabled := True;
       end
     else DoEvent(Event, esErrCmd, Data)
    else DoEvent(Event, ev, Data)
  end, WaitTime1);
end;


procedure TStolGK.Stop(Res: TStolRes);
 var
  rp: TStolRes;
begin
  StartComm;
  rp := procedure(e: TEventStol; const s: AnsiString)
  begin
    StopComm;
    if Assigned(Res) then Res(e, s);
  end;
  Send('ST*', 500, 500, procedure(e: TEventStol; const s: AnsiString)
  begin
    if esEndCmd = e then
     if s = 'E14*' then rp(e, s)
     else rp(esErrCmd, s)
    else
     begin
      if Assigned(Res) then Res(e, s);
      if e in [esErrCmd, esTimeOut] then
       begin
        S_StatusStol := FStatusStol - [ssRun];
        Send('ST*', 500, 500, rp);
       end
     end;
  end);
end;


procedure TStolGK.Run(const Cmd: string; Res: TStolRes);
   const
    C_DIR: array [0..3] of AnsiString = ('DR*','DL*','DL*','DL*');
    C_CMD: array [0..3] of AnsiString = ('HM*','ML1*','ML2*','ML3*');

  procedure MoveInf(UserCmdInd: Integer; Delay: Integer = 3*60000);
  begin
    Add('LB*');
    Add('BG*');
    Add(AnsiString(Format('SD%s*',[XMLCommand.Attributes['MaxSpeed']])));
    Add(AnsiString(Format('SS%s*',[XMLCommand.Attributes['MinSpeed']])));
    Add(AnsiString(Format('AL%s*',[XMLCommand.Attributes['AccellAmp']])));
    Add(C_DIR[UserCmdInd]);
    Add('EN*');
    Add(C_CMD[UserCmdInd]);
    Add('DS*');
    Add('ED*');
    Add('SB1*', Delay);
  end;

  procedure MoveN(n: Integer; UserCmdInd: Integer = -1);
   var
    S, S1, STvmax: Integer;
    V0, V, a: Integer;
    Tvmax, TAll: Double;
  begin
    V0 := XMLCommand.Attributes['MinSpeed'];
    V := XMLCommand.Attributes['MaxSpeed'];
    a := XMLCommand.Attributes['AccellAmp'];
    S := Abs(n)*200/5/XMLCommand.Attributes['DeltaStep'];

    if S = 0 then Exit;
    
    Tvmax := (V - V0)/a;
    STvmax := Round(V0*Tvmax + a*Tvmax*Tvmax/2);

    if S >= STvmax*2 then
     begin
      S1 := S - STvmax;
      TAll := Tvmax*2 + (S - 2*STvmax)/V;
     end
    else
     begin
      S1 := S div 2;
      TAll := (Sqrt(V0*V0 + 4*a/2*S/2)-V0)/a*2;
     end;

    Add('LB*');
    Add('BG*');

    if UserCmdInd >= 0 then Add(C_DIR[UserCmdInd])
    else if n < 0 then Add('DL*') else Add('DR*');

    Add(AnsiString(Format('AL%d*',[a])));
    Add(AnsiString(Format('SS%d*',[V0])));
    Add(AnsiString(Format('SD%d*',[V])));
    Add('EN*');
    Add(AnsiString(Format('MV%d*',[S1])));

    Add(AnsiString(Format('AL%d*',[-a])));
    Add(AnsiString(Format('SD%d*',[V0])));

    if UserCmdInd >= 0 then Add(C_CMD[UserCmdInd])
    else Add(AnsiString(Format('MV%d*',[S - S1])));

    Add('DS*');
    Add('ED*');
    Add('SB1*', Round(Tall*1000 + 15000));
  end;

 var
  xcmd: IXMLNode;
  dp, nm: Integer;
  c: string;
  ca: TArray<string>;
  setPos: Boolean;
begin
  if ssRun in FStatusStol then raise EStolGKException.CreateFmt('Идет выполнение комады %s',[string(FRunCmd)]);
  FRunRes := Res;
  xcmd := XMLCommand.ChildNodes.FindNode(Cmd);
  if cmd.Trim.IsEmpty then Exit
  else if Assigned(xcmd) then
   begin
    if not xcmd.HasAttribute('SYNC') and not (ssSync in FStatusStol) then raise EStolGKException.Create('Метка не найдена !!!');

    if not (ssSync in FStatusStol) and not xcmd.NodeName.Contains('HOME') then
    if MessageDlg(Format('Синхронизация положения отсутствует. Точка замера %s[%s] полжна находиться поблизости и правее текущего положения',
     [xcmd.NodeName, xcmd.Attributes['SYNC']]), TMsgDlgType.mtWarning, [mbOK, mbCancel], 0) = mrCancel then Exit;

    ScennaBegin;
    setPos := False;
    dp := Fposition;
    for c in string(xcmd.Attributes['COMMAND']).Split([';'], TStringSplitOptions.ExcludeEmpty) do
     begin
      if c.Contains('*') then Add(AnsiString(c))
      else
       begin
        ca := c.Trim.Split([':'], TStringSplitOptions.ExcludeEmpty);
        if ca[0] = 'GOTO' then
         begin
          if ca[1].Trim.Chars[0] = 'M' then
           begin
            nm := StrToInt(ca[1].Trim.Chars[1]);
            if nm > 3 then raise EStolGKException.CreateFmt('Нет метки M%d', [nm]);
            dp := xcmd.Attributes['SYNC'];
            setPos := True;
            if ssSync in FStatusStol then MoveN(dp - Fposition, nm)
            else MoveInf(nm);
           end
          else
           begin
            dp := ca[1].Trim.ToInteger();
            setPos := True;
            MoveN(dp - Fposition);
           end;
         end
         else raise EStolGKException.CreateFmt('Нет комады %s',[ca[0]]);
       end
     end;
//    if xcmd.HasAttribute('SYNC') then dp := xcmd.Attributes['SYNC'];
    ScennaRun(res, setPos, dp);
   end
  else if TryStrToInt(cmd.Trim, dp) then
   begin
    ScennaBegin;
    MoveN(dp);
    ScennaRun(res, ssSync in FStatusStol, Fposition + dp);
   end
  else if Cmd.Contains('GOTO:') then
   begin
    if not (ssSync in FStatusStol) then raise EStolGKException.Create('Метка не найдена !!!');
    dp := Cmd.Trim.Split([':'])[1].ToInteger();
    ScennaBegin;
    MoveN(dp - Fposition);
    ScennaRun(res, True, dp);
   end
  else raise EStolGKException.CreateFmt('комада %s не найдена',[Cmd]);
end;


{ TProtocolStolGK }

initialization
  RegisterClass(TStolGK);
  TRegister.AddType<TStolGK, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TStolGK>;
end.
