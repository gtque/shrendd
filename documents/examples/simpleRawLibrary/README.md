# simpleRawLibrary: writing and publishing a template library to nexus raw.
This is intended to be run from `shrendd/documents/examples/simpleRawLibrary` and
provide an example for defining a simple, single level (no transitive dependencies) template library
with example of publishing raw files to a nexus repository.

***shrendd is not responsible for, or a developer of, file repositories. Nexus is only being used as an example here to make some more complex tutorials possible.***

*The path is relative to wherever you have cloned the `shrendd` project to.*

## Prerequisites
1. docker must be installed and running
2. local instance of nexus3 running in docker
    1. cd to `shrendd/build/test/init/nexus`
    2. run `./init.sh`
    3. open a browser and navigate to [http://localhost:8081](http://localhost:8081)
    4. wait for nexus to load, you may have to refresh a few times. it can take a few minutes for it to come up completely.

## Publishing to local nexus
1. cd to `shrendd/documents/examples/simpleRawLibrary`
2. run `./build/build.sh`
3. open a browser
4. navigate to [http://localhost:8081](http://localhost:8081)
5. you can log in using username: admin and password: shrendd123!
6. check in shrendd-zip (or shrendd-public) for the artifact that was just published.

## Teardown
local instance of nexus3 running in docker
1. cd to `shrendd/build/test/teardown/nexus`
2. run `./teardown.sh`
