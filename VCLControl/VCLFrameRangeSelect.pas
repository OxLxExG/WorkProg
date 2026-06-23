unit VCLFrameRangeSelect;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,  tools,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RangeSelector, Vcl.StdCtrls, Vcl.Mask;

type
  TFrameRangeSelect = class(TFrame)
    Range: TRangeSelector;
    lbBegin: TLabel;
    lbEnd: TLabel;
    lbCnt: TLabel;
    edOtnBegin: TMaskEdit;
    edOtnEnd: TMaskEdit;
    edOtnCnt: TMaskEdit;
    edGlobBegin: TMaskEdit;
    edGlobEnd: TMaskEdit;
    lbKaBegin: TLabel;
    lbKaCnt: TLabel;
    lbKaEnd: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure RangeChange(Sender: TObject);
    procedure edOtnBeginKeyPress(Sender: TObject; var Key: Char);
    procedure edOtnCntKeyPress(Sender: TObject; var Key: Char);
    procedure edOtnEndKeyPress(Sender: TObject; var Key: Char);
    procedure edGlobBeginKeyPress(Sender: TObject; var Key: Char);
    procedure edGlobEndKeyPress(Sender: TObject; var Key: Char);
  private
    FKadrLen, FMaxKadr: Integer;
    FRamSize: Int64;
    FDelayStart: TDateTime;
    FOnChange: TProc;
    FLastWorkKadr: Integer;
    procedure SetLastWorkKadr(const Value: Integer);
  public
    kadr: record
     first, last, cnt: Integer;
    end;
    adr: record
     first, last, cnt: Int64;
    end;
    gtime: record
     first, last, cnt: TDateTime;
    end;
    otime: record
     first, last, cnt: TDateTime;
    end;
    procedure Init(KadrLen: Integer; RamSize: Int64; DelayStart: TDateTime; OnChange: TProc = nil); overload;
    procedure Init(KadrLen, KadrFirst, KadrLast: Integer; DelayStart: TDateTime; OnChange: TProc = nil); overload;
    procedure RunEnable(ena: Boolean);
//    property ADRFrom: Int64 read adr.first;
//    property ADRCnt: Int64 read adr.cnt;
    property LastWorkKadr: Integer read FLastWorkKadr write SetLastWorkKadr;
  end;

implementation

{$R *.dfm}

{ TFrameRangeSelect }

procedure TFrameRangeSelect.edGlobBeginKeyPress(Sender: TObject; var Key: Char);
 var
  e: Double;
begin
  if Key <> #$D then Exit; Key := #0;
  e := CTime.RoundToKadr(StrToDateTime(edGlobBegin.Text) - FDelayStart);
  if e > Range.Max then e := Range.Max;
  if e < Range.Min then e := Range.Min;
  Range.SelStart := e;
end;

procedure TFrameRangeSelect.edGlobEndKeyPress(Sender: TObject; var Key: Char);
 var
  e: Double;
begin
  if Key <> #$D then Exit; Key := #0;
  e := CTime.RoundToKadr(StrToDateTime(edGlobEnd.Text) - FDelayStart);
  if e > Range.Max then e := Range.Max;
  if e < Range.Min then e := Range.Min;
  Range.SelEnd := e;
end;

procedure TFrameRangeSelect.edOtnBeginKeyPress(Sender: TObject; var Key: Char);
 var
  e: Double;
begin
  if Key <> #$D then Exit; Key := #0;
  e := CTime.RoundToKadr(CTime.FromString(edOtnBegin.Text));
  if e > Range.Max then e := Range.Max;
  if e < Range.Min then e := Range.Min;
  Range.SelStart := e;
end;

procedure TFrameRangeSelect.edOtnCntKeyPress(Sender: TObject; var Key: Char);
 var
  e: Double;
begin
  if Key <> #$D then Exit; Key := #0;
  e := Range.SelStart + CTime.RoundToKadr(CTime.FromString(edOtnCnt.Text));
  if e > Range.Max then e := Range.Max;
  if e < Range.Min then e := Range.Min;
  Range.SelEnd := e;
end;

procedure TFrameRangeSelect.edOtnEndKeyPress(Sender: TObject; var Key: Char);
 var
  e: Double;
begin
  if Key <> #$D then Exit; Key := #0;
  e := CTime.RoundToKadr(CTime.FromString(edOtnEnd.Text));
  if e > Range.Max then e := Range.Max;
  if e < Range.Min then e := Range.Min;
  Range.SelEnd := e;
end;

procedure TFrameRangeSelect.Init(KadrLen, KadrFirst, KadrLast: Integer; DelayStart: TDateTime; OnChange: TProc);
begin
  FKadrLen := KadrLen;
  FMaxKadr := KadrLast;
  FDelayStart := DelayStart;
  FOnChange := OnChange;
  FLastWorkKadr := FMaxKadr;
  Range.Max := FMaxKadr;
  Range.Min := KadrFirst;
  Range.SelStart := KadrFirst;
  Range.SelEnd := KadrFirst;
  Range.ReadyEnd := FLastWorkKadr;
  if Assigned(FOnChange) then FOnChange();
end;


procedure TFrameRangeSelect.Init(KadrLen: Integer; RamSize: Int64; DelayStart: TDateTime; OnChange: TProc = nil);
 var
  TimMaxKadr: Integer;
begin
  FKadrLen := KadrLen;
  FRamSize := RamSize;
  FMaxKadr := RamSize div FKadrLen;
  FDelayStart := DelayStart;
  FOnChange := OnChange;
  FLastWorkKadr := FMaxKadr;
  if FDelayStart > 0 then
   begin
    TimMaxKadr := Ctime.ToKadr(Now - FDelayStart);
    if TimMaxKadr < FMaxKadr then FLastWorkKadr := TimMaxKadr;
   end;
  if FMaxKadr / FLastWorkKadr > 10 then FMaxKadr := FLastWorkKadr*10;

  Range.Max := FMaxKadr;
  Range.ReadyEnd := FLastWorkKadr;

  Range.SelStart := 0;
  Range.SelEnd := FLastWorkKadr;

  if Assigned(FOnChange) then FOnChange();
end;

procedure TFrameRangeSelect.RangeChange(Sender: TObject);
  function DeleteZnak(const s: string): string;
  begin
    Result := s.Trim;
    if not Result.Contains(' ') then Result := ' ' + Result;
  end;
  function AddSpace(const s: string): string;
  begin
    Result := s.Trim;
    if not Result.Contains(' ') then Result := Result + ' 00:00:00';
  end;
begin
  kadr.first := Round(Range.SelStart);
  kadr.last := Round(Range.SelEnd);
  kadr.cnt := kadr.last - kadr.first;
  adr.first := Int64(kadr.first) * FKadrLen;
  adr.cnt := Int64(kadr.cnt) * FKadrLen;
  adr.last := Int64(kadr.last) * FKadrLen;
  otime.first := CTime.FromKadr(kadr.first);
  otime.last := CTime.FromKadr(kadr.last);
  otime.cnt := CTime.FromKadr(kadr.cnt);
  gtime.first := otime.first + FDelayStart;
  gtime.last := otime.last + FDelayStart;
  gtime.cnt := otime.cnt + FDelayStart;
  edOtnBegin.Text := DeleteZnak(CTime.AsString(otime.first));
  edOtnCnt.Text := DeleteZnak(CTime.AsString(otime.cnt));
  edOtnEnd.Text := DeleteZnak(CTime.AsString(otime.last));
  edGlobBegin.Text := AddSpace(DateTimeToStr(gtime.first));
//  edGlobCnt.Text := DateTimeToStr(gtime.cnt);
  edGlobEnd.Text := AddSpace(DateTimeToStr(gtime.last));
  lbKaBegin.Caption := kadr.first.ToString;
  lbKaEnd.Caption := kadr.last.ToString;
  lbKaCnt.Caption := kadr.cnt.ToString;
//  lbBegin.Caption:= Format('Начало %8d %11d %11s %15s',[kadr.first, adr.first, ctime.AsString(otime.first), DateTimeToStr(gtime.first)]);
//  lbEnd.Caption:=   Format('Конец  %8d %11d %11s %15s',[kadr.last, adr.last, ctime.AsString(otime.last), DateTimeToStr(gtime.last)]);
//  lbCnt.Caption:=   Format('Кол-во %8d %11d %11s %15s',[kadr.cnt, adr.cnt, ctime.AsString(otime.cnt), DateTimeToStr(gtime.cnt)]);
//  lbBegin.Caption:= Format('Начало %8d %11s %s',[kadr.first, ctime.AsString(otime.first), DateTimeToStr(gtime.first)]);
//  lbEnd.Caption:=   Format('Конец  %8d %11s %s',[kadr.last, ctime.AsString(otime.last), DateTimeToStr(gtime.last)]);
//  lbCnt.Caption:=   Format('Кол-во %8d %11s %s',[kadr.cnt, ctime.AsString(otime.cnt), DateTimeToStr(gtime.cnt)]);
//  lbBegin.Caption:= Format('Начало %11s %s',[ctime.AsString(otime.first), DateTimeToStr(gtime.first)]);
//  lbEnd.Caption:=   Format('Конец  %11s %s',[ctime.AsString(otime.last), DateTimeToStr(gtime.last)]);
//  lbCnt.Caption:=   Format('Кол-во %11s %s',[ctime.AsString(otime.cnt), DateTimeToStr(gtime.cnt)]);
  if Assigned(FOnChange) then FOnChange();
end;

procedure TFrameRangeSelect.RunEnable(ena: Boolean);
begin
  Enabled   := ena;
//  Range.Enabled   := ena;
//  lbBegin.Enabled := ena;
//  lbEnd.Enabled   := ena;
//  lbCnt.Enabled   := ena;
end;

procedure TFrameRangeSelect.SetLastWorkKadr(const Value: Integer);
begin
  FLastWorkKadr := Value;
  Range.ReadyEnd := FLastWorkKadr;
  if Assigned(FOnChange) then FOnChange();
end;

initialization
  RegisterClass(TFrameRangeSelect);


end.
