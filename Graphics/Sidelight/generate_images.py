from PIL import Image

WIDTH = 4
COLOR = (255, 255, 255, 255)
LINE_HEIGHT = 13
MAX_LINES = 5
EXTRA_LINES = 1
MAX_HEIGHT = (MAX_LINES + EXTRA_LINES) * LINE_HEIGHT

im = Image.new("RGBA", (WIDTH, 1), (COLOR[0], COLOR[1], COLOR[2], 0))
im.save(f"Sidelight_0.png")

for height in range(1, MAX_HEIGHT + 1):
    im = Image.new("RGBA", (WIDTH, height), COLOR)
    im.save(f"Sidelight_{height}.png")
