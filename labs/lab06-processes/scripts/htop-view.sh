#!/bin/bash
# Lab 6, part 1: start the chosen process (ping) from this shell, so this bash is its parent,
# then show both in htop's tree view. Run in the Ubuntu guest: bash htop-view.sh
ping 127.0.0.1 > /dev/null &
echo $! > /tmp/lab6-ping.pid
echo "ping PID $!, parent (this bash) PID $$"
sleep 1
htop -t -p "$!,$$"
