# Wireguard VPN Setup

This Ansible role sets up a Wireguard VPN server using Docker containers.

## Directory Structure

```
devops/ansible/wireguard/
├── inventory/
│   └── hosts.ini                    # Inventory file with host groups
├── playbooks/
│   ├── roles/
│   │   └── wireguard/              # Wireguard role
│   │       ├── defaults/           # Default variables
│   │       ├── handlers/           # Service handlers
│   │       ├── tasks/             # Role tasks
│   │       └── templates/         # Configuration templates
│   └── wireguard.yml              # Main playbook
└── README.md                       # This file
```

## Configuration

1. Copy and edit the inventory file:
   ```bash
   cp inventory/hosts.ini.sample inventory/hosts.ini
   ```

2. Update the following in `inventory/hosts.ini`:
   - Server IP address
   - SSH user
   - SSH private key path

3. Customize variables in `playbooks/roles/wireguard/defaults/main.yml`:
   - `wireguard_network`: VPN network CIDR (default: 172.16.50.0/24)
   - `wireguard_endpoint`: Server public IP
   - `wireguard_port`: UDP port (default: 51820)
   - `wireguard_peers`: Number of peer configurations to generate

## Usage

Deploy the Wireguard server:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/wireguard.yml
```

## Generated Configurations

After running the playbook:
1. Server configuration will be in `~/wireguard/config/wg0.conf`
2. Peer configurations will be in `~/wireguard/config/peerN/peerN.conf`
3. QR codes for mobile clients will be in `~/wireguard/config/peerN/peerN.png` 