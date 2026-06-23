object FormOptionSetup: TFormOptionSetup
  Left = 0
  Top = 0
  Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '#1087#1086#1074#1077#1088#1082#1080
  ClientHeight = 344
  ClientWidth = 593
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  DesignSize = (
    593
    344)
  TextHeight = 13
  object insp: TJvInspector
    Left = 8
    Top = 8
    Width = 577
    Height = 289
    Style = isItemPainter
    Anchors = [akLeft, akTop, akRight, akBottom]
    Divider = 300
    ItemHeight = 16
    Painter = Painter
    TabStop = True
    TabOrder = 0
  end
  object btOK: TButton
    Left = 160
    Top = 311
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
    OnClick = btOKClick
  end
  object btCancel: TButton
    Left = 241
    Top = 311
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 2
    OnClick = btCancelClick
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
    ValueFont.Color = clWindowText
    ValueFont.Height = -12
    ValueFont.Name = 'Segoe UI'
    ValueFont.Style = []
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
    Left = 216
    Top = 168
  end
end
