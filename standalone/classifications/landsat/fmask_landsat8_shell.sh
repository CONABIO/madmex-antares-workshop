#!/bin/bash
#one: $1 is the path in the host for the tar file
#two: $2 is the path in the host for temporal folder
MADMEX_TEMP=$2
name=$(basename $1)
newdir=$(echo $name | sed -n 's/\(L*.*\).tar.bz/\1/;p')
dir=$MADMEX_TEMP/$newdir
mkdir -p $dir
cp $1 $dir
cd $dir

sudo docker run --rm -v $7/$newdir:/data madmex/python-fmask gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o ref.img $(ls $MADMEX_TEMP/$newdir|grep L[C-O]8.*_B[1-7,9].TIF)

sudo docker run --rm -v $7/$newdir:/data madmex/python-fmask gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o thermal.img $(ls $MADMEX_TEMP/$newdir|grep L[C-O]8.*_B1[0,1].TIF)

sudo docker run --rm -v $7/$newdir:/data madmex/python-fmask fmask_usgsLandsatSaturationMask.py -i ref.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -o saturationmask.img

sudo docker run --rm -v $7/$newdir:/data madmex/python-fmask fmask_usgsLandsatTOA.py -i ref.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -o toa.img

sudo docker run --rm -v $7/$newdir:/data madmex/python-fmask fmask_usgsLandsatStacked.py -t thermal.img -a toa.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -s saturationmask.img -o cloud.img

cd $MADMEX_TEMP/$newdir && gdal_translate -of ENVI cloud.img $(echo $newdir)_MTLFmask
