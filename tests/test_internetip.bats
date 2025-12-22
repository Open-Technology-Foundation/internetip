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

# =============================================================================
# URL Configuration Tests
# =============================================================================

@test "help shows --set-url option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--set-url"* ]]
  [[ "$output" == *"Configure system-wide callback URL"* ]]
}

@test "help shows --show-url option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--show-url"* ]]
}

@test "help shows --unset-url option" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--unset-url"* ]]
}

@test "help shows template variables documentation" {
  run "$BATS_TEST_DIRNAME/../internetip" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'$HOSTNAME'* ]]
  [[ "$output" == *'$GATEWAY_IP'* ]]
}

@test "--set-url requires root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --set-url
  [ "$status" -eq 1 ]
  [[ "$output" == *"Requires root"* ]]
}

@test "--unset-url requires root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --unset-url
  [ "$status" -eq 1 ]
  [[ "$output" == *"Requires root"* ]]
}

@test "--show-url works without root" {
  skip_if_root
  run "$BATS_TEST_DIRNAME/../internetip" --show-url
  [ "$status" -eq 0 ]
  [[ "$output" == *"Template:"* ]]
}

@test "--show-url displays template and expanded form" {
  run "$BATS_TEST_DIRNAME/../internetip" --show-url
  [ "$status" -eq 0 ]
  [[ "$output" == *"Template:"* ]]
  [[ "$output" == *"Expanded:"* ]]
}

@test "--show-url expands HOSTNAME in template" {
  # Set a test URL with $HOSTNAME and verify expansion shows hostname
  export INTERNETIP_CALL_URL='https://example.com?host=$HOSTNAME'
  run "$BATS_TEST_DIRNAME/../internetip" --show-url
  [ "$status" -eq 0 ]
  # Template line should show literal $HOSTNAME
  [[ "$output" == *'Template: https://example.com?host=$HOSTNAME'* ]]
  # Expanded line should NOT contain literal $HOSTNAME
  expanded_line=$(echo "$output" | grep "^Expanded:")
  [[ "$expanded_line" != *'$HOSTNAME'* ]]
}

@test "--show-url expands GATEWAY_IP placeholder" {
  export INTERNETIP_CALL_URL='https://example.com?ip=$GATEWAY_IP'
  run "$BATS_TEST_DIRNAME/../internetip" --show-url
  [ "$status" -eq 0 ]
  # Expanded line should show <IP> placeholder (no actual IP without fetch)
  [[ "$output" == *"<IP>"* ]]
}

@test "--show-url shows both template and expanded forms" {
  export INTERNETIP_CALL_URL='https://example.com?v=$VERSION'
  run "$BATS_TEST_DIRNAME/../internetip" --show-url
  [ "$status" -eq 0 ]
  # Expanded should contain actual version number
  [[ "$output" == *"2."* ]]
}

@test "-s fails gracefully when INTERNETIP_CALL_URL not set" {
  # Use non-existent profile file to test "not configured" scenario
  run env -u INTERNETIP_CALL_URL INTERNETIP_PROFILE=/nonexistent/profile.sh \
      "$BATS_TEST_DIRNAME/../internetip" -s
  [ "$status" -eq 1 ]
  [[ "$output" == *"INTERNETIP_CALL_URL not set"* ]]
  [[ "$output" == *"--set-url"* ]]
}

@test "--set-url creates profile.d file" {
  skip_if_not_root
  # Clean up first
  rm -f /etc/profile.d/internetip.sh

  # Run with input
  echo 'https://example.com/test?host=$HOSTNAME' | \
    "$BATS_TEST_DIRNAME/../internetip" --set-url

  # Verify file created
  [ -f /etc/profile.d/internetip.sh ]
  grep -q 'INTERNETIP_CALL_URL' /etc/profile.d/internetip.sh
}

@test "--set-url creates systemd generator" {
  skip_if_not_root
  # Clean up first
  rm -f /etc/systemd/system-environment-generators/internetip

  # Run with input
  echo 'https://example.com/test?host=$HOSTNAME' | \
    "$BATS_TEST_DIRNAME/../internetip" --set-url

  # Verify file created
  [ -f /etc/systemd/system-environment-generators/internetip ]
  [ -x /etc/systemd/system-environment-generators/internetip ]
}

@test "--unset-url removes configuration files" {
  skip_if_not_root
  # Create files first
  echo 'https://example.com/test' | \
    "$BATS_TEST_DIRNAME/../internetip" --set-url 2>/dev/null || true

  run "$BATS_TEST_DIRNAME/../internetip" --unset-url
  [ "$status" -eq 0 ]
  [[ "$output" == *"URL configuration removed"* ]]

  # Verify files removed
  [ ! -f /etc/profile.d/internetip.sh ]
  [ ! -f /etc/systemd/system-environment-generators/internetip ]
}

@test "--set-url escapes dollar signs in systemd generator" {
  skip_if_not_root
  # Run with input containing $HOSTNAME
  echo 'https://example.com?host=$HOSTNAME' | \
    "$BATS_TEST_DIRNAME/../internetip" --set-url

  # Verify generator has escaped $ (literal \$HOSTNAME)
  grep -q '\$HOSTNAME' /etc/systemd/system-environment-generators/internetip
}

@test "--set-url accepts URL as command-line argument" {
  skip_if_not_root
  # Clean up first
  rm -f /etc/profile.d/internetip.sh

  # Run with URL as argument (not interactive)
  run "$BATS_TEST_DIRNAME/../internetip" --set-url 'https://test.com?h=$HOSTNAME'
  [ "$status" -eq 0 ]
  [[ "$output" == *"URL template configured"* ]]

  # Verify file contains the URL
  grep -q 'https://test.com?h=\$HOSTNAME' /etc/profile.d/internetip.sh
}

@test "--set-url=URL equals syntax works" {
  skip_if_not_root
  # Run with equals syntax
  run "$BATS_TEST_DIRNAME/../internetip" --set-url='https://equals.test/api'
  [ "$status" -eq 0 ]
  [[ "$output" == *"URL template configured"* ]]

  # Verify file contains the URL
  grep -q 'https://equals.test/api' /etc/profile.d/internetip.sh
}

#fin
