#!/bin/bash
#one: $1 is the path in the host for the tar file
#two: $2 is the path in the host for ancillary data
#three,four: $3, $4 is the username and password for the http://e4ftl01.cr.usgs.gov server
#five, six: $5, $6 is the username and password for the ladssci.nascom.nasa.gov server
#seven : $7 is the path in the host for the temporal folder
#eigth: $8 is the path in host running docker daemon for the temporal folder
MADMEX_TEMP=$8
name=$(basename $1)
newdir=$(echo $name | sed -n 's/\(L*.*\).tar.bz/\1/;p')
dir=$MADMEX_TEMP/$newdir
mkdir -p $dir
cp $1 $dir
cd $dir

#Prepraring files for LEDAPS:
year=$(echo $name|sed -nE 's/L[A-Z]?[5-8][0-9]{3}[0-9]{3}([0-9]{4}).*.tar.bz/\1/p')
day_of_year=$(echo $name|sed -nE 's/L[A-Z]?[5-8][0-9]{3}[0-9]{3}[0-9]{4}([0-9]{1,3}).*.tar.bz/\1/p')
year_month_day=$(date -d "$year-01-01 +$day_of_year days -1 day" "+%Y.%m.%d")
if [ ! -e $2/LADS/$year/L8ANC$year$day_of_year.hdf_fused ];
then
  #download cmg products
  echo "download cmg products" >> $dir/log.txt
  root=http://e4ftl01.cr.usgs.gov
  mod09=MOLT/MOD09CMG.006
  myd09=MOLA/MYD09CMG.006
  #date_acquired=$(cat $metadata|grep 'DATE_ACQUIRED'|cut -d'=' -f2|sed -n -e "s/-/./g" -e "s/ //p")
  date_acquired=$year_month_day
  echo $date_acquired >> $dir/log.txt
  echo "$root/$mod09/$date_acquired" >> $dir/log.txt
  if [ $(wget -L --user=$3 --password=$4 -qO - $root/$mod09/$date_acquired/|grep "MOD.*.hdf\""|wc -l) -gt 1 ]; then echo "Too many files for MOD09CMG"; else
    wget -L --user=$3 --password=$4 -P $dir -A hdf,xml,jpg -nd -r -l1 --no-parent "$root/$mod09/$date_acquired/"
  fi
  if [ $(wget -L --user=$3 --password=$4 -qO - $root/$myd09/$date_acquired/|grep "MYD.*.hdf\""|wc -l) -gt 1 ]; then echo "Too many files for MYD09CMG"; else
    wget -L --user=$3 --password=$4 -P $dir -A hdf,xml,jpg -nd -r -l1 --no-parent "$root/$myd09/$date_acquired/"
  fi
  #download cma products
  echo "download cma products" >> $dir/log.txt
  root=ftp://$5:$6@ladssci.nascom.nasa.gov
  mod09cma=6/MOD09CMA
  myd09cma=6/MYD09CMA
  if [ $(wget -qO - $root/$mod09cma/$year/$day_of_year/|grep "MOD09CMA.*.hdf\""|wc -l) -gt 1 ]; then echo "Too many files for MOD09CMA"; else
    wget -A hdf -P $dir -nd -r -l1 --no-parent "$root/$mod09cma/$year/$day_of_year/"
  fi
  if [ $(wget -qO - $root/$mod09cma/$year/$day_of_year/|grep "MOD09CMA.*.hdf\""|wc -l) -gt 1 ]; then echo "Too many files for MYD09CMA"; else
    wget -A hdf -P $dir -nd -r -l1 --no-parent "$root/$myd09cma/$year/$day_of_year/"
  fi
  #combine aux data
  terra_cmg=$(ls .|grep MOD09CMG.*.hdf$)
  echo $terra_cmg >> $dir/log.txt
  terra_cma=$(ls .|grep MOD09CMA.*.hdf$)
  echo $terra_cma >> $dir/log.txt
  aqua_cma=$(ls .|grep MYD09CMA.*.hdf$)
  aqua_cmg=$(ls .|grep MYD09CMG.*.hdf$)
  echo $aqua_cma >> $dir/log.txt
  echo $aqua_cmg >> $dir/log.txt
  ssh docker@172.17.0.1 docker run --rm -v $7/$newdir:/data -w=/data -e terra_cmg=$terra_cmg -e terra_cma=$terra_cma -e aqua_cma=$aqua_cma -e aqua_cmg=$aqua_cmg madmex/ledaps-landsat8  /usr/local/espa-tools/bin/combine_l8_aux_data --terra_cmg=$terra_cmg --terra_cma=$terra_cma --aqua_cmg=$aqua_cmg --aqua_cma=$aqua_cma --output_dir=/data
  #copy the combine aux data for future processes
  anc=$(ls .|grep ANC)
  mkdir -p $2/LADS/$year
  cp $anc $2/LADS/$year
  #move the combine aux data
  mkdir -p LADS/$year
  mv $anc LADS/$year
  #else
else
  echo "found fused file, not downloading" >> $dir/log.txt
  mkdir -p LADS/$year
  anc=$(ls $2/LADS/$year|grep ".*$year$day_of_year")
  cp $2/LADS/$year/$anc LADS/$year/
fi

#surface reflectances:
echo "Beginning untar"
#untar file
tar xvf $name
echo "finish untar"
metadata=$(ls .|grep -E ^L[A-Z]?[5-8][0-9]{3}[0-9]{3}.*_MTL.txt)
metadataxml=$(echo $metadata|sed -nE 's/(L.*).txt/\1.xml/p')
echo $metadata >> $dir/log.txt
echo $metadataxml >> $dir/log.txt
echo "finish identification of metadata"
ssh docker@172.17.0.1 docker run --rm -v $7/$newdir:/data -w=/data -e metadata=$metadata -e metadataxml=$metadataxml madmex/ledaps-landsat8 /usr/local/espa-tools/bin/convert_lpgs_to_espa --mtl=$metadata --xml=$metadataxml
#check if the next line is important for the analysis
#line: $BIN/create_land_water_mask --xml=$metadataxml
cp -r $2/LDCMLUT .
cp $2/ratiomapndwiexp.hdf .
cp $2/CMGDEM.hdf .
echo "Surface reflectance process" >> $dir/log.txt
ssh docker@172.17.0.1 docker run --rm -v $7/$newdir:/data -w=/data -e LEDAPS_AUX_DIR=/data -e anc=$anc -e metadataxml=$metadataxml madmex/ledaps-landsat8 /usr/local/espa-tools/bin/lasrc --xml=$metadataxml --aux=$anc --verbose --write_toa
ssh docker@172.17.0.1 docker run --rm -v $7/$newdir:/data -w=/data -e newdir=$newdir -e metadataxml=$metadataxml madmex/ledaps-landsat8 /usr/local/espa-tools/bin/convert_espa_to_hdf --xml=$metadataxml --hdf=lndsr.$(echo $newdir).hdf --del_src_files
echo "finish surface reflectance" >> $dir/log.txt
mv lndsr.$(echo $newdir)_MTL.txt lndsr.$(echo $newdir)_metadata.txt
#mv lndcal.$(echo $newdir)_MTL.txt lndcal.$(echo $newdir)_metadata.txt
cp lndsr.$(echo $newdir).hdf lndcal.$(echo $newdir).hdf
cp lndsr.$(echo $newdir)_hdf.xml lndcal.$(echo $newdir)_hdf.xml

mkdir raw_data

mv L*_B[1-9].TIF raw_data
mv L*_B1[0-1].TIF raw_data
mv L*_BQA.TIF raw_data
cp *_MTL.txt raw_data

raw_data_number=$(ls raw_data|wc -l)

mkdir srfolder

mv lndsr.*hdf* srfolder/
cp *_MTL.txt srfolder
mv L*_sr_* srfolder/

ledaps_sr_number=$(ls srfolder|wc -l)

mkdir toafolder

mv lndcal.*hdf* toafolder/
cp *_MTL.txt toafolder
mv L*_toa_* toafolder/

ledaps_toa_number=$(ls toafolder|wc -l)

