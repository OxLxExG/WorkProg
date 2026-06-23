unit manager3.DataImport;

interface

//{$DEFINE USE_VTARRAY}

uses DataSetIntf, ExtendIntf, CustomPlot, Container, FileDataSet, Data.Db,
     System.SysUtils, Xml.XMLIntf;
                       // WRK RAM  GLU                  //TFileDataSet
//procedure CreateDataSet(RootSection: IXMLNode; out DataSet: IDataSet; ObjectFields: Boolean = True);
                                                            // TFileDataSet
procedure CreatePlotParam(col: TGraphColmn; Node: IXMLNode; DataSet: IDataSet; out PlotParam: TGraphPar);

function AddDataField(DataSet: IDataSet; Node: IXMLNode; const path: string; ObjectFields: Boolean; var ClcOffset: Word): TFileFieldDef;

implementation

uses tools, Parser;

function AddDataField(DataSet: IDataSet; Node: IXMLNode; const path: string; ObjectFields: Boolean; var ClcOffset: Word): TFileFieldDef;
 var
  a: TArray<string>;
  f: TFileFieldDef;
  fs: TFileFieldDefs;
  i, sz, aq, off, arsz: Integer;
  nm: string;
  ft: TFieldType;
  function Find(const AName: string): TFileFieldDef;
  var
    I: Integer;
  begin
    I := fs.IndexOf(AName);
    if I < 0 then Result := nil else Result := TFileFieldDef(fs.Items[I]);
  end;
begin
  fs := TFileFieldDefs(TFileDataSet(DataSet).FieldDefs);
  if ObjectFields then
   begin
    a := path.Split(['.'], ExcludeEmpty);
    for i := 0 to Length(a)-2 do
     begin
      f := Find(a[i]);
      if not Assigned(f) then
       begin
        f := TFileFieldDef(fs.AddFieldDef);
        f.Name := a[i];
        f.DataType := ftADT;
       end;
       fs := TFileFieldDefs(f.ChildDefs);
     end;
    nm := a[High(a)];
   end
  else nm := path;

  f := TFileFieldDef(fs.AddFieldDef);

  sz := TPars.VarTypeToLength(Node.Attributes[AT_TIP]);
  ft := TPars.VarTypeToDBField(Node.Attributes[AT_TIP]);
  if Node.HasAttribute(AT_AQURICY) then aq := Node.Attributes[AT_AQURICY] else aq := 0;

  // смещение в файловом буфере
  if Node.HasAttribute(AT_INDEX) then off := Node.Attributes[AT_INDEX]
  else if Node.NodeName = T_CLC then
    begin
   // смещение в буфере DataSet
     off := ClcOffset;
     inc(ClcOffset, sz);
     f.InternalCalcField := True;
    end
  else off := 0;

  f.Name := nm;
  f.DataType := ft;
  f.DataOffset := off;
  f.Precision := aq;

  if Node.ParentNode.HasAttribute(AT_ARRAY) then
   begin
    arsz := Node.ParentNode.Attributes[AT_ARRAY];
   {$IFDEF  USE_VTARRAY}
    f.DataType := ftArray;
    f.Size := arsz;
    for i := 0 to arsz-1 do with TFileFieldDef(f.ChildDefs.AddFieldDef) do
     begin
      DataType := ft;
      DataOffset := off + sz*i;
      Precision := aq;
    end;
   {$ELSE}
    f.DataType := ftBytes;
    f.Size := arsz*sz;
   {$ENDIF}
    f.ArraySize := arsz;
    f.ArrayType := Node.Attributes[AT_TIP];
   end;
  Result := f;
end;

                      // WRK RAM GLU
{procedure CreateDataSet(RootSection: IXMLNode; out DataSet: IDataSet; ObjectFields: Boolean = True);
 var
  ds: TFileDataSet;
  flName: string;
  rootrModul: string;
  ids: IDataSet;
  ClcOffset: Word;
begin
  if not StrIn(RootSection.NodeName, ARR_META_RECS) then raise Exception.Create('Error Message');
  if not RootSection.HasAttribute(AT_FILE_NAME) then raise Exception.Create('Error Message');
  flName := RootSection.Attributes[AT_FILE_NAME];
  if not FileExists(flName) then raise Exception.Create('Error Message');

  rootrModul := RootSection.ParentNode.NodeName;
  TFileDataSet.New(flName, DataSet);
  ds := TFileDataSet(DataSet);
  ids := DataSet;
  ClcOffset := 0;
  ExecXTree(RootSection, procedure(n: IXMLNode)
  begin
    if StrIn(n.NodeName, ARR_META_RECS) then
       ds.RecordLength := n.Attributes[AT_SIZE]
    else if n.HasAttribute(AT_TIP) and ((n.NodeName = T_CLC) or ((n.NodeName = T_DEV) and n.HasAttribute(AT_INDEX))) then
       AddDataField(ids, n, rootrModul + '.' + GetPathXNode(n), ObjectFields, ClcOffset)
  end);
end;}
                                                            // TFileDataSet
procedure CreatePlotParam(col: TGraphColmn; Node: IXMLNode; DataSet: IDataSet; out PlotParam: TGraphPar);
begin

end;

end.
