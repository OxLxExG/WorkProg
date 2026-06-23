object FrmInclinGraph: TFrmInclinGraph
  Left = 0
  Top = 0
  Width = 451
  Height = 305
  Align = alClient
  TabOrder = 0
  object sb: TStatusBar
    Left = 0
    Top = 286
    Width = 451
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 80
      end
      item
        Width = 70
      end
      item
        Width = 70
      end
      item
        Width = 70
      end
      item
        Width = 70
      end
      item
        Width = 80
      end>
  end
  object cht: TChart
    Left = 0
    Top = 0
    Width = 451
    Height = 286
    BackWall.Brush.Style = bsClear
    Legend.CheckBoxes = True
    Legend.GlobalTransparency = 6
    Legend.ResizeChart = False
    Legend.Symbol.Pen.SmallSpace = 1
    Legend.TextStyle = ltsPercent
    Legend.TopPos = 0
    MarginBottom = 0
    MarginLeft = 0
    MarginRight = 0
    MarginTop = 0
    Title.Text.Strings = (
      'TChart')
    Title.Visible = False
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    BottomAxis.Axis.Visible = False
    BottomAxis.AxisValuesFormat = '##O'
    BottomAxis.ExactDateTime = False
    BottomAxis.Increment = 1.000000000000000000
    BottomAxis.LabelsFormat.Font.Charset = RUSSIAN_CHARSET
    BottomAxis.LabelsOnAxis = False
    BottomAxis.LabelsSeparation = 30
    BottomAxis.LabelStyle = talValue
    BottomAxis.Maximum = 35.000000000000000000
    BottomAxis.MinorTickCount = 0
    BottomAxis.MinorTickLength = 0
    BottomAxis.MinorTicks.Visible = False
    BottomAxis.PositionPercent = 50.000000000000000000
    BottomAxis.TickLength = 0
    BottomAxis.Ticks.Visible = False
    BottomAxis.TicksInner.Visible = False
    BottomAxis.TickOnLabelsOnly = False
    LeftAxis.ExactDateTime = False
    LeftAxis.LabelsFormat.Font.Charset = RUSSIAN_CHARSET
    LeftAxis.LabelsFormat.Font.Color = clGray
    LeftAxis.LabelsFormat.Font.Name = 'Times New Roman'
    LeftAxis.LabelsFormat.Font.Style = [fsBold]
    LeftAxis.LabelStyle = talValue
    LeftAxis.MinorTickCount = 0
    LeftAxis.MinorTickLength = 1
    LeftAxis.TickLength = 0
    RightAxis.Visible = False
    Shadow.Visible = False
    TopAxis.Visible = False
    View3D = False
    View3DWalls = False
    Zoom.Pen.Mode = pmNotXor
    Zoom.Pen.SmallSpace = 1
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 1
    DefaultCanvas = 'TTeeCanvas3D'
    ColorPaletteIndex = 13
    object srData: TLineSeries
      HoverElement = [heCurrent]
      Legend.Text = #1044#1072#1085#1085#1099#1077
      LegendTitle = #1044#1072#1085#1085#1099#1077
      SeriesColor = 64
      Brush.BackColor = clDefault
      LinePen.Width = 3
      Pointer.Brush.Gradient.EndColor = 64
      Pointer.Gradient.EndColor = 64
      Pointer.InflateMargins = True
      Pointer.Pen.Visible = False
      Pointer.Style = psCircle
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
      Transparency = 55
    end
    object srIst: TLineSeries
      HoverElement = [heCurrent]
      Legend.Text = #1040#1087#1088#1086#1082#1089#1080#1084#1072#1094#1080#1103
      LegendTitle = #1040#1087#1088#1086#1082#1089#1080#1084#1072#1094#1080#1103
      SeriesColor = clRed
      Brush.BackColor = clDefault
      LinePen.Width = 2
      Pointer.Brush.Gradient.EndColor = clRed
      Pointer.Gradient.EndColor = clRed
      Pointer.HorizSize = 3
      Pointer.InflateMargins = True
      Pointer.Pen.Visible = False
      Pointer.Style = psCircle
      Pointer.VertSize = 3
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
      Transparency = 57
    end
    object srErrSin: TLineSeries
      HoverElement = [heCurrent]
      Legend.Text = #1048#1089#1090'+'#1086#1096
      LegendTitle = #1048#1089#1090'+'#1086#1096
      Brush.BackColor = clDefault
      Dark3D = False
      LinePen.Width = 2
      Pointer.Brush.Gradient.EndColor = 10708548
      Pointer.Gradient.EndColor = 10708548
      Pointer.HorizSize = 3
      Pointer.InflateMargins = True
      Pointer.Pen.Visible = False
      Pointer.Style = psCircle
      Pointer.VertSize = 3
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
      Transparency = 57
    end
    object srErr: TLineSeries
      HoverElement = [heCurrent]
      Legend.Text = #1086#1096#1080#1073#1082#1072
      LegendTitle = #1086#1096#1080#1073#1082#1072
      SeriesColor = 883154
      Brush.BackColor = clDefault
      LinePen.Width = 2
      Pointer.Brush.Gradient.EndColor = 883154
      Pointer.Gradient.EndColor = 883154
      Pointer.HorizSize = 3
      Pointer.InflateMargins = True
      Pointer.Pen.Visible = False
      Pointer.Style = psCircle
      Pointer.VertSize = 3
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
      Transparency = 55
    end
  end
end
