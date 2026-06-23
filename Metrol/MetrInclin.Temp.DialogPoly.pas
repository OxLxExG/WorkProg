unit MetrInclin.Temp.DialogPoly;

interface

uses  DockIForm, ExtendIntf, System.TypInfo, RootImpl, PluginAPI, MetrInclin.Temp.FormPoly, MetrInclin.Temp.Stat,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

  const
   STAT_FMT =  'Accel: %d %1.2f%% av: %1.3f%%     Magnit: %d %1.2f%% av: %1.3f%%     Ink:   %d %1.2f av: %1.3f'#$D#$A
              +'Çåíèò: %d %1.2f°  av: %1.3f°     Àçèìóò: %d %1.2f° av: %1.3f°     Âèçèð: %d %1.2f°av: %1.3f°';
type
  TDialogPoly = class(TDialogIForm, IDialog, IDialog<TFormMetrInclinTP>)
    btnClose: TButton;
    btnRunAmp: TButton;
    btnLS: TButton;
    mmo: TMemo;
    pb: TPanel;
    btnLMZU: TButton;
    chkV: TCheckBox;
    chkZ: TCheckBox;
    chkA: TCheckBox;
    btnClr: TButton;
    btnT: TButton;
    btnKos: TButton;
    btnKosv2: TButton;
    btnClrSe: TButton;
    procedure btnRunAmpClick(Sender: TObject);
    procedure btnLSClick(Sender: TObject);
    procedure btnLMZUClick(Sender: TObject);
    procedure chkVClick(Sender: TObject);
    procedure chkZClick(Sender: TObject);
    procedure chkAClick(Sender: TObject);
    procedure btnClrClick(Sender: TObject);
    procedure btnTClick(Sender: TObject);
    procedure btnKosClick(Sender: TObject);
    procedure btnKosv2Click(Sender: TObject);
    procedure btnClrSeClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    owner: TFormMetrInclinTP;
    procedure PrintRes(const Alg: string);
  public
    function GetInfo: PTypeInfo; override;
    function Execute(frm: TFormMetrInclinTP): Boolean;
  end;

implementation

uses  MetrInclin.Temp.MathPoly, LuaInclin.Temp.Poly;

{$R *.dfm}

procedure TDialogPoly.btnCloseClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize('Metrolog', 'TempPoly');
end;

procedure TDialogPoly.btnClrClick(Sender: TObject);
begin
  mmo.Lines.Clear;
end;

procedure TDialogPoly.btnClrSeClick(Sender: TObject);
begin
  TpolyMath.ClearStolError
end;

procedure TDialogPoly.btnTClick(Sender: TObject);
begin
  TpolyMath.RunT;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('T');
end;

procedure TDialogPoly.btnKosClick(Sender: TObject);
begin
  TpolyMath.RunKoso;
  TpolyMath.KosoToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(true);
  PrintRes('KOSO');
end;

procedure TDialogPoly.btnKosv2Click(Sender: TObject);
begin
  TpolyMath.RunKosoV2;
  TpolyMath.KosoToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(true);
  PrintRes('KOSO V2');
end;

procedure TDialogPoly.btnLMZUClick(Sender: TObject);
begin
  TpolyMath.RunZ;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(false);
  PrintRes('LMZU');
end;

procedure TDialogPoly.btnLSClick(Sender: TObject);
begin
   TpolyMath.RunLS;
   TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
   owner.RecalcResultAndUpdateTree(False);
   PrintRes('LS');
end;

procedure TDialogPoly.btnRunAmpClick(Sender: TObject);
begin
  TpolyMath.RunAmp;
  TpolyMath.ResultToXML(owner.CurrentTrr, TpolyMath.Res.G, TpolyMath.Res.H);
  owner.RecalcResultAndUpdateTree(False);
  PrintRes('AMP');
end;


procedure TDialogPoly.chkAClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolMagnit := chkA.Checked;
end;

procedure TDialogPoly.chkVClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolVisir := chkV.Checked;
end;

procedure TDialogPoly.chkZClick(Sender: TObject);
begin
 TpolyMath.SetupData.CorStolZenit := chkZ.Checked;
end;

function TDialogPoly.Execute(frm: TFormMetrInclinTP): Boolean;
begin
  Result := True;
  owner := frm;
  IShow;
end;

function TDialogPoly.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_Text_Init);
end;

procedure TDialogPoly.PrintRes(const Alg: string);
 const
  SE = 'incl: %7.3f     azi: %7.3f   viz: %7.3f '+#$D#$A+
       'Zen : %7.3f  AziZen: %7.1f'    ;
begin
  mmo.Lines.Add('**************'+Alg+'***************');
  var s := 'Correction:';
  if chkV.Checked then s := s+' Visir';
  if chkZ.Checked then s := s+' Zenit';
  if chkA.Checked then s := s+' Magnit';
  if s <> 'Correction:' then mmo.Lines.Add(s);

  mmo.Lines.Add(TpolyMath.EStatToStr(STAT_FMT));
  mmo.Lines.Add('------------îøèáêà ñòîëà-------------');
  var e := TpolyMath.eStol;
  mmo.Lines.Add(Format(SE,[e.cNakl,e.cAzi,e.cVis,e.cZenA, e.cZenAng]));
  mmo.Lines.Add('');
end;


initialization
  RegisterDialog.Add<TDialogPoly, Dialog_Text_Init>('Metrolog', 'TempPoly');
finalization
  RegisterDialog.Remove<TDialogPoly>;
end.
