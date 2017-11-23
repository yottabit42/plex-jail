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
# Revision 171123d-yottabit
#
# Licensed under BSD-3-Clause, the Modified BSD License

configDir=$(dialog --no-lines --stdout --inputbox "Persistent storage is:" \
0 0 /config) || exit

if [ -d "$configDir" ] ; then
  echo "$configDir exists, like a boss!"
else
  echo "$configDir does not exist, so exiting (you might want to link a dataset)."
  exit
fi

if dialog --no-lines --yesno "Do you have a Plex Pass subscription?" 0 0 ; then
  echo "Plex Pass selected! You rock!"
  plexTrain="plexmediaserver-plexpass"
  plexData="plexdata-plexpass"
else
  echo "Regular Plex selected."
  plexTrain="plexmediaserver"
  plexData="plexdata"
fi

service plexmediaserver_plexpass stop
service plexmediaserver stop
pkill -fl Plex

/usr/sbin/pkg update
/usr/sbin/pkg upgrade --yes
/usr/sbin/pkg install --yes $plexTrain
/usr/sbin/pkg clean --yes

if [ ! -d "$configDir/$plexTrain" ] ; then
  mv -v "/usr/local/share/$plexTrain" "$configDir/." || exit
  ln -s "$configDir/$plexTrain" "/usr/local/share/$plexTrain" || exit
  echo "Relocated $plexTrain."
else
  echo "$config/$plexTrain already exists."
fi

if [ ! -d "$configDir/$plexData" ] ; then
  mv -v "/usr/local/$plexData" "$configDir/." || exit
  ln -s "$configDir/$plexData" "/usr/local/$plexData" || exit
  echo "Relocated $plexData."
else
  echo "$config/$plexData already exists."
fi

if [ "$plexTrain" = "plexmediaserver-plexpass" ] ; then
  sysrc plexmediaserver_plexpass_enable=YES || exit
  service plexmediaserver_plexpass start || exit
else
  sysrc plexmediaserver_enable=YES || exit
  service plexmediaserver start || exit
fi

ip="`ifconfig | grep -v 127.0.0.1 | sed -n '/.inet /{s///;s/ .*//;p;}'`:32400/web"
echo "You should be able to start configuration of Plex on: $ip"
echo "Default uid:gid for Plex is 972:972. You may need to adjust manually if"
echo "you are having permissions problems to your linked in media dataset(s)"
echo "If you change the uid:gid, remember to also chown -R on everything in"
echo "$configDir"
