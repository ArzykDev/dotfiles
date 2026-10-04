#!/bin/bash
pkill openrgb

sleep 1
/usr/bin/openrgb --startminimized --profile 'Arzyk Blue' --server &
