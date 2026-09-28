object DialogPoly: TDialogPoly
  Left = 0
  Top = 0
  Caption = 'DialogPoly'
  ClientHeight = 333
  ClientWidth = 964
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object mmo: TMemo
    Left = 0
    Top = 97
    Width = 964
    Height = 236
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object pb: TPanel
    Left = 0
    Top = 0
    Width = 964
    Height = 97
    Align = alTop
    BevelEdges = []
    BevelOuter = bvNone
    Caption = 'pb'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      964
      97)
    object btnClose: TButton
      Left = 881
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnLS: TButton
      Left = 39
      Top = 10
      Width = 41
      Height = 25
      Caption = 'LS'
      TabOrder = 1
      OnClick = btnLSClick
    end
    object btnRunAmp: TButton
      Left = 86
      Top = 10
      Width = 75
      Height = 25
      Caption = 'LMAmp'
      TabOrder = 2
      OnClick = btnRunAmpClick
    end
    object btnLMZU: TButton
      Left = 167
      Top = 10
      Width = 48
      Height = 25
      Caption = 'LMZU'
      TabOrder = 3
      OnClick = btnLMZUClick
    end
    object chkV: TCheckBox
      Left = 0
      Top = -1
      Width = 33
      Height = 12
      Caption = 'cV'
      TabOrder = 4
      OnClick = chkVClick
    end
    object chkZ: TCheckBox
      Left = -1
      Top = 10
      Width = 33
      Height = 17
      Caption = 'cZ'
      TabOrder = 5
      OnClick = chkZClick
    end
    object chkA: TCheckBox
      Left = -1
      Top = 24
      Width = 33
      Height = 17
      Caption = 'cM'
      TabOrder = 6
      OnClick = chkAClick
    end
    object btnClr: TButton
      Left = 830
      Top = 8
      Width = 45
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Clear'
      TabOrder = 7
      OnClick = btnClrClick
    end
    object btnT: TButton
      Left = 215
      Top = 10
      Width = 34
      Height = 25
      Caption = 'T'
      TabOrder = 8
      OnClick = btnTClick
    end
    object btnKos: TButton
      Left = 255
      Top = 10
      Width = 34
      Height = 25
      Caption = 'Kos'
      TabOrder = 9
      OnClick = btnKosClick
    end
    object btnKosv2: TButton
      Left = 295
      Top = 10
      Width = 34
      Height = 25
      Caption = 'KsV2'
      TabOrder = 10
      OnClick = btnKosv2Click
    end
    object btnClrSe: TButton
      Left = 779
      Top = 8
      Width = 45
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'ClrSE'
      TabOrder = 11
      OnClick = btnClrSeClick
    end
    object btCorrVisir: TButton
      Left = 71
      Top = 41
      Width = 75
      Height = 25
      Caption = 'CorrVisir'
      TabOrder = 12
      OnClick = btCorrVisirClick
    end
    object btRunTests: TButton
      Left = 152
      Top = 41
      Width = 41
      Height = 25
      Caption = 'Test'
      TabOrder = 13
      OnClick = btRunTestsClick
    end
    object btHuber: TButton
      Left = 199
      Top = 41
      Width = 75
      Height = 25
      Caption = 'Huber Test'
      TabOrder = 14
      OnClick = btHuberClick
    end
    object btBestHu: TButton
      Left = 320
      Top = 41
      Width = 67
      Height = 25
      Caption = 'BestHu2:1:2'
      TabOrder = 15
      OnClick = btBestHuClick
    end
    object bt240: TButton
      Left = 401
      Top = 41
      Width = 75
      Height = 25
      Caption = '240 Test'
      TabOrder = 16
      OnClick = bt240Click
    end
    object cbW: TCheckBox
      Left = 273
      Top = 45
      Width = 41
      Height = 17
      Caption = 'W+'
      TabOrder = 17
    end
    object btLinAll: TButton
      Left = 167
      Top = 72
      Width = 75
      Height = 25
      Caption = 'LinAll'
      TabOrder = 18
      OnClick = btLinAllClick
    end
    object btLin240: TButton
      Left = 319
      Top = 70
      Width = 75
      Height = 25
      Caption = 'Lin240'
      TabOrder = 19
      OnClick = btLin240Click
    end
    object chCosT: TCheckBox
      Left = 0
      Top = 47
      Width = 49
      Height = 17
      Caption = 'CosT'
      TabOrder = 20
    end
    object btBestHuLin: TButton
      Left = 5
      Top = 70
      Width = 75
      Height = 25
      Caption = 'BestHuLin'
      TabOrder = 21
      OnClick = btBestHuLinClick
    end
    object btLinCrossCompare: TButton
      Left = 86
      Top = 72
      Width = 75
      Height = 25
      Caption = 'CrossCompare'
      TabOrder = 22
      OnClick = btLinCrossCompareClick
    end
    object btHybridHuber: TButton
      Left = 413
      Top = 70
      Width = 75
      Height = 25
      Caption = 'HybridHuber'
      TabOrder = 23
      OnClick = btHybridHuberClick
    end
    object btCompareTemperatureNodes: TButton
      Left = 507
      Top = 70
      Width = 75
      Height = 25
      Caption = 'btCompareTemperatureNodes'
      TabOrder = 24
      OnClick = btCompareTemperatureNodesClick
    end
    object Button1: TButton
      Left = 600
      Top = 70
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 25
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 694
      Top = 70
      Width = 75
      Height = 25
      Caption = 'Button2'
      TabOrder = 26
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 788
      Top = 70
      Width = 75
      Height = 25
      Caption = 'Button3'
      TabOrder = 27
      OnClick = Button3Click
    end
    object ch5: TCheckBox
      Left = 256
      Top = 74
      Width = 57
      Height = 17
      Caption = '5 nodes'
      TabOrder = 28
    end
  end
end
