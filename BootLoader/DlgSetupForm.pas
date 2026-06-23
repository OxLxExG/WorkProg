unit DlgSetupForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TChip = record
    Chip: Integer;
    Recs: Integer;
    InfoStart: Integer;
    Pages: Integer;
    Info: string;
    cbIndex: Integer;
    adr_sz: Integer;
    flash_begin: DWORD;
    constructor Create(AChip: Integer; ARecs: Integer; AInfoStart: Integer; APages: Integer; const Ainfo: string;
    adrsz: Integer; flashbegin: DWORD=0);
  end;
  TChips = TArray<TChip>;

  TDlgSetupAdr = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    cb: TComboBox;
    Label2: TLabel;
    edAdr: TEdit;
    Label3: TLabel;
    edSerial: TEdit;
    Label4: TLabel;
    Label1: TLabel;
    Label5: TLabel;
    edSubAdr: TEdit;
    Label6: TLabel;
    procedure rgClick(Sender: TObject);
  private
    { Private declarations }
  public
   class function Execute(var adr, subAdr, chip, serial: Integer; const Chips: TChips): Boolean;
  end;

implementation

{$R *.dfm}

{ TChip }

constructor TChip.Create(AChip, ARecs, AInfoStart, APages: Integer; const Ainfo: string; adrsz: Integer; flashbegin: DWORD);
begin
  Chip := AChip;
  Recs := ARecs;
  InfoStart := AInfoStart;
  Pages := APages;
  info := Ainfo;
  adr_sz := adrsz;
  flash_begin := flashbegin;
end;


class function TDlgSetupAdr.Execute(var adr, subAdr, chip, serial: Integer; const Chips: TChips): Boolean;
 var
  ch: TChip;
begin
  with TDlgSetupAdr.Create(nil) do
   try
    edAdr.Text := IntToStr(adr);
    edSerial.Text := IntToStr(serial);
    edSubAdr.Text := IntToHex(subAdr,2);
    for ch in Chips do
     if ch.Chip = chip then cb.ItemIndex := cb.Items.Add(ch.Info)
     else cb.Items.Add(ch.Info);
    if ShowModal = mrOk then
     begin
      adr := StrToInt(edAdr.Text);
      serial := StrToInt(edSerial.Text);
      subAdr := StrToInt('$'+edSubAdr.Text);
      if cb.ItemIndex >= 0 then chip := Chips[cb.ItemIndex].Chip
      else chip := -1;
      Result := True;
     end
    else Result := False;
   finally
    Free;
   end;
end;

procedure TDlgSetupAdr.rgClick(Sender: TObject);
begin
//
end;

end.
