object FormMetrSetup: TFormMetrSetup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1090#1072#1085#1076#1072#1088#1090#1085#1099#1077' '#1091#1089#1090#1072#1085#1086#1074#1082#1080
  ClientHeight = 177
  ClientWidth = 476
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
  object lbNatt: TLabel
    Left = 160
    Top = 74
    Width = 156
    Height = 13
    Caption = #1063#1080#1089#1083#1086' '#1076#1072#1085#1085#1099#1093' '#1076#1083#1103' '#1072#1090#1090#1077#1089#1090#1072#1094#1080#1080
  end
  object lbDev: TLabel
    Left = 16
    Top = 9
    Width = 35
    Height = 13
    Caption = #1058#1080#1087' '#1057#1055
  end
  object lbSerial: TLabel
    Left = 176
    Top = 9
    Width = 76
    Height = 13
    Caption = #1053#1086#1084#1077#1088' '#1087#1088#1080#1073#1086#1088#1072
  end
  object lbTrr: TLabel
    Left = 336
    Top = 9
    Width = 89
    Height = 13
    Caption = #1044#1072#1090#1072' '#1082#1072#1083#1080#1073#1088#1086#1074#1082#1080
  end
  object btOK: TButton
    Left = 128
    Top = 136
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
  end
  object btCancel: TButton
    Left = 232
    Top = 136
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object edNAtt: TEdit
    Left = 176
    Top = 93
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '5'
  end
  object edDev: TEdit
    Left = 16
    Top = 28
    Width = 121
    Height = 21
    TabOrder = 3
  end
  object cbAny: TCheckBox
    Left = 16
    Top = 55
    Width = 121
    Height = 17
    Caption = #1085#1077' '#1087#1088#1086#1074#1077#1088#1103#1090#1100
    TabOrder = 4
    OnClick = cbAnyClick
  end
  object edSerial: TEdit
    Left = 176
    Top = 28
    Width = 121
    Height = 21
    TabOrder = 5
    Text = '-1'
  end
  object dtTrr: TDateTimePicker
    Left = 336
    Top = 28
    Width = 121
    Height = 21
    Date = 41317.422428495370000000
    Time = 41317.422428495370000000
    TabOrder = 6
    OnChange = dtTrrChange
  end
end
