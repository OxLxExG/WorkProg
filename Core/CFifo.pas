unit CFifo;

interface

uses debug_except,  IndexBuffer,
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections, System.SyncObjs, System.Threading;

type

  EFifoException = class(EBaseException);

  TIndexFifo<T> = class(TIndexBuf<T>)
  private
    function ToLocal(idx: GlobIdx): LocIdx;
  protected
    FBuf: TIndexBuf<T>.TArrayT;
    procedure SetFirstIndex(const Value: GlobIdx); override;
    procedure SetCapacity(const Value: Integer); override;
    function GetData(const index: GlobIdx): T; override;
    procedure SetData(const index: GlobIdx; const Value: T); override;
  public
    function Write(pdata: Pointer; Cnt: integer): Integer; override;
    function Read(FromIndex: GlobIdx; Cnt: Integer): TCustomlIndexArray<T>; override;
  end;

  TIndexFifoDouble = TIndexFifo<Double>;
//  TIndexFifoDoubleClass = class of TIndexFifoDouble;


implementation

{ TFifo<T> }

procedure TIndexFifo<T>.SetCapacity(const Value: Integer);
begin
  if Capacity <> Value then
   begin
    inherited;
    SetLength(FBuf, Capacity);
   end;
end;

function TIndexFifo<T>.GetData(const index: GlobIdx): T;
begin
  Result := FBuf[ToLocal(index)]
end;

procedure TIndexFifo<T>.SetData(const index: GlobIdx; const Value: T);
begin
  FBuf[ToLocal(index)] := Value;
end;

procedure TIndexFifo<T>.SetFirstIndex(const Value: GlobIdx);
begin
  inherited;
  FCount := 0;
end;

function TIndexFifo<T>.ToLocal(idx: GlobIdx): LocIdx;
begin
  Result := idx mod Capacity;
  if (FirstIndex > idx) or (idx > LastIndex) then
     raise EFifoException.CreateFmt('Ошибка индекса %s  F=%d L=%d idx=%d', [Name, FirstIndex, LastIndex, idx]);
end;

function TIndexFifo<T>.Read(FromIndex: GlobIdx; Cnt: Integer): TCustomlIndexArray<T>;
 var
  l, h: LocIdx;
  n0, n1: Integer;
begin
  // потеря данных
  l := ToLocal(FromIndex);
  h := ToLocal(FromIndex + Cnt - 1);
  // initializ границы
  Result.FirstIdx := FromIndex;
  SetLength(Result.Data, cnt);
  // заполнение
  if l < h then Move(Fbuf[l], Result.Data[0], cnt*SIZE_T)
  else
   begin
    n0 := Capacity - l;
    n1 := cnt - n0; // == h+1
    Move(Fbuf[l], Result.Data[0], n0*SIZE_T);
    Move(Fbuf[0], Result.Data[n0], n1*SIZE_T);
   end;
end;

function TIndexFifo<T>.Write(pdata: Pointer; Cnt: integer): Integer;
 var
  p: PointerT;
  locCur, n0, n1: Integer;
begin
  p := pdata;
  Result := Cnt;
  if Cnt = 0 then Exit
  // бред
  else if Cnt < 0 then raise EFifoException.CreateFmt('IndexFifo.Write число данных [%d] для записи в буфер меньше 0', [cnt])
  // потеря данных
  else if Cnt > Capacity then
   begin
    n0 := cnt-Capacity;
    inc(FFirstIndex, n0);
    Inc(p, n0);
    Cnt := Capacity;
    if Assigned(TDebug.ExeptionEvent) then TDebug.ExeptionEvent(ClassName, Format('Потеря данных записи в буфер Capacity=%d Cnt=%d',[Capacity,  Cnt]), #$D#$A);
   end;
  // заполнение
  locCur := (FirstIndex + Count) mod Capacity;
  if locCur + Cnt > Capacity then
   begin
    n0 := Capacity-locCur;
    n1 := Cnt-n0;
    Move(p^, Fbuf[locCur], n0*SIZE_T);
    inc(p, n0);
    Move(p^, Fbuf[0], n1*SIZE_T);
   end
  else
   begin
    Move(p^, Fbuf[locCur], cnt*SIZE_T);
   end;
  // границы
  if Count + Cnt > Capacity then
   begin
    n0 := Count + Cnt - Capacity;
    inc(FFirstIndex, n0);
    FCount := Capacity;
   end
  else Inc(FCount, Cnt);
end;

end.
