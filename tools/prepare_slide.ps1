# Preserve the supplied RGB artwork; map the imagegen alpha back to its canvas.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
public class SlideAlpha {
 public static void Apply(string source, string mask, string output) {
  using (var original = new Bitmap(source))
  using (var alpha = new Bitmap(mask))
  using (var result = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb)) {
   // The extraction is uniformly fitted and centered inside a 3:1 canvas.
   double scale = alpha.Width / (double)original.Width;
   double top = (alpha.Height - original.Height * scale) * 0.5;
   bool[] visible = new bool[original.Width*original.Height];
   for (int y=0; y<original.Height; y++) for (int x=0; x<original.Width; x++) {
    int mx = Math.Min(alpha.Width-1, (int)Math.Round(x*scale));
    int my = Math.Clamp((int)Math.Round(y*scale+top), 0, alpha.Height-1);
    visible[y*original.Width+x] = alpha.GetPixel(mx,my).A >= 128;
   }
   // Keep the character component in each pose; detached floor/motion marks
   // must not turn into dark fragments when composited with the source RGB.
   int[] edges = {0,183,365,550,755,960,1125,1295,1464};
   bool[] visited = new bool[visible.Length], kept = new bool[visible.Length];
   for(int frame=0;frame<8;frame++) {
    int[] queue = new int[visible.Length], best = new int[0];
    for(int y=100;y<285;y++) for(int x=edges[frame];x<edges[frame+1];x++) {
     int seed=y*original.Width+x;
     if(!visible[seed] || visited[seed]) continue;
     int head=0,tail=1;queue[0]=seed;visited[seed]=true;
     while(head<tail) {
      int current=queue[head++],cx=current%original.Width,cy=current/original.Width;
      for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
       int nx=cx+dx,ny=cy+dy;
       if(nx<edges[frame] || nx>=edges[frame+1] || ny<100 || ny>=285) continue;
       int next=ny*original.Width+nx;
       if(visible[next] && !visited[next]) {visited[next]=true;queue[tail++]=next;}
      }
     }
     if(tail>best.Length) {best=new int[tail];Array.Copy(queue,best,tail);}
    }
    foreach(int pixel in best) kept[pixel]=true;
   }
   for(int y=0;y<original.Height;y++) for(int x=0;x<original.Width;x++) {
    var color=original.GetPixel(x,y);
    bool floorShadow = y>=240 && color.R<40 && color.G<45 && color.B>color.R+7 && color.B>color.G+5 && color.G>color.R+1;
    result.SetPixel(x,y,Color.FromArgb(kept[y*original.Width+x] && !floorShadow ?255:0,color.R,color.G,color.B));
   }
   result.Save(output,ImageFormat.Png);
  }
 }
}
"@
foreach ($variant in @('transparent', 'no_outline')) {
    [SlideAlpha]::Apply((Join-Path $projectRoot 'images/character/deslizarse.png'), (Join-Path $projectRoot 'tools/alpha_masks/slide.png'), (Join-Path $projectRoot "images/character/$variant/slide_resetbot.png"))
}
