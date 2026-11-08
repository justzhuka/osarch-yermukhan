#!/usr/bin/env bash
# collect-linux-specs.sh -- Lab 3, second half: CPU, memory and disk facts from the Linux command line.
#
# Usage:  bash collect-linux-specs.sh [output-file]      (default: ./linux-specs.txt)
#
# Every command is printed (with a "$ " prompt) right before its raw output,
# so the text file shows which command produced which number.
# dmidecode needs root, so the script asks for the sudo password once at the start.

set -u

out="${1:-linux-specs.txt}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=()
else
  SUDO=(sudo)
  sudo -v || echo "warning: sudo failed, the dmidecode sections will show an error" >&2
fi

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
  echo "Lab 3 -- Linux specs"
  echo "Collected: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Note: if this runs inside a VM, every number below describes the VIRTUAL machine, not the host."

  section "System / is this a VM?"
  run uname -a
  run hostnamectl
  run systemd-detect-virt
  run "${SUDO[@]}" dmidecode -s system-manufacturer
  run "${SUDO[@]}" dmidecode -s system-product-name

  section "CPU"
  run lscpu
  run nproc
  run grep -m1 "model name" /proc/cpuinfo

  section "Memory"
  run free -h
  run grep -E "MemTotal|SwapTotal" /proc/meminfo
  run "${SUDO[@]}" dmidecode -t memory
  if command -v lshw >/dev/null 2>&1; then
    run "${SUDO[@]}" lshw -short -C memory
  fi

  section "Disk"
  run lsblk -d -o NAME,MODEL,SIZE,ROTA,TRAN,TYPE
  run lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
  run df -h /
  if command -v smartctl >/dev/null 2>&1; then
    for dev in /dev/sd? /dev/nvme?n1; do
      [ -e "$dev" ] && run "${SUDO[@]}" smartctl -i "$dev"
    done
  fi
}

collect | tee "$out"
echo
echo "Saved to: $out"
