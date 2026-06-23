object FormDlgClc: TFormDlgClc
  Left = 0
  Top = 0
  Caption = 'FormDlgClc'
  ClientHeight = 94
  ClientWidth = 386
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  DesignSize = (
    386
    94)
  TextHeight = 13
  object Progress: TProgressBar
    Left = 18
    Top = 12
    Width = 351
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object btExit: TButton
    Left = 294
    Top = 39
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 1
    OnClick = btExitClick
  end
  object btTerminate: TButton
    Left = 98
    Top = 39
    Width = 75
    Height = 25
    Caption = #1055#1088#1077#1088#1074#1072#1090#1100
    TabOrder = 2
    OnClick = btTerminateClick
  end
  object btStart: TButton
    Left = 17
    Top = 39
    Width = 75
    Height = 25
    Caption = #1057#1090#1072#1088#1090
    TabOrder = 3
    OnClick = btStartClick
  end
  object sb: TStatusBar
    Left = 0
    Top = 75
    Width = 386
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
end
