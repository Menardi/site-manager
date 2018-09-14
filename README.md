# Nginx Site Manager

A simple set of scripts to set up multiple websites on a server. Convenient for setting up simple sites for family and friends.

## Features
The scripts do the following:

 - Create all the necessary config for the nginx site
 - Provides SFTP login with chroot-jailed users (that is, they can only see their home directory, where files are served from)
 - Set up LetsEncrypt with only modern ciphers

## Usage
Clone this repository onto your server, and run the scripts. Make sure that `nginx` is installed. If you want to use LetsEncrypt, you will also need to install [Certbot](https://certbot.eff.org/).

All commands require root privileges.

### System config
To ensure the SFTP users do not have access to the rest of the system, you must follow these steps. First, create a new group called `sftponly`.

```
sudo groupadd sftponly
```

Then edit `/etc/ssh/sshd_config`. We will change its configuration to enforce SFTP login for these users.

Find this line:

```
Subsystem sftp /usr/lib/openssh/sftp-server
```

And change it to:

```
Subsystem sftp internal-sftp
```

At the end of the file, add:
```
Match Group sftponly
        ChrootDirectory /home/%u
        ForceCommand internal-sftp
        X11Forwarding no
        AllowTcpForwarding no
```

Save the file. Now, restart the ssh server to enable this config (this may kick you off the server):

```
sudo /etc/init.d/ssh restart
```

### tl;dr
In most cases, you will want do do this:

```
sudo ./addnewsite.sh domain.com username
sudo ./enablesite.sh domain.com
sudo ./addletsencrypt.sh domain.com
```

### Create a site

The script requires two arguments. The first is the domain of the site you will be hosting. The second is the username of the account which will be used to log in via SFTP.

```
sudo ./addnewsite.sh github.com github
```

Creating the site will set up all the configuration, but will not enable it. To do that, use the enable script.

### Enable a site

Once the config is all ready, you can enable it in nginx:

```
sudo ./enablesite.sh github.com
```

### Disable a site

```
sudo ./disablesite.sh github.com
```

### Adding LetsEncrypt

Ensure that `certbot` is installed, or this step won't work. Be aware that this will overwrite your nginx configuration, so if you have made manual changes, this script will lose them.

```
sudo ./addletsencrypt.sh github.com
```

When installed, `certbot` automatically sets up a cron job to renew certificates when necessary, so you do not need to worry about that.

## Todo

- Add a script to remove sites and their users
- Improved error handling
- Add option to enable / disable `www` domain