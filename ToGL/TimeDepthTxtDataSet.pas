unit TimeDepthTxtDataSet;

interface

uses dtglDataSet,
  System.IOUtils,  System.Generics.Collections, Data.DB, Math,  Datasnap.DBClient, RLDataSet, System.DateUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls;

type
 TTimeDepthTxtDataSet = class(TdtglDataSet)
 private
  type
   EDtType = (etDelphi,etString,etUnix);
  var
   Fspliters: array of char;
   FdtFormat: string;
   Fy: integer;
   Fm: integer;
   Fd: integer;
   Fh: integer;
   Fn: integer;
   Fs: integer;
   function Str2DT(const sdt:string):TdateTime;
   function FindTypeStringDatetype(const dt: string): EDtType;
   function ToDt(const dt:string; t:EDtType):TDateTime;
 protected
   procedure InternalOpen;  override;
 public
   constructor Create(AOwner: TComponent; const fName: string; const DTFormat: string; ClearTmp: Boolean); reintroduce;
 end;

implementation

{ TTimeDepthTxtDataSet }

function TTimeDepthTxtDataSet.Str2DT(const sdt: string): TdateTime;
 var
   y,m,d,h,n,s: Integer;
begin
   if (Fy+Fm+Fd+Fn+Fn+Fs) = 0 then raise Exception.Create('Error Not found format');

   if Fy = 0 then y := 2000 else y := Copy(sdt,Fy,4).ToInteger;
   if Fm = 0 then m := 1 else m := Copy(sdt,Fm,2).ToInteger;
   if Fd = 0 then d := 1 else d := Copy(sdt,Fd,2).ToInteger;
   if Fh = 0 then h := 0 else h := Copy(sdt,Fh,2).ToInteger;
   if Fn = 0 then n := 0 else n := Copy(sdt,Fn,2).ToInteger;
   if Fs = 0 then s := 0 else s := Copy(sdt,Fs,2).ToInteger;
   Result := EncodeDateTime(y,m,d,h,n,s,0);
end;

// yyyymmddhhnnss
//       (N)(yyyymmdd) (N)(hhnnss)
 //yyyy-mm-ddThh:nn:ss
constructor TTimeDepthTxtDataSet.Create(AOwner: TComponent; const fName: string; const DTFormat: string; ClearTmp: Boolean);
begin
  inherited Create(AOwner, fName, ClearTmp);
  Fspliters := [' ',';','=',#9];
  if DTFormat <> '' then
  begin
    if DTFormat.Contains(' ') then Fspliters := [';','=', #9];
    FdtFormat := DTFormat;
    Fy := FdtFormat.IndexOf('y')+1;
    Fm := FdtFormat.IndexOf('m')+1;
    Fd := FdtFormat.IndexOf('d')+1;
    Fh := FdtFormat.IndexOf('h')+1;
    Fn := FdtFormat.IndexOf('n')+1;
    Fs := FdtFormat.IndexOf('s')+1;
  end;
end;

function TTimeDepthTxtDataSet.FindTypeStringDatetype(const dt: string): EDtType;
begin
  try
    Str2DT(dt);
    Exit(etString);
  except
    try
      var i := StrToInt64(dt);
      if i < 1600000000 then raise Exception.Create('Error Not Unix Time');
      Exit(etUnix);
    except
     var d := TDateTime(StrToFloat(dt));
     Exit(etDelphi);
    end;
  end;
end;

function TTimeDepthTxtDataSet.ToDt(const dt: string; t: EDtType): TDateTime;
begin
  case t of
    etDelphi: Exit(StrToFloat(dt));
    etString: Exit(Str2DT(dt));
    etUnix: Exit(UnixToDateTime(StrToInt64(dt),False));
  end;
end;

procedure TTimeDepthTxtDataSet.InternalOpen;
 var
  FStrings: TStrings;
  FLineFrom, idx: Integer;
  Str: TStream;
  tdt: EDtType;
  toall:Boolean;
begin
  if not TFile.Exists(BinFile) then
   begin
    FStrings := TStringList.Create;
    try
      FStrings.LoadFromFile(FileName);
      FLineFrom := 0;
      var tt := FStrings[0].Split(Fspliters, TStringSplitOptions.ExcludeEmpty);
      try
        tt[1].ToDouble;
      except
        FLineFrom := 1;
      end;
      // check true data
      for var i: Integer := FLineFrom to FLineFrom+10 do
       begin
        var rd :TfileRecData;
        var at := FStrings[i].Split(Fspliters, TStringSplitOptions.ExcludeEmpty);
        tdt := FindTypeStringDatetype(at[0]);
        rd.datetime := ToDt(at[0], tdt);
        rd.depth := at[1].ToDouble;
       end;
      try
        Str := TFileStream.Create(BinFile, fmCreate);
        var OldTime :TDateTime;
        for idx := FLineFrom to FStrings.Count-1 do
         begin
          var rd :TfileRecData;
          try
            var a := FStrings[idx].Split(Fspliters, TStringSplitOptions.ExcludeEmpty);
            rd.datetime := ToDt(a[0], tdt);
            if rd.datetime <= OldTime then
             begin
               if toall then Continue;

               var r := MessageDlg(Format('Error At:%d'+#$D#$A+'old %s > then %s',[idx, DateTimeToStr(OldTime), DateTimeToStr(rd.datetime)]),mtError, [mbIgnore, mbYesToAll, mbCancel],0);
               if r = mrCancel then Exit
               else if r = mrYesToAll then toall := True;

               Continue;
             end;
            OldTime := rd.datetime;
            rd.depth := a[1].ToDouble;
            Str.Write(rd, SizeOf(rd));
          except
           on E: Exception do
           begin
            var res := MessageDlg(Format('Error At:%d String:%s Msg: %s',[idx, FStrings[idx],  e.Message]),mtError, [mbIgnore, mbCancel],0);
            if res = mrCancel then Exit;
           end;
          end;
         end;
      finally
        Str.Free;
      end;
    finally
      FStrings.Free;
    end;
   end;
  inherited;
end;

end.
