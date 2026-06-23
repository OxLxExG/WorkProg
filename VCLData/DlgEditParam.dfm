object FormEditParam: TFormEditParam
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1080#1090#1100' '#1087#1072#1088#1072#1084#1077#1090#1088
  ClientHeight = 317
  ClientWidth = 323
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  DesignSize = (
    323
    317)
  TextHeight = 13
  object Insp: TJvInspector
    Left = 8
    Top = 8
    Width = 307
    Height = 270
    Style = isItemPainter
    Anchors = [akLeft, akTop, akRight, akBottom]
    Divider = 200
    ItemHeight = 16
    Painter = Painter
    TabStop = True
    TabOrder = 1
  end
  object btExit: TButton
    Left = 224
    Top = 284
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 0
    OnClick = btExitClick
  end
  object Painter: TJvInspectorDotNETPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBtnText
    CategoryFont.Height = -12
    CategoryFont.Name = 'Segoe UI'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -12
    NameFont.Name = 'Segoe UI'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clNavy
    ValueFont.Height = -12
    ValueFont.Name = 'Segoe UI'
    ValueFont.Style = [fsBold]
    DrawNameEndEllipsis = False
    HideSelectFont.Charset = DEFAULT_CHARSET
    HideSelectFont.Color = clHighlightText
    HideSelectFont.Height = -12
    HideSelectFont.Name = 'Segoe UI'
    HideSelectFont.Style = []
    SelectedFont.Charset = DEFAULT_CHARSET
    SelectedFont.Color = clHighlightText
    SelectedFont.Height = -12
    SelectedFont.Name = 'Segoe UI'
    SelectedFont.Style = []
    Left = 184
    Top = 112
  end
end
