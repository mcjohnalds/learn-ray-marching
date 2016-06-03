#!/bin/bash
montage -border 15 -tile 2x5 -geometry 900x $(\ls raymarch*.png | sort -V) raymarch-anim.png
montage -border 15 -tile 2x5 -geometry 900x $(\ls terrainmarch*.png | sort -V) terrainmarch-anim.png
