#!/bin/bash
 
# converts images for xcode using imagemagick

original=icon.png

sizes=(29 40 58 76 80 87 120 152 167 180)

for size in ${sizes[@]}; 
do
	convert $original -resize $sizex$size ../grades/Images.xcassets/AppIcon.appiconset/icon-$size.png
done