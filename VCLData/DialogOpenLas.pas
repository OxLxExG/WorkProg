unit DialogOpenLas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, LAS, LasImpl, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, JvExComCtrls, JvComCtrls, JvDotNetControls, Vcl.StdCtrls, JvDriveCtrls, JvExStdCtrls,
  JvListBox, JvDialogs, JvCombobox, JvExControls, JvInspector, JvComponentBase, Vcl.FileCtrl, Vcl.Grids, Data.DB, Vcl.DBGrids, Datasnap.DBClient;

type
  TDlgOpenLAS = class(TForm)
    DriveCombo: TJvDriveCombo;
    DirectoryList: TJvDirectoryListBox;
    FileList: TJvFileListBox;
    Inspector: TJvInspector;
    btCancel: TButton;
    btOK: TButton;
    pc: TPageControl;
    tshLAS: TTabSheet;
    tshData: TTabSheet;
    BorlandPainter: TJvInspectorBorlandPainter;
    DBGrid1: TDBGrid;
    ds: TDataSource;
    ClientDataSet: TClientDataSet;
    procedure FileListChange(Sender: TObject);
  private
    Items: TArray<string>;
    Selected: TArray<Boolean>;
  public
    class function Execute(var LasFile: string; var SelMnems: TArray<string>; const InitialDir: string =''): boolean;
  end;

  resourcestring
   RE_Wrap='WRAP=%s Перенос строк не поддерживается';

implementation

uses tools;

{$R *.dfm}

{$REGION 'TLasFormatData'}

type
  TLasFormatData = class(TJvInspectorCustomConfData)
  private
    las: ILasFormatSection;
    FItem: string;
  protected
    function ExistingValue: Boolean; override;
    procedure WriteValue(const Value: string); override;
  public
    function ReadValue: string; override;
    class function New(AParent: TJvCustomInspectorItem; ALasData: ILasFormatSection; const aMnem: string; ReadOnly: Boolean = True): TJvCustomInspectorItem; reintroduce;
  end;

{ TLasFormatData }


function TLasFormatData.ExistingValue: Boolean;
begin
  Result := True;
end;

class function TLasFormatData.New(AParent: TJvCustomInspectorItem; ALasData: ILasFormatSection; const aMnem: string; ReadOnly: Boolean = True): TJvCustomInspectorItem;
var
  cData: TLasFormatData;
begin
  with ALasData.Items[aMnem]^ do
       cData := CreatePrim(Format('[%9s.%-5s] %s', [aMnem, Units, string.LowerCase(Description)]) ,'nop', aMnem, System.TypeInfo(string));
  if not ReadOnly then cData.las := ALasData;
  if not ReadOnly then cData.FItem := aMnem
  else cData.FItem := ALasData.Items[aMnem].Data;
  cData := TLasFormatData(DataRegister.Add(cData));
  Result := cData.NewItem(AParent);
  Result.ReadOnly := ReadOnly;
end;

function TLasFormatData.ReadValue: string;
begin
  if Assigned(las) then Result := las.Items[FItem].Data
  else Result := FItem
end;

procedure TLasFormatData.WriteValue(const Value: string);
begin
 if Assigned(las) then las.Items[FItem].Data := Value;
end;

{$ENDREGION}

class function TDlgOpenLAS.Execute(var LasFile: string; var SelMnems: TArray<string>; const InitialDir: string =''): boolean;
 var
  i: Integer;
begin
  with Create(nil) do
   try
    if InitialDir <> '' then  DirectoryList.Directory := InitialDir;
    Result := (ShowModal() = mrOk);
    if Result then
     begin
      LasFile := Caption;
      SetLength(SelMnems, 0);
      for I := 0 to Length(Selected)-1 do if Selected[i] then CArray.Add<string>(SelMnems, Items[i]);
      Result := Length(SelMnems) > 0;
     end;
   finally
    Free;
   end;
end;

procedure TDlgOpenLAS.FileListChange(Sender: TObject);
  function CeateCat(lfs: ILasFormatSection; exp: Boolean = True; aditems: Boolean = true): TJvInspectorCustomCategoryItem;
   var
    s: string;
  begin
    Result := TJvInspectorCustomCategoryItem.Create(Inspector.Root, nil);
    Result.SortKind := iskNone;
    Result.DisplayName := lfs.Priambula[0].Substring(1);
    Result.Expanded := exp;
    if aditems then for s in lfs.Mnems do TLasFormatData.New(Result, lfs, s);
  end;
  procedure CreateCurve(lfs: ICurveSection);
   var
    i: Integer;
    c: TJvInspectorCustomCategoryItem;
  begin
    c := CeateCat(lfs, true, false);
    Items := lfs.Mnems;
    SetLength(Selected, Length(Items));
    for i := 0 to High(Selected) do with lfs.Formats[i] do
     begin
      TJvInspectorBooleanItem(TJvInspectorVarData.New(c, Format('[%9s.%-5s] %s', [Mnem, Units, string.LowerCase(Description)]), System.TypeInfo(Boolean), @Selected[i])).ShowAsCheckbox := True;
      ClientDataSet.FieldDefs.Add(Mnem, ftFloat);
     end;
  end;
  procedure CreateRows(lds: ILasDataSection);
   var
    i, j: Integer;
  begin
    ClientDataSet.DisableControls;
    try
     for j := 0 to Length(lds.Items)-1 do
      begin
       ClientDataSet.Append;
       for i := 0 to Length(lds.Items[j])-1 do if not VarIsNull(lds.Items[j, i]) then ClientDataSet.Fields[i].AsFloat := lds.Items[j, i];
       ClientDataSet.Post;
       if j > 100 then Break;
      end;
     ClientDataSet.First;
    finally
     ClientDataSet.EnableControls;
    end;
  end;
 var
  il: ILasDoc;
begin
  ClientDataSet.Active := False;
  pc.TabIndex := 0;
  ClientDataSet.FieldDefs.Clear;
  Inspector.Clear;
  Inspector.Root.SortKind := iskNone;
  SetLength(Selected, 0);
  SetLength(Items, 0);
  if FileList.FileName <>'' then
   begin
    Caption := FileList.FileName;
    il := NewLasDoc();
    il.LoadFromFile(Caption);
    //with il.Version.Items['WRAP']^ do if Data <> 'NO' then raise Exception.CreateFmt(RE_Wrap, [Data]);
    CreateCurve(il.Curve);
    CeateCat(il.Well);
    CeateCat(il.Params);
    CeateCat(il.Version);
    ClientDataSet.CreateDataSet;
    CreateRows(il.Data);
   end
  else Caption := 'Import LAS';
end;

end.
