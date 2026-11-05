Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
public class SpriteAlpha {
 public static void Apply(string source, string mask, string output, bool run) {
  using(var s=new Bitmap(source)) using(var m=new Bitmap(mask)) using(var o=new Bitmap(s.Width,s.Height,PixelFormat.Format32bppArgb)) {
   double scale=run ? m.Width/(double)s.Width : 1.0;
   for(int y=0;y<s.Height;y++) for(int x=0;x<s.Width;x++) {
    int mx=(int)Math.Round(x*scale), my=(int)Math.Round((y+(run?175:0))*scale);
    int a=0;
    // Small mask expansion restores original black outline pixels lost by extraction.
    for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
     int xx=mx+dx, yy=my+dy;
     if(xx>=0&&yy>=0&&xx<m.Width&&yy<m.Height) a=Math.Max(a,m.GetPixel(xx,yy).A);
    }
    var p=s.GetPixel(x,y);
    o.SetPixel(x,y,Color.FromArgb(a>80?255:0,p.R,p.G,p.B));
   }
   o.Save(output,ImageFormat.Png);
  }
 }
}
"@
foreach($name in @('run','jump','idle','gameover')) {
 [SpriteAlpha]::Apply((Join-Path $PWD "images/character/${name}_resetbot.png"),(Join-Path $PWD "tools/alpha_masks/$name.png"),(Join-Path $PWD "images/character/transparent/${name}_resetbot.png"),($name -eq 'run'))
}


& (Join-Path $PSScriptRoot "fix_gameover_eyes.ps1")

