unit MagniProTool;

interface

uses  debug_except,
    System.SysUtils, System.Classes, System.Types, System.IOUtils, Winapi.Windows;

function MagniProGetLastAmp: Double;

implementation


const MAGP = 'MAGNIPRO';
const FAIL = 'magnidat.txt';
//0000212;29391.0;08:48:18 01.02.22;??°??'??.???"?;???°??'??.???"?;31718;

Function Tail( const filename: string ): AnsiString;
Const
  blocksize= 150; // adjust as required
Var
  fs: TFileStream;
  numbytes: Cardinal;
  n: Integer;
begin
  fs:= TFileStream.Create( filename, fmOpenRead or fmShareDenyNone );
  try
    numbytes := blocksize;
    If fs.Size > numbytes then
      fs.Seek( -numbytes, soFromEnd )
    Else
      numbytes := fs.Size;
    SetLength( Result, numbytes );
    fs.ReadBuffer( Result[1], numbytes );
  finally
    fs.free
  end;
  If numbytes = blocksize Then Begin
    // eliminate potential partial line at start
    n:= Pos( #10, Result );
    If n > 0 Then
      Delete( Result, 1, n );
  End;
end;

procedure GetVolInfo(const name: string; var VolLabel: string);
var
  SerialNum: DWord;
  A,B: DWord;
  C: array [0..255] of Char;
  Buffer: array [0..255] of Char;
begin
  if GetVolumeInformation(
    PChar(name),
    Buffer,
    256,
    @SerialNum,
    A,
    B,
    C,
    256) then
    begin
      VolLabel := string(PChar(@Buffer[0]));
    end;
end;

function MagniProGetLastAmp: Double;
var
  Drives: TStringDynArray;
  Drive, a, last: string;
begin
  Drives := TDirectory.GetLogicalDrives;
  for Drive in Drives do
   begin
     GetVolInfo(Drive, a);
     if a = MAGP then
      begin
       last := Tail(Drive+FAIL);
       a := last.Split([';'], TStringSplitOptions.ExcludeEmpty)[1];
       Exit(StrToFloat(a));
      end;
    end;
   raise ENeedDialogException.Create('(MagniPro) Амплитуда магнитного поля не считана');
end;

end.
