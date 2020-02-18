#!/bin/bash

while true
do
   pushd /home/svends/sc5
   /home/svends/sc5/svends_run -debug -pingboost 3 -nosteamruntime +maxplayers 32
   popd
   sleep 5
done
