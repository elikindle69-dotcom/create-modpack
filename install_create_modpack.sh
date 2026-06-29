#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
default_instance="${HOME}/.minecraft/instances/neoforge"
instance_dir="$default_instance"
dry_run=0

usage() {
  cat <<'EOF'
Usage: install_create_modpack.sh [options]

Options:
  --instance PATH   Target NeoForge instance directory.
  --dry-run         Show what would change without copying files.
  -h, --help        Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance)
      [[ $# -ge 2 ]] || { echo "--instance requires a path" >&2; exit 2; }
      instance_dir="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mods_dir="$instance_dir/mods"
backup_dir="$instance_dir/mods_backup"

if [[ ! -d "$mods_dir" ]]; then
  echo "Missing instance mods directory: $mods_dir" >&2
  exit 1
fi

declare -A pack_files=()
declare -A instance_files=()
declare -a pack_paths=()
declare -a instance_paths=()
declare -a extras=()
declare -a missing=()

while IFS= read -r -d '' file; do
  name="$(basename -- "$file")"
  pack_files["$name"]="$file"
  pack_paths+=("$file")
done < <(find "$script_dir" -path "$script_dir/.git" -prune -o -type f -name '*.jar' -print0)

while IFS= read -r -d '' file; do
  name="$(basename -- "$file")"
  instance_files["$name"]="$file"
  instance_paths+=("$file")
done < <(find "$mods_dir" -maxdepth 1 -type f -name '*.jar' -print0)

for path in "${instance_paths[@]}"; do
  name="$(basename -- "$path")"
  [[ -n "${pack_files[$name]+x}" ]] || extras+=("$path")
done

for path in "${pack_paths[@]}"; do
  name="$(basename -- "$path")"
  [[ -n "${instance_files[$name]+x}" ]] || missing+=("$path")
done

echo "Instance: $instance_dir"
echo "Pack mods: ${#pack_paths[@]}"
echo "Instance mods: ${#instance_paths[@]}"
echo "Missing in instance: ${#missing[@]}"
echo "Extra in instance: ${#extras[@]}"

if (( ${#missing[@]} == 0 && ${#extras[@]} == 0 )); then
  echo "Verified: mod sets already match."
else
  if (( ${#extras[@]} > 0 )); then
    echo "Backing up extra instance mods to: $backup_dir"
    if (( dry_run == 0 )); then
      mkdir -p "$backup_dir"
      for path in "${extras[@]}"; do
        cp -p -- "$path" "$backup_dir/"
      done
    fi
  fi

  if (( ${#missing[@]} > 0 )); then
    echo "Installing missing pack mods into: $mods_dir"
    if (( dry_run == 0 )); then
      for path in "${missing[@]}"; do
        cp -p -- "$path" "$mods_dir/"
      done
    fi
  fi
fi

if (( dry_run == 0 )); then
  declare -A post_pack=()
  declare -A post_instance=()
  declare -a post_missing=()
  declare -a post_extras=()

  while IFS= read -r -d '' file; do
    name="$(basename -- "$file")"
    post_pack["$name"]="$file"
  done < <(find "$script_dir" -path "$script_dir/.git" -prune -o -type f -name '*.jar' -print0)

  while IFS= read -r -d '' file; do
    name="$(basename -- "$file")"
    post_instance["$name"]="$file"
  done < <(find "$mods_dir" -maxdepth 1 -type f -name '*.jar' -print0)

  for name in "${!post_instance[@]}"; do
    [[ -n "${post_pack[$name]+x}" ]] || post_extras+=("$name")
  done
  for name in "${!post_pack[@]}"; do
    [[ -n "${post_instance[$name]+x}" ]] || post_missing+=("$name")
  done

  if (( ${#post_missing[@]} == 0 && ${#post_extras[@]} == 0 )); then
    echo "Verification passed: instance mods now match the pack."
  else
    echo "Verification warning: instance still differs from the pack." >&2
    if (( ${#post_missing[@]} > 0 )); then
      printf 'Still missing: %s\n' "${post_missing[@]}" >&2
    fi
    if (( ${#post_extras[@]} > 0 )); then
      printf 'Still extra: %s\n' "${post_extras[@]}" >&2
      echo "Those extra mods were backed up to: $backup_dir" >&2
    fi
    exit 1
  fi
else
  echo "Dry run complete."
fi
