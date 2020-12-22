#!/bin/bash

#####################################################
# Garbage collect specific repositories, using jgit #
#####################################################
set -eo pipefail
set +e

source ./utils.sh

start_process=$SECONDS
log "START GC PROCESS"

if [ -z "$GC_PROJECT_LIST" ]; then
  echo "GC_PROJECT_LIST environment variable is empty. Nothing to do."
  exit 1
fi

for proj in $(echo "$GC_PROJECT_LIST" | sed "s/,/ /g"); do
  gc_project "$proj"
done

end_process=$SECONDS
log "END GC PROCESS"

duration_process=$(( end_process - start_process ))
log "GC process took $duration_process seconds"

set -e
