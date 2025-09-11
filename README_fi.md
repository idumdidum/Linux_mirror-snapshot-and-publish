<br/><br/>
Tavallinen paikallinen Linux peilipalvelin toimii hyvin, mutta jos on tarve ensin päivittää testipalvelimet ja testauksen jälkeen mahdollisesti päiviä myöhemmin päivittää tuotatopalvelimet samoilla päivityksillä, niin se ei vättämattä onnistu.
Linux peilejä päivitetään päivittäin, joten ei voida olla varmoja onko tuotantopalvelimiin enää saatavilla samoja päivityksia, kuin testipalvelimiin.
Tämän ongelman korjaamiseksi olen kirjoittanut bash scriptin.
Alma, Debian, Rocky ja Ubuntu Linuxille 'mirror-and-snapshot.bash'.

'mirror-and-snapshot.bash' laajentaa tavallisen peilipalvelimen toimintaa mahdollistamalla haluttujen peilien
päivittäiset tilannekuvat, jotka julkaistaan yksilölliseen web-osoitteeseen.
<br/><br/>
![mirrordebian](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/tavallinen.jpg)
<br/><br/>

Alla taulukko millaista isäntäkonetta voidaan käyttää minkin Linux arkiston peilaukseen ja tilannekuvan ottamiseen.
| Isäntä        | Peilattava arkisto   | Peilattava arkisto  | Peilattava arkisto  | Peilattava arkisto  | Peilattava arkisto  | Peilattava arkisto  | Peilattava arkisto  |
| :-------------: |:-------------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| Alma        | Alma   | Rocky  | Debian | Ubuntu | Fedora | Mint | Kali |
| Debian      | Debian | Ubuntu | Rocky | Alma | Fedora | Mint | Kali |
| Fedora      | Alma (ei testattu)  | Rocky (ei testattu)  | Debian (ei testattu)| Alma (ei testattu) | Fedora (ei testattu) |  Mint (ei testattu) | Kali (ei testattu) |
| Mint      | Alma (ei testattu)  | Rocky (ei testattu)  | Debian (ei testattu)| Alma (ei testattu) | Fedora (ei testattu) | Mint (ei testattu) | Kali (ei testattu) |
| Kali      | Alma (ei testattu)  | Rocky (ei testattu)  | Debian (ei testattu)| Alma (ei testattu) | Fedora (ei testattu) | Mint (ei testattu) | Kali (ei testattu) |
| Rocky       | Rocky  | Alma   | Debian|Ubuntu| Fedora | Mint | Kali |
| Ubuntu      | Ubuntu | Debian | Rocky | Alma | Fedora | Mint | Kali |
<br/><br/>

![all](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/linuxkaikki.jpg)
<br/><br/>
debMirror
![mirrorskuva1](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/debmirror.jpg)
<br/><br/>
rpmMirror
![mirrorskuva2](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/rpmmirror.jpg)

Yllä kuvatun ympäristön kuluttamasta levy tilasta infoa alla.

![dukaikki](https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/blob/main/dukaikki.jpg)


Testi tarkoituksiin yllä kuvattu ympäristö sopii hyvin, mutten suosittelisi sitä tuotantoympäristöksi.

Sen sijaan suosittelen:

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Alma

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Debian

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Rocky

https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/tree/main/Ubuntu
<br/><br/>




