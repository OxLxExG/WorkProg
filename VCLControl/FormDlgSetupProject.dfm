object FormSetupProject: TFormSetupProject
  Left = 0
  Top = 0
  Caption = #1057#1074#1086#1081#1089#1090#1074#1072' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 411
  ClientWidth = 630
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  DesignSize = (
    630
    411)
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 632
    Height = 369
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    object TabSheet1: TTabSheet
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Caption = #1057#1074#1086#1081#1089#1090#1074#1072' '#1087#1088#1086#1077#1082#1090#1072
      object Insp: TJvInspector
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 624
        Height = 341
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Style = isItemPainter
        Align = alClient
        BevelEdges = []
        BevelKind = bkNone
        Divider = 350
        ItemHeight = 16
        Painter = Painter
        TabStop = True
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = #1057#1084#1077#1097#1077#1085#1080#1077' '#1075#1083#1091#1073#1080#1085#1099
      ImageIndex = 1
      object InspZ: TJvInspector
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 624
        Height = 341
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Style = isItemPainter
        Align = alClient
        BevelEdges = []
        BevelKind = bkNone
        Divider = 350
        ItemHeight = 16
        Painter = PainterZ
        PopupMenu = ppM
        TabStop = True
        TabOrder = 0
      end
    end
  end
  object btExit: TButton
    Left = 15
    Top = 378
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 0
    OnClick = btExitClick
  end
  object ppM: TPopupActionBar
    Left = 208
    Top = 144
    object NReadOnly: TMenuItem
      AutoCheck = True
      Caption = #1058#1086#1083#1100#1082#1086' '#1095#1090#1077#1085#1080#1077
      Checked = True
      OnClick = UpdateGlu
    end
  end
  object Painter: TJvInspectorDotNETPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBtnText
    CategoryFont.Height = -12
    CategoryFont.Name = 'Segoe UI'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -12
    NameFont.Name = 'Segoe UI'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clWindowText
    ValueFont.Height = -12
    ValueFont.Name = 'Segoe UI'
    ValueFont.Style = []
    DrawNameEndEllipsis = False
    HideSelectFont.Charset = DEFAULT_CHARSET
    HideSelectFont.Color = clHighlightText
    HideSelectFont.Height = -12
    HideSelectFont.Name = 'Segoe UI'
    HideSelectFont.Style = []
    SelectedFont.Charset = DEFAULT_CHARSET
    SelectedFont.Color = clHighlightText
    SelectedFont.Height = -12
    SelectedFont.Name = 'Segoe UI'
    SelectedFont.Style = []
    Left = 324
    Top = 144
  end
  object PainterZ: TJvInspectorDotNETPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBtnText
    CategoryFont.Height = -12
    CategoryFont.Name = 'Segoe UI'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -12
    NameFont.Name = 'Segoe UI'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clWindowText
    ValueFont.Height = -12
    ValueFont.Name = 'Segoe UI'
    ValueFont.Style = []
    DrawNameEndEllipsis = False
    HideSelectFont.Charset = DEFAULT_CHARSET
    HideSelectFont.Color = clHighlightText
    HideSelectFont.Height = -12
    HideSelectFont.Name = 'Segoe UI'
    HideSelectFont.Style = []
    SelectedFont.Charset = DEFAULT_CHARSET
    SelectedFont.Color = clHighlightText
    SelectedFont.Height = -12
    SelectedFont.Name = 'Segoe UI'
    SelectedFont.Style = []
    Left = 324
    Top = 224
  end
end
