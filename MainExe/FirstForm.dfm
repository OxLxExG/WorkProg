object FormSplash: TFormSplash
  Left = 0
  Top = 0
  Caption = 'FormSplash'
  ClientHeight = 289
  ClientWidth = 554
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 554
    Height = 289
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'Memo')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object Button: TButton
    Left = 447
    Top = 8
    Width = 75
    Height = 25
    Caption = 'update'
    TabOrder = 1
    OnClick = ButtonClick
  end
end
