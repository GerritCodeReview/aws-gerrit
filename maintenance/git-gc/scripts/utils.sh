#!/bin/bash

JGIT=${JGIT:-"/bin/jgit"}
GIT_HOME=${GIT_HOME:-"/git"}
GIT_GC_OPTION=${GIT_GC_OPTION:-"--preserve-oldpacks"}

function gc_project {
  proj=$1

  PROJECT_PATH=$GIT_HOME/"$proj".git
  pushd "$PROJECT_PATH" || {
    status_code=$?
    err_proj "$proj" "Could not move into $PROJECT_PATH ($status_code). Skipping."
    return 1
  }

  log_project "$proj" "stats before GC"
  print_stats "$proj"

  do_gc

  log_project "$proj" "stats after GC"
  print_stats "$proj"

  popd || {
    status_code=$?
    err_proj "$proj" "Could not step out of $PROJECT_PATH ($status_code). Aborting"
    exit 1
  }
}

function do_gc() {
    start=$SECONDS
    log_project "$proj" "Running $JGIT gc $GIT_GC_OPTION ..."
    $JGIT gc $GIT_GC_OPTION || {
      status_code=$?
      err_proj "$proj" "Could not GC $proj ($status_code)."
      return 1
    }
    end=$SECONDS
    duration=$(( end - start ))
    log_project "$proj" "GC took $duration seconds"
    return 0
}

function print_stats {
   proj=$1

   log_project "$proj" "#num_objects: $(count_objects)"

   for ext in "pack" "bitmap" "idx" "keep"; do
    log_project "$proj" "#num_$ext: $(count_pack_objects $ext) files"
    log_project "$proj" "#size_$ext: $(size_pack_objects $ext) Kb"
    log_project "$proj" "#oldest_$ext: $(oldest_pack_object $ext)"
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