#!/bin/bash

## functions:
# mustg
# mustdoru
# mustnotdu
# mustdm
# mustum
# checksoftware
# whattodo
# sourceglobal
# globalsettingscheck
# checkhttp
# presanitycheck
# sanitycheck
# monthlycleanupdaycheck
# mirrorconffilescheck
# ownmirrornamecheck
# mrexclude
# getmetadata
# ifhttpdownloadrpmcleanup
# verify256
# timestamps
# dailyversion
# versionrepoarchsectioncleanup
# startlog
# logend
# websrvkeepalive
# ussl
# updatemirror
# mirrorupdatereturncode
# trydownloadrpmgpg
# cleanpublishedifoldexist
# snapshotcleanup
# csnapshot
# publishsnapshot
# printsnapshoturl
# del
# action

ifroot=$(id -u)
if [ ${ifroot} -eq 0 ]
then
    echo -e "Executing $(basename "$0") as root.\nBad root."
    exit 2
fi

help="Help: https://github.com/idumdidum/Linux_mirror-snapshot-and-publish/"

if [ -z ${1} ]; then echo "Options required."; echo "${help}"; exit 2; fi

while getopts "d:g:u:m:w" vipu
do
    case "${vipu}" in
       \?) echo "${help}"
           exit 2;;
        d) delete=${OPTARG};;
        g) globalsettings=${OPTARG};;
        u) update=${OPTARG};;
        m) mirrorflavor=${OPTARG};;
        w) webservicekeepalive=yes;;
    esac
done

nday=$(date +%d)
hdate=$(date +%Y-%m-%d)
udate=$(date -d "${hdate}" +%s)
month=$(date +%m)
secsinaday=86400
code=0
csnaps=0
SHA256checkfailed=0
abso='^/[a-zA-Z0-9]'
dirend='/$'
method='^http$|^https$'
type='^deb$|^rpm$'

presanitycheck () {
if [ ${code} -ne 0 ]
then
    echo "Error(s):"
    for ((e = 0; e < ${#sanityerror[@]}; e++))
    do
        echo "${sanityerror[$e]}"
    done
    exit ${code}
fi
}

mustg () {
if [ -z ${globalsettings} ]
then
    sanityerror+=("Option -g arg must exist.")
    code=2
    presanitycheck
fi
} 2> /dev/null

mustdoru () {
if [ -z ${delete} ] && [ -z ${update} ]
then
    sanityerror+=("Option -u arg or -d arg must exist.")
    code=2
    presanitycheck
fi
} 2> /dev/null

mustnotdu () {
if [ ! -z ${delete} ] && [ ! -z ${update} ]
then
    sanityerror+=("Option -u arg and -d arg cannot coexist.")
    code=2
    presanitycheck
fi
} 2> /dev/null

mustdm () {
if [ ! -z ${delete} ] && [ -z ${mirrorflavor} ]
then
    sanityerror+=("Option -m arg and -d must exist.")
    code=2
    presanitycheck
fi
} 2> /dev/null

mustum () {
if [ ! -z ${update} ] && [ -z ${mirrorflavor} ]
then
    sanityerror+=("Option -m arg and -u arg must exist.")
    code=2
    presanitycheck
fi
} 2> /dev/null

websrvkeepalive () {
if [ -z ${webservicekeepalive} ]
then
    webservicekeepalive=no
fi
}

checksoftware () {
hostflavor=Unknown
hostflavor=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | sed 's/\"//g')
if [ ! ${hostflavor} == "almalinux" ] && [ ! ${hostflavor} == "rocky" ] && [ ! ${hostflavor} == "debian" ] && [ ! ${hostflavor} == "ubuntu" ] && [ ! ${hostflavor} == "linuxmint" ] && [ ! ${hostflavor} == "kali" ] && [ ! ${hostflavor} == "fedora" ]
then
    sanityerror+=("Unknown OS release ${hostflavor}.")
    code=2
    presanitycheck
fi
if [ ${hostflavor} == "almalinux" ] || [ ${hostflavor} == "rocky" ] || [ ${hostflavor} == "fedora" ]
then
    webservice=httpd
    a2sitesavailable=/etc/httpd/conf.d
    a2logpath=/var/log/httpd
    if ! command -v bc > /dev/null
    then
        cmderror+=("bc")
        code=2
    fi
    if ! command -v rsync > /dev/null
    then
        cmderror+=("rsync")
        code=2
    fi
    if ! command -v wget > /dev/null
    then
        cmderror+=("wget")
        code=2
    fi
    if ! command -v sudo > /dev/null
    then
        cmderror+=("sudo")
        code=2
    fi
    if ! command -v gzip > /dev/null
    then
        cmderror+=("gzip")
        code=2
    fi
    if ! command -v bzip2 > /dev/null
    then
        cmderror+=("bzip2")
        code=2
    fi
    if ! command -v unzstd > /dev/null
    then
        cmderror+=("unzstd")
        code=2
    fi
    if ! command -v xz > /dev/null
    then
        cmderror+=("xz")
        code=2
    fi
    if ! command -v sqlite3 > /dev/null
    then
        cmderror+=("sqlite3")
        code=2
    fi
    if locale -a | grep "^C.utf8$" > /dev/null
    then
        LANG=C.utf8
    else
        cmderror+=("Locale C.utf8 is missing.")
        code=2
    fi
elif [ ${hostflavor} == "debian" ] || [ ${hostflavor} == "ubuntu" ] || [ ${hostflavor} == "linuxmint" ] || [ ${hostflavor} == "kali" ]
then
    webservice=apache2
    a2sitesavailable=/etc/apache2/sites-available
    a2logpath='${APACHE_LOG_DIR}'
    if ! command -v bc > /dev/null
    then
        cmderror+=("bc")
        code=2
    fi
    if ! command -v sudo > /dev/null
    then
        cmderror+=("sudo")
        code=2
    fi
    if ! command -v rsync > /dev/null
    then
        cmderror+=("rsync")
        code=2
    fi
    if ! command -v debmirror > /dev/null
    then
        cmderror+=("debmirror")
        code=2
    fi
    if ! command -v zcat > /dev/null
    then
        cmderror+=("zcat")
        code=2
    fi
    if ! command -v xzcat > /dev/null
    then
        cmderror+=("xzcat")
        code=2
    fi
    if locale -a | grep "^C.utf8$" > /dev/null
    then
        LANG=C.utf8
    else
        cmderror+=("Locale C.utf8 is missing.")
        code=2
    fi
fi
if [ ${code} -eq 2 ]
then
    echo "Please install missing software:"
    for ((s = 0; s < ${#cmderror[@]}; s++))
    do
        echo "${cmderror[$s]}"
    done
    exit ${code}
fi
}

sourceglobal () {
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
            presanitycheck
        fi
        grivit=$(cat ${globalsettings} | egrep -v ${ainii} | wc -l)
        if [ ${grivit} -eq 0 ]
        then
            source ${globalsettings}
        else
            ff=$(cat ${globalsettings} | egrep -vn ${ainii})
            sanityerror+=("Please check file ${globalsettings}. Errorneous line(s):")
            sanityerror+=("${ff}")
            code=2
            presanitycheck
        fi
    else
        sanityerror+=("Option -g ${globalsettings} must be a file and readable by user.")
        code=2
        presanitycheck
    fi
else
    sanityerror+=("Option -g arg expected to find one .gconf file. Found ${luku}. Please do not use wildcards.")
    code=2
    presanitycheck
fi
}

globalsettingscheck () {
if [ -z ${mirroruser} ]
then
    sanityerror+=("Option -g ${globalsettings} mirroruser=[mirroruser] is missing. Preconfiguration has been failed.")
    code=2
    presanitycheck
fi
muser=$(id | awk -F"[()]" '{print $2}')
if [ ! "${mirroruser}" == "${muser}" ]
then
    sanityerror+=("Invalid user:'${muser}'. Expected User:'${mirroruser}'".)
    code=2
    presanitycheck
fi
if [ -z ${globaltype} ]
then
    sanityerror+=("Option -g ${globalsettings} globaltype=[globaltype] is missing.")
    code=2
elif [[ ! ${globaltype} =~ ${type} ]]
then
    sanityerror+=("Option -g ${globalsettings} globaltype=${globaltype} is invalid. globaltype must be 'deb' or 'rpm'.")
    code=2
elif [ ! ${globaltype} == "${mirrorflavor}" ]
then
    sanityerror+=("Option -g ${globalsettings} globaltype=${globaltype} is invalid. Expected value is ${mirrorflavor}.")
    code=2
fi
if [ -z ${mirrordatadir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrordatadir=[mirrordatadir] is missing.")
    code=2
elif [[ ! ${mirrordatadir} =~ ${abso} ]] || [[ ${mirrordatadir} =~ ${dirend} ]]
then
    sanityerror+=("Option -g ${globalsettings} mirrordatadir=${mirrordatadir} invalid path detected. Use absolute path. Remove trailing slash.")
    code=2
elif [ ! -d ${mirrordatadir} ] || [ ! -w ${mirrordatadir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrordatadir=${mirrordatadir} must be a directory and writable by user.")
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
elif [ ! -d ${snapshotdir} ] || [ ! -w ${snapshotdir} ]
then
    sanityerror+=("Option -g ${globalsettings} snapshotdir=${snapshotdir} must be a directory and writable by user.")
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
elif [ ! -d ${mirrorconfdir} ] || [ ! -r ${mirrorconfdir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrorconfdir=${mirrorconfdir} must be a directory and readable by user.")
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
elif [ ! -d ${logdir} ] || [ ! -w ${logdir} ]
then
    sanityerror+=("Option -g ${globalsettings} logdir=${logdir} must be a directory and writable by user.")
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
elif [ ! -d ${mirrortempdir} ] || [ ! -w ${mirrortempdir} ]
then
    sanityerror+=("Option -g ${globalsettings} mirrortempdir=${mirrortempdir} must be a directory and writable by user.")
    code=2
fi
if [ -z ${usessl} ]
then
    sanityerror+=("Option -g ${globalsettings} usessl=[usessl] is missing. Use value yes, no or both.")
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
presanitycheck
}

whattodo () {
if [ ! -z ${update} ]
then
    if [ ${update} ==  "all" ]
    then
        mirrorconffiles="*.mconf"
        what=update
    else
        mirrorconffiles=${update}
        what=update
    fi
fi
if [ ! -z ${delete} ]
then
    mirrorconffiles=${delete}
    what=delete
fi
}

dailyversion () {
weekday=$(date +%a | tr [:upper:] [:lower:])
if [ ${nday} -ge 1 ] && [ ${nday} -le 7 ]
then
    n=1
elif [ ${nday} -ge 8 ] && [ ${nday} -le 14 ]
then
    n=2
elif [ ${nday} -ge 15 ] && [ ${nday} -le 21 ]
then
    n=3
elif [ ${nday} -ge 22 ] && [ ${nday} -le 28 ]
then
    n=4
else
    n=5
fi
daily=${n}${weekday}
}

startlog () {
if [ "${what}" == "update" ]
then
    echo "$(date +%Y-%m-%d_%H:%M:%S) $(basename "$0") start"
    echo "Daily snapshot version is ${daily}"
    echo "Executing $(basename "$0") -g ${globalsettings} -u ${update} -m ${mirrorflavor}"
elif [ "${what}" == "delete" ]
then
    echo "$(date +%Y-%m-%d_%H:%M:%S) $(basename "$0") start"
    echo "Executing $(basename "$0") -g ${globalsettings} -d ${delete}"
fi
}

logend () {
echo "$(date +%Y-%m-%d_%H:%M:%S) $(basename "$0") end"
echo "$(date +%Y-%m-%d_%H:%M:%S) $(basename "$0") return code ${code}"
if [ ${webservicekeepalive} == "no" ] && [ ${code} -eq 2 ]
then
    echo "Mirror(s) update failed. Stopping ${webservice}."
    sudo systemctl stop ${webservice}
fi
echo "Log: ${logdir}/${logname}"
exit ${code}
}

sanitycheck () {
if [ ${code} -ne 0 ]
then
    echo "Error(s):"
    for ((i = 0; i < ${#sanityerror[@]}; i++))
    do 
        echo "${sanityerror[$i]}"
    done
    logend
fi
}

chechttp () {
if [ ${usessl} == "no" ]
then
    if [ ! -f ${a2sitesavailable}/000-default.conf ]; then sanityerror+=("In ${globalsettings} usessl is set 'no', but HTTP is not configured."); code=2; fi
elif [ ${usessl} == "yes" ]
then
    if [ ! -f ${a2sitesavailable}/000-default-ssl.conf ]; then sanityerror+=("In ${globalsettings} usessl is set 'yes', but HTTPS is not configured."); code=2; fi
elif [ ${usessl} == "both" ]
then
    if [ ! -f ${a2sitesavailable}/000-default.conf ]; then sanityerror+=("In ${globalsettings} usessl is set 'both', but HTTP is not configured."); code=2; fi
    if [ ! -f ${a2sitesavailable}/000-default-ssl.conf ]; then sanityerror+=("In ${globalsettings} usessl is set 'both', but HTTPS is not configured."); code=2; fi
fi
presanitycheck
}

ownmirrornamecheck () {
aaownmirrorname=()
for nmirrorconf in $(find ${mirrorconfdir}/ -maxdepth 1 -type f -name "*.mconf" 2> /dev/null)
do
    aownmirrorname=$(grep '^mirrorname=' ${nmirrorconf} | awk -F= '{print $2}')
    mname='^[0-9a-z\-\/]+$'
    nname='^/|/$'
    if [[ ${aownmirrorname} =~ ${mname} ]] || [[ ! ${aownmirrorname} =~ $nname ]]
    then
        for dumdidum in "${aaownmirrorname[@]}"
        do
            if [ "${dumdidum}" == "${aownmirrorname}" ]
            then
                dublicate=$(grep '^mirrorname=' ${mirrorconfdir}/*.mconf | grep "${dumdidum}$")
                sanityerror+=("Each mirror must have it's own mirrorname:")
                sanityerror+=("${dublicate}")
                code=2
            fi
        done
    else
        sanityerror+=("${nmirrorconf} mirrorname=${aownmirrorname} must be relative path to directory. Capital letters not allowed. Hypens and slashes allowed. Slash not allowed to be last character.")
        code=2
        continue
    fi
    aaownmirrorname+=(${aownmirrorname})
done
}

monthlycleanupdaycheck () {
if [ ! -z ${monthlycleanupday} ]
then
    checkmonthlycleanupday='^[0-9]+$|^firstday$|^lastday$|^today$|^no$'
    if ! [[ ${monthlycleanupday} =~ ${checkmonthlycleanupday} ]]
    then
        sanityerror+=("${mconf} monthlycleanupday=${monthlycleanupday} is invalid.")
        code=2
    elif [ ${monthlycleanupday} -lt 1 ] || [ ${monthlycleanupday} -gt 31 ]
    then
        sanityerror+=("${mconf} monthlycleanupday=${monthlycleanupday} is invalid.")
        code=2
    elif [ ${monthlycleanupday} == "firstday" ]
    then
        monthlycleanupday=1
    elif [ ${monthlycleanupday} == "today" ]
    then
        monthlycleanupday=${nday}
    elif [ ${monthlycleanupday} == "lastday" ]
    then
        onkohan=$(echo "${udate} + ${secsinaday}" | bc)
        if ! date -d @${onkohan} +%m | grep ${month} > /dev/null
        then
            monthlycleanupday=${nday}
        else
            unset monthlycleanupday
        fi
    elif [ ${monthlycleanupday} == "no" ]
    then
        unset monthlycleanupday
    fi 2> /dev/null
fi
}

mirrorconffilescheck () {
if [ ${mirrorflavor} == "rpm" ]
then
if ! find ${mirrorconfdir} -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$" > /dev/null
then
    sanityerror+=("No mirror configuration file(s) (.mconf) found in directory ${mirrorconfdir}.")
    code=2
    sanitycheck
else
    for mconf in $(find ${mirrorconfdir}/ -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$")
    do
        if [ -r ${mconf} ]
        then
            mainii='^mirrortype=|^arch=|^host=|^rootdir=|^mirrorname=|^downloadmethod=|^repos=|^sections=|^enabled=|^verifysha256=|^createsnapshot=|^monthlycleanupday=|^mirrorsyncexclude=|^versions=|^trydownloadrpmgpgkeys=|^#|^$'
            mrivit=$(cat ${mconf} | egrep -v ${mainii} | wc -l)
            if [ ${mrivit} -eq 0 ]
            then
                if ! cat ${mconf} | egrep -v "^#|^$" | grep '*' > /dev/null
                then
                    unset mirrortype
                    unset arch
                    unset host
                    unset rootdir
                    unset mirrorname
                    unset downloadmethod
                    unset repos
                    unset sections
                    unset enabled
                    unset verifysha256
                    unset createsnapshot
                    unset mirrorsyncexclude
                    unset monthlycleanupday
                    unset versions
                    unset trydownloadrpmgpgkeys
                    source ${mconf}
                    dm='^rsync$|^http$|^https$'
                    yesno='^yes$|^no$|^force$'
                    try='^yes$|^no$'
                    if [ -z "${mirrortype}" ]; then sanityerror+=("${mconf} mirrortype is missing."); code=2; fi
                    if [[ ! "${mirrortype}" =~ ${type} ]]; then sanityerror+=("${mconf} mirrortype=${mirrortype} is invalid. mirrortype must be 'deb' or 'rpm'."); code=2; fi
                    if [ ! "${mirrortype}" == "${mirrorflavor}" ]; then sanityerror+=("${mconf} mirrortype=${mirrortype} is invalid."); code=2; fi
                    if [ -z "${enabled}" ]; then sanityerror+=("${mconf} enabled is missing."); code=2; fi
                    if [[ ! "${enabled}" =~ ${yesno} ]]; then sanityerror+=("${mconf} enabled=${enabled} is invalid."); code=2; fi
                    if [ -z "${verifysha256}" ]; then sanityerror+=("${mconf} verifysha256 is missing."); code=2; fi
                    if [[ ! "${verifysha256}" =~ ${yesno} ]]; then sanityerror+=("${mconf} verifysha256=${verifysha256} is invalid."); code=2; fi
                    if [ -z "${createsnapshot}" ]; then sanityerror+=("${mconf} createsnapshot is missing."); code=2; fi
                    if [[ ! "${createsnapshot}" =~ ${yesno} ]]; then sanityerror+=("${mconf} createsnapshot=${createsnapshot} is invalid."); code=2; fi
                    if [ -z "${trydownloadrpmgpgkeys}" ]; then sanityerror+=("${mconf} trydownloadrpmgpgkeys is missing."); code=2; fi
                    if [[ ! "${trydownloadrpmgpgkeys}" =~ ${try} ]]; then sanityerror+=("${mconf} trydownloadrpmgpgkeys=${trydownloadrpmgpgkeys} is invalid."); code=2; fi
                    if [ -z "${host}" ]; then sanityerror+=("${mconf} host is missing."); code=2; fi
                    if [ -z "${rootdir}" ]; then sanityerror+=("${mconf} rootdir is missing."); code=2; fi
                    if [ -z "${mirrorname}" ]; then sanityerror+=("${mconf} mirrorname is missing."); code=2; fi
                    if [ -z "${downloadmethod}" ]; then sanityerror+=("${mconf} downloadmethod is missing."); code=2; fi
                    if [[ ! "${downloadmethod}" =~ ${dm} ]]; then sanityerror+=("${mconf} downloadmethod=${downloadmethod} is invalid."); code=2; fi
                    if [ -z "${arch}" ]; then sanityerror+=("${mconf} arch is missing."); code=2; fi
                    if [ -z "${repos}" ]; then sanityerror+=("${mconf} repos is missing."); code=2; fi
                    if [ -z "${sections}" ]; then sanityerror+=("${mconf} sections"); code=2; fi
                    if [ -z "${mirrorsyncexclude}" ]; then sanityerror+=("${mconf} mirrorsyncexclude is missing."); code=2; fi
                    if [ -z "${monthlycleanupday}" ]; then sanityerror+=("${mconf} monthlycleanupday is missing."); code=2; fi
                    if [ -z "${versions}" ]; then sanityerror+=("${mconf} versions is missing."); code=2; fi
                    monthlycleanupdaycheck
                    ownmirrornamecheck
                    unset mconf
                else
                    ff=$(cat ${mconf} | egrep -v "^#|^$" | grep -n '*')
                    sanityerror+=("Please check file ${mconf}. Illegal character '*' detected.")
                    sanityerror+=("${ff}")
                    code=2
                    unset mconf
                fi
            else
                foo=$(cat ${mconf} | egrep -vn ${mainii})
                sanityerror+=("Please check file ${mconf}. Errorneous line(s):")
                sanityerror+=("${foo}")
                code=2
                unset mconf
            fi
        else
            sanityerror+=("File ${mconf} must be readable by user.")
            code=2
            unset mconf
        fi
    done
    sanitycheck
fi
elif [ ${mirrorflavor} == "deb" ]
then
if ! find ${mirrorconfdir} -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$" > /dev/null
then
    sanityerror+=("No mirror configuration file(s) found in directory ${mirrorconfdir}.")
    code=2
    sanitycheck
else
    for mconf in $(find ${mirrorconfdir}/ -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$")
    do
        if [ -r ${mconf} ]; then
            mainii='^mirrortype=|^arch=|^host=|^mirrorname=|^dist=|^rootdir=|^section=|^enabled=|^downloadmethod=|^createsnapshot=|^monthlycleanupday=|^debmirroroptions=|^verifysha256=|^#|^$'
            mrivit=$(cat ${mconf} | egrep -v ${mainii} | wc -l)
            if [ ${mrivit} -eq 0 ]
            then
                if ! cat ${mconf} | egrep -v "^#|^$" | grep '*' > /dev/null
                then
                    unset mirrortype
                    unset arch
                    unset section
                    unset host
                    unset dist
                    unset rootdir
                    unset mirrorname
                    unset downloadmethod
                    unset enabled
                    unset createsnapshot
                    unset debmirroroptions
                    unset monthlycleanupday
                    unset verifysha256
                    source ${mconf}
                    dm='^rsync$|^http$'
                    yesno='^yes$|^no$|^force$'
                    if [ -z "${mirrortype}" ]; then sanityerror+=("${mconf} mirrortype is missing."); code=2; fi
                    if [[ ! "${mirrortype}" =~ ${type} ]]; then sanityerror+=("${mconf} mirrortype=${mirrortype} is invalid. mirrortype must be 'deb' or 'rpm'."); code=2; fi
                    if [ ! "${mirrortype}" == "${mirrorflavor}" ]; then sanityerror+=("${mconf} mirrortype=${mirrortype} is invalid."); code=2; fi
                    if [ -z "${enabled}" ]; then sanityerror+=("${mconf} enabled is missing."); code=2; fi
                    if [[ ! "${enabled}" =~ ${yesno} ]]; then sanityerror+=("${mconf} enabled=${enabled} is invalid."); code=2; fi
                    if [ -z "${verifysha256}" ]; then sanityerror+=("${mconf} verifysha256 is missing."); code=2; fi
                    if [[ ! "${verifysha256}" =~ ${yesno} ]]; then sanityerror+=("${mconf} verifysha256=${verifysha256} is invalid."); code=2; fi
                    if [ -z "${createsnapshot}" ]; then sanityerror+=("${mconf} createsnapshot is missing."); code=2; fi
                    if [[ ! "${createsnapshot}" =~ ${yesno} ]]; then sanityerror+=("${mconf} createsnapshot=${createsnapshot} is invalid."); code=2; fi
                    if [ -z "${host}" ]; then sanityerror+=("${mconf} host is missing."); code=2; fi
                    if [ -z "${arch}" ]; then sanityerror+=("${mconf} arch is missing."); code=2; fi
                    if [ -z "${dist}" ]; then sanityerror+=("${mconf} dist is missing."); code=2; fi
                    if [ -z "${section}" ]; then sanityerror+=("${mconf} section is missing."); code=2; fi
                    if [ -z "${rootdir}" ]; then sanityerror+=("${mconf} rootdir is missing."); code=2; fi
                    if [ -z "${monthlycleanupday}" ]; then sanityerror+=("${mconf} monthlycleanupday is missing."); code=2; fi
                    if [ -z "${debmirroroptions}" ]; then sanityerror+=("${mconf} debmirroroptions is missing."); code=2; fi
                    if [ -z "${mirrorname}" ]; then sanityerror+=("${mconf} mirrorname is missing."); code=2; fi
                    if [ -z "${downloadmethod}" ]; then sanityerror+=("${mconf} downloadmethod is missing."); code=2; fi
                    if [[ ! "${downloadmethod}" =~ ${dm} ]]; then sanityerror+=("${mconf} downloadmethod=${downloadmethod} is invalid."); code=2; fi
                    ownmirrornamecheck
                    monthlycleanupdaycheck
                    unset mconf
                else
                    ff=$(cat ${mconf} | egrep -v "^#|^$" | grep -n '*')
                    sanityerror+=("Please check file ${mconf}. Illegal character '*' detected.")
                    sanityerror+=("${ff}")
                    code=2
                    unset mconf
                fi
            else
                foo=$(cat ${mconf} | egrep -v ${mainii})
                sanityerror+=("Please check file ${mconf}. Errorneous line(s):")
                sanityerror+=("${foo}")
                code=2
                unset mconf
            fi
        else
            sanityerror+=("Mirror configarion ${mconf} must be readable by user.")
            code=2
            unset mconf
        fi
    done
    sanitycheck
fi
fi
}

mrexclude () {
if [ ! ${mirrorsyncexclude} == "no" ] && [ ${downloadmethod} == "rsync" ]
then
    ohhjaa=0
    for mrexc in ${mirrorsyncexclude}
    do
        if [ ${ohhjaa} -eq 0 ]
        then
            mrrsyncexclude="--exclude ${mrexc}"
            ohhjaa=1
        else
            mrrsyncexclude="--exclude ${mrexc} ${mrrsyncexclude}"
        fi
    done
elif [[ ! ${mirrorsyncexclude} == "no" && ${downloadmethod} =~ ${method} ]]
then
    ohhjaa=0
    for mrexc in ${mirrorsyncexclude}
    do
        if [ ${ohhjaa} -eq 0 ]
        then
            mrrsyncexclude="/${mrexc}/"
            ohhjaa=1
        else
            mrrsyncexclude="${mrrsyncexclude}|/${mrexc}/"
        fi
    done
    mrrsyncexclude="--reject-regex=\"${mrrsyncexclude}\""
fi
}

mirrorupdatereturncode () {
if [ ${mirrorflavor} == "rpm" ]
then
if [ ${mirrorupdate} -ne 0 ]
then
    sanityerror+=("Mirror ${mirrorname} update failed")
    sanityerror+=("Sourced mirror configuration ${mconf}:")
    ff=$(cat ${mconf} | egrep -v "^#|^$")
    sanityerror+=("${ff}")
    mupdateerror=1
    code=2
fi
elif [ ${mirrorflavor} == "deb" ]
then
if [ ${mirrorupdate} -ne 0 ]
then
    sanityerror+=("Mirror ${mirrorname} update failed")
    sanityerror+=("Sourced mirror configuration ${mconf}:")
    ff=$(cat ${mconf} | egrep -v "^#|^$")
    sanityerror+=("${ff}")
    updateerror=1
    code=2
else
    rm -f ${mirrordatadir}/${mirrorname}/{*.human,*.unix}
    echo "Timestamps - ${mirrordatadir}/${mirrorname}/{${daily}.human,${hdate}.human,${udate}.unix}"
    touch ${mirrordatadir}/${mirrorname}/{${daily}.human,${hdate}.human,${udate}.unix}
fi
fi
}

timestamps () {
rm -f ${mirrordatadir}/${mirrorname}/{*.human,*.unix}
echo "Timestamps - ${mirrordatadir}/${mirrorname}/{${daily}.human,${hdate}.human,${udate}.unix}"
touch ${mirrordatadir}/${mirrorname}/{${daily}.human,${hdate}.human,${udate}.unix}
if [ ${createsnapshot} == "yes" ] && [ ${csnaps} -gt 0 ]
then
    cp -a ${mirrordatadir}/${mirrorname}/{*.human,*.unix} ${snapshotdir}/${daily}_${hdate}/${mirrorname}/
fi
}

getmetadata () {
unset metadatatype
unset primarydbname
unset primarysqlitesha
unset primarysqliteshasum
if [ -d ${destinationmirrorfullpath}/repodata ]
then
    repodatapath=${destinationmirrorfullpath}/repodata
    if ls ${destinationmirrorfullpath}/repodata/*primary.sqlite.* 2> /dev/null | egrep "\.gz|\.xz|\.bz2" > /dev/null
    then
        metadatatype="sqlite"
    elif ls ${destinationmirrorfullpath}/repodata/*primary.xml.zst 2> /dev/null
    then
        metadatatype="zst"
    fi
    if [ -z ${metadatatype} ]
    then
        sanityerror+=("Search base: ${repodatapath}. Did not find *-primary.sqlite.{gz,xz,bz2} or *-primary.xml.zst file.")
        code=2
    else
        if [ "${metadatatype}" == "sqlite" ]
        then
            metadatac=$(ls ${repodatapath}/*primary.sqlite.{gz,xz,bz2} 2> /dev/null | wc -l)
        elif [ "${metadatatype}" == "zst" ]
        then
            metadatac=$(ls ${repodatapath}/*primary.xml.zst 2> /dev/null | wc -l)
        fi
        if [ ${metadatac} -eq 1 ]
        then
            if [ "${metadatatype}" == "sqlite" ]
            then
                rm -f ${mirrortempdir}/{*primary.sqlite*,*.tmp}
                cp ${repodatapath}/*primary.sqlite.{gz,xz,bz2} ${mirrortempdir} 2> /dev/null
                primarysqlitesha=$(ls ${mirrortempdir}/*primary.sqlite.{gz,xz,bz2} 2> /dev/null | awk -F"-" '{print $1}' | awk -F/ '{print $NF}')
                primarysqliteshasum=$(sha256sum ${mirrortempdir}/*primary.sqlite.{gz,xz,bz2} 2> /dev/null | awk -F" " '{print $1}')
                if [ "${primarysqlitesha}" == "${primarysqliteshasum}" ]
                then
                    bz2orgzip=$(ls ${mirrortempdir}/*primary.sqlite.{gz,xz,bz2} 2> /dev/null | awk -F. '{print $NF}')
                    if [ ${bz2orgzip} == "gz" ]
                    then
                        gzip -d ${mirrortempdir}/*primary.sqlite.gz
                        primarydbname=$(ls ${mirrortempdir}/*primary.sqlite)
                    elif [ ${bz2orgzip} == "bz2" ]
                    then
                        bzip2 -d ${mirrortempdir}/*primary.sqlite.bz2
                        primarydbname=$(ls ${mirrortempdir}/*primary.sqlite)
                    elif [ ${bz2orgzip} == "xz" ]
                    then
                        xz -d ${mirrortempdir}/*primary.sqlite.xz
                        primarydbname=$(ls ${mirrortempdir}/*primary.sqlite)
                    fi
                    sqlite3 ${primarydbname} 'select pkgid, location_href from packages' -csv > ${mirrortempdir}/packagespkgid.tmp
                    metadatastatus=0
                else
                    sanityerror+=("Search base: ${repodatapath}. *-primary.sqlite.{gz,xz,bz2} SHA256 check failed. Expected ${primarysqlitesha}. Found ${primarysqliteshasum}.")
                    code=2
                fi
            elif [ "${metadatatype}" == "zst" ]
            then
                rm -f ${mirrortempdir}/{*primary.xml*,*.tmp}
                cp ${repodatapath}/*primary.xml.zst ${mirrortempdir}
                primarysqlitesha=$(ls ${mirrortempdir}/*primary.xml.zst 2> /dev/null | awk -F"-" '{print $1}' | awk -F/ '{print $NF}')
                primarysqliteshasum=$(sha256sum ${mirrortempdir}/*primary.xml.zst 2> /dev/null | awk -F" " '{print $1}')
                if [ "${primarysqlitesha}" == "${primarysqliteshasum}" ]
                then
                    unzstd -d ${mirrortempdir}/*primary.xml.zst
                    cat ${mirrortempdir}/*primary.xml | egrep "checksum type=\"sha256\" pkgid=\"YES\"|location href=" | sed 's/^  <checksum type="sha256" pkgid="YES">//;s/^  <location href="//;s/<\/checksum>//;s/"\/>//' > ${mirrortempdir}/std.tmp
                    paste -d "," - - < ${mirrortempdir}/std.tmp > ${mirrortempdir}/packagespkgid.tmp
                    metadatastatus=0
                else
                    sanityerror+=("Search base: ${repodatapath}. *-primary.xml.zst SHA256 check failed. Expected ${primarysqlitesha}. Found ${primarysqliteshasum}.")
                    code=2
                fi
            fi
        else
            sanityerror+=("Search base: ${repodatapath}. Expected to find one *-primary.sqlite.{gz,xz,bz2} or *-primary.xml.zst file. Found ${metadatac}.")
            code=2
        fi
    fi
fi
}

ifhttpdownloadrpmcleanup () {
unset rpmfiles
unset rpmfile
maskdestinationmirrorfullpath=$(echo "${destinationmirrorfullpath}/" | sed 's/\//\\\//g')
if [ ${metadatastatus} -eq 0 ]
then
    for rpmfiles in $(find ${destinationmirrorfullpath} -type f -name '*.rpm')
    do
        rpmfile=$(echo ${rpmfiles} | sed "s/${maskdestinationmirrorfullpath}//" | sed 's/\./\\./g;s/\+/\\+/g;s/\^/\\^/g')
        if ! egrep ",${rpmfile}$" ${mirrortempdir}/packagespkgid.tmp > /dev/null
        then
            echo "Removing obsolute rpm file ${rpmfiles}"
            sudo rm -f ${rpmfiles}
        fi
    done
fi
}

verify256 () {
if [ ${mirrorflavor} == "rpm" ]
then
if [ ${metadatastatus} -eq 0 ]
then
    unset rpmfiles
    unset rpmfile
    if [ ${verifysha256} == "force" ]; then rm -f ${mirrortempdir}/${mirrorname}_sha256scansuccess_${sdestination}; fi
    failed256file="${mirrortempdir}/failed256file_${sdestination}"
    if [ -f ${failed256file} ]; then rm -f ${failed256file}; fi
    echo "Verifying SHA256 ${destinationmirrorfullpath} in progress.."
    if [ ! -f ${mirrortempdir}/${mirrorname}_sha256scansuccess_${sdestination} ]
    then
        for rpmfileandid in $(cat ${mirrortempdir}/packagespkgid.tmp)
        do
            rpmfile=$(echo ${rpmfileandid} | awk -F, '{print $2}')
            rpmfileid=$(echo ${rpmfileandid} | awk -F, '{print $1}')
            rpmfilesha256=$(sha256sum ${destinationmirrorfullpath}/${rpmfile} | awk -F" " '{print $1}')
            if [ "${rpmfilesha256}" == "${rpmfileid}" ]
            then
                echo "${destinationmirrorfullpath}/${rpmfile} sha256 verified."
                # echo "${destinationmirrorfullpath}/${rpmfile} sha256 verified. Expected ${rpmfileid} - Found ${rpmfilesha256}."
            else
                #echo "${destinationmirrorfullpath}/${rpmfile} sha256 check failed." | tee -a ${failed256file}
                echo "${destinationmirrorfullpath}/${rpmfile} sha256 check failed. Expected ${rpmfileid} - Found ${rpmfilesha256}." | tee -a ${failed256file}
                SHA256checkfailed=1
                verify256check=1
            fi
        done
    else
        if [ -f ${mirrortempdir}/mirrordownload.tmp ]; then sudo rm -f ${mirrortempdir}/mirrordownload.tmp; fi
        touch ${mirrortempdir}/mirrordownload.tmp
        cat ${logdir}/${logname} | awk "/^a${tagi}a$/{a=1;next} /^b${tagi}b$/{a=0} a" > ${mirrortempdir}/mirrordownload.tmp
        if [[ "${downloadmethod}" =~ ${method} ]]
        then
            for drpmfile in $(cat ${mirrortempdir}/mirrordownload.tmp | egrep "\.rpm\’ saved \[" | awk -F"[‘’]" '{print $2}')
            do
                rpmfilesha256=$(sha256sum ${drpmfile} | awk -F" " '{print $1}')
                rpmfile=$(echo ${drpmfile} | awk -F/ '{print $NF}' | sed 's/\./\\./g;s/\+/\\+/g;s/\^/\\^/g')
                rpmfileid=$(egrep ",${rpmfile}" ${mirrortempdir}/packagespkgid.tmp | awk -F, '{print $1}')
                if [ "${rpmfilesha256}" == "${rpmfileid}" ]
                then
                    echo "${drpmfile} sha256 verified."
                    # echo "${drpmfile} sha256 verified. Expected ${rpmfileid} - Found ${rpmfilesha256}."
                else
                    # echo "${drpmfile} sha256 check failed." | tee -a ${failed256file}
                    echo "${drpmfile} sha256 check failed. Expected ${rpmfileid} - Found ${rpmfilesha256}." | tee -a ${failed256file}
                    SHA256checkfailed=1
                    verify256check=1
                fi
            done
        else
            for drpmfile in $(cat ${mirrortempdir}/mirrordownload.tmp | grep -v "^deleting " | egrep "\.rpm$" | cut -d"/" -f2-)
            do
                rpmfilesha256=$(sha256sum ${destinationmirrorfullpath}/${drpmfile} | awk -F" " '{print $1}')
                drpmfiles=$(echo ${drpmfile} | sed 's/\./\\./g;s/\+/\\+/g;s/\^/\\^/g')
                rpmfileid=$(egrep ",${drpmfiles}" ${mirrortempdir}/packagespkgid.tmp | awk -F, '{print $1}')
                if [ "${rpmfilesha256}" == "${rpmfileid}" ]
                then
                    echo "${destinationmirrorfullpath}/${drpmfile} sha256 verified."
                    # echo "${drpmfile} sha256 verified. Expected ${rpmfileid} - Found ${rpmfilesha256}."
                else
                    # echo "${destinationmirrorfullpath}/${drpmfile} sha256 check failed." | tee -a ${failed256file}
                    echo "${destinationmirrorfullpath}/${drpmfile} sha256 check failed. Expected ${rpmfileid} - Found ${rpmfilesha256}." | tee -a ${failed256file}
                    SHA256checkfailed=1
                    verify256check=1
                fi
            done
        fi
    fi
    if [ ${verify256check} -eq 1 ]
    then
        hmm="check failed"
    else
        hmm="check completed successfully"
        touch ${mirrortempdir}/${mirrorname}_sha256scansuccess_${sdestination}
    fi
echo "Verifying SHA256 ${destinationmirrorfullpath} ${hmm}."
fi
elif [ ${mirrorflavor} == "deb" ]
then
rm -f  ${mirrortempdir}/*.tmp*
if [ ${verifysha256} == "force" ]; then rm -f ${mirrortempdir}/${mirrorname}_sha256scansuccess; fi
if [ ! -f ${mirrortempdir}/${mirrorname}_sha256scansuccess ]
then
    for pkgid in $(find ${mirrordatadir}/${mirrorname}/dists -type f -name "Packages.gz")
    do
        zcat ${pkgid} | egrep "^Filename:|^SHA256:" | sed 's/ //;s/Filename://;s/SHA256://' >> ${mirrortempdir}/packagespkgid.tmp1
    done
    if [ ! -f ${mirrortempdir}/packagespkgid.tmp1 ]
    then
        for pkgid in $(find ${mirrordatadir}/${mirrorname}/dists -type f -name "Packages.xz")
        do
            xzcat ${pkgid} | egrep "^Filename:|^SHA256:" | sed 's/ //;s/Filename://;s/SHA256://' >> ${mirrortempdir}/packagespkgid.tmp1
        done
    fi
    if [ -f ${mirrortempdir}/packagespkgid.tmp1 ]
    then
        montarivia=$(cat ${mirrortempdir}/packagespkgid.tmp1 | wc -l)
        if (( ${montarivia} % 2 == 0 ))
        then
            echo "Mirror ${mirrorname} sha256 check in progress.."
            paste -d "#" - - < ${mirrortempdir}/packagespkgid.tmp1 >> ${mirrortempdir}/packagespkgid.tmp2
            cat ${mirrortempdir}/packagespkgid.tmp2 | sort | uniq >> ${mirrortempdir}/packagespkgid.tmp3
            failed256file="${mirrortempdir}/failed256file_${mirrorname}"
            if [ -f ${failed256file} ]; then rm -f ${failed256file}; fi
            for rivi in $(cat ${mirrortempdir}/packagespkgid.tmp3)
            do
                unset packagesha256
                unset filename
                unset debfilesha256
                filename=$(echo ${rivi} | awk -F"#" '{print $1}')
                packagesha256=$(echo ${rivi} | awk -F"#" '{print $2}')
                debfilesha256=$(sha256sum ${mirrordatadir}/${mirrorname}/${filename} 2> /dev/null | awk -F" " '{print $1}')
                if [ ! -z  ${debfilesha256} ]
                then
                    if [ "${debfilesha256}" == "${packagesha256}" ]
                    then
                        echo "${mirrordatadir}/${mirrorname}/${filename} sha256 verified."
                        # echo "${mirrordatadir}/${mirrorname}/${filename} sha256 verified. Expected ${packagesha256} - Found ${debfilesha256}."
                    else
                        # echo "${mirrordatadir}/${mirrorname}/${filename} sha256 check failed."
                        echo "${mirrordatadir}/${mirrorname}/${filename} sha256 check failed. Expected ${packagesha256} - Found ${debfilesha256}." | tee -a ${failed256file}
                        SHA256checkfailed=1
                        verify256check=1
                    fi
                fi
            done
            if [ ${verify256check} -eq 0 ]
            then
                touch ${mirrortempdir}/${mirrorname}_sha256scansuccess
                echo "Mirror ${mirrorname} sha256 check OK."
            else
               echo "Mirror ${mirrorname} sha256 check failed."
            fi
        else
            sanityerror+=("Mirror ${mirrorname} packages meta info invalid/corrupted.")
            code=2
        fi
    else
        sanityerror+=("Search base: ${mirrordatadir}/${mirrorname}/dists. Packages file(s) unknown compression. Expected xz or gz.")
        code=2
    fi
else
    if [ -f ${mirrortempdir}/mirrordownload.tmp ]; then sudo rm -f ${mirrortempdir}/mirrordownload.tmp; fi
    touch ${mirrortempdir}/mirrordownload.tmp
    cat ${logdir}/${logname} | awk "/^a${tagi}a$/{a=1;next} /^b${tagi}b$/{a=0} a" > ${mirrortempdir}/mirrordownload.tmp
    cdeb=0
    if [ ${downloadmethod} == "rsync" ]
    then
        cdeb=$(cat ${mirrortempdir}/mirrordownload.tmp | grep "^pool/" | egrep "\.deb$" | wc -l)
    elif [ ${downloadmethod} == "http" ]
    then
        cdeb=$(cat ${mirrortempdir}/mirrordownload.tmp | grep "Getting: pool/" | egrep "\.deb... ok$" | wc -l)
    fi
    echo "Mirror ${mirrorname} sha256 check in progress.."
    if [ ${cdeb} -gt 0 ]
    then
        for pkgid in $(find ${mirrordatadir}/${mirrorname}/dists -type f -name "Packages.gz")
        do
            zcat ${pkgid} | egrep "^Filename:|^SHA256:" | sed 's/ //;s/Filename://;s/SHA256://' >> ${mirrortempdir}/packagespkgid.tmp1
        done
        if [ ! -f ${mirrortempdir}/packagespkgid.tmp1 ]
        then
            for pkgid in $(find ${mirrordatadir}/${mirrorname}/dists -type f -name "Packages.xz")
            do
                xzcat ${pkgid} | egrep "^Filename:|^SHA256:" | sed 's/ //;s/Filename://;s/SHA256://' >> ${mirrortempdir}/packagespkgid.tmp1
            done
        fi
        if [ -f ${mirrortempdir}/packagespkgid.tmp1 ]
        then
            montarivia=$(cat ${mirrortempdir}/packagespkgid.tmp1 | wc -l)
            if (( ${montarivia} % 2 == 0 ))
            then
                paste -d "#" - - < ${mirrortempdir}/packagespkgid.tmp1 >> ${mirrortempdir}/packagespkgid.tmp2
                cat ${mirrortempdir}/packagespkgid.tmp2 | sort | uniq >> ${mirrortempdir}/packagespkgid.tmp3
                if [ ${downloadmethod} == "rsync" ]
                then
                    for debfile in $(cat ${mirrortempdir}/mirrordownload.tmp | grep "^pool" | egrep "\.deb$")
                    do
                        unset debfilesha256
                        unset sdebfile
                        debfilesha256=$(sha256sum ${mirrordatadir}/${mirrorname}/${debfile} 2> /dev/null | awk -F" " '{print $1}')
                        sdebfile=$(echo ${debfile} | sed 's/\./\\./g;s/\+/\\+/g')
                        if egrep "^${sdebfile}#${debfilesha256}$" ${mirrortempdir}/packagespkgid.tmp3 > /dev/null
                        then
                            echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 verified."
                            # echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 verified. Expected ${sdebfile} - Found ${debfilesha256}."
                        else
                            # echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 check failed." | tee -a ${failed256file}
                            echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 check failed. Expected ${sdebfile} - Found ${debfilesha256}."
                            SHA256checkfailed=1
                            verify256check=1
                        fi
                    done
                elif [ ${downloadmethod} == "http" ]
                then
                    for debfile in $(cat ${mirrortempdir}/mirrordownload.tmp | grep "Getting: pool/" | egrep "\.deb... ok$" | awk -F: '{print $2}' | sed 's/^ //' | sed 's/... ok$//')
                    do
                        unset debfilesha256
                        unset sdebfile
                        debfilesha256=$(sha256sum ${mirrordatadir}/${mirrorname}/${debfile} 2> /dev/null | awk -F" " '{print $1}')
                        sdebfile=$(echo ${debfile} | sed 's/\./\\./g;s/\+/\\+/g')
                        if egrep "^${sdebfile}#${debfilesha256}$" ${mirrortempdir}/packagespkgid.tmp3 > /dev/null
                        then
                            echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 verified."
                            # echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 verified. Expected ${sdebfile} - Found ${debfilesha256}."
                        else
                            # echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 check failed." | tee -a ${failed256file}
                            echo "${mirrordatadir}/${mirrorname}/${debfile} sha256 check failed. Expected ${sdebfile} - Found ${debfilesha256}."
                            SHA256checkfailed=1
                            verify256check=1
                        fi
                    done
                fi
            else
                sanityerror+=("Mirror ${mirrorname} packages meta info invalid/corrupted.")
                code=2
                verify256check=1
            fi
        else
            sanityerror+=("Search base: ${mirrordatadir}/${mirrorname}/dists. Packages file(s) unknown compression. Expected xz or gz.")
            code=2
            verify256check=1
        fi
    fi
    if [ ${verify256check} -eq 0 ]
    then
        touch ${mirrortempdir}/${mirrorname}_sha256scansuccess
        echo "Mirror ${mirrorname} sha256 check OK."
    else
        echo "Mirror ${mirrorname} sha256 check failed."
    fi
fi
fi
}

csnapshot () {
if [ ${mirrorflavor} == "rpm" ]
then
unset maskdestinationtapath
unset repodatapath
unset rpmpath
unset relativemirrorfullpath
unset relativerpmpath
uhjee=0
rpmc=0
if [ -d ${destinationmirrorfullpath}/repodata ]
then
    if [ ! ${section} == "empty" ]
    then
        echo "Creating snapshot Mirror: ${mirrorname} - Version: ${ver} - Repository: ${repo} - Architecture: ${aargh} - Section: ${section} - Daily version: ${daily}"
    else
        echo "Creating snapshot Mirror: ${mirrorname} - Version: ${ver} - Repository: ${repo} - Architecture: ${aargh} - Daily version: ${daily}"
    fi
    rpmc=$(find ${destinationmirrorfullpath} -maxdepth 1 -type f -name "*.rpm" | wc -l)
    if [ ${rpmc} -ne 0 ]
    then
        rpmpath=${destinationmirrorfullpath}
        uhjee=1
    fi
    if [ ${uhjee} -eq 0 ]
    then
        for rpmsearch in $(ls -l "${destinationmirrorfullpath}" | egrep "^d" | awk -F" " '{print $NF}' | egrep -v "^repodata$|^EFI$|^isolinux$|^images$")
        do
            rpmc=$(find "${destinationmirrorfullpath}/${rpmsearch}" -type f -name "*.rpm" | wc -l)
            if [ ${rpmc} -ne 0 ]
            then
                rpmpath="${destinationmirrorfullpath}/${rpmsearch}"
            fi
        done
    fi
    maskdestinationtapath=$(echo "${mirrordatadir}/${mirrorname}/" | sed 's/\//\\\//g')
    relativemirrorfullpath=$(echo ${destinationmirrorfullpath} | sed "s/${maskdestinationtapath}//")
    repodatapath=${destinationmirrorfullpath}/repodata
    relativerpmpath=$(echo ${rpmpath} | sed "s/${maskdestinationtapath}//")
    relativerepodatapath=$(echo ${repodatapath} | sed "s/${maskdestinationtapath}//" | sed "s/repodata//")
    if [ ! -d ${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerepodatapath} ]
    then
        mkdir -p ${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerepodatapath} > /dev/null
    fi
    rsync -a -v ${repodatapath} ${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerepodatapath}/
    if [ ${uhjee} -eq 1 ]
    then
        for linkrpm in $(ls ${rpmpath}/*.rpm)
        do
            rpmfile=$(echo "${linkrpm}" | awk -F/ '{print $NF}')
            sudo ln -s "${linkrpm}" "${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerpmpath}/${rpmfile}"
        done
    elif [ ! -L "${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerpmpath}" ]
    then
       sudo ln -s "${rpmpath}" "${snapshotdir}/${daily}_${hdate}/${mirrorname}/${relativerpmpath}"
    fi
    csnaps=$(echo "${csnaps} + 1" | bc)
fi
elif [ ${mirrorflavor} == "deb" ]
then
if [ ! -d ${snapshotdir}/${daily}_${hdate} ]
then
    mkdir ${snapshotdir}/${daily}_${hdate} > /dev/null
fi
echo "Creating snapshot: ${mirrorname} - Version: ${daily} - Usessl: ${usessl}"
rsync -a -v --exclude pool/ --exclude .temp/ ${mirrordatadir}/${mirrorname} ${snapshotdir}/${daily}_${hdate}/ > /dev/null
if [ ! -L ${snapshotdir}/${daily}_${hdate}/${mirrorname}/pool ]
then
    sudo ln -s ${mirrordatadir}/${mirrorname}/pool ${snapshotdir}/${daily}_${hdate}/${mirrorname}/pool
fi
csnaps=$(echo "${csnaps} + 1" | bc)
fi
}

versionrepoarchsectioncleanup () {
bname="${mirrorname}"
verexclude="-not \( -name "${mirrorname}" \)"
for vver in ${versions}
do
    verexclude="-not \( -name "${vver}" \) ${verexclude}"
done
vcleanm="find ${mirrordatadir}/${bname}/ -maxdepth 1 -type d ${verexclude} -exec sudo rm -rf {} \;"
eval ${vcleanm} > /dev/null 2>&1
vcleans="find ${snapshotdir}/*/${bname} -maxdepth 1 -type d ${verexclude} -exec sudo rm -rf {} \;"
eval ${vcleans} > /dev/null 2>&1
repoexcludes="${verexclude}"
for rrepo in ${repos}
do
    repoexcludes="-not \( -name "${rrepo}" \) ${repoexcludes}"
done
rcleanm="find ${mirrordatadir}/${bname}/ -maxdepth 2 -type d ${repoexcludes} -exec sudo rm -rf {} \;"
eval ${rcleanm} > /dev/null 2>&1
rcleans="find ${snapshotdir}/*/${bname}/ -maxdepth 2 -type d ${repoexcludes} -exec sudo rm -rf {} \;"
eval ${rcleans} > /dev/null 2>&1
archexcludes="${repoexcludes}"
for aaargh in ${arch}
do
    archexcludes="-not \( -name "${aaargh}" \) ${archexcludes}"
done
acleanm="find ${mirrordatadir}/${bname}/ -maxdepth 3 -type d ${archexcludes} -exec sudo rm -rf {} \;"
eval ${acleanm} > /dev/null 2>&1
acleans="find ${snapshotdir}/*/${bname}/ -maxdepth 3 -type d ${archexcludes} -exec sudo rm -rf {} \;"
eval ${acleans} > /dev/null 2>&1
if [ ! "${sections}" == "empty" ]
then
    sectionsexcludes="${archexcludes}"
    for ssection in ${sections}
    do
        sectionsexcludes="-not \( -name "${ssection}" \) ${sectionsexcludes}"
    done
    scleanm="find ${mirrordatadir}/${bname}/ -maxdepth 4 -type d ${sectionsexcludes} -exec sudo rm -rf {} \;"
    eval ${scleanm} > /dev/null 2>&1
    scleans="find ${snapshotdir}/*/${bname}/ -maxdepth 4 -type d ${sectionsexcludes} -exec sudo rm -rf {} \;"
    eval ${scleans} > /dev/null 2>&1
fi
apache2reload=0
nope=$(echo ${snapshotdir} | awk -F/ '{print $NF}')
if [ "${webservice}" == "httpd" ]
then
    for empty in $(find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -print)
    do
        for conf in $(grep ${empty} ${a2sitesavailable}/*.conf | awk -F: '{print $1}')
        do
            sudo rm -f ${conf}
            apache2reload=1
            done
    done
    if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
    find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -delete > /dev/null 2>&1
    mirrorcleanup=1
elif [ "${webservice}" == "apache2" ]
then
    for empty in $(find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -print)
    do
        for conf in $(grep ${empty} ${a2sitesavailable}/*.conf | awk -F: '{print $1}')
        do
            disconf=$(echo ${conf} | awk -F/ '{print $NF}')
            sudo a2dissite ${disconf} > /dev/null
            sudo rm -f ${conf}
            apache2reload=1
        done
    done
    if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
    find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -delete > /dev/null 2>&1
    mirrorcleanup=1
fi
}

snapshotcleanup () {
apache2reload=0
if [ "${webservice}" == "httpd" ]
then
    echo "Cleaning snapshots - ${mirrorname}"
    sudo rm -rf ${snapshotdir}/*/${mirrorname}
    sudo rm -f ${snapshotdir}/Published_snapshots
    nope=$(echo ${snapshotdir} | awk -F/ '{print $NF}')
    for empty in $(find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -print)
    do
        for conf in $(grep ${empty} ${a2sitesavailable}/*.conf | awk -F: '{print $1}')
        do
            sudo rm -f ${conf}
            apache2reload=1
        done
    done
    if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
    sudo find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -delete > /dev/null 2>&1
    echo "Cleaning snapshots - ${mirrorname} .. done"
    snapshotclean=1
elif [ "${webservice}" == "apache2" ]
then
    echo "Cleaning snapshots - ${mirrorname}"
    sudo rm -rf ${snapshotdir}/*/${mirrorname}
    sudo rm -f ${snapshotdir}/Published_snapshots
    nope=$(echo ${snapshotdir} | awk -F/ '{print $NF}')
    for empty in $(find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -print)
    do
        for conf in $(grep ${empty} ${a2sitesavailable}/*.conf | awk -F: '{print $1}')
        do
            disconf=$(echo ${conf} | awk -F/ '{print $NF}')
            sudo a2dissite ${disconf} > /dev/null
            sudo rm -f ${conf}
            apache2reload=1
        done
    done
    if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
    sudo find ${snapshotdir} -maxdepth 1 -type d -not -name ${nope} -empty -delete > /dev/null 2>&1
    echo "Cleaning snapshots - ${mirrorname} .. done"
fi
}

del () {
source ${mirrorconfdir}/${delete}
if [ ${enabled} == "no" ]; then
    echo -e "Deleting mirror ${mirrorname} and related snapshots.\nType yes and press enter to continue or type no and press enter to cancel."
    read -r jees
    case ${jees} in
    yes)
        if [ -d ${mirrordatadir}/${mirrorname} ] && [ -w ${mirrordatadir}/${mirrorname} ]
        then
            snapshotcleanup
            echo "Deleting mirror ${mirrorname}"
            sudo rm -rf ${mirrordatadir}/${mirrorname}
            sudo rm -f ${mirrortempdir}/${mirrorname}_sha256scansuccess_*
            echo "Deleting mirror ${mirrorname} .. done."
        else
            sanityerror+=("${mirrordatadir}/${mirrorname} must be a directory and writable by user.")
            code=2
            sanitycheck
        fi
    ;;
    no)
        sanityerror+=("Deleting mirror ${mirrorname} canceled.")
        code=1
        sanitycheck
    ;;
    *)
        sanityerror+=("Deleting mirror ${mirrorname} aborted.")
        code=2
        sanitycheck
    ;;
    esac
elif [ ${enabled} == "yes" ]
then
    sanityerror+=("In mirror configuration ${delete} enabled is yes. In onder to delete mirror ${mirrorname} enabled need to be set no.")
    code=1
    sanitycheck
fi
}

trydownloadrpmgpg () {
if [ "${downloadmethod}" == "rsync" ]
then
    sudo rsync -a -v --no-motd rsync://${host}/${rootdir}/RPM-GPG-KEY-* ${mirrordatadir}/${mirrorname}/
elif [[ "${downloadmethod}" =~ ${method} ]]
then
    wget -e robots=off --no-check-certificate --cut-dirs=${cdirs} -nH -np -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/RPM-GPG-KEY-*
fi
if [ ${createsnapshot} == "yes" ]
then
    sudo rsync -a -v  ${mirrordatadir}/${mirrorname}/RPM-GPG-KEY-* ${snapshotdir}/${daily}_${hdate}/${mirrorname}/
fi
}

destination () {
cdirs=$(echo "${rootdir}" | tr -d -c '/' | awk '{ print length }')
if [ -z ${cdirs} ]; then cdirs=0; fi
cdirs=$(echo "${cdirs} + 1" | bc)
if [ ! "${section}" == "empty" ]
then
    destinationmirrorfullpath="${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}/${section}"
    sdestination=$(echo ${destinationmirrorfullpath} | sed 's/\///g')
elif [ "${section}" == "empty" ]
then
    destinationmirrorfullpath="${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}"
    sdestination=$(echo ${destinationmirrorfullpath} | sed 's/\///g')
fi
}

updatemirror () {
if [ ${mirrorflavor} == "rpm" ]
then
echo "Global configuration:"
cat ${globalsettings} | egrep -v "^#|^$"
for mconf in $(find ${mirrorconfdir}/ -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$")
do
    unset arch
    unset host
    unset rootdir
    unset verifysha256
    unset mirrorname
    unset downloadmethod
    unset repos
    unset sections
    unset enabled
    unset createsnapshot
    unset mirrorsyncexclude
    unset mrrsyncexclude
    unset monthlycleanupday
    unset versions
    unset trydownloadrpmgpgkeys
    source ${mconf}
    if [ ${enabled} == "yes" ]
    then
        echo "Mirror ${mirrorname} configuration:"
        cat ${mconf} | egrep -v "^#|^$"
        echo "Log: ${logdir}/${logname}"
        rootdir=$(echo ${rootdir} | sed 's/^\///;s/\/$//')
        mupdateerror=0
        needed=0
        snapshotclean=0
        mirrorcleanup=0
        monthlycleanupdaycheck
        rm -fr ${snapshotdir}/${daily}_${hdate}/${mirrorname} > /dev/null
        for ver in ${versions}
        do
            for repo in ${repos}
            do
                for aargh in ${arch}
                do
                    for section in ${sections}
                    do
                        unset destinationmirrorfullpath
                        unset mirrorupdatenocleanup
                        unset mirrorupdatecleanup
                        mrexclude
                        destination
                        metadatastatus=1
                        verify256check=0
                        mirrorupdate=0
                        tagdate=$(date +%s)
                        tagi="tag${tagdate}"
                        if [ ! -z "${mrrsyncexclude}" ] && [ ! "${section}" == "empty" ] && [ "${downloadmethod}" == "rsync" ]
                        then
                            mirrorupdatenocleanup="eval sudo rsync -a -v ${mrrsyncexclude} --no-motd rsync://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}/"
                            mirrorupdatecleanup="eval sudo rsync -a -v ${mrrsyncexclude} --no-motd --delete rsync://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}/"
                        elif [ -z "${mrrsyncexclude}" ] && [ ! "${section}" == "empty" ] && [ "${downloadmethod}" == "rsync" ]
                        then
                            mirrorupdatenocleanup="eval sudo rsync -a -v --no-motd rsync://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}/"
                            mirrorupdatecleanup="eval sudo rsync -a -v --no-motd --delete rsync://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}/"
                        elif [ ! -z "${mrrsyncexclude}" ] && [ "${section}" == "empty" ] && [ "${downloadmethod}" == "rsync" ]
                        then
                            mirrorupdatenocleanup="eval sudo rsync -a -v ${mrrsyncexclude} --no-motd rsync://${host}/${rootdir}/${ver}/${repo}/${aargh} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}"
                            mirrorupdatecleanup="eval sudo rsync -a -v ${mrrsyncexclude} --no-motd --delete rsync://${host}/${rootdir}/${ver}/${repo}/${aargh} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}"
                        elif [ -z "${mrrsyncexclude}" ] && [ "${section}" == "empty" ] && [ "${downloadmethod}" == "rsync" ]
                        then
                            mirrorupdatenocleanup="eval sudo rsync -a -v --no-motd rsync://${host}/${rootdir}/${ver}/${repo}/${aargh} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}"
                            mirrorupdatecleanup="eval sudo rsync -a -v --no-motd --delete rsync://${host}/${rootdir}/${ver}/${repo}/${aargh} ${mirrordatadir}/${mirrorname}/${ver}/${repo}/${aargh}"
                        elif [[ ! -z "${mrrsyncexclude}" && ! "${section}" == "empty" && "${downloadmethod}" =~ ${method} ]]
                        then
                            mirrorupdatenocleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N ${mrrsyncexclude} -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section}/"
                            mirrorupdatecleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N ${mrrsyncexclude} -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section}/"
                        elif [[ -z "${mrrsyncexclude}" && ! "${section}" == "empty" && "${downloadmethod}" =~ ${method} ]]
                        then
                            mirrorupdatenocleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section}/"
                            mirrorupdatecleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/${section}/"
                        elif [[ ! -z "${mrrsyncexclude}" && "${section}" == "empty" && "${downloadmethod}" =~ ${method} ]]
                        then
                            mirrorupdatenocleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N ${mrrsyncexclude} -r -P ${mirrordatadir}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/"
                            mirrorupdatecleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N ${mrrsyncexclude} -r -P ${mirrordatadir}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/"
                        elif [[ -z "${mrrsyncexclude}" && "${section}" == "empty" && "${downloadmethod}" =~ ${method} ]]
                        then
                            mirrorupdatenocleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs} -nH -np -N -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/"
                            mirrorupdatecleanup="eval wget -e robots=off -a ${logdir}/${logname} --no-check-certificate --cut-dirs=${cdirs}-nH -np -N -r -P ${mirrordatadir}/${mirrorname}/ ${downloadmethod}://${host}/${rootdir}/${ver}/${repo}/${aargh}/"
                        fi
                        mupdateerror=0
                        unset mversionpath
                        unset rrepodatapath
                        if [ ! -d ${destinationmirrorfullpath} ]; then mkdir -p ${destinationmirrorfullpath}; fi
                        if [ -z ${monthlycleanupday} ]; then
                            echo "Update Mirror: ${mirrorname} - Version: ${ver} - Repository: ${repo} - Architecture: ${aargh} - Section: ${section} - Nocleanup - Create snapshot: ${createsnapshot}"
                            echo "Cmd: ${mirrorupdatenocleanup}"
                            echo "a${tagi}a" >> ${logdir}/${logname}
                            rrepodatapath=$(find ${destinationmirrorfullpath} -type d -name repodata)
                            if [ ! -z ${rrepodatapath} ]; then sudo rm -f ${rrepodatapath}/*; fi
                            ${mirrorupdatenocleanup}
                            if [ $? -ne 0 ]; then mirrorupdate=1; fi
                            mirrorupdatereturncode
                            echo "b${tagi}b" >> ${logdir}/${logname}
                            find ${mirrordatadir} -type f -name "index.htm*" -exec sudo rm -f {} \;
                            if [ ${mupdateerror} -eq 1 ]
                            then
                                find ${mirrordatadir}/${mirrorname}/ -type d -not \( -name "repodata" \) -not \( -name "${mirrorname}" \) -empty -exec sudo rm -fr {} \;
                                continue
                            fi
                            if [ ${mirrorcleanup} -eq 0 ]; then versionrepoarchsectioncleanup; fi
                            if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]
                            then 
                                getmetadata
                                verify256
                            fi
                        fi
                        if [ ! -z ${monthlycleanupday} ]; then
                            if [ ${nday} -ne ${monthlycleanupday} ]; then
                                echo "Update Mirror: ${mirrorname} - Version: ${ver} - Repository: ${repo} - Architecture: ${aargh} - Section: ${section} - Nocleanup - Create snapshot: ${createsnapshot}"
                                echo "Cmd: ${mirrorupdatenocleanup}"
                                echo "a${tagi}a" >> ${logdir}/${logname}
                                rrepodatapath=$(find ${destinationmirrorfullpath} -type d -name repodata)
                                if [ ! -z ${rrepodatapath} ]; then sudo rm -f ${rrepodatapath}/*; fi
                                ${mirrorupdatenocleanup}
                                if [ $? -ne 0 ]; then mirrorupdate=1; fi
                                mirrorupdatereturncode
                                echo "b${tagi}b" >> ${logdir}/${logname}
                                find ${mirrordatadir} -type f -name "index.htm*" -exec sudo rm -f {} \;
                                if [ ${mupdateerror} -eq 1 ]
                                then
                                    find ${mirrordatadir}/${mirrorname}/ -type d -not \( -name "repodata" \) -not \( -name "${mirrorname}" \) -empty -exec sudo rm -fr {} \;
                                    continue
                                fi
                                if [ ${mirrorcleanup} -eq 0 ]; then versionrepoarchsectioncleanup; fi
                                if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]
                                then
                                    getmetadata
                                    verify256
                                fi
                            elif [ ${nday} -eq ${monthlycleanupday} ]; then
                                echo "Update Mirror: ${mirrorname} - Version: ${ver} - Repository: ${repo} - Architecture: ${aargh} - Section: ${section} - Cleanup - Create snapshot: ${createsnapshot}"
                                if [ ${snapshotclean} -eq 0 ]; then snapshotcleanup; fi
                                echo "Cmd: ${mirrorupdatecleanup}"
                                echo "a${tagi}a" >> ${logdir}/${logname}
                                rrepodatapath=$(find ${destinationmirrorfullpath} -type d -name repodata)
                                if [ ! -z ${rrepodatapath} ]; then sudo rm -f ${rrepodatapath}/*; fi
                                ${mirrorupdatecleanup}
                                if [ $? -ne 0 ]; then mirrorupdate=1; fi
                                mirrorupdatereturncode
                                echo "b${tagi}b" >> ${logdir}/${logname}
                                find ${mirrordatadir} -type f -name "index.htm*" -exec sudo rm -f {} \;
                                if [ ${mupdateerror} -eq 1 ]
                                then
                                    find ${mirrordatadir}/${mirrorname}/ -type d -not \( -name "repodata" \) -not \( -name "${mirrorname}" \) -empty -exec sudo rm -fr {} \;
                                    continue
                                fi
                                if [ ${mirrorcleanup} -eq 0 ]; then versionrepoarchsectioncleanup; fi
                                if [[ ${downloadmethod} =~ ${method} ]]
                                then
                                    getmetadata
                                    ifhttpdownloadrpmcleanup
                                fi
                                if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]
                                then
                                    getmetadata
                                    verify256
                                fi
                            fi
                        fi
                        report+=("Updated_Mirror:${mirrorname} Repository:${repo} Version:${ver} Architecture:${aargh} Section:${section} Create_snapshot:${createsnapshot}")
                        if [ ${createsnapshot} == "yes" ]
                        then
                            csnapshot
                        fi
                    done
                done
            done
        done
        if [ ${usessl} == "no" ]
        then
            mainurls+=("Mirror ${mirrorname} main URL http://${mainsitename}.${domain}/${mirrorname}")
        elif [ ${usessl} == "yes" ]
        then
            mainurls+=("Mirror ${mirrorname} main URL https://${mainsitename}.${domain}/${mirrorname}")
        elif [ ${usessl} == "both" ]
        then
            mainurls+=("Mirror ${mirrorname} main URL http://${mainsitename}.${domain}/${mirrorname}")
            mainurls+=("Mirror ${mirrorname} main URL https://${mainsitename}.${domain}/${mirrorname}")
        fi
        if [ ${mupdateerror} -eq 0 ] && [ ${createsnapshot} == "yes" ]
        then
            cmirrorname+=(${mirrorname})
        fi
        if [ ${mupdateerror} -eq 0 ]
        then
            timestamps
            if [ "${trydownloadrpmgpgkeys}" == "yes" ]
            then
                trydownloadrpmgpg
            fi
        fi
    else
        echo "Mirror configuration: ${mconf} disabled."
    fi
done
for troper in ${report[@]}; do echo ${troper}; done
for ((i = 0; i < ${#mainurls[@]}; i++)); do echo "${mainurls[$i]}"; done
elif [ ${mirrorflavor} == "deb" ]
then
echo "Global configuration:"
cat ${globalsettings} | egrep -v "^#|^$"
for mconf in $(find ${mirrorconfdir}/ -maxdepth 1 -type f -name "${mirrorconffiles}" | egrep "\.mconf$")
do
    unset arch
    unset section
    unset host
    unset dist
    unset rootdir
    unset mirrorname
    unset downloadmethod
    unset enabled
    unset createsnapshot
    unset debmirroroptions
    unset monthlycleanupday
    source ${mconf}
    if [ ${enabled} == "yes" ]
    then
        echo "Mirror ${mirrorname} configuration:"
        cat ${mconf} | egrep -v "^#|^$"
        echo "Log: ${logdir}/${logname}"
        unset tagi
        mirrorupdate=0
        updateerror=0
        verify256check=0
        monthlycleanupdaycheck
        tagdate=$(date +%s)
        tagi="tag${tagdate}"
        rm -fr ${snapshotdir}/${hdate}/${mirrorname}
        if [[ "${downloadmethod}" == "rsync" && "${debmirroroptions}" != "no" ]]
        then
            mirrorupdatenocleanup="eval debmirror -a ${arch} -v ${debmirroroptions} --nocleanup -s ${section} -h ${host} -d ${dist} -r ${rootdir} -e rsync ${mirrordatadir}/${mirrorname}"
            mirrorupdatecleanup="eval debmirror -a ${arch} -v ${debmirroroptions} -s ${section} -h ${host} -d ${dist} -r ${rootdir} -e rsync ${mirrordatadir}/${mirrorname}"
        elif [[ "${downloadmethod}" == "rsync" && "${debmirroroptions}" == "no" ]]
        then
            mirrorupdatenocleanup="eval debmirror -a ${arch} -v --nocleanup -s ${section} -h ${host} -d ${dist} -r ${rootdir} -e rsync ${mirrordatadir}/${mirrorname}"
            mirrorupdatecleanup="eval debmirror -a ${arch} -v -s ${section} -h ${host} -d ${dist} -r ${rootdir} -e rsync ${mirrordatadir}/${mirrorname}"
        elif [[ "${downloadmethod}" == "http" && "${debmirroroptions}" != "no" ]]
        then
            mirrorupdatenocleanup="eval debmirror -a ${arch} -v ${debmirroroptions} --nocleanup -s ${section} -h ${host} -d ${dist} -r ${rootdir} --method=http ${mirrordatadir}/${mirrorname}"
            mirrorupdatecleanup="eval debmirror -a ${arch} -v ${debmirroroptions} -s ${section} -h ${host} -d ${dist} -r ${rootdir} --method=http ${mirrordatadir}/${mirrorname}"
        elif [[ "${downloadmethod}" == "http" && "${debmirroroptions}" == "no" ]]
        then
            mirrorupdatenocleanup="eval debmirror -a ${arch} -v --nocleanup -s ${section} -h ${host} -d ${dist} -r ${rootdir} --method=http ${mirrordatadir}/${mirrorname}"
            mirrorupdatecleanup="eval debmirror -a ${arch} -v -s ${section} -h ${host} -d ${dist} -r ${rootdir} --method=http ${mirrordatadir}/${mirrorname}"
        fi
        if [ -z ${monthlycleanupday} ]
        then
            echo "Update ${mirrorname}: ${dist} - Nocleanup - Create snapshot: ${createsnapshot} - Usessl: ${usessl}"
            echo "Cmd: ${mirrorupdatenocleanup}"
            echo "a${tagi}a" >> ${logdir}/${logname}
            ${mirrorupdatenocleanup}
            if [ $? -ne 0 ]; then mirrorupdate=1; fi
            mirrorupdatereturncode
            echo "b${tagi}b" >> ${logdir}/${logname}
            if [ ${updateerror} -ne 0 ]; then continue; fi
            if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]; then verify256; fi
            report+=("Updated_mirror: Distribution:${dist} Section:${section} Architecture:${arch} Host:${host} Debmirror_options: ${debmirroroptions} Create_snapshot:${createsnapshot}")
            if [ ${createsnapshot} == "yes" ]
            then
                cmirrorname+=(${mirrorname})
                csnapshot
            fi
        fi
        if [ ! -z ${monthlycleanupday} ]
        then
            if [ ${nday} -ne ${monthlycleanupday} ]
            then
                echo "Update ${mirrorname}: ${dist} - Nocleanup - Create snapshot: ${createsnapshot} - Usessl: ${usessl}"
                echo "Cmd: ${mirrorupdatenocleanup}"
                echo "a${tagi}a" >> ${logdir}/${logname}
                ${mirrorupdatenocleanup}
                if [ $? -ne 0 ]; then mirrorupdate=1; fi
                mirrorupdatereturncode
                echo "b${tagi}b" >> ${logdir}/${logname}
                if [ ${updateerror} -ne 0 ]; then continue; fi
                if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]; then verify256; fi
                report+=(Updated_mirror: Distribution:${dist} Section:${section} Architecture:${arch} Host:${host} Destination_directory:${mirrordatadir}/${mirrorname} Root_directory:${rootdir} Debmirror_options: ${debmirroroptions})
                if [ ${createsnapshot} == "yes" ]
                then
                    cmirrorname+=(${mirrorname})
                    csnapshot
                fi
            elif [ ${nday} -eq ${monthlycleanupday} ]
            then
                echo "Update ${mirrorname}: ${dist} - Cleanup - Create snapshot: ${createsnapshot} - Usessl: ${usessl}"
                snapshotcleanup
                echo "Cmd: ${mirrorupdatecleanup}"
                echo "a${tagi}a" >> ${logdir}/${logname}
                ${mirrorupdatecleanup}
                if [ $? -ne 0 ]; then mirrorupdate=1; fi
                mirrorupdatereturncode
                echo "b${tagi}b" >> ${logdir}/${logname}
                if [ ${updateerror} -ne 0 ]; then continue; fi
                if [ ${verifysha256} == "yes" ] || [ ${verifysha256} == "force" ]; then verify256; fi
                report+=(Updated_mirror: Distribution:${dist} Section:${section} Architecture:${arch} Host:${host} Destination_directory:${mirrordatadir}/${mirrorname} Root_directory:${rootdir} Debmirror_options: ${debmirroroptions})
                if [ ${createsnapshot} == "yes" ]
                then
                    cmirrorname+=(${mirrorname})
                    csnapshot
                fi
            fi
        fi
    else
        echo "Mirror configuration: ${mconf} disabled."
    fi
    mainurls+=("//${mainsitename}.${domain}/${mirrorname}")
done
for troper in ${report[@]}; do echo ${troper}; done
if [ ${usessl} == "no" ]
then
    for ((i = 0; i < ${#mainurls[@]}; i++)); do echo "Mirror ${mirrorname} main URL http:${mainurls[$i]}"; done
elif [ ${usessl} == "yes" ]
then
    for ((i = 0; i < ${#mainurls[@]}; i++)); do echo "Mirror ${mirrorname} main URL https:${mainurls[$i]}"; done
elif [ ${usessl} == "both" ]
then
    for ((i = 0; i < ${#mainurls[@]}; i++)); do echo "Mirror ${mirrorname} main URL http:${mainurls[$i]}"; done
    for ((i = 0; i < ${#mainurls[@]}; i++)); do echo "Mirror ${mirrorname} main URL https:${mainurls[$i]}"; done
fi
fi
}

ussl () {
if [ ${usessl} == "yes" ]
then
    ausessl=(yes)
elif [ ${usessl} == "no" ]
then
    ausessl=(no)
elif [ ${usessl} == "both" ]
then
    ausessl=(yes no)
fi
}

cleanpublishedifoldexist () {
apache2reload=0
causessl=(yes no)
if [ ${webservice} == "httpd" ]
then
    for usessla in ${causessl[@]}
    do
        if [ -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf ]
        then
            if ! grep "${snapshotdir}/${daily}_${hdate}" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf > /dev/null
            then
                sudo rm -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
                apache2reload=1
            fi
        fi
    done
elif [ ${webservice} == "apache2" ]
then
    for usessla in ${causessl[@]}
    do
        if [ -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf ]
        then
            if ! grep "${snapshotdir}/${daily}_${hdate}" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf > /dev/null
            then
                sudo a2dissite ${daily}.${domain}.${usessla}.conf > /dev/null
                sudo rm -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
                apache2reload=1
            fi
        fi
    done
fi
if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
}

publishsnapshot () {
snapshotdirdumdidum=$(echo ${snapshotdir} | sed 's/\//\\\//g')
a2logdirdumdidum=$(echo ${a2logpath} | sed 's/\//\\\//g')
apache2reload=0
if [ ${webservice} == "httpd" ]
then
    for usessla in ${ausessl[@]}
    do
        if [ ${usessla} == "no" ]
        then
            vhosttemplate="${mirrorconfdir}/vhost.sslno"
            if ! [ -f ${vhosttemplate} ]
            then
                code=2
                sanityerror+=("File ${vhosttemplate} does not exist.")
                sanitycheck
            fi
        elif [ ${usessla} == "yes" ]
        then
            vhosttemplate="${mirrorconfdir}/vhost.sslyes"
            if ! [ -f ${vhosttemplate} ]
            then
                code=2
                sanityerror+=("File ${vhosttemplate} does not exist.")
                sanitycheck
            fi
        fi
        if ! [ -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf ]
        then
            sudo rsync -v ${vhosttemplate} ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf > /dev/null
            sudo sed -i "s/muutaServerName/ServerName ${daily}.${domain}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/muutaDocumentRoot/DocumentRoot ${snapshotdirdumdidum}\/${daily}_${hdate}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/muutaDoc/${snapshotdirdumdidum}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/version/${daily}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/apache2logpath/${a2logdirdumdidum}/g" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            apache2reload=1
        fi
    done
elif [ ${webservice} == "apache2" ]
then
    for usessla in ${ausessl[@]}
    do
        if [ ${usessla} == "no" ]
        then
            vhosttemplate="${mirrorconfdir}/vhost.sslno"
            if [ ! -f ${vhosttemplate} ]
            then
                code=2
                sanityerror+=("File ${vhosttemplate} does not exist.")
                sanitycheck
            fi
        elif [ ${usessla} == "yes" ]
        then
            vhosttemplate="${mirrorconfdir}/vhost.sslyes"
            if [ ! -f ${vhosttemplate} ]
            then
                code=2
                sanityerror+=("File ${vhosttemplate} does not exist.")
                sanitycheck
            fi
        fi
        if [ ! -f ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf ]
        then
            sudo rsync -v ${vhosttemplate} ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf > /dev/null
            sudo sed -i "s/muutaServerName/ServerName ${daily}.${domain}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            snapshotdirdumdidum=$(echo ${snapshotdir} | sed 's/\//\\\//g')
            sudo sed -i "s/muutaDocumentRoot/DocumentRoot ${snapshotdirdumdidum}\/${daily}_${hdate}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/muutaDoc/${snapshotdirdumdidum}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/version/${daily}/" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i "s/apache2logpath/${a2logdirdumdidum}/g" ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo sed -i '/DocumentRoot /a IndexOptions FancyIndexing HTMLTable VersionSort NameWidth=* SuppressLastModified SuppressDescription' ${a2sitesavailable}/${daily}.${domain}.${usessla}.conf
            sudo a2ensite ${daily}.${domain}.${usessla}.conf > /dev/null
            apache2reload=1
        fi
    done
fi
if [ ${apache2reload} -eq 1 ]; then sudo systemctl reload ${webservice}; fi
}

printsnapshoturl () {
echo "Daily snapshot URL:"
for mname in ${cmirrorname[@]}
do
    check="${daily}.${domain}/${mname}"
    for usessla in ${ausessl[@]}
    do
        if [ ${usessla} == "no" ]
        then
            snaps+=("http://${check}")
        elif [ ${usessla} == "yes" ]
        then
            snaps+=("https://${check}")
        elif [ ${usessla} == "both" ]
        then
            snaps+=("http://${check}")
            snaps+=("https://${check}")
        fi
    done
done
for naps in ${snaps[@]}
do
    echo "${naps}"
done
rm -f ${snapshotdir}/Published_snapshots
touch ${snapshotdir}/Published_snapshots
for publ in $(ls ${a2sitesavailable} | grep "^[1-5]" | egrep ".${domain}.*conf$" | egrep "yes.conf$|no.conf$")
do
    dpubl=$(echo ${publ} | awk -F. '{print $1}')
    spubl=$(echo ${publ} | awk -F. '{print $(NF-1)}')
    if [ ${spubl} == "yes" ]
    then
        dailyname=$(grep DocumentRoot ${a2sitesavailable}/${publ} | awk -F/ '{print $NF}')
        echo "https://${dpubl}.${domain}/ -> ${dailyname}" >> ${snapshotdir}/Published_snapshots
    elif [ ${spubl} == "no" ]
    then
        dailyname=$(grep DocumentRoot ${a2sitesavailable}/${publ} | awk -F/ '{print $NF}')
        echo "http://${dpubl}.${domain}/  -> ${dailyname}" >> ${snapshotdir}/Published_snapshots
    fi
done
if [ ${usessla} == "no" ]
then
    echo "Published snapshots:"
    echo "http://${allsnapshotssitename}.${domain}/Published_snapshots"
    echo "All snapshots:"
    echo "http://${allsnapshotssitename}.${domain}/"
elif [ ${usessla} == "yes" ]
then
    echo "Published snapshots:"
    echo "https://${allsnapshotssitename}.${domain}/Published_snapshots"
    echo "All snapshots:"
    echo "https://${allsnapshotssitename}.${domain}/"
elif [ ${usessla} == "both" ]
then
    echo "Published snapshots:"
    echo "http://${allsnapshotssitename}.${domain}/Published_snapshots"
    echo "https://${allsnapshotssitename}.${domain}/Published_snapshots"
    echo "All snapshots:"
    echo "http://${allsnapshotssitename}.${domain}/"
    echo "https://${allsnapshotssitename}.${domain}/"
fi
}

mustg
mustdoru
mustnotdu
mustdm
mustum
websrvkeepalive
checksoftware
sourceglobal
globalsettingscheck
chechttp
whattodo
dailyversion

action () {
if [ ${what} == "update" ]
then
    startlog
    mirrorconffilescheck
    updatemirror
    ussl
    if [ ${csnaps} -gt 0 ]
    then
        cleanpublishedifoldexist
        publishsnapshot
        printsnapshoturl
    fi
    if [ ${SHA256checkfailed} -eq 1 ]
    then
        sanityerror+=("SHA256 check failed.")
        code=2
        for ffile in $(find ${mirrortempdir} -maxdepth 1 -type f -name "failed256file_*")
        do
            echo "SHA256 check failed:${ffile}"
            cat ${ffile}
        done
    fi
    sanitycheck
    logend
elif [ ${what} == "delete" ]
then
    startlog
    mirrorconffilescheck
    del
    logend
fi
}

action | tee -a ${logdir}/${logname}
