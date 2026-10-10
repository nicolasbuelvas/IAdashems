from PIL import Image, ImageDraw
import random

# Generate a 128x128 jagged fracture/crack overlay
im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
random.seed(99)

# Draw jagged crack lines
def draw_jagged(start, end, depth=3):
    pts = [start]
    cur = start
    steps = 8
    for i in range(1, steps):
        t = i / float(steps)
        inter = (start[0] + (end[0] - start[0]) * t, start[1] + (end[1] - start[1]) * t)
        jitter = (inter[0] + random.uniform(-6, 6), inter[1] + random.uniform(-6, 6))
        pts.append(jitter)
    pts.append(end)
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i+1]], fill=(255, 60, 40, 240), width=3)
        draw.line([pts[i], pts[i+1]], fill=(255, 255, 255, 200), width=1)

draw_jagged((64, 10), (64, 118))
draw_jagged((64, 64), (10, 40))
draw_jagged((64, 64), (118, 50))
draw_jagged((64, 75), (25, 100))
draw_jagged((64, 75), (105, 95))

im.save("ui/holder_cracked.png")
print("Saved ui/holder_cracked.png")
