#!/bin/sh

for (( ; ; ))
do
  date "+%H:%M:%S Launching postfix.."
  sudo launchctl start org.postfix.master
  sleep 60
done

