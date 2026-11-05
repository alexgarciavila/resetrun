from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
asset_variant = "transparent" if "--original-outline" in sys.argv else "no_outline"
specs={
 'run':('run_resetbot.png',[(x,75,230,230) for x in (55,320,575,825,1080,1325,1575,1810)],12,True),
 'jump':('jump_resetbot.png',[(i*256,150,256,340) for i in range(8)],(8 / 0.7),False),
 'idle':('idle_resetbot.png',[(x,125,240,360) for x in (30,285,535,790,1040,1290,1540,1790)],6,True),
 'game_over':('gameover_resetbot.png',[(x,225,245,255) for x in (45,310,550,790,1035,1285,1535,1785)],8,False),
 'hit':('gameover_resetbot.png',[(x,225,245,255) for x in (45,310,550)],12,False),
}
# Coordinates were measured on 2048-wide previews; source sheets are 2172 wide.
for name, (file, rects, fps, loop) in list(specs.items()):
 if file != 'run_resetbot.png':
  factor = 2172 / 2048
  rects = [tuple(round(v * factor) for v in rect) for rect in rects]
  specs[name] = (file, rects, fps, loop)
# Keep the lowest sole edge pixel (including gray antialiasing) at local y=360 in every Idle frame.
# Measured in source pixels: 493, 489, 480, 483, 489, 491, 491, 491.
file, rects, fps, loop = specs['idle']
idle_feet = (493, 489, 480, 483, 489, 491, 491, 491)
specs['idle'] = (file, [(x, foot - 360, w, h) for (x, y, w, h), foot in zip(rects, idle_feet)], fps, loop)
files=list(dict.fromkeys(s[0] for s in specs.values()))
lines=['[gd_resource type="SpriteFrames" load_steps=38 format=3]','']
for i,f in enumerate(files): lines.append(f'[ext_resource type="Texture2D" path="res://images/character/{asset_variant}/{f}" id="{i+1}"]')
animations=[]
n=0
for name,(file,rects,fps,loop) in specs.items():
 ids=[]
 for x,y,w,h in rects:
  n+=1; ids.append(n)
  lines.extend(['',f'[sub_resource type="AtlasTexture" id="Atlas_{n}"]',f'atlas = ExtResource("{files.index(file)+1}")',f'region = Rect2({x}, {y}, {w}, {h})'])
 frames=', '.join('{"duration": 1.0, "texture": SubResource("Atlas_%s")}'%i for i in ids)
 animations.append('{"frames": ['+frames+'], "loop": '+str(loop).lower()+', "name": &"'+name+'", "speed": '+str(float(fps))+'}')
lines+=['','[resource]','animations = ['+',\n'.join(animations)+']']
# Resource plus source textures plus all atlas regions.
lines[0]=f'[gd_resource type="SpriteFrames" load_steps={n+len(files)+1} format=3]'
(root/'scenes/resetbot_frames.tres').write_text('\n'.join(lines)+'\n')
