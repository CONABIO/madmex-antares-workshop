Create directory `/workshop/configuration`


Create `configuration.ini` in the path: `/workshop/configuration/configuration.ini`


```
[madmex]
log_level = DEBUG
antares_database = postgresql://madmex_user:madmex_user.@172.17.0.2:5432/madmex_database
date_format = %%Y-%%m-%%d
rapideye_footprints_mexico_old = False
test_folder = /workshop/eodata/
folder_segmentation = /workshop/segmentation/segmentation:/segmentation/
folder_segmentation_license = /workshop/segmentation/segmentation/license/license.txt:/segmentation/license.txt
training_data = /workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /workshop/classification/rapideye_simple_lcc/
```


##Classification

Exit madmex antares

Crete directory /workshop/training_data

Copy training data to /workshop/training_data

Create directory /workshop/segmentation


Clone https://github.com/CONABIO/docker-segmentation.git into /workshop/segmentation

cd /workshop/segmentation

git clone https://github.com/CONABIO/docker-segmentation.git .

Enter /workshop/segmentation/segmentation

Create directory /workshop/segmentation/license

Put license.txt in /workshop/segmentation/segmentation/license

Construct image of segmentation: segmentation/segmentation:v1



Enter madmex antares and register host and command in tables of database, we have to give the ip of the machine and the user root with it's password:


python /workshop/code_madmex_antares/madmex/bin/madmex remotecall --register host 172.16.9.145 madmex_run_container_nodo3 user_root root_password 22 workshop

python /workshop/code_madmex_antares/madmex/bin/madmex remotecall --register command workshop run_container workshop.q





For rapideye classification
create directory /workshop/eodata/rapideye_images

copy images to this directory  /workshop/eodata/rapideye_images

create directory for shapefile of landmask: /workshop/landmask/countries_caribe

Copy shapefile to: /workshop/landmask/countries_caribe



Create directories /workshop/classification/rapideye_simple_lcc

Change configuration.ini:
big_folder = /workshop/classification/rapideye_simple_lcc/

Install madmex again

python setup.py install

Enter to directory /workshop/classification/rapideye_simple_lcc


Run classification rapideye command:

python /workshop/code_madmex_antares/madmex/bin/madmex rapideyesimpleclassification --image /workshop/eodata/rapideye_images/1947604_2015-01-05_RE1_3A_298768.tif --landmask_path /workshop/landmask/countries_caribe/ --outlier True

