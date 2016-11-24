#Landsat Classification

#Requirements:

* We need an installation of docker-machine in the system : https://docs.docker.com/machine/

* An installation of virtualbox in the system: https://www.virtualbox.org/

* Create a directory `/Users/workshop_user/workshop`

```
$mkdir -p /Users/workshop_user/workshop
```

* Change directory `/Users/workshop_user/workshop`

```
$cd /Users/workshop_user/workshop
```

* Create a machine called `workshop`

```
$docker-machine create -d virtualbox workshop
```

* Make sure that this machine has 4096 mb of ram, if not, stop it and give this amount of ram

* Get the ip of the machine:

```
$docker-machine ip workshop
```

Assume this ip is `192.168.99.100`

Pull the images from docker hub:

```
$docker $(docker-machine config workshop) pull madmex/postgres-server
$docker $(docker-machine config workshop) pull madmex/ledaps-landsat8
$docker $(docker-machine config workshop) pull madmex/python-fmask
$docker $(docker-machine config workshop) pull madmex/antares
$docker $(docker-machine config workshop) pull madmex/segmentation
$docker $(docker-machine config workshop) pull madmex/c5_execution
```

#Setting up the database


Using the command line of your system, run the next line:

```
$docker $(docker-machine config workshop) run --hostname database --name postgres-server-madmex \
-v /Users/workshop_user/workshop:/entry_for_database -p 32852:22 \
-p 32851:5432 -dt madmex/postgres-server
```


Create user `madmex_user` with password `madmex_user.` using the next line:

```
$docker $(docker-machine config workshop) exec -u=postgres -it postgres-server-madmex \
psql -h $(docker-machine ip workshop) -p 32851 \
-c "CREATE USER madmex_user WITH PASSWORD 'madmex_user.'"
```

Create database `madmex_database` with owner `madmex_user`

```
$docker $(docker-machine config workshop) exec -u=postgres -it postgres-server-madmex psql -h $(docker-machine ip workshop) -p 32851 -c "CREATE DATABASE madmex_database WITH OWNER = madmex_user ENCODING = 'UTF8' TABLESPACE = pg_default TEMPLATE = template0 CONNECTION LIMIT = -1;"
```

Install extension postgis in `madmex_database`

```
$docker $(docker-machine config workshop) exec -u=postgres -it postgres-server-madmex psql -h $(docker-machine ip workshop) -p 32851 -d madmex_database -c "CREATE EXTENSION postgis"
$docker $(docker-machine config workshop) exec -u=postgres -it postgres-server-madmex psql -h $(docker-machine ip workshop) -p 32851 -d madmex_database -c "CREATE EXTENSION postgis_topology"
```

Clone madmex code into directory: `/Users/workshop_user/workshop/code_madmex_antares`

```
$git clone https://github.com/CONABIO/madmex-antares.git code_madmex_antares
```

Create directory `/Users/workshop_user/workshop/configuration`:

```
$sudo mkdir -p /Users/workshop_user/workshop/configuration
```

Create `configuration.ini` in path: `/Users/workshop_user/workshop/configuration/configuration.ini`, with an editor, for example using command `nano`:

```
$nano /Users/workshop_user/workshop/configuration/configuration.ini
```

And copy-paste the next lines:

```
[madmex]
log_level = DEBUG
antares_database = postgresql://madmex_user:madmex_user.@192.168.99.100:32851/madmex_database
date_format = %%Y-%%m-%%d
rapideye_footprints_mexico_old = False
test_folder = /Users/workshop_user/workshop/eodata/
folder_segmentation = /Users/workshop_user/workshop/segmentation/segmentation:/segmentation/
folder_segmentation_license = /Users/workshop_user/workshop/segmentation/segmentation/license/license.txt:/segmentation/license.txt
training_data = /Users/workshop_user/workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /Users/workshop_user/workshop/classification/landsat8/
```

We exit nano with `ctrl+x` and then type `y`in your keyboard to save changes.

Execute the following command:

```
$docker $(docker-machine config workshop) run -p 2225:22 -v /Users/workshop_user/workshop/configuration/configuration.ini:/workshop/code_madmex_antares/madmex/configuration/configuration.ini -v /Users/workshop_user/workshop:/workshop --hostname=madmex-antares --name madmex_antares_container -dit madmex/antares /bin/bash
```

Enter to docker container `madmex_antares_container`

```
$docker $(docker-machine config workshop) exec -it madmex_antares_container /bin/bash
```

Change directory `/workshop/code_madmex_antares`

```
#cd /workshop/code_madmex_antares
```

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


#Downloading landsat8 images


Create directory `/workshop/downloads_landsat`:

```
#mkdir /workshop/downloads_landsat
```

Change directory `downloads_landsat`

```
#cd /workshop/downloads_landsat
```

Choose a path, row of landsat, for example: 13, 045 

Create a *.txt file listing all the available data for this path, row:

```
#gsutil ls gs://earthengine-public/landsat/L8/013/045 > landsat_data_tile_013_045.txt
```

Choose three files to download that begin with `LC8`, for example:

```
gs://earthengine-public/landsat/L8/013/045/LC80130452013145LGN00.tar.bz
gs://earthengine-public/landsat/L8/013/045/LC80130452013161LGN00.tar.bz
gs://earthengine-public/landsat/L8/013/045/LC80130452013177LGN01.tar.bz
```

Download three images and copy to directory`/workshop/downloads_landsat`:

```
#gsutil cp gs://earthengine-public/landsat/L8/013/045/LC80130452013145LGN00.tar.bz /workshop/downloads_landsat
#gsutil cp gs://earthengine-public/landsat/L8/013/045/LC80130452013161LGN00.tar.bz /workshop/downloads_landsat
#gsutil cp gs://earthengine-public/landsat/L8/013/045/LC80130452013177LGN01.tar.bz /workshop/downloads_landsat
```

#Preprocessing and ingestion

##LEDAPS

For converting to surface reflectances and getting top of atmoshpere products for landsat8 we use: 

https://github.com/USGS-EROS/espa-surface-reflectance/tree/master/not-validated-prototype-lasrc

We create a ssh-keygen with the following command. Hit enter, until the key has been generated

```
#ssh-keygen
```

We copy the key to user `docker` with ip `172.17.0.1`

```
ssh-copy-id -i /root/.ssh/id_rsa.pub docker@172.17.0.1
```

We type yes, and when asked for password we type `tcuser`

If everything went ok, then we can execute the following command, without being asked for password

```
ssh docker@172.17.0.1
```

We exit, and return to container `madmex_antares_container`

```
docker@workshop:~$ exit
```

* create the file `/workshop/ledaps_landsat8_shell.sh` and copy-paste the shell [ledaps_landsat8_shell.sh](ledaps_landsat8_shell.sh) on it.

* Create directory: `/workshop/auxiliary_data_landsat8/`, change directory to `/workshop/auxiliary_data_landsat8` and curl the auxiliary data according to: https://github.com/USGS-EROS/espa-surface-reflectance/tree/master/not-validated-prototype-lasrc

```
#mkdir -p /workshop/auxiliary_data_landsat8
#cd /workshop/auxiliary_data_landsat8
#curl -O http://edclpdsftp.cr.usgs.gov/downloads/auxiliaries/l8sr_auxiliary/l8sr_auxiliary.tar.gz
```

* Decompress the auxiliary data:

```
#tar xvzf l8sr_auxiliary.tar.gz
```

* In directory where ledaps_landsat8_shell.sh is, run the following command as user root:

(Install wget)

```
#apt-get install wget
```

```
#bash ledaps_landsat8_shell.sh /workshop/downloads_landsat/LC80130452013145LGN00.tar.bz /workshop/auxiliary_data_landsat8/ user1 password1 user2 password2 /Users/workshop_user/workshop/downloads_landsat/ /workshop/downloads_landsat
```

If the command was successful, we will ingest the folder to database. First we enter to docker container `madmex_antares_container

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Then, execute the following command for ingestion of products:


```
#python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00/srfolder
```

(This next line will not function, because ingestion of toafolder is not yet implemented)

```
#python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00/toafolder

```

The shell `ledaps_landsat8_shell.sh` creates the directory `raw_data`, so we can also ingest this folder:

```
#python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00/raw_data

```

After the ingestion of the surface reflectances, and top of atmosphere products, we can delete the folder:

```
#rm -r /workshop/downloads_landsat/LC80130452013145LGN00/
```

After ingestion of raw data or products, we have registered both in database and in folder `/workshop/eodata` the archives

##FMASK

For clouds, we use Fmask algorithm: 

www.sciencedirect.com/science/article/pii/S0034425714005069

* Exit of madmex/antares:

```
#exit
```

* create the file `/workshop/fmask_landsat8_shell.sh` and copy-paste the shell [fmask_landsat8_shell.sh](fmask_landsat8_shell.sh) on it.


* In directory where fmask_landsat8_shell.sh is, run the following command as user root:

```
#bash fmask_landsat8_shell.sh /workshop/downloads_landsat/LC80130452013145LGN00.tar.bz /Users/workshop_user/workshop/downloads_landsat/ /workshop/downloads_landsat
```

If the command was successful, we will ingest the folder to database. First we enter to docker container `madmex_antares_container`:

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Then, execute the following command for ingestion of products:


```
#python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00/fmaskfolder
```


The shell `fmask_landsat8_shell.sh` creates the directory `raw_data`, so we can also ingest this folder:

```
#python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00/raw_data

```

After the ingestion the fmask product, we can delete the folder:

```
#rm -r /workshop/downloads_landsat/LC80130452013145LGN00/
```

After ingestion of raw data or products, we have registered both in database and in folder /workshop/eodata the archives

##Ingest raw folder:

If we only want to register raw data of landsat execute the following command:

Enter to docker container `madmex_antares_container`:

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Create directory `/workshop/downloads_landsat/LC80130452013145LGN00`

```
#mkdir -p /workshop/downloads_landsat/LC80130452013145LGN00`
```

Copy the *.tar.bz file to `/workshop/downloads_landsat/LC80130452013145LGN00`

```
cp /workshop/downloads_landsat/LC80130452013145LGN00.tar.bz /workshop/downloads_landsat/LC80130452013145LGN00
```

Enter to `/workshop/downloads_landsat/LC80130452013145LGN00`

Untar:

```
#tar xvf LC80130452013145LGN00.tar.bz
```

Execute the ingestion command:

```
python /workshop/code_madmex_antares/madmex/bin/madmex ingest --path /workshop/downloads_landsat/LC80130452013145LGN00
```

After ingestion the raw data, we can delete the folder:

```
#rm -r /workshop/downloads_landsat/LC80130452013145LGN00/
```


After ingestion of raw data we have registered both in database and in folder `/workshop/eodata` the archives

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

For landsat classification:

* Create directory for shapefile of landmask: `/workshop/landmask/countries_caribe`

```
#mkdir -p /workshop/landmask/countries_caribe
```

Copy archives of ESRI shapefile to: `/workshop/landmask/countries_caribe`

```
#cp countries_caribe.*  /workshop/landmask/countries_caribe
```

Create directories `/workshop/classification/landsat8`

```
#mkdir -p /workshop/classification/landsat8
```

Change `configuration.ini` (if necessary) with lines:

```
training_data = /workshop/training_data/globalland_caribe_geo_proj.vrt
big_folder = /workshop/classification/landsat8/
```

Note: if you also have auxiliary files such as dem, aspect, slope, then create directory `/workshop/dem_files`

```
$mkdir -p /workshop/dem_files
```

and copy dem, aspect, slope files to `/workshop/dem_files`

```
#cp dem.tif /workshop/dem_files
#cp aspect.tif /workshop/dem_files
#cp slope.tif /workshop/dem_files
```

and modify `configuration.ini` with lines:

```
dem = /workshop/dem_files/dem.tif
aspect_file = /workshop/dem_files/aspect.tif
slope_file = /workshop/dem_files/slope.tif
```

If you changed `configuration.ini`, you need to install madmex again:

```
#cd /workshop/code_madmex_antares
#python setup.py install
```

Create directory `/workshop/classification/landsat8`

```
#mkdir -p /workshop/classification/landsat8
```

Change directory `/workshop/classification/landsat8`

```
#cd /workshop/classification/landsat8
```

Run classification landsat command for a tile, and use `True`or `False` depending on your purposes.

For example, our tile is `13045` of year `2013`, a maximum of 10 cloud percentage, we don't have auxiliary_files, we want an outlier elimination and we want that the algorithm fill holes because of clouds, then, the command will be:

```
python /workshop/code_madmex_antares/madmex/bin/madmex landsatclassification --start_date 2013-01-01 --end_date 2013-12-31 --satellite 17 --cloud_coverage 10 --gridid 13045 --landmask_path /workshop/landmask/countries_caribe/ --outlier True --fill_holes True --auxiliary_files False
```














