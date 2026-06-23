unit Fifo.Decoder;

interface

uses debug_except, Fifo, Cfifo, Math.Telesistem.Custom, //JDtools,
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections, System.SyncObjs, System.Threading;


type

  TFifoDecoder = class(TBookmarkFifoDouble)
  private
    FDecoders: TCustomDecoderCollection;
    procedure SetDecoders(const Value: TCustomDecoderCollection);
  public
    procedure ExecDecoders;
    constructor Create(Owner: TPersistent; aCapacity: Integer); override;
    destructor Destroy; override;
    {[ShowProp('декодеры', true)]} property Decoders: TCustomDecoderCollection read FDecoders write SetDecoders;
  end;

  TCFifoDecoder = class(TIndexFifoDouble)
  private
    FDecoders: TCustomDecoderCollection;
    procedure SetDecoders(const Value: TCustomDecoderCollection);
  public
    procedure ExecDecoders;
    constructor Create(Owner: TPersistent; aCapacity: Integer); override;
    destructor Destroy; override;
    {[ShowProp('декодеры', true)]} property Decoders: TCustomDecoderCollection read FDecoders write SetDecoders;
  end;

implementation

{ TFifoDecoder }

constructor TFifoDecoder.Create(Owner: TPersistent; aCapacity: Integer);
begin
  FDecoders := TCustomDecoderCollection.Create(TCustomDecoder);
  inherited;
end;

destructor TFifoDecoder.Destroy;
begin
  FDecoders.Free;
  inherited;
end;

procedure TFifoDecoder.ExecDecoders;
 var
  i: Integer;
begin
  for i := 0 to FDecoders.Count-1 do  TCustomDecoder(FDecoders.Items[i]).RunAutomat;
end;

procedure TFifoDecoder.SetDecoders(const Value: TCustomDecoderCollection);
 var
  i: Integer;
begin
  if FDecoders <> Value then
   begin
    FDecoders.Free;
    FDecoders := Value;
    for i := 0 to FDecoders.Count-1 do  TCustomDecoder(FDecoders.Items[i]).Buf := Self;
   end;
end;

{ TCFifoDecoder }

constructor TCFifoDecoder.Create(Owner: TPersistent; aCapacity: Integer);
begin
  FDecoders := TCustomDecoderCollection.Create(TCustomDecoder);
  inherited;
end;

destructor TCFifoDecoder.Destroy;
begin
  FDecoders.Free;
  inherited;
end;

procedure TCFifoDecoder.ExecDecoders;
 var
  i: Integer;
begin
  for i := 0 to FDecoders.Count-1 do  TCustomDecoder(FDecoders.Items[i]).RunAutomat;
end;

procedure TCFifoDecoder.SetDecoders(const Value: TCustomDecoderCollection);
 var
  i: Integer;
begin
  if FDecoders <> Value then
   begin
    FDecoders.Free;
    FDecoders := Value;
    for i := 0 to FDecoders.Count-1 do  TCustomDecoder(FDecoders.Items[i]).Buf := Self;
   end;
end;

end.
