inherited FormSetupWlan: TFormSetupWlan
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1080' WiFi'
  TextHeight = 13
  inherited Label2: TLabel
    Top = 102
    ExplicitTop = 102
  end
  object Label4: TLabel [3]
    Left = 16
    Top = 53
    Width = 23
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'SSID'
  end
  inherited sb: TStatusBar
    ExplicitWidth = 300
  end
  inherited EdWait: TEdit
    Top = 121
    ExplicitTop = 121
  end
  object edSSID: TEdit
    Left = 16
    Top = 72
    Width = 171
    Height = 21
    Anchors = [akLeft, akBottom]
    TabOrder = 9
    Text = 'AMKGorizontWiFiUSO'
  end
end
