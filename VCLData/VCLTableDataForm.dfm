object TableDataForm: TTableDataForm
  Left = 0
  Top = 0
  Caption = 'TableDataForm'
  ClientHeight = 289
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Grid: TDBGrid
    Left = 0
    Top = 0
    Width = 554
    Height = 289
    Align = alClient
    DataSource = ds
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object ds: TDataSource
    Left = 136
    Top = 64
  end
  object ppm: TPopupMenu
    Left = 280
    Top = 104
    object NGra: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1085#1072' '#1075#1088#1072#1092#1080#1082#1077
      OnClick = NGraClick
    end
  end
end
