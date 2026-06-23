object FormGGKP: TFormGGKP
  Left = 0
  Top = 0
  ActiveControl = Tree
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1043#1043#1050#1055
  ClientHeight = 347
  ClientWidth = 726
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
    Width = 726
    Height = 347
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object Splitter: TSplitter
      Left = 361
      Top = 0
      Height = 334
      ExplicitLeft = 8
      ExplicitHeight = 377
    end
    object lbInfo: TLabel
      Left = 0
      Top = 334
      Width = 726
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
      ExplicitWidth = 3
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 361
      Height = 334
      Align = alLeft
      BorderWidth = 1
      Colors.BorderColor = 15987699
      Colors.DisabledColor = clGray
      Colors.DropMarkColor = 15385233
      Colors.DropTargetColor = 15385233
      Colors.DropTargetBorderColor = 15385233
      Colors.FocusedSelectionColor = 15385233
      Colors.FocusedSelectionBorderColor = 15385233
      Colors.GridLineColor = 15987699
      Colors.HeaderHotColor = clBlack
      Colors.HotColor = clBlack
      Colors.SelectionRectangleBlendColor = 15385233
      Colors.SelectionRectangleBorderColor = 15385233
      Colors.SelectionTextColor = clBlack
      Colors.TreeLineColor = 9471874
      Colors.UnfocusedColor = clGray
      Colors.UnfocusedSelectionColor = 13421772
      Colors.UnfocusedSelectionBorderColor = 13421772
      Header.AutoSizeIndex = -1
      Header.Height = 13
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 0
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toFullRowSelect]
      OnAddToSelection = TreeAddToSelection
      OnGetText = TreeGetText
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable]
          Position = 0
          Text = #8470','#1076#1080#1072#1084#1077#1090#1088
        end
        item
          Position = 1
          Text = #1055','#1075'/'#1089#1084'3'
        end
        item
          Position = 2
          Text = #1052#1047
        end
        item
          Position = 3
          Text = #1041#1047
        end
        item
          Position = 4
          Text = #1040'1'
        end
        item
          Position = 5
          Text = #1055#1083#1040'1'
        end
        item
          Position = 6
          Text = #1054#1090#1085'.'#1087#1086#1075' %'
          Width = 55
        end>
    end
    object Chart: TChart
      Left = 364
      Top = 0
      Width = 362
      Height = 334
      AllowPanning = pmNone
      Legend.CheckBoxes = True
      Legend.CheckBoxesStyle = cbsRadio
      Legend.LegendStyle = lsSeriesGroups
      Legend.Symbol.Visible = False
      Legend.TextStyle = ltsPlain
      Legend.TopPos = 6
      Legend.Visible = False
      MarginBottom = 0
      MarginLeft = 0
      MarginRight = 0
      MarginTop = 0
      Title.Text.Strings = (
        'TChart')
      Title.Visible = False
      BottomAxis.Title.Caption = #1040'1'
      LeftAxis.Title.Caption = #1087#1083#1086#1090#1085#1086#1089#1090#1100
      View3D = False
      View3DWalls = False
      Zoom.Allow = False
      Zoom.Pen.Mode = pmNotXor
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      DefaultCanvas = 'TTeeCanvas3D'
      PrintMargins = (
        15
        8
        15
        8)
      ColorPaletteIndex = 8
      object Series1: TLineSeries
        HoverElement = [heCurrent]
        ColorEachLine = False
        SeriesColor = clBlue
        Brush.BackColor = clDefault
        Dark3D = False
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = True
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
      object Series2: TLineSeries
        HoverElement = [heCurrent]
        ColorEachLine = False
        Brush.BackColor = clDefault
        Dark3D = False
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = True
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
      object Series3: TLineSeries
        HoverElement = [heCurrent]
        ColorEachLine = False
        SeriesColor = clOlive
        Brush.BackColor = clDefault
        Dark3D = False
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = True
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
    end
  end
end
