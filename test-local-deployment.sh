#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Petclinic Deployment Smoke Tests ==="

# Validate Docker Compose
docker compose -f compose-local.yml config --quiet
echo "PASS: Docker Compose configuration"

# Verify running services
running=$(docker compose -f compose-local.yml ps \
  --status running --services | wc -l | tr -d ' ')

if [ "$running" -ne 12 ]; then
  echo "FAIL: Only $running of 12 services running"
  exit 1
fi
echo "PASS: All 12 services running"

# Verify application endpoints
check_url() {
  curl -fsSL --max-time 20 -o /dev/null "$2"
  echo "PASS: $1"
}

check_url "Petclinic Homepage" http://localhost:8080/
check_url "Discovery Server" http://localhost:8761/
check_url "Config Server" http://localhost:8888/actuator/health
check_url "Customers API" http://localhost:8080/api/customer/owners
check_url "Vets API" http://localhost:8080/api/vet/vets
check_url "Grafana" http://localhost:3000/login
check_url "Prometheus" http://localhost:9091/-/ready

# Verify database access
docker exec mysql-server sh -c \
  'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -D petclinic -N -e "SELECT COUNT(*) FROM owners;"' > /dev/null

echo "PASS: MySQL database"
echo "SUCCESS: All local deployment checks passed!"
