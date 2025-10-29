#!/usr/bin/env bash

echo "Probando login..."
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  2>&1 | grep -E "HTTP|403|200|{" | head -20

