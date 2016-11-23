
We have two approaches for classification of rapideye images:

* Simple

Which we are going to test.

* Regional and temporal

This approach uses images that have similar regional and temporal characteristics. We use an ESRI shapefile `mapgrid` to define several regions that consists of rapideye tiles sharing common regional properties. As each rapideye image in a different time has different reflectances for each phase of vegetation, we use a seasonality window defined by a date and a buffer of days. This buffer also depends on the amount of images that we have for the given date.

#Requirements

* The next commands assume that the user has sudo privileges

* We need to have an installation of docker in the system : https://www.docker.com/

Pull the images from docker hub:

```
$sudo docker pull madmex/antares
```

Create a directory `workshop` with the next line:

```
$ sudo mkdir /workshop
```

Change directory to directory `workshop`

```
$cd /workshop


Create directory `/workshop/configuration`

```
$sudo mkdir -p /workshop/configuration
```

Create `configuration.ini` in path: `/workshop/configuration/configuration.ini`, with an editor, for example using command `nano`:

```
$nano /workshop/configuration/configuration.ini
```

And copy-paste the next lines:


```
[madmex]
log_level = DEBUG
date_format = %%Y-%%m-%%d
rapideye_footprints_mexico_old = False
folder_segmentation = /workshop/segmentation/segmentation:/segmentation/
folder_segmentation_license = /workshop/segmentation/segmentation/license/license.txt:/segmentation/license.txt
training_data = /workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /workshop/classification/rapideye_simple_lcc/
```

We exit nano with `ctrl+x` and then type `y`in your keyboard to save changes.

Execute the following command:

```
$sudo docker run -p 2225:22 -v /workshop/configuration:/workshop/code_madmex_antares/madmex/configuration/ -v /workshop:/workshop --hostname=madmex-antares --name madmex_antares_container -dit madmex/antares /bin/bash
```

Enter to docker container `madmex_antares_container`

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Change directory `/workshop/code_madmex_antares`

```
#cd /workshop/code_madmex_antares
```

Install madmex:

```
#python setup.py install
```


##Classification

Exit madmex antares

Crete directory `/workshop/training_data`:

```
$mkdir -p /workshop/training_data
```

Copy training data to `/workshop/training_data`

```
$cp training_data.tif /workshop/training_data
```

Create directory `/workshop/segmentation`

```
$mkdir -p /workshop/segmentation
```

Change directory `/workshop/segmentation`

```
cd /workshop/segmentation
```

Clone https://github.com/CONABIO/docker-segmentation.git

```
git clone https://github.com/CONABIO/docker-segmentation.git .
```

Change directory `/workshop/segmentation/segmentation`

```
$cd /workshop/segmentation/segmentation
```


Create directory `/workshop/segmentation/license`

```
$mkdir -p /workshop/segmentation/license
```

Create archive `license.txt` in `/workshop/segmentation/segmentation/license`

For this workshop we can use the license: `67156997172`

```
echo 67156997172 > /workshop/segmentation/license/license.txt
```

Enter madmex antares

```
$sudo docker exec -it madmex_antares_container /bin/bash
```


Register host and command in tables of database giving the ip of the machine and the user root with it's password:

```
python /workshop/code_madmex_antares/madmex/bin/madmex remotecall --register host 172.16.9.145 madmex_run_container root root_password 22 workshop
```

```
python /workshop/code_madmex_antares/madmex/bin/madmex remotecall --register command workshop run_container workshop.q 
```

For rapideye classification

* Create directory for shapefile of landmask: `/workshop/landmask/countries_caribe`

```
#mkdir -p /workshop/landmask/countries_caribe
```

Copy archives of ESRI shapefile to: `/workshop/landmask/countries_caribe`

```
#cp countries_caribe.*  /workshop/landmask/countries_caribe
```

Create directories `/workshop/eodata/rapideye_images` and `/workshop/classification/rapideye_simple_lcc`

```
#mkdir -p /workshop/eodata/rapideye_images
#mkdir -p /workshop/classification/rapideye_simple_lcc
```

Copy rapideye images to directory:  `/workshop/eodata/rapideye_images`

```
#cp image.tif /workshop/eodata/rapideye_images
```


Change `configuration.ini` (if necessary) with lines:

```
training_data = /workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /workshop/classification/rapideye_simple_lcc/
```


If you changed `configuration.ini`, you need to install madmex again:

```
#cd /workshop/code_madmex_antares
#python setup.py install
```

Change directory /workshop/classification/rapideye_simple_lcc

```
#cd /workshop/classification/rapideye_simple_lcc
```


Run classification rapideye command:

```
python /workshop/code_madmex_antares/madmex/bin/madmex rapideyesimpleclassification --image /workshop/eodata/rapideye_images/1947604_2015-01-05_RE1_3A_298768.tif --landmask_path /workshop/landmask/countries_caribe/ --outlier True
```
