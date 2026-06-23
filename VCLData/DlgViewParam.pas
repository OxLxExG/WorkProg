unit DlgViewParam;

interface

uses AbstractDlgParams,
  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Data.DB,  TypInfo, Xml.XMLIntf, RootIntf, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, tools,  System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  System.Generics.Collections,
  System.Bindings.Expression,
  System.Bindings.Helper,
  System.Bindings.Graph, RTTI;

type
  TUpdateFunc = reference to procedure(Selected: TArray<string>);

  TViewParams = record
  private
    DataBase: string;
    TypeData: TypeDataShow;
    Selected: TArray<string>;
    UpdateNotify: TUpdateFunc;
  public
    constructor Create(const ADataBase: string; ATypeData: TypeDataShow; ASelFieldNames: TArray<string>; AUpdateNotify: TUpdateFunc);
  end;

  TFormViewParams = class(TFormParamsAbstract, IDialog, IDialog<TViewParams>)
  private
    Selected: TArray<string>;
    FUpdateNotify: TUpdateFunc;
    procedure AddUserParam(root: IXMLNode; const Name: string);
    function Check(cn: IXMLNode{; const pre: string}): Boolean;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(Data: TViewParams): Boolean;
    procedure DoApply; override;
    procedure DoExitClick; override;
  end;


implementation

{ TViewParams }

constructor TViewParams.Create(const ADataBase: string; ATypeData: TypeDataShow; ASelFieldNames: TArray<string>; AUpdateNotify: TUpdateFunc);
begin
  DataBase := ADataBase;
  TypeData := ATypeData;
  Selected := ASelFieldNames;
  UpdateNotify := AUpdateNotify;
end;

{ TFormViewParams }

procedure TFormViewParams.DoApply;
 var
  s: TArray<string>;
begin
 //
 // Doc.SaveToFile(ExtractFilePath(ParamStr(0))+'VIEW.xml');
 //
  ExecXtree(Doc.DocumentElement, procedure(n: IXMLNode)
  begin
    if n.HasAttribute(CheckName) and Boolean(n.Attributes[CheckName]) then
     if n.HasAttribute(USER_PARAM) then Carray.Add<string>(s, n.ParentNode.NodeName)
     else
      begin
        if CNode.IsData(n) then Carray.Add<string>(s, CNode.DBName(n))
      end;
//     else if n.NodeName = T_DEV then Carray.Add<string>(s, THelperXMLtoDB.CreateName(n.ParentNode, 'R'))
//     else if n.NodeName = T_CLC then Carray.Add<string>(s, THelperXMLtoDB.CreateName(n.ParentNode, 'T'));
  end);
//  THelperXMLtoDB.UnDuplicateNames(s);
  FUpdateNotify(s);
end;

procedure TFormViewParams.DoExitClick;
begin
  RegisterDialog.UnInitialize<Dialog_SelectViewParameters>
end;

function TFormViewParams.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_SelectViewParameters);
end;

procedure TFormViewParams.AddUserParam(root: IXMLNode; const Name: string);
 var
  n, d: IXMLNode;
begin
  n := root.AddChild(Name, 0);
  d := n.AddChild(T_DEV);
  d.Attributes[USER_PARAM] := 1;
  d.Attributes[VIEW_DB] := Check(d);
end;

function TFormViewParams.Check(cn: IXMLNode{; const pre: string}): Boolean;
 var
  i: string;
  s: string;
begin
  Result := False;
  if cn.HasAttribute(USER_PARAM) then s := cn.ParentNode.NodeName else s := CNode.DBName(cn);
//  for i in Selected do if SameText(i, THelperXMLtoDB.CreateName(cn, pre)) then Exit(True);
  for i in Selected do if SameText(i, s) then Exit(True);
end;

function TFormViewParams.Execute(Data: TViewParams): Boolean;
 var
  r, n, w: IXMLNode;
begin
  Result := True;
  CheckName := VIEW_DB;
  TypeData := Data.TypeData;
  FUpdateNotify := Data.UpdateNotify;
  Selected := Data.Selected;
  Doc := NewXDocument();
  Doc.ChildNodes.Add((GContainer as IALLMetaDataFactory).Get(Data.DataBase).Get.DocumentElement.CloneNode(True));
  // remove unused
  for r in XEnum(Doc.DocumentElement) do //dev
   for n in XEnum(r) do //modul
     for w in XEnumDec(n) do if w.NodeName <> CL_TYPE[TypeData] then n.ChildNodes.Remove(w); // ram wrk glu
  // поля события Log
  r := Doc.DocumentElement.AddChild('Event', 0);
  r.Attributes[AT_SIZE] := 0;
  r := r.AddChild('Event', 0);
  r.Attributes[AT_SIZE] := 0;
  r := r.AddChild(CL_TYPE[TypeData]);
  r.Attributes[AT_SIZE] := 0;
  AddUserParam(r, 'ID');
  AddUserParam(r, 'Время');
  ExecXtree(Doc.DocumentElement, procedure(n: IXMLNode)
   var
    t: IXMLNode;
  begin
    if ((n.NodeName = T_DEV) or (n.NodeName = T_CLC)) and n.HasAttribute(AT_DB_SELECT) and Boolean(n.Attributes[AT_DB_SELECT]) then
       n.Attributes[CheckName] := Check(n);
//      if n.NodeName = T_DEV then n.Attributes[CheckName] := Check(n.ParentNode, 'R')
//      else n.Attributes[CheckName] := Check(n.ParentNode, 'T');
    while not n.HasChildNodes and not n.HasAttribute(CheckName) do
     begin
      t := n.ParentNode;
      t.ChildNodes.Remove(n);
      n := t;
     end;
  end, True);
  UpdateTree;
  IShow;
end;

initialization
  RegisterDialog.Add<TFormViewParams, Dialog_SelectViewParameters>;
finalization
  RegisterDialog.Remove<TFormViewParams>;
end.
