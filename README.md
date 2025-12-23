# internetip

Bash toolkit for public IP address management. Detect your internet-facing IP, validate addresses, monitor for changes, and notify remote servers - ideal for dynamic DNS, server monitoring, and automated IP registration.

## Scripts

| Script | Version | Purpose | Exported Function |
|--------|---------|---------|-------------------|
| `internetip` | 2.3.0 | Fetch and display public IP | `get_internet_ip` |
| `validip` | 1.1.0 | Validate IPv4 address format | `valid_ip` |
| `watchip` | 2.1.0 | Monitor for IP changes | `watch_ip` |

All scripts follow the [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard) and support dual-purpose usage (executable or sourceable as a module).

## Installation

```bash
# Clone and install
git clone https://github.com/OkusiAssociates/internetip.git
sudo ./internetip/internetip install

# Or from within the repo
sudo ./internetip install

# Update existing installation
sudo internetip update

# Uninstall
sudo internetip uninstall
```

Installs symlinks to `/usr/local/bin` and bash completion to `/etc/bash_completion.d`.

## Usage

### internetip

```bash
internetip              # Display current public IP
internetip -s           # Fetch IP and call callback URL
internetip -q           # Quiet mode (suppress info messages)
internetip -v           # Verbose mode
internetip -sv          # Combined options
internetip showurl      # Show current URL configuration
internetip -h           # Show help

# Administration (requires root)
sudo internetip install              # Install to /usr/local/bin
sudo internetip update               # Git pull + reinstall
sudo internetip uninstall            # Remove from /usr/local/bin
sudo internetip seturl               # Configure callback URL interactively
sudo internetip seturl='https://example.com?host=HOSTNAME&ip=GATEWAY_IP'
sudo internetip unseturl             # Remove URL configuration
```

**Commands:**

| Command | Description |
|---------|-------------|
| `install` | Install scripts to /usr/local/bin (requires root) |
| `update` | Git pull and reinstall (requires root) |
| `uninstall` | Remove scripts from /usr/local/bin (requires root) |
| `seturl [URL]` | Configure system-wide callback URL (requires root) |
| `showurl` | Show current callback URL configuration |
| `unseturl` | Remove system-wide URL configuration (requires root) |

**Options:**

| Option | Description |
|--------|-------------|
| `-s, -c, --call-url` | Call callback URL after fetching IP |
| `-v, --verbose` | Increase verbosity |
| `-q, --quiet` | Suppress informational output |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

Long options (`--install`, `--set-url`, etc.) are also supported.

**URL Configuration:**

The callback URL supports template variables expanded at runtime. The `$` prefix is optional (`HOSTNAME` works the same as `$HOSTNAME`):

| Variable | Description | Example |
|----------|-------------|---------|
| `HOSTNAME` | System hostname | `webserver01` |
| `GATEWAY_IP` | Fetched public IP | `203.0.113.45` |
| `SCRIPT_NAME` | Script name | `internetip` |
| `VERSION` | Script version | `2.3.0` |

```bash
# Configure system-wide (writes to /etc/profile.d/ and systemd)
sudo internetip seturl
# Enter: https://example.com/ip.php?host=HOSTNAME&ip=GATEWAY_IP

# Or pass URL directly
sudo internetip seturl='https://example.com/ip.php?host=HOSTNAME&ip=GATEWAY_IP'

# View current configuration
internetip showurl

# Remove configuration
sudo internetip unseturl
```

**Tip:** When passing URLs through SSH or remote execution tools, use `%26` instead of `&` to prevent shell interpretation:
```bash
# Local execution (& works fine)
sudo internetip seturl='https://example.com?host=HOSTNAME&ip=GATEWAY_IP'

# Remote execution via SSH/scripts (use %26)
ssh host "internetip seturl='https://example.com?host=HOSTNAME%26ip=GATEWAY_IP'"
```
The server decodes `%26` back to `&` automatically.

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `INTERNETIP_CALL_URL` | Callback URL template | *(none)* |
| `INTERNETIP_PROFILE` | Profile file for URL config | `/etc/profile.d/internetip.sh` |
| `GATEWAY_IP_FILE` | Cached IP file | `/tmp/GatewayIP` |

When run as root, caches result to `GATEWAY_IP_FILE`.

**Output icons:** Messages use status icons for clarity: ◉ info, ▲ warn, ✓ success, ✗ error.

### validip

```bash
validip 192.168.1.1 && echo valid || echo invalid
validip 256.1.1.1 && echo valid || echo invalid
```

### watchip

```bash
watchip                 # Check for IP change
watchip -q              # Quiet mode (for cron)
watchip --log           # Display log file contents
```

**Options:**

| Option | Description |
|--------|-------------|
| `-l, --log` | Display log file contents |
| `-q, --quiet` | Suppress output when IP unchanged |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `LOGFILE` | Log file path | `/var/log/watchip.log` (falls back to `~/.watchip.log`) |
| `IPFILE` | IP tracking file | `/tmp/internetip.txt` |

Logs state changes (initial IP, IP changes) to `LOGFILE`. When run as root, also logs to syslog (`local0.notice`). Typical cron entry:

```cron
*/5 * * * * /usr/local/bin/watchip -q
```

## Module Usage

All scripts can be sourced to use their functions directly:

```bash
# Fetch public IP
source internetip
ip=$(get_internet_ip)
echo "Current IP: $ip"

# Validate IP address
source validip
if valid_ip "$ip"; then
    echo "Valid"
fi

# Monitor for changes
source watchip
result=$(watch_ip /tmp/myapp_ip.txt)
case $result in
    initial:*)   echo "First run: ${result#initial:}" ;;
    changed:*)   echo "IP changed!" ;;
    unchanged:*) echo "IP unchanged" ;;
esac
```

## Architecture

```
watchip ──sources──> internetip ──sources──> validip
   │                     │                      │
   └─ watch_ip()         └─ get_internet_ip()   └─ valid_ip()
```

## Dependencies

| Dependency | Used By | Purpose |
|------------|---------|---------|
| `curl` | internetip | HTTP requests to ipecho.net |
| `logger` | watchip | Syslog integration |
| Bash 4.0+ | All | Shell interpreter |
| `bats-core` | tests | Test framework (optional) |

## Testing

A comprehensive test suite using [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Running Tests

```bash
./run_tests.sh              # Run as user (skips root tests)
./run_tests.sh -a           # Run all including root tests
./run_tests.sh -v           # Verbose TAP output

# Or directly with bats
bats tests/                 # All tests
bats tests/test_validip.bats  # Single test file
sudo bats tests/            # Root-required tests
```

### Test Coverage

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test_validip.bats` | 20 | IP validation, CLI options, sourcing |
| `test_internetip.bats` | 56 | Network fetch, caching, verbose/quiet, install/update/uninstall, URL config |
| `test_watchip.bats` | 30 | Change detection, logging, file ops |

**Total: 106 tests** covering:
- Valid/invalid IP formats
- Executable mode (options, exit codes)
- Sourced mode (function exports, no side effects)
- Root vs non-root behavior
- Install/update/uninstall operations
- URL configuration (seturl, showurl, unseturl)
- Template variable expansion
- Real network calls to ipecho.net

### Test Structure

```
tests/
├── helpers/
│   ├── setup.bash      # Common setup/teardown
│   └── mocks.bash      # Mock logger function
├── test_validip.bats
├── test_internetip.bats
└── test_watchip.bats
```

## Files

| File | Description |
|------|-------------|
| `internetip` | Main IP detection script |
| `validip` | IP validation module |
| `watchip` | IP monitoring daemon |
| `internetip.bash_completion` | Tab completion support |
| `run_tests.sh` | Test runner script |
| `tests/` | bats-core test suite |
| `CLAUDE.md` | Claude Code project guidance |
| `AUDIT-BASH.md` | BCS compliance audit report |

## License

GPL-3.0

#fin
