object DlgSetupAdr: TDlgSetupAdr
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = #1042#1088#1091#1095#1085#1091#1102' '#1091#1089#1090#1072#1085#1086#1074#1082#1080
  ClientHeight = 229
  ClientWidth = 291
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object Label2: TLabel
    Left = 24
    Top = 86
    Width = 92
    Height = 13
    Caption = #1040#1076#1088#1077#1089' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
  end
  object Label3: TLabel
    Left = 24
    Top = 18
    Width = 239
    Height = 13
    Caption = #1057#1077#1088#1080#1081#1085#1099#1081' '#1085#1086#1084#1077#1088' ('#1073#1091#1076#1077#1090' '#1079#1072#1087#1080#1089#1072#1085' '#1074' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1086')'
  end
  object Label4: TLabel
    Left = 145
    Top = 86
    Width = 19
    Height = 13
    Caption = #1063#1080#1087
  end
  object Label1: TLabel
    Left = 24
    Top = 72
    Width = 223
    Height = 13
    Caption = #1048#1079#1084#1077#1085#1103#1102#1090' '#1090#1086#1083#1100#1082#1086' '#1088#1077#1078#1080#1084' '#1087#1088#1086#1075#1088#1072#1084#1084#1080#1088#1086#1074#1072#1085#1080#1103
  end
  object Label5: TLabel
    Left = 24
    Top = 134
    Width = 114
    Height = 13
    Caption = #1040#1076#1088#1077#1089' '#1087#1086#1076' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
  end
  object Label6: TLabel
    Left = 24
    Top = 153
    Width = 12
    Height = 13
    Caption = '0x'
  end
  object btOK: TButton
    Left = 24
    Top = 187
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
  end
  object btCancel: TButton
    Left = 136
    Top = 187
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object cb: TComboBox
    Left = 144
    Top = 101
    Width = 99
    Height = 21
    Style = csDropDownList
    TabOrder = 2
  end
  object edAdr: TEdit
    Left = 24
    Top = 101
    Width = 99
    Height = 21
    TabOrder = 3
    Text = '-1'
  end
  object edSerial: TEdit
    Left = 24
    Top = 37
    Width = 99
    Height = 21
    TabOrder = 4
    Text = '-1'
  end
  object edSubAdr: TEdit
    Left = 38
    Top = 150
    Width = 83
    Height = 21
    TabOrder = 5
    Text = 'nop'
  end
end
