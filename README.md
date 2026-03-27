# NetBox Snap Package

A self-contained [snap](https://snapcraft.io/) package for
[NetBox](https://github.com/netbox-community/netbox).

This snap packages the NetBox application and Gunicorn web server.
**PostgreSQL and Redis are required** but managed outside the snap so you
can use your existing infrastructure.

## Prerequisites

NetBox needs a PostgreSQL database and a Redis server. Install them any
way you like (system packages, Docker, managed service, etc.):

```bash
# Example: system packages on Ubuntu/Debian
sudo apt install postgresql redis-server

# Create the database
sudo -u postgres createuser --superuser netbox
sudo -u postgres createdb -O netbox netbox
```

## Quick Start

```bash
# Install the snap
sudo snap install netbox

# Point at your database and Redis (defaults: localhost, standard ports)
sudo snap set netbox db.host=localhost db.port=5432 \
  db.name=netbox db.user=netbox db.password=""
sudo snap set netbox redis.host=localhost redis.port=6379

# Restart to apply
sudo snap restart netbox

# Create an admin user
sudo netbox.manage createsuperuser

# Open the web UI
xdg-open http://localhost:8080
```

## Configuration

All settings are exposed via `snap set` / `snap get`:

### Database (PostgreSQL)

| Key           | Default     | Description           |
|---------------|-------------|-----------------------|
| `db.host`     | `localhost` | PostgreSQL host       |
| `db.port`     | `5432`      | PostgreSQL port       |
| `db.name`     | `netbox`    | Database name         |
| `db.user`     | `netbox`    | Database user         |
| `db.password` | *(empty)*   | Database password     |

### Cache & Queue (Redis)

| Key              | Default     | Description       |
|------------------|-------------|-------------------|
| `redis.host`     | `localhost` | Redis host        |
| `redis.port`     | `6379`      | Redis port        |
| `redis.password` | *(empty)*   | Redis password    |

### Web Server

| Key         | Default | Description        |
|-------------|---------|------------------  |
| `http.port` | `8080`  | NetBox listen port |

```bash
# Example: change the web UI port
sudo snap set netbox http.port=9090
sudo snap restart netbox

# View all current settings
sudo snap get netbox
```

### Advanced Settings

The full NetBox configuration file is at:

```
/var/snap/netbox/common/config/configuration.py
```

Edit it to change `ALLOWED_HOSTS`, authentication backends, email, plugins,
or any other [NetBox setting](https://docs.netbox.dev/en/stable/configuration/).

> **Note:** Running `snap set netbox …` regenerates this file. If you need
> persistent hand-edits, make your changes *after* the last `snap set` call,
> or manage the file entirely yourself.

## Architecture

The snap runs two daemon services:

| Service                  | Description                       |
|--------------------------|-----------------------------------|
| `netbox.netbox-web`      | Gunicorn WSGI server (NetBox UI)  |
| `netbox.netbox-rqworker` | Background task worker (RQ)       |

Both start automatically after installation. On each start the web service
runs database migrations and collects static files so upgrades are seamless.

## Management Commands

```bash
sudo netbox.manage createsuperuser       # Create admin user
sudo netbox.manage migrate               # Run migrations manually
sudo netbox.manage nbshell               # Interactive NetBox shell
sudo netbox.manage dumpdata --format json # Export data
sudo netbox.manage loaddata fixture.json  # Import data
```

## Data Locations

| Path | Contents |
|------|----------|
| `/var/snap/netbox/common/config/`  | Configuration files |
| `/var/snap/netbox/common/media/`   | Uploaded files |
| `/var/snap/netbox/common/reports/` | Custom reports |
| `/var/snap/netbox/common/scripts/` | Custom scripts |
| `/var/snap/netbox/common/static/`  | Collected static files |

## Service Management

```bash
sudo snap services netbox                     # Status
sudo snap restart netbox                      # Restart all
sudo snap logs netbox.netbox-web              # View logs
sudo snap stop netbox.netbox-rqworker         # Stop worker
```

## Building from Source

```bash
sudo snap install snapcraft --classic
cd community-netbox/
snapcraft
sudo snap install netbox_*.snap --dangerous
```

## License

NetBox is released under the
[Apache 2.0 License](https://github.com/netbox-community/netbox/blob/main/LICENSE.txt).
