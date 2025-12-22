#!/usr/bin/env bats
# Tests for internetip script and get_internet_ip() function

load 'helpers/setup'

# =============================================================================
# get_internet_ip() Function Tests
# =============================================================================

@test "get_internet_ip returns valid IP from network" {
  source "$BATS_TEST_DIRNAME/../internetip"
  run get_internet_ip
  [ "$status" -eq 0 ]
  # Verify output matches IPv4 format
  is_valid_ipv4_format "$output"
}

@test "get_internet_ip output has no trailing whitespace" {
  source "$BATS_TEST_DIRNAME/../internetip"
  run get_internet_ip
  [ "$status" -eq 0 ]
  # Check no trailing newlines or spaces
  [[ "$output" == "${output%% }" ]]
  [[ "$output" == "${output%%$'\n'}" ]]
}

@test "internetip alias works same as get_internet_ip" {
  source "$BATS_TEST_DIRNAME/../internetip"
  ip1=$(get_internet_ip)
  ip2=$(internetip)
  [ "$ip1" = "$ip2" ]
}

# =============================================================================
# valid_ip() Availability Tests (sourced from validip)
# =============================================================================

@test "internetip sources valid_ip function" {
  source "$BATS_TEST_DIRNAME/../internetip"
  declare -F valid_ip
}

@test "valid_ip works after sourcing internetip" {
  source "$BATS_TEST_DIRNAME/../internetip"
  run valid_ip "192.168.1.1"
  [ "$status" -eq 0 ]
}

# =============================================================================
# Executable Mode Tests
# =============================================================================

@test "internetip executable shows help with -h" {
  run "$BATS_TEST_DIRNAME/../internetip" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fetch and display public internet IP"* ]]
}

@test "internetip executable shows help with --help" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"INTERNETIP_CALL_URL"* ]]
}

@test "internetip executable shows version with -V" {
  run "$BATS_TEST_DIRNAME/../internetip" -V
  [ "$status" -eq 0 ]
  [[ "$output" == *"internetip"* ]]
  [[ "$output" == *"2."* ]]  # Version starts with 2.
}

@test "internetip executable shows version with --version" {
  run "$BATS_TEST_DIRNAME/../internetip" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"internetip"* ]]
}

@test "internetip executable returns valid IP" {
  run "$BATS_TEST_DIRNAME/../internetip"
  [ "$status" -eq 0 ]
  is_valid_ipv4_format "$output"
}

@test "internetip executable returns 22 for unknown option" {
  run "$BATS_TEST_DIRNAME/../internetip" --invalid-option
  [ "$status" -eq 22 ]
  [[ "$output" == *"Unknown option"* ]]
}

@test "internetip executable returns 22 for unexpected argument" {
  run "$BATS_TEST_DIRNAME/../internetip" somearg
  [ "$status" -eq 22 ]
  [[ "$output" == *"Unexpected argument"* ]]
}

# =============================================================================
# Verbose/Quiet Mode Tests
# =============================================================================

@test "internetip -q returns valid IP" {
  run "$BATS_TEST_DIRNAME/../internetip" -q
  [ "$status" -eq 0 ]
  is_valid_ipv4_format "$output"
}

@test "internetip --quiet returns valid IP" {
  run "$BATS_TEST_DIRNAME/../internetip" --quiet
  [ "$status" -eq 0 ]
  is_valid_ipv4_format "$output"
}

@test "internetip -v returns valid IP" {
  run "$BATS_TEST_DIRNAME/../internetip" -v
  [ "$status" -eq 0 ]
  # Output contains IP (may have additional verbose output)
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "internetip --verbose returns valid IP" {
  run "$BATS_TEST_DIRNAME/../internetip" --verbose
  [ "$status" -eq 0 ]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "internetip -c is alias for -s (help shows it)" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"-s, -c, --call-url"* ]]
}

@test "internetip combined short options -qV works" {
  run "$BATS_TEST_DIRNAME/../internetip" -qV
  [ "$status" -eq 0 ]
  [[ "$output" == *"internetip"* ]]
  [[ "$output" == *"2."* ]]
}

@test "help shows -v/--verbose option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--verbose"* ]]
}

@test "help shows -q/--quiet option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--quiet"* ]]
}

# =============================================================================
# Root Behavior Tests
# =============================================================================

@test "internetip caches IP to /tmp/GatewayIP when run as root" {
  skip_if_not_root
  rm -f /tmp/GatewayIP
  run "$BATS_TEST_DIRNAME/../internetip"
  [ "$status" -eq 0 ]
  [ -f /tmp/GatewayIP ]
  cached_ip=$(<"/tmp/GatewayIP")
  [ "$cached_ip" = "$output" ]
}

@test "internetip does not create /tmp/GatewayIP when non-root" {
  skip_if_root
  # Skip if file exists and we can't remove it (owned by root)
  if [[ -f /tmp/GatewayIP ]] && ! rm -f /tmp/GatewayIP 2>/dev/null; then
    skip "Cannot remove /tmp/GatewayIP (owned by root)"
  fi
  run "$BATS_TEST_DIRNAME/../internetip"
  [ "$status" -eq 0 ]
  [ ! -f /tmp/GatewayIP ]
}

# =============================================================================
# Sourced Mode Tests
# =============================================================================

@test "internetip exports get_internet_ip function when sourced" {
  source "$BATS_TEST_DIRNAME/../internetip"
  declare -F get_internet_ip
}

@test "internetip exports internetip function when sourced" {
  source "$BATS_TEST_DIRNAME/../internetip"
  declare -F internetip
}

@test "sourcing internetip does not produce output" {
  run bash -c 'source "$1" && echo "done"' -- "$BATS_TEST_DIRNAME/../internetip"
  [ "$status" -eq 0 ]
  [ "$output" = "done" ]
}

@test "sourcing internetip does not fetch IP (no side effects)" {
  # Sourcing should be fast - no network call
  start=$(date +%s%N)
  source "$BATS_TEST_DIRNAME/../internetip"
  end=$(date +%s%N)
  elapsed=$(( (end - start) / 1000000 ))  # ms
  # Should complete in under 100ms (network call takes seconds)
  [ "$elapsed" -lt 100 ]
}

# =============================================================================
# Environment Variable Tests
# =============================================================================

@test "help shows INTERNETIP_CALL_URL documentation" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"INTERNETIP_CALL_URL"* ]]
  [[ "$output" == *"Callback URL"* ]]
}

# =============================================================================
# Install/Update/Uninstall Tests
# =============================================================================

@test "help shows --install option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--install"* ]]
}

@test "help shows --update option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--update"* ]]
}

@test "help shows --uninstall option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--uninstall"* ]]
}

@test "--install requires root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --install
  [ "$status" -eq 1 ]
  [[ "$output" == *"requires root"* ]]
}

@test "--update requires root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --update
  [ "$status" -eq 1 ]
  [[ "$output" == *"requires root"* ]]
}

@test "--uninstall requires root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --uninstall
  [ "$status" -eq 1 ]
  [[ "$output" == *"requires root"* ]]
}

@test "--install creates symlinks in /usr/local/bin" {
  skip_if_not_root
  # Clean up first
  rm -f /usr/local/bin/{internetip,validip,watchip}

  run "$BATS_TEST_DIRNAME/../internetip" --install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation complete"* ]]

  # Verify symlinks exist
  [ -L /usr/local/bin/internetip ]
  [ -L /usr/local/bin/validip ]
  [ -L /usr/local/bin/watchip ]
}

@test "--install creates bash completion" {
  skip_if_not_root
  run "$BATS_TEST_DIRNAME/../internetip" --install
  [ "$status" -eq 0 ]

  # Verify bash completion installed (if directory exists)
  if [[ -d /etc/bash_completion.d ]]; then
    [ -L /etc/bash_completion.d/internetip ]
  fi
}

@test "--uninstall removes symlinks" {
  skip_if_not_root
  # Ensure installed first
  "$BATS_TEST_DIRNAME/../internetip" --install >/dev/null

  run "$BATS_TEST_DIRNAME/../internetip" --uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"Uninstalled"* ]]

  # Verify symlinks removed
  [ ! -e /usr/local/bin/internetip ]
  [ ! -e /usr/local/bin/validip ]
  [ ! -e /usr/local/bin/watchip ]
}

@test "--install is idempotent (can run twice)" {
  skip_if_not_root
  run "$BATS_TEST_DIRNAME/../internetip" --install
  [ "$status" -eq 0 ]

  # Run again - should succeed
  run "$BATS_TEST_DIRNAME/../internetip" --install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation complete"* ]]
}

@test "--update runs git pull" {
  skip_if_not_root
  # Ensure installed
  "$BATS_TEST_DIRNAME/../internetip" --install >/dev/null

  run "$BATS_TEST_DIRNAME/../internetip" --update
  [ "$status" -eq 0 ]
  [[ "$output" == *"Updated from git"* ]] || [[ "$output" == *"Already up"* ]]
}

#fin
