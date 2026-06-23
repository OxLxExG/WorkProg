object DialogSelectProfile: TDialogSelectProfile
  Left = 0
  Top = 0
  Caption = #1042#1099#1073#1086#1088' '#1087#1088#1086#1092#1080#1083#1103' '#1087#1088#1080#1073#1086#1088#1072
  ClientHeight = 184
  ClientWidth = 305
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 305
    Height = 143
    Align = alClient
    DefaultNodeHeight = 19
    Header.AutoSizeIndex = 0
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    TabOrder = 0
    TreeOptions.SelectionOptions = [toFullRowSelect, toSelectNextNodeOnRemoval]
    OnGetText = TreeGetText
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Position = 0
        Text = #8470
        Width = 72
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus, coEditable, coStyleColor]
        Position = 1
        Text = #1048#1084#1103
        Width = 229
      end>
  end
  object Panel: TPanel
    Left = 0
    Top = 143
    Width = 305
    Height = 41
    Align = alBottom
    Caption = 'Panel'
    ShowCaption = False
    TabOrder = 1
    object Button: TButton
      Left = 208
      Top = 8
      Width = 75
      Height = 25
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 0
      OnClick = ButtonClick
    end
  end
end
