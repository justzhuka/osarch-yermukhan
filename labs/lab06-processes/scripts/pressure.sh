#!/bin/bash
# Lab 6, part 2: free -h before / during / after while memhog.py eats memory.
#
# The recorder and the memory hog run in two DIFFERENT tmux sessions on purpose:
# the user systemd instance has DefaultOOMPolicy=stop, so when the kernel OOM killer
# kills a process, systemd stops every other process in the same scope. In run 1 the
# recorder lived next to the hog and died with it (see README).
#
# Run in the Ubuntu guest:  bash ~/lab06/pressure.sh
cd ~/lab06
rm -f STOP memory-pressure.txt vmstat.txt memhog.log

cat > record.sh <<'EOF'
cd ~/lab06
{ echo "=== BEFORE $(date '+%F %T %Z') ==="; free -h; swapon --show; } > memory-pressure.txt
vmstat -t 2 > vmstat.txt &
while [ ! -f STOP ]; do echo "=== $(date +%T) ==="; free -h; sleep 2; done >> memory-pressure.txt
kill %1
{ echo "=== AFTER $(date '+%F %T %Z') ==="; free -h; } >> memory-pressure.txt
EOF

tmux new-session -d -s rec 'bash ~/lab06/record.sh'          # scope 1: recorder
sleep 6
echo "=== $(date +%T) START python3 memhog.py 64 0.5 ===" >> memory-pressure.txt
tmux new-session -d -s hog 'python3 ~/lab06/memhog.py 64 0.5 > ~/lab06/memhog.log 2>&1; echo "exit code $?" >> ~/lab06/memhog.log'   # scope 2: hog
while tmux has-session -t hog 2>/dev/null; do sleep 1; done
echo "=== $(date +%T) memhog session ended: $(tail -n 1 memhog.log) ===" >> memory-pressure.txt
sleep 10
touch STOP; sleep 3
tail -n 2 memhog.log
