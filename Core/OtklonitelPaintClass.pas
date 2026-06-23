unit OtklonitelPaintClass;

interface

  uses
    GR32, GR32_Image,  GR32_VectorUtils, GR32_polygons, JDtools,
    Controls, Classes, StdCtrls, SysUtils, AVRTypes, math, RootImpl, actns, System.Types,
    JvInspector;

  type
  TOtkProbabData = record
   Dt: Real;
   Pr: Real;
   Color: TColor32;
  end;

  TOtklonitelPaint = class(TPaintBox32)
  private
    FPrbData: TPriborData;
    FColorShkala: TColor32;
    FColorFontAZO: TColor32;
    FColorLabel: TColor32;
    FColorOtkl: TColor32;
    FColorSector: TColor32;
    FOtklNeed: Real;
    FOtklDopusk: Real;
    FSectorPart: Real;
    FOtkText: String;
    FOtkTexTColor32: TColor32;
    FZenText: String;
    FZenTexTColor32: TColor32;
    FAziText: String;
    FAziTexTColor32: TColor32;
    FOtklCount: Integer;
    FOtklAngle: Real;
    FOtklRaiusPart: Real;
    FOtkl: array[0..10] of TOtkProbabData;
    FAO: array[0..10] of TOtkProbabData;
    FColorFontAZOE: TColor32;
    FColorAO: TColor32;
//    FColorOtkE: TColor32;
//    FColorAOE: TColor32;
    FColorFontAZOZ: TColor32;
    FColorOtklZamer: TColor32;
    FColorAOZamer: TColor32;
    FPorog: Double;
    procedure SetPrbData(const Value: TPriborData);
    procedure SeTColor32FontAZO(const Value: TColor32);
    procedure SeTColor32Label(const Value: TColor32);
    procedure SeTColor32Otkl(const Value: TColor32);
    procedure SeTColor32Sector(const Value: TColor32);
    procedure SeTColor32Shkala(const Value: TColor32);
    procedure SetOtklDopusk(const Value: Real);
    procedure SetOtklNeed(const Value: Real);
    procedure SetSectorPart(const Value: Real);
    procedure SetOtklAngle(const Value: Real);
    procedure SetOtklCount(const Value: Integer);
    procedure SetOtklRaiusPart(const Value: Real);
    procedure SeTColor32FontAZOE(const Value: TColor32);
    procedure SeTColor32AO(const Value: TColor32);
//    procedure SeTColor32AOE(const Value: TColor32);
//    procedure SeTColor32OtkE(const Value: TColor32);
    procedure SeTColor32FontAZOZ(const Value: TColor32);
    procedure SeTColor32AOZamer(const Value: TColor32);
    procedure SeTColor32OtklZamer(const Value: TColor32);
    function SetColorOrErrColor(c: TColor32; prb, porog: Double): TColor32;
  protected
    FRenderer: TPolygonRenderer32VPR;
    procedure DoPaintBuffer; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property C_Data: TPriborData read FPrbData write SetPrbData;
  published
    [ShowProp('отклонитель требуемый')] property OtklNeed: Real read FOtklNeed write SetOtklNeed;
    [ShowProp('отклонитель допуск')]property OtklDopusk: Real read FOtklDopusk write SetOtklDopusk;
    [ShowProp('отклонитель число')]property OtklCount: Integer read FOtklCount write SetOtklCount default 3;
    [ShowProp('OtklRaiusPart')] property OtklRaiusPart: Real read FOtklRaiusPart write SetOtklRaiusPart;
    [ShowProp('OtklAngle')] property OtklAngle: Real read FOtklAngle write SetOtklAngle;
    [ShowProp('SectorPart')] property SectorPart: Real read FSectorPart write SetSectorPart;
    [ShowProp('÷вет отклонител€ в статике')] property ColorOtklZamer: TColor32 read FColorOtklZamer write SeTColor32OtklZamer;
    [ShowProp('÷вет отклонител€')] property ColorOtkl: TColor32 read FColorOtkl write SeTColor32Otkl;
//    [ShowProp('÷вет отклонител€ с ошибкой')] property ColorOtkE: TColor32 read FColorOtkE write SeTColor32OtkE;
    [ShowProp('÷вет азимута отклонител€ в статике')] property ColorAOZamer: TColor32 read FColorAOZamer write SeTColor32AOZamer;
    [ShowProp('÷вет азимута отклонител€')] property ColorAO: TColor32 read FColorAO write SeTColor32AO;
  //  [ShowProp('÷вет азимута отклонител€ с ошибкой')] property ColorAOE: TColor32 read FColorAOE write SeTColor32AOE;
    [ShowProp('÷вет сектора')]property ColorSector: TColor32 read FColorSector write SeTColor32Sector;
    [ShowProp('ColorShkala')] property ColorShkala: TColor32 read FColorShkala write SeTColor32Shkala;
    [ShowProp('ColorLabel')] property ColorLabel: TColor32 read FColorLabel write SeTColor32Label;
    [ShowProp('ColorFontAZO')] property ColorFontAZO: TColor32 read FColorFontAZO write SeTColor32FontAZO;
    [ShowProp('ColorFontAZOE')] property ColorFontAZOE: TColor32 read FColorFontAZOE write SeTColor32FontAZOE;
    [ShowProp('ColorFontAZOZ')] property ColorFontAZOZ: TColor32 read FColorFontAZOZ write SeTColor32FontAZOZ;
  end;

//procedure Register;

implementation

{procedure Register;
begin
  RegisterComponents('Oleg', [TOtklonitelPaint]);
end;}

function AngleToPoint(Angle, Xs, Ys, R, dx, dy: Single): TFloatPoint;
 var
  A: Real;
begin
  A := DegToRad(Angle);
  Result.X := Xs + (R-dx/2)*Sin(A)-dx/2;
  Result.Y := Ys - (R-dy/2)*cos(A)-dy/2;
end;
{ TCustomOtklonitelPaint }

constructor TOtklonitelPaint.Create(AOwner: TComponent);
 var
  i: integer;
begin
  inherited Create(AOwner);
  FRenderer := TPolygonRenderer32VPR.Create(Buffer);
  FColorFontAZO := clBlue32;
  FColorFontAZOE := clBlue32;
  FColorFontAZOZ := clBlue32;
  FColorLabel := clBlack32;
  FColorOtkl := clRed32;
  FColorAO := clDarkRed32;
  FColorSector := clGreen32;
  FColorShkala := clNavy32;
  FColorOtklZamer := clGreen32;
  FColorAOZamer := clDarkGreen32;
  FPorog := 30;
  FSectorPart := 25;
  FOtklDopusk := 10;
  FOtklCount := 3;
  FOtklAngle := 7;
  FOtklRaiusPart := 50;
  Height := 200;
  Width := 200;
  FOtkText := '----';
  FZenText := '----';
  FAziText := '----';
  for i := 0 to 10 do FOtkl[i].Dt := -1;
  for i := 0 to 10 do FAO[i].Dt := -1;
end;

procedure TOtklonitelPaint.DoPaintBuffer;
 const
   DOTK = 7;
 var
  R, Dim, i: Integer;
//  x1,y1, x2,y2: Integer;
  sz: TSize;
  pp: TArrayOfFloatPoint;
  ppp: TArrayOfArrayOfFloatPoint;
  p1,p2: TFloatPoint;
  center: TFloatPoint;
  radius: Single;
  oneed, dopusk, wdth: Single;
  procedure paintOtk(const o: array of TOtkProbabData);// cnt: Integer; cl, clErr: TColor32);
   var
    i: Integer;
    p1,p2, p3: TFloatPoint;
    x1, x2: Single;
    c: TColor32;
  begin
    X1 := radius;
    for i := 0 to FOtklCount-1 do
     begin
      X2 := radius - radius*(i+1)/100 * FOtklRaiusPart/FOtklCount;//cnt;
      p1 := AngleToPoint(o[i].Dt, radius, radius, X1 , 0, 0);
      p2 := AngleToPoint(o[i].Dt-FOtklAngle, radius, radius, X2, 0, 0);
      p3 := AngleToPoint(o[i].Dt+FOtklAngle, radius, radius, X2, 0, 0);
      X1 := X2;
      c := SetColorOrErrColor(o[i].Color, o[i].Pr, FPorog);
      c := SetAlpha(c, AlphaComponent(c)-i*$10);
      if o[i].Dt<>-1 then
       begin
        FRenderer.Color := c;
        FRenderer.PolygonFS([p1, p2, p3]);
       end;
    end;
  end;
begin
  if not Assigned(Parent)  then Exit;

  with Buffer do
    begin
    Dim := Min(ClientRect.Width, ClientRect.Height);
    Buffer.Font.Size := Round(Dim*8/300);

    center := TFloatPoint.Create(Dim/2, Dim/2);
    radius := Dim/2;
    R := Round(radius);

    FillRect(0, 0, ClientRect.Width, ClientRect.Height, clWhite32);

    // сектор отклонител€
    oneed := DegToRad(FOtklNeed-90-FOtklDopusk/2);
    dopusk := DegToRad(FOtklDopusk);
    pp := Pie(center, radius,  dopusk, oneed);
    FRenderer.Color := FColorSector;
    FRenderer.PolygonFS(pp);
    pp := Pie(center, radius * (100 - FSectorPart)/100,  dopusk, oneed);
    FRenderer.Color := clWhite32;
    FRenderer.PolygonFS(pp);
    // shkala
    wdth :=  Round(2/300*Dim);
    for i := 0 to 35 do
     begin
      p1 := AngleToPoint(i*10, radius, radius, radius - Font.Size*2, 0, 0);
      if (i=0) or (i=9) or (i=18) or (i=27) then p2 := AngleToPoint(i*10, radius, radius, radius/1.5, 0, 0)
      else p2 := AngleToPoint(i*10, radius, radius, radius/1.2, 0, 0);
      ppp := ppp + [BuildPolyline([p1, p2], wdth)];

      sz := TextExtent(inttostr(i*10));
      p1 := AngleToPoint(i*10, radius, radius, radius, sz.cx, sz.cy);
      RenderText(Round(p1.X), Round(p1.Y), IntToStr(i*10), 1, FColorLabel);
     end;
    FRenderer.Color := FColorShkala;
    FRenderer.PolyPolygonFS(ppp);

    Font.Size := Round(Dim*16/300);
    sz := TextExtent('отклонитель');
    RenderText(r - sz.cx div 2, R - sz.cy, 'отклонитель', 1, FColorLabel);
    sz := TextExtent('зенит');
    RenderText(R - sz.cx div 2, R - 3 * sz.cy, 'зенит',1,  FColorLabel);
    sz := TextExtent('азимут');
    RenderText(R - sz.cx div 2, R + sz.cy, 'азимут', 1, FColorLabel);
    sz := TextExtent(FZenText);
    RenderText(R - sz.cx div 2, R - 2*sz.cy, FZenText, 1, FZenTexTColor32);
    sz := TextExtent(FOtkText);
    RenderText(R - sz.cx div 2, R , FOtkText, 1, FOtkTexTColor32);
    sz := TextExtent(FAziText);
    RenderText(R - sz.cx div 2, R + 2* sz.cy, FAziText, 1, FAziTexTColor32);

    paintOtk(FOtkl);//, FOtklCount, FColorOtkl, FColorOtkE);
    paintOtk(FAO);//, FOtklCount, FColorAO, FColorAOE);
   end;
  inherited;
end;

procedure TOtklonitelPaint.SeTColor32FontAZO(const Value: TColor32);
begin
  FColorFontAZO := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32Label(const Value: TColor32);
begin
  FColorLabel := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32Otkl(const Value: TColor32);
begin
  FColorOtkl := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32OtklZamer(const Value: TColor32);
begin
  FColorOtklZamer := Value;
  Paint;
end;

procedure TOtklonitelPaint.SeTColor32Sector(const Value: TColor32);
begin
  FColorSector := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32Shkala(const Value: TColor32);
begin
  FColorShkala := Value;
  Repaint;
end;

function TOtklonitelPaint.SetColorOrErrColor(c: TColor32; prb, porog: Double): TColor32;
begin
  if prb >= porog then Result := c
  else Result := SetAlpha(c, AlphaComponent(c) div 2);
  //  Color32(RedComponent(c), Round(GreenComponent(c)/1.1), Round(BlueComponent(c)/1.1));
end;

procedure TOtklonitelPaint.SetOtklAngle(const Value: Real);
begin
  FOtklAngle := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SetOtklDopusk(const Value: Real);
begin
  FOtklDopusk := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SetOtklNeed(const Value: Real);
begin
  FOtklNeed := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SetOtklCount(const Value: Integer);
begin
  if (Value <= 11) and (Value > 0) then FOtklCount := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SetOtklRaiusPart(const Value: Real);
begin
  FOtklRaiusPart := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SetPrbData(const Value: TPriborData);
 var
  i: integer;
begin
  FPrbData := Value;
  case FPrbData.DataType of
   dtOtklonitel:
    begin
     for i := 10 downto 1 do FOtkl[i] := FOtkl[i-1];
     FOtkl[0].Dt := FPrbData.Data;
     FOtkl[0].Pr := FPrbData.Probability;
     FOtkl[0].Color := ColorOtkl;
     FOtkText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FOtkTexTColor32 := FColorFontAZOE
     else FOtkTexTColor32 := FColorFontAZO;
    end;
   dtOtklonitelZamer:
    begin
     for i := 10 downto 1 do FOtkl[i] := FOtkl[i-1];
     FOtkl[0].Dt := FPrbData.Data;
     FOtkl[0].Pr := FPrbData.Probability;
     FOtkl[0].Color := ColorOtklZamer;
     FOtkText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FOtkTexTColor32 := FColorFontAZOE
     else FOtkTexTColor32 := FColorFontAZO;
    end;
   dtAO:
    begin
     for i := 10 downto 1 do FAO[i] := FAO[i-1];
     FAO[0].Dt := FPrbData.Data;
     FAO[0].Pr := FPrbData.Probability;
     FAO[0].Color := ColorAO;
    end;
   dtAOZamer:
    begin
     for i := 10 downto 1 do FAO[i] := FAO[i-1];
     FAO[0].Dt := FPrbData.Data;
     FAO[0].Pr := FPrbData.Probability;
     FAO[0].Color := ColorAOZamer;
    end;
   dtZenit:
    begin
     FZenText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FZenTexTColor32 := FColorFontAZOE
     else FZenTexTColor32 := FColorFontAZO;
    end;
   dtAzimut:
    begin
     FAziText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FAziTexTColor32 := FColorFontAZOE
     else FAziTexTColor32 := FColorFontAZO;
    end;
   dtZamerZenit:
    begin
     FZenText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FZenTexTColor32 := FColorFontAZOE
     else FZenTexTColor32 := FColorFontAZOZ;
    end;
   dtZamerAzimut:
    begin
     FAziText := Format('%2.1f',[FPrbData.Data]);
     if FPrbData.Probability <= 30 then FAziTexTColor32 := FColorFontAZOE
     else FAziTexTColor32 := FColorFontAZOZ;
    end;
   dtBadCode:
    begin
     FOtkText := '----';
     FZenText := '----';
     FAziText := '----';
     FAziTexTColor32 := FColorFontAZO;
     FZenTexTColor32 := FColorFontAZO;
     FOtkTexTColor32 := FColorFontAZO;
     for i := 0 to 10 do FOtkl[i].Dt := -1;
     for i := 0 to 10 do FAO[i].Dt := -1;
    end;
   dtNotZabur: for i := 0 to 10 do FAO[i].Dt := -1;
   end;
  Repaint;
end;

procedure TOtklonitelPaint.SetSectorPart(const Value: Real);
begin
  FSectorPart := Value;
  Repaint;
end;

destructor TOtklonitelPaint.Destroy;
begin
  TBindHelper.RemoveExpressions(Self);
  FRenderer.Free;
//  FBitmap.Free;
  inherited;
end;

procedure TOtklonitelPaint.SeTColor32FontAZOE(const Value: TColor32);
begin
  FColorFontAZOE := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32AO(const Value: TColor32);
begin
  FColorAO := Value;
  Repaint;
end;


procedure TOtklonitelPaint.SeTColor32AOZamer(const Value: TColor32);
begin
  FColorAOZamer := Value;
  Paint;
end;

{procedure TOtklonitelPaint.SeTColor32AOE(const Value: TColor32);
begin
  FColorAOE := Value;
  Repaint;
end;

procedure TOtklonitelPaint.SeTColor32OtkE(const Value: TColor32);
begin
  FColorOtkE := Value;
  Repaint;
end;}

procedure TOtklonitelPaint.SeTColor32FontAZOZ(const Value: TColor32);
begin
  FColorFontAZOZ := Value;
  Repaint;
end;

end.
