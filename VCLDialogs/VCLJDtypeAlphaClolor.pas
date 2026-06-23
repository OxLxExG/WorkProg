unit VCLJDtypeAlphaClolor;

interface

uses JDtools, System.UITypes, VCL.JDType.Form,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, JvExControls, JvInspector, JvComponentBase;

type
  TFormSetAlphaColor = class(TJDTypeForm<TAlphaColor>)
    R: TScrollBar;
    G: TScrollBar;
    B: TScrollBar;
    A: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    procedure RChange(Sender: TObject);
  protected
    procedure AfteSetData; override;
  end;

implementation

{$R *.dfm}

{ TFormSetGPColor }

procedure TFormSetAlphaColor.AfteSetData;
begin
  R.Position := TAlphaColorRec(FEditData).R;
  G.Position := TAlphaColorRec(FEditData).G;
  B.Position := TAlphaColorRec(FEditData).B;
  A.Position := TAlphaColorRec(FEditData).A;
end;

procedure TFormSetAlphaColor.RChange(Sender: TObject);
 var
  c: TAlphaColorRec;
begin
  c.A := a.Position;
  c.R := r.Position;
  c.G := g.Position;
  c.B := b.Position;
  EditData := TAlphaColor(c);
end;


type
  TInspAlphaColorItem = class(TJvCustomInspectorItem)
  protected
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure DrawValue(const ACanvas: TCanvas); override;
    procedure Edit; override;
    procedure InitEdit; override;
    procedure DoneEdit(const CancelEdits: Boolean = False); override;
  end;


constructor TInspAlphaColorItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspAlphaColorItem.DrawValue(const ACanvas: TCanvas);
 var
  c: TAlphaColorRec;
begin
  if not Data.HasValue then Exit;
  c.Color := Cardinal(Data.AsOrdinal);
  ACanvas.Brush.Color :=  RGB(c.R, c.G, c.B);
  ACanvas.FillRect(Rects[iprValueArea]);
  if Editing then DrawEditor(ACanvas);
end;

procedure TInspAlphaColorItem.Edit;
begin
  TFormSetAlphaColor.execute(Tcontrol(Inspector.Owner).ClientToScreen(Rects[iprEditButton].TopLeft), TAlphaColor(Data.AsOrdinal),
  procedure (c: TAlphaColor)
  begin
    Data.AsOrdinal := c;
  end);
end;

procedure TInspAlphaColorItem.DoneEdit(const CancelEdits: Boolean);
begin
  SetEditing(False);
end;

procedure TInspAlphaColorItem.InitEdit;
begin
  SetEditing(CanEdit);
end;

initialization
  with TJvCustomInspectorData.ItemRegister do
   begin
    Add(TJvInspectorTypeInfoRegItem.Create(TInspAlphaColorItem, TypeInfo(TAlphaColor)));
   end;
end.
