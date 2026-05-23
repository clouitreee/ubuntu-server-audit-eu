# L1 Runtime And eBPF

Goal: determine whether modern kernel-level runtime visibility exists and whether eBPF programs are loaded.

## Read-Only Checks

```bash
command -v falco tetragon cilium bpftrace bpftool 2>/dev/null
systemctl status falco tetragon cilium-agent --no-pager 2>/dev/null
bpftool prog list 2>/dev/null
bpftool map list 2>/dev/null
mount | grep -E '/sys/fs/bpf|tracefs|debugfs'
```

## Interpretation

- `checked`: bpftool output and runtime detection status are visible.
- `partial`: bpftrace/bpftool exists, but runtime agents such as Falco/Tetragon/Cilium are absent.
- `blocked`: `bpftool prog list` or map listing requires root/capabilities.

Do not install, start, or enable Falco, Tetragon, Cilium, bpftrace, or bpftool.
