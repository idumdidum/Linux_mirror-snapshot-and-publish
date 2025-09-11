#### Debian mirror server installation.
#### Can use the latest LTS version (at the time of writing, trixie).
#### Standard installation with standard system tools
#### LVM usage recommended.
<br/>

#### Before installing the Debian mirror server, let's familiarize ourselves with the global Debian mirror configuration file 'global-deb.gconf'. The file extension must be .gconf and there can only be one of them.
#### The file contains, among other things, settings for directories where data is stored.


#### Example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/global-deb.gconf:
#### #globaltype=deb - ensuring that the correct type of global configuration file (.gconf) is used with the mirror-and-snapthot-deb.bash (option -m deb).
globaltype=deb
#### #domain=debian.mirror.lan - domain where updates and snapshots are published.
domain=debian.mirror.lan
#### #mainsitename=uptodate - create an FQDN with the domain, where you can find the latest updates. Example http(s)://uptodate.debian.mirror.lan/.
mainsitename=uptodate
#### #allsnapshotssitename=allsnapshots - creates an FQDN with the domain, where all snapshots can be found. Example http(s)://allsnapshots.debian.mirror.lan/.
allsnapshotssitename=allsnapshots
#### #usessl=no - is SSL used when publishing a snapshot. Options 'no', 'yes' or 'both'.
usessl=no
#### mirrorconfdir, mirrordatadir, mirrortempdir, snapshotdir ja logdir. These directories should be on their own paths. These directories should not be subdirectories or superdirectories of each other.
#### mirrorconfdir=/etc/mirrordeb - a directory that stores mirror configuration files (.mconf), virtualhost templates (used for snapshot publishing), and mirror-and-snapshot.bash. Also a good place for the general Debian mirror configuration file.
mirrorconfdir=/etc/mirrordeb
#### #mirrordatadir=/srv/mirrordatadeb - directory where mirror data is written. This directory takes up the most disk space (see example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg).
mirrordatadir=/srv/mirrordatadeb
#### #mirrortempdir=/srv/mirrortempdeb - directory for temporary files. The directory also stores the status of the sha256 check of the mirrors.
mirrortempdir=/srv/mirrortempdeb
#### #snapshotdir=/srv/mirrorsnapshotsdeb - directory where mirror snapshots are stored.
snapshotdir=/srv/mirrorsnapshotsdeb
#### #logdir=/var/log/mirror - directory where mirror-and-snapshot.bash writes logs.
logdir=/var/log/mirror
#### #logname=${hdate}_${globaltype}_mirror.log - log name.
logname=${hdate}_${globaltype}_mirror.log
<br/><br/>
#### Let's take a look at the mirror configuration file debian.mconf.tmpl.
#### There can be multiple mirror configuration files. The file extension must be .mconf and the directory where the .mconf files should be located is specified in the Debian mirror's global configuration file ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb).

Mirror configuration examples:<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/debian.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/debian-security.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/postgresql-deb.mconf.tmpl

#### Example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/debian.mconf.tmpl:
#### #mirrortype=deb - ensuring that the correct type of mirror configuration file (.mconf) is used with the mirror-and-snapthot.bash script.
mirrortype=deb
#### #host=ftp.debian.org - where to download updates.
host=ftp.debian.org
#### #arch=amd64,i386 - downloadable architectures.
arch=amd64
#### #dist=bookworm,bookworm-updates,bullseye,bullseye-updates - downloadable versions.
dist=bookworm,bookworm-updates
#### #section=main,contrib,non-free,non-free-firmware - downloadable sections.
section=main,contrib,non-free,non-free-firmware
#### #mirrorname=debian - mirror name. Each mirror must have a unique name.
#### #mirrorname=pub/debian - the mirror name can be a relative path to a directory.
mirrorname=debian
#### #rootdir=debian - where does the Debian archive start on the remote host (example ftp.debian.org/debian).
rootdir=debian
#### #debmirroroptions="--no-source --i18n" - additional options for debmirror. Don't overwrite options '-v, --nocleanup, -a, -s, -h, -d, -r, -e rsync or --method=http'.
debmirroroptions="--no-source --i18n"
#### #downloadmethod=rsync - how to download updates. Options 'rsync' or 'http'.
downloadmethod=rsync
#### #enabled=yes - is the mirror configuration enabled. Options 'yes' or 'no'.
enabled=yes
#### #verifysha256=yes - whether to check sha256 of updates. Options 'yes' or 'no'.
verifysha256=yes
#### #If verifysha256=yes, then the first time the mirror is updated, all updates for that day will be checked, and then only the downloaded updates will be checked.
#### #If verifysha256=force, then all updates for that day will always be checked.
#### #createsnapshot=yes - should a snapshot be created. Options 'yes' or 'no'.
createsnapshot=yes
#### #monthlycleanupday=firstday - when to clean up outdated updates and delete all snapshots. Options 'firstday', 'lastday', 'today', 'no' or '1-31'.
monthlycleanupday=firstday
<br/>

#### Once the Debian mirror is installed, you can download debian-configure-mirror.tar to debian mirror.<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Debian/debian-configure-mirror.tar.<br/>
000-default-ssl.conf<br/>
000-default.conf<br/>
configure-mirror.bash<br/>
debian-security.mconf.tmpl<br/>
debian.mconf.tmpl<br/>
global-deb.gconf<br/>
mirror-and-snapshot.bash<br/>
postgresql-deb.mconf.tmpl<br/>
vhost.sslno<br/>
vhost.sslyes

Extract debian-configure-mirror.tar and use configure-mirror.bash to configure the mirror server.<br/>
The mirror server configuration is a two- or three-step process depending on whether you want to use HTTP and/or HTTPS to publish updates.<br/><br/>
configure-mirror.bash optios:
- -g [mirror global configuration file] (mandatory)
- -u [ID to be created] (mandatory)
- -p (only in the first stage)
- -s no (if HTTP is used)
- -s yes -c [path to certificate] -k [path to key] -n [path to certificate chain] (if HTTPS is used)<br/>

NOTE -n is not mandatory<br/>

First stage:
- create the account needed for mirroring
- create folders and set permissions for folders
- copy the mirror's global configuration file to the home directory of the created account ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- create trustedkeys.gpg keyring
- install programs<br/>

Example<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -p

Second stage:
- configure the web service to use HTTP or HTTPS
- copy vhost.sslno or vhost.sslyes to the home directory of the created account ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- copy mirror configuration templates to the home directory of the created account ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- copy mirror-and-snapshot.bash to the home directory of the created account ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- configure the firewall, if applicable (firewalld, ufw tai iptables)<br/>

Example (HTTP)<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -s no


Third stage:
- configure the web service to use HTTP or HTTPS
- copy vhost.sslno or vhost.sslyes to the home directory of the created account ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- configure the firewall, if applicable (firewalld, ufw tai iptables)

Example (HTTPS)<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -s yes -c /etc/ssl/private/apache-selfsigned.crt -k /etc/ssl/certs/apache-selfsigned.key

#### You can now activate the created account.
mirror-and-snapshot.bash options during mirror update:
- -g [global mirror configuration file] (If mirror-and-snapshot.bash is not in the same directory as the global mirror configuration file, use the absolute path. Mandatory)
- -u all or -u [mirror configuration file name] (mandatory)
- -m deb (mirror type. mandatory)
- -w (keeps the web service up in case of errors. Good option for testing. Optional)

mirror-and-snapshot.bash options when removing a mirror:
- -g [global mirror configuration file] (If mirror-and-snapshot.bash is not in the same directory as the global mirror configuration file, use the absolute path. Mandatory)
- -d [mirror configuration file name] (mandatory)
- -m deb (mirror type. mandatory)

There are example mirror configuration files (*.mconf.tmpl) in the account's home directory..
For example, change the name of the file debian.mconf.tmpl to -> debian.mconf and edit as needed.

Creating or updating a Debian mirror and publishing a snapshot:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -u debian.mconf -m deb

If you want to update all 'enabled=yes' mirrors:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -u all -m deb

If you want to remove a mirror, use the -d option (in this case enabled must be 'no'). This will remove the Debian mirror and the Debian mirror snapshots:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -d debian.mconf -m deb

