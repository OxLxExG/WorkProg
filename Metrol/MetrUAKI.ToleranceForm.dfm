object FormUAKItolerance: TFormUAKItolerance
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1090#1086#1095#1085#1086#1089#1090#1080
  ClientHeight = 122
  ClientWidth = 259
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object edTole: TEdit
    Left = 16
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '0.05'
  end
  object btGet: TButton
    Left = 161
    Top = 22
    Width = 75
    Height = 25
    Caption = #1063#1090#1077#1085#1080#1077
    TabOrder = 1
    OnClick = btGetClick
  end
  object btSet: TButton
    Left = 161
    Top = 75
    Width = 75
    Height = 25
    Caption = #1047#1072#1087#1080#1089#1100
    TabOrder = 2
    OnClick = btSetClick
  end
  object btExit: TButton
    Left = 16
    Top = 75
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 3
  end
end
