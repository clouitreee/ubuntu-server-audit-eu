# L8 Container Runtime Evidence

Use this layer when Docker, containerd, Podman, Kubernetes, or similar runtimes are present. Container inspection is read-only, but often requires root or membership in the runtime group. If unavailable, mark as `partial` or `blocked` with the exact permission reason.

## Scope

Evidence goals:

- Runtime inventory and socket exposure.
- Running containers, images, published ports, networks, and mounts.
- Privileged containers, added capabilities, host namespaces, host networking, and writable root filesystems.
- Default user posture: root vs non-root container user.
- Bind mounts and possible mounted secrets by path/name only.
- Image age and drift indicators.

## Read-Only Commands

```bash
command -v docker podman containerd ctr crictl kubectl helm 2>/dev/null || true
ls -l /var/run/docker.sock /run/containerd/containerd.sock /run/podman/podman.sock 2>/dev/null || true
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.CreatedSince}} {{.Size}}' 2>/dev/null || true
docker network ls 2>/dev/null || true
docker volume ls 2>/dev/null || true
```

For each container, collect metadata only. Do not print environment variables.

```bash
docker inspect --format 'container={{.Name}} image={{.Config.Image}} user={{.Config.User}} privileged={{.HostConfig.Privileged}} cap_add={{json .HostConfig.CapAdd}} cap_drop={{json .HostConfig.CapDrop}} security_opt={{json .HostConfig.SecurityOpt}} network={{.HostConfig.NetworkMode}} pid={{.HostConfig.PidMode}} ipc={{.HostConfig.IpcMode}} readonly_rootfs={{.HostConfig.ReadonlyRootfs}} binds={{json .HostConfig.Binds}} mounts={{json .Mounts}}' "$container_id"
```

If sudo is explicitly enabled for read-only audit:

```bash
sudo -n docker ps
sudo -n docker inspect --format '...' "$container_id"
sudo -n ctr containers list 2>/dev/null
sudo -n crictl ps 2>/dev/null
```

## Findings To Flag

- `Privileged=true`.
- `User=` empty or `User=root`, unless justified.
- `CapAdd` contains broad capabilities such as `SYS_ADMIN`, `NET_ADMIN`, `SYS_PTRACE`, `DAC_READ_SEARCH`, or `ALL`.
- `NetworkMode=host`, `PidMode=host`, or `IpcMode=host`.
- Docker socket mounted into a container.
- Host paths mounted read-write into sensitive locations.
- Secrets mounted from broad host paths or exposed via filenames.
- Old images with no patch cadence evidence.
- Runtime socket writable by broad groups or unexpected users.

## Secret Handling

Do not run:

```bash
docker inspect "$container_id"
docker exec "$container_id" env
docker compose config
```

unless the output is filtered to avoid environment variables, labels, auth headers, tokens, database URLs, and passwords. Prefer `--format` templates that select safe metadata fields only.

## Reporting

Report container findings separately from host findings. Container drift is often independent from host drift and should include:

- Runtime status.
- Socket permissions.
- Running container count.
- High-risk container count.
- Privileged or host-namespace containers.
- Root/default-user containers.
- Sensitive bind mounts by path only.
- Blocked/partial reasons.
