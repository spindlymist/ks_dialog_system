from PIL import Image

MAX_WIDTH = 200
COLOR = (255, 255, 255, 255)
TRANSPARENT = (COLOR[0], COLOR[1], COLOR[2], 0)

for width in range(MAX_WIDTH + 1):
    im = Image.new("RGBA", (MAX_WIDTH, 1), TRANSPARENT)
    for x in range(width):
        im.putpixel((x, 0), COLOR)
    im.save(f"Underline_{width}.png")
