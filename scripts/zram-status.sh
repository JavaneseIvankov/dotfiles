#!/usr/bin/env bash
# zram-status.sh - Simple zram performance summary

ZRAM_DEV="/sys/block/zram0"

# Get stats
read orig compr mem_used mem_limit mem_max same pages_comp huge huge_since < "$ZRAM_DEV/mm_stat"

# Compression ratio
if [ "$compr" -gt 0 ]; then
    ratio=$(awk -v o="$orig" -v c="$compr" 'BEGIN { printf "%.2f", o/c }')
else
    ratio="N/A"
fi

# Human-readable sizes
h_orig=$(numfmt --to=iec $orig)
h_compr=$(numfmt --to=iec $compr)
h_mem=$(numfmt --to=iec $mem_used)
h_mem_max=$(numfmt --to=iec $mem_max)

echo "=== ZRAM Status ==="
echo "Original data size : $h_orig"
echo "Compressed size    : $h_compr"
echo "RAM used (current) : $h_mem"
echo "RAM used (max)     : $h_mem_max"
echo "Compression ratio  : $ratio"
echo "Same pages         : $same"
echo ""

echo "=== Swap Usage ==="
swapon --show --bytes | awk 'NR==1 || /zram|file/'

