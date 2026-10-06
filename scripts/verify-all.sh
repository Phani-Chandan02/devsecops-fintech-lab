#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " DEVSECOPS FINTECH LAB VERIFICATION (ALL PHASES)"
echo "=========================================================="

bash scripts/bootstrap.sh
echo ""
bash scripts/verify-phase1.sh
echo ""
bash scripts/verify-phase2.sh
echo ""
bash scripts/verify-phase3.sh
echo ""
bash scripts/verify-phase4.sh

echo "=========================================================="
echo " [VERIFICATION SUMMARY] ALL TESTED PHASES EVALUATED"
echo "=========================================================="
