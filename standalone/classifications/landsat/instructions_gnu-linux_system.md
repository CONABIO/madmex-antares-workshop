# Minimum requirements

On the next list you can find the minimum hardware requirements that your system needs for using MADMEX on a standalone version. 

* `RAM` of at least 6 gb

* A `volume`, `disk`, or `hard disk` with at least 100 gb of free space

#System

We are going to assume an `ubuntu` gnu-linux system, please, do the appropiate changes of the name of the list of packages or commands if you are using a distribution different of `ubuntu`

## Packages

* openssh-server
* nano

To install a package, for example `openssh-server` execute:

```
$sudo apt-get install openssh-server
```

Once you have installed the above packages, here are some settings that you need to have:

## For the ssh:

```
$sudo service ssh restart
```

## For the user root:

* Give a password to the user root:

```
$sudo passwd
```
After executing this command, you need to type the password

* Authentication to root:

Using a text editor, for example nano, execute:

```
$sudo nano /etc/ssh/sshd_config
```

Use the up, down, left, right arrows on your keyboard so you can traverse the screen that appears after executing the above command.

Find the line under `#Authentication` that says `PermitRootLogin` and change to `Yes`:

```
#Authentication:
LoginGraceTime 120
PermitRootLogin Yes
StrictMode yes
```
Type `ctrl + x`, when asked if save the file, then type `y` and then hit `enter` to write the file

You need to restart the ssh service to update this changes:

```
$sudo service ssh restart
```


