#!/bin/bash
# Pre-flight Check Validation Script - Phase 4.3
# Tests the enhanced preflight checks for AI Processing Tier

echo "============================================================="
echo " PRE-FLIGHT CHECK VALIDATION - PHASE 4.3"
echo "============================================================="

# Change to ansible directory
cd /opt/CX-Dev-Test-Infrastructure/ansible

echo "🔍 Running enhanced preflight checks on AI servers..."
echo ""

# Run the preflight checks
ansible-playbook -i inventory/hosts.yml ../configs/ansible/preflight-checks.yml

echo ""
echo "============================================================="
echo " VALIDATION COMPLETE"
echo "============================================================="
echo ""
echo "📋 Check the output above for:"
echo "  ✅ NVIDIA Driver detection"
echo "  ✅ CUDA environment validation"
echo "  ✅ Miniconda installation verification"
echo "  ✅ Ollama binary and API accessibility"
echo "  ✅ System resource availability"
echo "  ✅ JSON report generation"
echo ""
echo "📄 JSON reports saved to: /tmp/preflight_[hostname]_[timestamp].json"
echo ""
