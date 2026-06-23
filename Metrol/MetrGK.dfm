object FormGK: TFormGK
  Left = 0
  Top = 0
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1043#1050
  ClientHeight = 311
  ClientWidth = 670
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object PanelM: TPanel
    Left = 0
    Top = 0
    Width = 670
    Height = 311
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object Splitter: TSplitter
      Left = 329
      Top = 0
      Height = 285
      ExplicitLeft = 8
      ExplicitHeight = 377
    end
    object lbInfo: TLabel
      Left = 0
      Top = 298
      Width = 3
      Height = 13
      Align = alBottom
      Alignment = taCenter
    end
    object lbAlpha: TLabel
      Left = 0
      Top = 285
      Width = 3
      Height = 13
      Align = alBottom
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 329
      Height = 285
      Align = alLeft
      BorderWidth = 1
      Header.AutoSizeIndex = -1
      Header.Height = 13
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 0
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toFullRowSelect]
      OnAddToSelection = TreeAddToSelection
      OnGetText = TreeGetText
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #8470
        end
        item
          Position = 1
          Text = 'R,'#1084
        end
        item
          Position = 2
          Text = 'P('#1084#1082#1088'/'#1095') '
          Width = 61
        end
        item
          Position = 3
          Text = #1080#1084#1087'/'#1082#1072#1076#1088
          Width = 52
        end
        item
          Position = 4
          Text = 'P('#1084#1082#1088'/'#1095') '#1088#1072#1089#1095#1080#1090#1072#1085#1085#1086#1077
        end
        item
          Position = 5
          Text = #948'('#1056'),%'
          Width = 66
        end>
    end
    object Chart: TChart
      Left = 332
      Top = 0
      Width = 338
      Height = 285
      Legend.Alignment = laTop
      Legend.LegendStyle = lsSeries
      Legend.ResizeChart = False
      Legend.TopPos = 6
      Legend.Visible = False
      Title.Text.Strings = (
        'TChart')
      Title.Visible = False
      BottomAxis.Title.Caption = #1084#1082#1088'/'#1095
      LeftAxis.Title.Caption = #1080#1084#1087'/'#1082#1072#1076#1088
      View3D = False
      Zoom.Pen.Mode = pmNotXor
      Align = alClient
      TabOrder = 1
      DefaultCanvas = 'TTeeCanvas3D'
      PrintMargins = (
        15
        8
        15
        8)
      ColorPaletteIndex = 1
      object Series: TLineSeries
        HoverElement = [heCurrent]
        Legend.Text = #1044#1072#1085#1085#1099#1077
        LegendTitle = #1044#1072#1085#1085#1099#1077
        Brush.BackColor = clDefault
        LinePen.Width = 3
        Pointer.Brush.Gradient.EndColor = 16751001
        Pointer.Gradient.EndColor = 16751001
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = True
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
        Transparency = 8
      end
      object SeriesLS: TFastLineSeries
        HoverElement = []
        LinePen.Color = 6697881
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
    end
  end
end
