#!/bin/sh
# One reading for the CPU panel (modules/Cpu.qml), as key=value lines.
# Sensors differ per machine, so each figure is looked up by name and simply
# left out when the hardware doesn't expose it; the panel hides missing rows.

# CPU package temperature in millidegrees: AMD k10temp/zenpower, Intel coretemp,
# else the first thermal zone
for h in /sys/class/hwmon/hwmon*; do
	case $(cat "$h/name" 2>/dev/null) in
	k10temp | zenpower | coretemp)
		[ -r "$h/temp1_input" ] && echo "temp=$(cat "$h/temp1_input")" && break
		;;
	esac
done

# Average current clock across cores, in MHz
awk '/^cpu MHz/ { s += $4; n++ } END { if (n) printf "freq=%d\n", s / n }' /proc/cpuinfo

# 1-minute load average and the core count it is measured against
read -r load _ </proc/loadavg && echo "load=$load"
echo "cores=$(nproc)"

# Memory in kB: what is in use is total minus available
awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "memtotal=%d\nmemused=%d\n", t, t - a }' /proc/meminfo

# GPU busy percent (amdgpu exposes it in sysfs; others don't)
for g in /sys/class/drm/card*/device/gpu_busy_percent; do
	[ -r "$g" ] && echo "gpu=$(cat "$g")" && break
done

# The three processes using the most CPU right now
ps -eo comm=,%cpu= --sort=-%cpu | head -n 3 | awk '{ printf "top=%s %s\n", $1, $2 }'
