unit RLDataSet;

interface

uses System.IOUtils,  System.Generics.Collections, Data.DB, Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls;


type

  PRecBuffer = ^TRecBuffer;
  TRecBuffer = record
    BookmarkFlag: TBookmarkFlag;
    ID: Integer;
  end;


///  T1RLDataSet = class(TCustomClientDataSet);

  TRDataSet = class(TDataSet)
  private
  protected
    FCurrent: Integer;
    function GetActiveRecBuf(var RecBuf: PRecBuffer): Boolean;
    // буферизация
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;
    function GetRecordSize: Word; override;
    //закладки
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); override;
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); override;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;
    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;
    procedure InternalGotoBookmark(Bookmark: TBookmark); override;
    // маршрутизация
    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
    procedure SetRecNo(Value: Integer); override;
    function GetRecNo: Integer; override;
    // open close
    procedure InternalClose; override;
    procedure InternalOpen; override;
    // другое
    procedure InternalHandleException; override;
  end;

implementation

{$REGION 'TRLDataSet'}

{ TRLDataSet }

function TRDataSet.GetRecordSize: Word;
begin
  Result := SizeOf(TRecBuffer);
end;

function TRDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  GetMem(Result, RecordSize);
  InternalInitRecord(Result);
end;

procedure TRDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  FreeMem(Buffer);
  Buffer := nil;
end;

procedure TRDataSet.InternalInitRecord(Buffer: TRecordBuffer);
begin
  FillChar(Buffer^, RecordSize, 0);
end;

procedure TRDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
begin
  PInteger(@Data[0])^ := PRecBuffer(Buffer).ID;
end;

procedure TRDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
begin
  PRecBuffer(Buffer).ID := PInteger(@Data[0])^;
end;

function TRDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  Result := PRecBuffer(Buffer).BookmarkFlag;
end;

procedure TRDataSet.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
  PRecBuffer(Buffer).BookmarkFlag := Value;
end;

procedure TRDataSet.InternalGotoBookmark(Bookmark: TBookmark);
begin
  FCurrent := PInteger(@Bookmark[0])^-1;
end;

procedure TRDataSet.InternalHandleException;
begin
  raise Exception(ExceptObject);
end;

function TRDataSet.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
begin
  Result := grOK; // default
  case GetMode of
    gmNext: // move on
      if FCurrent < RecordCount - 1 then Inc(FCurrent)
      else Result := grEOF; // end of file
    gmPrior: // move back
      if FCurrent > 0 then Dec(FCurrent)
      else Result := grBOF; // begin of file
    gmCurrent: // check if empty
      if FCurrent >= RecordCount then Result := grEOF;
  end;
  if Result = grOK then
    with PRecBuffer(Buffer)^ do
    begin
     InternalInitRecord(Buffer);
     ID := FCurrent+1;
     BookmarkFlag := bfCurrent;
    end;
end;

procedure TRDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  FCurrent := PRecBuffer(Buffer).ID-1;
end;

procedure TRDataSet.InternalLast;
begin
  FCurrent := RecordCount;
end;

procedure TRDataSet.InternalFirst;
begin
  FCurrent := -1;
end;

function TRDataSet.GetRecNo: Integer;
begin
  Result := FCurrent + 1;
end;

procedure TRDataSet.SetRecNo(Value: Integer);
begin
  if Value <> (FCurrent + 1) then
  begin
    DoBeforeScroll;
    FCurrent := Min(max(1, Value), RecordCount)-1;
    Resync([]);
    DoAfterScroll;
  end;
end;

procedure TRDataSet.InternalClose;
begin
  BindFields(False);
  DestroyFields;
end;

procedure TRDataSet.InternalOpen;
begin
  BookmarkSize := SizeOf(Integer);
  FieldDefs.Updated := False;
  FieldDefs.Update;
  FieldDefList.Update;
  CreateFields;
  BindFields(True);
  InternalFirst;
end;

function TRDataSet.GetActiveRecBuf(var RecBuf: PRecBuffer): Boolean;
begin
  case State of
    dsBrowse:
      if IsEmpty then
        RecBuf := nil
      else
        RecBuf := PRecBuffer(ActiveBuffer);
    dsEdit, dsInsert:
      RecBuf := PRecBuffer(ActiveBuffer);
    dsCalcFields:
      RecBuf := PRecBuffer(CalcBuffer);
    dsFilter:
      RecBuf := PRecBuffer(TempBuffer);
    else
      RecBuf := nil;
  end;
  Result := RecBuf <> nil;
end;

{$ENDREGION 'TRLDataSet'}


end.
