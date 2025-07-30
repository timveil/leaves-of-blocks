#!/usr/bin/env python3
"""Create App Clip header image for Leaves of Blocks game."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# App Clip header dimensions
WIDTH = 1800
HEIGHT = 1200

# Autumn color palette (from your Colors.swift)
COLORS = {
    'background_primary': (25, 13, 5),
    'background_secondary': (51, 38, 26),
    'background_tertiary': (38, 26, 13),
    'accent_primary': (230, 179, 26),  # Golden amber
    'accent_secondary': (230, 128, 26),  # Burnt orange
    'accent_tertiary': (204, 102, 26),  # Deep orange
    'text_primary': (242, 230, 204),  # Cream
    'grid_background': (38, 26, 13),
    'grid_border': (102, 64, 26),
    'block_blue': (102, 153, 204),
    'block_green': (77, 153, 51),
    'block_red': (204, 51, 26),
    'block_yellow': (230, 179, 26),
    'block_purple': (128, 77, 102),
    'block_orange': (230, 128, 26),
}

def create_gradient_background(draw, width, height):
    """Create a vertical gradient background."""
    for y in range(height):
        # Interpolate between background colors
        ratio = y / height
        if ratio < 0.5:
            # Interpolate between primary and secondary
            t = ratio * 2
            r = int(COLORS['background_primary'][0] * (1-t) + COLORS['background_secondary'][0] * t)
            g = int(COLORS['background_primary'][1] * (1-t) + COLORS['background_secondary'][1] * t)
            b = int(COLORS['background_primary'][2] * (1-t) + COLORS['background_secondary'][2] * t)
        else:
            # Interpolate between secondary and tertiary
            t = (ratio - 0.5) * 2
            r = int(COLORS['background_secondary'][0] * (1-t) + COLORS['background_tertiary'][0] * t)
            g = int(COLORS['background_secondary'][1] * (1-t) + COLORS['background_tertiary'][1] * t)
            b = int(COLORS['background_secondary'][2] * (1-t) + COLORS['background_tertiary'][2] * t)
        
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))

def draw_rounded_rect(draw, coords, color, corner_radius=8):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = coords
    
    # Draw main rectangle
    draw.rectangle([x1, y1 + corner_radius, x2, y2 - corner_radius], fill=color)
    draw.rectangle([x1 + corner_radius, y1, x2 - corner_radius, y2], fill=color)
    
    # Draw corners
    draw.pieslice([x1, y1, x1 + 2*corner_radius, y1 + 2*corner_radius], 180, 270, fill=color)
    draw.pieslice([x2 - 2*corner_radius, y1, x2, y1 + 2*corner_radius], 270, 360, fill=color)
    draw.pieslice([x1, y2 - 2*corner_radius, x1 + 2*corner_radius, y2], 90, 180, fill=color)
    draw.pieslice([x2 - 2*corner_radius, y2 - 2*corner_radius, x2, y2], 0, 90, fill=color)

def draw_block(draw, x, y, size, color, shadow_offset=3):
    """Draw a game block with shadow."""
    # Draw shadow
    shadow_color = tuple(max(0, c - 40) for c in color)
    draw_rounded_rect(draw, (x + shadow_offset, y + shadow_offset, 
                            x + size + shadow_offset, y + size + shadow_offset), 
                     shadow_color, 6)
    
    # Draw main block
    draw_rounded_rect(draw, (x, y, x + size, y + size), color, 6)
    
    # Add highlight
    highlight_color = tuple(min(255, c + 30) for c in color)
    draw_rounded_rect(draw, (x + 2, y + 2, x + size - 2, y + size - 2), 
                     highlight_color, 4)

def main():
    # Create image
    img = Image.new('RGB', (WIDTH, HEIGHT), COLORS['background_primary'])
    draw = ImageDraw.Draw(img)
    
    # Create gradient background
    create_gradient_background(draw, WIDTH, HEIGHT)
    
    # Define grid parameters
    grid_size = 8
    cell_size = 50
    grid_width = grid_size * cell_size
    grid_height = grid_size * cell_size
    grid_x = (WIDTH - grid_width) // 2
    grid_y = (HEIGHT - grid_height) // 2
    
    # Draw grid background
    grid_padding = 20
    draw_rounded_rect(draw, (grid_x - grid_padding, grid_y - grid_padding,
                            grid_x + grid_width + grid_padding, 
                            grid_y + grid_height + grid_padding),
                     COLORS['grid_background'], 10)
    
    # Draw grid lines
    for i in range(grid_size + 1):
        # Vertical lines
        x = grid_x + i * cell_size
        draw.line([(x, grid_y), (x, grid_y + grid_height)], 
                 fill=COLORS['grid_border'], width=1)
        
        # Horizontal lines
        y = grid_y + i * cell_size
        draw.line([(grid_x, y), (grid_x + grid_width, y)], 
                 fill=COLORS['grid_border'], width=1)
    
    # Draw some placed blocks to show gameplay
    block_size = cell_size - 4
    block_offset = 2
    
    # L-shape in top-left (blue)
    positions = [(0, 0), (0, 1), (0, 2), (1, 2)]
    for row, col in positions:
        x = grid_x + col * cell_size + block_offset
        y = grid_y + row * cell_size + block_offset
        draw_block(draw, x, y, block_size, COLORS['block_blue'])
    
    # Completed horizontal line (mixed colors)
    colors = [COLORS['block_yellow'], COLORS['block_orange'], COLORS['block_red'],
              COLORS['block_green'], COLORS['block_purple'], COLORS['block_blue'],
              COLORS['block_yellow'], COLORS['block_orange']]
    
    for col, color in enumerate(colors):
        x = grid_x + col * cell_size + block_offset
        y = grid_y + 4 * cell_size + block_offset  # Row 4
        draw_block(draw, x, y, block_size, color)
    
    # T-shape in bottom-right (green)
    positions = [(6, 5), (7, 4), (7, 5), (7, 6)]
    for row, col in positions:
        x = grid_x + col * cell_size + block_offset
        y = grid_y + row * cell_size + block_offset
        draw_block(draw, x, y, block_size, COLORS['block_green'])
    
    # Square shape (purple)
    positions = [(1, 5), (1, 6), (2, 5), (2, 6)]
    for row, col in positions:
        x = grid_x + col * cell_size + block_offset
        y = grid_y + row * cell_size + block_offset
        draw_block(draw, x, y, block_size, COLORS['block_purple'])
    
    # Draw available blocks on the sides
    # Left side - single block
    side_block_size = 60
    draw_block(draw, 100, HEIGHT // 2 - 100, side_block_size, COLORS['block_red'])
    
    # Left side - L-shape
    l_positions = [(0, 0), (1, 0), (2, 0), (2, 1)]
    for row, col in l_positions:
        x = 100 + col * (side_block_size + 5)
        y = HEIGHT // 2 + 50 + row * (side_block_size + 5)
        draw_block(draw, x, y, side_block_size, COLORS['block_yellow'])
    
    # Right side - straight line
    for i in range(4):
        x = WIDTH - 160
        y = HEIGHT // 2 - 100 + i * (side_block_size + 5)
        draw_block(draw, x, y, side_block_size, COLORS['block_orange'])
    
    # Add decorative autumn leaves
    leaf_positions = [
        (200, 150, COLORS['accent_primary']),
        (300, 100, COLORS['accent_secondary']),
        (WIDTH - 200, 180, COLORS['accent_tertiary']),
        (150, HEIGHT - 200, COLORS['accent_secondary']),
        (WIDTH - 180, HEIGHT - 150, COLORS['accent_primary']),
    ]
    
    for x, y, color in leaf_positions:
        # Simple leaf shape using ellipses
        draw.ellipse([x-12, y-20, x+12, y+20], fill=color)
        draw.ellipse([x-8, y-15, x+8, y+15], fill=tuple(min(255, c + 20) for c in color))
    
    # Create tmp directory if it doesn't exist
    tmp_dir = 'tmp'
    if not os.path.exists(tmp_dir):
        os.makedirs(tmp_dir)
    
    # Save the image
    output_path = os.path.join(tmp_dir, 'app-clip-header.png')
    img.save(output_path, 'PNG', quality=95)
    print("App Clip header image created successfully!")
    print(f"Dimensions: {WIDTH}x{HEIGHT}")
    print(f"File: {output_path}")

if __name__ == '__main__':
    main()