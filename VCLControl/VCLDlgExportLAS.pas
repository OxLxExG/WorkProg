unit VCLDlgExportLAS;

interface

{$INCLUDE global.inc}

uses DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, debug_except, Actns, Container, tools,
  Xml.XMLIntf, DataSetIntf, XMLDataSet, System.TypInfo, LAS, LasImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids, VCLFrameSelectParam, Vcl.StdCtrls, Vcl.ExtCtrls,
  SelectPath, Vcl.ComCtrls, Vcl.Menus, Vcl.DBCtrls, Vcl.Mask, JvExMask, JvToolEdit, VCLFrameRangeSelect;

{$IFDEF ENG_VERSION}
 const
  RS_Export = 'Export';
  RS_file ='0:File.Export|1:2';
{$ELSE}
 const
  RS_Export = 'Экспорт';
  RS_file ='0:Файл.Экспорт|1:2';
{$ENDIF}

const
  T_KADR='.время.DEV';
  T_ID='ID';

type
  TFormExportLASP3 = class(TDialogIForm, IDialog, IDialog<Integer>)
    pc: TPageControl;
    tshSelDir: TTabSheet;
    tshSelParam: TTabSheet;
    FrameSelectParam: TFrameSelectParam;
    tshData: TTabSheet;
    DBGrid1: TDBGrid;
    btCancel: TButton;
    btOK: TButton;
    tshLas: TTabSheet;
    cb: TComboBox;
    Label4: TLabel;
    ds: TDataSource;
    od: TJvFilenameEdit;
    Label1: TLabel;
    Memo: TMemo;
    RangeSelect: TFrameRangeSelect;
    sb: TStatusBar;
    Label2: TLabel;
    lbAq: TEdit;
    lbDg: TEdit;
    cbUnq: TCheckBox;
    cbKadr: TCheckBox;
    FrameSelectPath: TSelectPathFrm;
    procedure btOKClick(Sender: TObject);
    procedure odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure tshLasShow(Sender: TObject);
    procedure cbUnqClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
 type
   TInternalNames = record
    exclude: Boolean;
    lf: TLasFormat;
    DigitFormat: string;
    namPath: TArray<string>
   end;
   var
    ids: IDataSet;
    fldKadr: TField;
    FirstKadr, LastKadr: Integer;
    lasf: TArray<TInternalNames>;
    flds: TArray<TField>;
    procedure GenerateNames(excludeOnlyEqal: boolean = true);
  public
    function Execute(dummy: Integer): Boolean;
    function GetInfo: PTypeInfo; override;
    class function ClassIcon: Integer; override;
    [StaticAction('-LAS...', RS_Export, 128, RS_file)]
    class procedure DoExportLAS(Sender: IAction);
  end;

  resourcestring
  RS_ERR_SelectData='Не выбраны параметры';
  RS_ERR_SelectFile='Не выбран файл';

implementation

{$R *.dfm}

uses Math;

{ TFormExportLASP3 }

class function TFormExportLASP3.ClassIcon: Integer;
begin
  Result := 128;
end;

class procedure TFormExportLASP3.DoExportLAS(Sender: IAction);
var
  d: Idialog;
begin
  if RegisterDialog.TryGet(EXPORT_DIALOG_CATEGORY, 'LAS', d) then (d as IDialog<Integer>).Execute(0);
end;

procedure TFormExportLASP3.GenerateNames(excludeOnlyEqal: boolean);
 var
  s, dg, aq: string;
  i, cnt, findCnt: Integer;
  n: IXMLNode;
  function IsUniqe(const idel: Integer): Boolean;
   var
    a, nms: TArray<string>;
    n: TInternalNames;
    i,j: Integer;
  begin
    Result := True;
    nms := [];
    for n in lasf do if not n.exclude then
     begin
      a := n.namPath;
      Delete(a, idel, 1);
      nms := nms + [string.Join('', a)];
     end;
    for i := 0 to High(nms)-1 do
     for j := i+1 to High(nms) do if SameText(nms[i], nms[j]) then Exit(False);
  end;
  function GetMaxLen: Integer;
   var
    n: TInternalNames;
  begin
    Result := 0;
    for n in lasf do if not n.exclude then Result := max(Result, Length(n.namPath));
  end;
  function GetMinLen: Integer;
   var
    n: TInternalNames;
  begin
    Result := 1000;
    for n in lasf do if not n.exclude then Result := min(Result, Length(n.namPath));
  end;
  function GetFindCnt: Integer;
   var
    n: TInternalNames;
  begin
    Result := 0;
    for n in lasf do if not n.exclude then Inc(Result);
  end;
  procedure Del(ix: Integer);
   var
    i: Integer;
  begin
    for i := 0 to Length(lasf)-1 do if not lasf[i].exclude then
     begin
      if ix < 0 then Delete(lasf[i].namPath, Length(lasf[i].namPath)-ix, 1)
      else Delete(lasf[i].namPath, ix, 1);
     end;
  end;
  function ChekEq(ix: Integer): Boolean;
   var
    i, idx: Integer;
    n: TInternalNames;
    first: string;
  begin
    Result := True;
    first := '';
    for n in lasf do if not n.exclude then
     begin
      if ix < 0 then idx := Length(n.namPath)-ix else idx := ix;
      if (idx >= Length(n.namPath)) or (idx <0 ) then Exit(False);
      if first = '' then first := n.namPath[idx]
      else if not SameText(first, n.namPath[idx]) then Exit(False);
     end;
  end;
begin
  SetLength(lasf, Length(flds));
  for i := 0 to High(flds) do with lasf[i] do
    begin
      aq := lbAq.Text;
      dg := lbDg.Text;
      namPath := flds[i].FullName.Split(['.'], TStringSplitOptions.ExcludeEmpty);
      if TXMLDataSet(ids).TryGetX(flds[i].FullName, n) then
       begin
        if n.HasAttribute(AT_TITLE) then
         begin
          exclude := True;
          lf.Mnem := n.Attributes[AT_TITLE];
          lf.Description := string.Join('-', namPath);
         end
        else
         begin
         end;
        if n.HasAttribute(AT_EU) then lf.Units := n.Attributes[AT_EU];
        if n.HasAttribute(AT_AQURICY) then aq := n.Attributes[AT_AQURICY];
        if n.HasAttribute(AT_DIGITS) then dg := n.Attributes[AT_DIGITS];
       end;
      DigitFormat := ' %'+dg+'.'+ aq +'f';
    end;
   // exclude eqal paths
    findCnt := GetFindCnt();
   if findCnt > 1 then
    begin

     cnt := GetMaxLen;
     i := 0;
     while i < cnt do
      begin
       while (GetMinLen > 1) and ChekEq(i) do Del(i);
       if (findCnt > 2) and (i > 0) and ChekEq(-i) then Del(-i);
       Inc(i);
      end;

     cnt := GetMinLen;
     if not excludeOnlyEqal and (cnt > 1) then
      begin
       while IsUniqe(0) do Del(0);
      end;
    end;
   for i := 0 to High(flds) do with lasf[i] do if not exclude then lf.Mnem := string.Join('_', namPath);
end;

function TFormExportLASP3.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_Export);
end;

procedure TFormExportLASP3.odBeforeDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
  od.FileName := '';
end;

procedure TFormExportLASP3.cbUnqClick(Sender: TObject);
 var
  s: string;
  im: TInternalNames;
begin
  memo.Clear;
  GenerateNames(cbUnq.Checked);
  for im in lasf do
   begin
    s := 'name: '+ im.lf.Mnem;
    if im.lf.Units <> '' then s := s + '.'+ im.lf.Units;
    if im.lf.Description <> '' then s := s + ' desc: ' + im.lf.Description;
    s := s + ' fmt: ' + im.DigitFormat;
    memo.Lines.Add(s);
   end;
end;

procedure TFormExportLASP3.tshLasShow(Sender: TObject);
begin
  flds := FrameSelectParam.GetSelected;
  cbUnqClick(nil);
end;

function TFormExportLASP3.Execute(dummy: Integer): Boolean;

begin
  Result := True;
  IShow;
    FrameSelectPath.Execute(Caption, procedure(XMLSection: IXMLNode)
    begin
      TXMLDataSet.Get(XMLSection,  ids,  True);
      ids.DataSet.Open;
    //  fldKadr := ids.DataSet.FieldByName(TXMLDataSet(ids.DataSet).XMLSection.ParentNode.NodeName +'.время.DEV');
      fldKadr := ids.DataSet.FieldByName(T_ID);
      ids.DataSet.Last;
      LastKadr := fldKadr.AsInteger;
      ids.DataSet.First;
      FirstKadr := fldKadr.AsInteger;
      RangeSelect.Init(TXMLDataSet(ids.DataSet).RecordLength, FirstKadr, LastKadr, (GContainer as IProjectOptions).DelayStart);
      FrameSelectParam.InitTree(ids.DataSet);
      ds.DataSet := ids.DataSet;
    end);
end;

procedure TFormExportLASP3.btCancelClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize(EXPORT_DIALOG_CATEGORY, 'LAS');
end;

procedure TFormExportLASP3.btOKClick(Sender: TObject);
 var
  from, last, i : Integer;
  il: ILasDoc;
  n: IXMLNode;
  im: TInternalNames;
  v: array of Variant;
     procedure UpdateSb4(const s: string);
     begin
       TThread.Synchronize(nil, procedure
        begin
          sb.Panels[4].Text := s;
        end);
     end;
begin
  if Length(flds) = 0 then raise ENeedDialogException.Create(RS_ERR_SelectData);
  if od.FileName = '' then raise ENeedDialogException.Create(RS_ERR_SelectFile);
  if not Assigned(ids) then raise ENeedDialogException.Create(RS_ERR_SelectFile);
  from := RangeSelect.kadr.first;
  last := RangeSelect.kadr.last;
  il := NewLasDoc();
   UpdateSb4('работа');
   Application.ProcessMessages;
  // инициализируем поля
  for im in lasf do
   begin
    il.Curve.Add(im.lf);
    il.Curve.DisplayFormat[im.lf.Mnem] := im.DigitFormat;
   end;
  ids.DataSet.RecNo := from - FirstKadr;
  SetLength(v, Length(flds)+1);
  // пишем данные
  while (not ids.DataSet.Eof) and (last >= fldKadr.AsInteger) do
   begin
    v[0] := fldKadr.AsInteger;
    for i := 1 to Length(flds) do
     if flds[i-1] is TNumericField then  v[i] := flds[i-1].AsFloat
     else v[i] := flds[i-1].AsString;
    il.Data.AddData(v);
    ids.DataSet.Next;
   end;
  il.Encoding := LasEncoding(cb.ItemIndex); 
  il.SaveToFile(od.FileName);
  UpdateSb4('конец');
end;


initialization
  RegisterDialog.Add<TFormExportLASP3, Dialog_Export>(EXPORT_DIALOG_CATEGORY, 'LAS');
finalization
  RegisterDialog.Remove<TFormExportLASP3>;
end.
