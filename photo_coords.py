# export csv with lat lon info from jpg image file exif
# arguments:
# sys.argv[1] = image directory
# sys.argv[2] = file extension - should be jpg or JPG to pull exif info
#
# example run:
# $ python photo_coords.py /home/btober/Documents/Malsaspina_gopro/ JPG
#
# author: Brandon S. Tober
# 22-September-2021

import sys,glob
from PIL import Image
from PIL.ExifTags import TAGS
from PIL.ExifTags import GPSTAGS
import csv

def get_exif(filename):
    image = Image.open(filename)
    image.verify()
    return image._getexif()

def get_labeled_exif(exif):
    labeled = {}
    for (key, val) in exif.items():
        labeled[TAGS.get(key)] = val

    return labeled


def get_geotagging(exif):
    if not exif:
        return

    geotagging = {}
    for (idx, tag) in TAGS.items():
        if tag == 'GPSInfo':
            if idx not in exif:
                return

            for (key, val) in GPSTAGS.items():
                if key in exif[idx]:
                    geotagging[val] = exif[idx][key]

    return geotagging

def get_decimal_from_dms(dms, ref):

    degrees = dms[0]
    minutes = dms[1] / 60.0
    seconds = dms[2] / 3600.0

    if ref in ['S', 'W']:
        degrees = -degrees
        minutes = -minutes
        seconds = -seconds

    return round(degrees + minutes + seconds, 5)

def get_coordinates(geotags):
    lat = get_decimal_from_dms(geotags['GPSLatitude'], geotags['GPSLatitudeRef'])

    lon = get_decimal_from_dms(geotags['GPSLongitude'], geotags['GPSLongitudeRef'])

    return (lat,lon)


if __name__ == '__main__':
    path = sys.argv[1]
    sfix = sys.argv[2]
    print("### photo_coords.py ###")
    print("-----------------------")
    print("Creating csv with photo coordinates for files in {:s}*.{:s}".format(path,sfix))
    with open(path + "photo_coords.csv","w") as f:
        writer=csv.writer(f, delimiter=",",lineterminator="\n",)
        writer.writerow(["lat","lon","file"])
        for file in glob.glob(path + "*." + sfix):
            print(file)
            out = "lat,lon,file"
            exif = get_exif(file)
            geotags = get_geotagging(exif)
            if geotags:
                coords = get_coordinates(geotags)
                row = coords[0],coords[1],file.split("/")[-1]
                writer.writerow(row)
    