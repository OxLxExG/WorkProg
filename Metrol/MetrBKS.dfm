object FormBKS: TFormBKS
  Left = 0
  Top = 0
  Caption = #1052#1077#1087#1090#1088#1086#1083#1086#1075#1080#1103' '#1041#1050#1057
  ClientHeight = 673
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PanelM: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 673
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object lbInfo: TLabel
      Left = 0
      Top = 660
      Width = 420
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
      ExplicitWidth = 3
    end
    object lbAlpha: TLabel
      Left = 0
      Top = 647
      Width = 420
      Height = 13
      Align = alBottom
      WordWrap = True
      ExplicitWidth = 3
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 420
      Height = 647
      Align = alClient
      BorderWidth = 1
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
          Text = #1060#1086#1082#1091#1089
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = #1047#1086#1085#1076
          Width = 42
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = #1047#1085#1072#1095#1077#1085#1080#1077
          Width = 61
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 4
          Text = #1050#1086#1101#1092
          Width = 92
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 5
          Text = 'U '#1073#1082
          Width = 136
        end>
    end
  end
end
