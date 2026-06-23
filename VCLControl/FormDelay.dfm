object FormDly: TFormDly
  Left = 227
  Top = 108
  Caption = #1055#1086#1089#1090#1072#1085#1086#1074#1082#1072' '#1085#1072' '#1079#1072#1076#1077#1088#1078#1082#1091', '#1089#1080#1085#1093#1088#1086#1085#1080#1079#1072#1094#1080#1103' '#1079#1072#1076#1077#1088#1078#1082#1080
  ClientHeight = 256
  ClientWidth = 521
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = True
  Position = poMainFormCenter
  DesignSize = (
    521
    256)
  PixelsPerInch = 96
  TextHeight = 13
  object btSyncDelay: TButton
    Left = 181
    Top = 155
    Width = 169
    Height = 21
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = #1057#1080#1085#1093#1088#1086#1085#1080#1079#1080#1088#1086#1074#1072#1090#1100' '#1079#1072#1076#1077#1088#1078#1082#1091
    TabOrder = 1
    OnClick = btSyncDelayClick
  end
  object btSetDelay: TButton
    Left = 8
    Top = 155
    Width = 142
    Height = 21
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = #1055#1086#1089#1090#1072#1074#1080#1090#1100' '#1085#1072' '#1079#1072#1076#1077#1088#1078#1082#1091
    TabOrder = 0
    OnClick = btSetDelayClick
  end
  object sb: TStatusBar
    Left = 0
    Top = 233
    Width = 521
    Height = 23
    Panels = <
      item
        Width = 50
      end>
  end
  object btClose: TButton
    Left = 8
    Top = 198
    Width = 89
    Height = 21
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = #1047#1072#1082#1088#1099#1090#1100' '#1086#1082#1085#1086
    TabOrder = 3
    OnClick = btCloseClick
  end
  object Insp: TJvInspector
    AlignWithMargins = True
    Left = 5
    Top = 7
    Width = 511
    Height = 130
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Style = isItemPainter
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelEdges = []
    BevelKind = bkNone
    Divider = 300
    ItemHeight = 16
    Painter = InspectorBorlandPainter
    TabStop = True
    TabOrder = 4
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 152
    Top = 232
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
    Left = 200
    Top = 40
  end
end
