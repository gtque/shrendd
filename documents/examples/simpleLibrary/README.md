# simpleLibrary: writing and publishing template a template library
This is intended to be run from `shrendd/documents/examples/simpleLibrary` and 
provide an example for defining a simple, single level (no transitive dependencies) template library
with examples of publishing different ways to a nexus repository.

***shrendd is not responsible for, or a developer of, file repositories. Nexus is only being used as an example here to make some more complex tutorials possible.***

*The path is relative to wherever you have cloned the `shrendd` project to.* 

curl -v -u 'deployment:password' --upload-file fileArchive.tar.gz 'https://nexus.company.com:8443/repository/reponame/config/test/fileArchive.tar.gz