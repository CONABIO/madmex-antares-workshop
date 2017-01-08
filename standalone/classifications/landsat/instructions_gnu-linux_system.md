# Minimum requirements

On the next list you can find the minimum hardware requirements that your system needs for using MADMEX on a standalone version. 

* `RAM` of at least 6gb

* A `volume`, `disk`, or `hard disk` with at least 100 gb of free space

We are going to assume an `ubuntu` gnu-linux system, please, do the appropiate changes of the name of the next packages if you are using a distribution different of `ubuntu` 

* openssh-server

Once you have installed the above packages, here are some settings that you need to have:

## For the ssh:

```
$sudo service ssh restart
```

## For the user root:

* Give a password to the user root, for example, setting the password of root to `root_password`:

```
$sudo passwd
```
After executing this command, you need to type `root_password`

* Authentication to root change to yes on file /etc/ssh/sshd_config:

Using a text editor, for example nano, execute:

```
$sudo nano /etc/ssh/sshd_config
```

Using "&#8592", "&#8593", "&#8594", "&#8595" on your keyboarrd you can traverse the file.

Find the line under `#Authentication` that says `PermitRootLogin` and change to `Yes`:

```
#Authentication:
LoginGraceTime 120
PermitRootLogin Yes
StrictMode yes
```











