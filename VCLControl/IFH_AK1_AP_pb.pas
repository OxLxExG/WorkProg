//-Акустический профилемер в ПРОЦЕССЕ БУРЕНИЯ.
unit IFH_AK1_AP_pb;

interface

uses Dialogs, SysUtils, Forms,Windows,Graphics;

procedure transform_Ap_pb(k: byte);

implementation

uses Unit_FB, cwtbar, Controls, Calip3;

Type
  Taccel = packed record
    X,Y,Z: SmallInt;
  end;

  TFkd = packed record
    d0: array[0..680] of SmallInt;
    d1,d2,d3,d4,d5,d6,d7,d8: array[0..681] of SmallInt;
  end;

  TFkd2 = packed record
    d0: array[0..678] of SmallInt;
    d1,d2,d3,d4,d5,d6,d7,d8: array[0..681] of SmallInt;
  end;

 TProfilemerData = packed record
   Time: Integer;
   Acccel: Taccel;
   T: word;
   AmpH: word;
   Fkd: TFkd;
 end;

 TProfilemerData2 = packed record
   Time: Integer;
   Acccel: Taccel;
   T: single;
   AmpH: word;
   GK: word;
   Fkd: TFkd2;
 end;

var   f: file of TProfilemerData3;
    fap: file of word;
     fe: file of longint;

procedure IFH_Ap_2_2;  //-Новый формат от 21.09.2015
var cs:array[0..6] of longint;  //if
    cs0:array[0..6128] of word; //ak1
    ai: TProfilemerData3; //ifh      12288 байт.
    Count, n: longint;
begin
   Count := FileSize(f);// div Size;
   n := 0;
   cs[0] := 0;
   while not eof(f) do begin
      if n >= count then begin
         Application.ProcessMessages;
         exit;
      end;
      Application.ProcessMessages;
      //-Блок файла *.if = 7 слов = 28 байт.
      BlockRead(f, ai, 1);
      if ai.Time = -1
        then continue;

      if (ai.Time = 0) and (n > 0)
        then ai.Time := cs[0] + 1;  //-номера кадра

      cs[0] := ai.Time;  //-номера кадра
      cs[1] := ai.Acccel.X;
      cs[2] := ai.Acccel.Y;
      cs[3] := ai.Acccel.Z;
      cs[4] := round(ai.T*100);
      cs[5] := ai.AmpH;
      cs[6] := ai.GK;
      BlockWrite(fe, cs, 7);

      //-Блок файла *.ak1
      //-Блок файла *.ak1 = Nкадра - 2 слова * 2 = 4 байта
      //-Блок файла *.ak1 = ФКД - 9*682 = 6138 слов * 2 = 12276 б.

      cs0[0] := ai.Time mod 10;  //-номера кадра
      cs0[1] := ai.Time div 10;  //-номера кадра
      BlockWrite(fap, cs0, 2);

      BlockWrite(fap, ai.Fkd.d0, SizeOf(ai.Fkd.d0));
      BlockWrite(fap, ai.Fkd.d1, SizeOf(ai.Fkd.d1));
      BlockWrite(fap, ai.Fkd.d2, SizeOf(ai.Fkd.d2));
      BlockWrite(fap, ai.Fkd.d3, SizeOf(ai.Fkd.d3));
      BlockWrite(fap, ai.Fkd.d4, SizeOf(ai.Fkd.d4));
      BlockWrite(fap, ai.Fkd.d5, SizeOf(ai.Fkd.d5));
      BlockWrite(fap, ai.Fkd.d6, SizeOf(ai.Fkd.d6));
      BlockWrite(fap, ai.Fkd.d7, SizeOf(ai.Fkd.d7));
      BlockWrite(fap, ai.Fkd.d8, SizeOf(ai.Fkd.d8));
      //-Дописываем 3 слова => все блоки по 682 слова.
      BlockWrite(fap, ai.Fkd.d0[676], 3);
      //-Остальные 8 датчиков.
      BlockWrite(fap, ai.Fkd.d1, 682);
      BlockWrite(fap, ai.Fkd.d2, 682);
      BlockWrite(fap, ai.Fkd.d3, 682);
      BlockWrite(fap, ai.Fkd.d4, 682);
      BlockWrite(fap, ai.Fkd.d5, 682);
      BlockWrite(fap, ai.Fkd.d6, 682);
      BlockWrite(fap, ai.Fkd.d7, 682);
      BlockWrite(fap, ai.Fkd.d8, 682);
      inc(n);
//      if (n mod 50) = 0
//          then CWT_Bar.ProgressBar1.Position := n;
//      Application.ProcessMessages;
//      if not CWT_Bar.Visible
//         then exit;
    end;
end;

procedure transform_AP_pb(k:byte);
var ExtName, Dir: string;
    Op: TOpenDialog;
    nameIf, nameAk1, nameIfh: String;
begin
  Dir := GetCurrentDir;
  Op := TOpenDialog.Create(nil);
  Op.Filter := '(*.Bin)|*.BIN|';
  Op.DefaultExt := 'bin';
//  Op.InitialDir := FB.Dir_aktiv;
  if Op.Execute then begin
    ExtName := UpperCase(ExtractFileExt(Op.FileName));
    if ExtName = '.BIN' then begin
      nameIfh := Op.FileName;
      nameIf := ChangeFileExt(nameIfh, '.if');
      nameAk1 := ChangeFileExt(nameIfh, '.ak1');

      AssignFile(f, nameIfh);
      Reset(f);
      AssignFile(fe, nameIf);
      Rewrite(fe);
      AssignFile(fap, nameAk1);
      Rewrite(fap);
  try
//      CWT_Bar := TCWT_Bar.Create(nil);
//      CWT_Bar.Caption := 'Подождите, идет процесс преобразования...';
//      CWT_Bar.ProgressBar1.Max := FileSize(f);
//      CWT_Bar.Show;
      IFH_AP_2_2;

   finally
      CloseFile(f);
      CloseFile(fe);
      CloseFile(fap);

//      CWT_Bar.Close;
//      CWT_Bar.Free;
//      CWT_Bar := nil;
  end;
    end;
    SetCurrentDir(Dir);
    Op.Free;
  end;
end;

end.
