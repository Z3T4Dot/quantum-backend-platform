#!/usr/bin/env bash
# =============================================================================
# generate-permissions.sh
# Generates Permission.java and Permission.ts from Backend/permissions.yaml
#
# Usage:
#   ./scripts/generate-permissions.sh
#
# Requirements:
#   - python3 (for YAML parsing via PyYAML)   OR
#   - yq (https://github.com/mikefarah/yq)
#
# Called automatically by:
#   - Maven exec-maven-plugin (generate-sources phase) in Spring Boot services
#   - "prebuild" script in NestJS package.json
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YAML_FILE="$REPO_ROOT/Backend/permissions.yaml"

JAVA_OUT="$REPO_ROOT/Backend/services/identity-service/src/main/java/global/brandex/quantum/identity/authorization/domain/model/Permission.java"
TS_OUT="$REPO_ROOT/Backend/shared/auth/src/Permission.ts"

if [[ ! -f "$YAML_FILE" ]]; then
  echo "ERROR: $YAML_FILE not found. Run from repo root." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Extract permission names from YAML
# Expects: permissions: { PERM_NAME: { resource: ..., description: ... } }
# ---------------------------------------------------------------------------
if command -v python3 &>/dev/null; then
  PERMS=$(python3 - <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    content = f.read()

# Simple regex extraction — avoids full PyYAML dependency
pattern = r'^  ([A-Z][A-Z0-9_]+):'
for m in re.finditer(pattern, content, re.MULTILINE):
    name = m.group(1)
    if name not in ('version', 'resources', 'permissions'):
        print(name)
PYEOF
  "$YAML_FILE")
elif command -v yq &>/dev/null; then
  PERMS=$(yq '.permissions | keys | .[]' "$YAML_FILE")
else
  echo "ERROR: python3 or yq is required to run this script." >&2
  exit 1
fi

if [[ -z "$PERMS" ]]; then
  echo "ERROR: No permissions found in $YAML_FILE" >&2
  exit 1
fi

PERM_COUNT=$(echo "$PERMS" | wc -l | tr -d ' ')
echo ">> Found $PERM_COUNT permissions in $YAML_FILE"

# ---------------------------------------------------------------------------
# Generate Permission.java
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$JAVA_OUT")"

{
cat <<HEADER
package global.brandex.quantum.identity.authorization.domain.model;

/**
 * Typed permission catalog for Quantum ERP.
 *
 * AUTO-GENERATED — do not edit manually.
 * Source of truth: Backend/permissions.yaml
 * Regenerate: scripts/generate-permissions.sh
 */
public enum Permission {

HEADER

first=true
while IFS= read -r perm; do
  [[ -z "$perm" ]] && continue
  if [[ "$first" == "true" ]]; then
    printf '    %s' "$perm"
    first=false
  else
    printf ',\n    %s' "$perm"
  fi
done <<< "$PERMS"

cat <<FOOTER

}
FOOTER
} > "$JAVA_OUT"

echo ">> Generated: $JAVA_OUT"

# ---------------------------------------------------------------------------
# Generate Permission.ts
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$TS_OUT")"

{
cat <<HEADER
/**
 * Typed permission catalog for Quantum ERP.
 *
 * AUTO-GENERATED — do not edit manually.
 * Source of truth: Backend/permissions.yaml
 * Regenerate: scripts/generate-permissions.sh
 */
export enum Permission {
HEADER

while IFS= read -r perm; do
  [[ -z "$perm" ]] && continue
  printf "  %s = '%s',\n" "$perm" "$perm"
done <<< "$PERMS"

cat <<FOOTER
}
FOOTER
} > "$TS_OUT"

echo ">> Generated: $TS_OUT"
echo ">> Done. $PERM_COUNT permissions synchronized."
