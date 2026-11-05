shader_type canvas_item;
uniform bool align_idle = true;

void fragment() {
 vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
 vec2 sample_uv = UV;
 if (align_idle && pixel.y >= 425.0 && pixel.y < 510.0) {
  float shift = 0.0;
  // Right shoe only: correct the source pose independently of the left shoe.
  if (pixel.x >= 435.0 && pixel.x < 530.0) shift = 1.0;
  else if (pixel.x >= 700.0 && pixel.x < 795.0) shift = 3.0;
  else if (pixel.x >= 970.0 && pixel.x < 1066.0) shift = 5.0;
  else if (pixel.x >= 1235.0 && pixel.x < 1331.0) shift = 3.0;
  else if (pixel.x >= 1500.0 && pixel.x < 1596.0) shift = 1.0;
  else if (pixel.x >= 1765.0 && pixel.x < 1861.0) shift = 1.0;
  sample_uv.y -= shift * TEXTURE_PIXEL_SIZE.y;
 }
 COLOR = texture(TEXTURE, sample_uv) * COLOR;
}
