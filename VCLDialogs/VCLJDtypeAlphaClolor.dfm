object FormSetAlphaColor: TFormSetAlphaColor
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FormSetAlphaColor'
  ClientHeight = 127
  ClientWidth = 68
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 0
    Width = 68
    Height = 127
    Align = alClient
    Shape = bsFrame
    ExplicitWidth = 64
    ExplicitHeight = 132
  end
  object Label1: TLabel
    Left = 6
    Top = 1
    Width = 7
    Height = 13
    Caption = 'A'
  end
  object Label2: TLabel
    Left = 22
    Top = 1
    Width = 7
    Height = 13
    Caption = 'R'
  end
  object Label3: TLabel
    Left = 38
    Top = 1
    Width = 7
    Height = 13
    Caption = 'G'
  end
  object Label4: TLabel
    Left = 54
    Top = 1
    Width = 6
    Height = 13
    Caption = 'B'
  end
  object R: TScrollBar
    Left = 17
    Top = 17
    Width = 16
    Height = 107
    Kind = sbVertical
    Max = 255
    PageSize = 0
    TabOrder = 0
    TabStop = False
    OnChange = RChange
  end
  object G: TScrollBar
    Left = 33
    Top = 17
    Width = 16
    Height = 107
    Kind = sbVertical
    Max = 255
    PageSize = 0
    TabOrder = 1
    TabStop = False
    OnChange = RChange
  end
  object B: TScrollBar
    Left = 49
    Top = 17
    Width = 16
    Height = 107
    Kind = sbVertical
    Max = 255
    PageSize = 0
    TabOrder = 2
    TabStop = False
    OnChange = RChange
  end
  object A: TScrollBar
    Left = 1
    Top = 17
    Width = 16
    Height = 106
    Kind = sbVertical
    Max = 255
    PageSize = 0
    TabOrder = 3
    TabStop = False
    OnChange = RChange
  end
end
