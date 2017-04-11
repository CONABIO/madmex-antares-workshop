# Rapideye classification

We have two approaches for classification of rapideye images:

* Simple

Which we are going to test.


* Regional and temporal

This approach uses images that have similar regional and temporal characteristics. We use an ESRI shapefile `mapgrid` to define several regions that consists of rapideye tiles sharing common regional properties. As each rapideye image in a different time has different reflectances for each phase of vegetation, we use a seasonality window defined by a date and a buffer of days. This buffer also depends on the amount of images that we have for the given date.


We are going to assume an `ubuntu gnu-linux system`, please, do the appropiate changes if you are using a distribution different of `ubuntu`


# Requirements

* The ip of the machine in which we are going to perform the classification command is `172.16.9.145`.

* We need to have an installation of docker in the system : https://www.docker.com/

* The next commands assume that the user has sudo privileges or the user that is going to execute the following commands needs permissions to create, modify, read, write and install packages.

* An installation of git:

Using the command line of your system, run the next line:

```
$sudo apt-get install git
```

* We need the root's password. You can stablish it with the file `instructions_gnu-linux_system.md`. Go to the `README.md` of this repository under the levels: 

`madmex-antares-workshop/standalone/classifications/rapideye/instructions_gnu-linux_system.md`

for the minimum requirements that your system needs.

On the next commands, you can identify the commands executed inside a container and executed by the host, seeing the beginning of a command, which are highlighted with gray color ` `:

If the command begins with `#`, then is a command executed inside a container. If it begins with `$`, then is a command executed by the host 

Pull the next image from docker hub:

Using the command line of your system, run the next line:


```
$sudo docker pull madmex/postgres-server
$sudo docker pull madmex/antares
$sudo docker pull madmex/c5_execution
$sudo docker pull madmex/segmentation
```

Create a directory `workshop` with the next line:

```
$ sudo mkdir /workshop
```

Change directory to directory `workshop`

```
$cd /workshop
```

# Setting up the database


Using the command line of your system, run the next line:

```
$sudo docker run --hostname database --name postgres-server-madmex -v /workshop:/entry_for_database -p 32852:22 -p 32851:5432 -dt madmex/postgres-server
```

Get the ip of the docker container that is running:

```
$sudo docker inspect postgres-server-madmex|grep IPAddress\"
```

Assume that is ip is 172.17.0.2

Create user `madmex_user` with password `madmex_user.` using the next line:

```
$sudo docker exec -u=postgres -it postgres-server-madmex psql -h 172.17.0.2 -p 5432 -c "CREATE USER madmex_user WITH PASSWORD 'madmex_user.'"
```

Create database `madmex_database` with owner `madmex_user`

```
$sudo docker exec -u=postgres -it postgres-server-madmex psql -h 172.17.0.2 -p 5432 -c "CREATE DATABASE madmex_database WITH OWNER = madmex_user ENCODING = 'UTF8' TABLESPACE = pg_default TEMPLATE = template0 CONNECTION LIMIT = -1;"
```

Install extension postgis in `madmex_database`

```
$sudo docker exec -u=postgres -it postgres-server-madmex psql -h 172.17.0.2 -p 5432 -d madmex_database -c "CREATE EXTENSION postgis"
$sudo docker exec -u=postgres -it postgres-server-madmex psql -h 172.17.0.2 -p 5432 -d madmex_database -c "CREATE EXTENSION postgis_topology"
```

Clone madmex code into directory: `/workshop/code`

```
$sudo git clone https://github.com/CONABIO/madmex-antares.git code_madmex_antares
```
	
Execute the following command to start a container named: `madmex_antares_container`

```
$sudo docker run -p 2225:22 -v /workshop:/workshop --hostname=madmex-antares --name madmex_antares_container -dit madmex/antares /bin/bash
```

Enter to docker container `madmex_antares_container`

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Change directory `/workshop/code_madmex_antares`

```
#cd /workshop/code_madmex_antares
```

Modify `configuration.ini` using `sudo nano`:

```
#sudo nano /workshop/code_madmex_antares/madmex/configuration/configuration.ini

```

And copy-paste the next lines:


```
[madmex]
log_level = DEBUG
antares_database = postgresql://madmex_user:madmex_user.@172.17.0.2:5432/madmex_database
date_format = %%Y-%%m-%%d
rapideye_footprints_mexico_old = False
folder_segmentation = /workshop/segmentation/segmentation:/segmentation/
folder_segmentation_license = /workshop/segmentation/segmentation/license/license.txt:/segmentation/license.txt
training_data = /workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /workshop/classification/rapideye_simple_lcc/
big_folder_host = /workshop/classification/rapideye_simple_lcc/:/results
landmask_path =/workshop/landmask/countries_caribe/
```

We exit nano with `ctrl+x` and then type `y`in your keyboard to save changes.



Install madmex:

```
#python setup.py install
```

Change directory `/workshop/`

```
#cd /workshop
```

Run the next script for creating the database:

```
#python /workshop/code_madmex_antares/madmex/persistence/database/populate.py
```
With dbvisualizer, for example, we can have a picture of the database:

![Database_madmex_antares.png](database_madmex_antares_image/Database_madmex_antares.png)

Dbvisualizer: https://www.dbvis.com/download/

## Classification

Create directory `/workshop/training_data`:

```
#mkdir -p /workshop/training_data
```

Copy training data to `/workshop/training_data`

```
$cp training_data.tif /workshop/training_data
```

Create directory `/workshop/segmentation`

```
#mkdir -p /workshop/segmentation
```

Change directory `/workshop/segmentation`

```
#cd /workshop/segmentation
```

Clone https://github.com/CONABIO/docker-segmentation.git

```
#git clone https://github.com/CONABIO/docker-segmentation.git .
```

Change directory `/workshop/segmentation/segmentation`

```
#cd /workshop/segmentation/segmentation
```


Create directory `/workshop/segmentation/segmentation/license`

```
#mkdir -p /workshop/segmentation/segmentation/license
```

Create archive `license.txt` in `/workshop/segmentation/segmentation/license`

For this workshop we can use the license: `67156997172`

```
#echo 67156997172 > /workshop/segmentation/segmentation/license/license.txt
```


Register host and command in tables of database giving the ip of the machine and the user root with it's password:

```
#madmex remotecall --register host 172.16.9.145 madmex_run_container root root_password 22 workshop
```

```
#madmex remotecall --register command workshop run_container workshop.q 
```

For rapideye classification

* Create directory for shapefile of landmask: `/workshop/landmask/countries_caribe`

```
#mkdir -p /workshop/landmask/countries_caribe
```

Copy archives of ESRI shapefile to: `/workshop/landmask/countries_caribe`

```
$cp countries_caribe.*  /workshop/landmask/countries_caribe
```

Create directories `/workshop/eodata/rapideye_images` and `/workshop/classification/rapideye_simple_lcc`

```
#mkdir -p /workshop/eodata/rapideye_images
#mkdir -p /workshop/classification/rapideye_simple_lcc
```

Copy rapideye images to directory:  `/workshop/eodata/rapideye_images`

```
$cp image.tif /workshop/eodata/rapideye_images
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

The image that we are going to classify is from Dominican Republic: 1947604_2015-01-05_RE1_3A_298768.tif


![rep_dominicana_imagen_original.png](result_images/rep_dominicana_imagen_original.png)

The training data for this classification was generated by National Geomatics Center of China: GlobeLand30-2010 (Chen et al. 2015, resolution: 30m) 


![rep_dominicana_training_data.png](result_images/rep_dominicana_training_data.png)

<img src="result_images/legend_globalland30m.png" width="30%">


Reference: http://glc30.tianditu.com/

(Now is down this web page. For an "explanation:" http://gis.stackexchange.com/questions/210953/glc30-globeland30-disapearance)


Run classification rapideye command:

```
#madmex rapideyesimpleclassification --image /workshop/eodata/rapideye_images/1947604_2015-01-05_RE1_3A_298768.tif --outlier True
```

![rep_dominicana.png](result_images/rep_dominicana.png)



Another example for Jamaica.

 Original image: 1847306_2014-10-06_RE5_3A_275562.tif

![jamaica_imagen_original.png](result_images/jamaica_imagen_original.png)

```
#madmex rapideyesimpleclassification --image /workshop/eodata/rapideye_images/jamaica/1847306_2014-10-06_RE5_3A_275562.tif --outlier True
```
Training data from globeland30

![jamaica_training_data.png](result_images/jamaica_training_data.png)

<img src="result_images/legend_globalland30m.png" width="30%">

Result of classification:
![jamaica_globeland30.png](result_images/jamaica_globeland30.png)

Training data from ESA2010: (Ecological Society of America, 250m resolution)

![jamaica_training_data_esa2010.png](result_images/jamaica_training_data_esa2010.png)

<img src="result_images/legend_ESA.png" width="60%">

Result of classification:

![jamaica_esa2010.png](result_images/jamaica_esa2010.png)





