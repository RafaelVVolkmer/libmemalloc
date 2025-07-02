
#!/usr/bin/env bash

set -euo pipefail

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

DOXYFILE="doxygen/Doxyfile"
BUILD_DIR="build/docs/html"

if [ ! -f "${DOXYFILE}" ]; then
  echo "${YELLOW}Generating default Doxyfile…${RESET}"
  doxygen -g "${DOXYFILE}"
else
  echo "${YELLOW}Using existing ${DOXYFILE}${RESET}"
fi

echo "${YELLOW}Running Doxygen…${RESET}"
doxygen "${DOXYFILE}"

echo "${GREEN}Documentation generated successfully!${RESET}"
echo "→ open ${BUILD_DIR}/index.html in your browser"
