# Draws the app icon (cooking pot with steam and a leaf) into assets/icon/. Run once; commit the PNGs.
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot '..\assets\icon'
New-Item -ItemType Directory -Force $out | Out-Null

function C($hex) { [Drawing.ColorTranslator]::FromHtml($hex) }
function Draw($path, $withBackground, $scale) {
  $size = 1024
  $bmp = New-Object Drawing.Bitmap $size, $size
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  if ($withBackground) { $g.Clear((C '#C2381E')) } else { $g.Clear([Drawing.Color]::Transparent) }
  # content is drawn around the centre and scaled so it stays inside Android's safe zone
  $g.TranslateTransform($size / 2, $size / 2)
  $g.ScaleTransform($scale, $scale)
  $g.TranslateTransform(-$size / 2, -$size / 2)

  $cream = New-Object Drawing.SolidBrush (C '#FFF4E0')
  $deep = New-Object Drawing.SolidBrush (C '#F3D9B1')
  $green = New-Object Drawing.SolidBrush (C '#2F6B3F')
  # handles
  $pen = New-Object Drawing.Pen((C '#FFF4E0'), 38)
  $g.DrawArc($pen, 150, 520, 140, 140, 90, 180)
  $g.DrawArc($pen, 734, 520, 140, 140, -90, 180)
  # pot body (rounded bottom) and lid
  $body = New-Object Drawing.Drawing2D.GraphicsPath
  $body.AddArc(220, 440, 584, 120, 180, 180)
  $body.AddArc(220, 500, 584, 300, 0, 90)
  $body.AddLine(804, 650, 220, 650)
  $g.FillRectangle($cream, 220, 500, 584, 215)
  $g.FillPie($cream, 220, 560, 584, 280, 0, 180)
  $g.FillRectangle($deep, 220, 500, 584, 40)
  $lid = New-Object Drawing.Drawing2D.GraphicsPath
  $lid.AddArc(250, 400, 524, 200, 180, 180)
  $lid.CloseFigure()
  $g.FillPath($cream, $lid)
  $g.FillEllipse($cream, 482, 350, 60, 60)
  # steam
  $steam = New-Object Drawing.Pen((C '#FFF4E0'), 30)
  $steam.StartCap = 'Round'; $steam.EndCap = 'Round'
  foreach ($x in 380, 640) {
    $g.DrawBezier($steam, $x, 300, ($x - 50), 240, ($x + 50), 190, $x, 120)
  }
  # leaf on the lid
  $leaf = New-Object Drawing.Drawing2D.GraphicsPath
  $leaf.AddBezier(512, 650, 560, 560, 660, 550, 700, 580)
  $leaf.AddBezier(700, 580, 660, 660, 580, 670, 512, 650)
  $g.FillPath($green, $leaf)
  $bmp.Save($path, [Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
Draw (Join-Path $out 'icon.png') $true 1.0
Draw (Join-Path $out 'icon_foreground.png') $false 0.72
"Icons written to $out"
