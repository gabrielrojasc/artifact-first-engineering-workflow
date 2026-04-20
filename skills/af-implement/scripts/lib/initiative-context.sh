af_expand_home_path() {
  printf '%s' "${1/#\~/$HOME}"
}

af_next_sequence_number() {
  local active_dir="$1"
  local archive_dir="$2"
  local max=0
  local num=""
  local basename=""
  local dir=""
  local entry=""

  for dir in "$active_dir" "$archive_dir"; do
    [ -d "$dir" ] || continue
    for entry in "$dir"/*/; do
      [ -d "$entry" ] || continue
      basename="$(basename "$entry")"
      num="${basename%%_*}"
      if [[ "$num" =~ ^[0-9]+$ ]]; then
        num=$((10#$num))
        if [ "$num" -gt "$max" ]; then
          max="$num"
        fi
      fi
    done
  done

  printf '%04d' $((max + 1))
}

af_find_existing_initiative_folder() {
  local active_dir="$1"
  local initiative_name="$2"
  local ticket_key="$3"
  local entry=""
  local entry_base=""
  local entry_suffix=""
  local target_suffix="$initiative_name"

  if [ -n "$ticket_key" ]; then
    target_suffix="${initiative_name}_${ticket_key}"
  fi

  for entry in "$active_dir"/*/; do
    [ -d "$entry" ] || continue
    entry_base="$(basename "$entry")"
    entry_suffix="${entry_base#*_}"
    if [ "$entry_suffix" = "$target_suffix" ]; then
      printf '%s' "$entry_base"
      return 0
    fi
  done

  return 1
}

af_resolve_initiative_folder() {
  local active_dir="$1"
  local archive_dir="$2"
  local initiative_name="$3"
  local ticket_key="$4"
  local existing_folder=""
  local folder_name=""
  local seq_num=""

  if existing_folder="$(af_find_existing_initiative_folder "$active_dir" "$initiative_name" "$ticket_key")"; then
    folder_name="$existing_folder"
    seq_num="${folder_name%%_*}"
    AF_REUSED=1
  else
    seq_num="$(af_next_sequence_number "$active_dir" "$archive_dir")"
    if [ -n "$ticket_key" ]; then
      folder_name="${seq_num}_${initiative_name}_${ticket_key}"
    else
      folder_name="${seq_num}_${initiative_name}"
    fi
    AF_REUSED=0
  fi

  AF_FOLDER_NAME="$folder_name"
  AF_SEQ_NUM="$seq_num"
}
