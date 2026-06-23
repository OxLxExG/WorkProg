unit ProtocolBurUnit;

interface

uses  AbstractDev,
      debug_except,
      CRC16,
  System.SysUtils, System.Generics.Collections, System.SyncObjs;

type
  // Тип процедуры для очереди
  TRunSerialQeRef = reference to procedure(RemainingCount: Integer);

  EProtocolBurException = class(EBaseException);

  TProtocolBur = class(TAbstractProtocol)
  private
    FLock: TObject;
    FQe: TQueue<TRunSerialQeRef>;
    FIsWaitingResponse: Boolean;
  protected
    FOldCount: Integer;
    FCRC: Word;
    procedure ProcessNext;
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
    procedure EventRxChar(Sender: TAbstractConnectIO); override;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $400); override;
  public
    constructor Create;
    destructor Destroy; override;

    // Добавление в очередь (из любого потока)
    function Add(data: TRunSerialQeRef): Integer;
    // Переход к следующей задаче (вызывать после обработки ответа)
    procedure Next;
    // Полная очистка очереди
    procedure Clear;
  end;

implementation

{ TProtocolBur }

constructor TProtocolBur.Create;
begin
  inherited Create;
  FLock := TObject.Create;
  FQe := TQueue<TRunSerialQeRef>.Create;
  FIsWaitingResponse := False;
end;

destructor TProtocolBur.Destroy;
begin
  Clear;
  FQe.Free;
  FLock.Free;
  inherited Destroy;
end;

function TProtocolBur.Add(data: TRunSerialQeRef): Integer;
begin
  TMonitor.Enter(FLock);
  try
    FQe.Enqueue(data);
    Result := FQe.Count;

    // Если порт свободен — запускаем выполнение немедленно
    if not FIsWaitingResponse then
      ProcessNext;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TProtocolBur.Next;
begin
  TMonitor.Enter(FLock);
  try
    FIsWaitingResponse := False;
    ProcessNext;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TProtocolBur.ProcessNext;
begin
  // Метод вызывается строго под FLock
  if (FQe.Count > 0) and (not FIsWaitingResponse) then
  begin
    FIsWaitingResponse := True;
    var Task := FQe.Dequeue;
    // Выполняем задачу (отправку в порт)
    if Assigned(Task) then Task(FQe.Count);
  end;
end;

procedure TProtocolBur.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
begin
  if Cnt > maxsend then
    raise EProtocolBurException.CreateFmt('Data count for read %d more than %d', [Cnt,maxsend]);
  SetCRC16(Data, Cnt);
  Sender.FICount := 0;
  Inc(Cnt, 2);

  FOldCount := 0;
  FCRC := $FFFF;
end;

procedure TProtocolBur.Clear;
begin
  TMonitor.Enter(FLock);
  try
    FQe.Clear;
    FIsWaitingResponse := False;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TProtocolBur.EventRxChar(Sender: TAbstractConnectIO);
var
  n, o: Integer;
begin
  Sender.FTimerRxTimeOut.Enabled := False;
  n := Sender.FICount - FOldCount;
  o := FOldCount;
  FOldCount := Sender.FICount;

  try
    if CRC16_Find(@Sender.FInput[o], n, FCRC) then
    begin
      Sender.DoEvent(@Sender.FInput[0], Sender.FICount - 2);
      Next; // Успех -> следующая задача
    end
    else
      Sender.FTimerRxTimeOut.Enabled := True;
  except
    Next; // Даже если DoEvent упал, не блокируем очередь
  end;
end;

procedure TProtocolBur.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  try
    // Логика обработки таймаута
    Sender.DoEvent(nil, -1);
  finally
    Next; // По таймауту тоже переходим к следующему элементу
  end;
end;

end.
