# check_aim
Nagios plugin for Adder Infinity Manager (AIM)
Uses SNMP. MIB available at https://<IP>/AIM-MIB.txt

## Author
Toni Comerma

## Usage
check_AIM.sh -H host -u username -p password -m CPU|MEM|DISK -w xx -c yy

   - CPU: checks CPU usage. According to documentation: "Load average over the last minute ('0.00' to '100.00', where '8.00' is fully loaded)"
   - MEM % of memory usage
   - DISK: % of system disk usage (does not monitor backup partition)
Returns performance data.

## Limitations
Works only with SNMP v3 MD5/DES