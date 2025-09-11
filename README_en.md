<br/><br/>
A regular local Linux mirror server works fine, but if you need to first update the test servers and then, after testing, possibly update the production servers with the same updates a few days later, it won't necessarily work.
Linux mirrors are updated daily, so it is not certain whether the same updates are available for production servers as for test servers.
To fix this problem I have written a bash script. 'mirror-and-snapshot.bash'.
The script works on Alma, Debian, Rocky and Ubuntu Linux.

'mirror-and-snapshot.bash' extends the functionality of a standard mirror server by enabling daily snapshots of desired mirrors, which are published to a unique web address.
<br/><br/>
![mirrordebian](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/common.jpg)
<br/><br/>

![all](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/linuxall.jpg)
<br/><br/>
debMirror
![mirrorskuva1](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/debmirror.jpg)
<br/><br/>
rpmMirror
![mirrorskuva2](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/rpmmirror.jpg)

Information about the disk space consumed by the environment described above is below.

![dukaikki](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg)


The environment described above is fine for testing purposes, but I would not recommend it as a production environment.

Instead, I recommend:

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/AlmaLinux

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Debian

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Rocky

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Ubuntu
<br/><br/>

Below is a table of what kind of host can be used to mirror and take a snapshot of any Linux repository.

| Host        | Mirrored archive   | Mirrored archive  | Mirrored archive  | Mirrored archive  | Mirrored archive  | Mirrored archive  | Mirrored archive  |
| :-------------: |:-------------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| Alma        | Alma   | Rocky  | Debian| Alma | Fedora | Mint | Kali |
| Debian      | Debian | Ubuntu | Rocky | Alma | Fedora | Mint | Kali |
| Fedora      | Alma (not tested)  | Rocky (not tested)  | Debian (not tested)| Alma (not tested) | Fedora (not tested) | Mint (not tested) | Kali (not tested) |
| Mint      | Alma (not tested)  | Rocky (not tested)  | Debian (not tested)| Alma (not tested) | Fedora (not tested) | Mint (not tested) | Kali (not tested) |
| Kali      | Alma (not tested)  | Rocky not tested)  | Debian (not tested)| Alma (not tested) | Fedora (not tested) | Mint (not tested) | Kali (not tested) |
| Rocky       | Rocky  | Alma   | Debian|Ubuntu| Fedora | Mint | Kali |
| Ubuntu      | Ubuntu | Debian | Rocky | Alma | Fedora | Mint | Kali |


