
import functools
import os

from PIL import ImageFont

try:
    import image_manip
except ImportError:
    import opengl.image_manip as image_manip

#gen fonts, cache fonts ?
current_dir = os.path.dirname(os.path.abspath(__file__))
default_font = ImageFont.truetype(os.path.join(current_dir, 'DejaVuSansMono-Bold.ttf'), size=80)


@functools.lru_cache()
def load_font(font_name, font_size):
    return ImageFont.truetype(os.path.join(current_dir, font_name), size=font_size)

@functools.lru_cache()
def render_text(text, font_name='DejaVuSansMono-Bold.ttf', font_size=60):
    "Renders a text with a given font. Returns a mask object."
    font = load_font(font_name, font_size)
    mask = font.getmask(text, mode='1')
    return (mask.size, bytes(mask))

def blit_mask(image, width, height, mask, x_offset, y_offset, color):
    """Sets an image color where the mask is non-zero

    image: bytearray (4 bytes per pixel)
    width, height: dimensions of the image in pixels
    mask: mask object
    x_offset, y_offset: upper-left corner position of the mask in the image
    color: pixel value to write in the image
    """
    (fw, fh), fm = mask
    image_manip.blit_image(image, width, height, fm, fw, fh, x_offset, y_offset, color)

