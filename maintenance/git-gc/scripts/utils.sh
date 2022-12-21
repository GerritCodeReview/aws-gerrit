#!/bin/bash

JGIT=${JGIT:-$(which jgit)}
GIT=${GIT:-$(which git)}
GIT_HOME=${GIT_HOME:-"/git"}
GIT_GC_OPTION=${GIT_GC_OPTION:-""}
PACK_THREADS=${PACK_THREADS:-""}
PRUNE_EXPIRE=${PRUNE_EXPIRE:-""}
PRUNE_PACK_EXPIRE=${PRUNE_PACK_EXPIRE:-""}
GC_LOCK_EXPIRE_SECONDS=${GC_LOCK_EXPIRE_SECONDS:-"43200"} # 12 hours
INCOMING_EXPIRE_SECONDS=${INCOMING_EXPIRE_SECONDS:-"43200"} # 12 hours
KEEP_EXPIRE_SECONDS=${KEEP_EXPIRE_SECONDS:-"43200"} # 12 hours
TMP_EXPIRE_SECONDS=${TMP_EXPIRE_SECONDS:-"43200"} # 12 hours
MAX_HEADS_FOR_BITMAPS=${MAX_HEADS_FOR_BITMAPS:-"300"}

function gc_project {
  proj=$1

  PROJECT_PATH=$GIT_HOME/"$proj".git
  pushd "$PROJECT_PATH" > /dev/null || {
    status_code=$?
    err_proj "$proj" "Could not move into $PROJECT_PATH ($status_code). Skipping."
    return 1
  }

  log_env

  print_stats "$proj" "before"
  do_clean_up "$proj"
  do_gc "$proj"
  print_stats "$proj" "after"

  popd > /dev/null || {
    status_code=$?
    err_proj "$proj" "Could not step out of $PROJECT_PATH ($status_code). Aborting"
    exit 1
  }
}

function java_heap_for_repo() {
  MIN_SIZE=1048576
  REPO_SIZE_X2=$(expr $(du -s --exclude=preserved -k . | cut -f 1) '*' 2)
  [ $REPO_SIZE_X2 -gt $MIN_SIZE ] && echo $REPO_SIZE_X2 || echo $MIN_SIZE
}

function do_gc() {
    proj=$1

    should_continue_GC "$proj" || {
      status_code=$?
      err_proj "$proj" "Could not GC $proj ($status_code)."
      return 1
    }

    log_project "$proj" "Disable JGit automatic GC (gc.auto=0; gc.autoPackLimit=0)"
    $GIT config gc.auto 0
    $GIT config gc.autoPackLimit 0

    if should_create_bitmaps "$proj"
    then
      $GIT config pack.buildBitmaps true
    else
      $GIT config pack.buildBitmaps false
    fi

    [ -z "$PRUNE_PACK_EXPIRE" ] || $GIT config gc.prunePackExpire $PRUNE_PACK_EXPIRE
    [ -z "$PRUNE_EXPIRE" ] || $GIT config gc.pruneExpire $PRUNE_EXPIRE
    [ -z "$PACK_THREADS" ] || $GIT config gc.packThreads $PACK_THREADS

    JAVA_ARGS="$JAVA_ARGS -Xmx$(java_heap_for_repo)k"
    log_project "$proj" "Running java_args=\"$JAVA_ARGS\" $JGIT gc $GIT_GC_OPTION ..."
    start=$SECONDS
    (java_args=$JAVA_ARGS $JGIT gc $GIT_GC_OPTION 2>&1) || {
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

   $GIT count-objects -v | while read line; do log_project "$proj" "$phase|#$line"; done
   log_project "$proj" "$phase|#oldest_pack: $(oldest_pack_object pack)"

   for ext in "bitmap" "idx" "keep"; do
    log_project "$proj" "$phase|#num_$ext: $(count_pack_objects $ext) files"
    log_project "$proj" "$phase|#size_$ext: $(size_pack_objects $ext) Kb"
    log_project "$proj" "$phase|#oldest_$ext: $(oldest_pack_object $ext)"
   done

   if [ -d "objects/pack/preserved" ]
   then
     for ext in "old-pack" "old-idx"; do
      log_project "$proj" "$phase|#num_$ext: $(count_pack_objects $ext "/preserved") preserved files"
      log_project "$proj" "$phase|#size_$ext: $(size_pack_objects $ext "/preserved") Kb preserved"
      log_project "$proj" "$phase|#oldest_$ext: $(oldest_pack_object $ext "/preserved") preserved"
     done
   fi

   log_project "$proj" "$phase|#size_packed-refs: $(du -k packed-refs | cut -f 1) Kb"
   log_project "$proj" "$phase|#num_packed-refs: $(wc -l packed-refs | cut -d ' ' -f 1) refs"
   log_project "$proj" "$phase|#num_loose-refs: $(find refs -type f | wc -l) refs"

   log_project "$proj" "$phase|#empty_dirs: $(find . -type d -empty | wc -l)"
}

function count_pack_objects {

   find objects/pack$2 -type f -name "*.$1" | wc -l | sed 's/\ //g'
}

function size_pack_objects {
   out=$(find objects/pack$2 -type f -name "*.$1" -exec du -ck {} + | grep total$ | cut -d$'\t' -f1)
   out="${out:-0}"
   echo "$out"
}

function oldest_pack_object {
   out=$(find objects/pack$2 -type f -name "*.$1" -print0 | xargs -0 ls -tl | tail -1)
   out="${out:-NONE}"
   echo "$out"
}

function should_continue_GC() {
  proj=$1
  gc_log_lock="gc.log.lock"
  lockTime=$(find . -maxdepth 1 -name $gc_log_lock -type f | grep -q . && stat -c "%Z" $gc_log_lock)

  if [ -n "$lockTime" ]
  then
    log_project "$proj" "'$gc_log_lock' exists with stats: [$(stat $gc_log_lock)]"
    now=$(date +%s)
    lockFileAgeSeconds="$((now-lockTime))"
    if (( lockFileAgeSeconds > GC_LOCK_EXPIRE_SECONDS ))
    then
      log_project "$proj" "Consider '$gc_log_lock' stale since its age ($lockFileAgeSeconds secs) is older than the configured threshold ($GC_LOCK_EXPIRE_SECONDS secs). Removing it and and continuing."
      rm -vf $gc_log_lock
      # 0 = true
      return 0
    else
      log_project "$proj" "Consider '$gc_log_lock' still relevant since its age ($lockFileAgeSeconds secs) is younger than the configured threshold ($GC_LOCK_EXPIRE_SECONDS secs). Possibly another GC process is still running? Skipping GC for project $proj."
      # 1 = false
      return 1
    fi
  fi

}

function count_heads() {
  out=$(git show-ref --heads | wc -l | xargs)

  echo "${out:-0}"
}

function should_create_bitmaps() {
  proj=$1
  numberOfHeads=$(count_heads)

 if (( numberOfHeads < MAX_HEADS_FOR_BITMAPS ))
     then
       log_project "$proj" "Number of heads $numberOfHeads is < than the configured threshold $MAX_HEADS_FOR_BITMAPS, WILL create bitmap"
       return 0 # true
     else
       log_project "$proj" "Number of heads $numberOfHeads is >= than the configured threshold $MAX_HEADS_FOR_BITMAPS, WILL NOT create bitmap"
       return 1 # false
     fi
}

function do_clean_up() {
  proj=$1
  log_project "$proj" "Checking incoming files older than $INCOMING_EXPIRE_SECONDS seconds"
  delete_if_older_than "$INCOMING_EXPIRE_SECONDS" "incoming_*"

  log_project "$proj" "Checking keep files older than $KEEP_EXPIRE_SECONDS seconds"
  delete_if_older_than "$KEEP_EXPIRE_SECONDS" "*.keep"

  log_project "$proj" "Checking tmp files older than $TMP_EXPIRE_SECONDS seconds"
  delete_if_older_than "$TMP_EXPIRE_SECONDS" "*_tmp"
}

function delete_if_older_than() {
  secondsAgo=$1
  matchName=$2
  find . -type f -name "$matchName" -not -newermt "-$secondsAgo seconds" -print -delete
}

function log_env() {
  log "######## ENVIRONMENT ########"
  log "# GC_PROJECT_LIST=${GC_PROJECT_LIST}"
  log "# JGIT=${JGIT}"
  log "# GIT=${GIT}"
  log "# GIT_HOME=${GIT_HOME}"
  log "# GIT_GC_OPTION=${GIT_GC_OPTION}"
  log "# PACK_THREADS=${PACK_THREADS}"
  log "# PRUNE_EXPIRE=${PRUNE_EXPIRE}"
  log "# PRUNE_PACK_EXPIRE=${PRUNE_PACK_EXPIRE}"
  log "# JAVA_ARGS=${JAVA_ARGS}"
  log "# GC_LOCK_EXPIRE_SECONDS=${GC_LOCK_EXPIRE_SECONDS}"
  log "# MAX_HEADS_FOR_BITMAPS=${MAX_HEADS_FOR_BITMAPS}"
  log "# INCOMING_EXPIRE_SECONDS=${INCOMING_EXPIRE_SECONDS}"
  log "# KEEP_EXPIRE_SECONDS=${KEEP_EXPIRE_SECONDS}"
  log "# TMP_EXPIRE_SECONDS=${TMP_EXPIRE_SECONDS}"
  log "############################"
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