object GraphCartForm: TGraphCartForm
  Left = 0
  Top = 0
  Caption = #1058#1077#1089#1090' '#1050#1072#1088#1090#1086#1075#1088#1072#1092#1072
  ClientHeight = 513
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Splitter2: TSplitter
    Left = 0
    Top = 255
    Width = 624
    Height = 3
    Cursor = crVSplit
    Align = alTop
    Beveled = True
    Color = clBtnFace
    ParentColor = False
    ExplicitLeft = 16
    ExplicitTop = 208
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 148
    Width = 624
    Height = 3
    Cursor = crVSplit
    Align = alTop
    Beveled = True
    Color = clBtnFace
    ParentColor = False
    ExplicitLeft = 24
    ExplicitTop = 136
  end
  object Splitter3: TSplitter
    Left = 0
    Top = 375
    Width = 624
    Height = 3
    Cursor = crVSplit
    Align = alTop
    Beveled = True
    Color = clBtnFace
    ParentColor = False
    ExplicitTop = 260
  end
  object Splitter0: TSplitter
    Left = 0
    Top = 145
    Width = 624
    Height = 3
    Cursor = crVSplit
    Align = alTop
    Beveled = True
    Color = clBtnFace
    ParentColor = False
    ExplicitLeft = 16
    ExplicitTop = 32
  end
  object Panel: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel'
    ShowCaption = False
    TabOrder = 0
    object cb400R: TCheckBox
      Left = 8
      Top = 0
      Width = 97
      Height = 17
      Caption = '400'#1082#1043#1094' '#1059#1069#1057
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = cbClick
    end
    object cb400F: TCheckBox
      Tag = 1
      Left = 8
      Top = 18
      Width = 97
      Height = 17
      Caption = '400'#1082#1043#1094' '#1060#1072#1079#1072
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = cbClick
    end
    object cb2000R: TCheckBox
      Tag = 2
      Left = 104
      Top = 3
      Width = 97
      Height = 17
      Caption = '2000'#1082#1043#1094' '#1059#1069#1057
      Checked = True
      State = cbChecked
      TabOrder = 2
      OnClick = cbClick
    end
    object cb2000F: TCheckBox
      Tag = 3
      Left = 104
      Top = 16
      Width = 97
      Height = 17
      Caption = '2000'#1082#1043#1094' '#1060#1072#1079#1072
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = cbClick
    end
    object brEq: TButton
      Left = 216
      Top = 7
      Width = 25
      Height = 25
      Hint = #1042#1099#1088#1072#1074#1085#1080#1090#1100' '#1075#1088#1072#1092#1080#1082#1080' '#1087#1086' '#1074#1099#1089#1086#1090#1077
      Caption = '='
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = brEqClick
    end
    object btClr: TButton
      Left = 261
      Top = 7
      Width = 25
      Height = 25
      Hint = #1054#1095#1080#1089#1090#1080#1100' '#1075#1088#1072#1092#1080#1082#1080
      Caption = 'CLR'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = btClrClick
    end
    object btZero: TButton
      Left = 306
      Top = 7
      Width = 25
      Height = 25
      Hint = #1054#1090#1087#1088#1072#1074#1080#1090#1100' '#1082#1086#1084#1072#1085#1076#1091' 0 '#1074' '#1082#1072#1088#1090#1086#1075#1088#1072#1092
      Caption = '0'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      Visible = False
      OnClick = btZeroClick
    end
    object btMetr: TButton
      Left = 352
      Top = 7
      Width = 65
      Height = 25
      Hint = #1057#1095#1080#1090#1072#1090#1100' '#1084#1077#1090#1088#1086#1083#1086#1075#1080#1102' '#1080#1079' '#1082#1072#1088#1090#1086#1075#1088#1072#1092#1072' '#1080' '#1079#1072#1087#1080#1089#1072#1090#1100' '#1074' '#1092#1072#1081#1083
      Caption = 'Read MTR'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      Visible = False
      OnClick = btMetrClick
    end
  end
  object Chart0: TChart
    Left = 0
    Top = 41
    Width = 624
    Height = 104
    Legend.CheckBoxes = True
    MarginBottom = 0
    MarginRight = 0
    MarginTop = 0
    Title.Text.Strings = (
      '400'#1082#1043#1094' '#1059#1069#1057' Om')
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    LeftAxis.ExactDateTime = False
    LeftAxis.LabelsExponent = True
    LeftAxis.LabelsSeparation = 100
    LeftAxis.Logarithmic = True
    LeftAxis.MaximumOffset = 5
    LeftAxis.MinimumOffset = 5
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DOptions.Orthogonal = False
    View3DWalls = False
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DefaultCanvas = 'TTeeCanvas3D'
    ColorPaletteIndex = 13
  end
  object Chart2: TChart
    Left = 0
    Top = 258
    Width = 624
    Height = 117
    Legend.CheckBoxes = True
    MarginBottom = 0
    MarginRight = 0
    MarginTop = 0
    Title.Text.Strings = (
      '2000'#1082#1043#1094' '#1059#1069#1057' Om')
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    LeftAxis.LabelsExponent = True
    LeftAxis.LabelsSeparation = 100
    LeftAxis.Logarithmic = True
    LeftAxis.MaximumOffset = 5
    LeftAxis.MinimumOffset = 5
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DOptions.Orthogonal = False
    View3DWalls = False
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    DefaultCanvas = 'TTeeCanvas3D'
    ColorPaletteIndex = 13
  end
  object Chart1: TChart
    Left = 0
    Top = 151
    Width = 624
    Height = 104
    Legend.CheckBoxes = True
    MarginBottom = 0
    MarginRight = 0
    MarginTop = 0
    Title.Text.Strings = (
      '400'#1082#1043#1094' '#1060#1072#1079#1072' m'#1043#1088#1072#1076)
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    LeftAxis.MaximumOffset = 5
    LeftAxis.MinimumOffset = 5
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DOptions.Orthogonal = False
    View3DWalls = False
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    DefaultCanvas = 'TTeeCanvas3D'
    ColorPaletteIndex = 13
  end
  object Chart3: TChart
    Left = 0
    Top = 378
    Width = 624
    Height = 116
    Legend.CheckBoxes = True
    MarginBottom = 0
    MarginRight = 0
    MarginTop = 0
    Title.Text.Strings = (
      '2000'#1082#1043#1094' '#1060#1072#1079#1072' m'#1043#1088#1072#1076)
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    LeftAxis.MaximumOffset = 5
    LeftAxis.MinimumOffset = 5
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DOptions.Orthogonal = False
    View3DWalls = False
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitHeight = 124
    DefaultCanvas = 'TTeeCanvas3D'
    ColorPaletteIndex = 13
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 494
    Width = 624
    Height = 19
    Panels = <>
    ExplicitLeft = 320
    ExplicitTop = 264
    ExplicitWidth = 0
  end
end
