
import functools

from PIL import ImageFont

try:
    import image_manip
except ImportError:
    import opengl.image_manip as image_manip

#gen fonts, cache fonts ?
default_font = ImageFont.truetype('DejaVuSansMono-Bold.ttf', size=80)

@functools.lru_cache()
def render_text(text, font=default_font):
    "Renders a text with a given font. Returns a mask object."
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
