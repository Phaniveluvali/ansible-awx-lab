#!/bin/bash

# WebSphere Deployment Test Script
# This script tests the playbook structure and configuration

set -e

PLAYBOOK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$PLAYBOOK_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create logs directory
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "WebSphere Playbook Test Suite"
echo "=========================================="
echo "Test Time: $(date)"
echo "Playbook Directory: $PLAYBOOK_DIR"
echo "Log Directory: $LOG_DIR"
echo ""

# Test 1: Syntax Validation
echo "[TEST 1] Validating playbook syntax..."
ansible-playbook "$PLAYBOOK_DIR/deploy-was.yml" --syntax-check
if [ $? -eq 0 ]; then
    echo "✓ Syntax validation PASSED"
else
    echo "✗ Syntax validation FAILED"
    exit 1
fi
echo ""

# Test 2: Inventory Check
echo "[TEST 2] Checking inventory..."
if [ -f "$PLAYBOOK_DIR/inventory/windows_was.ini" ]; then
    echo "✓ Inventory file found"
    echo "  Contents:"
    grep -E "^\[|^[^#;\[]" "$PLAYBOOK_DIR/inventory/windows_was.ini" | head -10
else
    echo "✗ Inventory file not found"
    exit 1
fi
echo ""

# Test 3: Check required files
echo "[TEST 3] Checking required files..."
REQUIRED_FILES=(
    "deploy-was.yml"
    "ansible.cfg"
    "inventory/windows_was.ini"
    "group_vars/windows_was.yml"
    "profiles/dev-profile.yml"
    "profiles/prod-profile.yml"
    "roles/prerequisites/tasks/main.yml"
    "roles/download/tasks/main.yml"
    "roles/install/tasks/main.yml"
    "roles/configure/tasks/main.yml"
    "roles/start/tasks/main.yml"
    "roles/validate/tasks/main.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PLAYBOOK_DIR/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file MISSING"
        exit 1
    fi
done
echo ""

# Test 4: Variable validation
echo "[TEST 4] Validating variables in dev-profile..."
if grep -q "was_version:" "$PLAYBOOK_DIR/profiles/dev-profile.yml" && \
   grep -q "was_install_path:" "$PLAYBOOK_DIR/profiles/dev-profile.yml"; then
    echo "✓ Required variables found in dev-profile"
else
    echo "✗ Required variables missing"
    exit 1
fi
echo ""

# Test 5: Role structure
echo "[TEST 5] Checking role structure..."
ROLES=("prerequisites" "download" "install" "configure" "start" "validate")
for role in "${ROLES[@]}"; do
    if [ -d "$PLAYBOOK_DIR/roles/$role/tasks" ]; then
        echo "  ✓ Role: $role/tasks"
    else
        echo "  ✗ Role: $role/tasks MISSING"
        exit 1
    fi
done
echo ""

# Test 6: Tag extraction
echo "[TEST 6] Extracting playbook tags..."
TAGS=$(grep -oP "tags:\s*$" "$PLAYBOOK_DIR/deploy-was.yml" -A 5 | grep "^        -" | sed 's/^.*- //' | sort | uniq)
echo "  Available tags:"
echo "$TAGS" | while read tag; do
    [ ! -z "$tag" ] && echo "    - $tag"
done
echo ""

# Test 7: Dry run (if inventory has hosts defined)
echo "[TEST 7] Checking if dry-run is possible..."
if grep -q "ansible_host=" "$PLAYBOOK_DIR/inventory/windows_was.ini"; then
    echo "✓ Inventory has hosts defined (dry-run possible)"
    echo "  To perform a dry-run, execute:"
    echo "  ansible-playbook $PLAYBOOK_DIR/deploy-was.yml --check -v"
else
    echo "ⓘ No hosts in inventory yet. Update inventory/windows_was.ini with your hosts."
fi
echo ""

# Summary
echo "=========================================="
echo "Test Suite Summary"
echo "=========================================="
echo "✓ All structural tests PASSED"
echo "✓ Playbook is ready for use"
echo ""
echo "Next Steps:"
echo "1. Update inventory with Windows hosts"
echo "2. Configure credentials (password or SSH key)"
echo "3. Test with: ansible-playbook deploy-was.yml --check"
echo "4. Run deployment: ansible-playbook deploy-was.yml --tags prerequisites"
echo ""
echo "Documentation: See README.md for detailed usage instructions"
echo "=========================================="
