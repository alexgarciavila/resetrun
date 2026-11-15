"""Split imagegen transparency sheets into individual, padded game sprites.

Source artwork remains in images/obstacles/sources/<world>; alpha sheets are retained.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    entries = json.loads((ROOT / 'tools/new_obstacles.json').read_text())
    for world, objects in entries.items():
        sheet = Image.open(ROOT / f'tools/alpha_masks/new_obstacles/{world}.png').convert('RGBA')
        sheet.putalpha(sheet.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
        width, height = sheet.size
        # Original sheets have three columns and two rows, with unequal baselines.
        # Vendrell's lamp extends below the first row's baseline.
        split = {'botiga': .49, 'magatzem': .48, 'oficina': .49, 'vendrell': .49}.get(world, .53)
        for index, (name, _) in enumerate(objects):
            col, row = index % 3, index // 3
            columns = {
                'magatzem': ([0, .305, .645, 1], [0, .30, .625, 1]),
                'oficina': ([0, .33, .68, 1], [0, .32, .69, 1]),
                'botiga': ([0, .38, .66, 1], [0, .35, .65, 1]),
                'taller': ([0, .35, .66, 1], [0, .39, .63, 1]),
                'vendrell': ([0, .40, .64, 1], [0, .40, .64, 1]),
            }.get(world, ([0, 1/3, 2/3, 1], [0, 1/3, 2/3, 1]))[row]
            cell_split = .45 if world == 'vendrell' and col == 0 else split
            bounds = (int(columns[col] * width), 0 if row == 0 else int(height * cell_split),
                      int(columns[col + 1] * width), int(height * cell_split) if row == 0 else height)
            piece = sheet.crop(bounds)
            box = piece.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
            if box is None:
                raise ValueError(f'Empty sprite: {world}/{name}')
            piece = piece.crop(box)
            padded = Image.new('RGBA', (piece.width + 4, piece.height + 4))
            padded.paste(piece, (2, 2))
            destination = ROOT / f'images/obstacles/prepared/{world}/{name}.png'
            destination.parent.mkdir(parents=True, exist_ok=True)
            padded.save(destination)
            print(f'{world}/{name}: {padded.size}')


if __name__ == '__main__':
    main()
