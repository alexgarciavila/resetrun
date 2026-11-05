Add-Type -AssemblyName System.Drawing
$path = Join-Path $PSScriptRoot '../images/character/transparent/gameover_resetbot.png'
$source = [System.Drawing.Bitmap]::FromFile($path)
$edit = [System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot 'alpha_masks/gameover_eye_edit.png'))
$result = New-Object System.Drawing.Bitmap $source
$centers = @(@(148,307),@(395,307),@(680,307),@(945,340),@(1180,377))
$factor = $source.Width / 2048.0
$changed = 0
foreach($center in $centers) {
 $cx = [int][math]::Round($center[0]*$factor)
 $cy = [int][math]::Round($center[1]*$factor)
 for($y=$cy-7;$y -le $cy+7;$y++) {
  for($x=$cx-7;$x -le $cx+7;$x++) {
   $p=$source.GetPixel($x,$y)
   $q=$edit.GetPixel($x,$y)
   if($p.R -lt 140 -and $q.R -gt 180 -and $q.G -lt 100 -and $q.B -lt 100) {
    $result.SetPixel($x,$y,[System.Drawing.Color]::FromArgb($p.A,$q.R,$q.G,$q.B))
    $changed++
   }
  }
 }
}
$source.Dispose();$edit.Dispose()
$result.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()
Write-Output "Pupil pixels corrected: $changed"
