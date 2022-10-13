#!/bin/sh
# FILE: "check_AIM"
# DESCRIPTION: Check Adder AIM manager status
# REQUIRES: snmpget
# AUTHOR: Toni Comerma
# DATE: oct-2022


BASEOID=.1.3.6.1.4.1.25119.1.3
serverCPULoadOID=$BASEOID.1.0
serverMemoryUsageOID=$BASEOID.2.0
serverSoftwareVersionOID=$BASEOID.3.0
serverDiskSpaceOID=$BASEOID.4.0

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

print_usage() {
	echo "Usage: $0 -H host -u username -p password -m CPU|MEM|DISK -w xx -c yy"
    echo "   Works only with SNMPv3, MD5/DES"
	exit $STATE_UNKNOWN
}


if test "$1" = -h; then
	print_usage
fi

IGNORE_WARNING=0
while getopts "H:u:p:m:w:c:" o; do
	case "$o" in
	H )
		HOST="$OPTARG"
		;;
	u )
		USERNAME="$OPTARG"
		;;
	p )
		PASSWORD="$OPTARG"
		;;
	m )
		MEASUREMENT="$OPTARG"
		;;
	w )
		WARNING="$OPTARG"
		;;
	c )
		CRITICAL="$OPTARG"
		;;

	* )
		print_usage
		;;
	esac
done

# Parameters verification

# Check username and password
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "ERROR: Must specify -u and -p"
    print_usage
fi

# Check measurement
if [ -z "$MEASUREMENT" ] ; then
    echo "ERROR: Must specify -m CPU|MEM|DISK"
    print_usage
fi

# Check host
if [ -z "$HOST" ] ; then
    echo "ERROR: Must specify -H"
    print_usage
fi
case $MEASUREMENT in
    MEM) MEASUREMENT=$serverMemoryUsageOID
         NAME="Memory"
         ;;
    CPU) MEASUREMENT=$serverCPULoadOID
         NAME="CPU"
         ;;
    DISK) MEASUREMENT=$serverDiskSpaceOID
          NAME="Disk"
          ;;
    *) echo "invalid -m value"
       print_usage
        ;;
esac

STATE=$STATE_OK

# Get version number
VERSION=`snmpget -v 3 -u $USERNAME -a MD5 -x DES -A $PASSWORD  -X $PASSWORD -l authPriv -On $HOST $serverSoftwareVersionOID 2>&1`
if [ $? -ne 0 ]; then
    echo "CRITICAL: Error connecting $HOST. $VERSION"
    exit $STATE_CRITICAL
fi
VERSION=`echo $VERSION | cut -f2 -d '"'`

# Get measurement
M=`snmpget -v 3  -u $USERNAME -a MD5 -x DES -A $PASSWORD  -X $PASSWORD -l authPriv -On $HOST $MEASUREMENT 2>&1`
if [ $? -ne 0 ]; then
    echo "CRITICAL: Error connecting $HOST. $M"
    exit $STATE_CRITICAL
fi
M=`echo $M | cut -f2 -d '"'`

M_INT=`echo $M | awk '{print int($1)}'`

# check range

if [ ! -z "$CRITICAL" ]; then
    if [ $M_INT -gt $CRITICAL ]; then
       echo "CRITICAL: $HOST version $VERSION: $NAME over $M | $NAME=$M"
       exit $STATE_CRITICAL
    fi
fi
if [ ! -z "$WARNING" ]; then
   if [ $M_INT -gt $WARNING ]; then
       echo "WARNING: $HOST version $VERSION: $NAME over $M | $NAME=$M"
       exit $STATE_WARNING
    fi
fi

echo "OK: $HOST version $VERSION: $NAME at $M | $NAME=$M"
exit $STATE_OK