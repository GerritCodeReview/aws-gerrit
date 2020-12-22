#!/bin/bash

#####################################################
# Garbage collect specific repositories, using jgit #
#####################################################
set -eo pipefail
set +e

source ./utils.sh

JGIT="/bin/jgit"
GIT_HOME="/git"

echo "$(date '+%d/%m/%Y %H:%M:%S')|START GC"

if [ -z "$GC_PROJECT_LIST" ]; then
  echo "GC_PROJECT_LIST environment variable is empty. Nothing to do."
else
  for proj in $(echo "$GC_PROJECT_LIST" | sed "s/,/ /g"); do
    PROJECT_PATH=$GIT_HOME/"$proj".git

    if [ ! -d "$PROJECT_PATH" ]; then
      echo "Project $proj.git could not be found in $GIT_HOME. Skipping."
      continue
    fi

    pushd "$PROJECT_PATH"

    log "$proj" "STATS BEFORE GC"
    print_stats "$proj"

    start_object_count=$(git count-objects | awk '{print $1}')
    start_epoch_time=$(date +%s)
    log "$proj" "GC started - $(date '+%d/%m/%Y %H:%M:%S'):"
    $JGIT gc
    jgitResult=$?
    log "$proj" "GC finished - $(date '+%d/%m/%Y %H:%M:%S'): $(date +%s)"
    if [[ $jgitResult != 0 ]]; then
      log "$proj" "Error running GC (continuing with next project)"
    else
      end_epoch_time=$(date +%s)
      end_object_count=$(git count-objects | awk '{print $1}')
      runtime=$((end_epoch_time - start_epoch_time))
      let compression_rate=0
      if [[ $start_object_count != 0 ]]; then
        let compression_rate="($start_object_count-$end_object_count)*100/$start_object_count"
      fi

      log "$proj" "STATS AFTER GC"
      print_stats "$proj"
      log "$proj" "time-taken: $runtime seconds compression-rate: $compression_rate pct"
    fi
    popd
  done
fi

echo "$(date '+%d/%m/%Y %H:%M:%S')|END GC"

set -e
