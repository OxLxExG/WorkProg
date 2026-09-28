object FormCheckUni: TFormCheckUni
  Left = 0
  Top = 0
  Caption = 'FormCheckUni'
  ClientHeight = 420
  ClientWidth = 664
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object pc: TPageControl
    Left = 0
    Top = 0
    Width = 664
    Height = 420
    ActivePage = tshTest
    Align = alClient
    TabOrder = 0
    object tshTest: TTabSheet
      Caption = 'Test'
      object Tree: TVirtualStringTree
        Left = 0
        Top = 0
        Width = 656
        Height = 371
        AccessibleName = 'eI'
        Align = alClient
        DefaultNodeHeight = 19
        Header.AutoSizeIndex = -1
        Header.Height = 15
        Header.MainColumn = -1
        Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
        TabOrder = 0
        TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSort, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes, toAutoChangeScale]
        TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
        TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
        TreeOptions.SelectionOptions = [toFullRowSelect, toSelectNextNodeOnRemoval]
        OnAddToSelection = TreeAddToSelection
        OnGetText = TreeGetText
        Touch.InteractiveGestures = [igPan, igPressAndTap]
        Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
        Columns = <>
      end
      object sb: TStatusBar
        Left = 0
        Top = 371
        Width = 656
        Height = 19
        Panels = <>
        SimplePanel = True
      end
    end
    object tshReport: TTabSheet
      Caption = 'Report'
      ImageIndex = 1
      object mmo: TMemo
        Left = 0
        Top = 0
        Width = 656
        Height = 390
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        ExplicitLeft = 256
        ExplicitTop = 152
        ExplicitWidth = 185
        ExplicitHeight = 89
      end
    end
  end
end
