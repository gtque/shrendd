#!/bin/bash
echo "initializing nexus for tests"
echo "admin/shrendd123!"
echo "splinter/tmnt"

_nexus_data=$(docker volume ls | grep "nexus-data" || echo "not found")
if [[ "${_nexus_data}" == "not found" ]]; then
  echo "no volume found, creating it..."
  docker volume create nexus-data
  docker run -v nexus-data:/nexus-data --name nexus-init ubuntu /bin/bash
  docker run --rm --volumes-from nexus-init -v $(pwd)/backup:/backup ubuntu bash -c "cd /nexus-data && tar xvf /backup/backup.tar --strip 1"
  docker stop nexus-init
else
  echo "volume found."
fi

docker compose up --detach

echo "nexus started"
