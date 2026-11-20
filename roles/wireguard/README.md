# WireGuard VPN Server Role

This Ansible role installs and configures a WireGuard VPN server on Debian/Ubuntu systems.

## Features

- Installs WireGuard packages
- Enables IP forwarding
- Generates private/public keys automatically (if not provided)
- Creates WireGuard server interface configuration
- Manages WireGuard service
- Configures firewall rules (UFW)

## Configuration

Add WireGuard server configuration to your `group_vars/all.yml` or `host_vars/<hostname>.yml` file:

### Example: Server Configuration

The role automatically generates client keys and creates client config files. Just provide a name for each client:

```yaml
debian:
  wireguard:
    server_endpoint: vpn.example.com  # Server's public IP or hostname
    interfaces:
      - name: wg0
        address: 10.0.0.1/24
        peers:
          - name: client1
            allowed_ips: 10.0.0.2/32
          - name: client2
            allowed_ips: 10.0.0.3/32
```

The role will automatically:
- Generate client key pairs
- Add client public keys to the server config
- Create ready-to-use client config files in `/etc/wireguard/clients/`

Client config files will be created at:
- `/etc/wireguard/clients/wg0_client1.conf`
- `/etc/wireguard/clients/wg0_client2.conf`

Just copy the client config file to the client device and import it into WireGuard!

## Configuration Options

### Interface Options (Required)

- `name` (required): Interface name (e.g., `wg0`)
- `address` (required): Server IP address and CIDR (e.g., `10.0.0.1/24`)
- `peers` (required): List of client peer configurations

### WireGuard Options (Required)

- `server_endpoint` (required for client configs): Server's public IP or hostname

### Interface Options (Optional)

- `private_key`: Server private key (auto-generated if not provided)

### Peer Options (Required)

- `name` (required): Client name (used for key generation and config file naming)
- `allowed_ips` (required): Client IP address/CIDR (e.g., `10.0.0.2/32`)

### Peer Options (Optional)

- `preshared_key`: Optional preshared key for additional security

## Standard Defaults

- **Port**: 51820/UDP (WireGuard standard port, hardcoded)
- **Interface name**: Typically `wg0` (configurable via `name`)

## Key Generation

### Server Keys

If you don't provide a `private_key`, the role will automatically generate one using `wg genkey`. The generated keys are stored in:
- `/etc/wireguard/<interface-name>_private.key`
- `/etc/wireguard/<interface-name>_public.key`

To retrieve the server's public key after generation:
```bash
cat /etc/wireguard/wg0_public.key
```

### Client Keys

Client keys are automatically generated for each peer. The role:
- Generates client key pairs for each peer
- Adds client public keys to the server config
- Creates ready-to-use client config files in `/etc/wireguard/clients/`

Just copy the client config file to the client device and import it into WireGuard!

The role also packs the client configs into one tar and fetches it back to the machine running Ansible:

- `~/.wireguard/<inventory-hostname>-clients.tar`
- Override the directory with `wireguard.client_config_dir`
- The archive is mode `0600` and contains `<interface>_<peer>.conf` files
- Fetch only: `ansible-playbook playbooks/provision.yml --limit mini-cloud --tags get-client-configs`

## Usage

Add the role to your playbook:

```yaml
roles:
  - { role: wireguard, tags: ['wireguard'] }
```

Run the playbook:
```bash
ansible-playbook playbooks/provision.yml --tags wireguard
```

## Notes

- The role automatically enables IP forwarding (`net.ipv4.ip_forward = 1`)
- Firewall rules are automatically configured if `firewall_rules` is defined in your vars
- Configuration files are created with mode `0600` (root only)
- The service is automatically enabled and started for each configured interface
- This role is designed for server configuration only
