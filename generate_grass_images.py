#!/usr/bin/env python3
"""
Generate static grass images for the Leaves of Blocks iOS game.
Creates grass images for different screen sizes and densities.
"""

from PIL import Image, ImageDraw
import os
import random
import colorsys

# Grass colors matching the Swift implementation
GRASS_COLORS = [
    (38, 153, 13),   # Dark green
    (64, 179, 38),   # Medium green  
    (51, 166, 26),   # Forest green
    (77, 191, 51),   # Light green
    (46, 158, 20),   # Deep green
    (56, 173, 31),   # Pine green
    (71, 186, 46),   # Spring green
]

def seeded_random(col, block_index):
    """Deterministic random matching Swift implementation"""
    seed = col * 1000 + block_index * 100
    return ((seed * 9301 + 49297) % 233280) // 1000

def get_column_height(col):
    """Get deterministic column height matching Swift implementation"""
    seed = col * 7919
    random_val = ((seed * 9301 + 49297) % 233280) // 50000
    return min(4, max(2, random_val + 2))

def create_grass_image(width, height, scale=1):
    """Create a grass image with specified dimensions"""
    # Scale everything for retina displays
    actual_width = int(width * scale)
    actual_height = int(height * scale)
    
    # Create image with transparency
    img = Image.new('RGBA', (actual_width, actual_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    block_size = int(12 * scale)
    spacing = int(2 * scale)
    column_count = actual_width // (block_size + spacing)
    
    # Draw grass columns
    for col in range(column_count):
        x = col * (block_size + spacing)
        column_height = get_column_height(col)
        
        for block_index in range(column_height):
            y = actual_height - (block_index + 1) * (block_size + 1)
            
            # Get color
            color_index = seeded_random(col, block_index) % len(GRASS_COLORS)
            base_color = GRASS_COLORS[color_index]
            
            # Create gradient effect by varying brightness
            top_color = tuple(min(255, int(c * 1.2)) for c in base_color)
            bottom_color = tuple(int(c * 0.6) for c in base_color)
            
            # Draw grass block with simple gradient
            block_rect = [x, y, x + block_size, y + block_size]
            
            # Fill with gradient (simple top-to-bottom)
            for i in range(block_size):
                gradient_ratio = i / block_size
                current_color = tuple(
                    int(top_color[j] * (1 - gradient_ratio) + bottom_color[j] * gradient_ratio)
                    for j in range(3)
                )
                current_color = current_color + (255,)  # Add alpha
                
                line_y = y + i
                draw.line([(x, line_y), (x + block_size - 1, line_y)], fill=current_color)
            
            # Add border
            border_color = tuple(int(c * 0.4) for c in base_color) + (255,)
            draw.rectangle(block_rect, outline=border_color, width=1)
    
    return img

def create_ground_base(width, height, scale=1):
    """Create the ground base image"""
    actual_width = int(width * scale)
    actual_height = int(height * scale)
    
    img = Image.new('RGBA', (actual_width, actual_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create gradient from top to bottom
    top_color = (31, 115, 10)    # Matching Swift colors
    bottom_color = (26, 102, 8)
    
    for y in range(actual_height):
        gradient_ratio = y / actual_height
        current_color = tuple(
            int(top_color[i] * (1 - gradient_ratio) + bottom_color[i] * gradient_ratio)
            for i in range(3)
        )
        current_color = current_color + (255,)  # Add alpha
        draw.line([(0, y), (actual_width - 1, y)], fill=current_color)
    
    return img

def main():
    """Generate grass images for different device sizes"""
    
    # Device screen widths (in points)
    device_sizes = [
        ("iPhone-SE", 375),      # iPhone SE, 12 mini
        ("iPhone-Standard", 390), # iPhone 14, 15
        ("iPhone-Plus", 428),    # iPhone 14 Plus, 15 Plus  
        ("iPhone-Pro", 393),     # iPhone 14 Pro, 15 Pro
        ("iPhone-ProMax", 430),  # iPhone 14 Pro Max, 15 Pro Max
        ("Universal", 500),      # Universal fallback (wider than any device)
    ]
    
    # Grass and ground heights
    grass_height = 80
    ground_height = 20
    
    # Create output directory
    output_dir = "grass_assets"
    os.makedirs(output_dir, exist_ok=True)
    
    for device_name, width in device_sizes:
        print(f"Generating images for {device_name} (width: {width}px)...")
        
        # Generate grass images for different scales
        for scale_name, scale in [("1x", 1), ("2x", 2), ("3x", 3)]:
            # Grass image
            grass_img = create_grass_image(width, grass_height, scale)
            grass_filename = f"{output_dir}/grass-{device_name}@{scale_name}.png"
            grass_img.save(grass_filename, "PNG")
            
            # Ground base image
            ground_img = create_ground_base(width, ground_height, scale)
            ground_filename = f"{output_dir}/ground-{device_name}@{scale_name}.png"
            ground_img.save(ground_filename, "PNG")
            
            print(f"  Created {grass_filename} and {ground_filename}")
    
    print(f"\nAll grass images generated in '{output_dir}' directory!")
    print("\nNext steps:")
    print("1. Add these to your Xcode project's Assets.xcassets")
    print("2. Create image sets for 'grass-texture' and 'ground-texture'")
    print("3. Update BlockGrassView to use Image('grass-texture') and Image('ground-texture')")

if __name__ == "__main__":
    main()