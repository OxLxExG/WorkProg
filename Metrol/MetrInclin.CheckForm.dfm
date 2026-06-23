object FormInclinCheck: TFormInclinCheck
  Left = 0
  Top = 0
  ActiveControl = Tree
  Caption = #1055#1086#1074#1077#1088#1082#1072' '#1080#1085#1082#1083#1080#1085#1086#1084#1077#1090#1088#1072
  ClientHeight = 314
  ClientWidth = 757
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Splitter: TSplitter
    Left = 0
    Top = 227
    Width = 757
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 0
    ExplicitWidth = 280
  end
  object PanelM: TPanel
    Left = 0
    Top = 0
    Width = 757
    Height = 227
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object lbInfo: TLabel
      Left = 0
      Top = 214
      Width = 3
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
    end
    object pc: TCPageControl
      Left = 0
      Top = 0
      Width = 757
      Height = 214
      Align = alClient
      TabOrder = 1
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 757
      Height = 214
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
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 0
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toFullRowSelect]
      OnAddToSelection = TreeAddToSelection
      OnGetText = TreeGetText
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #8470
          Width = 60
        end
        item
          Position = 1
          Text = #1040#1079#1080'.'#1089#1090#1086#1083
          Width = 60
        end
        item
          Position = 2
          Text = #1040#1079#1080#1084#1091#1090
          Width = 60
        end
        item
          Position = 3
          Text = #1040#1079#1080#1084'.'#1086#1096
          Width = 60
        end
        item
          Position = 4
          Text = #1047#1077#1085'.'#1089#1090#1086#1083
          Width = 60
        end
        item
          Position = 5
          Text = #1047#1077#1085#1080#1090
          Width = 60
        end
        item
          Position = 6
          Text = #1047#1077#1085'.'#1086#1096
          Width = 60
        end
        item
          Position = 7
          Text = #1042#1080#1079#1080#1088
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 8
          Text = #1042#1080#1079#1080#1088' '#1084#1072#1075#1085#1080#1090#1085#1099#1081
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 9
          Text = 'G'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 10
          Text = 'H'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 11
          Text = 'I'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 12
          Text = 'Gx'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 13
          Text = 'Gy'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 14
          Text = 'Gz'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 15
          Text = 'Hx'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 16
          Text = 'Hy'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 17
          Text = 'Hz'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 18
          Text = 'Gx.'#1090#1072#1088#1080#1088'.'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 19
          Text = 'Gy.'#1090#1072#1088#1080#1088'.'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 20
          Text = 'Gz.'#1090#1072#1088#1080#1088'.'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 21
          Text = 'Hx.'#1090#1072#1088#1080#1088'.'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 22
          Text = 'Hy.'#1090#1072#1088#1080#1088'.'
          Width = 60
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 23
          Text = 'Hz.'#1090#1072#1088#1080#1088'.'
          Width = 271
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 24
          Text = 'H.'#1089#1090#1086#1083'.'
          Width = 271
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 25
          Text = 'T'
          Width = 277
        end>
    end
  end
  object PanelP: TPanel
    Left = 0
    Top = 230
    Width = 757
    Height = 84
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'PanelP'
    ShowCaption = False
    TabOrder = 1
    Visible = False
    object Splitter2: TSplitter
      Left = 321
      Top = 0
      Height = 84
      ExplicitLeft = 392
      ExplicitTop = 40
      ExplicitHeight = 100
    end
    object TreeA: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 321
      Height = 84
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
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 0
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning]
      TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowVertGridLines, toThemeAware, toUseBlendedImages]
      TreeOptions.SelectionOptions = [toDisableDrawSelection, toExtendedFocus, toMiddleClickSelect, toMultiSelect, toRightClickSelect]
      OnGetText = TreeAHGetText
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = 'G'
          Width = 24
        end
        item
          Position = 1
          Text = 'X'
          Width = 75
        end
        item
          Position = 2
          Text = 'Y'
          Width = 75
        end
        item
          Position = 3
          Text = 'Z'
          Width = 75
        end
        item
          Position = 4
          Text = 'D'
          Width = 72
        end>
    end
    object TreeH: TVirtualStringTree
      Left = 324
      Top = 0
      Width = 433
      Height = 84
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
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 1
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages]
      TreeOptions.SelectionOptions = [toDisableDrawSelection, toExtendedFocus, toSimpleDrawSelection]
      OnGetText = TreeAHGetText
      Columns = <
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = 'H'
          Width = 24
        end
        item
          Position = 1
          Text = 'X'
          Width = 75
        end
        item
          Position = 2
          Text = 'Y'
          Width = 75
        end
        item
          Position = 3
          Text = 'Z'
          Width = 75
        end
        item
          Position = 4
          Text = 'D'
          Width = 184
        end>
    end
  end
end
