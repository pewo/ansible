#!/bin/sh

PATH=/usr/bin:/bin
ME=$0
SCRIPTDIR="`dirname $ME`"
EXTENSION="cer"
#TEMPDIR="`mktemp --director`"
TEMPDIR=/tmp/bepa
INVENTORY=$TEMPDIR/inventory
HOSTEXTENSION="-rm"

extract() {
	echo "Testing ${ZIPFILE}"
	unzip -t ${ZIPFILE}
	RC=$?
	echo "RC: $RC"
	if [ $RC -ne 0 ]; then
		exit
	fi

	echo "Extracting $ZIPFILE to ${TEMPDIR}"
	unzip -o -j $ZIPFILE *.${EXTENSION}  -d ${TEMPDIR}
	RC=$?
	echo "RC: $RC"
	if [ $RC -ne 0 ]; then
		exit
	fi
}

build_inventory() {
	rm -f $INVENTORY
	echo "[cert]" >> $INVENTORY
	for cert in `zipinfo -1 $ZIPFILE *.${EXTENSION}`; do
		host=`echo $cert | sed -e "s/${HOSTEXTENSION}//" -e "s/\.${EXTENSION}//"`
		echo "cert: $cert, host: $host"
		echo "$host certfile=$TEMPDIR/$cert" >> $INVENTORY
		HOSTVARS=$TEMPDIR/host_vars
		mkdir -p $HOSTVARS
		HOSTVAR=$HOSTVARS/$host
		rm -f $HOSTVAR
		cat $TEMPDIR/$cert \
			| awk 'BEGIN { 
					printf("cert: |\n")
				} 
				{ 
					printf("  %s\n",$0)
				}' \
			>> $HOSTVAR
	done
}

usage() { 
	echo "Usage: $0 [-z <zipfile> -p <playbook> -a <ansible-playbook-executable> ]" 1>&2
       	exit 1
}

ZIPFILE=""
PLAYBOOK=""
ANSIBLE=""
while getopts "a:p:z:" o; do
    case "${o}" in
	a)
	    ANSIBLE=${OPTARG}
	    ;;
        p)
	    PLAYBOOK=${OPTARG}
	    ;;
        z)
            ZIPFILE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${ZIPFILE}" ]; then
	echo "Missing zipfile (-z)"
    	usage
fi

if [ ! -r "${ZIPFILE}" ]; then
	cat ${ZIPFILE}
	usage
fi

if [ -z "${PLAYBOOK}" ]; then
	echo "Missing playbook (-p)"
	usage
fi

if [ -z "${ANSIBLE}" ]; then
	ANSIBLE="ansible-playbook"
fi

extract
build_inventory

echo "$ANSIBLE $PLAYBOOK -i $INVENTORY"
