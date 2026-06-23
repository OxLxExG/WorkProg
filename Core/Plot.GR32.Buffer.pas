unit Plot.GR32.Buffer;

interface

uses System.SysUtils, GR32, GR32_Backends_VCL, CustomPlot, Vcl.Forms, GR32_ExtImage;

type
  TRenderReadyEvent = TProc;
  TGR32DataBuffer = class(TBitmap32)
  private
   type
    TDataRegion = record
      Y0,     Y1: Double;
      Ypx0, Ypx1: Integer;
      Ready: Boolean;
    end;
   var
    FRegion: TGraphRegion;
    FReadyRegion: TArray<TDataRegion>;
    procedure JoinDataRegion;
    procedure SplitDataRegion(DownDir: Boolean);
    function YtoBitmap(Ypos: Double): Integer;
  public
    class function GetPlatformBackendClass: TCustomBackendClass; override;

    procedure Draw(Y0, Y1: Double; Dst: TBitmap32; ReadyEvent: TRenderReadyEvent);
//    property Mirror: Boolean;
//    property YFirst: Double;
//    property YFirstPixel: Integer;
//    property YLast: Double;
//    property YLastPixel: Integer;
//    property YScale: Double;
  end;

  TGR32BufferBackend = class(TGDIMMFBackend)

  end;

implementation

{ TGR32Buffer }

function TGR32DataBuffer.YtoBitmap(Ypos: Double): Integer;
var
  pos: Double;
begin
  Pos := (Ypos - FRegion.Graph.YTopScreen) * (Screen.PixelsPerInch / 2.54 * 2) * FRegion.Graph.YScale;
  Result := Round(pos);
end;


procedure TGR32DataBuffer.Draw(Y0, Y1: Double; Dst: TBitmap32; ReadyEvent: TRenderReadyEvent);
begin
  JoinDataRegion;

end;

class function TGR32DataBuffer.GetPlatformBackendClass: TCustomBackendClass;
begin
  Result := TGR32BufferBackend;
end;

procedure TGR32DataBuffer.JoinDataRegion;
  function ChekJoin(l,h: integer): Boolean;
  begin
    if h >= Length(FReadyRegion) then Exit(False);
    if FReadyRegion[l].Ready and FReadyRegion[h].Ready and (FReadyRegion[l].Ypx1 = FReadyRegion[h].Ypx0) then
     begin
      FReadyRegion[l].Y1 := FReadyRegion[h].Y1;
      FReadyRegion[l].Ypx1 := FReadyRegion[h].Ypx1;
      System.Delete(FReadyRegion, h , 1);
      Result := True;
     end
    else Result := False;
  end;
 var
  i: Integer;
begin
  i := 0;
  while i < Length(FReadyRegion) do
   begin
    while ChekJoin(i, i+1) do;
    inc(i);
   end;
end;

procedure TGR32DataBuffer.SplitDataRegion(DownDir: Boolean);
 var
  hs, h, hy, i: Integer;
  s, y0, y1: Double;
  ys0, ys1: Double;
begin
  hs := FRegion.ClientRect.Height;
  s := (Screen.PixelsPerInch / 2.54 * 2) * FRegion.Graph.YScale;
  y0 := FRegion.Graph.YFromData;
  y1 := FRegion.Graph.YLast;
  ys0 := FRegion.Graph.YTopScreen;
  ys1 := FRegion.Graph.YButtomScreen;
  h := Height;
  hy := Round(Abs(y1-y0)*s);
  if hy <= h then
   begin
   // буфер больше
    SetLength(FReadyRegion, hy div 100 + 1);
    for i := 0 to hy div 100 do
     begin

     end;

    if FRegion.Graph.YMirror then
     begin

     end
    else
    begin

    end;
   end
  else
   begin


   end;
end;

end.
