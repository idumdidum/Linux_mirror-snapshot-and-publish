#!/bin/bash

help="Help: https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/"
code=0

if [ -z ${1} ]; then echo "Options required."; echo "${help}"; exit 2; fi

ifroot=$(id -u)
if [ ${ifroot} -ne 0 ]
then
    echo -e "Executing $(basename "$0") as non-root.\nBad non-root."
    exit 2
fi

while getopts "pu:g:s:c:k:n:" vipu
do
    case "${vipu}" in
       \?) echo "${help}"
           exit 2;;
        u) user=${OPTARG};;
        g) globalsettings=${OPTARG};;
        c) SSLcert=${OPTARG};;
        k) SSLkey=${OPTARG};;
        n) SSLchain=${OPTARG};;
        s) ssl=${OPTARG};;
        p) preconfigure=yes;;
    esac
done

if [ ! -z ${preconfigure} ] && [ ! -z ${ssl} ]
then
    echo "Option -p and -s cannot coexist."
    echo "${help}"
    exit 2
fi

if [ -z ${preconfigure} ] && [ -z ${ssl} ]
then
    echo "Option -p or -s must exist."
    echo "${help}"
    exit 2
fi

hostflavor=Unknown
hostflavor=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | sed 's/\"//g')
abso='^/[a-zA-Z0-9]'
dirend='/$'

sanitycheck () {
if [ ${code} -ne 0 ]
then
    echo -e "\nError(s):"
    for ((e = 0; e < ${#sanityerror[@]}; e++))
    do
        echo "${sanityerror[$e]}"
    done
    echo "Help: ${help}"
    exit ${code}
fi
}

checkbc () {
if [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "kali" ] || [ ${hostflavor} == "linuxmint" ]
then
    if ! command -v bc > /dev/null
    then
        echo "Installing bc"
        apt update
        apt install bc -y
    fi
elif [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "fedora" ]
then
    if ! command -v bc > /dev/null
    then
        echo "Installing bc"
        yum install bc -y
    fi
fi
}

if [ ! -z ${ssl} ]
then
    checkusessl='^yes$|^no$|^both$'
    if [[ ! ${ssl} =~ ${checkusessl} ]]
    then
        sanityerror+=("Option -s ${ssl} is invalid.")
        code=2
        sanitycheck
    fi
fi

checkglobal () {
luku=0
ainii='^globaltype=|^domain=|^mainsitename=|^usessl=|^mirrorconfdir=|^mirrordatadir=|^snapshotdir=|^logdir=|^logname=|^mirrortempdir=|^allsnapshotssitename=|^mirroruser=|^#|^$'
for global in $(readlink -f ${globalsettings} | egrep "\.gconf$")
do
    luku=$(echo "${luku} + 1" | bc)
done
if [ ${luku} -eq 1 ]
then
    if [ -f ${globalsettings} ] && [ -r ${globalsettings} ]
    then
        if cat ${globalsettings} | egrep -v "^#|^$" | grep '*' > /dev/null
        then
            ff=$(cat ${globalsettings} | egrep -v "^#|^$" | grep -n '*')
            sanityerror+=("Please check file ${globalsettings}. Illegal character '*' detected.")
            sanityerror+=("${ff}")
            code=2
            sanitycheck
        fi
        grivit=$(cat ${globalsettings} | egrep -v ${ainii} | wc -l)
        if [ ${grivit} -eq 0 ]
        then
            source ./${globalsettings}
        else
            ff=$(cat ${globalsettings} | egrep -vn ${ainii})
            sanityerror+=("Please check file ${globalsettings}. Errorneous line(s):")
            sanityerror+=("${ff}")
            code=2
            sanitycheck
        fi
    else
        sanityerror+=("Option -g ${globalsettings} must be a file and readable by user.")
        code=2
        sanitycheck
    fi
else
    sanityerror+=("Option -g arg expected to find one .gconf file. Found ${luku}.")
    code=2
    sanitycheck
fi

if [ -z ${mirrordatadir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrordatadir=[mirrordatadir] is missing.")
    code=2
elif [[ ! ${mirrordatadir} =~ ${abso} ]] || [[ ${mirrordatadir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} mirrordatadir=${mirrordatadir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
fi
if [ -z ${snapshotdir} ]
then
    sanityerror+=("Option -g ${globalsettings} snapshotdir=[snapshotdir] is missing.")
    code=2
elif [[ ! ${snapshotdir} =~ ${abso} ]] || [[ ${snapshotdir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} snapshotdir=${snapshotdir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
fi
if [ -z ${mirrorconfdir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrorconfdir=[mirrorconfdir] is missing.")
    code=2
elif [[ ! ${mirrorconfdir} =~ ${abso} ]] || [[ ${mirrorconfdir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} mirrorconfdir=${mirrorconfdir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
fi
if [ -z ${logdir} ]
then
    sanityerror+=("Option -g ${globalsettings} logdir=[logdir] is missing.")
    code=2
elif [[ ! ${logdir} =~ ${abso} ]] || [[ ${logdir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} logdir=${logdir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
fi
if [ -z ${logname} ]
then
    sanityerror+=("Option -g arg ${globalsettings} logname=[logname] is missing.")
fi
if [ -z ${mirrortempdir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrortempdir=[mirrortempdir] is missing.")
    code=2
elif [[ ! ${mirrortempdir} =~ ${abso} ]] || [[ ${mirrortempdir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} mirrortempdir=${mirrortempdir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
fi
if [ -z ${usessl} ]
then
    sanityerror+=("Option -g ${globalsettings} usessl=[usessl] Use value yes, no or both.")
    code=2
elif [ ! -z ${usessl} ]
then
    checkusessl='^yes$|^no$|^both$'
    if ! [[ ${usessl} =~ ${checkusessl} ]]
    then
        sanityerror+=("-g ${globalsettings} usessl=${usessl} is invalid.")
        code=2
    fi
fi
if [ -z ${domain} ]
then
    sanityerror+=("Option -g ${globalsettings} domain=[domain] is missing.")
    code=2
fi
if [ -z ${mainsitename} ]
then
    sanityerror+=("Option -g ${globalsettings} mainsitename=[mainsitename] is missing.")
    code=2
fi
if [ -z ${allsnapshotssitename} ]
then
    sanityerror+=("Option -g ${globalsettings} allsnapshotssitename=[allsnapshotssitename] is missing.")
    code=2
fi
if ! egrep "^mirroruser=$" ${globalsettings} > /dev/null && [ -z ${ssl} ]
then
    sanityerror+=("Option -g ${globalsettings} mirroruser= is missing or value has been set.")
    code=2
fi
sanitycheck
if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    webservice=httpd
    a2sitesavailable=/etc/httpd/conf.d
    a2logpath=/var/log/httpd
elif [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]
then
    webservice=apache2
    a2sitesavailable=/etc/apache2/sites-available
    a2logpath='${APACHE_LOG_DIR}'
fi
}

preconfcheck () {
hmm='.gconf'
if [ -z ${user} ]; then sanityerror+=("Option -u arg is missing."); code=2; sanitycheck; fi
if [ ! ${hostflavor} == "almalinux" ] && [ ! ${hostflavor} == "rocky" ] && [ ! ${hostflavor} == "debian" ] && [ ! ${hostflavor} == "ubuntu" ] && [ ! ${hostflavor} == "linuxmint" ] && [ ! ${hostflavor} == "fedora" ] && [ ! ${hostflavor} == "kali" ]
then
    sanityerror+=("Unkown OS release ${hostflavor}.")
    code=2
    sanitycheck
fi
if [ -z ${globalsettings} ]; then sanityerror+=("Option -g arg is missing."); code=2; sanitycheck; fi
if [ ! -f ${globalsettings} ]; then sanityerror+=("Option -g ${globalsettings} must be a file."); code=2; sanitycheck; fi
if [[ ! ${globalsettings} =~ ${hmm} ]]; then sanityerror+=("Option -g ${globalsettings} invalid file suffix."); code=2; sanitycheck; fi
checkbc
checkglobal
}

preconf () {
if [ -d ${mirrorconfdir} ] || [ -d ${mirrordatadir} ] || [ -d ${logdir} ] || [ -d ${snapshotdir} ] || [ -d ${mirrortempdir} ]
then
    sanityerror+=("Seems like preconfiguration has already been done.")
    code=1
    sanitycheck
fi

echo -e "\nPreconfiguring mirror\n"

if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    echo -e "\nInstalling ${webservice} sudo rsync zstd bzip2 gzip wget sqlite policycoreutils-python-utils"
    echo "Creating user ${user}"
    echo "User ${user} home directory is ${mirrorconfdir}"
    echo "Setting password for user ${user} will be asked during preconfiguration"
    echo "Creating directorys and setting owner to ${user}:"
    echo ${mirrordatadir}
    echo ${mirrortempdir}
    echo ${snapshotdir}
    echo ${logdir}
    echo "Configuring SELinux:"
    echo "Adding httpd_sys_content_t ${mirrordatadir}"
    echo "Adding httpd_sys_content_t ${snapshotdir}"
    echo "Preconfiguring ${webservice}"
    echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
    read -r jees
    case ${jees} in
        yes)
        ;;
        no)
            sanityerror+=("Preconfiguration canceled.")
            code=1
            sanitycheck
        ;;
        *)
            sanityerror+=("Preconfiguration aborted.")
            code=2
            sanitycheck
        ;;
    esac
    yum install ${webservice} sudo rsync zstd bzip2 gzip wget sqlite policycoreutils-python-utils -y
    rm -f ${a2sitesavailable}/welcome.conf
    sed -i 's/^IndexOptions FancyIndexing HTMLTable VersionSort$/IndexOptions FancyIndexing HTMLTable VersionSort NameWidth=* SuppressLastModified SuppressDescription/' ${a2sitesavailable}/autoindex.conf
    systemctl enable ${webservice}
    systemctl start ${webservice}

    groupadd ${user}
    useradd -m -d ${mirrorconfdir} -c "${user}" -g ${user} ${user} -s /bin/bash
    echo "${user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo -e "\nSet password for ${user}:"
    passwd ${user}

    mkdir -p ${mirrordatadir}
    mkdir -p ${mirrortempdir}
    mkdir -p ${snapshotdir}
    mkdir -p ${logdir}

    chown -R ${user}:${user} ${mirrordatadir}
    chown -R ${user}:${user} ${mirrortempdir}
    chown -R ${user}:${user} ${snapshotdir}
    chown -R ${user}:${user} ${logdir}

    semanage fcontext -a -t httpd_sys_content_t "${mirrordatadir}(/.*)?"
    semanage fcontext -a -t httpd_sys_content_t "${snapshotdir}(/.*)?"
    restorecon -R -v ${mirrordatadir}
    restorecon -R -v ${snapshotdir}
elif [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]
then
    echo -e "\nInstalling ${webservice} debmirror debian-keyring sudo rsync"
    echo "Creating user ${user}"
    echo "User ${user} home directory is ${mirrorconfdir}"
    echo "Setting password user ${user} will be asked during preconfiguration"
    echo "Creating directorys and setting owner to ${user}:"
    echo ${mirrordatadir}
    echo ${mirrortempdir}
    echo ${snapshotdir}
    echo ${logdir}
    echo "Preconfiguring ${webservice}"
    echo "Creating trustedkeys.gpg keyring"
    echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
    read -r jees
    case ${jees} in
        yes)
        ;;
        no)
            sanityerror+=("Preconfiguration canceled.")
            code=1
            sanitycheck
        ;;
        *)
            sanityerror+=("Preconfiguration aborted.")
            code=2
            sanitycheck
        ;;
    esac
    apt update
    apt install ${webservice} debmirror debian-keyring sudo rsync -y

    sed -i '/^<Directory \/[uv]/,/^<\/Directory>/d' /etc/apache2/apache2.conf
    sed -i '/^<\/Directory>/a \\nIndexOptions FancyIndexing HTMLTable VersionSort NameWidth=* SuppressLastModified SuppressDescription' /etc/apache2/apache2.conf
    for conf in $(find ${a2sitesavailable} -type f -name "*.conf" | awk -F/ '{print $NF}')
    do
        a2dissite ${conf} > /dev/null
        rm -f ${a2sitesavailable}/${conf}
        systemctl reload ${webservice}
    done

    echo "Creating user ${user}"
    groupadd ${user}
    useradd -m -d ${mirrorconfdir} -c "${user}" -g ${user} ${user} -s /bin/bash
    echo "${user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo -e "\nSet password for ${user}"
    passwd ${user}

    mkdir -p ${mirrordatadir}
    mkdir -p ${mirrortempdir}
    mkdir -p ${snapshotdir}
    mkdir -p ${logdir}

    chown -R ${user}:${user} ${mirrordatadir}
    chown -R ${user}:${user} ${mirrortempdir}
    chown -R ${user}:${user} ${snapshotdir}
    chown -R ${user}:${user} ${logdir}

    sudo -u ${user} gpg --no-default-keyring --keyring trustedkeys.gpg --import /usr/share/keyrings/${hostflavor}-archive-keyring.gpg
fi
sed -i "s/^mirroruser=$/mirroruser=${user}/" ./${globalsettings}
cp ./${globalsettings} ${mirrorconfdir}/
chown ${user}:${user} ${mirrorconfdir}/*
echo -e "\nPreconfiguration done.\nNext configure ${webservice}.\n"
}

confnonssl () {
hmm='.gconf$'
if [ -z ${user} ]; then sanityerror+=("Option -u arg is missing."); code=2; sanitycheck; fi
if [ -z ${globalsettings} ]; then sanityerror+=("Option -g arg is missing."); code=2; sanitycheck; fi
if [ ! -f ${globalsettings} ]; then sanityerror+=("Option -g ${globalsettings} must be a file."); code=2; sanitycheck; fi
if [[ ! ${globalsettings} =~ ${hmm} ]]; then sanityerror+=("Option -g ${globalsettings} invalid file suffix."); code=2; sanitycheck; fi
if [ ! ${hostflavor} == "almalinux" ] && [ ! ${hostflavor} == "rocky" ] && [ ! ${hostflavor} == "debian" ] && [ ! ${hostflavor} == "ubuntu" ] && [ ! ${hostflavor} == "linuxmint" ] && [ ! ${hostflavor} == "fedora" ] && [ ! ${hostflavor} == "kali" ]
then
    sanityerror+=("Unkown OS release ${hostflavor}.")
    code=2
    sanitycheck
fi

checkglobal

if [ ! -d ${mirrorconfdir} ] || [ ! -d ${mirrordatadir} ] || [ ! -d ${logdir} ] || [ ! -d ${snapshotdir} ] || [ ! -d ${mirrortempdir} ]
then
    sanityerror+=("Seems like preconfiguration has not been done.")
    code=2
    sanitycheck
fi

if [ -f ${a2sitesavailable}/000-default.conf ]
then
    sanityerror+=("Seems like nonssl has already been configured.")
    code=1
    sanitycheck
fi

if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    if command -v firewall-cmd > /dev/null
    then
        echo "Firewall: firewalld installed on system"
        fwstatus=$(systemctl status firewalld | grep "Active: " | sed 's/^ *//g')
        fwrules=$(firewall-cmd --list-all)
        echo "firewalld ${fwstatus}"
        echo "firewalld rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 80"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring firewalld. Opening port TCP/80."
                firewall-cmd --permanent --add-port=80/tcp
                firewall-cmd --reload
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    fi
fi

if [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]
then
    if command -v ufw > /dev/null
    then
        echo "Firewall: ufw installed on system"
        fwstatus=$(ufw status)
        fwrules=$(ufw show added)
        echo "ufw ${fwstatus}"
        echo "ufw rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 80"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring ufw. Opening port TCP/80."
                ufw allow 80
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    elif command -v iptables > /dev/null
    then
        echo "Firewall: iptables installed on system"
        fwrules=$(iptables -L -v)
        echo "iptables rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 80"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring iptables. Opening port TCP/80."
                iptables -A INPUT -p tcp --dport 80 -j ACCEPT
                netfilter-persistent save
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    fi
fi

snapshotdirdumdidum=$(echo ${snapshotdir} | sed 's/\//\\\//g')
mirrordatadirdumdidum=$(echo ${mirrordatadir} | sed 's/\//\\\//g')
a2logdirdumdidum=$(echo ${a2logpath} | sed 's/\//\\\//g')

sed -i "s/mirrordatadir/${mirrordatadirdumdidum}/;s/mirrorsnapshotdir/${snapshotdirdumdidum}/" ./000-default.conf
sed -i "s/mainsitename/${mainsitename}.${domain}/g" ./000-default.conf
sed -i "s/allsnapshotssitename/${allsnapshotssitename}.${domain}/g" ./000-default.conf
sed -i "s/mirrordatadir/${mirrordatadirdumdidum}/g" ./000-default.conf
sed -i "s/snapshotdir/${snapshotdirdumdidum}/g" ./000-default.conf
sed -i "s/apache2logpath/${a2logdirdumdidum}/g" ./000-default.conf

cp ./000-default.conf ${a2sitesavailable}/
if [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]; then a2ensite 000-default.conf; fi
systemctl reload ${webservice}

cp ./vhost.sslno ${mirrorconfdir}/
if [ ! -f ${mirrorconfdir}/mirror-and-snapshot.bash ]; then cp ./mirror-and-snapshot.bash ${mirrorconfdir} && chmod +x ${mirrorconfdir}/mirror-and-snapshot.bash; fi
chown ${user}:${user} ${mirrorconfdir}/*

echo -e "\nHTTP Setup OK."
echo "http://${mainsitename}.${domain}/"
echo "http://${allsnapshotssitename}.${domain}/"
}

confssl () {
hmm='.gconf$'
if [ -z ${user} ]; then sanityerror+=("Option -u arg is missing."); code=2; sanitycheck; fi
if [ -z ${globalsettings} ]; then sanityerror+=("Option -g arg is missing."); code=2; sanitycheck; fi
if [ ! -f ${globalsettings} ]; then sanityerror+=("Option -g ${globalsettings} must be a file."); code=2; sanitycheck; fi
if [[ ! ${globalsettings} =~ ${hmm} ]]; then sanityerror+=("Option -g ${globalsettings} invalid file suffix."); code=2; sanitycheck; fi
if [ ! ${hostflavor} == "almalinux" ] && [ ! ${hostflavor} == "rocky" ] && [ ! ${hostflavor} == "debian" ] && [ ! ${hostflavor} == "ubuntu" ] && [ ! ${hostflavor} == "linuxmint" ] && [ ! ${hostflavor} == "fedora" ] && [ ! ${hostflavor} == "kali" ]
then
    sanityerror+=("Unkown OS release ${hostflavor}.")
    code=2
    sanitycheck
fi

checkglobal

if [ ! -d ${mirrorconfdir} ] || [ ! -d ${mirrordatadir} ] || [ ! -d ${logdir} ] || [ ! -d ${snapshotdir} ] || [ ! -d ${mirrortempdir} ]
then
    sanityerror+=("Seems like preconfiguration has not been done.")
    code=2
    sanitycheck
fi

if [ -f ${a2sitesavailable}/000-default-ssl.conf ]
then
    sanityerror+=("Seems like ssl has already been configured.")
    code=1
    sanitycheck
fi

if [ -z ${SSLcert} ] && [ -z ${SSLkey} ]
then
    sanityerror+=("Option -k arg and -c arg is missing.")
    code=2
    sanitycheck
elif [ ! -z ${SSLcert} ] && [ -z ${SSLkey} ]
then
    sanityerror+=("-k arg is missing.")
    code=2
    sanitycheck
elif [ -z ${SSLcert} ] && [ ! -z ${SSLkey} ]
then
    sanityerror+=("-c arg is missing.")
    code=2
    sanitycheck
fi

if [ ! -f ${SSLcert} ]; then sanityerror+=("SSLCertificate: -c ${SSLcert} must be a file."); code=2; sanitycheck; fi
if [ ! -f ${SSLkey} ]; then sanityerror+=("SSLKey: -k ${SSLkey} must be a file."); code=2; sanitycheck; fi
if ! [ -z ${SSLchain} ] && [ -f ${SSLchain} ]; then sanityerror+=("SSLChain: -n ${SSLchain} must be a file."); code=2; sanitycheck; fi
if ! [[ -f ${SSLcert} && ${SSLcert} =~ ${abso} ]]; then sanityerror+=("${SSLcert} non absolute path detected. Please use absolute path to certificate."); code=2; sanitycheck; fi
if ! [[ -f ${SSLkey} && ${SSLkey} =~ ${abso} ]]; then sanityerror+=("${SSLkey} non absolute path detected. Please use absolute path to certificate key."); code=2; sanitycheck; fi
if ! [[ -z ${SSLchain} && ${SSLchain} =~ ${abso} ]]; then sanityerror+=("${SSLchain} non absolute path detected. Please use absolute path to certificate chain."); code=2; sanitycheck; fi

if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    if command -v firewall-cmd > /dev/null
    then
        echo "Firewall: firewalld installed on system"
        fwstatus=$(systemctl status firewalld | grep "Active: " | sed 's/^ *//g')
        fwrules=$(firewall-cmd --list-all)
        echo "firewalld ${fwstatus}"
        echo "firewalld rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 443"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring firewalld. Opening port TCP/443."
                firewall-cmd --permanent --add-port=443/tcp
                firewall-cmd --reload
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    fi
    yum install mod_ssl -y
fi

if [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]
then
    if command -v ufw > /dev/null
    then
        echo "Firewall: ufw installed on system"
        fwstatus=$(ufw status)
        fwrules=$(ufw show added)
        echo "ufw ${fwstatus}"
        echo "ufw rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 443"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring ufw. Opening port TCP/443."
                ufw allow 443
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    elif command -v iptables > /dev/null
    then
        echo "Firewall: iptables installed on system"
        fwrules=$(iptables -L -v)
        echo "iptables rules:"
        echo "${fwrules}"
        echo "Would you like add rule: allow TCP HTTP port 443"
        echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
        read -r jees
        case ${jees} in
            yes)
                echo "Configuring iptables. Opening port TCP/443."
                iptables -A INPUT -p tcp --dport 443 -j ACCEPT
                netfilter-persistent save
            ;;
            no)
                echo "Firewall configuration canceled."
                echo "Proceed with ${webservice} configutation:"
                echo -e "\nProceed type 'yes' and press enter or type 'no' and press enter to cancel:"
                read -r jeep
                case ${jeep} in
                   yes)
                   ;;
                   no)
                       sanityerror+=("${webservice} configutation canceled.")
                       code=1
                       sanitycheck
                   ;;
                   *)
                        sanityerror+=("${webservice} configuration aborted.")
                        code=2
                        sanitycheck
                    ;;
                esac
            ;;
            *)
                sanityerror+=("Configuration aborted.")
                code=2
                sanitycheck
            ;;
        esac
    fi
    a2enmod ssl
fi

snapshotdirdumdidum=$(echo ${snapshotdir} | sed 's/\//\\\//g')
mirrordatadirdumdidum=$(echo ${mirrordatadir} | sed 's/\//\\\//g')
a2logdirdumdidum=$(echo ${a2logpath} | sed 's/\//\\\//g')
SSLcertdumdidum=$(echo ${SSLcert} | sed 's/\//\\\//g')
SSLkeydumdidum=$(echo ${SSLkey} | sed 's/\//\\\//g')
if [ ! -z ${SSLchain} ]
then
    chaindumdidum=$(echo ${SSLchain} | sed 's/\//\\\//g')
fi

if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    sed -i '/^<VirtualHost _default_:443>/,/^<\/VirtualHost>/d' ${a2sitesavailable}/ssl.conf
fi

sed -i "s/mainsitename/${mainsitename}.${domain}/g" ./000-default-ssl.conf
sed -i "s/allsnapshotssitename/${allsnapshotssitename}.${domain}/g" ./000-default-ssl.conf
sed -i "s/mirrordatadir/${mirrordatadirdumdidum}/g" ./000-default-ssl.conf
sed -i "s/snapshotdir/${snapshotdirdumdidum}/g" ./000-default-ssl.conf
sed -i "s/apache2logpath/${a2logdirdumdidum}/g" ./000-default-ssl.conf

sed -i "s/fullpathtocerticate/${SSLcertdumdidum}/g" ./000-default-ssl.conf
sed -i "s/fullpathtokey/${SSLkeydumdidum}/g" ./000-default-ssl.conf
if [ ! -z ${SSLchain} ]
then
    sed -i "s/#SSLCertificateChain/SSLCertificateChainFile ${chaindumdidum}/g" ./000-default-ssl.conf
fi

cp ./000-default-ssl.conf ${a2sitesavailable}/
if [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]; then a2ensite 000-default-ssl.conf; fi
systemctl reload ${webservice}

sed -i "s/fullpathtocerticate/${SSLcertdumdidum}/g" ./vhost.sslyes
sed -i "s/fullpathtokey/${SSLkeydumdidum}/g" ./vhost.sslyes
if [ ! -z ${SSLchain} ]
then
    sed -i "s/#SSLCertificateChain/SSLCertificateChainFile ${chaindumdidum}/g" ./vhost.sslyes
fi
cp ./vhost.sslyes ${mirrorconfdir}
if [ ! -f ${mirrorconfdir}/mirror-and-snapshot.bash ]; then cp ./mirror-and-snapshot.bash ${mirrorconfdir} && chmod +x ${mirrorconfdir}/mirror-and-snapshot.bash; fi
chown ${user}:${user} ${mirrorconfdir}/*

echo -e "\nHTTPS Setup OK."
echo "https://${mainsitename}.${domain}/"
echo "https://${allsnapshotssitename}.${domain}/"
}

info () {
echo -e "\nNext add mirroring configuration."
echo "Example:"
if ! ls ${mirrorconfdir}/*.mconf* > /dev/null 2>&1; then cp ./*.mconf.tmpl ${mirrorconfdir}/ && chown ${user}:${user} ${mirrorconfdir}/*; fi
ls ${mirrorconfdir}/*.mconf*
IP6=$(ip a | grep "inet6" | grep -v "::1/128" | awk -F" " '{print $2}' | cut -d "/" -f 1)
IP4=$(ip a | grep "inet " | grep -v 127.0.0.1 | awk -F" " '{print $2}' | cut -d "/" -f 1)
echo -e "\nMirror host IPv6 address seems to be ${IP6}."
echo -e "Mirror host IPv4 address seems to be ${IP4}.\n"
echo "Add something like this to DNS."
echo "${mainsitename}.${domain}.    A    ${IP4}"
echo "${allsnapshotssitename}.${domain}.    A    ${IP4}"
for f in 1 2 3 4 5; do for d in mon tue wed thu fri sat sun; do echo "${f}${d}.${domain}.        IN      A       ${IP4}"; done; done
echo -e "\nOr add something like this to hosts file."
echo "${IP4}     ${mainsitename}.${domain}"
echo "${IP4}     ${allsnapshotssitename}.${domain}"
for f in 1 2 3 4 5; do for d in mon tue wed thu fri sat sun; do echo "${IP4}     ${f}${d}.${domain}"; done; done
}

action () {
if [ ! -z ${preconfigure} ] && [ ${preconfigure} == "yes" ]
then
    preconfcheck
    preconf
elif [ ! -z ${ssl} ] && [ ${ssl} == "no" ]
then
    checkbc
    confnonssl
    info
elif [ ! -z ${ssl} ] && [ ${ssl} == "yes" ]
then
   checkbc
   confssl
   info
elif [ ! -z ${ssl} ] && [ ${ssl} == "both" ]
then
    checkbc
    confnonssl
    confssl
    info
fi
}

action
