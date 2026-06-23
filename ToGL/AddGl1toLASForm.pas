unit AddGl1toLASForm;

interface

uses System.IOUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, LasDataSet, DataSetIntf,
  LAS, FileDataSet,  LasImpl,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, JvExMask, JvToolEdit, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.ComCtrls;

type
  TFormAddGl1ToLAS = class(TForm)
    fneLAS: TJvFilenameEdit;
    fneGL1: TJvFilenameEdit;
    lLas: TLabel;
    lGl: TLabel;
    dbgLas: TDBGrid;
    btRUN: TButton;
    dsLAS: TDataSource;
    dsGL1: TDataSource;
    pc: TPageControl;
    tshLAS: TTabSheet;
    tshGL: TTabSheet;
    dbgGl: TDBGrid;
    edDelta: TEdit;
    ldDelta: TLabel;
    procedure fneLASAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure fneGL1AfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure btRUNClick(Sender: TObject);
  private
    Lds: TLasDataSet;
    Fds: TFileDataSet;

  public
    { Public declarations }
  end;

var
  FormAddGl1ToLAS: TFormAddGl1ToLAS;

implementation

{$R *.dfm}

procedure TFormAddGl1ToLAS.btRUNClick(Sender: TObject);
var
 from: Integer;
 fldKadr: TField;
 fldGl: TField;
begin
  if Fds.Active then
   begin
    from := StrToInt(edDelta.Text);

    dsGL1.DataSet := nil;

    Fds.First;

    fldKadr := Fds.FieldByName('kadr');
    fldGl := Fds.FieldByName('glsm');

    repeat
     var kdr := fldKadr.AsInteger;
     if kdr >= from then
      begin
        from := kdr;
        Break;
      end;
      Fds.Next;
    until Fds.Eof;

    Lds.Close;

    var pl := Lds.LasDoc.Curve.Items['GL1'];
    if not Assigned(pl) then
    begin
     Lds.LasDoc.Curve.Add(TLasFormat.Create('GL1','sm','','Depth sm'));
     Lds.UpdateFields();
    end;
    var nul := Double(Lds.LasDoc.Well.Items['NULL'].Value);
    for var i := 0 to Lds.LasDoc.DataCount-1 do
     begin
      if (i < from) or Fds.Eof then Lds.LasDoc['GL1', i] := nul
      else
       begin
        Lds.LasDoc['GL1', i] := fldGl.AsInteger/100;
        Fds.Next;
       end;
     end;
    var fn := Tpath.GetFileNameWithoutExtension(Lds.LasDoc.FileName);
    var fp := ExtractFilePath(Lds.LasDoc.FileName);
    Lds.LasDoc.SaveToFile(fp + fn + '_GL1.las');
    Lds.Open;
    dsGL1.DataSet := Fds;
   end;
end;

procedure TFormAddGl1ToLAS.fneGL1AfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
 var
  ffd: TFileFieldDef;
begin
    if Assigned(Fds)then
     begin
      Fds.Close;
      FreeAndNil(Fds);
     end;
    Fds := TFileDataSet.Create;
    Fds.FieldDefs.Add('ID',ftInteger);

    ffd := TFileFieldDef(Fds.FieldDefs.AddFieldDef);
    ffd.DataOffset := 0;
    ffd.DataType := ftInteger;
    ffd.Name := 'kadr';

    ffd := TFileFieldDef(Fds.FieldDefs.AddFieldDef);
    ffd.DataOffset := 4;
    ffd.DataType := ftInteger;
    ffd.Name := 'glsm';

    Fds.BinFileName := AName;
    Fds.RecordLength := 8;

    dsGL1.DataSet := Fds;
    Fds.Open;
end;

procedure TFormAddGl1ToLAS.fneLASAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
    if Assigned(Lds)then
     begin
      Lds.Close;
      FreeAndNil(Lds);
     end;
    Lds := TLasDataSet.Create;
    Lds.Encoding := lsenANSI;
    Lds.LasFile := AName;

    dsLAS.DataSet := Lds;
    Lds.Open;
end;

end.
