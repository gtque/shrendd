#!/bin/bash
_cdir=$(pwd)
cd ../../init/nexus
docker compose down -v
cd $_cdir
