object FrameRangeSelect: TFrameRangeSelect
  Left = 0
  Top = 0
  Width = 293
  Height = 124
  AutoSize = True
  TabOrder = 0
  DesignSize = (
    293
    124)
  object lbBegin: TLabel
    Left = 0
    Top = 74
    Width = 42
    Height = 15
    Caption = #1053#1072#1095#1072#1083#1086
  end
  object lbEnd: TLabel
    Left = 0
    Top = 106
    Width = 34
    Height = 15
    Caption = #1050#1086#1085#1077#1094
  end
  object lbCnt: TLabel
    Left = 0
    Top = 90
    Width = 39
    Height = 15
    Caption = #1050#1086#1083'-'#1074#1086
  end
  object lbKaBegin: TLabel
    Left = 233
    Top = 77
    Width = 6
    Height = 15
    Caption = '0'
  end
  object lbKaCnt: TLabel
    Left = 233
    Top = 93
    Width = 6
    Height = 15
    Caption = '0'
  end
  object lbKaEnd: TLabel
    Left = 233
    Top = 109
    Width = 6
    Height = 15
    Caption = '0'
  end
  object Label1: TLabel
    Left = 38
    Top = 63
    Width = 74
    Height = 15
    Caption = #1074#1088#1077#1084#1103' '#1086#1090' '#1074#1082#1083'.'
  end
  object Label2: TLabel
    Left = 124
    Top = 63
    Width = 60
    Height = 15
    Caption = #1076#1072#1090#1072' '#1074#1088#1077#1084#1103
  end
  object Label3: TLabel
    Left = 232
    Top = 63
    Width = 34
    Height = 15
    Caption = #1082#1072#1076#1088#1099
  end
  object Range: TRangeSelector
    Left = 0
    Top = 0
    Width = 293
    Height = 57
    Anchors = [akLeft, akTop, akRight]
    Max = 100.000000000000000000
    SelStart = 50.000000000000000000
    SelEnd = 70.000000000000000000
    ReadyEnd = 80.000000000000000000
    OnChange = RangeChange
  end
  object edOtnBegin: TMaskEdit
    Left = 38
    Top = 76
    Width = 80
    Height = 16
    AutoSize = False
    EditMask = '!99 90:00:00;1;_'
    MaxLength = 11
    TabOrder = 1
    Text = '     :  :  '
    OnKeyPress = edOtnBeginKeyPress
  end
  object edOtnEnd: TMaskEdit
    Left = 38
    Top = 106
    Width = 80
    Height = 16
    AutoSize = False
    EditMask = '!99 90:00:00;1;_'
    MaxLength = 11
    TabOrder = 2
    Text = '     :  :  '
    OnKeyPress = edOtnEndKeyPress
  end
  object edOtnCnt: TMaskEdit
    Left = 38
    Top = 91
    Width = 80
    Height = 16
    AutoSize = False
    EditMask = '!99 90:00:00;1;_'
    MaxLength = 11
    TabOrder = 3
    Text = '     :  :  '
    OnKeyPress = edOtnCntKeyPress
  end
  object edGlobBegin: TMaskEdit
    Left = 120
    Top = 76
    Width = 111
    Height = 16
    AutoSize = False
    EditMask = '00/00/0000 !00:00:00;1;_'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    MaxLength = 19
    ParentFont = False
    TabOrder = 4
    Text = '  .  .       :  :  '
    OnKeyPress = edGlobBeginKeyPress
  end
  object edGlobEnd: TMaskEdit
    Left = 120
    Top = 106
    Width = 111
    Height = 16
    AutoSize = False
    EditMask = '00/00/0000 !00:00:00;1;_'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    MaxLength = 19
    ParentFont = False
    TabOrder = 5
    Text = '  .  .       :  :  '
    OnKeyPress = edGlobEndKeyPress
  end
end
