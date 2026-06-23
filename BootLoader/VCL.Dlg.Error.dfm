object FormError: TFormError
  Left = 0
  Top = 0
  Anchors = [akRight, akBottom]
  Caption = #1054#1096#1080#1073#1082#1080
  ClientHeight = 257
  ClientWidth = 329
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    329
    257)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 17
    Top = 230
    Width = 92
    Height = 13
    Anchors = [akRight, akBottom]
    Caption = #1040#1076#1088#1077#1089' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
    ExplicitLeft = 114
    ExplicitTop = 292
  end
  object btOK: TButton
    Left = 246
    Top = 224
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1057#1095#1080#1090#1072#1090#1100
    TabOrder = 0
    OnClick = ReadClick
  end
  object btClear: TButton
    Left = 153
    Top = 224
    Width = 87
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1057#1073#1088#1086#1089#1080#1090#1100' '#1092#1083#1072#1075
    TabOrder = 1
    OnClick = ReadClick
  end
  object edAdr: TEdit
    Left = 115
    Top = 226
    Width = 35
    Height = 21
    Anchors = [akRight, akBottom]
    TabOrder = 2
    Text = '6'
  end
  object MemoX: TMemo
    Left = 8
    Top = 8
    Width = 313
    Height = 202
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
end
