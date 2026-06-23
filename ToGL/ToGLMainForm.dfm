object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Converter Any to (.gl1)'
  ClientHeight = 638
  ClientWidth = 970
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 353
    Top = 0
    Height = 619
    ExplicitLeft = 296
    ExplicitTop = 248
    ExplicitHeight = 100
  end
  object sb: TStatusBar
    Left = 0
    Top = 619
    Width = 970
    Height = 19
    Panels = <
      item
        Width = 400
      end
      item
        Width = 50
      end>
  end
  object Panel: TPanel
    Left = 0
    Top = 0
    Width = 353
    Height = 619
    Align = alLeft
    Caption = 'Panel'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      353
      619)
    object lbFromPB: TLabel
      Left = 43
      Top = 331
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbToPB: TLabel
      Left = 43
      Top = 352
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label1: TLabel
      Left = 9
      Top = 331
      Width = 28
      Height = 15
      Caption = 'From'
    end
    object Label2: TLabel
      Left = 9
      Top = 352
      Width = 13
      Height = 15
      Caption = 'To'
    end
    object lbName: TLabel
      Left = 9
      Top = 302
      Width = 112
      Height = 16
      Caption = 'Horizont PB data'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label3: TLabel
      Left = 194
      Top = 315
      Width = 31
      Height = 15
      Caption = 'Select'
    end
    object Label4: TLabel
      Left = 43
      Top = 315
      Width = 18
      Height = 15
      Caption = 'File'
    end
    object lbGlu: TLabel
      Left = 9
      Top = 3
      Width = 56
      Height = 16
      Caption = 'GTI data'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbToGlu: TLabel
      Left = 43
      Top = 61
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label6: TLabel
      Left = 5
      Top = 82
      Width = 31
      Height = 15
      Caption = 'Select'
    end
    object Label7: TLabel
      Left = 9
      Top = 61
      Width = 13
      Height = 15
      Caption = 'To'
    end
    object lbFromGlu: TLabel
      Left = 43
      Top = 40
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label9: TLabel
      Left = 9
      Top = 40
      Width = 28
      Height = 15
      Caption = 'From'
    end
    object Label10: TLabel
      Left = 43
      Top = 24
      Width = 27
      Height = 15
      Caption = 'Time'
    end
    object lbDeltaTime: TLabel
      Left = 226
      Top = 99
      Width = 79
      Height = 14
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label8: TLabel
      Left = 226
      Top = 78
      Width = 57
      Height = 15
      Caption = 'Delta Time'
    end
    object lbEndGluDep: TLabel
      Left = 226
      Top = 61
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label12: TLabel
      Left = 226
      Top = 24
      Width = 25
      Height = 15
      Caption = 'Dept'
    end
    object lbFromGluDep: TLabel
      Left = 226
      Top = 40
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbMaxTime: TLabel
      Left = 88
      Top = 557
      Width = 147
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Visible = False
    end
    object lbMinTime: TLabel
      Left = 88
      Top = 536
      Width = 147
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Visible = False
    end
    object Label15: TLabel
      Left = 25
      Top = 536
      Width = 56
      Height = 15
      Caption = 'Min Depth'
      Visible = False
    end
    object Label16: TLabel
      Left = 25
      Top = 557
      Width = 57
      Height = 15
      Caption = 'Max Depth'
      Visible = False
    end
    object Label17: TLabel
      Left = 59
      Top = 520
      Width = 27
      Height = 15
      Caption = 'Time'
      Visible = False
    end
    object Label18: TLabel
      Left = 242
      Top = 520
      Width = 25
      Height = 15
      Caption = 'Dept'
      Visible = False
    end
    object lbMinDep: TLabel
      Left = 242
      Top = 536
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Visible = False
    end
    object lbMaxDep: TLabel
      Left = 242
      Top = 557
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Visible = False
    end
    object Label5: TLabel
      Left = 8
      Top = 376
      Width = 35
      Height = 15
      Caption = 'Mnem'
    end
    object Label11: TLabel
      Left = 30
      Top = 457
      Width = 39
      Height = 15
      Caption = 'Scale 1:'
    end
    object Label13: TLabel
      Left = 23
      Top = 415
      Width = 12
      Height = 15
      Caption = 'H:'
    end
    object Label14: TLabel
      Left = 88
      Top = 415
      Width = 14
      Height = 15
      Caption = 'm:'
    end
    object Label19: TLabel
      Left = 157
      Top = 415
      Width = 8
      Height = 15
      Caption = 's:'
    end
    object Label20: TLabel
      Left = 217
      Top = 415
      Width = 19
      Height = 15
      Caption = 'ms:'
    end
    object Label21: TLabel
      Left = 41
      Top = 399
      Width = 37
      Height = 15
      Caption = 'Delta X'
    end
    object Label22: TLabel
      Left = 30
      Top = 483
      Width = 32
      Height = 15
      Caption = 'Add Y'
    end
    object lbSpeed: TLabel
      Left = 159
      Top = 232
      Width = 25
      Height = 15
      Caption = 'm/H'
      Enabled = False
      Visible = False
    end
    object Label23: TLabel
      Left = 8
      Top = 210
      Width = 91
      Height = 16
      Caption = 'Filtered data'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbOutRangeFrom: TLabel
      Left = 45
      Top = 168
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbOutRangeFromDept: TLabel
      Left = 228
      Top = 168
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label26: TLabel
      Left = 197
      Top = 168
      Width = 25
      Height = 15
      Caption = 'Dept'
    end
    object lbOutRangeToDept: TLabel
      Left = 228
      Top = 189
      Width = 79
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label28: TLabel
      Left = 45
      Top = 152
      Width = 27
      Height = 15
      Caption = 'Time'
    end
    object Label29: TLabel
      Left = 11
      Top = 168
      Width = 28
      Height = 15
      Caption = 'From'
    end
    object lbOutRangeTo: TLabel
      Left = 45
      Top = 189
      Width = 145
      Height = 15
      AutoSize = False
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label31: TLabel
      Left = 11
      Top = 131
      Width = 84
      Height = 16
      Caption = 'Output Range'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label32: TLabel
      Left = 5
      Top = 102
      Width = 25
      Height = 15
      Caption = 'View'
    end
    object Label24: TLabel
      Left = 11
      Top = 189
      Width = 13
      Height = 15
      Caption = 'To'
    end
    object edPbBegin: TMaskEdit
      Left = 194
      Top = 331
      Width = 111
      Height = 16
      TabStop = False
      AutoSize = False
      EditMask = '00/00/0000 !00:00:00;1;_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 19
      ParentFont = False
      TabOrder = 0
      Text = '  .  .       :  :  '
    end
    object edPbEnd: TMaskEdit
      Left = 194
      Top = 352
      Width = 111
      Height = 16
      TabStop = False
      AutoSize = False
      EditMask = '00/00/0000 !00:00:00;1;_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 19
      ParentFont = False
      TabOrder = 1
      Text = '  .  .       :  :  '
    end
    object edEndGlu: TMaskEdit
      Left = 42
      Top = 101
      Width = 111
      Height = 16
      TabStop = False
      AutoSize = False
      EditMask = '00/00/0000 !00:00:00;1;_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 19
      ParentFont = False
      TabOrder = 2
      Text = '  .  .       :  :  '
    end
    object edFromGlu: TMaskEdit
      Left = 42
      Top = 83
      Width = 111
      Height = 16
      TabStop = False
      AutoSize = False
      EditMask = '00/00/0000 !00:00:00;1;_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 19
      ParentFont = False
      TabOrder = 3
      Text = '  .  .       :  :  '
    end
    object cbMnem: TComboBox
      Left = 43
      Top = 373
      Width = 262
      Height = 22
      Style = csOwnerDrawFixed
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 4
    end
    object edScale: TEdit
      Left = 69
      Top = 454
      Width = 121
      Height = 23
      TabOrder = 5
      Text = '200'
    end
    object btPbApply: TButton
      Left = 229
      Top = 473
      Width = 75
      Height = 25
      Caption = 'Apply'
      TabOrder = 6
      OnClick = btPbApplyClick
    end
    object udH: TJvUpDown
      Left = 69
      Top = 412
      Width = 16
      Height = 23
      Associate = edH
      Min = -100
      TabOrder = 7
    end
    object edH: TEdit
      Left = 41
      Top = 412
      Width = 28
      Height = 23
      TabOrder = 8
      Text = '0'
    end
    object edM: TEdit
      Left = 108
      Top = 412
      Width = 28
      Height = 23
      TabOrder = 9
      Text = '0'
    end
    object udM: TJvUpDown
      Left = 136
      Top = 412
      Width = 16
      Height = 23
      Associate = edM
      Min = -59
      Max = 59
      TabOrder = 10
    end
    object udS: TJvUpDown
      Left = 200
      Top = 412
      Width = 16
      Height = 23
      Associate = edS
      Min = -59
      Max = 59
      TabOrder = 11
    end
    object edS: TEdit
      Left = 172
      Top = 412
      Width = 28
      Height = 23
      TabOrder = 12
      Text = '0'
    end
    object edmS: TEdit
      Left = 242
      Top = 412
      Width = 44
      Height = 23
      TabOrder = 13
      Text = '0'
    end
    object btApplyGti: TButton
      Left = 159
      Top = 82
      Width = 55
      Height = 35
      Caption = 'Apply'
      TabOrder = 14
      OnClick = btApplyGtiClick
    end
    object edAddDepth: TEdit
      Left = 69
      Top = 480
      Width = 121
      Height = 23
      TabOrder = 15
      Text = '0'
    end
    object JvUpDown1: TJvUpDown
      Left = 286
      Top = 412
      Width = 16
      Height = 23
      Associate = edmS
      Min = -999
      Max = 999
      TabOrder = 16
    end
    object chMonotone: TCheckBox
      Left = 28
      Top = 247
      Width = 84
      Height = 17
      Caption = 'Monotone'
      TabOrder = 17
      OnClick = chMonotoneClick
    end
    object chRemoveSpeed: TCheckBox
      Left = 28
      Top = 232
      Width = 106
      Height = 17
      Caption = 'Max Speed'
      TabOrder = 18
      Visible = False
      OnClick = chRemoveSpeedClick
    end
    object edSpeed: TEdit
      Left = 118
      Top = 229
      Width = 35
      Height = 23
      Enabled = False
      TabOrder = 19
      Text = '200'
      Visible = False
    end
    object btFilter: TButton
      Left = 229
      Top = 258
      Width = 75
      Height = 25
      Caption = 'Apply'
      TabOrder = 20
      OnClick = btFilterClick
    end
    object chAverage: TCheckBox
      Left = 28
      Top = 262
      Width = 75
      Height = 17
      Caption = 'Average'
      TabOrder = 21
      OnClick = chMonotoneClick
    end
    object edNave: TEdit
      Left = 118
      Top = 259
      Width = 35
      Height = 23
      TabOrder = 22
      Text = '1'
    end
    object btResetFilter: TButton
      Left = 229
      Top = 227
      Width = 75
      Height = 25
      Caption = 'Reset'
      TabOrder = 23
      OnClick = btResetFilterClick
    end
    object cbDelJumps: TCheckBox
      Left = 28
      Top = 277
      Width = 73
      Height = 17
      Caption = 'Del Jumps'
      TabOrder = 24
      OnClick = chMonotoneClick
    end
    object btResetOut: TButton
      Left = 228
      Top = 137
      Width = 75
      Height = 25
      Caption = 'Reset'
      TabOrder = 25
      OnClick = btResetOutClick
    end
  end
  object pc: TPageControl
    Left = 356
    Top = 0
    Width = 614
    Height = 619
    ActivePage = Graph
    Align = alClient
    TabOrder = 2
    object db: TTabSheet
      Caption = 'PB Data'
      object DBGridPB: TDBGrid
        Left = 0
        Top = 0
        Width = 606
        Height = 589
        Align = alClient
        DataSource = DataSourcePB
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
      end
    end
    object tshGti: TTabSheet
      Caption = 'GTI'
      ImageIndex = 1
      object DBGridGTI: TDBGrid
        Left = 0
        Top = 0
        Width = 606
        Height = 589
        Align = alClient
        DataSource = DataSourceGTI
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
      end
    end
    object Graph: TTabSheet
      Caption = 'Graph'
      ImageIndex = 2
      object Chart: TChart
        Left = 0
        Top = 0
        Width = 606
        Height = 589
        BackWall.Visible = False
        BottomWall.Visible = False
        LeftWall.Visible = False
        Legend.CheckBoxes = True
        Legend.GlobalTransparency = 70
        Legend.ResizeChart = False
        Legend.TopPos = 0
        MarginLeft = 8
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        OnClickSeries = ChartClickSeries
        RightAxis.Visible = False
        TopAxis.Visible = False
        View3D = False
        View3DWalls = False
        Align = alClient
        BevelOuter = bvNone
        PopupMenu = ppm
        TabOrder = 0
        OnMouseDown = ChartMouseDown
        DefaultCanvas = 'TTeeCanvas3D'
        PrintMargins = (
          27
          15
          27
          15)
        ColorPaletteIndex = 13
        object Series1: TFastLineSeries
          HoverElement = []
          LinePen.Color = 10708548
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object Series2: TFastLineSeries
          HoverElement = []
          LinePen.Color = 3513587
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object Series3: TFastLineSeries
          HoverElement = []
          SeriesColor = clLime
          LinePen.Color = clLime
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object Series4: TFastLineSeries
          HoverElement = []
          Legend.Visible = False
          SeriesColor = 8388863
          ShowInLegend = False
          LinePen.Color = 8388863
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object Series5: TFastLineSeries
          HoverElement = []
          Legend.Visible = False
          SeriesColor = 8388863
          ShowInLegend = False
          LinePen.Color = 8388863
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
      end
    end
  end
  object MainMenu: TMainMenu
    Left = 472
    Top = 88
    object mFile: TMenuItem
      Caption = 'File'
      object NOpen: TMenuItem
        Caption = 'Open'
        object mOpenHorozontPB: TMenuItem
          Caption = 'Horizont PB'
          OnClick = mOpenHorozontPBClick
        end
        object LAS1: TMenuItem
          Caption = 'LAS'
          OnClick = LAS1Click
        end
        object N3: TMenuItem
          Caption = '-'
        end
        object mOpenTimeDepthtTxt: TMenuItem
          Caption = 'Time-Depth.txt'
          OnClick = mOpenTimeDepthtTxtClick
        end
        object Opeb1: TMenuItem
          Caption = 'Datetime-Zb-Dl.las'
          OnClick = Opeb1Click
        end
        object DatetxtTimetxtZbDllas1: TMenuItem
          Caption = 'Date(txt)-Time(txt)-Zb-Dl.las'
          OnClick = DatetxtTimetxtZbDllas1Click
        end
        object DEPTTimezbtslasOpeb: TMenuItem
          Caption = 'DEPT-TIME-'#1075#1083#1091#1073'-TIME_SEC.las'
          OnClick = DEPTTimezbtslasOpebClick
        end
        object N1DTMs15VALUE54mlas1: TMenuItem
          Caption = '1.DTM,s-15.VALUE54,m.las'
          OnClick = N1DTMs15VALUE54mlas1Click
        end
        object t2md1: TMenuItem
          Caption = '*.t2md'
          OnClick = t2md1Click
        end
      end
      object CartographerAddGl11: TMenuItem
        Caption = 'Add Gl1 to LAS...'
        OnClick = CartographerAddGl11Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exportgl1file1: TMenuItem
        Caption = 'Save .gl1 file'
        OnClick = btSaveClick
      end
    end
    object mOptions: TMenuItem
      Caption = 'Options'
      object mClearTmp: TMenuItem
        AutoCheck = True
        Caption = 'Clear temp file'
      end
      object NTimeDepthtxt: TMenuItem
        Caption = 'Time-Depth.txt'
        object UserDateTimeFormat: TMenuItem
          Caption = 'UserDateTimeFormat...'
          OnClick = UserDateTimeFormatClick
        end
      end
      object NLAS: TMenuItem
        Caption = 'LAS'
        object DatetimeZbDllas: TMenuItem
          Caption = 'Datetime-Zb-Dl.las'
          object NLasDepth: TMenuItem
            Caption = 'Depth'
            object NZaboyS101: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'S101: Zaboy: m'
              GroupIndex = 11
            end
            object NDolotoS115: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'S115: Doloto: m'
              Checked = True
              GroupIndex = 11
            end
          end
          object NLasDT: TMenuItem
            Caption = 'Time'
            object NLasTime_DateTime: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'DATETIME: Double '
              Checked = True
            end
          end
        end
        object DateTimeZbDl1: TMenuItem
          Caption = 'Date(txt)-Time(txt)-Zb-Dl.las'
          object NLasDTTxtDepth: TMenuItem
            Caption = 'Depth'
            GroupIndex = 11
            object d1: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'DMEA: Zaboy: m '
              GroupIndex = 12
            end
            object NDolotoDBTM: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'DBTM:  Doloto: m'
              Checked = True
              GroupIndex = 12
            end
          end
          object ime1: TMenuItem
            Caption = 'Time'
            GroupIndex = 11
            Visible = False
            object NLasTime_Date1Time2txt: TMenuItem
              AutoCheck = True
              AutoHotkeys = maManual
              Caption = 'DATE: TIME: txt'
              Checked = True
            end
          end
        end
        object DEPTTimezbtslas: TMenuItem
          Caption = 'DEPT-Time-zb-ts.las'
          Visible = False
          object D2: TMenuItem
            Caption = 'Depth'
            object M1: TMenuItem
              Caption = #1075#1083#1091#1073'.M'
              Checked = True
            end
          end
          object ime2: TMenuItem
            Caption = 'Time'
            object ime3: TMenuItem
              Caption = 'Time'
              Checked = True
            end
            object imeSec1: TMenuItem
              Caption = 'Time_Sec'
            end
          end
        end
      end
      object NFilters: TMenuItem
        Caption = 'Filters'
        object NDelJumps: TMenuItem
          Caption = 'Del Jumps'
          OnClick = NDelJumpsClick
        end
      end
      object NFrameTime: TMenuItem
        Caption = 'FrameTime(s)'
        object N20971521: TMenuItem
          AutoCheck = True
          AutoHotkeys = maManual
          Caption = '2.097152'
          Checked = True
          GroupIndex = 1
          RadioItem = True
        end
        object N41943041: TMenuItem
          AutoCheck = True
          Caption = '4.194304'
          GroupIndex = 1
          RadioItem = True
        end
        object N41: TMenuItem
          AutoCheck = True
          AutoHotkeys = maManual
          Caption = '4.00000'
          GroupIndex = 1
          RadioItem = True
        end
        object Setup1: TMenuItem
          AutoCheck = True
          AutoHotkeys = maManual
          Caption = 'Setup...'
          GroupIndex = 1
          RadioItem = True
          OnClick = Setup1Click
        end
      end
    end
    object Exit1: TMenuItem
      Caption = 'Exit'
      OnClick = Exit1Click
    end
  end
  object DataSourcePB: TDataSource
    Left = 472
    Top = 146
  end
  object DataSourceGTI: TDataSource
    Left = 560
    Top = 146
  end
  object ppm: TPopupMenu
    AutoPopup = False
    Left = 688
    Top = 314
    object ppRemoveArrea: TMenuItem
      Caption = 'Remove Arrea'
      OnClick = ppRemoveArreaClick
    end
    object BeginOutputRange1: TMenuItem
      Caption = 'Begin Output Range'
      OnClick = BeginOutputRange1Click
    end
    object BeginOutputRange2: TMenuItem
      Caption = 'End Output Range'
      OnClick = BeginOutputRange2Click
    end
  end
end
