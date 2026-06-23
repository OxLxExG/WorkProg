object FormPIDsetup: TFormPIDsetup
  Left = 0
  Top = 0
  Caption = #1085#1072#1089#1090#1088#1086#1081#1082#1072' '#1090#1077#1088#1084#1086#1089#1090#1072#1090#1072' '#1059#1040#1050'-'#1057#1048
  ClientHeight = 554
  ClientWidth = 916
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnDestroy = FormDestroy
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 916
    Height = 126
    Align = alTop
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object lbTincl: TLabel
      Left = 431
      Top = 72
      Width = 50
      Height = 16
      AutoSize = False
      Caption = '11212 '
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbT: TLabel
      Left = 247
      Top = 72
      Width = 170
      Height = 16
      AutoSize = False
      Caption = '11212   12312312  123213'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label6: TLabel
      Left = 247
      Top = 51
      Width = 119
      Height = 15
      Caption = #1044#1072#1085#1085#1099#1077' '#1090#1077#1084#1087#1077#1088#1072#1090#1091#1088#1099
    end
    object Label5: TLabel
      Left = 8
      Top = 51
      Width = 77
      Height = 15
      Caption = #1044#1072#1085#1085#1099#1077' '#1090#1077#1085#1086#1074
    end
    object lbPower: TLabel
      Left = 8
      Top = 72
      Width = 222
      Height = 16
      AutoSize = False
      Caption = '11212   12312312  123213'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clBlue
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label3: TLabel
      Left = 109
      Top = 6
      Width = 72
      Height = 15
      Caption = #1060#1072#1081#1083' '#1076#1072#1085#1085#1099#1093
    end
    object Label4: TLabel
      Left = 493
      Top = 4
      Width = 14
      Height = 15
      Caption = 'Kp'
    end
    object Label7: TLabel
      Left = 551
      Top = 4
      Width = 10
      Height = 15
      Caption = 'Ki'
    end
    object Label8: TLabel
      Left = 609
      Top = 4
      Width = 14
      Height = 15
      Caption = 'Kd'
    end
    object Label9: TLabel
      Left = 852
      Top = 12
      Width = 55
      Height = 15
      Caption = ' Frm(pow)'
      Visible = False
    end
    object Label10: TLabel
      Left = 855
      Top = 63
      Width = 68
      Height = 15
      Caption = 'to time(stab)'
      Visible = False
    end
    object Label11: TLabel
      Left = 663
      Top = 5
      Width = 26
      Height = 15
      Caption = 'delta'
    end
    object Label12: TLabel
      Left = 695
      Top = 5
      Width = 31
      Height = 15
      Caption = 'Nsred'
    end
    object Label13: TLabel
      Left = 727
      Top = 5
      Width = 38
      Height = 15
      Caption = 'NsredY'
    end
    object Label2: TLabel
      Left = 7
      Top = 2
      Width = 96
      Height = 15
      Caption = #1048#1085#1090#1077#1088#1074#1072#1083' '#1086#1087#1088#1086#1089#1072
    end
    object Label1: TLabel
      Left = 493
      Top = 46
      Width = 114
      Height = 15
      Caption = #1048#1085#1090#1077#1088#1074' '#1086#1087#1088' PID(min)'
    end
    object Label14: TLabel
      Left = 493
      Top = 81
      Width = 51
      Height = 15
      Caption = #1091#1089#1090#1072#1074#1082#1072' '#1058
    end
    object Label15: TLabel
      Left = 109
      Top = 31
      Width = 70
      Height = 15
      Caption = #1060#1072#1081#1083' '#1079#1072#1087#1080#1089#1080
    end
    object sbStart: TSpeedButton
      Left = 458
      Top = 24
      Width = 26
      Height = 27
      AllowAllUp = True
      GroupIndex = 1
      OnClick = sbStartClick
    end
    object odr: TJvFilenameEdit
      Left = 188
      Top = 2
      Width = 293
      Height = 23
      DefaultExt = 'bin'
      Filter = 'csv '#1092#1072#1081#1083' (*.csv)|*.csv'
      DialogOptions = [ofHideReadOnly, ofPathMustExist]
      DirectInput = False
      TabOrder = 0
      Text = ''
    end
    object edT: TEdit
      Left = 536
      Top = 96
      Width = 41
      Height = 23
      TabOrder = 1
      Text = '0'
    end
    object btStart: TButton
      Left = 582
      Top = 95
      Width = 96
      Height = 25
      Caption = 'Update ten Val'
      TabOrder = 2
      OnClick = btStartClick
    end
    object edKp: TEdit
      Left = 493
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 3
      Text = '1'
    end
    object edKi: TEdit
      Left = 551
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 4
      Text = '0'
    end
    object edKd: TEdit
      Left = 609
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 5
      Text = '0'
    end
    object Find: TButton
      Left = 756
      Top = 13
      Width = 87
      Height = 36
      Caption = 'ZieglerNichols'
      TabOrder = 6
      WordWrap = True
      OnClick = FindClick
    end
    object edFrom: TEdit
      Left = 855
      Top = 33
      Width = 52
      Height = 23
      TabOrder = 7
      Text = '14.25'
      Visible = False
    end
    object edTo: TEdit
      Left = 855
      Top = 84
      Width = 52
      Height = 23
      TabOrder = 8
      Text = '17.82'
      Visible = False
    end
    object edDk: TEdit
      Left = 669
      Top = 26
      Width = 26
      Height = 23
      TabOrder = 9
      Text = '10'
    end
    object edSred: TEdit
      Left = 701
      Top = 26
      Width = 20
      Height = 23
      TabOrder = 10
      Text = '20'
    end
    object edSredY: TEdit
      Left = 727
      Top = 26
      Width = 23
      Height = 23
      TabOrder = 11
      Text = '20'
    end
    object edInt: TEdit
      Left = 7
      Top = 25
      Width = 96
      Height = 23
      TabOrder = 12
      Text = '10000'
      OnChange = edIntChange
    end
    object edIntPID: TEdit
      Left = 493
      Top = 62
      Width = 36
      Height = 23
      TabOrder = 13
      Text = '1'
      OnChange = edIntChange
    end
    object btStartPID: TButton
      Left = 613
      Top = 49
      Width = 42
      Height = 21
      Caption = 'start'
      TabOrder = 14
      OnClick = btStartPIDClick
    end
    object btStopPID: TButton
      Left = 613
      Top = 68
      Width = 42
      Height = 21
      Caption = 'stop'
      TabOrder = 15
      OnClick = btStopPIDClick
    end
    object edUstT: TEdit
      Left = 493
      Top = 97
      Width = 36
      Height = 23
      TabOrder = 16
      Text = '70'
      OnChange = edIntChange
      OnKeyPress = edUstTKeyPress
    end
    object odw: TJvFilenameEdit
      Left = 188
      Top = 27
      Width = 269
      Height = 23
      OnAfterDialog = odwAfterDialog
      DialogKind = dkSave
      DefaultExt = 'bin'
      Filter = 'csv '#1092#1072#1081#1083' (*.csv)|*.csv'
      DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
      DirectInput = False
      TabOrder = 17
      Text = ''
    end
    object Find2: TButton
      Left = 756
      Top = 48
      Width = 87
      Height = 36
      Caption = 'CohenCoon'
      TabOrder = 18
      WordWrap = True
      OnClick = FindClick
    end
    object Find3: TButton
      Left = 756
      Top = 84
      Width = 87
      Height = 36
      Caption = #1063#1048#1053#1040'- '#1061#1056#1054#1053#1045#1057#1040'- '#1056#1045#1057#1042#1048#1050#1040
      TabOrder = 19
      WordWrap = True
      OnClick = FindClick
    end
    object Find4: TButton
      Left = 695
      Top = 55
      Width = 55
      Height = 23
      Caption = 'Lambda'
      TabOrder = 20
      WordWrap = True
      OnClick = FindClick
    end
    object FindCoon: TButton
      Left = 695
      Top = 86
      Width = 55
      Height = 23
      Caption = 'coon'
      TabOrder = 21
      WordWrap = True
      OnClick = FindClick
    end
  end
  object Chart: TChart
    Left = 0
    Top = 126
    Width = 916
    Height = 428
    Legend.CheckBoxes = True
    Legend.LegendStyle = lsSeries
    Legend.ResizeChart = False
    Legend.Symbol.Visible = False
    Legend.TextStyle = ltsPlain
    Legend.TopPos = 6
    Title.Text.Strings = (
      'TChart')
    Title.Visible = False
    BottomAxis.Title.Caption = 'time'
    LeftAxis.Title.Caption = 'T,'#1084#1086#1097#1085#1086#1089#1090#1100' '#1090#1077#1085#1072' %'
    View3D = False
    Zoom.Pen.Mode = pmNotXor
    Align = alClient
    TabOrder = 1
    DefaultCanvas = 'TTeeCanvas3D'
    PrintMargins = (
      15
      18
      15
      18)
    ColorPaletteIndex = 13
    object srsPower: TLineSeries
      HoverElement = [heCurrent]
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsTten: TLineSeries
      HoverElement = [heCurrent]
      SeriesColor = 8388863
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsTincl: TLineSeries
      HoverElement = [heCurrent]
      SeriesColor = 1017855
      Brush.BackColor = clDefault
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsFind: TPointSeries
      HoverElement = [heCurrent]
      ClickableLine = False
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psDiamond
      Pointer.VertSize = 2
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsDD: TLineSeries
      HoverElement = [heCurrent]
      Marks.Callout.Length = 0
      SeriesColor = clNavy
      Brush.BackColor = clDefault
      ClickableLine = False
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psCircle
      Pointer.VertSize = 2
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsResampl: TLineSeries
      HoverElement = [heCurrent]
      Marks.Callout.Length = 0
      SeriesColor = clRed
      Brush.BackColor = clDefault
      ClickableLine = False
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psCircle
      Pointer.VertSize = 2
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsdY: TLineSeries
      HoverElement = [heCurrent]
      Marks.Callout.Length = 0
      SeriesColor = clRed
      Brush.BackColor = clDefault
      ClickableLine = False
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psCircle
      Pointer.VertSize = 2
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
    object srsResZ: TLineSeries
      HoverElement = [heCurrent]
      Marks.Callout.Length = 0
      SeriesColor = clBlack
      Brush.BackColor = clDefault
      ClickableLine = False
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psCircle
      Pointer.VertSize = 2
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
  end
  object Timer: TTimer
    Interval = 10000
    OnTimer = TimerTimer
    Left = 368
    Top = 174
  end
  object TimerPID: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = TimerPIDTimer
    Left = 432
    Top = 174
  end
end
