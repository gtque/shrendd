# simpleMavenLibrary: writing and publishing a template library with maven
This is intended to be run from `shrendd/documents/examples/simpleMavenLibrary` and 
provide an example for defining a simple, single level (no transitive dependencies) template library
with examples of publishing with maven to a nexus repository.

***shrendd is not responsible for, or a developer of, file repositories. Nexus is only being used as an example here to make some more complex tutorials possible.***

*The path is relative to wherever you have cloned the `shrendd` project to.* 

## Prerequisites 
1. docker must be installed and running
2. if running on linux (or linux in wsl): leave build/Dockerfile-mvn and build/build.sh as is
3. if running on windows/max
   1. update build/build.sh: delete `--network=host` from the docker command
   2. update build/Dockerfile-mvn: replace `localhost` with `host.docker.internal`
   3. update build/maven-settings.xml: replace `localhost` with `host.docker.internal`
   4. this is just the way docker works. I have only tested the process running in wsl, so I am not 100% certain this works as expected on windows/mac
4. local instance of nexus3 running in docker
   1. cd to `shrendd/build/test/init/nexus`
   2. run `./init.sh`
   3. open a browser and navigate to `http://localhost:8081`
   4. wait for nexus to load, you may have to refresh a few times. it can take a few minutes for it to come up completely.

## Publishing to local nexus
1. cd to `shrendd/documents/examples/simpleMavenLibrary`
2. run `./build/build.sh`
3. open a browser
4. navigate to `http://localhost:8081`
5. you can login using username: admin and password: shrendd123!
6. check in maven-releases (or maven-public) for the artifact that was just published.

## Teardown
local instance of nexus3 running in docker
1. cd to `shrendd/build/test/teardown/nexus`
2. run `./teardown.sh`
