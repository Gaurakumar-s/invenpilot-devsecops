#!/usr/bin/env bash
# Seed demo inventory data.   Usage: ./scripts/seed.sh [http://localhost:8000]
set -euo pipefail
BASE="${1:-http://localhost:8000}"
HDR=(); [ -n "${HOST_HEADER:-}" ] && HDR=(-H "Host: ${HOST_HEADER}")   # e.g. HOST_HEADER=stockpilot.local on minikube
post() { curl -sS -o /dev/null "${HDR[@]}" -w "  %{http_code}  $2\n" -X POST "$BASE/api/products" -H 'Content-Type: application/json' -d "$1"; }
echo "Seeding products at $BASE ..."
post '{"sku":"LAP-001","name":"Dell Latitude 5540","category":"Laptops","description":"14-inch business laptop","quantity":18,"reorder_level":5,"unit_price":68999}' "Dell Latitude 5540"
post '{"sku":"LAP-002","name":"MacBook Air M3","category":"Laptops","description":"13-inch, 16 GB RAM","quantity":4,"reorder_level":5,"unit_price":114900}' "MacBook Air M3"
post '{"sku":"MON-001","name":"LG 27UL500 4K Monitor","category":"Displays","description":"27-inch IPS 4K","quantity":12,"reorder_level":4,"unit_price":24999}' "LG 27UL500"
post '{"sku":"KB-001","name":"Logitech MX Keys","category":"Accessories","description":"Wireless keyboard","quantity":0,"reorder_level":10,"unit_price":8995}' "Logitech MX Keys"
post '{"sku":"MS-001","name":"Logitech MX Master 3S","category":"Accessories","description":"Wireless mouse","quantity":25,"reorder_level":10,"unit_price":9495}' "Logitech MX Master 3S"
post '{"sku":"DOCK-001","name":"Dell WD19S Dock","category":"Accessories","description":"USB-C docking station","quantity":7,"reorder_level":3,"unit_price":18500}' "Dell WD19S Dock"
post '{"sku":"HS-001","name":"Jabra Evolve2 65","category":"Audio","description":"Wireless headset","quantity":9,"reorder_level":10,"unit_price":21999}' "Jabra Evolve2 65"
post '{"sku":"CAB-001","name":"USB-C to HDMI cable 2m","category":"Cables","description":"","quantity":60,"reorder_level":20,"unit_price":799}' "USB-C to HDMI cable"
echo "Recording a few stock movements ..."
curl -sS -o /dev/null "${HDR[@]}" -X POST "$BASE/api/products/1/movements" -H 'Content-Type: application/json' -d '{"movement_type":"OUT","quantity":3,"note":"Issued to new joiners"}'
curl -sS -o /dev/null "${HDR[@]}" -X POST "$BASE/api/products/2/movements" -H 'Content-Type: application/json' -d '{"movement_type":"IN","quantity":6,"note":"Supplier delivery PO-1182"}'
curl -sS -o /dev/null "${HDR[@]}" -X POST "$BASE/api/products/5/movements" -H 'Content-Type: application/json' -d '{"movement_type":"OUT","quantity":5,"note":"Customer order #1024"}'
echo "Done."; curl -sS "${HDR[@]}" "$BASE/api/products/stats"; echo
