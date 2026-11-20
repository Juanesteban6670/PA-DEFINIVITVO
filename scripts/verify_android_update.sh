#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 ]]; then
  echo 'Usage: verify_android_update.sh CURRENT_APK CANDIDATE_APK' >&2
  exit 2
fi

package_metadata() {
  aapt2 dump badging "$1" | awk -F"'" '/^package: name=/ {print $2, $4}'
}

signing_certificates() {
  apksigner verify --print-certs "$1" | sed -n 's/^Signer #[0-9]* certificate SHA-256 digest: //p' | sort
}

current_metadata=$(package_metadata "$1")
candidate_metadata=$(package_metadata "$2")
read -r current_id current_version <<<"$current_metadata"
read -r candidate_id candidate_version <<<"$candidate_metadata"
current_cert=$(signing_certificates "$1")
candidate_cert=$(signing_certificates "$2")

if [[ -z "$current_cert" || "$current_cert" != "$candidate_cert" ]]; then
  echo 'The signing certificates of the current and candidate APKs differ.' >&2
  exit 1
fi
if [[ -z "$current_id" || "$current_id" != "$candidate_id" ]]; then
  echo 'The APK application identifiers differ.' >&2
  exit 1
fi
if [[ ! "$current_version" =~ ^[0-9]+$ || ! "$candidate_version" =~ ^[0-9]+$ ]] ||
   (( candidate_version <= current_version )); then
  echo 'The candidate APK must have a higher versionCode than the current release.' >&2
  exit 1
fi
