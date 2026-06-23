object FrameFindDev: TFrameFindDev
  Left = 0
  Top = 0
  Width = 352
  Height = 40
  Align = alTop
  TabOrder = 0
  DesignSize = (
    352
    40)
  object lbCon: TLabel
    Left = 3
    Top = 3
    Width = 126
    Height = 23
    AutoSize = False
    Caption = #1057#1086#1077#1076#1080#1085#1077#1085#1080#1077
    Color = clWindow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Transparent = True
    StyleElements = []
  end
  object edName: TEdit
    Left = 135
    Top = 3
    Width = 126
    Height = 23
    Enabled = False
    TabOrder = 0
    Text = #1048#1084#1103' '#1087#1088#1080#1073#1086#1088#1072
  end
  object btAdd: TButton
    Left = 266
    Top = 3
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100
    Enabled = False
    TabOrder = 1
    OnClick = btAddClick
  end
  object cbx: TCheckListBox
    Left = 3
    Top = 32
    Width = 338
    Height = 0
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clWhite
    ItemHeight = 17
    TabOrder = 2
  end
end
