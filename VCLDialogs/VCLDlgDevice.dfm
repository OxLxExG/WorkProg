object DlgSetupDev: TDlgSetupDev
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1088#1080#1073#1086#1088#1072
  ClientHeight = 106
  ClientWidth = 297
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 80
    Height = 13
    Caption = #1048#1084#1103' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
  end
  object lbPeriod: TLabel
    Left = 154
    Top = 8
    Width = 106
    Height = 13
    Caption = #1055#1077#1088#1080#1086#1076' '#1094#1080#1082#1083#1086#1086#1087#1088#1086#1089#1072
    Visible = False
  end
  object btApply: TButton
    Left = 200
    Top = 63
    Width = 75
    Height = 25
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    TabOrder = 0
    OnClick = btApplyClick
  end
  object Button1: TButton
    Left = 104
    Top = 64
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object ButtonOK: TButton
    Left = 8
    Top = 63
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
    OnClick = ButtonOKClick
  end
  object edName: TEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 3
  end
  object edPeriod: TEdit
    Left = 154
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 4
    Visible = False
  end
end
