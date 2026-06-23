unit XMLScript.IKN;

interface

uses  XMLScript, tools, debug_except, MathIntf, System.UITypes, XMLScript.math, Winapi.GDIPAPI, RootImpl,
      SysUtils, o_iinterpreter, o_ipascal, Xml.XMLIntf, System.Generics.Collections, System.Classes, math, System.Variants;
type
  EIkn = class(EBaseException);


  TXMLScriptIKN = class
  private
    class constructor Create;
    class destructor Destroy;
  public
    const
    DEF_VAL: array[0..42]of string =
     ('10.02.15',
      '09:52:32',
      '7',
      '230 354 500 707 1000 1414 2000',
      '4',
      '1666 666 266 106',
      '13',
      '0.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0 110.0 120.0',
      '3 6 6 6',
      '0.0 11.561644 0.0 0.0',
      '0.5 1.0',
      '0 0 0 0 0 0 0 0 0 0 0 0 0',
      '0 0 0 0 0 0 0 0 0 0 0 0 0',
      '0 0 0 0 0 0 0 0 0 0 0 0 0',
      '0 0 0 0 0 0 0 0 0 0 0 0 0',
      '1.5059461 1.5144782 1.5230104 1.5315426 1.5400748 1.548524 1.5567362 1.5665116 1.5740517 1.5775662 1.5839336 1.5871535 1.5978023',
      '0.91893271 0.92819837 0.93746404 0.94672971 0.95599537 0.9650458 0.9728206 0.98296563 0.99130989 0.99369806 1.0020668 1.0079212 1.0105523',
      '-0.21885633 -0.20781575 -0.19677518 -0.1857346 -0.17469402 -0.16382967 -0.15415459 -0.14419806 -0.13484805 -0.12796126 -0.11486422 -0.10016482 -0.10379985',
      '-2.5069624 -2.5015192 -2.496076 -2.4906328 -2.4851896 -2.4794866 -2.4733202 -2.4663511 -2.4630782 -2.4569036 -2.4456878 -2.4327214 -2.4424386',
      '1.5756011 1.5852497 1.5948983 1.6045469 1.6141955 1.6238397 1.6311723 1.6443782 1.649364 1.6462121 1.6633026 1.6712934 1.6748696',
      '0.9504968 0.96314536 0.97579392 0.98844248 1.001091 1.0137947 1.0233831 1.0440145 1.0505401 1.0404898 1.0607215 1.0672243 1.0723783',
      '-0.2227747 -0.20765008 -0.19252546 -0.17740083 -0.16227621 -0.14717427 -0.13516946 -0.11649853 -0.10651482 -0.10888263 -0.09576132 -0.083763314 -0.088206159',
      '-2.5935462 -2.5793213 -2.5650964 -2.5508715 -2.5366466 -2.5229719 -2.5133742 -2.5062388 -2.5005366 -2.4953197 -2.4869821 -2.4736476 -2.492766',
      '1.5375609 1.5478897 1.5582186 1.5685474 1.5788763 1.5902725 1.6053704 1.617824 1.6253613 1.6311733 1.6371121 1.6336401 1.6377635',
      '0.92961604 0.94364972 0.9576834 0.97171708 0.98575075 0.99996115 1.0079812 1.0224912 1.0375059 1.0407507 1.0398805 1.0372785 1.036264',
      '-0.21995563 -0.21375188 -0.20754812 -0.20134437 -0.19514062 -0.1894719 -0.18935961 -0.19024389 -0.17813333 -0.16874364 -0.15838865 -0.13245962 -0.12198081',
      '-2.6519053 -2.6455173 -2.6391294 -2.6327414 -2.6263534 -2.620271 -2.6207702 -2.6244748 -2.6299728 -2.6271901 -2.6093759 -2.5902895 -2.5922012',
      '1.17891 1.1857887 1.1926674 1.199546 1.2064247 1.2131508 1.2277018 1.2392606 1.2393889 1.2531989 1.2976656 1.3644024 1.3900317',
      '0.67926993 0.69145369 0.70363745 0.71582121 0.72800498 0.74005173 0.76355032 0.78466819 0.7908465 0.81423346 0.84398112 0.87196185 0.90875863',
      '-0.43012086 -0.40233103 -0.3745412 -0.34675136 -0.31896153 -0.29146618 -0.25440809 -0.22361907 -0.19726301 -0.16644183 -0.17716826 -0.21236431 -0.18926577',
      '-2.7198006 -2.6977173 -2.6756339 -2.6535506 -2.6314673 -2.6105128 -2.5799479 -2.5645745 -2.5345952 -2.519604 -2.5421969 -2.5644456 -2.550483',
      '0.97758836 0.99384896 1.0101096 1.0263702 1.0426307 1.0586875 1.0763388 1.1019625 1.1173246 1.1243878 1.1276029 1.1388457 1.1486343',
      '0.47214847 0.48333204 0.4945156 0.50569917 0.51688274 0.53036915 0.55081111 0.58300089 0.59890722 0.60728878 0.63318595 0.65463315 0.6632917',
      '-0.64304247 -0.64162617 -0.64020986 -0.63879356 -0.63737726 -0.63466424 -0.63161389 -0.62056289 -0.61191497 -0.59712373 -0.57466421 -0.5662092 -0.55297022',
      '-3.351566 -3.3444628 -3.3373595 -3.3302563 -3.3231531 -3.3164592 -3.3029454 -3.3124619 -3.3003635 -3.2839536 -3.2931184 -3.2899718 -3.2707389',
      '1.9383079 1.8558481 1.7733884 1.6909286 1.6084688 1.5092876 1.3198386 1.0974707 1.0108269 1.0134827 1.0337163 1.0504245 1.0581331',
      '0.99861849 0.93778579 0.87695299 0.81612019 0.75528749 0.69341711 0.66567491 0.5145757 0.44247073 0.45225597 0.43866201 0.43090034 0.45028678',
      '-1.6627379 -1.5386826 -1.4146273 -1.290572 -1.1665168 -1.019318 -0.75065609 -0.47997823 -0.39214783 -0.39611062 -0.38293901 -0.34173998 -0.32857072',
      '-3.7787031 -3.7638495 -3.7489959 -3.7341423 -3.7192887 -3.6923222 -3.5968202 -3.3734516 -3.2589167 -3.2599875 -3.2539456 -3.242217 -3.231703',
      '1.0595116 1.0588194 1.0581272 1.0574351 1.0567429 1.0476835 1.0481928 1.1212177 1.1503994 1.1593781 1.1555107 1.15085 1.1464135',
      '0.68324331 0.63444077 0.58563823 0.53683569 0.48803315 0.44770038 0.49348281 0.56674329 0.61891895 0.62721545 0.65503132 0.68091329 0.6818076',
      '-0.64374472 -0.68969711 -0.73564951 -0.78160194 -0.82755434 -0.86387404 -0.82381784 -0.81976764 -0.76354474 -0.73000982 -0.73255296 -0.74661104 -0.72113833',
      '-4.0182833 -4.014571 -4.0108588 -4.0071465 -4.0034342 -3.9932269 -3.9506721 -3.9064767 -3.8246368 -3.8230231 -3.8872952 -3.944527 -3.9471593');
     T_PRV = 'ѕроводимось';
     AT_NZ = 'N_ZND';
     AT_ALZ = 'ZND';
     AT_NF = 'N_FQ';
     AT_AK1 = 'K1';
     AT_NT = 'N_T';
     AT_AT = 'AT';
     AT_ASUM = 'ASUM';
     AT_AKR = 'AKR';
     AT_AIMAX = 'AIMAX';
     AT_INDEX: array[0..10] of Integer = (1, 4, 7, 10, 13, 16, 19, 22, 69, 72, 75);
     AT_NAME: array[0..10] of string = (AT_TIMEATT, 'TIME_TIME_ATT', AT_NZ, AT_ALZ, AT_NF, AT_AK1, AT_NT, AT_AT, AT_ASUM, AT_AKR, AT_AIMAX);
    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
    class procedure Exec_IKN_A2(v, t: Variant);
    class procedure Setup_IKN_A2(v: Variant);
    class procedure Setup_IKN(t: Variant);
    class procedure Import_IKN_A2(const TrrFile: string; NewTrr: Variant);
  end;

implementation


type
  ITrrFileIKNA2 = interface
  ['{84AF2603-720C-4169-BBFA-9D754ED4445D}']
   function ph_zero_spline(n,m: Integer; t: double): double;
   function s_from_a(da, L1, L2, w: Double): Double;
   function s_from_a_SL(da: Double; L2, k1: Integer): Double;
  end;

  TTrrFileIKNA2 = class(TIObject, ITrrFileIKNA2)
   type TTrr = TArray<TArray<TArray<Double>>>;
   var
    Fdata: TTrr;
    FarrT: TArray<Double>;
    FZnd: TArray<Double>;
    Fw: TArray<Double>;
   constructor Create(Root: IXMLNode);
   function ph_zero_spline(n, m: Integer; t: double): double;
   function s_from_a(da, L1, L2, w: Double): Double;
   function s_from_a_SL(da: Double; L2, k1: Integer): Double;
  end;

constructor TTrrFileIKNA2.Create(Root: IXMLNode);
 var
  nt,nf,nz, i,j,t: Integer;
  d: TArray<string>;
begin
  nt := Root.Attributes[TXMLScriptIKN.AT_NT];
  nf := Root.Attributes[TXMLScriptIKN.AT_NF];
  nz := Root.Attributes[TXMLScriptIKN.AT_NZ];

  SetLength(Fdata, nz+1, nf, nt);
  SetLength(FarrT, nt);
  SetLength(FZnd, nz);
  SetLength(Fw, nf);

  d := string(root.Attributes[TXMLScriptIKN.AT_AT]).Split([' ']);
  for i := 0 to nt-1 do FarrT[i] := d[i].ToDouble;

  d := string(root.Attributes[TXMLScriptIKN.AT_ALZ]).Split([' ']);
  for i := 0 to nz-1 do FZnd[i] := d[i].ToDouble;

  d := string(root.Attributes[TXMLScriptIKN.AT_AK1]).Split([' ']);
  for i := 0 to nf-1 do Fw[i] := 40e6*2*pi/d[i].ToDouble;

  for i := 0 to nz do for j := 0 to nf-1 do
   begin
    d := string(root.Attributes[Format('L%dF%d',[i,j+1])]).Split([' ']);
    for t := 0 to nt-1 do Fdata[i,j,t] := d[t].ToDouble;
   end;
end;

function TTrrFileIKNA2.ph_zero_spline(n, m: Integer; t: double): double;
 var
  ph_zero1, ph_zero2, temp2, temp1: Double;
  i, Ht: Integer;
begin
  Ht := High(FarrT);
  temp2 := FarrT[1];
  temp1 := FarrT[0];
  ph_zero2 := Fdata[n, m, 1];
  ph_zero1 := Fdata[n, m, 0];
  if t >= FarrT[0] then
   if t >= FarrT[Ht] then
   begin
    temp2 := FarrT[Ht];
    temp1 := FarrT[Ht - 1];
    ph_zero2 := Fdata[n, m, Ht];
    ph_zero1 := Fdata[n, m, Ht-1];
   end
  else for i := 1 to Ht do if t <= FarrT[i] then
   begin
    temp2 := FarrT[i];
    temp1 := FarrT[i - 1];
    ph_zero2 := Fdata[n, m, i];
    ph_zero1 := Fdata[n, m, i-1];
    Break;
   end;
  Result :=  ph_zero1 + (ph_zero2 - ph_zero1)/(temp2 - temp1) * (t - temp1);
end;

function TTrrFileIKNA2.s_from_a(da, L1, L2, w: Double): Double;
 var
  x,y, f,df: double;
  i: Integer;
begin
  if da = 0  then Exit(0);
  x := Sqrt(Abs(da));
  for i := 1 to 20 do
   begin
    f := x*(L2-L1) - abs(da) - (arctan(x*L2/(1+x*L2)) - arctan(x*L1/(1+x*L1)));
    df := (L2-L1) - (L2/(1+2*x*L2+2* x*x * L2*L2) - L1/(1+2*x*L1+2 * x*x * L1*L1));
    y := x - f/df;
    if abs((y-x)/x) < 1e-10 then
     begin
      x := y;
      break;
     end;
    x := y;
   end;
  Result := 2*x*x/(4*pi*1e-7)/w;
  if da < 0 then  Result := -Result;
end;

function TTrrFileIKNA2.s_from_a_SL(da: Double; L2, k1: Integer): Double;
begin
  Result := s_from_a(da, 0, FZnd[L2], Fw[k1]);
end;

{function s = s_from_a(da, L1, L2, w)
  if(da == 0)

    s = 0;
    return;
  end

  % начальное приближение
  x = sqrt(abs(da));
  % итерации по методу Ќьютона
  for i = 1:20
    f = x*(L2-L1) - abs(da) - (atan(x*L2/(1+x*L2)) - atan(x*L1/(1+x*L1)));
    df = (L2-L1) - (L2/(1+2*x*L2+2*x^2*L2^2) - L1/(1+2*x*L1+2*x^2*L1^2));
    y = x - f/df;
    if abs((y-x)/x) < 1e-10
      x = y;
      break;
    end
    x = y;
  end

  s = 2*x^2/(4*pi*1e-7)/w; % проводимость

  if(da < 0)
    s = -s;
  end
end     }


{ TXMLScriptIKN }

class function TXMLScriptIKN.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
begin
  if      MethodName = 'EXEC_IKN_A2'   then Exec_IKN_A2(Params[0], Params[1])
  else if MethodName = 'IMPORT_IKN_A2'  then Import_IKN_A2(Params[0], Params[1])
  else if MethodName = 'SETUP_IKN_A2'  then Setup_IKN_A2(Params[0])
  else if MethodName = 'SETUP_IKN'  then Setup_IKN(Params[0])
end;

class constructor TXMLScriptIKN.Create;
begin
  TXmlScriptInner.RegisterMethods([
  'procedure Setup_IKN(t: Variant)',
  'procedure Import_IKN_A2(const TrrFile: string; NewTrr: Variant)',
  'procedure Exec_IKN_A2(v, t: Variant)',
  'function Setup_IKN_A2(v: Variant)'], CallMeth);
end;

class destructor TXMLScriptIKN.Destroy;
begin
  TXmlScriptInner.UnRegisterMethods(CallMeth);
end;

class procedure TXMLScriptIKN.Setup_IKN(t: Variant);
 var
  i,f, n: Integer;
  root: IXMLNode;
begin
  root := TVxmlData(t).Node;
  for i := 0 to 10 do root.Attributes[AT_NAME[i]] := DEF_VAL[i];
  n := 11;
  for i := 0 to 7 do for f := 1 to 4 do
   begin
    root.Attributes[Format('L%dF%d',[i,f])] := DEF_VAL[n];
    inc(n);
   end;
  //root.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'ind3.xml');
end;

class procedure TXMLScriptIKN.Setup_IKN_A2(v: Variant);
 var
  l, p, f, m: Variant;
  i, j: Integer;
 const
  CLL: array[0..6] of TAlphaColor = ($FF240000,$FF480000,$FF6C0000,$FF900000,$FFB40000,$FFD80000,$FFFF0000);
  CLF: array[1..4] of TAlphaColor = ($FF004000,$FF008000,$FF00C000,$FF0000FF);
begin
  p := XToVar(TVxmlData(v).Node.AddChild(T_PRV, 1));// TXMLScriptMath.AddXmlPath(v, 'ѕроводимось');
  p.SIZE := 0;
  for j := 1 to 4 do
   begin
    f := TXMLScriptMath.AddXmlPath(p, 'F'+j.ToString);
    f.SIZE := 0;
    for i := 0 to 6 do
    begin
     l := TXMLScriptMath.AddXmlPath(f, 'L'+i.ToString);
     m := TXMLScriptMath.AddMetrology(l, Format('L%dF%d',[i,j]),'—м/м');
     m.VALUE := 0;
     TXMLScriptMath.AddMetrologyFM(m, 5, 4);
     TXMLScriptMath.AddMetrologyRG(m, 0, 100);
     TXMLScriptMath.AddMetrologyCL(m, CLL[i] or CLF[j], 1, 0);
    end;
   end;
// TVxmlData(v).Node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'IND.xml');
end;

// 0 Ц 24 к√ц, автокалибровка
// 1 Ц 24 к√ц, измерение
// 2 Ц 60 к√ц, автокалибровка
// 3 Ц 60 к√ц, измерение
// 4 Ц 150 к√ц, автокалибровка
// 5 Ц 150 к√ц, измерение
// 6 Ц 377 к√ц, автокалибровка
// 7 Ц 377 к√ц, измерение

class procedure TXMLScriptIKN.Exec_IKN_A2(v, t: Variant);
 var
  root: IXMLNode;
  const
   PFT = '‘аза.‘%d.%s%d.T.DEV';
   TRRS: array[Boolean] of string = ('RS', 'TR');
   function GetData(const path: string; nl, nf: integer): Integer;
    var
     s: string;
     res: IXMLNode;
   begin
     s := Format(path,[nf, TRRS[nl = 0], nl]);
     if not TryGetX(root, s, res, AT_VALUE) then raise EIkn.Createfmt('ѕуть [%s.VALUE] не найден',[s]);
     Result := Integer(res.NodeValue);
   end;
   function ang240(nl, nf: integer): Double;
    const
     PFSIN = '‘аза.‘%d.%s%d.QSin.DEV';
     PFCOS = '‘аза.‘%d.%s%d.QCos.DEV';
    var
     s,c: Double;
   begin
     s := GetData(PFSIN, nl, nf);
     c := GetData(PFCOS, nl, nf);
     Result := RadToDeg(ArcTan2(s, c));
     if Result > 240 then Result := Result - 360
     else if Result < -120 then  Result := Result + 360;
   end;
 var
  al, cl, tl, pl: array[0..7,1..4] of Double;
  i, j: Integer;
  d: ITrrFileIKNA2;
  trr, pr, fq, lz: IXMLNode;
begin
  root := TVxmlData(v).Node;
  trr := TVxmlData(t).Node;
  if not XSupport(trr, ITrrFileIKNA2, d) then
   begin
    d := TTrrFileIKNA2.Create(trr);
    (trr as IOwnIntfXMLNode).Intf := d;
   end;
  for j := 1 to 4 do for i := 0 to 7 do
   begin
    al[i,j] := ang240(i, j*2-1);
    cl[i,j] := ang240(i, j*2-2);
    tl[i,j] := GetData(PFT, i, j*2-1)*0.0625;
   end;
  for i := 0 to 7 do for j := 1 to 4 do
   begin
    pl[i,j] := al[i,j] - cl[i,j] - al[0,j] + cl[0,j] - d.ph_zero_spline(i,j-1, tl[i,j]);
   end;
  pr := root.ChildNodes.FindNode(T_PRV);
  for j := 1 to 4 do
   begin
    fq := pr.ChildNodes.FindNode('F'+j.ToString);
    for i := 0 to 6 do
     begin
      lz := fq.ChildNodes.FindNode('L'+i.ToString);
      lz.ChildNodes.FindNode(T_CLC).Attributes[AT_VALUE] := d.s_from_a_SL(pl[i+1,j], i, j-1);
     end;
   end;
end;

class procedure TXMLScriptIKN.Import_IKN_A2(const TrrFile: string; NewTrr: Variant);
 var
  ss: TStrings;
  root: IXMLNode;
  i,f: Integer;
begin
  root := TVxmlData(NewTrr).Node;
  ss := TStringList.Create();
  try
   ss.LoadFromFile(TrrFile);
   if ss.Count < 78 then raise EBaseException.Createfmt('” файла %s %d (78)строк', [TrrFile, ss.Count]);
   for i := 0 to 10 do root.Attributes[AT_NAME[i]] := ss[AT_INDEX[i]];
   for i := 0 to 7 do for f := 1 to 4 do root.Attributes[Format('L%dF%d',[i,f])] := ss[27 + i*5 + f].Split(['%'])[0].Trim;
  finally
   ss.Free;
  end;
end;

end.
