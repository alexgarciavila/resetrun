Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Console,System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
public class OutlineVariant {
 public static void Apply(string source,string mask,string output,bool run) {
  using(var s=new Bitmap(source)) using(var m=new Bitmap(mask)) using(var o=new Bitmap(s.Width,s.Height,PixelFormat.Format32bppArgb)) {
   double scale=run?m.Width/(double)s.Width:1.0;
   int removed=0;
   for(int y=0;y<s.Height;y++) for(int x=0;x<s.Width;x++) {
    var p=s.GetPixel(x,y); int a=p.A;
    if(a>0 && p.R<70 && p.G<70 && p.B<90) {
     int mx=(int)Math.Round(x*scale),my=(int)Math.Round((y+(run?175:0))*scale);
     bool nearEdge=false;
     for(int dy=-4;dy<=4&&!nearEdge;dy++) for(int dx=-4;dx<=4;dx++) {
      int xx=x+dx,yy=y+dy;
      if(xx<0||yy<0||xx>=s.Width||yy>=s.Height||s.GetPixel(xx,yy).A==0) {nearEdge=true;break;}
     }
     if(nearEdge && mx>=0&&my>=0&&mx<m.Width&&my<m.Height && m.GetPixel(mx,my).A<128) {a=0;removed++;}
    }
    o.SetPixel(x,y,Color.FromArgb(a,p.R,p.G,p.B));
   }
   o.Save(output,ImageFormat.Png);Console.WriteLine(output+": "+removed+" outline pixels removed");
  }
 }
}
"@
foreach($name in @('run','jump','idle','gameover')) {
 [OutlineVariant]::Apply((Join-Path $PWD "images/character/transparent/${name}_resetbot.png"),(Join-Path $PWD "tools/outline_masks/$name.png"),(Join-Path $PWD "images/character/no_outline/${name}_resetbot.png"),($name -eq 'run'))
}

