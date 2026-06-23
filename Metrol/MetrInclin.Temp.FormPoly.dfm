object FormMetrInclinTP: TFormMetrInclinTP
  Left = 0
  Top = 0
  Caption = 'FormMetrInclinTP'
  ClientHeight = 583
  ClientWidth = 872
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnDestroy = FormDestroy
  TextHeight = 13
  object sp: TSplitter
    Left = 0
    Top = 378
    Width = 872
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    Color = clHotLight
    ParentColor = False
    Visible = False
    ExplicitTop = 380
  end
  object pAlg: TPanel
    Left = 0
    Top = 0
    Width = 872
    Height = 378
    Align = alClient
    TabOrder = 0
    object lbInfo: TLabel
      Left = 1
      Top = 364
      Width = 80
      Height = 13
      Align = alBottom
      Caption = '--------------------'
      WordWrap = True
    end
    object Tree: TVirtualStringTree
      Left = 1
      Top = 1
      Width = 870
      Height = 363
      AccessibleName = 'AHz'
      Align = alClient
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
      Header.MainColumn = -1
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
      Columns = <>
    end
  end
  object pRes: TPanel
    Left = 0
    Top = 383
    Width = 872
    Height = 200
    Align = alBottom
    TabOrder = 1
    Visible = False
    object splRes: TSplitter
      Left = 1
      Top = 94
      Width = 870
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      Color = clHotLight
      ParentColor = False
      Visible = False
      ExplicitTop = 57
    end
    object TreeResA: TVirtualStringTree
      Left = 1
      Top = 1
      Width = 870
      Height = 93
      AccessibleName = 'AHz'
      Align = alClient
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
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toFullRowSelect]
      OnGetText = TreeResAGetText
      OnPaintText = TreeResAPaintText
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #1054#1089#1100
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 1
          Text = 'x'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = 'xt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = 'xtt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 4
          Text = 'xttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 5
          Text = 'y'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 6
          Text = 'yt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 7
          Text = 'ytt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 8
          Text = 'yttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 9
          Text = 'z'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 10
          Text = 'zt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 11
          Text = 'ztt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 12
          Text = 'zttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 13
          Text = '1'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 14
          Text = 't'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 15
          Text = 'tt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 16
          Text = 'ttt'
          Width = 10
        end>
    end
    object TreeResH: TVirtualStringTree
      Left = 1
      Top = 99
      Width = 870
      Height = 100
      AccessibleName = 'AHz'
      Align = alBottom
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
      Header.Height = 20
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 1
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toFullRowSelect]
      OnGetText = TreeResHGetText
      OnPaintText = TreeResAPaintText
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #1054#1089#1100
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 1
          Text = 'x'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = 'xt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = 'xtt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 4
          Text = 'xttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 5
          Text = 'y'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 6
          Text = 'yt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 7
          Text = 'ytt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 8
          Text = 'yttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 9
          Text = 'z'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 10
          Text = 'zt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 11
          Text = 'ztt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 12
          Text = 'zttt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 13
          Text = '1'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 14
          Text = 't'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 15
          Text = 'tt'
          Width = 70
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 16
          Text = 'ttt'
          Width = 10
        end>
    end
  end
end
