object FormShowArray: TFormShowArray
  Left = 0
  Top = 0
  Caption = 'FormShowArray'
  ClientHeight = 289
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object ChartCode: TChart
    Left = 0
    Top = 0
    Width = 554
    Height = 289
    BottomWall.Visible = False
    LeftWall.Visible = False
    Legend.CheckBoxes = True
    Legend.GlobalTransparency = 18
    Legend.ResizeChart = False
    Legend.TopPos = 0
    MarginBottom = 1
    MarginLeft = 0
    MarginRight = 1
    MarginTop = 1
    MarginUnits = muPixels
    Title.Text.Strings = (
      'TChart')
    Title.Visible = False
    BottomAxis.Axis.Width = 0
    LeftAxis.Axis.Width = 0
    LeftAxis.AxisValuesFormat = '#0.#'
    LeftAxis.LabelsFormat.Font.Shadow.Smooth = False
    LeftAxis.LabelsFormat.Font.Shadow.Visible = False
    LeftAxis.LabelsFormat.Shadow.Visible = False
    LeftAxis.LabelsSeparation = 20
    LeftAxis.LabelStyle = talValue
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DWalls = False
    Zoom.Allow = False
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    OnMouseMove = ChartCodeMouseMove
    DefaultCanvas = 'TTeeCanvas3D'
    PrintMargins = (
      15
      23
      15
      23)
    ColorPaletteIndex = 19
  end
end
