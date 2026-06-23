unit VCLJDtypeClolor;

interface

uses JDtools, System.UITypes, VCL.JDType.Form,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, JvExControls, JvInspector, JvComponentBase;

type
  TFormSetColor = class(TJDTypeForm<TColor>)
    R: TScrollBar;
    G: TScrollBar;
    B: TScrollBar;
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

procedure TFormSetColor.AfteSetData;
begin
  inherited;
  TColorRec(FEditData).A := 0;
  R.Position := TColorRec(FEditData).R;
  G.Position := TColorRec(FEditData).G;
  B.Position := TColorRec(FEditData).B;
end;

procedure TFormSetColor.RChange(Sender: TObject);
 var
  c: TColorRec;
begin
  c.R := R.Position;
  c.G := G.Position;
  c.B := B.Position;
  EditData := c.Color;
end;


type
  TInspColorItem = class(TJvCustomInspectorItem)
  protected
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure DrawValue(const ACanvas: TCanvas); override;
    procedure Edit; override;
    procedure InitEdit; override;
    procedure DoneEdit(const CancelEdits: Boolean = False); override;
  end;


constructor TInspColorItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspColorItem.DrawValue(const ACanvas: TCanvas);
begin
  if not Data.HasValue then Exit;
  ACanvas.Brush.Color :=  Cardinal(Data.AsOrdinal);
  ACanvas.FillRect(Rects[iprValueArea]);
  if Editing then DrawEditor(ACanvas);
end;

procedure TInspColorItem.Edit;
begin
  TFormSetColor.execute(Tcontrol(Inspector.Owner).ClientToScreen(Rects[iprEditButton].TopLeft), TColor(Data.AsOrdinal),
  procedure (c: TColor)
  begin
    Data.AsOrdinal := c;
  end);
end;

procedure TInspColorItem.DoneEdit(const CancelEdits: Boolean);
begin
  SetEditing(False);
end;

procedure TInspColorItem.InitEdit;
begin
  SetEditing(CanEdit);
end;

initialization
  with TJvCustomInspectorData.ItemRegister do
   begin
    Add(TJvInspectorTypeInfoRegItem.Create(TInspColorItem, TypeInfo(TColor)));
   end;
end.
