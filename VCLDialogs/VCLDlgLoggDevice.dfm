object FormLogg: TFormLogg
  Left = 0
  Top = 0
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 400
    Width = 624
    Height = 41
    Align = alBottom
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object LabelTotal: TLabel
      Left = 280
      Top = 24
      Width = 3
      Height = 15
    end
    object LabelWork: TLabel
      Left = 280
      Top = 3
      Width = 3
      Height = 15
    end
    object BtReadLogg: TButton
      Left = 16
      Top = 6
      Width = 89
      Height = 25
      Caption = 'Read'
      TabOrder = 0
      OnClick = BtReadLoggClick
    end
    object btClose: TButton
      Left = 152
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 1
      OnClick = btCloseClick
    end
  end
  object grid: TDBGrid
    Left = 0
    Top = 0
    Width = 624
    Height = 400
    Align = alClient
    DataSource = ds
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object ds: TDataSource
    DataSet = md
    Left = 144
    Top = 80
  end
  object md: TJvMemoryData
    FieldDefs = <>
    OnCalcFields = mdCalcFields
    Left = 272
    Top = 176
  end
end
