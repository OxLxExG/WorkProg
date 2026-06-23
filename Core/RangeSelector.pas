unit RangeSelector;

interface

uses
  SysUtils, Windows, Messages, Graphics, Classes, Controls, UxTheme, Dialogs, tools;

type
  TRangeSelectorState = (rssNormal, rssDisabled, rssThumb1Hover, rssThumb1Down, rssThumb2Hover, rssThumb2Down, rssBlockHover, rssBlockDown);

  TRangeSelector = class(TCustomControl)
  private
    { Private declarations }
    FBuffer: TBitmap;
    FMin,
    FMax,
    FSelStart,
    FSelEnd: real;
    FTrackPos,
    FSelPos,
    FReadyPos1,
    FReadyPos2,
    FReadyPos3,
    FThumbPos1,
    FThumbPos2: TRect;
    FState: TRangeSelectorState;
    FDown: boolean;
    FPrevX,
    FPrevY: integer;
    FOnChange: TNotifyEvent;
    FDblClicked: Boolean;
    FThumbSize: TSize;
    FReadyEnd: real;
    procedure SwapBuffers;
    procedure SetMin(Min: real);
    procedure SetMax(Max: real);
    procedure SetSelStart(SelStart: real);
    procedure SetSelEnd(SelEnd: real);
    function GetSelLength: real;
    procedure UpdateMetrics;
    procedure SetState(State: TRangeSelectorState);
    function DeduceState(const X, Y: integer; const Down: boolean): TRangeSelectorState;
    function BarWidth: integer; inline;
    function LogicalToScreen(const LogicalPos: real): real;
    procedure UpdateThumbMetrics;
    procedure SetReadyEnd(const Value: real);
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseLeave(Sender: TObject);
    procedure DblClick; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
    property Anchors;
    property Min: real read FMin write SetMin;
    property Max: real read FMax write SetMax;
    property SelStart: real read FSelStart write SetSelStart;
    property SelEnd: real read FSelEnd write SetSelEnd;
    property ReadyEnd: real read FReadyEnd write SetReadyEnd;

    property SelLength: real read GetSelLength;
    property Enabled;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses Math;

function IsIntInInterval(x, xmin, xmax: integer): boolean; inline;
begin
  IsIntInInterval := (xmin <= x) and (x <= xmax);
end;

function PointInRect(const X, Y: integer; const Rect: TRect): boolean; inline;
begin
  PointInRect := IsIntInInterval(X, Rect.Left, Rect.Right) and
                 IsIntInInterval(Y, Rect.Top, Rect.Bottom);
end;

function IsRealInInterval(x, xmin, xmax: extended): boolean; inline;
begin
  IsRealInInterval := (xmin <= x) and (x <= xmax);
end;

{ TRangeSelector }

function TRangeSelector.BarWidth: integer;
begin
  result := Width - 2*FThumbSize.cx;
end;

constructor TRangeSelector.Create(AOwner: TComponent);
begin
  inherited;
  FBuffer := TBitmap.Create;
  FMin := 0;
  FMax := 100;
  FSelStart := 20;
  FSelEnd := 80;
  FDown := false;
  FPrevX := -1;
  FPrevY := -1;
  FDblClicked := false;
end;

procedure TRangeSelector.UpdateThumbMetrics;
var
  theme: HTHEME;
const
  DEFAULT_THUMB_SIZE: TSize = (cx: 12; cy: 20);
begin
  FThumbSize := DEFAULT_THUMB_SIZE;
  if UxTheme.UseThemes then
  begin
    theme := OpenThemeData(Handle, 'TRACKBAR');
    if theme <> 0 then
      try
        GetThemePartSize(theme, FBuffer.Handle, TKP_THUMBTOP, TUTS_NORMAL, nil, TS_DRAW, FThumbSize);
      finally
        CloseThemeData(theme);
      end;
  end;
end;

destructor TRangeSelector.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

function TRangeSelector.GetSelLength: real;
begin
  result := FSelEnd - FSelStart;
end;

function TRangeSelector.LogicalToScreen(const LogicalPos: real): real;
begin
  result := FThumbSize.cx + BarWidth * (LogicalPos - FMin) / Math.Max( FMax - FMin, 1);
end;

procedure TRangeSelector.DblClick;
var
  str: string;
begin
  FDblClicked := true;
  case FState of
    rssThumb1Hover, rssThumb1Down:
      begin
        str := FloatToStr(FSelStart);
        if InputQuery('Initial value', 'Enter new initial value:', str) then
          SetSelStart(StrToFloat(str));
      end;
    rssThumb2Hover, rssThumb2Down:
      begin
        str := FloatToStr(FSelEnd);
        if InputQuery('Final value', 'Enter new final value:', str) then
          SetSelEnd(StrToFloat(str));
      end;
  end;
end;

function TRangeSelector.DeduceState(const X, Y: integer; const Down: boolean): TRangeSelectorState;
begin
  result := rssNormal;

  if not Enabled then
    Exit(rssDisabled);

  if PointInRect(X, Y, FThumbPos1) then
    if Down then
      result := rssThumb1Down
    else
      result := rssThumb1Hover

  else if PointInRect(X, Y, FThumbPos2) then
    if Down then
      result := rssThumb2Down
    else
      result := rssThumb2Hover

  else if PointInRect(X, Y, FSelPos) then
    if Down then
      result := rssBlockDown
    else
      result := rssBlockHover;


end;

procedure TRangeSelector.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if FDblClicked then
  begin
    FDblClicked := false;
    Exit;
  end;
  FDown := Button = mbLeft;
  SetState(DeduceState(X, Y, FDown));
end;

procedure TRangeSelector.MouseLeave(Sender: TObject);
begin
  if Enabled then
    SetState(rssNormal)
  else
    SetState(rssDisabled);
end;

procedure TRangeSelector.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FState = rssThumb1Down then
    SetSelStart(FSelStart + (X - FPrevX) * (FMax - FMin) / BarWidth)
  else if FState = rssThumb2Down then
    SetSelEnd(FSelEnd + (X - FPrevX) * (FMax - FMin) / BarWidth)
  else if FState = rssBlockDown then
  begin
    if IsRealInInterval(FSelStart + (X - FPrevX) * (FMax - FMin) / BarWidth, FMin, FMax) and
       IsRealInInterval(FSelEnd + (X - FPrevX) * (FMax - FMin) / BarWidth, FMin, FMax) then
    begin
      SetSelStart(FSelStart + (X - FPrevX) * (FMax - FMin) / BarWidth);
      SetSelEnd(FSelEnd + (X - FPrevX) * (FMax - FMin) / BarWidth);
    end;
  end
  else
    SetState(DeduceState(X, Y, FDown));

  FPrevX := X;
  FPrevY := Y;
end;

procedure TRangeSelector.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  FDown := false;
  SetState(DeduceState(X, Y, FDown));
end;

procedure TRangeSelector.Paint;
var
  theme: HTHEME;
//  themep: HTHEME;
begin
  inherited;

  FBuffer.Canvas.Brush.Color := clThBkg;
  FBuffer.Canvas.FillRect(ClientRect);

  if UxTheme.UseThemes then
  begin

    theme := OpenThemeData(Handle, 'TRACKBAR');
//    themep := OpenThemeData(Handle, VSCLASS_PROGRESS);


    if theme <> 0 then
      try

//        DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_TRACK, TRS_NORMAL, FTrackPos, nil);

        case FState of
          rssDisabled:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_DISABLED, FSelPos, nil);
          rssBlockHover:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_HOT, FSelPos, nil);
          rssBlockDown:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_PRESSED, FSelPos, nil);
        else
          DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_NORMAL, FSelPos, nil);
        end;

        if not FReadyPos1.IsEmpty then DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_HOT, FReadyPos1, nil);
        if not FReadyPos2.IsEmpty then DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_HOT, FReadyPos2, nil);
        if not FReadyPos3.IsEmpty then DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMB, TUS_HOT, FReadyPos3, nil);

        case FState of
          rssDisabled:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBBOTTOM, TUBS_DISABLED, FThumbPos1, nil);
          rssThumb1Hover:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBBOTTOM, TUBS_HOT, FThumbPos1, nil);
          rssThumb1Down:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBBOTTOM, TUBS_PRESSED, FThumbPos1, nil);
        else
          DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBBOTTOM, TUBS_NORMAL, FThumbPos1, nil);
        end;

        case FState of
          rssDisabled:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBTOP, TUTS_DISABLED, FThumbPos2, nil);
          rssThumb2Hover:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBTOP, TUTS_HOT, FThumbPos2, nil);
          rssThumb2Down:
            DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBTOP, TUTS_PRESSED, FThumbPos2, nil);
        else
          DrawThemeBackground(theme, FBuffer.Canvas.Handle, TKP_THUMBTOP, TUTS_NORMAL, FThumbPos2, nil);
        end;

      finally
        CloseThemeData(theme);
      end;

  end

  else

  begin

    DrawEdge(FBuffer.Canvas.Handle, FTrackPos, EDGE_SUNKEN, BF_RECT);

    FBuffer.Canvas.Brush.Color := clHighlight;
    FBuffer.Canvas.FillRect(FSelPos);

    case FState of
      rssDisabled:
        DrawEdge(FBuffer.Canvas.Handle, FSelPos, EDGE_BUMP, BF_RECT or BF_MONO);
      rssBlockHover:
        DrawEdge(FBuffer.Canvas.Handle, FSelPos, EDGE_RAISED, BF_RECT);
      rssBlockDown:
        DrawEdge(FBuffer.Canvas.Handle, FSelPos, EDGE_SUNKEN, BF_RECT);
    else
      DrawEdge(FBuffer.Canvas.Handle, FSelPos, EDGE_ETCHED, BF_RECT);
    end;

    if not FReadyPos1.IsEmpty then DrawEdge(FBuffer.Canvas.Handle, FReadyPos1, EDGE_SUNKEN, BF_RECT);
    if not FReadyPos2.IsEmpty then DrawEdge(FBuffer.Canvas.Handle, FReadyPos2, EDGE_SUNKEN, BF_RECT);
    if not FReadyPos3.IsEmpty then DrawEdge(FBuffer.Canvas.Handle, FReadyPos3, EDGE_SUNKEN, BF_RECT);

    case FState of
      rssDisabled:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos1, EDGE_BUMP, BF_RECT or BF_MONO);
      rssThumb1Hover:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos1, EDGE_RAISED, BF_RECT);
      rssThumb1Down:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos1, EDGE_SUNKEN, BF_RECT);
    else
      DrawEdge(FBuffer.Canvas.Handle, FThumbPos1, EDGE_ETCHED, BF_RECT);
    end;

    case FState of
      rssDisabled:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos2, EDGE_BUMP, BF_RECT or BF_MONO);
      rssThumb2Hover:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos2, EDGE_RAISED, BF_RECT);
      rssThumb2Down:
        DrawEdge(FBuffer.Canvas.Handle, FThumbPos2, EDGE_SUNKEN, BF_RECT);
    else
      DrawEdge(FBuffer.Canvas.Handle, FThumbPos2, EDGE_ETCHED, BF_RECT);
    end;

  end;

//  FBuffer.Canvas.Brush.Color := clRed;
//  FBuffer.Canvas.FillRect(FReadyPos1);
//  FBuffer.Canvas.FillRect(FReadyPos2);

  SwapBuffers;
end;

procedure TRangeSelector.UpdateMetrics;
begin
  UpdateThumbMetrics;
  FBuffer.SetSize(Width, Height);
  FTrackPos := Rect(FThumbSize.cx, FThumbSize.cy + 2, Width - FThumbSize.cx, Height - FThumbSize.cy - 2);
  FSelPos := Rect(round(LogicalToScreen(FSelStart)),
                  FTrackPos.Top,
                  round(LogicalToScreen(FSelEnd)),
                  FTrackPos.Bottom);
  FReadyPos1.Empty;
  FReadyPos2.Empty;
  FReadyPos3.Empty;
  if FReadyEnd > 0 then if FReadyEnd > FSelStart then
   begin
      FReadyPos1 := Rect(round(LogicalToScreen(Fmin)),
                  FTrackPos.Top+4,
                  round(LogicalToScreen(FSelStart-1)),
                  FTrackPos.Bottom-4);
      if FReadyEnd > FSelEnd then
       begin
        FReadyPos2 := Rect(round(LogicalToScreen(FSelStart+1)),
                  FTrackPos.Top+4,
                  round(LogicalToScreen(FSelEnd-1)),
                  FTrackPos.Bottom-4);
        FReadyPos3 := Rect(round(LogicalToScreen(FSelEnd+1)),
                  FTrackPos.Top+4,
                  round(LogicalToScreen(FReadyEnd)),
                  FTrackPos.Bottom-4);

       end
      else FReadyPos2 := Rect(round(LogicalToScreen(FSelStart+1)),
                  FTrackPos.Top+4,
                  round(LogicalToScreen(FReadyEnd)),
                  FTrackPos.Bottom-4);
   end
  else FReadyPos1 := Rect(round(LogicalToScreen(Fmin)),
                  FTrackPos.Top+4,
                  round(LogicalToScreen(FReadyEnd)),
                  FTrackPos.Bottom-4);


  with FThumbPos1 do
  begin
    Top := 0;
    Left := round(LogicalToScreen(FSelStart) - FThumbSize.cx / 2);
    Right := Left + FThumbSize.cx;
    Bottom := Top + FThumbSize.cy;
  end;
  with FThumbPos2 do
  begin
    Top := Self.Height - FThumbSize.cy;
    Left := round(LogicalToScreen(FSelEnd) - FThumbSize.cx / 2);
    Right := Left + FThumbSize.cx;
    Bottom := Top + FThumbSize.cy;
  end;
end;

procedure TRangeSelector.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_SIZE:
      UpdateMetrics;
  end;
end;

procedure TRangeSelector.SetMax(Max: real);
begin
  if FMax <> Max then
  begin
    FMax := Max;
    UpdateMetrics;
    Paint;
  end;
end;

procedure TRangeSelector.SetMin(Min: real);
begin
  if FMin <> Min then
  begin
    FMin := Min;
    UpdateMetrics;
    Paint;
  end;
end;

procedure TRangeSelector.SetReadyEnd(const Value: real);
begin
  if (FReadyEnd <> Value) and IsRealInInterval(Value, FMin, FMax) then
  begin
    FReadyEnd := Value;
    UpdateMetrics;
    Paint;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRangeSelector.SetSelEnd(SelEnd: real);
begin
  if (FSelEnd <> SelEnd) and IsRealInInterval(SelEnd, FMin, FMax) then
  begin
    FSelEnd := SelEnd;
    if FSelStart > FSelEnd then
      FSelStart := FSelEnd;
    UpdateMetrics;
    Paint;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRangeSelector.SetSelStart(SelStart: real);
begin
  if (FSelStart <> SelStart) and IsRealInInterval(SelStart, FMin, FMax) then
  begin
    FSelStart := SelStart;
    if FSelStart > FSelEnd then
      FSelEnd := FSelStart;
    UpdateMetrics;
    Paint;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRangeSelector.SetState(State: TRangeSelectorState);
begin
  if State <> FState then
  begin
    FState := State;
    Paint;
  end;
end;

procedure TRangeSelector.SwapBuffers;
begin
  BitBlt(Canvas.Handle,
         0,
         0,
         Width,
         Height,
         FBuffer.Canvas.Handle,
         0,
         0,
         SRCCOPY);
end;

end.

