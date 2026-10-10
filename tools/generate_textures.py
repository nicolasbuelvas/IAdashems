import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter

os.makedirs("level/textures", exist_ok=True)
random.seed(42)

def make_concrete(path, size=512):
    # Base concrete: neutral slate gray with stippled aggregates
    img = Image.new("RGB", (size, size), (160, 164, 168))
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    
    # Perlin-like noise simulation
    for y in range(size):
        for x in range(size):
            # Base variation
            noise1 = math.sin(x * 0.05) * math.cos(y * 0.05) * 12
            noise2 = math.sin((x + y) * 0.08) * 8
            speckle = random.randint(-18, 18)
            val = int(162 + noise1 + noise2 + speckle)
            val = max(110, min(210, val))
            # subtle cool tint
            pixels[x, y] = (val - 4, val, val + 4)
            
    # Add subtle expansion seams/grooves every 256 pixels
    for x in range(0, size, 256):
        draw.line([(x, 0), (x, size)], fill=(115, 118, 122), width=2)
        draw.line([(x+1, 0), (x+1, size)], fill=(195, 200, 205), width=1)
    for y in range(0, size, 256):
        draw.line([(0, y), (size, y)], fill=(115, 118, 122), width=2)
        draw.line([(0, y+1), (size, y+1)], fill=(195, 200, 205), width=1)

    # Subtle blur to integrate grain
    img = img.filter(ImageFilter.GaussianBlur(radius=0.7))
    img.save(path)
    print(f"Generated {path}")

def make_brick(path, size=512):
    # Office subway/brick wall: warm tan/cream bricks with mortar
    img = Image.new("RGB", (size, size), (200, 195, 185)) # mortar base
    draw = ImageDraw.Draw(img)
    
    brick_w = 64
    brick_h = 32
    mortar = 4
    
    rows = size // brick_h
    cols = (size // brick_w) + 2
    
    for r in range(rows):
        y1 = r * brick_h + mortar // 2
        y2 = (r + 1) * brick_h - mortar // 2
        offset = (brick_w // 2) if (r % 2 == 1) else 0
        
        for c in range(-1, cols):
            x1 = c * brick_w + offset + mortar // 2
            x2 = (c + 1) * brick_w + offset - mortar // 2
            
            # Brick tone variation
            tone = random.randint(185, 215)
            r_val = tone + random.randint(5, 15)
            g_val = tone - random.randint(5, 10)
            b_val = tone - random.randint(15, 25)
            
            # Draw individual brick with subtle bevel
            draw.rectangle([x1, y1, x2, y2], fill=(r_val, g_val, b_val))
            draw.line([(x1, y1), (x2, y1)], fill=(min(255, r_val + 20), min(255, g_val + 20), min(255, b_val + 20)), width=1)
            draw.line([(x1, y2), (x2, y2)], fill=(max(0, r_val - 25), max(0, g_val - 25), max(0, b_val - 25)), width=1)

    # Add subtle texture noise over bricks
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            r, g, b = pixels[x, y]
            grain = random.randint(-10, 10)
            pixels[x, y] = (max(0, min(255, r + grain)), max(0, min(255, g + grain)), max(0, min(255, b + grain)))

    img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
    img.save(path)
    print(f"Generated {path}")

def make_drywall(path, size=512):
    # Office drywall panel with vertical seams
    img = Image.new("RGB", (size, size), (220, 218, 212))
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    
    for y in range(size):
        for x in range(size):
            noise = random.randint(-8, 8)
            val = 220 + noise
            pixels[x, y] = (val, val - 2, val - 6)
            
    # Vertical panel seam every 128 px
    for x in range(0, size, 128):
        draw.line([(x, 0), (x, size)], fill=(170, 168, 162), width=2)
        draw.line([(x+1, 0), (x+1, size)], fill=(240, 238, 232), width=1)
        
    img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
    img.save(path)
    print(f"Generated {path}")

def make_carpet(path, size=512):
    # Corporate carpet tile (charcoal/slate weave)
    img = Image.new("RGB", (size, size), (95, 98, 102))
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    
    for y in range(size):
        for x in range(size):
            # Weave cross pattern
            weave = 8 if ((x // 2 + y // 2) % 2 == 0) else -8
            noise = random.randint(-12, 12)
            val = max(50, min(150, 96 + weave + noise))
            pixels[x, y] = (val, val + 2, val + 4)
            
    # Tile seam every 128px
    for x in range(0, size, 128):
        draw.line([(x, 0), (x, size)], fill=(65, 68, 72), width=2)
    for y in range(0, size, 128):
        draw.line([(0, y), (size, y)], fill=(65, 68, 72), width=2)
        
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    img.save(path)
    print(f"Generated {path}")

make_concrete("level/textures/office_concrete_wall.png")
make_brick("level/textures/office_brick_wall.png")
make_drywall("level/textures/office_drywall_panel.png")
make_carpet("level/textures/office_carpet_floor.png")
