unit SetGPClolor;

interface

uses JDtools, System.UITypes,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, //Winapi.GDIPAPI, WinAPI.GDIPObj,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, JvExControls, JvInspector, JvComponentBase;

type
  TFormSetGPColor = class(TForm)
    R: TScrollBar;
    G: TScrollBar;
    B: TScrollBar;
    A: TScrollBar;
    Timer1: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    procedure RChange(Sender: TObject);
    procedure FormMouseLeave(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormMouseEnter(Sender: TObject);
  private
   FRes: Tproc<TAlphaColor>;
  public
   class procedure Execute(ALeftTop: TPoint; c: TAlphaColor; func: Tproc<TAlphaColor>);
  end;

  TInspGPColorItem = class(TJvCustomInspectorItem)
  protected
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure DrawValue(const ACanvas: TCanvas); override;
    procedure Edit; override;
    procedure InitEdit; override;
    procedure DoneEdit(const CancelEdits: Boolean = False); override;
  end;


implementation

{$R *.dfm}


constructor TInspGPColorItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspGPColorItem.DrawValue(const ACanvas: TCanvas);
 var
  c: TAlphaColorRec;
begin
  if not Data.HasValue then Exit;
  c.Color := Cardinal(Data.AsOrdinal);
  ACanvas.Brush.Color :=  RGB(c.R, c.G, c.B);
  ACanvas.FillRect(Rects[iprValueArea]);
  if Editing then DrawEditor(ACanvas);
end;

procedure TInspGPColorItem.Edit;
begin
  TFormSetGPColor.execute(Tcontrol(Inspector.Owner).ClientToScreen(Rects[iprEditButton].TopLeft), TAlphaColor(Data.AsOrdinal),
  procedure (c: TAlphaColor)
  begin
    Data.AsOrdinal := c;
  end);
end;

procedure TInspGPColorItem.DoneEdit(const CancelEdits: Boolean);
begin
  SetEditing(False);
end;

procedure TInspGPColorItem.InitEdit;
begin
  SetEditing(CanEdit);
end;

{ TFormSetGPColor }

class procedure TFormSetGPColor.Execute(ALeftTop: TPoint; c: TAlphaColor; func: Tproc<TAlphaColor>);
begin
  with Create(nil) do
   begin
    Left := ALeftTop.X;
    Top := ALeftTop.Y;
    R.Position := TAlphaColorRec(c).R;
    G.Position := TAlphaColorRec(c).G;
    B.Position := TAlphaColorRec(c).B;
    A.Position := TAlphaColorRec(c).A;
    FRes := func;
    Show;
    SetFocus;
   end;
end;

procedure TFormSetGPColor.FormMouseEnter(Sender: TObject);
begin
  Timer1.Enabled := False;
end;

procedure TFormSetGPColor.FormMouseLeave(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TFormSetGPColor.RChange(Sender: TObject);
 var
  c: TAlphaColorRec;
begin
  if Assigned(FRes) then
   begin
    c.A := a.Position;
    c.R := r.Position;
    c.G := g.Position;
    c.B := b.Position;
    FRes(TAlphaColor(c));
   end;
end;

procedure TFormSetGPColor.Timer1Timer(Sender: TObject);
begin
  Free;
end;

initialization
  with TJvCustomInspectorData.ItemRegister do
   begin
//    Add(TJvInspectorTypeInfoRegItem.Create(TInspGPColorItem, TypeInfo(TGPColor)));
    Add(TJvInspectorTypeInfoRegItem.Create(TInspGPColorItem, TypeInfo(TAlphaColor)));
//    Add(TJvInspectorTypeInfoRegItem.Create(TInspGPColorItem, TypeInfo(TColor32)));
   end;
end.
