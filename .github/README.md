# 🛠️ Provisions

Your personal “push-button” setup for **workstations** (local) and **servers** (remote) using **Ansible** — plus Helm values/scripts for a small homelab stack.

## 🚀 Quickstart

### 🍎 macOS / 🐧 Linux (one-liner)

This bootstrap will:
- Install **Git** and **Ansible** when they are missing (Homebrew on macOS, `dnf` on Fedora/RHEL, `apt` on Debian/Ubuntu)
- Use the checkout you launched it from. The one-liner clones to `~/git/Provisions` on a new machine
- Run the **local** playbook limited to the inventory host that matches this machine

```bash
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/provision.sh | bash
```

On a machine that is already cloned, run it from the repo:

```bash
./scripts/provision.sh
```

The local inventory group uses `ansible_connection=local` for every host, so the script always passes `--limit`. It matches `hostname -s` to `.ansible/hosts` (for example `GameBox`).

### 🎛️ Custom arguments

```bash
./scripts/provision.sh -n GameBox -t packages
./scripts/provision.sh -e nerd-fonts
./scripts/provision.sh -r -n mini-cloud -t k3s
```

The same flags work with the one-liner (`bash -s -- -n GameBox -t packages`).

## 🧩 Tags (what you can run)

- **💻 Workstation**: `packages`, `casks`, `wakeonlan`, `nerd-fonts`, `shell`, `files`, `fstab`, `hostname`, `go`
- **🧪 Homelab/remote**: `config`, `filesystem`, `network`, `ufw`, `static-ip`, `wireguard`, `k3s`, `smb`, `nfs`

## 🛰️ Remote host provisioning

Remote mode runs `playbooks/provision.yml` against one host in the `remote` group. It needs SSH access from `.ansible/ssh.config` and the gitignored vault password at `.ansible/vault_password`.

```bash
./scripts/provision.sh -r -n mini-cloud
```

## 🗺️ Inventory + playbooks (quick map)

- **📒 Inventory**: `.ansible/hosts`
  - `[local]` (uses `ansible_connection=local`)
  - `[remote]` (SSH)
- **💻 Local playbook**: `playbooks/provision-local.yml` (targets `hosts: local`)
- **🛰️ Remote playbook**: `playbooks/provision.yml` (targets `hosts: remote`)

## 🗂️ Repo layout

- **`playbooks/`**: entrypoints + `group_vars/` + `host_vars/`
- **`roles/`**: Ansible roles
- **`assets/`**: dotfiles/configs/themes/docs
- **`k3s/helm/`**: Helm charts/values used by the cluster
- **`scripts/`**: bootstrap + K3s helper scripts

## 📚 Docs (deeper dives)

- **Playbooks usage**: **[`playbooks/README.md`](../playbooks/README.md)**
- **Vars reference**: **[`playbooks/VARS.md`](../playbooks/VARS.md)**

<!-- ## 🪟 Windows (bootstrap)

This sets up WSL + WinRM prerequisites; after it completes, open WSL (Debian) and run the Linux one-liner above.

```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
``` -->