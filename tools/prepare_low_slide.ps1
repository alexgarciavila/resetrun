# Remove near-transparent extraction noise while retaining the revised artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;
public class LowSlideAlpha {
 public static void Apply(string source, string output) {
  using(var image=new Bitmap(source))
  using(var result=new Bitmap(image.Width,image.Height,PixelFormat.Format32bppArgb)) {
   for(int y=0;y<image.Height;y++) for(int x=0;x<image.Width;x++) {
    var pixel=image.GetPixel(x,y);
    result.SetPixel(x,y,Color.FromArgb(pixel.A>=128?255:0,pixel.R,pixel.G,pixel.B));
   }
   result.Save(output,ImageFormat.Png);
  }
 }
}
"@
foreach($variant in @('no_outline','transparent')) {
    [LowSlideAlpha]::Apply((Join-Path $projectRoot 'tools/alpha_masks/slide_low_source.png'),(Join-Path $projectRoot "images/character/$variant/slide_low_resetbot.png"))
}
