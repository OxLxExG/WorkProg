object FormDlgExportCaliper: TFormDlgExportCaliper
  Left = 0
  Top = 0
  Caption = #1087#1088#1086#1092#1080#1083#1077#1084#1077#1088' '#1074' '#1072#1082'1'
  ClientHeight = 275
  ClientWidth = 289
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  DesignSize = (
    289
    275)
  TextHeight = 13
  object Label3: TLabel
    Left = 8
    Top = 30
    Width = 58
    Height = 13
    Caption = #1044#1083#1080#1085#1072' '#1060#1050#1044
  end
  object Label1: TLabel
    Left = 72
    Top = 30
    Width = 90
    Height = 13
    Caption = #1044#1080#1072#1084#1077#1090#1088' '#1055#1088#1080#1073#1086#1088#1072
  end
  object od: TJvFilenameEdit
    Left = 8
    Top = 8
    Width = 273
    Height = 21
    DialogKind = dkSave
    DefaultExt = 'if'
    Filter = #1041#1080#1085#1072#1088#1085#1099#1081' '#1092#1072#1081#1083' (*.if,*ak1)|*.if;*.ak1;'
    DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    DirectInput = False
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = ''
  end
  object btStart: TButton
    Left = 8
    Top = 227
    Width = 75
    Height = 25
    Caption = #1057#1090#1072#1088#1090
    TabOrder = 1
    OnClick = btExportClick
  end
  object btTerminate: TButton
    Left = 89
    Top = 227
    Width = 75
    Height = 25
    Caption = #1055#1088#1077#1088#1074#1072#1090#1100
    TabOrder = 2
    OnClick = btTerminateClick
  end
  object btExit: TButton
    Left = 207
    Top = 227
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 3
    OnClick = btExitClick
  end
  object Progress: TProgressBar
    Left = 8
    Top = 204
    Width = 273
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
  end
  object edFKD: TEdit
    Left = 8
    Top = 46
    Width = 58
    Height = 21
    Enabled = False
    TabOrder = 5
    Text = '682'
  end
  inline RangeSelect: TFrameRangeSelect
    Left = 8
    Top = 72
    Width = 273
    Height = 122
    Anchors = [akLeft, akTop, akRight]
    AutoSize = True
    TabOrder = 6
    ExplicitLeft = 8
    ExplicitTop = 72
    ExplicitWidth = 273
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
      Width = 273
      ExplicitWidth = 273
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
  object sb: TStatusBar
    Left = 0
    Top = 256
    Width = 289
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
  object cbFKD: TComboBox
    Left = 72
    Top = 45
    Width = 91
    Height = 21
    Style = csDropDownList
    Enabled = False
    ItemIndex = 0
    TabOrder = 8
    Text = '108'#1084#1084
    OnChange = cbFKDChange
    Items.Strings = (
      '108'#1084#1084
      '120'#1084#1084
      '172'#1084#1084
      '120'#1084#1084'-'#1084#1086#1076#1091#1083#1100#1085#1099#1081)
  end
  object cbAuto: TCheckBox
    Left = 168
    Top = 47
    Width = 97
    Height = 17
    Caption = #1060#1050#1044' '#1072#1074#1090#1086
    Checked = True
    State = cbChecked
    TabOrder = 9
    OnClick = cbAutoClick
  end
end
