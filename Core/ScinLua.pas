unit ScinLua;

interface

uses  System.SysUtils, Winapi.Windows, Graphics, System.UITypes, Xml.XMLIntf, Xml.XMLDoc,
      Vcl.Controls,
      debug_except,
      VerySimple.Lua, VerySimple.Lua.Lib,
      DScintillaCustom, DScintilla, DScintillaTypes;

 type
   TScinLua = class(TDScintilla)
   protected
     procedure InitDefaults; override;
   public
     procedure IndicatorClear;
     procedure ErrorShow(const lin_ind_len: string);
   end;

implementation

{ TScinLua }

procedure TScinLua.IndicatorClear;
begin
  IndicatorClearRange(0, Length(Lines.Text));
end;

procedure TScinLua.InitDefaults;
begin
  inherited;
  SetScrollWidth(430); //so we don't see it
  Margins.Right:=1;
  Margins.Left:=0;
  Margins.Top:=0;
  Margins.Bottom:=0;
  SetMarginLeft(5);
  SetMarginWidthN(0,40);
  SetMarginWidthN(1,0);
  SetExtraAscent(4); //space between lines
  DllModule := 'SciLexer.dll'; // the syntax library
  Align := alClient;           // object alignment to the whole parent

  SetCodePage(CP_UTF8);

  //-----------------------margin line numbers
  StyleSetFont(STYLE_LINENUMBER, 'Default');
  StyleSetBold(STYLE_LINENUMBER, true);
  StyleSetBack(STYLE_LINENUMBER, clgray);
  StyleSetFore(STYLE_LINENUMBER,clWebBlack);

 //-----------------------Text
  SetLexerLanguage('lua');  //don't work
  SetLexer(SCLEX_LUA);
  StyleSetFont(SCE_LUA_DEFAULT, 'Courier New');
  StyleSetSize(SCE_LUA_DEFAULT,10);
  StyleSetFont(SCE_LUA_IDENTIFIER, 'Courier New');
  StyleSetSize(SCE_LUA_IDENTIFIER,10);
  StyleSetFont(SCE_LUA_OPERATOR, 'Courier New');
  StyleSetSize(SCE_LUA_OPERATOR,10);
  StyleSetFont(SCE_LUA_NUMBER, 'Courier New');
  StyleSetSize(SCE_LUA_NUMBER,10);
  StyleSetFont(SCE_LUA_COMMENTLINE, 'Courier New');
  StyleSetSize(SCE_LUA_COMMENTLINE,10);
  StyleSetFont(SCE_LUA_WORD, 'Courier New');
  StyleSetSize(SCE_LUA_WORD,10);
  StyleSetFont(SCE_LUA_WORD2, 'Courier New');
  StyleSetSize(SCE_LUA_WORD2,10);
  StyleSetFont(SCE_LUA_WORD3, 'Courier New');
  StyleSetSize(SCE_LUA_WORD3,10);
  StyleSetFont(SCE_LUA_LITERALSTRING, 'Courier New');
  StyleSetSize(SCE_LUA_LITERALSTRING,10);
  StyleSetFont(SCE_LUA_COMMENTDOC, 'Courier New');

 //-----------------------Italics
  StyleSetItalic(SCE_LUA_COMMENTLINE,true);  // "--..."
  StyleSetItalic(SCE_LUA_LITERALSTRING,true);   // "[[...]]"
  //StyleSetItalic(SCE_LUA_NUMBER,true);
  StyleSetBold(SCE_LUA_OPERATOR,true);
  StyleSetBold(SCE_LUA_WORD,true);   //init start/end true false
  StyleSetBold(SCE_LUA_WORD2, True);

  StyleSetBold(SCE_LUA_NUMBER,true);
  StyleSetItalic(SCE_LUA_COMMENTDOC,true); //don't work

 //-----------------------KeyWords
  SetKeyWords(0, 'while and  break  do else elseif end false for function if in local nil not or repeat return then true until');
 //-----------------------Colours
  StyleSetFore(SCE_LUA_COMMENTLINE, clGreen);
  StyleSetFore(SCE_LUA_COMMENTDOC, clGreen);
  StyleSetFore(SCE_LUA_NUMBER, clblue);
  StyleSetFore(SCE_LUA_CHARACTER, TColorRec.RoyalBlue);
  StyleSetFore(SCE_LUA_STRING, TColorRec.RoyalBlue);
  StyleSetFore(SCE_LUA_OPERATOR, clred);
  StyleSetFore(SCE_LUA_LITERALSTRING, clGreen);
  StyleSetFore(SCE_LUA_IDENTIFIER, clpurple);

  StyleSetFore(SCE_LUA_WORD2, TColors.MediumVioletRed);
  StyleSetFore(SCE_LUA_WORD, clblue);

  AssignCmdKey(vkS or (SCMOD_CTRL shl 16), SCI_AUTOCCOMPLETE);

  SendEditor(SCI_IndicSetStyle, 8, INDIC_ROUNDBOX);
  SendEditor(SCI_INDICSETFORE, 8, clRed);
  SendEditor(SCI_INDICSETALPHA, 8, 50);
  SendEditor(SCI_SETINDICATORCURRENT, 8, 0);
  SendEditor(SCI_SETINDICATORVALUE, 8);
  SendEditor(SCI_INDICSETUNDER, 1);
 // onchange := IndicatorClear;
//  IndicatorClearRange(0, Length(Lines.Text));

end;

procedure TScinLua.ErrorShow(const lin_ind_len: string);
 var
  pos: Integer;
  a: Tarray<string>;
begin
   a := lin_ind_len.Split([':'], TStringSplitOptions.ExcludeEmpty);
   pos := SendEditor(SCI_PositionFromLIne, a[0].ToInteger-1,0);
   IndicatorFillRange(pos+a[1].ToInteger, a[2].ToInteger);
end;

end.
