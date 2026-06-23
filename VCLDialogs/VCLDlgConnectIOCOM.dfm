inherited FormSetupCom: TFormSetupCom
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1080' '#1057#1054#1052
  ClientHeight = 228
  ExplicitHeight = 267
  TextHeight = 13
  inherited Label2: TLabel
    Top = 106
    ExplicitTop = 74
  end
  object Label1: TLabel [1]
    Left = 16
    Top = 20
    Width = 97
    Height = 13
    Caption = #1042#1099#1073#1088#1072#1090#1100' '#1057#1054#1052' '#1087#1086#1088#1090
  end
  inherited sb: TStatusBar
    Top = 209
    ExplicitTop = 209
  end
  inherited ButtonOK: TButton
    Top = 169
    ExplicitTop = 169
  end
  inherited btTest: TButton
    Top = 168
    ExplicitTop = 168
  end
  inherited EdWait: TEdit
    Top = 125
    ExplicitTop = 125
  end
  inherited Button1: TButton
    Top = 169
    ExplicitTop = 169
  end
  inherited btClose: TButton
    Top = 119
    ExplicitTop = 119
  end
  inherited btOpen: TButton
    Top = 71
    ExplicitTop = 71
  end
  object cbCom: TComComboBox
    Left = 16
    Top = 39
    Width = 171
    Height = 21
    ComProperty = cpPort
    Text = 'COM1'
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 7
  end
  object cb9600: TCheckBox
    Left = 203
    Top = 41
    Width = 89
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = '9600 '#1073#1086#1076
    TabOrder = 8
  end
  object cb256k: TCheckBox
    Left = 203
    Top = 19
    Width = 89
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = '256k'#1073#1086#1076
    TabOrder = 9
  end
end
