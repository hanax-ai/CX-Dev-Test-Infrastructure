#!/bin/bash
# Test script to verify vault integration
# This demonstrates how to extract secrets from vault for use in scripts

cd /opt/CX-Dev-Test-Infrastructure/configs/ansible

echo "Testing Ansible Vault Integration..."
echo "===================================="

# Test 1: Verify vault file can be decrypted
echo "1. Testing vault decryption..."
if ansible-vault view group_vars/all/vault.yml > /dev/null 2>&1; then
    echo "   ✅ Vault decryption successful"
else
    echo "   ❌ Vault decryption failed"
    exit 1
fi

# Test 2: Extract postgres password for environment variable
echo "2. Extracting postgres_password..."
POSTGRES_PASSWORD=$(ansible localhost -m debug -a "var=postgres_password" -e @group_vars/all/vault.yml 2>/dev/null | grep -o '"CitadelLLM#2025\$SecurePass!"' | tr -d '"')

if [ ! -z "$POSTGRES_PASSWORD" ]; then
    echo "   ✅ Password extraction successful"
    export POSTGRES_PASSWORD
    echo "   🔒 POSTGRES_PASSWORD environment variable set"
else
    echo "   ❌ Password extraction failed"
    exit 1
fi

echo ""
echo "✅ Vault integration test completed successfully!"
echo "💡 Use: export POSTGRES_PASSWORD=\$(ansible localhost -m debug -a \"var=postgres_password\" -e @group_vars/all/vault.yml 2>/dev/null | grep -o '\"[^\"]*\"' | head -1 | tr -d '\"')"
