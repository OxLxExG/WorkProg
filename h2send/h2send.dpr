program h2send;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.classes,
  System.Generics.Collections,
  GeneratorMetaData in 'GeneratorMetaData.pas';

begin
  try
    if ParamCount < 3 then raise Exception.Create('ParamCount < 3');
    var p1 := ParamStr(1);
    var p2 := ParamStr(2);
    var p3 := ParamStr(3);
    var ss := TstringList.Create;
    var tokens: TArray<TArray<string>>;
    try
      ss.LoadFromFile(p1);
      for var s in ss do
       begin
         var sc := s;
         var sub := '';
         // remove comments
         var ci := sc.IndexOf('//');
         if (ci >=0) and not sc.Contains('//%') then
          begin
           sc := sc.Remove(ci);
          end;

         sc := sc.Replace('#', ' # ')
                    .Replace(';', ' ; ')
                    .Replace('//%', ' //% ')
                    .Replace('/*', ' /* ')
                    .Replace('*/', ' */ ')
                    .Replace('=', ' = ')
                    .Replace('[', ' [ ')
                    .Replace(']', ' ] ');
         var a := sc.Split([' ', #9],TStringSplitOptions.ExcludeEmpty);

         tokens := tokens + [a];
       end;

      ss.Clear;

      var p := TGeneratorMetaData.Create(tokens);
      p.Parse;
      p.Generate(ss, p3);
      ss.SaveToFile(p2);
    finally
      ss.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
