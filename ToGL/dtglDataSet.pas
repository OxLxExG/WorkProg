unit dtglDataSet;

interface

uses System.IOUtils,  System.Generics.Collections, Data.DB, Math,  Datasnap.DBClient, RLDataSet, System.DateUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls;

type
  TRecData = record
   idx: Integer;
   datetime: TDateTime;
   depth: Double;
  end;
//  TMaxMinDepth = record
//   min: TRecData;
//   max: TRecData;
//  end;
  TfileRecData = packed record
   datetime: TDateTime;
   depth: Double;
  end;
  TMaxMinDepth = record
   min: TfileRecData;
   max: TfileRecData;
  end;

 TdtglDataSet = class(TRDataSet)
 private
   FStream: TFileStream;
   FName: string;
   FBinFile: string;
   FRecCount: Integer;
   FCurrentID: Integer;
   FCurrentGlu: TfileRecData;
   FCurrentTimeStamp: TTimeStamp;
 protected
   procedure InternalClose;  override;
   procedure InternalHandleException;  override;
   procedure InternalInitFieldDefs;  override;
   procedure InternalOpen;  override;
   function GetRecordCount: Integer; override;
   function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
  public
    DataStart: TfileRecData;
    DataEnd: TfileRecData;
    DeltaTime: Integer;
    constructor Create(AOwner: TComponent; const fName: string; ClearTmp: Boolean); reintroduce;
    function GetMaxMinDept(fromTime, toTime: TDateTime): TMaxMinDepth;
    function IsCursorOpen: Boolean;  override;
    property Stream: TFileStream read FStream;
    property FileName: string  read FName;
    property BinFile: string read FBinFile;
 end;

implementation


constructor TdtglDataSet.Create(AOwner: TComponent; const fName: string; ClearTmp: Boolean);
begin
  inherited Create(AOwner);
  Self.FName := fName;
  FBinFile:= TPath.ChangeExtension(fName, 'dtgl');
  if ClearTmp and TFile.Exists(FBinFile) then TFile.Delete(FBinFile);
end;

function TdtglDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
 var
  ab: PRecBuffer;
begin
  Result := false;
  if Field.IsBlob then Exit(False);
  if not GetActiveRecBuf(ab) then Exit;

  if Field.FieldNo = 1 then
   begin
    SetLength(Buffer, sizeof(Integer));
    PInteger(Buffer)^ := ab.ID;
    Exit(True);
   end;
  if ab.ID <> FCurrentID then
   begin
     FCurrentID := ab.ID;
     FStream.Seek(Int64(ab.ID-1)*SizeOf(TfileRecData), soBeginning);
     FStream.Read(FCurrentGlu, SizeOf(TfileRecData));
     FCurrentTimeStamp := DateTimeToTimeStamp(FCurrentGlu.datetime);
   end;
  if Field.FieldNo = 2 then
   begin
    SetLength(Buffer, sizeof(Cardinal));
    PCardinal(Buffer)^ := FCurrentTimeStamp.Date;
    Exit(True);
   end;
  if Field.FieldNo = 3 then
   begin
    SetLength(Buffer, sizeof(Cardinal));
    PCardinal(Buffer)^ := FCurrentTimeStamp.Time;
    Exit(True);
   end;
  if Field.FieldNo = 4 then
   begin
    SetLength(Buffer, sizeof(Double));
    PDouble(Buffer)^ := FCurrentGlu.depth;
    Exit(True);
   end;
end;

function TdtglDataSet.GetMaxMinDept(fromTime, toTime: TDateTime): TMaxMinDepth;
 var
 cur: TfileRecData;
begin
  DisableControls;
  try
    FStream.Seek(0, soBeginning);
    FStream.Read(cur, SizeOf(TfileRecData));
    Result.min := cur;
    Result.max := cur;
    while FStream.Read(cur, SizeOf(TfileRecData)) = SizeOf(TfileRecData) do
     begin
      if cur.datetime < fromTime then Continue
      else if cur.datetime > toTime then Break;
      if cur.depth >= Result.max.depth then Result.max := cur
      else if cur.depth <= Result.min.depth then Result.min := cur;
     end;
  finally
   EnableControls;
  end;
end;

function TdtglDataSet.GetRecordCount: Integer;
begin
  Result := FRecCount;
end;

procedure TdtglDataSet.InternalClose;
begin
  inherited;
  FreeAndNil(FStream);
end;

procedure TdtglDataSet.InternalHandleException;
begin
  Application.HandleException(self);
end;

procedure TdtglDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  var fn := 1;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftInteger;
    FieldNo := fn;Inc(fn);
    Name := 'ID';
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftDate;
    FieldNo := fn;Inc(fn);
    Name := 'Date';
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftTime;
    FieldNo := fn;Inc(fn);
    Name := 'Time';
  end;
  with FieldDefs.AddFieldDef do
  begin
    DataType := ftFloat;
    FieldNo := fn;Inc(fn);
    Name := 'Depth';
  end;
//  with FieldDefs.AddFieldDef do
//  begin
//    Attributes:= [faHiddenCol];
//    DataType := ftFloat;
//    FieldNo := fn;Inc(fn);
//    Name := 'DateTime';
//  end;
end;

procedure TdtglDataSet.InternalOpen;
// var
//  FStrings: TStrings;
//  FLineFrom: Integer;
begin
//  FBinFile := TPath.ChangeExtension(FileName, 'dtgl');
//  if not TFile.Exists(BinFile) then
//   begin
//    FStrings := TStringList.Create;
//    try
//      FStrings.NameValueSeparator := FSeparator;
//      FStrings.LoadFromFile(FName);
//      FLineFrom := 0;
//      try
//        FStrings.ValueFromIndex[0].ToDouble;
//      except
//        FLineFrom := 1;
//      end;
//      // check true data
//      for var i: Integer := FLineFrom to FLineFrom+10 do
//       begin
//        var rd :TfileRecData;
//        rd.datetime := StrToDateTime(FStrings.Names[i]);
//        rd.depth := FStrings.ValueFromIndex[i].ToDouble;
//       end;
//      try
//        FStream := TFileStream.Create(BinFile, fmCreate);
//        for var i: Integer := FLineFrom to FStrings.Count-1 do
//         begin
//          var rd :TfileRecData;
//          rd.datetime := StrToDateTime(FStrings.Names[i]);
//          rd.depth := FStrings.ValueFromIndex[i].ToDouble;
//          FStream.Write(rd, SizeOf(rd));
//         end;
//      finally
//        FStream.Free;
//      end;
//    finally
//      FStrings.Free;
//    end;
//   end;
  FStream := TFileStream.Create(BinFile, fmOpenRead);
  FRecCount := FStream.Size div SizeOf(TfileRecData);
  FStream.Seek(0, soBeginning);
  FStream.Read(DataStart, SizeOf(TfileRecData));
  FStream.Read(FCurrentGlu, SizeOf(TfileRecData));
  FStream.Seek(-SizeOf(TfileRecData), soEnd);
  FStream.Read(DataEnd, SizeOf(TfileRecData));
  DeltaTime := MilliSecondsBetween(FCurrentGlu.datetime, DataStart.datetime);
  inherited;
end;

function TdtglDataSet.IsCursorOpen: Boolean;
begin
  Result := Assigned(FStream);
end;

end.
