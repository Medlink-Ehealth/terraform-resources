#!/bin/bash

set -euo pipefail

ENV=${1:-dev}
ENV_DIR="environments/$ENV"

if [ ! -d "$ENV_DIR" ]; then
  echo "❌ Environment '$ENV' not found."
  exit 1
fi

PLAN_FILE="$ENV_DIR/plan.tfplan"
if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ No plan file found at $PLAN_FILE"
  echo "   Run ./scripts/plan.sh $ENV first."
  exit 1
fi

echo ""
echo "======================================================"
echo "  Terraform Apply — Environment: $ENV"
echo "======================================================"
echo ""
echo "  ⚠️  This will make REAL changes to Azure."
echo "  You are deploying to: $ENV"
echo ""
read -p "  Are you sure? Type 'yes' to continue: " CONFIRM
echo ""

if [ "$CONFIRM" != "yes" ]; then
  echo "  Aborted."
  exit 0
fi

cd "$ENV_DIR"

terraform apply plan.tfplan

echo ""
echo "======================================================"
echo "  ✅ Apply complete for environment: $ENV"
echo "======================================================"
echo ""