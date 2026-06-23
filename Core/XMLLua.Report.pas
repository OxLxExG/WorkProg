unit XMLLua.Report;

interface

 {$M+}

uses
      XMLLua, VerySimple.Lua.Lib, tools, Container, debug_except, ExtendIntf,  System.IOUtils,
      Winapi.ActiveX, Xml.XMLDoc, Xml.XMLIntf,
      SysUtils, System.UITypes, System.Generics.Collections, System.Classes, math, System.Variants;

type
  TXMLScriptReport = class
  private
    class procedure ExportToNNK(const TrrFile: string; XNewTrr: IXMLNode); overload; static;
    class procedure ExportToNNK128(const TrrFile: string; XNewTrr: IXMLNode); overload; static;
    class procedure ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: IXMLNode); overload; static;
    class constructor Create;
    class destructor Destroy;
  published
//    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
    class function ExportToCalc(L: lua_State): Integer; overload; cdecl; static;
    class function ExportToNNK(L: lua_State): Integer; overload; cdecl; static;
    class function ExportToNNK128(L: lua_State): Integer; overload; cdecl; static;
  end;


implementation

{ TXMLScriptReport }

//class function TXMLScriptReport.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//begin
//  if SameText(MethodName, 'ExportToCalc') then ExportToCalc(Params[0],Params[1],Params[2],Params[3]);
//end;

class constructor TXMLScriptReport.Create;
begin
  TXMLLua.RegisterLuaMethods(TXMLScriptReport);
//  TXmlScriptInner.RegisterMethods([
//  'procedure ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: variant)'], CallMeth);
end;

class destructor TXMLScriptReport.Destroy;
begin

end;


class procedure TXMLScriptReport.ExportToNNK(const TrrFile: string; XNewTrr: IXMLNode);
// preambula
 const STR0 = '%-43sНаименование прибора';
 const STR1 = '%-43sДата калибровки';
 const STR2 = '%-43sИсточник';
 const STR3 = 'Дскв,мм  Кп,%	  МЗ        БЗ      НГК';
// ambula
 const STRA: array of string =
 [
'124      100      %-9s %-9s %-6s Вода',
'124      0.6      %-9s %-9s %-6s',
'124      16.5     %-9s %-9s %-6s',
'124      34.0     %-9s %-9s %-6s',
'156      100      %-9s %-9s %-6s Вода',
'156      0.7      %-9s %-9s %-6s',
'156      14.8     %-9s %-9s %-6s',
'156      34.0     %-9s %-9s %-6s',
'216      100      %-9s %-9s %-6s Вода',
'216      0.7      %-9s %-9s %-6s',
'216      16.5     %-9s %-9s %-6s',
'216      34.0     %-9s %-9s %-6s',
'295      100      %-9s %-9s %-6s Вода',
'295      0.7      %-9s %-9s %-6s',
'295      16.5     %-9s %-9s %-6s',
'295      34.0     %-9s %-9s %-6s'
 ];
 const STEPA: array of integer =
 [
  1,  2,  3,  4,
  1,  5,  6,  7,
  11, 8,  9,  10,
  11, 12, 13, 14
 ];
 var
  sernom: Integer;
  s: string;
  NewTrr: Variant;
begin
  NewTrr := XToVar(XNewTrr);
  with  TstringList.Create do
   try
    sernom := TVxmlData(NewTrr).Node.ParentNode.ParentNode.Attributes[AT_SERIAL];
    s := NewTrr.TNNK.DevName + ' ' + sernom.ToString;
    Add(Format(STR0,[s]));
    s := NewTrr.TNNK.TIME_ATT;
    Add(Format(STR1,[s]));
    s := NewTrr.TNNK.ISTOCHNIK;
    Add(Format(STR2,[s]));
    Add(STR3);
    for var i := 0 to High(STRA) do
     begin
      var vi := XToVar(GetXNode(XNewTrr, Format('TNNK.STEP%d',[STEPA[i]])));
      var snk1 := RoundTo(double(vi.нк1.DEV.VALUE), -3).ToString;
      if vi.нк1.DEV.VALUE = '0' then snk1 := '1';
      var snk2 := RoundTo(double(vi.нк2.DEV.VALUE), -3).ToString;;
      if vi.нк2.DEV.VALUE = '0' then snk2 := '1';
      var sngk := RoundTo(double(vi.нгк.DEV.VALUE), -3).ToString;
      if vi.нгк.DEV.VALUE = '0' then sngk := '1';
      Add(Format(STRA[i],[snk1, snk2, sngk]));
     end;

    SaveToFile(TrrFile);
   finally
    Free;
   end;
end;

class function TXMLScriptReport.ExportToCalc(L: lua_State): Integer;
 var
  ReportShablon, ReportXML, ReportFile: string;
  Data: IXMLNode;
begin
  ReportShablon := string(lua_tostring(L,1));
  ReportXML := string(lua_tostring(L,2));
  ReportFile := string(lua_tostring(L,3));
  Data := TXMLLua.XNode(L, 4);

  ExportToCalc(ReportShablon, ReportXML, ReportFile, Data);
  Result := 0;
end;

class function TXMLScriptReport.ExportToNNK(L: lua_State): Integer;
begin
  ExportToNNK(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class function TXMLScriptReport.ExportToNNK128(L: lua_State): Integer;
begin
  ExportToNNK128(string(lua_tostring(L, 1)), TXMLLua.XNode(L, 2));
  Result := 0;
end;

class procedure TXMLScriptReport.ExportToNNK128(const TrrFile: string; XNewTrr: IXMLNode);
// preambula
 const STR0 = '%-43sНаименование прибора';
 const STR1 = '%-43sДата калибровки';
 const STR2 = '%-43sИсточник';
 const STR3 = 'Дскв,мм  Кп,%	  МЗ        БЗ      НГК';
// ambula
 const STRA: array of string =
 [
'124      100      %-9s %-9s %-6s Вода',
'124      0.6      %-9s %-9s %-6s',
'124      16.5     %-9s %-9s %-6s',
'124      34.0     %-9s %-9s %-6s',
'156      100      %-9s %-9s %-6s Вода',
'156      0.7      %-9s %-9s %-6s',
'156      14.8     %-9s %-9s %-6s',
'156      34.0     %-9s %-9s %-6s',
'216      100      %-9s %-9s %-6s Вода',
'216      0.7      %-9s %-9s %-6s',
'216      16.5     %-9s %-9s %-6s',
'216      34.0     %-9s %-9s %-6s',
'295      100      %-9s %-9s %-6s Вода',
'295      0.7      %-9s %-9s %-6s',
'295      16.5     %-9s %-9s %-6s',
'295      34.0     %-9s %-9s %-6s'
 ];
 const STEPA: array of integer =
 [
  1,  2,  3,  4,
  1,  5,  6,  7,
  11, 8,  9,  10,
  11, 12, 13, 14
 ];
 var
  sernom: Integer;
  s: string;
  NewTrr: Variant;
begin
  NewTrr := XToVar(XNewTrr);
  with  TstringList.Create do
   try
    sernom := TVxmlData(NewTrr).Node.ParentNode.ParentNode.Attributes[AT_SERIAL];
    s := NewTrr.TNNK128.DevName + ' ' + sernom.ToString;
    Add(Format(STR0,[s]));
    s := NewTrr.TNNK128.TIME_ATT;
    Add(Format(STR1,[s]));
    s := NewTrr.TNNK128.ISTOCHNIK;
    Add(Format(STR2,[s]));
    Add(STR3);
    for var i := 0 to High(STRA) do
     begin
      var vi := XToVar(GetXNode(XNewTrr, Format('TNNK128.STEP%d',[STEPA[i]])));
      var snk1 := RoundTo(double(vi.мз.DEV.VALUE), -3).ToString;
      if vi.мз.DEV.VALUE = '0' then snk1 := '1';
      var snk2 := RoundTo(double(vi.бз.DEV.VALUE), -3).ToString;;
      if vi.бз.DEV.VALUE = '0' then snk2 := '1';
//      var sngk := RoundTo(double(vi.нгк.DEV.VALUE), -3).ToString;
//      if vi.нгк.DEV.VALUE = '0' then sngk := '1';
      Add(Format(STRA[i],[snk1, snk2, '1']));
     end;

    SaveToFile(TrrFile);
   finally
    Free;
   end;
end;

//только имя файла       файла и путь    %DEV%.Метрология.%modul%     //
class procedure TXMLScriptReport.ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: IXMLNode);
begin
  TThread.CreateAnonymousThread(procedure
   var
    v, varr: Variant;
    Xlo,Xhi, x, Ylo, Yhi, y, i: Integer;
    r: IReport;
    notes, sht, cell, ranges, n, root, metr: IXMLNode;
    Sheet, Range: Variant;
    Path: string;
    rngarr, Indarr, xyarr: TArray<string>;
    d: Double;
    s: string;
  begin
    try
      CoInitialize(nil);
      // открываем шаблон
      r := GlobalCore as IReport;
      r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\'+ReportShablon);
      notes := LoadXMLDocument(ExtractFilePath(ParamStr(0))+'Devices\'+ReportXML).DocumentElement;
      root := Data;
      //Tdebug.Log(Root.NodeName);
      for sht in Xenum(notes) do
       begin
        // открываем sheet
        try
        if sht.HasAttribute('SheetByIndex') then Sheet := r.Document.GetSheets.getByIndex(sht.Attributes['SheetByIndex'])
        else if sht.HasAttribute('SheetByName') then Sheet := r.Document.GetSheets.getByName(sht.Attributes['SheetByName'])
        else raise Exception.Create('Error SheetByIndex SheetByName');
        // заполняем единичные ячейки
        cell := sht.ChildNodes.FindNode('CELL');
        if Assigned(cell) then
          for n in XEnumAttr(cell) do
            try
             if TryValX(Root, n.NodeValue, v) and not VarIsNull(v) then
               begin
                if TryStrToFloat(v, d) then
                  Sheet.getCellRangeByName(n.NodeName).getCellByPosition(0,0).SetValue(d)
                else
                  Sheet.getCellRangeByName(n.NodeName).getCellByPosition(0,0).SetString(v)
               end
            else
              raise Exception.CreateFmt('Нет пути %s %s', [n.NodeName, n.NodeValue]);
            except
             on E: Exception do TDebug.DoException(E);
            end;
        // заполняем массивы ячеек СЧИТАЕМ ИХ КАК Double !!!
        ranges := sht.ChildNodes.FindNode('RANGES');
        if Assigned(ranges) then for n in XEnum(ranges) do
         begin
          // диапазон для офиса  С11 -С22
          rngarr := string(n.Attributes['Cells']).Split([' '], TStringSplitOptions.ExcludeEmpty);
          // диапазон для STEPi калибровки
          Indarr := string(n.Attributes['DataIndex']).Split([' '], TStringSplitOptions.ExcludeEmpty);
          if Length(rngarr) <> Length(Indarr) then raise Exception.Create(' Length(Cells) <> Length(DataIndex)');
          for i := 0 to Length(rngarr)-1 do
           try
            xyarr := Indarr[i].Trim.Split([':'], TStringSplitOptions.ExcludeEmpty);
            Xlo := xyarr[0].ToInteger;
            XHi := xyarr[1].ToInteger;
            Ylo := xyarr[2].ToInteger;
            YHi := xyarr[3].ToInteger;
            { TODO : check rng and X Y }
            // заполняем массив
            varr := VarArrayCreate([0, Xhi-Xlo, 0, Yhi-Ylo], varVariant);
            for x := Xlo to Xhi do
             for y := Ylo to Yhi do
              begin
               path := Format(n.Attributes['Source'], [x, y]);
               if TryValX(Root, path, v) then
                if VarIsNull(v) then varr[x-Xlo, y-Ylo] := ''
                else if TryStrTofloat(v, d) then varr[x-Xlo, y-Ylo] := d
                     else varr[x-Xlo, y-Ylo] := string(v)
               else
                 raise Exception.CreateFmt('Нет пути %s ', [path]);
              end;
            // пишим в офис
            Range := Sheet.getCellRangeByName(rngarr[i]);
            Range.setDataArray(varr);
           except
            on E: Exception do TDebug.DoException(E);
           end;
         end;
       except
         on E: Exception do TDebug.DoException(E);
       end;
       end;
      r.SaveAs(TPath.ChangeExtension(ReportFile,TPath.GetExtension(ReportShablon)));
      CoUnInitialize();
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

end.
