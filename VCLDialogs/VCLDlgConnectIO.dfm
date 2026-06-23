object FormSetupConnect: TFormSetupConnect
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1080' COM '#1087#1086#1088#1090#1072
  ClientHeight = 174
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  DesignSize = (
    300
    174)
  TextHeight = 13
  object Label2: TLabel
    Left = 16
    Top = 52
    Width = 145
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = #1042#1088#1077#1084#1103' '#1086#1078#1080#1076#1072#1085#1080#1103' '#1086#1090#1074#1077#1090#1072' ('#1084#1089')'
    ExplicitTop = 125
  end
  object sb: TStatusBar
    Left = 0
    Top = 155
    Width = 300
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object ButtonOK: TButton
    Left = 16
    Top = 115
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
    OnClick = ButtonOKClick
  end
  object btTest: TButton
    Left = 208
    Top = 114
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    TabOrder = 2
    OnClick = btTestClick
  end
  object EdWait: TEdit
    Left = 16
    Top = 71
    Width = 171
    Height = 21
    Anchors = [akLeft, akBottom]
    TabOrder = 3
    Text = '1000'
  end
  object Button1: TButton
    Left = 112
    Top = 115
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 4
  end
  object btClose: TButton
    Left = 208
    Top = 65
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1047#1072#1082#1088#1099#1090#1100
    TabOrder = 5
    OnClick = btCloseClick
  end
  object btOpen: TButton
    Left = 208
    Top = 17
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1090#1082#1088#1099#1090#1100
    TabOrder = 6
    OnClick = btOpenClick
  end
end
