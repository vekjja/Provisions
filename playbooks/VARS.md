## 🧩 Vars reference (`group_vars/` + `host_vars/`)

This doc is the **single source of truth** for variables used by the playbooks/roles in this repo.

### 🧠 Where to put vars (and what wins)

Ansible loads vars with precedence roughly like:

- **`playbooks/group_vars/all.yml`**: defaults for *every* host (shared baseline)
- **`playbooks/host_vars/<hostname>`** (or `.yml`): per-host overrides (wins over group defaults)

Optional (not currently present, but supported by Ansible):

- **`playbooks/group_vars/local.yml`**: defaults for the `local` inventory group
- **`playbooks/group_vars/remote.yml`**: defaults for the `remote` inventory group

> ✅ Hostnames must match inventory entries in `.ansible/hosts`.

### 🏷️ Inventory groups used here

- **`local`**: local workstation(s) (`ansible_connection=local`)
- **`remote`**: remote machines (SSH)

---

## 🧑‍💻 Workstation + general vars

### 📦 `unix_packages` (baseline packages)

Used by: `roles/packages/tasks/unix.yml`  
Applies to: macOS + Linux (installed via the OS package manager)

```yaml
# playbooks/group_vars/all.yml
unix_packages:
  - git
  - curl
  - zsh
```

Notes:
- On macOS, packages are installed via Homebrew (through Ansible’s package abstraction).
- On Linux, packages are installed via the distro package manager.

### 📦 `packages` (host-specific packages)

Used by: `roles/packages/tasks/unix.yml`  
Applies to: macOS + Linux

```yaml
# playbooks/host_vars/macbook
packages:
  - kubectl
  - k9s
```

### 🍺 `casks` (macOS apps)

Used by: `roles/packages/tasks/darwin.yml`  
Applies to: macOS only

```yaml
# playbooks/host_vars/macbook
casks:
  - iterm2
  - google-chrome
```

### 🪟 `windows.packages` (Chocolatey packages)

Used by: `roles/packages/tasks/windows.yml`  
Applies to: Windows only

```yaml
# playbooks/group_vars/all.yml (or playbooks/host_vars/<winhost>.yml)
windows:
  packages:
    - git
    - 7zip
```

### 🔤 `nerd_fonts` (Nerd Fonts to install)

Used by:
- Linux: `roles/nerd-fonts/tasks/unix.yml`
- macOS: `roles/nerd-fonts/tasks/darwin.yml`
- Windows: `roles/nerd-fonts/tasks/windows.yml`

```yaml
# playbooks/group_vars/all.yml
nerd_fonts:
  - FiraMono
  - JetBrainsMono
```

Notes:
- Values must match Nerd Fonts release zip names (e.g. `JetBrainsMono.zip`).

### 📁 `unix_directories` (directories to ensure exist)

Used by: `roles/system/tasks/unix.yml`  
Applies to: macOS + Linux

```yaml
# playbooks/group_vars/all.yml
unix_directories:
  - ~/.history
  - ~/.config
```

### 📄 `files` (dotfiles/configs to link or copy)

Used by: `roles/files/tasks/main.yml`  
Applies to: macOS + Linux + Windows

```yaml
# playbooks/host_vars/macbook
files:
  - { src: "dotfiles/.zshrc-mac", dest: "~/.zshrc" }
  - { src: "dotfiles/.zshrc-common", dest: "~/.zshrc-common" }
  - { src: "configs/ssh.config", dest: "~/.ssh/config" }
```

How it behaves:
- **`src` is relative to `assets/`** (example above maps to `assets/dotfiles/.zshrc-mac`).
- **Local group** (`local`): creates **symlinks** into your working tree (fast iteration).
- **Remote group** (`remote`): **copies** files to the host.

---

## 🛰️ Remote / homelab vars (Debian-focused)

### 🌐 `static_ip` (Debian netplan + /etc/hosts)

Used by: `roles/network/tasks/debian.yml`  
Applies to: Debian/Ubuntu hosts (netplan)

```yaml
# playbooks/host_vars/mini-cloud.yml
static_ip:
  interface: enp4s0
  address: 10.0.0.10
  gateway: 10.0.0.1
  netmask: 16          # optional (default: 24)
  nameservers:         # optional (default: [8.8.8.8, 8.8.4.4])
    - 10.0.0.1
    - 1.1.1.1
  search:              # optional
    - home.arpa
  hostname: mini-cloud # optional (defaults to current hostname)
```

What it does:
- Installs netplan, writes `/etc/netplan/99-static-ip-config.yaml`, runs `netplan apply`
- Ensures a line for the host exists in `/etc/hosts`

### 🔥 `firewall_rules` (UFW)

Used by: `roles/network/tasks/debian.yml`  
Applies to: Debian/Ubuntu with UFW

```yaml
firewall_rules:
  - { port: "22", proto: "tcp", comment: "SSH" }
  - { port: "6443", proto: "tcp", comment: "Kubernetes API" }
  # Optional fields: rule, from
  - { rule: "allow", from: "10.0.0.0/16", port: "2049", proto: "tcp", comment: "NFS" }
```

Notes:
- When both `static_ip` and `firewall_rules` are defined, the role also adds helper rules to allow NFS from your local network.

### 💾 `fs_mounts` (fstab entries)

Used by: `roles/fstab/tasks/main.yml`  
Applies to: primarily remote Linux

```yaml
fs_mounts:
  - path: /mnt/ssd/movies
    src: "UUID=0CB81103B810ED48"
    fstype: ntfs
    opts: "defaults,nobootwait,nofail,x-systemd.device-timeout=5"
```

**Recommended mount options for boot performance:**
- `nobootwait`: Don't wait for mount to complete before continuing boot (Ubuntu/Debian)
- `nofail`: Don't halt boot if mount fails
- `x-systemd.device-timeout=5`: Limit device discovery wait time to 5 seconds (prevents long boot delays when drives aren't available)

### 📤 `nfs_shares` (NFS server exports)

Used by: `roles/nfs/tasks/debian.yml`  
Applies to: Debian/Ubuntu NFS server

```yaml
nfs_shares:
  - "/mnt/ssd/movies *(rw,no_root_squash,insecure,async,no_subtree_check,anonuid=1000,anongid=1000)"
  - "/mnt/hdd/tera *(rw,no_root_squash,insecure,async,no_subtree_check,anonuid=1000,anongid=1000)"
```

### ☸️ `k3s` (K3s install + kubeconfig fetch)

Used by: `roles/k3s/tasks/unix.yml`  
Applies to: Linux (when `k3s` is defined)

```yaml
k3s:
  args:
    - --disable=traefik
    - --tls-san 10.0.0.10
  kubeconfig: /etc/rancher/k3s/k3s.yaml
  local_kubeconfig: "{{ lookup('env', 'HOME') }}/.kube/mini-cloud"
```

Notes:
- `args` is appended to the installer command: `/tmp/k3s.sh {{ k3s.args | join(' ') }}`
- The `get-kubeconfig` tag fetches `k3s.kubeconfig.remote` to `k3s.kubeconfig.local`

### 🧩 `k3s_tuning` (inotify + NOFILE tuning for Kubernetes log tailing)

Used by: `roles/k3s/tasks/tuning.yml`  
Applies to: Linux/systemd hosts where `k3s` is defined

This is primarily to prevent log agents (like **Grafana Alloy**) from spamming:
`failed to create fsnotify watcher: too many open files`

Also configures shutdown timeouts to reduce long shutdown times caused by containerd.

```yaml
k3s_tuning:
  enabled: true
  nofile_limit: 1048576
  inotify_max_user_watches: 1048576
  inotify_max_user_instances: 8192
  inotify_max_queued_events: 32768
  fs_file_max: 2097152
  shutdown_timeout_sec: 30  # Reduces containerd shutdown delays (default: 30s, systemd default: 90s)
```

### 🔐 `wireguard` (WireGuard server + client configs)

Used by: `roles/wireguard/tasks/debian.yml` + templates  
Applies to: Debian/Ubuntu (WireGuard)

```yaml
wireguard:
  server_endpoint: livingroom.cloud  # required for client configs
  interfaces:
    - name: wg0
      address: 10.0.10.0/24
      # Optional: private_key (if omitted, generated on host)
      peers:
        - name: workMac
          allowed_ips: 10.0.10.2/32  # required
          # Optional: preshared_key
```

Exact behavior:
- Generates server keys at `/etc/wireguard/<iface>_{private,public}.key` (unless you supply `private_key`)
- Generates per-peer keys under `/etc/wireguard/clients/`
- Renders `/etc/wireguard/<iface>.conf` and `wg-quick@<iface>` services
- Writes client configs to `/etc/wireguard/clients/<iface>_<peer>.conf`

Dependencies/interaction:
- For NAT, WireGuard uses **`static_ip.interface`** if present; otherwise it auto-detects the default route interface.

---

## 🧰 Misc / special cases

### 🟦 `golang`

Used by: `roles/golang/tasks/main.yml` (gate)  
Behavior varies by OS.

Current behavior:
- The role only runs when `golang` is defined.
- On macOS (`ansible_facts['distribution'] == 'Darwin'`): runs the mac path.
- On Linux: runs the unix path.

Minimal example to enable the role:

```yaml
golang: true
```


