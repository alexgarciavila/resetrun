# Compose original colors with imagegen alpha, split multi-object sheets and crop.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
public class ObstacleAlpha {
 public static string Apply(string source,string mask,string output,int startY,int endY) {
  using(var image=new Bitmap(source)) using(var alpha=new Bitmap(mask)) {
   if(image.Size!=alpha.Size) throw new Exception("Mask size differs from original.");
   int left=image.Width,top=endY,right=-1,bottom=-1;
   for(int y=startY;y<endY;y++) for(int x=0;x<image.Width;x++) if(alpha.GetPixel(x,y).A>=128) {
    left=Math.Min(left,x);top=Math.Min(top,y);right=Math.Max(right,x);bottom=Math.Max(bottom,y);
   }
   if(right<left) throw new Exception("No opaque object found.");
   using(var result=new Bitmap(right-left+5,bottom-top+5,PixelFormat.Format32bppArgb)) {
    for(int y=top;y<=bottom;y++) for(int x=left;x<=right;x++) if(alpha.GetPixel(x,y).A>=128) {
     var pixel=image.GetPixel(x,y);
     result.SetPixel(x-left+2,y-top+2,Color.FromArgb(255,pixel.R,pixel.G,pixel.B));
    }
    result.Save(output,ImageFormat.Png);
    return String.Format("{0}: {1}x{2}; original region {3},{4},{5},{6}",output,result.Width,result.Height,left,top,right-left+1,bottom-top+1);
   }
  }
 }
}
"@
$items = @(
    @('camrouter','camera',0,760),
    @('camrouter','laptops_router',760,1254),
    @('computer','computer',0,1254),
    @('hightower','tower',0,1254),
    @('perifericos','peripherals',0,1254),
    @('printer','cables',0,625),
    @('printer','printer',625,1254),
    @('repair_station','repair_gate',0,1254)
)
New-Item -ItemType Directory -Force (Join-Path $projectRoot 'images/obstacles/prepared') | Out-Null
foreach($item in $items) {
    [ObstacleAlpha]::Apply((Join-Path $projectRoot "images/obstacles/$($item[0]).png"),(Join-Path $projectRoot "tools/alpha_masks/obstacles/$($item[0]).png"),(Join-Path $projectRoot "images/obstacles/prepared/$($item[1]).png"),$item[2],$item[3])
}
