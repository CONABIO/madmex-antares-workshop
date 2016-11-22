
#Setting up the database

The next commands assume that the user has sudo privileges and in the system there is an installation of docker: https://www.docker.com/

Create a directory `workshop` with the next line:

```
$ sudo mkdir /workshop
```

Enter to directory `workshop`

```
$cd /workshop
```

Using the command line of your system, run the next line:

```
$sudo docker run --hostname database --name postgres-server-madmex \
-v $(pwd):/entry_for_database -p 32852:22 \
-p 32851:5432 -p 32850:22 -dt madmex/postgres-server
```

Enter to the docker container:

```
$sudo docker exec -it postgres-server-madmex /bin/bash 
```

Create user `madmex_user` :






