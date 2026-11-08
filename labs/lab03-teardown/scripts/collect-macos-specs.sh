#!/bin/bash
# collect-macos-specs.sh -- Lab 3, second half: CPU, memory and disk facts from the macOS command line.
#
# Usage:  bash collect-macos-specs.sh [output-file]      (default: ./macos-specs.txt)
#
# Written for the bash 3.2 that ships with macOS. No sudo needed.
# Every command is printed (with a "$ " prompt) right before its raw output.

set -u

out="${1:-macos-specs.txt}"

section() {
  printf '\n==================== %s ====================\n' "$1"
}

run() {
  # print the command the way you would type it (quote args that contain spaces/specials)
  local a shown=""
  for a in "$@"; do
    case "$a" in
      *[[:space:]\|\&\;\<\>\(\)\$\*\?]*) shown="$shown \"$a\"" ;;
      *) shown="$shown $a" ;;
    esac
  done
  printf '\n$%s\n' "$shown"
  "$@" 2>&1 || printf '[exit code %s]\n' "$?"
}

collect() {
  echo "Lab 3 -- macOS specs"
  echo "Collected: $(date '+%Y-%m-%d %H:%M:%S %Z')"

  section "System"
  run sw_vers
  run uname -a
  run sysctl -n kern.hv_vmm_present
  run system_profiler SPHardwareDataType

  section "CPU"
  run sysctl -n machdep.cpu.brand_string
  run sysctl -n hw.physicalcpu
  run sysctl -n hw.logicalcpu

  section "Memory"
  run sysctl -n hw.memsize
  run system_profiler SPMemoryDataType

  section "Disk"
  run diskutil list internal physical
  run diskutil info disk0
  run system_profiler SPNVMeDataType
  run system_profiler SPSerialATADataType
  run df -h /
}

collect | tee "$out"
echo
echo "Saved to: $out"
