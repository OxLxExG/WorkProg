unit Fifo;

interface

uses debug_except, IndexBuffer,
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections, System.SyncObjs, System.Threading;

type
  TFifo<T> = class(TIndexBuf<T>)
  public
   type
    PointerT = TIndexBuf<T>.PointerT;
    TBeforeDeleteEvent = procedure(Sender: TFifo<T>; DelCnt: Integer) of object;
    TAfteWriteEvent = procedure(Sender: TFifo<T>{; AddCnt: Integer}) of object;
    TResultExtruct = reference to procedure(NNeedWrite, NWrite: Integer);
    TResultInsert = reference to procedure();
    TGetDataChild = reference to procedure(Sender: TFifo<T>; out PData: Pointer; out Cnt: Integer);
  private
    FOnDelete: TBeforeDeleteEvent;
    FParentFifo: TFifo<T>;
    FChildFifo: TFifo<T>;
    FOnAfteWrite: TAfteWriteEvent;
    procedure SetChildFifo(const Value: TFifo<T>);
    procedure SetParentFifo(const Value: TFifo<T>);
   var
    FBuf, FPLast: PointerT;
    FLockCount: Integer;
    FLock: TCriticalSection;
    FSendIndex: Integer;
    FSendTask: ITask;
    function GetBuf(Index: Integer): PointerT;
    function GetBufData(Index: Integer): T;
  protected
    procedure DeleteBuf(cnt_del: Integer); virtual;
    procedure SetCapacity(const Value: Integer); override;
    function GetData(const index: GlobIdx): T; override;
    procedure SetData(const index: GlobIdx; const Value: T); override;
  public
    constructor Create(Owner: TPersistent; ACapacity: Integer); override;
    destructor Destroy; override;

    procedure Extract(Res: TResultExtruct = nil);
    procedure Insert(Item: TFifo<T>; Res: TResultInsert = nil; Before: Boolean = False);

    procedure Lock;
    procedure UnLock;

    procedure ClearBuffer; virtual;
    procedure AddData(data: T); virtual;
    function Write(pdata: Pointer; Cnt: integer): Integer; override;
    function Read(FromIndex: GlobIdx; Cnt: Integer): TCustomlIndexArray<T>; override;

    function TryGetData(FromIndex, ToIndex: Integer; pOutData: Pointer): boolean;

    procedure WriteTo2(Fifo: TFifo<T>; pdata: PointerT; Cnt: integer);
    function WriteTo(ChildFifo: TFifo<T>; FromIndex, ToIndex: Integer): integer;
    function IsValidIndex(Index: Integer): Boolean;

    procedure AsyncSend(AsyncEvent: TGetDataChild);

    property OnDelete: TBeforeDeleteEvent read FOnDelete write FOnDelete;
    property OnAfteWrite: TAfteWriteEvent read FOnAfteWrite write FOnAfteWrite;
    property First: PointerT read FBuf;
    property Last: PointerT read FPLast;
    /// Index <= 0 - относительно последних данных
    /// Index > 0 - √лобальный счетчик  с 1
    property PBuf[Index: Integer]: PointerT read GetBuf;
    property Buf[Index: Integer]: T read GetBufData;

   // property FifoConnection: TFifoConnection<T> read FFifoConnection write SetFifoConnection;
    property ParentFifo: TFifo<T> read FParentFifo write SetParentFifo;
    property ChildFifo: TFifo<T> read FChildFifo write SetChildFifo;

    property SendIndex: Integer read FSendIndex write FSendIndex;
  end;

  TFifoDouble = class(TFifo<Double>);

  TBookmarkFifo<T> = class(TFifo<T>)
  public
   type
    TbookmarkEvent = reference to procedure(Index, Data: Integer);
  private
   type
    TBookmarkData = record
      Index: Integer;
      Data: Integer;
      Ev: TbookmarkEvent;
     class function Create(AIndex, Data: Integer; AEv: TbookmarkEvent): TBookmarkData; static;
    end;
   var
    FBookmarks: TArray<TBookmarkData>;
  protected
    procedure DeleteBuf(cnt_del: Integer); override;
  public
    procedure AddData(data: T); override;
    function Write(pdata: Pointer; Cnt: integer): Integer; override;
    /// установка метки данных существующих в буфере LastIndex в насто€щем
    procedure Bookmark(Data: Integer); overload;
    /// установка  метки данных существующих в буфере или в будующем
    procedure Bookmark(Index, Data: Integer; Ev: TbookmarkEvent); overload;
    property Bookmarks: TArray<TBookmarkData> read FBookmarks write FBookmarks;
  end;

  TBookmarkFifoDouble = class(TBookmarkFifo<Double>);
  TBookmarkFifoDoubleClass = class of TBookmarkFifoDouble;

implementation

{ TFifo<T> }

constructor TFifo<T>.Create(Owner: TPersistent; ACapacity: Integer);
begin
  inherited;
  FLock := TCriticalSection.Create;
  GetMem(FBuf, Capacity*SIZE_T);
  FFirstIndex := 1;
  ClearBuffer;
end;

destructor TFifo<T>.Destroy;
begin
   if Assigned(FSendTask) and (FSendTask.Status = TTaskStatus.Running) then FSendTask.Wait();
   if Assigned(FChildFifo) then FChildFifo.ParentFifo := nil;
   if Assigned(FParentFifo) then FParentFifo.ChildFifo := nil;
   FreeMem(FBuf);
   FLock.Free;
   inherited;
end;

procedure TFifo<T>.Extract(Res: TResultExtruct);
 var
  n, n1, nwrite: Integer;
begin
  nwrite := 0;
  if Assigned(ChildFifo) then
   begin
    /// часть обработанных данных удал€емого буфера
    n := LastIndex - ChildFifo.LastIndex;
    if n > 0 then inc(nwrite, ChildFifo.Write(PBuf[-n + 1], n));
    /// часть не обработанных данных родительского буфера
    if Assigned(ParentFifo) then
     begin
      n1 := ParentFifo.LastIndex - LastIndex;
      if n1 > 0 then inc(nwrite, ChildFifo.Write(ParentFifo.PBuf[-n1 + 1], n1));
     end
   end;
  if Assigned(ParentFifo) then ParentFifo.ChildFifo := ChildFifo;
  if Assigned(ChildFifo) then ChildFifo.ParentFifo := ParentFifo;
  FChildFifo := nil;
  FParentFifo := nil;
  ClearBuffer;
  if Assigned(Res) then Res(n+n1, nwrite);
end;

procedure TFifo<T>.Insert(Item: TFifo<T>; Res: TResultInsert; Before: Boolean);
begin
  Item.ClearBuffer;
  Item.FirstIndex := LastIndex+1;
  if Before then
   begin
    Item.ParentFifo := ParentFifo;
    Item.ChildFifo := Self;
    if Assigned(Item.ParentFifo) then Item.FirstIndex := Item.ParentFifo.LastIndex+1
   end
  else
   begin
    Item.ChildFifo := ChildFifo;
    Item.ParentFifo := Self;
   end;
  if Assigned(Res) then Res();
end;

procedure TFifo<T>.AsyncSend(AsyncEvent: TGetDataChild);
begin
  if Assigned(FChildFifo) and (not Assigned(FSendTask) or (FSendTask.Status > TTaskStatus.Running)) then
   begin
    FSendTask := TTask.Run(procedure
     var
      d: Pointer;
      n: Integer;
    begin
      Lock;
      if not Assigned(FChildFifo) then
       begin
        UnLock;
        Exit;
       end;
      FChildFifo.Lock;
      try
       AsyncEvent(Self, d, n);
       if n > 0 then
        begin
         Inc(FSendIndex, FChildFifo.Write(d, n));
         if Assigned(FChildFifo.OnAfteWrite) then FChildFifo.OnAfteWrite(FChildFifo);
        end;
      finally
       FChildFifo.UnLock;
       UnLock;
      end;
    end);
   end;
end;

procedure TFifo<T>.ClearBuffer;
begin
  FPLast := FBuf;
  Dec(FPLast);
  FCount := 0;
end;

procedure TFifo<T>.DeleteBuf(cnt_del: Integer);
 var
  b: PointerT;
begin
  if Assigned(FOnDelete) then FOnDelete(Self, cnt_del);
  b := FBuf;
  inc(b, cnt_del);
  Move(b^, FBuf^, (FCount - cnt_del)*SIZE_T);
  FCount := FCount - cnt_del;
  Dec(FPLast, cnt_del);
  Inc(FFirstIndex, cnt_del);
end;

function TFifo<T>.IsValidIndex(Index: Integer): Boolean;
begin
  if Index <= 0 then Result := FCount > -Index
  else Result := (index >= FFirstIndex) and (index < FFirstIndex + FCount);
end;


function TFifo<T>.TryGetData(FromIndex, ToIndex: Integer; pOutData: Pointer): boolean;
begin
  Result := (FromIndex >= FFirstIndex) and (FromIndex <= ToIndex) and (ToIndex < FFirstIndex + FCount);
  if Result then Move(Pbuf[FromIndex]^, pOutData^, (ToIndex-FromIndex+1)*SIZE_T);
end;

procedure TFifo<T>.Lock;
begin
  FLock.Acquire;
  if FLockCount <= 0 then TDebug.Log('Acquire %s = %d',[name, FLockCount]);
  inc(FLockCount);
end;

function TFifo<T>.Read(FromIndex: GlobIdx; Cnt: Integer): TCustomlIndexArray<T>;
begin
  Result.FirstIdx := FromIndex;
  SetLength(Result.Data, cnt);
  if not TryGetData(FromIndex, FromIndex+cnt-1, @Result.Data[0]) then    //Read BUF[F=1 N=15552] Read[from=15354 cnt=256]
     raise EIndexBufferException.CreateFmt('TFifo<T>.Read BUF[F=%d L=%d] Need[F=%d L=%d]', [FirstIndex, LastIndex, FromIndex, FromIndex + cnt - 1]);
end;

procedure TFifo<T>.SetCapacity(const Value: Integer);
begin
  if Capacity <> Value then
   begin
    inherited;
    ReallocMem(FBuf, Capacity*SIZE_T);
    FPLast := FBuf;
    Inc(FPLast, Count-1);
   end;
end;

procedure TFifo<T>.SetChildFifo(const Value: TFifo<T>);
begin
//  if Assigned(Value) then
//    begin
//     Value.FParentFifo := Self;
//     Value.FChildFifo := FChildFifo;
//    end;
//  if Assigned(FChildFifo) then FChildFifo.FParentFifo := Value;
//  FChildFifo := Value;

  FChildFifo := Value;
  if Assigned(Value) then Value.FParentFifo := Self;
end;

procedure TFifo<T>.SetData(const index: GlobIdx; const Value: T);
begin
  GetBuf(Index)^ := Value;
end;

procedure TFifo<T>.SetParentFifo(const Value: TFifo<T>);
begin
  FParentFifo := Value;
  if Assigned(Value) then Value.FChildFifo := Self;
end;

procedure TFifo<T>.UnLock;
begin
  Dec(FLockCount);
  if FLockCount <= 0 then 
   begin
    TDebug.Log('Release %s = %d',[name, FLockCount]);
    if FLockCount < 0 then
     begin
      TDebug.Log('ERROR Release %s = %d',[name, FLockCount]);
     end;
   end ;
  FLock.Release;
end;

function TFifo<T>.GetBuf(Index: Integer): PointerT;
 var
  i: Integer;
begin
  if Index > 0 then
   begin
    i := Index - FFirstIndex;
    Assert(not ((i < 0) or (i >= FCount)), Format('%s: (i = %d < 0) or (i >= FCount = %d  FFirst = %d)', [name, i, Fcount, FFirstIndex]));
    Result := FBuf;
    inc(Result, i);
   end
  else
   begin
    Assert(FCount + Index > 0, name + ': -Index '+ Index.ToString +' >= '+ FCount.ToString + ' FCount');
    Result := FPLast;
    Inc(Result, Index);
   end;
end;

function TFifo<T>.GetBufData(Index: Integer): T;
begin
  Result := GetBuf(Index)^;
end;

function TFifo<T>.GetData(const index: GlobIdx): T;
begin
  Result := GetBuf(Index)^;
end;

//function TFifo<T>.GetLastIndex: Integer;
//begin
//  Result := FFirstIndex + FCount - 1;
//end;

procedure TFifo<T>.AddData(data: T);
 var
  cnt_del, ind: Integer;
  i: integer;
begin
  if FCount = Capacity then DeleteBuf(Fcount div 2);
  inc(FPLast);
  FPLast^ := Data;
  ind := FFirstIndex + Fcount;
  Inc(Fcount);
end;

function TFifo<T>.Write(pdata: Pointer; Cnt: integer): Integer;
 var
  del_cnt: Integer;
begin
  if Cnt > Capacity then Cnt := Capacity;
  if Cnt + FCount > Capacity then
   begin
    del_cnt := FCount div 2;
    if Cnt + del_cnt > Capacity then del_cnt := FCount;
    DeleteBuf(del_cnt);
   end;
  inc(FPLast);
  move(pdata^, FPLast^, Cnt*SIZE_T);
  Inc(FPLast, cnt-1);
  Inc(FCount, Cnt);
  Result := Cnt;
end;

function TFifo<T>.WriteTo(ChildFifo: TFifo<T>; FromIndex, ToIndex: Integer): integer;
begin
  Assert(IsValidIndex(FromIndex) and IsValidIndex(ToIndex), 'not IsValidIndex(FromIndex) and IsValidIndex(ToIndex)');
  if ChildFifo.LastIndex <> FromIndex-1 then
  begin
   TDebug.Log('ChildFifo.LastIndex %d <> FromIndex -1 %d',[ChildFifo.LastIndex, FromIndex-1]);
  end;
  Result := ChildFifo.Write(PBuf[FromIndex], ToIndex - FromIndex + 1);
end;

procedure TFifo<T>.WriteTo2(Fifo: TFifo<T>; pdata: PointerT; Cnt: integer);
 var
  nwrite: integer;
begin
  nwrite := 0;
  repeat
   Dec(cnt, nwrite);
   inc(pdata, nwrite);
   nwrite := Fifo.Write(pdata, cnt);
  until nwrite = cnt;
end;

{ TBookmarkFifo<T> }

{ TBookmarkFifo<T>.TBookmarkData }

class function TBookmarkFifo<T>.TBookmarkData.Create(AIndex, Data: Integer; AEv: TbookmarkEvent): TBookmarkData;
begin
  Result.Index := AIndex;
  Result.Data := Data;
  Result.Ev := Aev;
end;

procedure TBookmarkFifo<T>.DeleteBuf(cnt_del: Integer);
 var
  i: Integer;
begin
  inherited;
  for i := Length(FBookmarks)-1 downto 0 do if FBookmarks[i].Index < FFirstIndex then
   begin
    Assert(FBookmarks[i].Ev = nil, 'FBookmarks[i].Ev <> nil');
    Delete(FBookmarks, i, 1);
   end;
end;

procedure TBookmarkFifo<T>.AddData(data: T);
 var
  i: integer;
begin
  inherited;
  for i := 0 to Length(FBookmarks)-1 do with FBookmarks[i] do if (Index <= LastIndex) and Assigned(Ev) then
   begin
    Ev(Index, Data);
    Ev := nil;
   end;
end;

function TBookmarkFifo<T>.Write(pdata: Pointer; Cnt: integer): Integer;
 var
  i: integer;
begin
  Result := inherited;
  for i := 0  to Length(FBookmarks)-1 do with FBookmarks[i] do if (Index <= LastIndex) and Assigned(Ev) then
   begin
    Ev(Index, Data);
    Ev := nil;
   end;
end;

procedure TBookmarkFifo<T>.Bookmark(Index, Data: Integer; Ev: TbookmarkEvent);
begin
  Assert(not (Index < FFirstIndex), 'Bookmark Index < FFirstIndex');
  FBookmarks := FBookmarks + [TBookmarkData.Create(Index, Data, Ev)]
end;

procedure TBookmarkFifo<T>.Bookmark(Data: Integer);
begin
  FBookmarks := FBookmarks + [TBookmarkData.Create(LastIndex, Data, nil)]
end;

end.
