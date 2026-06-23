unit XMLScript.Report;

interface

uses  XMLScript, tools, debug_except, MathIntf, System.UITypes, XMLScript.math, Winapi.GDIPAPI, RootImpl, ExtendIntf,
      Winapi.ActiveX, Container, Xml.XMLDoc,
      SysUtils, o_iinterpreter, o_ipascal, Xml.XMLIntf, System.Generics.Collections, System.Classes, math, System.Variants;

type
  TXMLScriptReport = class
  private
    class procedure ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: variant);
    class constructor Create;
    class destructor Destroy;
    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
  end;


implementation

{ TXMLScriptReport }

class function TXMLScriptReport.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
begin
  if SameText(MethodName, 'ExportToCalc') then ExportToCalc(Params[0],Params[1],Params[2],Params[3]);
end;

class constructor TXMLScriptReport.Create;
begin
  TXmlScriptInner.RegisterMethods([
  'procedure ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: variant)'], CallMeth);
end;

class destructor TXMLScriptReport.Destroy;
begin

end;
                                                    //только имя файла       файла и путь    %DEV%.Метрология.%modul%     //
class procedure TXMLScriptReport.ExportToCalc(const ReportShablon, ReportXML, ReportFile: string; Data: variant);
begin
 // if GkNgk = 'NGK' then  root := NewTrr.TNGK else root := NewTrr.TGK;
//  if not TVxmlData(Data).Node.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
//     raise EBaseException.Create('Параметры метрологии не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    v, varr: Variant;
    Xlo,Xhi, x, Ylo, Yhi, y, i: Integer;
    r: IReport;
    notes, sht, cell, ranges, n, root: IXMLNode;
    Sheet, Range: Variant;
    Path: string;
    rngarr, Indarr, xyarr: TArray<string>;
    fs: TFormatSettings;
  begin
    try
      CoInitialize(nil);
      // формат windows
      fs := FormatSettings;
      fs.DecimalSeparator := (GlobalCore as Iproject).DecimalSeparator;

      // открываем шаблон
      r := GlobalCore as IReport;
      r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\'+ReportShablon);
      notes := LoadXMLDocument(ExtractFilePath(ParamStr(0))+'Devices\'+ReportXML).DocumentElement;
      root := TVxmlData(Data).Node;
      Tdebug.Log(Root.NodeName);
      for sht in Xenum(notes) do
       begin
        // открываем sheet
        if sht.HasAttribute('SheetByIndex') then Sheet := r.Document.GetSheets.getByIndex(sht.Attributes['SheetByIndex'])
        else if sht.HasAttribute('SheetByName') then Sheet := r.Document.GetSheets.getByName(sht.Attributes['SheetByName'])
        else raise Exception.Create('Error SheetByIndex SheetByName');

        // заполняем единичные ячейки
        cell := sht.ChildNodes.FindNode('CELL');
        if Assigned(cell) then
          for n in XEnumAttr(cell) do
            try
             if TryValX(Root, n.NodeValue, v) then
               Sheet.getCellRangeByName(n.NodeName).getCellByPosition(0,0).SetString(v)
            else
              raise Exception.CreateFmt('Нет пути %s %s', [n.NodeName, n.NodeValue]);
            except
             on E: Exception do TDebug.DoException(E);
            end;

        // заполняем массивы ячеек
        ranges := sht.ChildNodes.FindNode('RANGES');
        if Assigned(ranges) then for n in XEnum(ranges) do
         begin
          // диапазон для офиса  С11 -С22
          rngarr := string(n.Attributes['Cells']).Split([' '], ExcludeEmpty);
          // диапазон для STEPi калибровки
          Indarr := string(n.Attributes['DataIndex']).Split([' '], ExcludeEmpty);
          if Length(rngarr) <> Length(Indarr) then raise Exception.Create(' Length(Cells) <> Length(DataIndex)');
          for i := 0 to Length(rngarr)-1 do
           try
            xyarr := Indarr[i].Trim.Split([':'], ExcludeEmpty);
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
                  varr[x-Xlo, y-Ylo] :=  Double(v).ToString(fs)
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
       end;
      r.SaveAs(ReportFile);
      CoUnInitialize();
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

end.
