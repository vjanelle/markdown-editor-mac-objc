#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [download-url]" >&2
  exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENDOR_DIR="${REPO_ROOT}/Draftmark/Resources/vendor/mermaid"
STABLE_FILE="${VENDOR_DIR}/mermaid.min.js"
VERSIONED_FILE="${VENDOR_DIR}/mermaid-${VERSION}.min.js"
DEFAULT_URL="https://cdn.jsdelivr.net/npm/mermaid@${VERSION}/dist/mermaid.min.js"
DOWNLOAD_URL="${2:-${DEFAULT_URL}}"
DATE_VENDORED="$(date +%F)"

mkdir -p "${VENDOR_DIR}"

TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/mermaid.XXXXXX.js")"
trap 'rm -f "${TMP_FILE}"' EXIT

echo "Downloading Mermaid ${VERSION} from ${DOWNLOAD_URL}" >&2
curl -fL "${DOWNLOAD_URL}" -o "${TMP_FILE}"

cp "${TMP_FILE}" "${VERSIONED_FILE}"
cp "${TMP_FILE}" "${STABLE_FILE}"

cat > "${VENDOR_DIR}/VERSION.md" <<EOF
# Mermaid Vendor Metadata

- Version: \`${VERSION}\`
- Upstream repository: <https://github.com/mermaid-js/mermaid>
- Bundled file: \`mermaid.min.js\`
- Versioned copy: \`mermaid-${VERSION}.min.js\`
- Download URL: <${DOWNLOAD_URL}>
- Date vendored: ${DATE_VENDORED}

## Update Process

Run:

\`\`\`sh
./scripts/update-mermaid.sh ${VERSION}
\`\`\`

Pass an explicit URL as the second argument if the default CDN path changes.
After updating, verify the preview still loads Mermaid diagrams and commit the bundle and this metadata file together.
EOF

echo "Updated ${STABLE_FILE}" >&2
echo "Updated ${VERSIONED_FILE}" >&2
echo "Updated ${VENDOR_DIR}/VERSION.md" >&2
