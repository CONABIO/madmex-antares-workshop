#!/bin/bash
#one: $1 is the path in the host for the tar file
#two: $2 is the path in the host for temporal folder
#three: $3 is the path in host running docker daemon for the temporal folder
MADMEX_TEMP=$3
name=$(basename $1)
newdir=$(echo $name | sed -n 's/\(L*.*\).tar.bz/\1/;p')
dir=$MADMEX_TEMP/$newdir
mkdir -p $dir
cp $1 $dir
cd $dir

tar xvf $name

ssh docker@172.17.0.1 docker run --rm -v $2/$newdir:/data madmex/python-fmask gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o ref.img $(ls $MADMEX_TEMP/$newdir|grep L[C-O]8.*_B[1-7,9].TIF)

ssh docker@172.17.0.1 docker run --rm -v $2/$newdir:/data madmex/python-fmask gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o thermal.img $(ls $MADMEX_TEMP/$newdir|grep L[C-O]8.*_B1[0,1].TIF)

ssh docker@172.17.0.1 docker run --rm -v $2/$newdir:/data madmex/python-fmask fmask_usgsLandsatSaturationMask.py -i ref.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -o saturationmask.img

ssh docker@172.17.0.1 docker run --rm -v $2/$newdir:/data madmex/python-fmask fmask_usgsLandsatTOA.py -i ref.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -o toa.img

ssh docker@172.17.0.1 docker run --rm -v $2/$newdir:/data madmex/python-fmask fmask_usgsLandsatStacked.py -t thermal.img -a toa.img -m $(ls $MADMEX_TEMP/$newdir|grep .*_MTL.txt) -s saturationmask.img -o cloud.img

cd $MADMEX_TEMP/$newdir && gdal_translate -of ENVI cloud.img $(echo $newdir)_MTLFmask
mkdir fmaskfolder

cp *_MTL.txt fmaskfolder

mv *_MTLFmask* fmaskfolder

mkdir raw_data

mv L*_B[1-9].TIF raw_data
mv L*_B1[0-1].TIF raw_data
mv L*_BQA.TIF raw_data
cp *_MTL.txt raw_data
