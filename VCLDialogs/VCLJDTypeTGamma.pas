unit VCLJDTypeTGamma;

interface

uses  VCL.JDType.Form, CustomPlot, JvExControls, JvInspector, JvComponentBase, JDtools, debug_except,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, GR32_ColorPicker, GR32_Image, GR32;

type
  TJDTypeFormGamma = class(TJDTypeForm<TGammaProp>)
    tbPlus: TTrackBar;
    tbMinus: TTrackBar;
    clTop: TColorPickerGTK;
    clBot: TColorPickerGTK;
    pb: TPaintBox32;
    Bevel1: TBevel;
    procedure AllChange(Sender: TObject);
    procedure AllDropDown(Sender: TObject);
    procedure AllCloseUp(Sender: TObject);
    procedure pbPaintBuffer(Sender: TObject);
  private
    procedure SetGamma(const Value: TGamma);
    function GetGamma: TGamma;
    procedure UpdateGamma;
    procedure PaintBuffer;
  protected
    procedure AfteSetData; override;
    procedure DoDataChanged; override;
  public
    property Gamma: TGamma read GetGamma write SetGamma;
    class function StrToGamma(const StrGamma: string): TGamma;
  end;

implementation

{$R *.dfm}

procedure TJDTypeFormGamma.AfteSetData;
begin
  inherited;
  clTop.SelectedColor := Tcolor32(Gamma[ShortInt.MaxValue]);
  tbPlus.Position := 255 - Gamma[0] shr 24;
  tbMinus.Position := Gamma[-1] shr 24;
  clBot.SelectedColor := Tcolor32(Gamma[ShortInt.MinValue]);
  PaintBuffer;
end;

procedure TJDTypeFormGamma.DoDataChanged;
begin
  if SetData then Exit;
  UpdateGamma;
  inherited;
  PaintBuffer;
end;

function TJDTypeFormGamma.GetGamma: TGamma;
begin
  Result := StrToGamma(string(FEditData));
end;

procedure TJDTypeFormGamma.PaintBuffer;
 var
  i, pbw: Integer;
  g: TGamma;
begin
  g := Gamma;
  pbw := pb.Width;
  pb.Buffer.FillRect(0, 0, pbw, pb.Height, clWhite32);
  if not Assigned(pb.Buffer.bits) then Exit;  for I := 0 to 255 do pb.Buffer.HorzLineT(0, i, pbw, TColor32(g[i-128]));
  pb.Repaint;
end;

procedure TJDTypeFormGamma.pbPaintBuffer(Sender: TObject);
begin
  PaintBuffer;
end;

procedure TJDTypeFormGamma.SetGamma(const Value: TGamma);
 var
  c: TColor;
begin
  FEditData := '';
  for c in Value do FEditData := FEditData + ','+ IntToHex(c, 4);
end;

class function TJDTypeFormGamma.StrToGamma(const StrGamma: string): TGamma;
 var
  i: Integer;
  a: TArray<string>;
begin
  a := StrGamma.Split([','], TStringSplitOptions.ExcludeEmpty);
  if Length(a) <> 256 then raise Exception.Create('Error Message');
  for i := 0 to 255 {Min(255, High(a))} do Result[i-128] :=('$'+a[i]).ToInteger;
end;

procedure TJDTypeFormGamma.UpdateGamma;
 var
  i, pbw: Integer;
  g: TGamma;
  Kminus, KPlus: Double;
  function FindAlphaPlus(GammaIndex: ShortInt): Integer;
  begin
    Result := Round(TColor32Entry(clTop.SelectedColor).A - KPlus*GammaIndex);
  //  TDebug.Log('%x',[Result]);
    if Result > 255 then Result := 255;
    if Result < 0 then Result := 0;
  end;
  function FindAlphaMinus(GammaIndex: ShortInt): Integer;
  begin
    Result := Round(TColor32Entry(clBot.SelectedColor).A - Kminus*GammaIndex);
    if Result > 255 then Result := 255;
    if Result < 0 then Result := 0;
  //  TDebug.Log('%x',[Result]);
  end;
begin
  Kminus := (TColor32Entry(clBot.SelectedColor).A - (tbMinus.Position)) / 128;
  //TDebug.Log('%x',[TColor32Entry(clBot.SelectedColor).A]);
  KPlus := (TColor32Entry(clTop.SelectedColor).A - (255-tbPlus.Position)) / 128;
  //TDebug.Log('PLUS: %x, %1.3f MIUS: %x, %1.3f',[tbPlus.Position, KPlus, tbMinus.Position, Kminus]);
  for I := 0 to 127 do
   begin
   //+
    g[127-i]     := Integer(SetAlpha(clTop.SelectedColor, FindAlphaPlus(i)));
   //-
    g[i-128] := Integer(SetAlpha(clBot.SelectedColor, FindAlphaMinus(i)));
   end;
  Gamma := g;
end;

procedure TJDTypeFormGamma.AllChange(Sender: TObject);
begin
  DoDataChanged;
end;

procedure TJDTypeFormGamma.AllCloseUp(Sender: TObject);
begin
  FCanClose := True;
end;

procedure TJDTypeFormGamma.AllDropDown(Sender: TObject);
begin
  FCanClose := False;
end;

type
  TInspGammaItem = class(TJvCustomInspectorItem)
  protected
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure DrawValue(const ACanvas: TCanvas); override;
    procedure Edit; override;
    procedure InitEdit; override;
    procedure DoneEdit(const CancelEdits: Boolean = False); override;
  end;


constructor TInspGammaItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspGammaItem.DrawValue(const ACanvas: TCanvas);
 var
  g: TGamma;
  b: TBitmap32;
  r: TRect;
  i: Integer;
//  sb: TGPSolidBrush;
begin
//  inherited;
  if not Data.HasValue then Exit;
  g := TJDTypeFormGamma.StrToGamma(Data.AsString);
  r := Rects[iprValueArea];
  b := TBitmap32.Create();
  try
   b.SetSize(256, r.Height);
   b.FillRect(0, 0, 255, r.Height, clWhite32);
   for i := 0 to 255 do b.VertLineT(i, 0, r.Height, TColor32(g[i-128]));
   b.DrawTo(ACanvas.Handle, r, b.BoundsRect);
   if  Editing then DrawEditor(ACanvas);
  finally
   b.Free;
  end;
end;

procedure TInspGammaItem.Edit;
begin
  TJDTypeFormGamma.execute(Tcontrol(Inspector.Owner).ClientToScreen(Rects[iprEditButton].TopLeft), TGammaProp(Data.AsString),
  procedure (c: TGammaProp)
  begin
    Data.AsString := c;
  end);
end;

procedure TInspGammaItem.DoneEdit(const CancelEdits: Boolean);
begin
  SetEditing(False);
end;

procedure TInspGammaItem.InitEdit;
begin
  SetEditing(CanEdit);
end;

initialization
  with TJvCustomInspectorData.ItemRegister do
   begin
     Add(TJvInspectorTypeInfoRegItem.Create(TInspGammaItem, TypeInfo(TGammaProp)));
   end;
end.
