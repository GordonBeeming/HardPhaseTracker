#!/bin/bash

# Script to embed Git commit hash into Info.plist during build
# Add this as a "Run Script" build phase in Xcode (before "Copy Bundle Resources")

set -e

# Get the short commit hash
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Update Info.plist with the commit hash
if [ -f "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}" ]; then
    /usr/libexec/PlistBuddy -c "Add :GitCommitHash string ${COMMIT_HASH}" "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :GitCommitHash ${COMMIT_HASH}" "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
fi

echo "Embedded Git commit hash: ${COMMIT_HASH}"
