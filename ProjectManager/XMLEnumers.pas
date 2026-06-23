unit XMLEnumers;

interface

uses System.SysUtils, System.Generics.Collections, System.Classes, Xml.XMLIntf,
     System.Generics.Defaults,
     debug_except, RootIntf, DeviceIntf, ExtendIntf, Container, RootImpl;

type
  TXMEnum<T: IManagItem> = class(TRootServiceManager<T>)
  protected
    class function SupportPublishedChanged: Boolean; override;
    procedure SetItemChanged(const Value: string); override;
    procedure DoAfterItemChanged(n: IXMLNode; mi: TInstanceRec); virtual;
    procedure DoAfterAdd(mi: IManagItem); override;
    procedure DoAfterAddIner(n: IXMLNode; mi: IManagItem); virtual;
    procedure DoAfterRemove(mi: IManagItem); override;
    procedure Load; override;
    procedure UpdateProject;
    function Root: IXmlNode; virtual; abstract;
  end;

  TConnectIOs = class(TXMEnum<IConnectIO>, IConnectIOEnum)
  protected
    procedure DoAfterAdd(mi: IManagItem); override;
    procedure DoAfterAddIner(n: IXMLNode; mi: IManagItem); override;
    function Root: IXmlNode; override;
  end;

  TDevices = class(TXMEnum<IDevice>, IDeviceEnum)
  protected
//    procedure DoAfterItemChanged(n: IXMLNode; mi: TInstanceRec); override;
//    procedure DoAfterAddIner(n: IXMLNode; mi: IManagItem); override;
  protected
    function Root: IXmlNode; override;
  end;

  { TODO : плохая идея необходимо о длинне данных держать информацию в другом файле !!! }
//  TFiles = class(TXMEnum<IFileData>, IFileEnum)
//  protected
//    function GetFileData(const FileName: string): IFileData;
//    function Root: IXmlNode; override;
//  end;


implementation

uses tools, manager3;

{$REGION 'TXMEnum<T>'}

{ TXMEnum<T> }

class function TXMEnum<T>.SupportPublishedChanged: Boolean;
begin
  Result := True;
end;

procedure TXMEnum<T>.UpdateProject;
begin
  TManager.This.FProjecDoc.SaveToFile(TManager.This.FProjectFile);
  TManager.This.FProjecDoc.Resync;
end;

procedure TXMEnum<T>.DoAfterAdd(mi: IManagItem);
 var
  ir: TInstanceRec;
  n: IXMLNode;
begin
  if GContainer.TryGetInstRec(mi.Model, mi.IName, ir) then
  begin
   n := Root.AddChild(mi.IName);
   n.Attributes[AT_PRIORITY] := mi.Priority;
   n.Attributes[AT_OBJ] := ir.Text;
   DoAfterAddIner(n, mi);
  end;
  inherited;
  UpdateProject;
end;

procedure TXMEnum<T>.DoAfterAddIner(n: IXMLNode; mi: IManagItem);
begin
end;

procedure TXMEnum<T>.DoAfterItemChanged(n: IXMLNode; mi: TInstanceRec);
begin
end;

procedure TXMEnum<T>.DoAfterRemove(mi: IManagItem);
 var
  n: IXMLNode;
begin
  n := Root.ChildNodes.FindNode(mi.IName);
  Root.ChildNodes.Remove(n);
  inherited;
  UpdateProject;
end;

procedure TXMEnum<T>.SetItemChanged(const Value: string);
 var
  ir: TInstanceRec;
  n: IXMLNode;
begin
  inherited;
  if not GContainer.TryGetInstRecKnownServ(TypeInfo(T), Value, ir) then Exit;
  n := Root.ChildNodes.FindNode(Value);
  n.Attributes[AT_OBJ] := ir.Text;
  DoAfterItemChanged(n, ir);
  UpdateProject;
end;

procedure TXMEnum<T>.Load;
 var
  v: IXMLNode;
  i: Integer;
  a: TArray<IXMLNode>;
begin
  SetLength(a, root.ChildNodes.Count);
  for i := 0 to root.ChildNodes.Count-1 do a[i] := root.ChildNodes[i];
//  TArray.Sort<IXMLNode>(a, TComparer<IXMLNode>.Construct(function(const Left, Right: IXMLNode): Integer
//  begin
//    Result := Left.Attributes[AT_PRIORITY] - Right.Attributes[AT_PRIORITY];
//  end));
  for v in a do
   try
    DoLoadItem(v.Attributes[AT_OBJ], v.Attributes[AT_PRIORITY]);
   except
    on E: Exception do TDebug.DoException(E, False);
   end;
end;
{$ENDREGION}

{ TConnectIOs }

procedure TConnectIOs.DoAfterAdd(mi: IManagItem);
 var
  c: IconnectIO;
begin
  inherited;
  c := mi as IconnectIO;
  c.Status := c.Status - [icAdding];
end;

procedure TConnectIOs.DoAfterAddIner(n: IXMLNode; mi: IManagItem);
 var
  c: IconnectIO;
begin
  inherited;
  c := mi as IconnectIO;
  c.Status := c.Status + [icAdding];
end;

function TConnectIOs.Root: IXmlNode;
begin
  Result := TManager.This.FConnect;
end;

{ TDevices }

{procedure TDevices.DoAfterAddIner(n: IXMLNode; mi: IManagItem);
begin
  inherited;
  n.Attributes[AT_CAPTION] := (mi as ICaption).Text;
end;

procedure TDevices.DoAfterItemChanged(n: IXMLNode; mi: TInstanceRec);
begin
  inherited;
  if Assigned(mi.Inst) then n.Attributes[AT_CAPTION] := (mi.Inst as ICaption).Text;
end;}


function TDevices.Root: IXmlNode;
begin
  Result := TManager.This.FDevices;
end;


{ TFiles }

//function TFiles.GetFileData(const FileName: string): IFileData;
// var
//  i: TInstanceRec<IFileData>;
//begin
//  for i in AsArrayRec do
//   if Assigned(i.Inst) then
//    begin
//     if SameStr(i.Inst.FileName, FileName) then Exit(i.Inst);
//    end
//   else if Gcon  then
//
//end;
//
//function TFiles.Root: IXmlNode;
//begin
//  Result := TManager.This.FFiles;
//end;

initialization
  RegisterClasses([TDevices, TConnectIOs]);
  TRegister.AddType<TDevices, IDeviceEnum>
           .LiveTime(ltSingletonNamed)
           .AddInstance(TDevices.Create as IInterface);
  TRegister.AddType<TConnectIOs, IConnectIOEnum>
           .LiveTime(ltSingletonNamed)
           .AddInstance(TConnectIOs.Create as IInterface);
//  TRegister.AddType<TFiles, IFileEnum>
//           .LiveTime(ltSingletonNamed)
//           .AddInstance(TFiles.Create as IInterface);
finalization
  GContainer.RemoveModel<TDevices>;
//  GContainer.RemoveModel<TFiles>;
  GContainer.RemoveModel<TConnectIOs>;
end.
