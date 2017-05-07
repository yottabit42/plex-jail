#!/bin/sh
#
# This script installs Plex Media Server and moves the configuration files to
# $configDir. The user specified $configDir by prompt, as well as whether a
# Plex Pass is subscribed. Some minimal checks are performed and some minimal
# safeguards are implemented. Should any part of the script fail, hopefully it
# will just exit and leave the mess for the user to correct.
#
# Customization of the paths in this script are expected to be performed by the
# user.
#
# Also available in a convenient Google Doc:
# https://docs.google.com/document/d/1LSr3J6hdnCDQHfiH45K3HMvEqzbug7GeUeDa_6b_Hhc
#
# Jacob McDonald
# Revision 170422a-yottabit

configDir=$(dialog --no-lines --stdout --inputbox "Persistent storage is:" \
0 0 /config) || exit

if [ -d "/$configDir" ] ; then
  echo "$configDir exists, like a boss!"
else
  echo "$configDir does not exist, so exiting (you might want to link a dataset)."
  exit
fi

if dialog --no-lines --yesno "Do you have a Plex Pass subscription?" 0 0 ; then
  echo "Plex Pass selected! You rock!"
  plexTrain="plexmediaserver-plexpass"
else
  echo "Regular Plex selected."
  plexTrain="plexmediaserver"
fi

service plexmediaserver_plexpass stop
service plexmediaserver stop

/usr/sbin/pkg update || exit
/usr/sbin/pkg upgrade --yes || exit
/usr/sbin/pkg install --yes $plexTrain || exit
/usr/sbin/pkg clean --yes || exit

[ ! -d "/$configDir/$plexTrain" ] && \
cp -R "/usr/local/share/$plexTrain" "/$configDir/." || exit
rm -R "/usr/local/share/$plexTrain/" || exit
ln -s "/$configDir/$plexTrain" "/usr/local/share/$plexTrain" || exit

if [ "$plexTrain" = "plexmediaserver-plexpass" ] ; then
  sysrc plexmediaserver_plexpass_enable=YES || exit
  service plexmediaserver_plexpass start || exit
else
  sysrc plexmediaserver_enable=YES || exit
  service plexmediaserver start || exit
fi

ip="`ifconfig | grep -v 127.0.0.1 | sed -n '/.inet /{s///;s/ .*//;p;}'`:32400/web"
echo "You should be able to start configuration of Plex on: $ip"
echo "Default uid:gid for Plex is 972:972. You may need to adjust manually if\
you are having permissions problems to your linked in media dataset(s)"
