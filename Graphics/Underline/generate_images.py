from PIL import Image
from numpy import asfortranarray
from bezier import Curve

nodes = asfortranarray([
    [0.0, 0.5, 1.0],
    [0.0, 1.0, 1.0],
])
curve = Curve(nodes, degree=2)

WIDTH = 200 - 60
COLOR = (255, 255, 255, 255)
TRANSPARENT = (COLOR[0], COLOR[1], COLOR[2], 0)
ITERATIONS = 20

for i in range(1, ITERATIONS + 1):
    t = i / ITERATIONS
    bar_width = round(curve.evaluate(t)[1][0] * WIDTH)

    im = Image.new("RGBA", (WIDTH, 1), TRANSPARENT)
    for x in range(bar_width):
        im.putpixel((x, 0), COLOR)
    im.save(f"Underline_{i-1}.png")
