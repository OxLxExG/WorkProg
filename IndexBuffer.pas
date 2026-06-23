unit IndexBuffer;

interface

uses debug_except,
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections, System.SyncObjs, System.Threading;
type

  EIndexBufferException = class(EBaseException);

  GlobIdx = type Integer;
  LocIdx = type Integer;

  TCustomBufPoint<T> = record
    dat: T;
    idx: LocIdx;
    function Assign(d: T; i: LocIdx): TCustomBufPoint<T>;
    constructor Create(d: T; i: LocIdx);
  end;
  TBufPoint = TCustomBufPoint<Double>;

  TCopyConvertFunc<T> = reference to function (Idx: integer; Dat: T): T;
  ///	<summary>
  ///	  локальный буфер прив€заный к глобальному индеку
  ///	</summary>
  TCustomlIndexArray<T> = record
    FirstIdx: GlobIdx;
    Data: TArray<T>;
    function Len: Integer;
  // перенос локальной точки с self буфера в другой буфер
    function LocalTo(Buf: TCustomlIndexArray<T>; g: LocIdx): LocIdx;
    function Local(g: GlobIdx): LocIdx;
    function Global(l: LocIdx): GlobIdx;
    function Copy(const Convert: TCopyConvertFunc<T> = nil): TCustomlIndexArray<T>;
    class operator Add(const A, B: TCustomlIndexArray<T>): TCustomlIndexArray<T>;
    class operator Add(const A: TCustomlIndexArray<T>; const B: TArray<T>): TCustomlIndexArray<T>;
  end;
  TIndexArray = TCustomlIndexArray<Double>;

  ///	<summary>
  ///	  индекc буфер abstract
  ///	</summary>
  ///      Ќ≈Ћ№«я Ќј—Ћ≈ƒќ¬ј“№ bind не работает
  TIndexBuf = class
  private
    FCapacity: Integer;
    FOwner: TPersistent;
    FName: string;
    function GetLastIndex: GlobIdx; inline;
  protected
    FFirstIndex: GlobIdx;
    FCount: Integer;
    function GetOwner: TPersistent; virtual;
    procedure SetFirstIndex(const Value: GlobIdx); virtual;
    procedure SetCapacity(const Value: Integer); virtual;
    function GetName: string; virtual;
  public
    constructor Create(Owner: TPersistent; ACapacity: Integer); virtual;
    function Write(pdata: Pointer; Cnt: integer): Integer; virtual; abstract;
    property FirstIndex: GlobIdx read FFirstIndex write SetFirstIndex;
    property LastIndex: GlobIdx read GetLastIndex;
    property Owner: TPersistent read FOwner;
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Name: string read GetName write FName;
  end;

  TIndexBufClass = class of TIndexBuf;

  TIndexBuf<T> = class(TIndexBuf) //(Tcomponent) //TInterfacedPersistent bind перестает работать!!!
  public
   type
    PointerT = ^T;
    TArrayT = TArray<T>;
   const
    SIZE_T = SizeOf(T);
  protected
    function GetData(const index: GlobIdx): T; virtual; abstract;
    procedure SetData(const index: GlobIdx; const Value: T); virtual; abstract;
  public
    function Read(FromIndex: GlobIdx; Cnt: Integer): TCustomlIndexArray<T>; virtual; abstract;
    property Data[const index: GlobIdx]: T read GetData write SetData;
  end;

  TIndexBufWrap = record
    obj: TIndexBuf;
    class operator Implicit(d: TIndexBuf): TIndexBufWrap;
    class operator Implicit(d: TIndexBufWrap): TIndexBuf;
  end;

  TIndexBufDouble = TIndexBuf<Double>;


implementation

{ TIndexFifo }

constructor TIndexBuf.Create(Owner: TPersistent; ACapacity: Integer);
begin
  FOwner := Owner;
  Capacity := ACapacity;
end;

function TIndexBuf.GetLastIndex: GlobIdx;
begin
  Result := FFirstIndex + FCount - 1;
end;

function TIndexBuf.GetName: string;
begin
  if FName = '' then FName := ClassName + Double(Now).Tostring;
  Result := FName;
end;

function TIndexBuf.GetOwner: TPersistent;
begin
  Result := FOwner
end;

procedure TIndexBuf.SetCapacity(const Value: Integer);
begin
  FCapacity := Value;
end;

procedure TIndexBuf.SetFirstIndex(const Value: GlobIdx);
begin
  FFirstIndex := Value;
end;

///
///
///
class operator TCustomlIndexArray<T>.Add(const A, B: TCustomlIndexArray<T>): TCustomlIndexArray<T>;
begin
  if A.FirstIdx + A.Len <> B.FirstIdx then
    raise EIndexBufferException.CreateFmt('ќшибка сложени€ IndexArray A[%d %d] + B[%d %d]', [a.FirstIdx, a.Len, b.FirstIdx, b.Len]);
  Result := A;
  Result.Data := A.Data + B.Data;
end;

class operator TCustomlIndexArray<T>.Add(const A: TCustomlIndexArray<T>; const B: TArray<T>): TCustomlIndexArray<T>;
begin
  Result := A;
  Result.Data := A.Data + B;
end;

function TCustomlIndexArray<T>.Copy(const Convert: TCopyConvertFunc<T>): TCustomlIndexArray<T>;
 var
  i: Integer;
begin
  Result.FirstIdx := FirstIdx;
  SetLength(Result.Data, Length(Data));
  if Assigned(Convert) then
     for I := 0 to Length(Data)-1 do Result.Data[i] := Convert(i, Data[i])
  else Move(Data[0], Result.Data[0], Length(Data)*Sizeof(T));
end;

function TCustomlIndexArray<T>.Global(l: LocIdx): GlobIdx;
begin
  Result := FirstIdx + l;
end;

function TCustomlIndexArray<T>.Len: Integer;
begin
  Result := Length(Data);
end;

function TCustomlIndexArray<T>.Local(g: GlobIdx): LocIdx;
begin
  Result := g - FirstIdx;
end;

function TCustomlIndexArray<T>.LocalTo(Buf: TCustomlIndexArray<T>; g: LocIdx): LocIdx;
begin
  Result := g + FirstIdx - Buf.FirstIdx;
end;

{ TBufPoint }

function TCustomBufPoint<T>.Assign(d: T; i: LocIdx): TCustomBufPoint<T>;
begin
  dat := d;
  idx := i;
  Result := Self;
end;

constructor TCustomBufPoint<T>.Create(d: T; i: LocIdx);
begin
  dat := d;
  idx := i;
end;

{ TIndexBufWrap}

class operator TIndexBufWrap.Implicit(d: TIndexBuf): TIndexBufWrap;
begin
  Result.obj := d;
end;

class operator TIndexBufWrap.Implicit(d: TIndexBufWrap): TIndexBuf;
begin
  Result := d.obj;
end;

end.
