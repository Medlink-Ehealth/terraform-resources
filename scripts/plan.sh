#!/bin/bash

set -euo pipefail

ENV=${1:-dev}
ENV_DIR="environments/$ENV"

if [ ! -d "$ENV_DIR" ]; then
  echo "❌ Environment '$ENV' not found. Expected directory: $ENV_DIR"
  exit 1
fi

echo ""
echo "======================================================"
echo "  Terraform Plan — Environment: $ENV"
echo "======================================================"
echo ""

cd "$ENV_DIR"

echo "▶  Formatting check..."
terraform fmt -check -recursive
echo "   ✅ Format OK"
echo ""

echo "▶  Validating configuration..."
terraform validate
echo "   ✅ Validation OK"
echo ""

echo "▶  Running plan (output saved to plan.tfplan)..."
terraform plan -out=plan.tfplan
echo ""
echo "   ✅ Plan complete. Review the output above."
echo "   To apply, run: ./scripts/apply.sh $ENV"
echo ""