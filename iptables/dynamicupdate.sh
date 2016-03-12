#!/usr/bin/env bash
IPT=/usr/sbin/iptables

#Dynamic hostname
HOSTNAME=<REDACTED>

#storing ip
IPLOG=/var/log/myip.log
LASTIP=$(cat $IPLOG)

#check ip for dynamic dns entry ensure you have bind-utils installed
CURRENTIP=$(host $HOSTNAME | grep -iE "[1-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)

#check to see if this is the first run, and insert ip. if ip hasnt changed then exit
if [ "$LASTIP" = "" ] ; then
   $IPT -I home -s $CURRENTIP -j ACCEPT
   echo $CURRENTIP > $IPLOG
   echo $CURRENTIP added to iptables
else
   if [ "$CURRENTIP" = "$LASTIP" ] ; then
   echo IP still the same no action
#if ip doesnt match flush the home chain and insert new rule based on new ip
   else
     $IPT -F home
     $IPT -I home -s $CURRENTIP -j ACCEPT
     echo $CURRENTIP > $IPLOG
     echo new ip added
   fi
fi
