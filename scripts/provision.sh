#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: provision.sh [-l|-r] [-n inventory-host] [-t tag] [-e tag]

  -l   Provision this machine (default) with playbooks/provision-local.yml
  -r   Provision one remote host with playbooks/provision.yml
  -n   Inventory host to limit to. Local mode defaults to this machine when
       its short hostname matches a host in .ansible/hosts.
  -t   Run only tasks with this tag. Repeatable.
  -e   Skip tasks with this tag. Repeatable.

Examples:
  ./scripts/provision.sh
  ./scripts/provision.sh -n GameBox -t packages
  ./scripts/provision.sh -r -n mini-cloud -t k3s
EOF
}

mode="local"
limit=""
ansible_args=()

while getopts ':t:e:n:rlh' flag; do
  case "${flag}" in
  t) ansible_args+=(--tags "${OPTARG}") ;;
  e) ansible_args+=(--skip-tags "${OPTARG}") ;;
  n) limit="${OPTARG}" ;;
  r) mode="remote" ;;
  l) mode="local" ;;
  h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

os_label() {
  local name
  name="$(uname -s)"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    name="${NAME:-$name}"
  fi
  printf '%s\n' "$name"
}

install_prerequisites() {
  local missing=()
  is_installed git || missing+=(git)
  is_installed ansible-playbook || missing+=(ansible)
  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  echo "Installing: ${missing[*]}"
  case "$(uname -s)" in
  Darwin)
    ensure_brew_path
    if ! is_installed brew; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ensure_brew_path
    fi
    brew install "${missing[@]}"
    ;;
  Linux)
    if is_installed dnf; then
      run_privileged dnf install -y "${missing[@]}"
    elif is_installed apt-get; then
      run_privileged env DEBIAN_FRONTEND=noninteractive apt-get update
      run_privileged env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    else
      echo "Unsupported Linux distribution. Install git and ansible, then rerun."
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s)"
    exit 1
    ;;
  esac
}

repo_from_script() {
  local script_path script_dir candidate
  script_path="${BASH_SOURCE[0]:-}"
  if [[ -z "$script_path" || ! -f "$script_path" ]]; then
    return 1
  fi
  script_dir="$(cd "$(dirname "$script_path")" && pwd)"
  candidate="$(cd "${script_dir}/.." && pwd)"
  if [[ -f "${candidate}/ansible.cfg" && -f "${candidate}/.ansible/hosts" ]]; then
    repo_root="$candidate"
    return 0
  fi
  return 1
}

ensure_repo() {
  local repo_url
  if repo_from_script; then
    return 0
  fi

  repo_url="https://github.com/vekjja/provisions.git"
  if [[ -d "${HOME}/git/Provisions/.git" ]]; then
    repo_root="${HOME}/git/Provisions"
  elif [[ -d "${HOME}/git/provisions/.git" ]]; then
    repo_root="${HOME}/git/provisions"
  else
    repo_root="${HOME}/git/Provisions"
    mkdir -p "${HOME}/git"
    echo "Cloning ${repo_url} into ${repo_root}"
    git clone "$repo_url" "$repo_root"
    return 0
  fi

  echo "Updating ${repo_root}"
  if ! git -C "$repo_root" pull --ff-only; then
    echo "git pull --ff-only failed. Continuing with the existing checkout."
  fi
}

host_in_group() {
  local host="$1" group="$2" current="" line name host_lc name_lc
  host_lc="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == \[*\] ]]; then
      current="${line#[}"
      current="${current%]}"
      continue
    fi
    [[ "$current" == "$group" ]] || continue
    name="${line%%[[:space:]]*}"
    name_lc="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    if [[ "$name_lc" == "$host_lc" ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < .ansible/hosts
  return 1
}

list_group() {
  local group="$1" current="" line name
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == \[*\] ]]; then
      current="${line#[}"
      current="${current%]}"
      continue
    fi
    [[ "$current" == "$group" ]] || continue
    name="${line%%[[:space:]]*}"
    printf '  %s\n' "$name"
  done < .ansible/hosts
}

echo "Running setup for $(os_label)"
install_prerequisites

repo_root=""
ensure_repo
cd "$repo_root"

if [[ "$mode" == "remote" ]]; then
  playbook="playbooks/provision.yml"
  group="remote"
else
  playbook="playbooks/provision-local.yml"
  group="local"
fi

vault_file="${repo_root}/.ansible/vault_password"
if [[ ! -f "$vault_file" ]]; then
  if [[ "$mode" == "remote" ]]; then
    echo "Missing ${vault_file}."
    echo "Remote provisioning decrypts playbooks/group_vars/vault.yml. Create that gitignored file with the vault password, then rerun."
    exit 1
  fi
  local_vault="$(mktemp)"
  chmod 600 "$local_vault"
  printf '%s\n' "local-only" >"$local_vault"
  export ANSIBLE_VAULT_PASSWORD_FILE="$local_vault"
  echo "No .ansible/vault_password file. The local playbook does not use the vault."
fi

requested="$limit"
if [[ -z "$requested" ]]; then
  if [[ "$mode" == "remote" ]]; then
    echo "Remote mode provisions one host. Pass -n <inventory-host>."
    echo "Hosts in [remote]:"
    list_group remote
    exit 1
  fi
  short_host="$(hostname -s 2>/dev/null || hostname)"
  if ! limit="$(host_in_group "$short_host" local)"; then
    echo "Hostname '${short_host}' is not in [local]."
    echo "Pass -n <inventory-host>. Hosts in [local]:"
    list_group local
    exit 1
  fi
elif ! limit="$(host_in_group "$requested" "$group")"; then
  echo "Host '${requested}' is not in [${group}]."
  echo "Hosts in [${group}]:"
  list_group "$group"
  exit 1
fi

echo "Running: ansible-playbook${ansible_args[*]+ ${ansible_args[*]}} --limit ${limit} ${playbook}"
# Become prompts read stdin. A curl|bash install has the script on stdin, so
# give ansible-playbook the terminal when one is available.
if ( : </dev/tty ) 2>/dev/null; then
  ansible-playbook ${ansible_args[@]+"${ansible_args[@]}"} --limit "$limit" "$playbook" </dev/tty
else
  ansible-playbook ${ansible_args[@]+"${ansible_args[@]}"} --limit "$limit" "$playbook"
fi
