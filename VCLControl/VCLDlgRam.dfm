object FormDlgRam: TFormDlgRam
  Left = 0
  Top = 0
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1095#1090#1077#1085#1080#1103' '#1087#1072#1084#1103#1090#1080
  ClientHeight = 349
  ClientWidth = 386
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  DesignSize = (
    386
    349)
  TextHeight = 13
  object lbFile: TLabel
    Left = 18
    Top = 8
    Width = 125
    Height = 13
    Caption = #1057#1086#1079#1076#1072#1090#1100' '#1073#1080#1085#1072#1088#1085#1099#1081' '#1092#1072#1081#1083
    Visible = False
  end
  object lbLen: TLabel
    Left = 224
    Top = 81
    Width = 86
    Height = 13
    Caption = #1044#1083#1080#1085#1072' '#1087#1072#1082#1077#1090#1072' 0x'
  end
  object lbSD: TLabel
    Left = 224
    Top = 58
    Width = 44
    Height = 13
    Caption = #1044#1080#1089#1082'  SD'
    Enabled = False
  end
  object lblssd: TLabel
    Left = 225
    Top = 95
    Width = 3
    Height = 13
  end
  object btStart: TButton
    Left = 16
    Top = 294
    Width = 75
    Height = 25
    Caption = #1057#1090#1072#1088#1090
    TabOrder = 0
    OnClick = btStartClick
  end
  object btExit: TButton
    Left = 291
    Top = 294
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 1
    OnClick = btExitClick
  end
  object cbToFF: TCheckBox
    Left = 18
    Top = 114
    Width = 151
    Height = 17
    Caption = #1063#1080#1090#1072#1090#1100' '#1076#1086' '#1087#1091#1089#1090#1086#1081' '#1087#1072#1084#1103#1090#1080
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object Progress: TProgressBar
    Left = 17
    Top = 271
    Width = 350
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
  end
  object btTerminate: TButton
    Left = 178
    Top = 294
    Width = 75
    Height = 25
    Caption = #1055#1088#1077#1088#1074#1072#1090#1100
    TabOrder = 4
    OnClick = btTerminateClick
  end
  object sb: TStatusBar
    Left = 0
    Top = 330
    Width = 386
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object rg: TRadioGroup
    Left = 18
    Top = 48
    Width = 201
    Height = 63
    Caption = #1042#1099#1089#1086#1082#1072#1103' '#1089#1082#1086#1088#1086#1089#1090#1100
    Columns = 4
    ItemIndex = 0
    Items.Strings = (
      '125'#1050
      '0.5M'
      '1M'
      '2M'
      '3M'
      '6M'
      '8M'
      '12M')
    TabOrder = 6
    OnClick = rgClick
  end
  object od: TJvFilenameEdit
    Left = 18
    Top = 21
    Width = 350
    Height = 21
    OnBeforeDialog = odBeforeDialog
    DialogKind = dkSave
    DefaultExt = 'bin'
    Filter = #1041#1080#1085#1072#1088#1085#1099#1081' '#1092#1072#1081#1083' (*.bin)|*.bin'
    DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    DirectInput = False
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
    Text = ''
    Visible = False
  end
  object edLen: TEdit
    Left = 310
    Top = 78
    Width = 56
    Height = 21
    TabOrder = 8
    Text = '3FF0'
  end
  object cbSD: TComboBox
    Left = 270
    Top = 55
    Width = 97
    Height = 21
    Style = csDropDownList
    Enabled = False
    TabOrder = 9
    OnChange = cbSDChange
    OnDropDown = cbSDDropDown
  end
  object cbClcCreate: TCheckBox
    Left = 171
    Top = 114
    Width = 196
    Height = 17
    Caption = #1057#1086#1079#1076#1072#1090#1100' '#1092#1072#1081#1083' '#1088#1072#1089#1089#1095#1077#1090#1085#1099#1093' '#1076#1072#1085#1085#1099#1093
    TabOrder = 10
  end
  inline RangeSelect: TFrameRangeSelect
    Left = 18
    Top = 144
    Width = 348
    Height = 122
    Anchors = [akLeft, akTop, akRight]
    AutoSize = True
    TabOrder = 11
    ExplicitLeft = 18
    ExplicitTop = 144
    ExplicitWidth = 348
    ExplicitHeight = 122
    inherited lbBegin: TLabel
      Width = 37
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 37
      ExplicitHeight = 13
    end
    inherited lbEnd: TLabel
      Width = 31
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 31
      ExplicitHeight = 13
    end
    inherited lbCnt: TLabel
      Width = 35
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 35
      ExplicitHeight = 13
    end
    inherited lbKaBegin: TLabel
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitHeight = 13
    end
    inherited lbKaCnt: TLabel
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitHeight = 13
    end
    inherited lbKaEnd: TLabel
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitHeight = 13
    end
    inherited Label1: TLabel
      Width = 70
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 70
      ExplicitHeight = 13
    end
    inherited Label2: TLabel
      Width = 58
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 58
      ExplicitHeight = 13
    end
    inherited Label3: TLabel
      Width = 33
      Height = 13
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 33
      ExplicitHeight = 13
    end
    inherited Range: TRangeSelector
      Width = 348
      SelStart = 20.000000000000000000
      SelEnd = 80.000000000000000000
      ExplicitWidth = 348
    end
    inherited edOtnBegin: TMaskEdit
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited edOtnEnd: TMaskEdit
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited edOtnCnt: TMaskEdit
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited edGlobBegin: TMaskEdit
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited edGlobEnd: TMaskEdit
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  object btContinue: TButton
    Left = 97
    Top = 294
    Width = 75
    Height = 25
    Caption = #1055#1088#1086#1076#1086#1083#1078#1080#1090#1100
    Enabled = False
    TabOrder = 12
    OnClick = btContinueClick
  end
end
