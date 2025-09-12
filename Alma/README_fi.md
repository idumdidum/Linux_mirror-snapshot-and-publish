#### Alma peilipalvelimen asennus.
#### Voit käyttää viimeisintä LTS versiota (tätä kirjoittaessa versio 10).
#### Vakio asennus tavallisilla järjestelmätyökaluilla.
#### LVM käyttö suositeltavaa.
<br/>

#### Ennen Alma peilipalvelimen asennusta tutustutaan yleiseen Alma peili konfiguraatiotiedostoon 'global-rpm.gconf'. Tiedostopäätteen tulee olla .gconf ja niitä saa olla vain yksi.
#### Tiedosto sisältää mm. asetukset hakemistoille minne dataa tallennetaan. Muuten yleisen konfiguraatiotiedoston voi nimetä vapaasti. Myös mirror-and-snapshot scriptinkin voi nimetä vapaasti.


#### Esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/global-rpm.gconf:
#### #globaltype=rpm - varmistetaan, että käytetään oikean tyyppistä yleistä konfiguraatiotiedostoa (.gconf) mirror-and-snapthot.bash scriptin kanssa (optio -m rpm).
globaltype=rpm
#### #domain=alma.mirror.lan - domain johon tilannekuvat julkaistaan.
domain=alma.mirror.lan
#### #mainsitename=uptodate - muodostaa domainin kanssa FQDN, josta löytyy tuoreimmat päivitykset. Esim. http(s)://uptodate.alma.mirror.lan/.
mainsitename=uptodate
#### #allsnapshotssitename=allsnapshots - muodostaa domainin kanssa FQDN, josta löytyy kaikki tilannekuvat. Esim. http(s)://allsnapshots.alma.mirror.lan/.
allsnapshotssitename=allsnapshots
#### #usessl=no - käytetäänkö SSL kun tilannekuva julkaistaan. Vaihtoehdot 'no', 'yes' ja 'both'.
usessl=no
#### #mirrorconfdir, mirrordatadir, mirrortempdir, snapshotdir ja logdir. Näiden hekemistojen tulee olla omissa poluissaan. Näiden hakemistojen ei tule olla toistensa alempia tai ylempiä hakemistoja.
#### #mirrorconfdir=/etc/mirrorrpm - kansio, jossa säilytetään yleistä Alma peilin konfiguraatiotiedostoa, peilien konfiguraatiotiedostoja (.mconf), virtualhost templateja (käytetään tilannekuvien julkaisussa) ja mirror-and-snapshot.bash.
mirrorconfdir=/etc/mirrorrpm
#### #mirrordatadir=/srv/mirrordatarpm - kansio jonne peilien data kirjoitetaan. Tämä hakemisto vie eniten levytilaa (katso esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg).
mirrordatadir=/srv/mirrordatarpm
#### #mirrortempdir=/srv/mirrortemprpm - kansio väliaikaisille tiedostoille. Kansiossa säilytetään myös statusta peilien sha256 tarkistuksesta.
mirrortempdir=/srv/mirrortemprpm
#### #snapshotdir=/srv/mirrorsnapshotsrpm - kansio jonne peilien tilannekuvat tallennetaan.
snapshotdir=/srv/mirrorsnapshotsrpm
##### #logdir=/var/log/mirror - kansio jonne mirror-and-snapshot.bash kirjoittaa lokit
logdir=/var/log/mirror
#### #logname=${hdate}_${globaltype}_mirror.log - lokin nimi.
logname=${hdate}_${globaltype}_mirror.log
<br/><br/>
#### Tutustutaan myös peili konfiguraatiotiedostoon alma.mconf.tmpl.
#### Peili konfiguraatiotiedostoja voi olla useita. Tiedostopäätteen tulee olla .mconf ja hakemisto, jossa .mconf tiedostojen tulee sijaita määritellään Alma peilin yleisessä konfiguraatiotiedostossa ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm). Muuten peili konfiguraatiotiedostot voi nimetä vapaasti.

Peili konfiguraatio esimerkkejä:<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/almalinux.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/fedoralinux.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/postgresql-rpm.mconf.tmpl<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/rockylinux.mconf.tmpl

#### Esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/almalinux.mconf.tmpl:
#### #mirrortype=rpm - varmistetaan, että käytetään oikean tyyppistä peili konfiguraatio tiedostoa (.mconf) mirror-and-snapthot.bash scriptin kanssa.
mirrortype=rpm
#### #host=mirror.raiolanetworks.com - mistä päivitykset ladataan.
host=mirror.raiolanetworks.com
#### #arch="x86_64 aarch64" - ladattavat arkkitehtuurit.
arch="x86_64"
#### #versions="9 10" - ladattavat versiot.
versions="9 10"
#### #sections="os debug" - ladattavat sectiot.
sections="os"
#### #repos="AppStream BaseOS extras" - ladattavat repot.
repos="AppStream BaseOS extras"
#### #mirrorname=alma - peilin nimi. Jokaisella peilillä on oltava yksilöllinen nimi.
#### #mirrorname=pub/alma - peilin nimi voi olla suhteellinen polku hakemistoon.
mirrorname=alma
#### #rootdir=alma - mistä Alma arkisto alkaa etäisännällä (esim. mirror.eu.ossplanet.net/almalinux).
rootdir=almalinux
#### #downloadmethod=rsync - miten päivitykset ladataan. Vaihtoehdot 'rsync', 'http' tai 'https'.
downloadmethod=rsync
#### #enabled=yes - onko peilin päivitys käytössä. Vaihtoehdot 'yes' tai 'no'.
enabled=yes
#### #verifysha256=yes - tarkistetaanko päivitysten sha256. Vaihtoehdot 'no', 'yes' tai 'force'.
#### #Jos verifysha256=yes, niin ensimmäisellä peilin päivitys kerralla tarkistetaan kaikki kyseisen päivän päivitykset ja sen jälkeen vain ladatut päivitykset.
#### #Jos verifysha256=force, niin tarkitetaan aina kaikki kyseisen päivän päivitykset.
verifysha256=yes
#### #createsnapshot=yes - luodaanko tilannekuva. Vaihtoehdot 'yes' tai 'no'.
createsnapshot=yes
#### #monthlycleanupday=firstday - milloin poistetaan vanhentuneet päivitykset ja poistetaan kaikki tilannekuvat. Vaihtoehdot 'firstday', 'lastday', 'today', 'no' tai '1-31'.
monthlycleanupday=firstday
#### #trydownloadrpmgpgkeys=yes - yritetäänko ladata RPM-GPG-KEY-avaimet. RPM-GPG-KEY-avaimien tulee sijaita Alma arkiston juuressa. (esim. mirror.eu.ossplanet.net/almalinux). Vaihtoehdot 'no' tai 'yes'.
trydownloadrpmgpgkeys=yes
<br/>

#### Kun Alma peilipalvelin on asennettu, voit ladata peilipalvelimelle alma-configure-mirror.tar.<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Alma/alma-configure-mirror.tar.<br/>
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

Pura alma-configure-mirror.tar ja käytä configure-mirror.bash peilipalvelimen konfiguraatioon.<br/>
Peilipalvelimen konfiguraation on kaksi tai kolme vaiheinen riippuen halutaanko käyttää HTTP ja/tai HTTPS päivitysten julkaisuun.<br/><br/>
configure-mirror.bash optiot:
- -g [peilin yleinen konfiguraatiotiedosto] (pakollinen)
- -u [luotava tunnus] (pakollinen)
- -p (vain ensimmäisessä vaiheessa)
- -s no (jos käytetään HTTP)
- -s yes -c [polku certifikaattiin] -k [polku avaimeen] -n [polku certifikaatti ketjuun] (jos käytetään HTTPS)<br/>

HUOM -n ei ole pakollinen<br/>

Ensimmäinen vaihe:
- luo peilaukseen tarvittavan tunnuksen
- luo kansiot ja asettaa oikeudet kansioille
- kopio peilin yleisen konfiguraatiotiedoston luodun tunnuksen kotihakemistoon ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- asentaa ohjelmat<br/>

Esimerkki<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -p

Toinen vaihe:
- konfiguroi web palvelu käyttämään HTTP tai HTTPS
- kopio vhost.sslno tai vhost.sslyes luodun tunnuksen kotihakemistoon ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- kopio peili konfiguraatio templatet luodun tunnuksen kotihakemistoon ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- kopio mirror-and-snapshot.bash luodun tunnuksen kotihakemistoon ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- konfiguroi palomuurin, jos on (firewalld, ufw tai iptables)<br/>

Esimerkki (HTTP)<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -s no


Kolmas vaihe:
- konfiguroi web palvelu käyttämään HTTP tai HTTPS
- kopio vhost.sslno tai vhost.sslyes luodun tunnuksen kotihakemistoon ('global-rpm.gconf':mirrorconfdir=/etc/mirrorrpm)
- konfiguroi palomuurin, jos on (firewalld, ufw tai iptables)

Esimerkki (HTTPS)<br/>

./configure-mirror.bash -g global-rpm.gconf -u mirror -s yes -c /etc/ssl/private/apache-selfsigned.crt -k /etc/ssl/certs/apache-selfsigned.key

#### Nyt voit ottaa käyttöön luodun tunnuksen.
mirror-and-snapshot.bash optiot päivityksen yhteydessä:
- -g [yleinen peili konfiguraatiotiedosto] (Jos mirror-and-snapshot.bash ei ole samassa hamemistossa, kuin yleinen peili konfiguraatiotiedosto, niin käytä absoluuttista polkua. Pakollinen)
- -u all tai -u [peili konfiguraatiotiedoston nimi] (pakollinen)
- -m rpm (peilin tyyppi. pakollinen)
- -w (pidetään web palvelu ylhäällä, jos virheitä tapahtuu. Hyvä optio testatessa. Vapaaehtoinen)

mirror-and-snapshot.bash optiot poistaessa peiliä:
- -g [yleinen peili konfiguraatiotiedosto] (Jos mirror-and-snapshot.bash ei ole samassa hamemistossa, kuin yleinen peili konfiguraatiotiedosto, niin käytä absoluuttista polkua. Pakollinen)
- -d [peili konfiguraatiotiedoston nimi] (pakollinen)
- -m rpm (peilin tyyppi. pakollinen)

Tunnuksen kotihakemistossa on esimerkki peili konfiguraatiotiedostoja (*.mconf.tmpl).
Muuta esimerkiksi tiedoston alma.mconf.tmpl nimi -> alma.mconf ja muokkaa tarpeen mukaan.

Luodaan/päivitetään alma peili ja julkaistaan tilannekuva:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -u alma.mconf -m rpm

Jos halutaan päivittää kaikki 'enabled=yes' peilit:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -u all -m rpm

Jos jokin peili halutaan poistaa, niin käytetään optiota -d (tällöin enabled on oltava 'no'). Tämä poistaa alma peilin ja alma peilin tilannekuvat:

/etc/mirrorrpm/mirror-and-snapshot.bash -g /etc/mirrorrpm/global-rpm.gconf -d alma.mconf -m rpm



