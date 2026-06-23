object FormNNK128: TFormNNK128
  Left = 0
  Top = 0
  ActiveControl = Tree
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1053#1053#1050
  ClientHeight = 382
  ClientWidth = 657
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
    Width = 657
    Height = 382
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object Splitter: TSplitter
      Left = 281
      Top = 0
      Height = 369
      ExplicitLeft = 8
      ExplicitHeight = 377
    end
    object lbInfo: TLabel
      Left = 0
      Top = 369
      Width = 3
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 281
      Height = 369
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
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #8470','#1076#1080#1072#1084#1077#1090#1088
        end
        item
          Position = 1
          Text = #1050#1087',%'
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
          Text = #1043#1082
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 5
          Text = #1052'/'#1041','#1082' '#1074#1086#1076#1077
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 6
          Text = #1052#1047','#1082' '#1074#1086#1076#1077
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 7
          Text = #1041#1047','#1082' '#1074#1086#1076#1077
        end
        item
          MinWidth = 25
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 8
          Text = #1043#1050','#1082' '#1074#1086#1076#1077
          Width = 31
        end>
    end
    object Chart: TChart
      Left = 284
      Top = 0
      Width = 373
      Height = 369
      AllowPanning = pmNone
      Legend.CheckBoxes = True
      Legend.CheckBoxesStyle = cbsRadio
      Legend.LegendStyle = lsSeriesGroups
      Legend.Symbol.Visible = False
      Legend.TextStyle = ltsPlain
      Legend.TopPos = 6
      Title.Text.Strings = (
        'TChart')
      Title.Visible = False
      BottomAxis.Title.Caption = #1050#1087',%'
      LeftAxis.Title.Caption = #1082' '#1074#1086#1076#1077
      View3D = False
      Zoom.Allow = False
      Zoom.Pen.Mode = pmNotXor
      Align = alClient
      PopupMenu = ppM
      TabOrder = 1
      DefaultCanvas = 'TTeeCanvas3D'
      PrintMargins = (
        15
        8
        15
        8)
      ColorPaletteIndex = 8
    end
    object Edit1: TEdit
      Left = 616
      Top = 0
      Width = 41
      Height = 21
      TabOrder = 2
      Text = '148'
      OnKeyPress = Edit1KeyPress
    end
  end
  object ppM: TPopupActionBar
    Left = 360
    Top = 56
    object NShowLegend: TMenuItem
      AutoCheck = True
      Caption = #1051#1077#1075#1077#1085#1076#1072
      Checked = True
      OnClick = NShowLegendClick
    end
    object NWater: TMenuItem
      AutoCheck = True
      Caption = #1055#1086#1082#1072#1079#1099#1074#1072#1090#1100' '#1074#1086#1076#1091
      OnClick = NWaterClick
    end
  end
end
