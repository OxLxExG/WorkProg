object FormStolGK: TFormStolGK
  Left = 0
  Top = 0
  Caption = #1057#1090#1086#1083' '#1040#1090#1090#1077#1089#1090#1072#1094#1080#1080' '#1043#1050
  ClientHeight = 120
  ClientWidth = 266
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object lbPosition: TLabel
    Left = 97
    Top = 38
    Width = 32
    Height = 13
    Caption = '--------'
  end
  object btAct: TSpeedButton
    Left = 8
    Top = 35
    Width = 75
    Height = 22
    AllowAllUp = True
    GroupIndex = 1
    Caption = #1047#1072#1089#1083#1086#1085#1082#1072
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    OnClick = btActClick
  end
  object btStop: TButton
    Left = 8
    Top = 73
    Width = 75
    Height = 22
    Caption = #1057#1090#1086#1087
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = btStopClick
  end
  object sb: TStatusBar
    Left = 0
    Top = 101
    Width = 266
    Height = 19
    Panels = <
      item
        Width = 36
      end
      item
        Width = 32
      end
      item
        Width = 50
      end>
  end
  object cb: TComboBox
    Left = 8
    Top = 8
    Width = 105
    Height = 21
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object btGo: TButton
    Left = 119
    Top = 8
    Width = 34
    Height = 22
    Caption = 'Go'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = btGoClick
  end
end
