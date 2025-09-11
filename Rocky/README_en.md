#### Rocky mirror server installation.
#### Can use the latest LTS version (at the time of writing, version 10).
#### Standard installation with standard system tools
#### LVM usage recommended.
<br/>

#### Before installing the Rocky mirror server, let's familiarize ourselves with the general Rocky mirror configuration file 'global-rpm.gconf'. The file extension must be .gconf and there can only be one of them.
#### The file contains, among other things, settings for directories where data is stored.


#### Example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/global-rpm.gconf:
#### #globaltype=rpm - ensuring that the correct type of global configuration file (.gconf) is used with the mirror-and-snapthot-rpm.bash (option -m rpm).
globaltype=rpm
#### #domain=rocky.mirror.lan - domain where updates and snapshots are published.
domain=rocky.mirror.lan
#### #mainsitename=uptodate - create an FQDN with the domain, where you can find the latest updates. Example http(s)://uptodate.rocky.mirror.lan/.
mainsitename=uptodate
#### #allsnapshotssitename=allsnapshots - creates an FQDN with the domain, where all snapshots can be found. Example http(s)://allsnapshots.rocky.mirror.lan/.
allsnapshotssitename=allsnapshots
#### #usessl=no - is SSL used when publishing a snapshot. Options 'no', 'yes' or 'both'.
usessl=no
#### mirrorconfdir, mirrordatadir, mirrortempdir, snapshotdir ja logdir. These directories should be on their own paths. These directories should not be subdirectories or superdirectories of each other.
#### mirrorconfdir=/etc/mirrorrpm - a directory that stores general Rocky mirror configuration file, mirror configuration files (.mconf), virtualhost templates (used for snapshot publishing), and mirror-and-snapshot.bash.
mirrorconfdir=/etc/mirrorrpm
#### #mirrordatadir=/srv/mirrordatarpm - directory where mirror data is written. This directory takes up the most disk space (see example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg).
mirrordatadir=/srv/mirrordatarpm
#### #mirrortempdir=/srv/mirrortemprpm - directory for temporary files. The directory also stores the status of the sha256 check of the mirrors.
mirrortempdir=/srv/mirrortemprpm
#### #snapshotdir=/srv/mirrorsnapshotsrpm - directory where mirror snapshots are stored.
snapshotdir=/srv/mirrorsnapshotsrpm
#### #logdir=/var/log/mirror - directory where mirror-and-snapshot.bash writes logs.
logdir=/var/log/mirror
#### #logname=${hdate}_${globaltype}_mirror.log - log name.
logname=${hdate}_${globaltype}_mirror.log
<br/><br/>
#### Let's take a look at the mirror configuration file rocky.mconf.tmpl.
#### There can be multiple mirror configuration files. The file extension must be .mconf and the directory where the .mconf files should be located is specified in the Rocky mirror's global configuration file ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm).

Mirror configuration examples:<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/almalinux.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/fedoralinux.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/postgresql-rpm.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/rockylinux.mconf.tmpl

#### Example https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/rocky.mconf:
#### #mirrortype=rpm - ensuring that the correct type of mirror configuration file (.mconf) is used with the mirror-and-snapthot.bash script.
mirrortype=rpm
#### #host=mirror.eu.ossplanet.net - where to download updates.
host=mirror.eu.ossplanet.net
#### #arch="x86_64 aarch64" - downloadable architectures.
arch="x86_64"
#### #versions="9 10" - downloadable versions.
versions="9 10"
#### #sections="os debug" - downloadable sections.
sections="os"
#### #mirrorname=rocky - mirror name. Each mirror must have a unique name.
#### #mirrorname=pub/rocky - the mirror name can be a relative path to a directory.
mirrorname=rocky
#### #rootdir=rocky - where does the Rocky archive start on the remote host (example ftp.rocky.org/rocky).
rootdir=rockylinux
#### #downloadmethod=rsync - how to download updates. Options 'rsync', 'http' or 'https'.
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
#### #trydownloadrpmgpgkeys=yes - are you trying to download RPM-GPG-KEYs?. The RPM-GPG-KEY keys should be located in the root of the Rocky repository (e.g. mirror.eu.ossplanet.net/rockylinux). Options 'no' or 'yes'.
trydownloadrpmgpgkeys=yes
<br/>

#### Once the Rocky mirror is installed, you can download rocky-configure-mirror.tar to rocky mirror.<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Rocky/rocky-configure-mirror.tar.<br/>
000-default-ssl.conf<br/>
000-default.conf<br/>
almalinux.mconf.tmpl<br/>
configure-mirror.bash<br/>
fedoralinux.mconf.tmpl<br/>
global-rpm.gconf<br/>
mirror-and-snapshot.bash<br/>
postgresql-rpm.mconf.tmpl<br/>
rockylinux.mconf.tmpl<br/>
vhost.sslno<br/>
vhost.sslyes

Extract rocky-configure-mirror.tar and use configure-mirror.bash to configure the mirror server.<br/>
The mirror server configuration is a two- or three-step process depending on whether you want to use HTTP and/or HTTPS to publish updates.<br/><br/>
configure-mirror.bash optios:
- -g [mirror global configuration file] (mandatory)
- -u [ID to be created] (mandatory)
- -p (only in the first stage)
- -s no (if HTTP is used)
- -s yes -c [path to certificate] -k [path to key] -n [path to certificate chain] (if HTTPS is usedS)<br/>

NOTE -n is not mandatory<br/>

First stage:
- create the account needed for mirroring
- create folders and set permissions for folders
- copy the mirror's general configuration file to the home directory of the created account ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- install programs<br/>

Example<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -p

Second stage:
- configure the web service to use HTTP or HTTPS
- copy vhost.sslno or vhost.sslyes to the home directory of the created account ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- copy mirror configuration templates to the home directory of the created account ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- copy mirror-and-snapshot.bash to the home directory of the created account ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- configure the firewall, if applicable (firewalld, ufw tai iptables)<br/>

Example (HTTP)<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -s no


Third stage:
- configure the web service to use HTTP or HTTPS
- copy vhost.sslno or vhost.sslyes to the home directory of the created account ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- configure the firewall, if applicable (firewalld, ufw tai iptables)

Example (HTTPS)<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -s yes -c /etc/ssl/private/apache-selfsigned.crt -k /etc/ssl/certs/apache-selfsigned.key

#### You can now activate the created account.
mirror-and-snapshot.bash options during mirror update:
- -g [global mirror configuration file] (If mirror-and-snapshot.bash is not in the same directory as the global mirror configuration file, use the absolute path. Mandatory)
- -u all or -u [mirror configuration file name] (mandatory)
- -m rpm (mirror type. mandatory)
- -w (keeps the web service up in case of errors. Good option for testing. Optional)

mirror-and-snapshot.bash options when removing a mirror:
- -g [global mirror configuration file] (If mirror-and-snapshot.bash is not in the same directory as the global mirror configuration file, use the absolute path. Mandatory)
- -d [mirror configuration file name] (mandatory)
- -m rpm (mirror type. mandatory)

There are example mirror configuration files (*.mconf.tmpl) in the account's home directory..
For example, change the name of the file rocky.mconf.tmpl to -> rocky.mconf and edit as needed.

Creating or updating a Rocky mirror and publishing a snapshot:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -u rocky.mconf -m rpm

If you want to update all 'enabled=yes' mirrors:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -u all -m rpm

If you want to remove a mirror, use the -d option (in this case enabled must be 'no'). This will remove the Rocky mirror and the Rocky mirror snapshots:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -d rocky.mconf -m rpm


