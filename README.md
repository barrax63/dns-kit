# DNS Kit (Pi-hole & dnscrypt-proxy)

**DNS Kit** is an open-source template that quickly sets up a comprehensive DNS privacy and security solution featuring Pi-hole with DNSCrypt-Proxy for encrypted DNS queries.

### What's included

✅ [**Pi-hole**](https://pi-hole.net/) - Network-wide ad blocking and DNS sinkhole with powerful web interface

✅ [**DNSCrypt-Proxy**](https://github.com/DNSCrypt/dnscrypt-proxy) - Flexible DNS proxy with support for encrypted DNS protocols (DNSCrypt, DNS-over-HTTPS, Anonymized DNS)

### What you can build

⭐️ **Network-Wide Ad Blocking** - Block ads and trackers for all devices on your network

⭐️ **Encrypted DNS** - Protect your DNS queries from eavesdropping and manipulation using DNSCrypt or DNS-over-HTTPS

⭐️ **Privacy-First DNS** - Run your own recursive DNS resolver with Unbound, eliminating third-party DNS providers

⭐️ **Anonymized DNS** - Route DNS queries through relay servers for enhanced privacy

⭐️ **Custom DNS Filtering** - Create custom blocklists and allowlists for granular control

## Installation

### Prerequisites

- Docker and Docker Compose installed on your system
- Basic understanding of DNS and networking

### Running Pi-hole DNS Kit using Docker Compose

#### Standard Setup

```bash
git clone <your-repository-url>
cd <repository-name>
cp .env.example .env # Update the STANDARD CONFIGURATION section inside
docker compose up -d
```

> [!IMPORTANT]
> Make sure to update the following variables in your `.env` file:
> - `WEBSERVER_PASSWORD` - Set a strong password for Pi-hole admin interface
> - `TZ` - Your timezone (e.g., `Europe/Berlin`, `America/New_York`)

## ⚡️ Quick start and usage

The Pi-hole DNS Kit is built around a Docker Compose file that's pre-configured with network isolation, security hardening, and persistent storage.

After completing the installation steps above, access the Pi-hole admin interface:

- **Local Access**: <http://localhost/admin> or <http://YOUR_SERVER_IP/admin>

### First-time Setup

1. **Log in to Pi-hole**: Use the password you set in `WEBSERVER_PASSWORD`
2. **Configure DNS Settings**: 
   - Go to Settings → DNS
   - Verify your upstream DNS servers (dnscrypt-proxy on port 5053)
3. **Update Blocklists**: 
   - Go to Group Management → Adlists
   - Default lists are pre-configured, update them via Tools → Update Gravity
4. **Configure Network Devices**: 
   - Point your router's DNS to your Pi-hole server IP
   - Or configure individual devices to use Pi-hole as their DNS server
5. **Monitor Activity**: 
   - Dashboard shows real-time DNS query statistics
   - Query Log shows detailed DNS request history

### DNS Architecture Options

This kit uses the following DNS resolution strategy:

```
Client → Pi-hole (filtering) → DNSCrypt-Proxy (encryption) → Upstream DNS Servers
```

**Benefits**: Encrypted DNS queries, multiple protocol support, anonymized DNS

## Containers and access

The kit consists of multiple containers with restricted access for enhanced security.
For more information on how to access the services, please refer to the table below.

| Container          | Version     | Hostname        | Port(s)      | Network accessible?      |
|--------------------|-------------|-----------------|--------------|------------------------- |
| `pihole`           | `latest`    | pihole          | 53, 80, 443  | From network             |
| `dnscrypt-proxy`   | `latest`    | dnscrypt-proxy  | 5053         | From Docker network only |

## Upgrading

### Update all containers to latest versions

```bash
git pull
docker compose up -d --pull always
```

This will:
- Pull the latest code changes
- Download the latest container images
- Recreate containers with new versions
- Preserve all your data in volumes (blocklists, settings, query history)

### Enable auto-updates

You can enable automatic updates by adding a cron job. Run:

```bash
crontab -u <USER> -e
```

Add this entry:

```bash
# Every Sunday at 00:00 run git pull and compose up with latest images
0 0 * * 0 cd /home/<USER>/dns-kit && /usr/bin/git pull && /usr/bin/docker compose pull && /usr/bin/docker compose up -d >> /home/<USER>/dns-kit/dns-kit-update.log 2>&1
```

### Update Pi-hole Gravity (Blocklists)

Pi-hole automatically updates blocklists weekly. To manually update use the web interface:
Tools → Update Gravity

## 👓 Recommended reading

### Official Documentation

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [DNSCrypt-Proxy Wiki](https://github.com/DNSCrypt/dnscrypt-proxy/wiki)

### Key Features

#### Pi-hole
- **Ad Blocking**: Block ads at the DNS level for all devices
- **Dashboard**: Beautiful web interface with real-time statistics
- **Query Log**: Detailed logging of all DNS requests
- **Whitelist/Blacklist**: Granular control over blocked/allowed domains
- **Group Management**: Organize clients and apply different filtering rules
- **DHCP Server**: Optional DHCP server functionality
- **Conditional Forwarding**: Forward specific domains to specific DNS servers

#### DNSCrypt-Proxy
- **DNSCrypt Protocol**: Encrypt DNS queries using DNSCrypt
- **DNS-over-HTTPS (DoH)**: Support for DoH protocol
- **DNS-over-TLS (DoT)**: Support for DoT protocol
- **Anonymized DNS**: Route queries through relay servers
- **DNSSEC**: Validate DNS responses
- **Cloaking**: Override DNS responses for specific domains
- **Query Logging**: Log all DNS queries for debugging

### Privacy & Security Resources

- [DNS Privacy Project](https://dnsprivacy.org/)
- [Understanding DNS Security](https://www.cloudflare.com/learning/dns/dns-security/)
- [DNSCrypt vs DNS-over-HTTPS](https://www.quad9.net/news/blog/dns-over-tls-vs-dns-over-https/)
- [Pi-hole Security Best Practices](https://docs.pi-hole.net/main/security/)

## Configuration Guide

### Environment Variables

The `.env.example` file contains all configurable options.

### Security Features

This setup includes several security hardening measures:

- **No new privileges**: Containers cannot gain additional privileges
- **AppArmor**: Additional security layer for container isolation
- **Capability dropping**: Minimal required capabilities only
- **Network isolation**: Internal network for service communication
- **Resource limits**: CPU and memory constraints to prevent resource exhaustion
- **Health checks**: Automatic container health monitoring
- **Secure DNS**: Encrypted DNS queries prevent eavesdropping
- **DNSSEC**: Validate DNS responses to prevent spoofing

## 📜 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 💬 Support

### Community Resources

- [Pi-hole Discourse](https://discourse.pi-hole.net/)
- [Pi-hole Reddit](https://www.reddit.com/r/pihole/)
- [DNSCrypt GitHub Discussions](https://github.com/DNSCrypt/dnscrypt-proxy/discussions)

### Getting Help

- **Report Bugs**: Use GitHub Issues to report bugs or problems
- **Feature Requests**: Share your ideas for new features
- **Community Support**: Join Pi-hole Discourse for real-time help and discussions
- **Documentation**: Check the official docs for detailed guides

### Useful Links

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [DNSCrypt Server List](https://dnscrypt.info/public-servers)
- [Pi-hole Regex Database](https://github.com/mmotti/pihole-regex)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Acknowledgments

- [Pi-hole](https://pi-hole.net/) - The amazing network-wide ad blocker
- [DNSCrypt-Proxy](https://github.com/DNSCrypt/dnscrypt-proxy) - Flexible DNS proxy with encryption support
- [Docker](https://www.docker.com/) - Containerization platform
