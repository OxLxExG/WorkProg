object FormNNK2X: TFormNNK2X
  Left = 0
  Top = 0
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1053#1053#1050
  ClientHeight = 305
  ClientWidth = 397
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
    Width = 397
    Height = 305
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object lbInfo: TLabel
      Left = 0
      Top = 292
      Width = 3
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 397
      Height = 292
      Align = alClient
      BorderWidth = 1
      Header.AutoSizeIndex = -1
      Header.Height = 17
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
          Width = 76
        end
        item
          Position = 1
          Text = #1050#1087',%'
          Width = 58
        end
        item
          Position = 2
          Text = #1083'/'#1087
          Width = 60
        end
        item
          Position = 3
          Text = #1041#1051
        end
        item
          Position = 4
          Text = #1041#1055
        end
        item
          Position = 5
          Text = #1044#1051
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 6
          Text = #1044#1055
          Width = 53
        end>
    end
  end
end
