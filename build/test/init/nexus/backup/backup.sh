#!/bin/bash
echo "backing up nexus volume..."
cd ..
./init.sh
cd backup
docker run --rm --volumes-from nexus-nexus-1 -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /nexus-data
echo "backed up, stopping the container now."
cd ../../../teardown/nexus
./teardown.sh
