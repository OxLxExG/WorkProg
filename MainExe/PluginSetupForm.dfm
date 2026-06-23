object FormPluginSetup: TFormPluginSetup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1084#1086#1076#1091#1083#1077#1081
  ClientHeight = 383
  ClientWidth = 594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  DesignSize = (
    594
    383)
  TextHeight = 13
  object btClose: TButton
    Left = 8
    Top = 350
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1050
    TabOrder = 0
    OnClick = btCloseClick
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 594
    Height = 338
    Anchors = [akLeft, akTop, akRight, akBottom]
    BorderWidth = 1
    Header.AutoSizeIndex = -1
    Header.Height = 13
    Header.Options = [hoColumnResize, hoDrag, hoShowImages, hoShowSortGlyphs, hoVisible]
    TabOrder = 1
    TabStop = False
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    OnGetText = TreeGetText
    OnInitNode = TreeInitNode
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        MaxWidth = 1000
        Position = 0
        Text = #1047#1072#1075#1088#1091#1078#1072#1090#1100','#1048#1084#1103
        Width = 150
      end
      item
        MaxWidth = 100
        Position = 1
        Text = #1042#1077#1088#1089#1080#1103
        Width = 60
      end
      item
        Margin = 0
        MaxWidth = 300
        MinWidth = 40
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
        Position = 2
        Text = #1048#1044
        Width = 40
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coWrapCaption]
        Position = 3
        Text = #1060#1072#1081#1083
        Width = 250
      end>
    DefaultText = ''
  end
  object btSave: TButton
    Left = 104
    Top = 350
    Width = 129
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1085#1072#1089#1090#1088#1086#1081#1082#1080
    TabOrder = 2
    OnClick = btSaveClick
  end
  object btUpdate: TButton
    Left = 256
    Top = 350
    Width = 137
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1077#1088#1077#1079#1072#1075#1088#1091#1079#1080#1090#1100' '#1084#1086#1076#1091#1083#1080
    TabOrder = 3
    OnClick = btUpdateClick
  end
end
