#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
generate_csr_with_token.sh - Generate a CSR that includes a JWT in challengePassword

Usage:
  script/generate_csr_with_token.sh -t <token> -c <certname> [-o output_dir] [--subject "/CN=..."]

Options:
  -t, --token      JWT token to embed in the CSR (required)
  -c, --certname   Common Name used for the CSR and output file names (required)
  -o, --output     Directory for the generated key and CSR (default: current directory)
  --subject        Full distinguished name for the CSR subject (default: "/CN=<certname>")
  -h, --help       Show this help message

Outputs:
  <output_dir>/<certname>.key.pem
  <output_dir>/<certname>.csr.pem
USAGE
}

TOKEN=""
CERTNAME=""
OUTPUT_DIR="."
SUBJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--token)
      TOKEN="${2-}"
      shift 2
      ;;
    -c|--certname)
      CERTNAME="${2-}"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="${2-}"
      shift 2
      ;;
    --subject)
      SUBJECT="${2-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TOKEN" || -z "$CERTNAME" ]]; then
  echo "Error: --token and --certname are required." >&2
  usage >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

CONFIG_FILE="$(mktemp)"
trap 'rm -f "$CONFIG_FILE"' EXIT

python3 - "$CONFIG_FILE" "${SUBJECT:-}" "$CERTNAME" "$TOKEN" <<'PY'
import sys
from pathlib import Path

config_path, subject, certname, token = sys.argv[1:]
lines = [
    "[ req ]",
    "default_bits       = 2048",
    "distinguished_name = req_distinguished_name",
    "string_mask        = utf8only",
    "prompt             = no",
    "attributes         = req_attributes",
    "",
    "[ req_distinguished_name ]",
]

components = []
subject = subject.strip()
if subject:
    if subject.startswith("/"):
        subject = subject[1:]
    for part in subject.split("/"):
        if not part or "=" not in part:
            continue
        key, value = part.split("=", 1)
        components.append(f"{key.strip()} = {value.strip()}")

if not components:
    components.append(f"CN = {certname}")

lines.extend(components)
lines.extend([
    "",
    "[ req_attributes ]",
    f"challengePassword = {token}",
])

Path(config_path).write_text("\n".join(lines) + "\n")
PY

KEY_FILE="${OUTPUT_DIR}/${CERTNAME}.key.pem"
CSR_FILE="${OUTPUT_DIR}/${CERTNAME}.csr.pem"

openssl req \
  -new \
  -nodes \
  -keyout "${KEY_FILE}" \
  -out "${CSR_FILE}" \
  -config "${CONFIG_FILE}" >/dev/null

echo "Generated:"
echo "  Key: ${KEY_FILE}"
echo "  CSR: ${CSR_FILE}"

