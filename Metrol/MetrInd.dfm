object FormInd: TFormInd
  Left = 0
  Top = 0
  Caption = #1052#1077#1087#1090#1088#1086#1083#1086#1075#1080#1103' '#1041#1050'Z3'
  ClientHeight = 673
  ClientWidth = 721
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
    Width = 721
    Height = 673
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object lbInfo: TLabel
      Left = 0
      Top = 660
      Width = 721
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
      ExplicitWidth = 3
    end
    object lbAlpha: TLabel
      Left = 0
      Top = 647
      Width = 721
      Height = 13
      Align = alBottom
      WordWrap = True
      ExplicitWidth = 3
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 721
      Height = 647
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
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect]
      OnAddToSelection = TreeAddToSelection
      OnGetText = TreeGetText
      Columns = <
        item
          MaxWidth = 100
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #8470
          Width = 33
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 1
          Text = 'PH1'
          Width = 200
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = 'PH2'
          Width = 200
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = 'AirZZ'
          Width = 282
        end>
    end
  end
end
