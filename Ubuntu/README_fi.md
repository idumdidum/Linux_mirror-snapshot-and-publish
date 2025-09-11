#### Ubuntu peilipalvelimen asennus.
#### Voit käyttää viimeisintä LTS versiota (tätä kirjoittaessa Noble Numbat).
#### Vakio asennus tavallisilla järjestelmätyökaluilla.
#### LVM käyttö suositeltavaa.
<br/>

#### Ennen Ubuntu peilipalvelimen asennusta tutustutaan yleiseen Ubuntu peili konfiguraatiotiedostoon 'global-deb.gconf'. Tiedostopäätteen tulee olla .gconf ja niitä saa olla vain yksi. Muuten yleisen konfiguraatiotiedoston voi nimetä vapaasti. Myös mirror-and-snapshot scriptin voi nimetä vapaasti.
#### Tiedosto sisältää mm. asetukset hakemistoille minne dataa tallennetaan. 


#### Esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Ubuntu/global-deb.gconf:
#### #globaltype=deb - varmistetaan, että käytetään oikean tyyppistä yleistä konfiguraatiotiedostoa (.gconf) mirror-and-snapthot.bash scriptin kanssa (optio -m deb).
globaltype=deb
#### #domain=ubuntu.mirror.lan - domain johon tilannekuvat julkaistaan.
domain=ubuntu.mirror.lan
#### #mainsitename=uptodate - muodostaa domainin kanssa FQDN, josta löytyy tuoreimmat päivitykset. Esim. http(s)://uptodate.ubuntu.mirror.lan/.
mainsitename=uptodate
#### #allsnapshotssitename=allsnapshots - muodostaa domainin kanssa FQDN, josta löytyy kaikki tilannekuvat. Esim. http(s)://allsnapshots.ubuntu.mirror.lan/.
allsnapshotssitename=allsnapshots
#### #usessl=no - käytetäänkö SSL kun tilannekuva julkaistaan. Vaihtoehdot 'no', 'yes' ja 'both'.
usessl=no
#### #mirrorconfdir, mirrordatadir, mirrortempdir, snapshotdir ja logdir. Näiden hekemistojen tulee olla omissa poluissaan. Näiden hakemistojen ei tule olla toistensa alempia tai ylempiä hakemistoja.
#### #mirrorconfdir=/etc/mirrordeb - kansio, jossa säilytetään peilien konfiguraatiotiedostoja (.mconf), virtualhost templateja (käytetään tilannekuvien julkaisussa) ja mirror-and-snapshot.bash. Hyvä paikka myös yleiselle Ubuntu peilin konfiguraatiotiedostolle.
mirrorconfdir=/etc/mirrordeb
#### #mirrordatadir=/srv/mirrordatadeb - kansio jonne peilien data kirjoitetaan. Tämä hakemisto vie eniten levytilaa (katso esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg).
mirrordatadir=/srv/mirrordatadeb
#### #mirrortempdir=/srv/mirrortempdeb - kansio väliaikaisille tiedostoille. Kansiossa säilytetään myös statusta peilien sha256 tarkistuksesta.
mirrortempdir=/srv/mirrortempdeb
#### #snapshotdir=/srv/mirrorsnapshotsdeb - kansio jonne peilien tilannekuvat tallennetaan.
snapshotdir=/srv/mirrorsnapshotsdeb
##### #logdir=/var/log/mirror - kansio jonne mirror-and-snapshot.bash kirjoittaa lokit
logdir=/var/log/mirror
#### #logname=${hdate}_${globaltype}_mirror.log - lokin nimi.
logname=${hdate}_${globaltype}_mirror.log
<br/><br/>
#### Tutustutaan myös peili konfiguraatiotiedostoon ubuntu.mconf.tmpl.
#### Peili konfiguraatiotiedostoja voi olla useita. Tiedostopäätteen tulee olla .mconf ja hakemisto, jossa .mconf tiedostojen tulee sijaita määritellään Ubuntu peilin yleisessä konfiguraatiotiedostossa ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb). Muuten peili konfiguraatiotiedostot voi nimetä vapaasti.

Peili konfiguraatio esimerkkejä:<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Ubuntu/ubuntu.mconf.tmpl
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Ubuntu/postgresql-deb.mconf.tmpl

#### Esimerkki https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Ubuntu/ubuntu.mconf.tmpl:
#### #mirrortype=deb - varmistetaan, että käytetään oikean tyyppistä peili konfiguraatio tiedostoa (.mconf) mirror-and-snapthot.bash scriptin kanssa.
mirrortype=deb
#### #host=ftp.ubuntu.com - mistä päivitykset ladataan.
host=ftp.ubuntu.com
#### #arch=amd64,i386 - ladattavat arkkitehtuurit.
arch=amd64
#### #dist=noble,noble-updates,noble-security,noble-backports - ladattavat versiot.
dist=noble,noble-updates,noble-security,noble-backports
#### #section=main,multiverse,universe,restricted - ladattavat sectiot.
section=main,multiverse,universe,restricted
#### #mirrorname=ubuntu - peilin nimi. Jokaisella peilillä on oltava yksilöllinen nimi.
#### #mirrorname=pub/ubuntu - peilin nimi voi olla suhteellinen polku hakemistoon.
mirrorname=ubuntu
#### #rootdir=ubuntu - mistä Ubuntu arkisto alkaa etäisännällä (esim. ftp.ubuntu.org/ubuntu).
rootdir=ubuntu
#### #debmirroroptions="--no-source --i18n" - lisäoptiot debmirror:lle. Älä yliaja optioita '-v, --nocleanup, -a, -s, -h, -d, -r, -e rsync tai --method=http'.
debmirroroptions="--no-source --i18n"
#### #downloadmethod=rsync - miten päivitykset ladataan. Vaihtoehdot 'rsync' tai 'http'.
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
<br/>

#### Kun Ubuntu peilipalvelin on asennettu, voit ladata peilipalvelimelle ubuntu-configure-mirror.tar.<br/>
https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/Ubuntu/ubuntu-configure-mirror.tar.<br/>
000-default-ssl.conf<br/>
000-default.conf<br/>
configure-mirror.bash<br/>
global-deb.gconf<br/>
mirror-and-snapshot.bash<br/>
postgresql-deb.mconf.tmpl<br/>
ubuntu.mconf.tmpl<br/>
vhost.sslno<br/>
vhost.sslyes

Pura ubuntu-configure-mirror.tar ja käytä configure-mirror.bash peilipalvelimen konfiguraatioon.<br/>
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
- kopio peilin yleisen konfiguraatiotiedoston luodun tunnuksen kotihakemistoon ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- luo trustedkeys.gpg keyringin
- asentaa ohjelmat<br/>

Esimerkki<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -p

Toinen vaihe:
- konfiguroi web palvelu käyttämään HTTP tai HTTPS
- kopio vhost.sslno tai vhost.sslyes luodun tunnuksen kotihakemistoon ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- kopio peili konfiguraatio templatet luodun tunnuksen kotihakemistoon ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- kopio mirror-and-snapshot.bash luodun tunnuksen kotihakemistoon ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- konfiguroi palomuurin, jos on (firewalld, ufw tai iptables)<br/>

Esimerkki (HTTP)<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -s no


Kolmas vaihe:
- konfiguroi web palvelu käyttämään HTTP tai HTTPS
- kopio vhost.sslno tai vhost.sslyes luodun tunnuksen kotihakemistoon ('global-deb.gconf':mirrorconfdir=/etc/mirrordeb)
- konfiguroi palomuurin, jos on (firewalld, ufw tai iptables)

Esimerkki (HTTPS)<br/>

./configure-mirror.bash -g global-deb.gconf -u mirror -s yes -c /etc/ssl/private/apache-selfsigned.crt -k /etc/ssl/certs/apache-selfsigned.key

#### Nyt voit ottaa käyttöön luodun tunnuksen.
mirror-and-snapshot.bash optiot päivityksen yhteydessä:
- -g [yleinen peili konfiguraatiotiedosto] (Jos mirror-and-snapshot.bash ei ole samassa hamemistossa, kuin yleinen peili konfiguraatiotiedosto, niin käytä absoluuttista polkua. Pakollinen)
- -u all tai -u [peili konfiguraatiotiedoston nimi] (pakollinen)
- -m deb (peilin tyyppi. pakollinen)
- -w (pidetään web palvelu ylhäällä, jos virheitä tapahtuu. Hyvä optio testatessa. Vapaaehtoinen)

mirror-and-snapshot.bash optiot poistaessa peiliä:
- -g [yleinen peili konfiguraatiotiedosto] (Jos mirror-and-snapshot.bash ei ole samassa hamemistossa, kuin yleinen peili konfiguraatiotiedosto, niin käytä absoluuttista polkua. Pakollinen)
- -d [peili konfiguraatiotiedoston nimi] (pakollinen)
- -m deb (peilin tyyppi. pakollinen)

Tunnuksen kotihakemistossa on esimerkki peili konfiguraatiotiedostoja (*.mconf.tmpl).
Muuta esimerkiksi tiedoston ubuntu.mconf.tmpl nimi -> ubuntu.mconf ja muokkaa tarpeen mukaan.

Luodaan/päivitetään ubuntu peili ja julkaistaan tilannekuva:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -u ubuntu.mconf -m deb

Jos halutaan päivittää kaikki 'enabled=yes' peilit:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -u all -m deb

Jos jokin peili halutaan poistaa, niin käytetään optiota -d (tällöin enabled on oltava 'no'). Tämä poistaa ubuntu peilin ja ubuntu peilin tilannekuvat:

/etc/mirrordeb/mirror-and-snapshot.bash -g /etc/mirrordeb/global-deb.gconf -d ubuntu.mconf -m deb


