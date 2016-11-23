#Requirements:

The next commands assume that the user has sudo privileges, the ip of the machine in which we are going to perform the classification command is `172.16.9.145` and there is an installation of docker in the system : https://www.docker.com/

Pull the images from docker hub:

```
$sudo docker pull madmex/postgres-server
$sudo docker pull madmex/ledaps-landsat8
$sudo docker pull madmex/python-fmask
$sudo docker pull madmex/antares
```

Create a directory `workshop` with the next line:

```
$ sudo mkdir /workshop
```

Enter to directory `workshop`

```
$cd /workshop
```

#Setting up the database


Using the command line of your system, run the next line:

```
$sudo docker run --hostname database --name postgres-server-madmex \
-v /workshop:/entry_for_database -p 32852:22 \
-p 32851:5432 -dt madmex/postgres-server
```

Get the ip of the docker container that is running:

```
$sudo docker inspect postgres-server-madmex|grep IPAddress\"
```

Assume that is ip is 172.17.0.2

Create user `madmex_user` with password `madmex_user.` using the next line:

```
$sudo docker exec -u=postgres -it postgres-server-madmex \
psql -h 172.17.0.2 -p 5432 \
-c "CREATE USER madmex_user WITH PASSWORD 'madmex_user.'"
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


Execute the following command:

```
$sudo docker run -p 2225:22 -v /workshop/configuration:/workshop/code_madmex_antares/madmex/configuration/ -v /workshop:/workshop --hostname=madmex-antares --name madmex_antares_container -dit madmex/antares /bin/bash
```

Enter to docker container `madmex_antares_container`

```
$sudo docker exec -it madmex_antares_container /bin/bash
```

Enter to directory `/workshop/code_madmex_antares`

```
#cd /workshop/code_madmex_antares
```

Install madmex:

```
#python setup.py install
```

Enter to directory `/workshop/`

```
#cd /workshop
```

Run the next script for creating the database:

```
#python /workshop/code_madmex_antares/madmex/persistence/database/populate.py
```


#Downloading landsat8 images


Create directory `downloads_landsat`:

```
#mkdir downloads_landsat
```

Enter to directory `downloads_landsat`

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

For converting to surface reflectances and getting top of atmoshpere products:

* Exit of madmex/antares:

```
#exit
```

* create the file `/workshop/ledaps_landsat8_shell.sh` and copy-paste the shell [ledaps_landsat8_shell.sh](ledaps_landsat8_shell.sh) on it.

* Create directory: `/workshop/auxiliary_data_landsat8/`, enter to `/workshop/auxiliary_data_landsat8` and curl the auxiliary data according to: https://github.com/USGS-EROS/espa-surface-reflectance/tree/master/not-validated-prototype-lasrc

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

```
#bash ledaps_landsat8_shell.sh /workshop/downloads_landsat/LC80130452013145LGN00.tar.bz /workshop/auxiliary_data_landsat8/ user1 password1 user2 password2 /workshop/downloads_landsat/
```

If the command was successful, we will ingest the folder to database. First we enter to docker container madmex/antares:

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

After ingestion of raw data or products, we have registered both in database and in folder /workshop/eodata the archives

##FMASK

For clouds, we use Fmask*

* Exit of madmex/antares:

```
#exit
```

* create the file `/workshop/fmask_landsat8_shell.sh` and copy-paste the shell [fmask_landsat8_shell.sh](fmask_landsat8_shell.sh) on it.


* In directory where fmask_landsat8_shell.sh is, run the following command as user root:

```
#bash fmask_landsat8_shell.sh /workshop/downloads_landsat/LC80130452013145LGN00.tar.bz /workshop/downloads_landsat/
```

If the command was successful, we will ingest the folder to database. First we enter to docker container madmex/antares:

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

Enter to docker container madmex/antares:

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


After ingestion of raw data we have registered both in database and in folder /workshop/eodata the archives

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















