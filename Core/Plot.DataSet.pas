unit Plot.DataSet;

interface

uses sysutils, Classes, Controls, Db, VCL.forms, debug_except, IDataSets;

type
  PBuffer = ^TBuffer;

  TBuffer = record
    BookmarkData: Integer;
    BookmarkFlag: TBookmarkFlag;
  end;

  TPlotDataSet = class(TIDataSet)
  private
    FActive: Boolean;
    FRealRecordPos: Integer;
    procedure SetRecordPosition(const Value: Integer);
  protected
  // create, close, and so on
    procedure InternalOpen; override;
    procedure InternalClose; override;
    function IsCursorOpen: Boolean; override;
  // memory management
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    function GetRecordSize: Word; override;
// movement and optional navigation (used by grids)
    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
    function GetRecordCount: Integer; override;
    function GetRecNo: Integer; override;
    procedure SetRecNo(Value: Integer); override;

    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override;
     // bookmarks
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;
    procedure SetBookmarkFlag(Buffer:TRecordBuffer; Value: TBookmarkFlag); override;
    procedure InternalGotoBookmark(Bookmark: Pointer); override;
    property RecordPos: Integer read FRealRecordPos write SetRecordPosition;
    function getID(pos: Integer): Integer;
  public
    function GetCurrentRecord(Buffer: TRecBuf): Boolean; override;
    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
  end;


implementation

{ TPlotDataSet }


function TPlotDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  GetMem(Result, SizeOf(TBuffer));
  InternalInitRecord(Result);
end;

procedure TPlotDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  FreeMem(Buffer);
  Buffer := nil;
end;

procedure TPlotDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  PBuffer(Data)^ := PBuffer(Buffer)^;
end;

function TPlotDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  Result := PBuffer(Buffer).BookmarkFlag
end;

function TPlotDataSet.GetCurrentRecord(Buffer: TRecBuf): Boolean;
begin
  Result := False;
  if not IsEmpty and (GetBookmarkFlag(ActiveBuffer) = bfCurrent) then
  begin
    UpdateCursorPos;
    if (RecordPos >= 0) and (RecordPos < RecordCount) then
    begin
     PBuffer(Buffer).BookmarkData := RecordPos;
     PBuffer(Buffer).BookmarkFlag := bfCurrent;
     Result := True;
    end;
  end;
end;

function TPlotDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
 var
  s: AnsiString;
begin
  if IsEmpty then Exit(False);
  if Field.FieldName = 'Field1' then
   begin
    Pinteger(Buffer)^ := getID(PBuffer(ActiveBuffer).BookmarkData)
   end
  else if Field.FieldName = 'Field2' then
   begin
    case PBuffer(ActiveBuffer).BookmarkFlag of
      bfCurrent: s := 'Current';
      bfBOF: s := 'BOF';
      bfEOF: s := 'EOF';
      bfInserted: s := 'Inserted';
    end;
    Move(s[1], Buffer[0], Length(s)*SizeOf(AnsiChar));
   end;
  Result := True;
end;

function TPlotDataSet.getID(pos: Integer): integer;
begin
//Result := RecordCount - pos - 1; // pos
  Result := pos;
end;

function TPlotDataSet.GetRecNo: Integer;
begin
  CheckActive;
  UpdateCursorPos;
  Result := RecordPos;
end;

function TPlotDataSet.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
begin   // Дать запись. Космический код ! Править нельзя !
  Result := grOk;
  if not Assigned(Buffer) then Exit(grError);

  //Accept := True;
//  _CheckPositionCursor(RecordPos);
  case GetMode of
   gmPrior: begin   // Предыдущую
      if RecordPos <= 0 then
       begin  // Предыдущих нет
        Result := grBof;
        RecordPos := -1;
       end
      else
       begin
        RecordPos := RecordPos-1;
       { repeat // Пролистаем отфильтрованые
         RecordPos:=RecordPos-1;
         //Accept := _RecordFilter;
         //if Filtered then Accept := _RecordFilter;
        until Accept or (RecordPos =  0);
        if not Accept then
         begin
          Result := grBOF;
          RecordPos := -1;
        end;}
       end;
    end;
   gmCurrent: begin  // Текущую
     if (RecordPos < 0) or (RecordPos >= RecordCount) then Result := grError
//     else if Filtered then
//      if not _RecordFilter then Result := grError;
    end;
   gmNext: begin  // Следующую
      if (RecordPos >= RecordCount - 1) then Result := grEof
      else
       begin
         RecordPos := RecordPos + 1;
     {   repeat  // Пролистаем отфильтрованные
         RecordPos := RecordPos + 1;
         Accept := _RecordFilter;
         //if Filtered then Accept := _RecordFilter;
        until Accept or ((RecordPos > RecordCount - 1) and FIsFechAll);
        if not Accept then
         begin
          Result := grEOF;
          RecordPos := RecordCount - 1;
         end;}
       end;
    end;
  end;
  if Result = grOk then
   begin // Проверки на здравый смысл
     PBuffer(Buffer).BookmarkData := RecordPos;
     PBuffer(Buffer).BookmarkFlag := bfCurrent;
//     GetCalcFields(Buffer);
   end
  else
   if (Result = grError) and DoCheck then DatabaseError('str_No_Record', Self);
end;

function TPlotDataSet.GetRecordCount: Integer;
begin
  Result := 3000;
end;

function TPlotDataSet.GetRecordSize: Word;
begin
  Result := SizeOf(TBuffer);
end;

procedure TPlotDataSet.InternalClose;
begin
  FActive := False;
  if DefaultFields then  DestroyFields;
end;

procedure TPlotDataSet.InternalFirst;
begin
  RecordPos := -1;
end;

procedure TPlotDataSet.InternalGotoBookmark(Bookmark: Pointer);
begin
  RecordPos := PBuffer(Bookmark).BookmarkData
end;

procedure TPlotDataSet.InternalHandleException;
begin
  Application.HandleException(Self);
end;

procedure TPlotDataSet.InternalInitFieldDefs;
begin
    with FieldDefs.AddFieldDef do
    begin
      DataType := ftInteger;
      Name := 'Field1';
    end;
    with FieldDefs.AddFieldDef do
    begin
      DataType := ftString;
      Size := 10;
      Name := 'Field2';
    end;
end;

procedure TPlotDataSet.InternalInitRecord(Buffer: TRecordBuffer);
begin
//  PBuffer(Buffer).BookmarkData := RecordPos;
//  PBuffer(Buffer).BookmarkFlag := bfCurrent;
end;

procedure TPlotDataSet.InternalLast;
begin
  RecordPos := GetRecordCount -1;
end;

procedure TPlotDataSet.InternalOpen;
begin
  BookmarkSize := Sizeof(TBuffer);
  RecordPos := -1;
  FActive := True;
  FieldDefs.Updated := False;
  FieldDefs.Update;
  FieldDefList.Update;
//  InitFieldDefsFromFields;
  if DefaultFields then CreateFields;
  BindFields(True);
//  ActivateBuffers;
end;

procedure TPlotDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  RecordPos := PBuffer(Buffer).BookmarkData;
//  PBuffer(Buffer).BookmarkFlag := bfCurrent;
end;

function TPlotDataSet.IsCursorOpen: Boolean;
begin
  Result := FActive
end;

procedure TPlotDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  PBuffer(Buffer)^ := PBuffer(Data)^;
end;

procedure TPlotDataSet.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
  PBuffer(Buffer).BookmarkFlag := Value;
end;

procedure TPlotDataSet.SetRecNo(Value: Integer);
begin
  if (Value >= 0) and (Value < RecordCount) then
  begin
    DoBeforeScroll;
    RecordPos := Value;
    Resync([]);
    DoAfterScroll;
  end;
end;

procedure TPlotDataSet.SetRecordPosition(const Value: Integer);
begin
  FRealRecordPos := Value;
end;

end.
