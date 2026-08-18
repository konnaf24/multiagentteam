#!/usr/bin/env sh

set -eu

usage() {
  echo "Usage: $0 <case-slug> [case title]" >&2
  echo "Example: $0 bng-random-disconnect \"BNG Random Subscriber Disconnects\"" >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 2
fi

case_slug=$1
case "$case_slug" in
  *[!a-z0-9-]* | -* | *- | *--*)
    echo "Error: case slug must use lowercase letters, numbers, and single hyphens." >&2
    exit 2
    ;;
esac

if [ -z "$case_slug" ]; then
  echo "Error: case slug cannot be empty." >&2
  exit 2
fi

case_title=${2:-$(printf '%s' "$case_slug" | tr '-' ' ')}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
created_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

case_dir="$repo_root/cases/$case_slug"
if [ -e "$case_dir" ]; then
  echo "Error: case '$case_slug' already exists." >&2
  exit 1
fi

escape_sed() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

render_template() {
  template=$1
  destination=$2
  escaped_slug=$(escape_sed "$case_slug")
  escaped_title=$(escape_sed "$case_title")
  escaped_created_at=$(escape_sed "$created_at")

  sed \
    -e "s/{{CASE_SLUG}}/$escaped_slug/g" \
    -e "s/{{CASE_TITLE}}/$escaped_title/g" \
    -e "s/{{CREATED_AT}}/$escaped_created_at/g" \
    "$template" > "$destination"
}

mkdir -p \
  "$case_dir" \
  "$repo_root/tasks/$case_slug" \
  "$repo_root/evidence/$case_slug" \
  "$repo_root/findings/$case_slug" \
  "$repo_root/reviews/$case_slug"

render_template "$repo_root/docs/templates/CASE.md" "$case_dir/CASE.md"
render_template "$repo_root/docs/templates/CLAIMS.md" "$case_dir/CLAIMS.md"
render_template "$repo_root/docs/templates/TASK.md" \
  "$repo_root/tasks/$case_slug/TASK-001.md"

cat > "$repo_root/evidence/$case_slug/README.md" <<EOF
# Evidence inventory: $case_title

| Artifact | Source | Collected (UTC) | Integrity | Sanitized | Notes |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

Preserve source artifacts. Put interpretations in \`findings/$case_slug/\`.
EOF

printf '%s\n' \
  "# Add investigator reports for $case_slug here." \
  > "$repo_root/findings/$case_slug/README.md"
printf '%s\n' \
  "# Add adversarial reviews for $case_slug here." \
  > "$repo_root/reviews/$case_slug/README.md"

echo "Created case '$case_slug'."
echo "Next: complete cases/$case_slug/CASE.md and evidence/$case_slug/README.md."
