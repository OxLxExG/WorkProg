unit BookMarkFifo;

interface

uses
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections;

type
  TBookmarkFifo<T> = class
  public
   type
    TbookmarkEvent = reference to procedure(Index, Data: Integer);
  private
   type
    PointerT = ^T;
    TBookmarkData = record
      Index: Integer;
      Data: Integer;
      Ev: TbookmarkEvent;
     class function Create(AIndex, Data: Integer; AEv: TbookmarkEvent): TBookmarkData; static;
    end;
   const
    CT = SizeOf(T);
   var
    FBuf, FPLast: PointerT;
    FBookmarks: TArray<TBookmarkData>;
    FCapacity: Integer;
    FCount: Integer;
    FFirstIndex: Integer;
    function GetLastIndex: Integer; inline;
    function GetBuf(Index: Integer): PointerT;
    function GetBufData(Index: Integer): T;
  public
    constructor Create(Capacity: Integer);
    destructor Destroy; override;
    procedure DeleteBuf(cnt_del: Integer);
    /// установка метки данных существующих в буфере LastIndex в настоящем
    procedure Bookmark(Data: Integer); overload;
    /// установка  метки данных существующих в буфере или в будующем
    procedure Bookmark(Index, Data: Integer; Ev: TbookmarkEvent); overload;
    procedure AddData(data: T);
    function Write(pdata: Pointer; Cnt: integer): Integer;
    class procedure WriteTo(Fifo: TBookmarkFifo<T>; pdata: Pointer; Cnt: integer);
    function IsValidIndex(Index: Integer): Boolean;
    procedure ClearBuffer;
    property FirstIndex: Integer read FFirstIndex;
    property LastIndex: Integer read GetLastIndex;
    property Count: Integer read FCount;
    property First: PointerT read FBuf;
    property Last: PointerT read FPLast;
    /// Index <= 0 - относительно последних данных
    /// Index > 0 - Глобальный счетчик  с 1
    property PBuf[Index: Integer]: PointerT read GetBuf;
    property Buf[Index: Integer]: T read GetBufData;
    property Bookmarks: TArray<TBookmarkData> read FBookmarks write FBookmarks;
  end;

  TBookmarkFifoDouble = class(TBookmarkFifo<Double>);

implementation

{ TBookmarkFifo<T>.TBookmarkData }

class function TBookmarkFifo<T>.TBookmarkData.Create(AIndex, Data: Integer; AEv: TbookmarkEvent): TBookmarkData;
begin
  Result.Index := AIndex;
  Result.Data := Data;
  Result.Ev := Aev;
end;

{ TBookmarkFifo<T> }

constructor TBookmarkFifo<T>.Create(Capacity: Integer);
begin
  inherited Create;
  FCapacity := Capacity;
  GetMem(FBuf, Capacity*CT);
  ClearBuffer;
  FFirstIndex := 1;
end;

destructor TBookmarkFifo<T>.Destroy;
begin
  FreeMem(FBuf);
  inherited;
end;

procedure TBookmarkFifo<T>.ClearBuffer;
begin
  FPLast := FBuf;
  Dec(FPLast);
  FCount := 0;
end;

procedure TBookmarkFifo<T>.DeleteBuf(cnt_del: Integer);
 var
  b: PointerT;
  i: Integer;
begin
  Assert(cnt_del <= FCount, 'cnt_del > FCount');
  b := FBuf;
  inc(b, cnt_del);
  Move(b^, FBuf^, (FCount - cnt_del)*CT);
  FCount := FCount - cnt_del;
  Dec(FPLast, cnt_del);
  Inc(FFirstIndex, cnt_del);
  for i := Length(FBookmarks)-1 downto 0 do if FBookmarks[i].Index < FFirstIndex then
   begin
    Assert(FBookmarks[i].Ev <> nil, 'FBookmarks[i].Ev = nil');
    Delete(FBookmarks, i, 1);
   end;
end;

function TBookmarkFifo<T>.IsValidIndex(Index: Integer): Boolean;
begin
  if Index <= 0 then Result := FCount + Index > 0
  else Result := (Index >= FFirstIndex) and (Index < FFirstIndex + FCount);
end;


function TBookmarkFifo<T>.GetBuf(Index: Integer): PointerT;
 var
  i: Integer;
begin
  if Index > 0 then
   begin
    i := Index - FFirstIndex;
    Assert(not ((i < 0) or (i >= FCount)), 'TBookmarkFifo<T>.GetBuf (i < 0) or (i >= FCount)');
    Result := FBuf;
    inc(Result, i);
   end
  else
   begin
    Assert(not (FCount + Index > 0), '-Index >= FCount');
    Result := FPLast;
    Inc(Result, Index);
   end;
end;

function TBookmarkFifo<T>.GetBufData(Index: Integer): T;
begin
  Result := GetBuf(Index)^;
end;

function TBookmarkFifo<T>.GetLastIndex: Integer;
begin
  Result := FFirstIndex + FCount - 1;
end;

procedure TBookmarkFifo<T>.AddData(data: T);
 var
  cnt_del, ind: Integer;
  i: integer;
begin
  if FCount = FCapacity then DeleteBuf(Fcount div 2);
  inc(FPLast);
  FPLast^ := Data;
  ind := FFirstIndex + Fcount;
  Inc(Fcount);
  for i := 0  to Length(FBookmarks)-1 do with FBookmarks[i] do if (Index = ind) and Assigned(Ev) then
   begin
    Ev(Index, Data);
    Ev := nil;
   end;
end;

function TBookmarkFifo<T>.Write(pdata: Pointer; Cnt: integer): Integer;
 var
  del_cnt, Lind, Hind: Integer;
  i: integer;
begin
  if Cnt > FCapacity then Cnt := FCapacity;
  if Cnt + FCount > FCapacity then
   begin
    del_cnt := FCount div 2;
    if Cnt + del_cnt > FCapacity then del_cnt := FCount;
    DeleteBuf(del_cnt);
   end;
  inc(FPLast);
  move(pdata^, FPLast^, Cnt*CT);
  Inc(FPLast, cnt-1);
  Lind := FFirstIndex + FCount;
  Inc(FCount, Cnt);
  Hind := FFirstIndex + Fcount-1;
  for i := 0  to Length(FBookmarks)-1 do with FBookmarks[i] do if (Index >= Lind) and (Index <= Hind) and Assigned(Ev) then
   begin
    Ev(Index, Data);
    Ev := nil;
   end;
  Result := Cnt;
end;

class procedure TBookmarkFifo<T>.WriteTo(Fifo: TBookmarkFifo<T>; pdata: Pointer; Cnt: integer);
 var
  nwrite: integer;
begin
  nwrite := 0;
  repeat
   Dec(cnt, nwrite);
   nwrite := Fifo.Write(pdata, cnt);
  until nwrite = cnt;
end;

procedure TBookmarkFifo<T>.Bookmark(Data: Integer);
begin
  FBookmarks := FBookmarks + [TBookmarkData.Create(LastIndex, Data, nil)]
end;

procedure TBookmarkFifo<T>.Bookmark(Index, Data: Integer; Ev: TbookmarkEvent);
begin
  Assert(not (Index < FFirstIndex), 'Bookmark Index < FFirstIndex');
  FBookmarks := FBookmarks + [TBookmarkData.Create(Index, Data, Ev)]
end;

end.
