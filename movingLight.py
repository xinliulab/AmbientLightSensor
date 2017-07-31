import imageio
imageio.plugins.ffmpeg.download()
import moviepy.editor as mpy

import numpy as np
import gizeh as gz


Width,Height,Length = 1920,1080,120
widthNumber = Width / Length
heightNumber = Height / Length
Duration = 1

def make_frame(t):
    surface = gz.Surface(Width,Height)
    center = []
    T = round(t*widthNumber*heightNumber/Duration)

    x = ( T%widthNumber )*Length + Length/2
    y = ( T//widthNumber )*Length + Length/2

    square = gz.square(l=Length, xy=[x,y], fill=(0, 0, 0))
    square.draw(surface)

    return surface.get_npimage()

clip = mpy.VideoClip(make_frame, duration=Duration)
clip.write_gif("background.gif", fps=widthNumber*heightNumber, opt="OptimizePlus")

