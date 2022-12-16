#!/bin/bash

JGIT=${JGIT:-$(which jgit)}
GIT=${GIT:-$(which git)}
GIT_HOME=${GIT_HOME:-"/git"}
GIT_GC_OPTION=${GIT_GC_OPTION:-""}
PACK_THREADS=${PACK_THREADS:-""}
PRUNE_EXPIRE=${PRUNE_EXPIRE:-""}
PRUNE_PACK_EXPIRE=${PRUNE_PACK_EXPIRE:-""}

function gc_project {
  proj=$1

  PROJECT_PATH=$GIT_HOME/"$proj".git
  pushd "$PROJECT_PATH" || {
    status_code=$?
    err_proj "$proj" "Could not move into $PROJECT_PATH ($status_code). Skipping."
    return 1
  }

  log_project "$proj" "stats before GC"
  print_stats "$proj" "before"

  do_gc "$proj"

  log_project "$proj" "stats after GC"
  print_stats "$proj" "after"

  popd || {
    status_code=$?
    err_proj "$proj" "Could not step out of $PROJECT_PATH ($status_code). Aborting"
    exit 1
  }
}

function java_heap_for_repo() {
  MIN_SIZE=1048576
  REPO_SIZE_X2=$(expr $(du -s -k . | cut -f 1) '*' 2)
  [ $REPO_SIZE_X2 -gt $MIN_SIZE ] && echo $REPO_SIZE_X2 || echo $MIN_SIZE
}

function do_gc() {
    proj=$1
    [ -z "$PRUNE_PACK_EXPIRE" ] || $GIT config gc.prunePackExpire $PRUNE_PACK_EXPIRE
    [ -z "$PRUNE_EXPIRE" ] || $GIT config gc.pruneExpire $PRUNE_EXPIRE
    [ -z "$PACK_THREADS" ] || $GIT config gc.packThreads $PACK_THREADS

    JAVA_ARGS="$JAVA_ARGS -Xmx$(java_heap_for_repo)k"
    log_project "$proj" "Running java_args=\"$JAVA_ARGS\" $JGIT gc $GIT_GC_OPTION ..."
    start=$SECONDS
    (java_args=$JAVA_ARGS $JGIT gc $GIT_GC_OPTION 2>&1 | tr '\r' '\n' | grep -v "^$" | cut -d ':' -f 1 | uniq | while read line; do log_project "$proj" "GC|$line"; done) || {
      status_code=$?
      err_proj "$proj" "Could not GC $proj ($status_code)."
      return 1
    }
    end=$SECONDS
    duration=$(( end - start ))
    log_project "$proj" "GC|took $duration seconds"
    return 0
}

function print_stats {
   proj=$1
   phase=$2

   log_project "$proj" "$phase|#num_objects: $(count_objects)"

   for ext in "pack" "bitmap" "idx" "keep"; do
    log_project "$proj" "$phase|#num_$ext: $(count_pack_objects $ext) files"
    log_project "$proj" "$phase|#size_$ext: $(size_pack_objects $ext) Kb"
    log_project "$proj" "$phase|#oldest_$ext: $(oldest_pack_object $ext)"
  done
}

function count_pack_objects {
   find objects/pack -type f -name "*.$1" | wc -l | sed 's/\ //g'
}

function size_pack_objects {
   out=$(find objects/pack -type f -name "*.$1" -exec du -ck {} + | grep total$ | cut -d$'\t' -f1)
   out="${out:-0}"
   echo "$out"
}

function oldest_pack_object {
   out=$(find objects/pack -type f -name "*.$1" -print0 | xargs -0 ls -tl | tail -1)
   out="${out:-NONE}"
   echo "$out"
}

function count_objects {
  git count-objects  | awk '{print $1}'
}

function now {
  date -u '+%FT%TZ'
}

function log_project {
  echo "$(now)|INFO|$1|$2"
}

function log {
  echo "$(now)|INFO|$1"
}

function err_proj {
  >&2 echo "$(now)|ERROR|$1|$2"
}