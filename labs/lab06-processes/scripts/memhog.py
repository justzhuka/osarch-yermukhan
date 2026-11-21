#!/usr/bin/env python3
"""Lab 6: allocate memory in 64 MiB steps until the kernel stops us.

stress-ng --vm dies with SIGILL in this VirtualBox guest (see Lab 2), so this
does the same job: every chunk is filled with non-zero bytes, so the pages are
really touched and must live in RAM or swap.
Usage: python3 memhog.py [step_MiB] [pause_s]
"""
import sys, time

step = int(sys.argv[1]) if len(sys.argv) > 1 else 64
pause = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
chunks = []
t0 = time.time()
while True:
    t = time.time()
    chunks.append(b"\x01" * (step * 1024 * 1024))
    took = time.time() - t
    print(f"{time.strftime('%H:%M:%S')}  +{time.time() - t0:6.1f}s  allocated {len(chunks) * step:5d} MiB  (last {step} MiB took {took:5.2f}s)", flush=True)
    time.sleep(pause)
