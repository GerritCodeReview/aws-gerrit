#!/bin/bash

function print_stats {
   proj=$1

   log "$proj" "#num_packfiles: $(ls -1 objects/pack/ | wc -l) files"
   log "$proj" "#num_bitmaps: $(ls -1 objects/pack/ | grep bitmap | wc -l) files"
   log "$proj" "#num_keep: $(ls -1 objects/pack/ | grep keep | wc -l) files"
   log "$proj" "#size_packfiles: $(du -sk objects/pack | cut -d'o' -f1) kilobytes"
   log "$proj" "#oldest_packfile: $(find objects/pack/ -type f -printf '%T+ %p\n' | sort | head -n 1)"
   log "$proj" "#num_objects: $(git count-objects -v)"
}

function log {
  echo "$(date '+%d/%m/%Y %H:%M:%S')|$1|$2"
}