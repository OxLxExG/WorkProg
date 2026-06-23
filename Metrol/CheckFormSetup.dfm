object FormCheckSetup: TFormCheckSetup
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1055#1072#1087#1072#1084#1077#1090#1088#1099' '#1087#1088#1086#1074#1077#1088#1082#1080
  ClientHeight = 267
  ClientWidth = 607
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    607
    267)
  PixelsPerInch = 96
  TextHeight = 13
  object insp: TJvInspector
    Left = 8
    Top = 8
    Width = 591
    Height = 221
    Style = isItemPainter
    Anchors = [akLeft, akTop, akRight, akBottom]
    Divider = 300
    ItemHeight = 16
    Painter = InspectorBorlandPainter
    TabStop = True
    TabOrder = 0
  end
  object btOK: TButton
    Left = 208
    Top = 235
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btCancel: TButton
    Left = 312
    Top = 235
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 2
  end
  object InspectorBorlandPainter: TJvInspectorBorlandPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBlack
    CategoryFont.Height = -11
    CategoryFont.Name = 'Tahoma'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -11
    NameFont.Name = 'Tahoma'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clNavy
    ValueFont.Height = -11
    ValueFont.Name = 'Tahoma'
    ValueFont.Style = [fsBold]
    DrawNameEndEllipsis = True
    Left = 272
    Top = 32
  end
end
