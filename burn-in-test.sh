#!/usr/bin/env bash

set -e

DRIVE="$1"

BLOCKSIZE=$(blockdev --getbsz "$DRIVE")

SHORT_POLL_MINUTES=$(smartctl -c "$DRIVE" -json | jq '.ata_smart_data.self_test.polling_minutes.short')
LONG_POLL_MINUTES=$(smartctl -c "$DRIVE" -json | jq '.ata_smart_data.self_test.polling_minutes.extended')
CONVEYANCE_POLL_MINUTES=$(smartctl -c "$DRIVE" -json | jq '.ata_smart_data.self_test.polling_minutes.conveyance')

if [[ -n "$SHORT_POLL_MINUTES" && "$SHORT_POLL_MINUTES" != "null" ]]; then
  SHORT_POLL_MINUTES=$((SHORT_POLL_MINUTES + 1))
fi
if [[ -n "$LONG_POLL_MINUTES" && "$LONG_POLL_MINUTES" != "null" ]]; then
  LONG_POLL_MINUTES=$((LONG_POLL_MINUTES + 1))
fi
if [[ -n "$CONVEYANCE_POLL_MINUTES" && "$CONVEYANCE_POLL_MINUTES" != "null" ]]; then
  CONVEYANCE_POLL_MINUTES=$((CONVEYANCE_POLL_MINUTES + 1))
fi

function run_test() {
  TYPE="$1"
  MINUTES="$2"
  if [[ -n "$MINUTES" && "$MINUTES" != "null" ]]; then
    smartctl -t "$TYPE" "$DRIVE"
    echo
    echo "Waiting $MINUTES minutes for smart $TYPE test to complete"
    echo
    sleep "${MINUTES}m"
  else
    echo "Drive $DRIVE does not support smart $TYPE test"
    echo
  fi
}

function run_short_test() {
  run_test "short" "$SHORT_POLL_MINUTES"
}

function run_long_test() {
  run_test "long" "$LONG_POLL_MINUTES"
}

function run_conveyance_test() {
  run_test "conveyance" "$CONVEYANCE_POLL_MINUTES"
}

function show_test_status() {
  smartctl -l selftest "$DRIVE"
  echo
}

run_short_test
show_test_status

run_conveyance_test
show_test_status

run_long_test
show_test_status

badblocks -t random -b "$BLOCKSIZE" -ws "$DRIVE"

run_long_test
show_test_status

SMART_ATTRIBUTES=$(smartctl -A "$DRIVE" -json | jq '.ata_smart_attributes.table')
REALLOCATED_SECTOR_COUNT=$(echo "$SMART_ATTRIBUTES" | jq '. | map(select(.id == 5)) | .[0].raw.value')
CURRENT_PENDING_SECTOR=$(echo "$SMART_ATTRIBUTES" | jq '. | map(select(.id == 197)) | .[0].raw.value')
OFFLINE_UNCORRECTABLE=$(echo "$SMART_ATTRIBUTES" | jq '. | map(select(.id == 198)) | .[0].raw.value')

echo "Checking smart results"
echo

function check_smart_value() {
  NAME="$1"
  VALUE="$2"
  if [ "$VALUE" -ne 0 ]; then
    echo "$NAME is not 0"
  else
    echo "$NAME is 0"
  fi
}

smartctl -A "$DRIVE"
echo

check_smart_value "Reallocated Sector Count" "$REALLOCATED_SECTOR_COUNT"
check_smart_value "Current Pending Sector" "$CURRENT_PENDING_SECTOR"
check_smart_value "Offline Uncorrectable" "$OFFLINE_UNCORRECTABLE"
