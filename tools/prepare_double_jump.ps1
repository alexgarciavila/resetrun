# Keep original RGB pixels; use the imagegen extraction only for its alpha mask.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$sourcePath = Join-Path $projectRoot 'images/character/doble salto giratorio.png'
$maskPath = Join-Path $projectRoot 'tools/alpha_masks/double_jump.png'
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;
public class DoubleJumpAlpha {
 public static void Apply(string source, string mask, string output) {
  using (var original = new Bitmap(source))
  using (var alpha = new Bitmap(mask))
  using (var result = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb)) {
   if (original.Size != alpha.Size) throw new System.Exception("Mask dimensions must match the original sheet.");
   for (int y = 0; y < original.Height; y++) for (int x = 0; x < original.Width; x++) {
    var color = original.GetPixel(x, y);
    int opacity = alpha.GetPixel(x, y).A >= 128 ? 255 : 0;
    result.SetPixel(x, y, Color.FromArgb(opacity, color.R, color.G, color.B));
   }
   result.Save(output, ImageFormat.Png);
  }
 }
}
"@
foreach ($variant in @('transparent', 'no_outline')) {
    $output = Join-Path $projectRoot "images/character/$variant/double_jump_resetbot.png"
    [DoubleJumpAlpha]::Apply($sourcePath, $maskPath, $output)
}
