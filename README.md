# internetip

A Bash utility toolkit for detecting, validating, and monitoring public IP addresses.

## Scripts

| Script | Version | Purpose | Exported Function |
|--------|---------|---------|-------------------|
| `internetip` | 2.1.0 | Fetch and display public IP | `get_internet_ip` |
| `validip` | 1.1.0 | Validate IPv4 address format | `valid_ip` |
| `watchip` | 2.0.0 | Monitor for IP changes | `watch_ip` |

All scripts follow the [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard) and support dual-purpose usage (executable or sourceable as a module).

## Installation

```bash
# Clone and install (one-liner)
git clone https://github.com/OkusiAssociates/internetip.git
sudo ./internetip/internetip --install

# Or from within the repo
sudo ./internetip --install

# Update existing installation
sudo internetip --update

# Uninstall
sudo internetip --uninstall
```

Installs symlinks to `/usr/local/bin` and bash completion to `/etc/bash_completion.d`.

## Usage

### internetip

```bash
internetip              # Display current public IP
internetip -s           # Fetch IP and call callback URL
internetip -h           # Show help

# Administration (requires root)
sudo internetip --install    # Install to /usr/local/bin
sudo internetip --update     # Git pull + reinstall
sudo internetip --uninstall  # Remove from /usr/local/bin
```

Environment variables:
```bash
# Override callback URL for -s option
INTERNETIP_CALL_URL=http://example.com/ip internetip -s
```

When run as root, caches result to `/tmp/GatewayIP`.

### validip

```bash
validip 192.168.1.1 && echo valid || echo invalid
validip 256.1.1.1 && echo valid || echo invalid
```

### watchip

```bash
sudo watchip            # Check for IP change
sudo watchip -q         # Quiet mode (for cron)
```

Logs IP changes to syslog (`local0.notice`). Typical cron entry:

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
| `test_internetip.bats` | 30 | Network fetch, caching, install/update/uninstall |
| `test_watchip.bats` | 21 | Change detection, file ops, root check |

**Total: 71 tests** covering:
- Valid/invalid IP formats
- Executable mode (options, exit codes)
- Sourced mode (function exports, no side effects)
- Root vs non-root behavior
- Install/update/uninstall operations
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

MIT

#fin
