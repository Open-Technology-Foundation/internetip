#!/usr/bin/env bash
# Test runner for internetip test suite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# Colors for output
if [[ -t 1 ]]; then
  GREEN=$'\033[0;32m'
  RED=$'\033[0;31m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  NC=$'\033[0m'
else
  GREEN='' RED='' YELLOW='' BLUE='' NC=''
fi

usage() {
  cat <<EOF
Usage: ${0##*/} [options] [test_file...]

Run the internetip test suite using bats-core.

Options:
  -h, --help     Show this help
  -v, --verbose  Verbose TAP output
  -r, --root     Run tests requiring root (uses sudo)
  -a, --all      Run all tests including root tests

Examples:
  ${0##*/}                    # Run non-root tests
  ${0##*/} -a                 # Run all tests (prompts for sudo)
  ${0##*/} tests/test_validip.bats  # Run specific test file
  ${0##*/} -v                 # Verbose output
EOF
}

main() {
  local run_root=0 run_all=0
  local -a test_files=()
  local -a bats_opts=()

  while (($#)); do
    case $1 in
      -h|--help)    usage; return 0 ;;
      -v|--verbose) bats_opts+=(--tap) ;;
      -r|--root)    run_root=1 ;;
      -a|--all)     run_all=1 ;;
      *.bats)       test_files+=("$1") ;;
      *)            echo "${RED}Unknown option: $1${NC}"; usage; return 1 ;;
    esac
    shift
  done

  # Check bats is installed
  if ! command -v bats &>/dev/null; then
    echo "${RED}Error: bats-core not installed${NC}"
    echo "Install with: sudo apt install bats"
    return 1
  fi

  echo "${BLUE}internetip Test Suite${NC}"
  echo "====================="
  echo

  # If no specific files given, run all
  if ((${#test_files[@]} == 0)); then
    test_files=("$TESTS_DIR"/*.bats)
  fi

  # Run non-root tests first
  echo "${YELLOW}Running tests as $(whoami)...${NC}"
  bats "${bats_opts[@]}" "${test_files[@]}" || {
    echo "${RED}Some tests failed${NC}"
  }

  # Run root tests if requested
  if ((run_root || run_all)); then
    echo
    echo "${YELLOW}Running root-required tests with sudo...${NC}"
    sudo bats "${bats_opts[@]}" "${test_files[@]}" || {
      echo "${RED}Some root tests failed${NC}"
    }
  fi

  echo
  echo "${GREEN}Test run complete${NC}"
}

main "$@"
#fin
