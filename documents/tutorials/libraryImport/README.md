# libraryImport: how to define a library and import templates
This is intended to be run from `shrendd/documents/tutorial/libraryImport` and
provide a tutorial on basic import functionality and some slightly more advanced import scenarios.

***shrendd is not responsible for, or a developer of, file repositories. Nexus is only being used as an example here to make some more complex tutorials possible.***

*The path is relative to wherever you have cloned the `shrendd` project to.*

## Prerequisites
1. docker must be installed and running
2. local instance of nexus3 running in docker
    1. cd to `shrendd/build/test/init/nexus`
    2. run `./init.sh`
    3. open a browser and navigate to [http://localhost:8081](http://localhost:8081)
    4. wait for nexus to load, you may have to refresh a few times. it can take a few minutes for it to come up completely.
3. libraries published to the nexus repo
   1. You really should do the [simpleRawLibrary](https://github.com/gtque/shrendd/tree/main/documents/examples/simpleRawLibrary) and [simpleMavenLibrary](https://github.com/gtque/shrendd/tree/main/documents/examples/simpleMavenLibrary) examples.
4. public internet access to [https://github.com/gtque/shrendd-lib-test](https://github.com/gtque/shrendd-lib-test)

## A simple import
Shrendd allows for the "importing" of templates into other templates. It currently supports direct inline "text" imports
or in place "yaml" imports. Auto-detection is stubbed but not yet implemented, even though it is set as the default type.

Importing is made up of two parts:
* The library to be imported
* The file to be imported

The library to be imported is defined in the "shrendd.yml" file under `shrendd.library`. The "key" will be the name by which you reference the library in the import statement.
It is strongly encouraged to use the artifact id/name, but technically you can name it whatever you want.
below that you specify the "version" key set to the version of the library to import. 
You then also specify the "get" configuration, which defines how to retrieve the library. Under "get", the only required field is "src" which defines the location of the library, aka the url.
You may additionally specify "method" and "parameters" if needed. "method" will default to either "curl" or "wget" if not specified.
And finally, under the library, at the same level as "version" and "get", you may specify the default "type" to use when importing the files in the library. Which default to "shrendd.library.default.type" if not specified, which is "auto" by default.
sample of shrendd.yml (with just a library specified)
```yaml
shrendd:
  library:
    shrendd-lib-test:
      get:
        src: "https://github.com/gtque/shrendd-lib-test/releases/download/v$(shrenddOrDefault \"shrendd.library.shrendd-lib-test.version\")/shrendd-lib-test.zip"
      version: 2.0.0
      type: yaml
```

Once the library has been defined in the shrendd.yml file, you may now "import" the file(s) into your templates. This is done using the `importShrendd` function.
This function takes in one parameter, which is a colon, `:`, separated string defining the file to import. This string use the pattern: "libraryName:path/to/template/inside/library.txt.srd:type:map".

* The libraryName should match the key used when defining the library in the `shrendd.yml` file.
* The `path/to/template/inside/library.txt.srd` should be just that, the path, relative the library, to the template to be imported
* The type is optional, and will default to the library type, or the default type if library type is not set.
* The map is an extra parameter that can be passed to non-standard "types" for additional configuration. Currently, text and yaml do not make use of this even if specified, only `K8sScript` does and that is not covered by this tutorial.
* If you wish to skip an optional parameter, but set a later one, you must still specify the colon. example: `$(importShrendd "libraryName:path/to/template/inside/library.txt.srd::map")`

Shrendd doesn't understand the concept of "snapshot", no does it know if downloading a library failed or not. That means if it tried and failed, the `~/.shrendd/cache` will have a stubbed folder, and either partial or no content in it for the library.
When it is in this state, it will think the library has been downloaded and will not retry. You can either delete the cache manually, or use the `-U` flag when running shrendd to force an update.
The `-U` flag will force an update of all libraries (and plugins). Keep the `-U` parameter in mind as you work through the tutorial in case you run into issues downloading the libraries.

*Before starting, if you want to follow this entire tutorial, make sure you have fulfilled the prerequisites.*

## My first import
A simple import from a public library. For this step we will be using the [shrendd-lib-test](https://github.com/gtque/shrendd-lib-test) library.

This part can be completed without the local nexus repo.

library information:
* url: `https://github.com/gtque/shrendd-lib-test/releases/download/v$(shrenddOrDefault \"shrendd.library.shrendd-lib-test.version\")/shrendd-lib-test.zip`
  * notice the `$(shrenddOrDefult ...)` in the middle of the url, this is how you can reference shrendd properties from other properties.
* method: default (curl/wget)
* version: 2.0.0
* type: text

### the first import
1. Open up the shrendd.yml file
2. find the "library" section.
3. Add a new key `shrendd-lib-test`
4. under `shrendd-lib-test` add `get`
5. under `get` add the `src` and set the value to the url.
6. under `shrendd-lib-test` add `version` and set the value to the version to be used.
7. under `shrendd-lib-test` add `type` and set the value to `"text"`
8. save the changes
9. create the "deploy/render/template" folder structure if it does not already exist.
10. add a new txt template file, `myfirstimport.txt.srd`
11. Open up `myfirstimport.txt.srd`
12. on the first line add the text: `biscuits:`
13. import the `bob/text/biscuits.txt` file on the second line.
    1. remember to use the `$(...)` syntax
    2. the function for importing is `importShrendd`
    3. the pattern for the file to import is: `libraryName:path/to/template/inside/library.txt.srd:type:map`
14. save the file
15. run `./shrendd`
    1. there should be no errors during rendering.
16. back in `myfirstimport.txt.srd` add a third line and add the text: `cake:`
17. import `bob/text/cake.txt.srd` on the forth line.
18. run `./shrendd`

You will notice that this time there was a rendering error. Let's get that resolved.
To resolve this, we can either define the input yml file, the default is `config/localdev.yml`, or generate an input schema.

### Let's generate the input schema and go from there.
1. run `./shrendd -extract`
2. open up the `config/config-template.yml` file
3. From here, you can configure the schema to fit your needs.

You will notice two input parameters, but only one of those caused a rendering issue. That is because `milk2` was referenced using `getConfigOrEmpty` which will simply return an empty string if the input parameter is not found.
This should be used with caution as it can be difficult to diagnose or find issues when the referenced parameter is not provided.

Each extracted parameter is stubbed with required, description, sensitive, indirect, and a commented out default, each with a description describing their purpose.

If you were to run shrendd again, this time you will see two render errors because both fields are marked as required. This supersedes the `getConfigOrEmpty`.

### Time to update the schema and try again.
1. set milk2 to not be required
2. uncomment the default value for milk2 and set to something, or leave the stubbed string if you want, I can't stop you or make you.
3. open, or create and then open, `config/localdev.yml`
4. add an entry for `lib.butter.alternative2`
5. set the value to whatever you want.
6. run `./shrendd`

Congratulations, you have now shrenddered a template built by importing templates from a library, generating an input schema file, and filling out a minimum viable input file.
Next we will import a local template, that has nested imports inside of it. Yes, that is correct, 
shrendd will process nested imports. Transitive imports are not currently supported, so you must define all necessary library imports in your shrendd.yml file.

### Now, let's build a nest.
1. add new file, `deploy/render/templates/mysecondimport.txt.srd`
2. open this new file
3. add `from the first:` to the first line
4. one the second line, import `myfirstimport.txt.srd`
   1. the path is relative to the defined "deploy" directory, which by default is just `deploy`
   2. the library should be self-referencing, ie `libraryImport`
5. run `./shrendd`

If there was an error, check the error output and see if it was an issue with the path to the template being imported
or an issue with the library self-reference.

## But what if the library is in a protected repository?
The short answer is that is what the library's get.parameters are for. And this works well if the parameters for curl/wget
are sufficient for providing the necessary auth or settings for using them to pull the artifact(s) from the repository.
Sometimes though, you need something different, but we will get to that.

*The following parts of the tutorial are written against the local nexus3 stood up, hopefully, as part of the prerequisites.*

### Auth with curl
First we will pull a template library from a protected repository.

* url: `http://localhost:8081/repository/shrendd-public/simpleRawLibrary/v$(shrenddOrDefault shrendd.library.simpleRawLibrary.version)/simpleRawLibrary.zip`
* method: curl
* version: 1.0.0
* type: text
* curl auth: `-u 'splinter:tmnt'`

1. open `shrendd.yml`
2. add a new library entry for `simpleRawLibrary`
3. under `simpleRawLibrary` add `get`
4. under `get` add the `src` and set the value to the url.
5. under `simpleRawLibrary` add `version` and set the value to the version to be used.
6. under `simpleRawLibrary` add `type` and set the value to `"text"`
7. this time, we do want to specify the get.method, so under `get` add the `method` and set the value to the method we want to use, which is curl.
   1. NOTE: shrendd has a wrapper method for curl (and wget) that handles some boilerplate syntax. These functions end with an uppercase D
   2. ie, the method should be set to `curlD`
8. under `get` add the `parameters` and set the value to the auth string.
   1. This is where you need to set any additional parameters that may need to be set in the curl command.
9. save the changes.
10. create a new template file: `deploy/render/templates/myrawimport.txt.srd`
11. on the first line, import `render/templates/simple.txt.srd` from simpleRawLibrary
12. remember: if you render now, it will likely fail, so do an extract first: `./shrendd -extract`
    1. Running extract again will simply update in place the existing config-template.yml, including reducing if necessary. Extract is covered in more detail in a separate tutorial/example.
13. update the config-template.yml file or add the missing values to the localdev.yml file
14. run `./shrendd`

This time, we did an extract before attempting to do a full render. Libraries will be pulled during an extract, just like for a render, if they have not
already been pulled.

## Let's try a more complicated "maven" based import
The method specified in the library definition is in fact the name of a method to be executed.
Shrendd calls this method and passes 3 parameters, in the following order:
1. the destination of the artifact, including the artifact name and not just the directory
2. the library source
3. the defined parameters

With that information in hand, we can define a custom library method to pull the artifact however we need. This function can be pulled in by a plugin, or written directly in `boot.shrendd`.
The `boot.shrendd` file is a script file (so start it with `#!/bin/bash`) that is used to bootstrap custom functions into shrendd that can then be leveraged by library/plugin definitions and even in the templates themselves.
For this tutorial, we will be defining using the `boot.shrendd` approach.

### Come on Bill, bootstrap.
* url: `http://localhost:8081/repository/maven-public`
* method: myMvnClone
* version: 1.0.0
* type: text
* parameters: `"com.shrendd.examples:simpleMavenLibrary:$(shrenddOrDefault shrendd.library.simpleMavenLibrary.version)"`
  * for those that have experience with maven, this syntax should look familiar

1. create `boot.shrendd` in the root directory of this tutorial, `shrendd/documents/tutorials/libraryImport/boot.shrendd`
2. open `boot.shrendd`
3. start the file with `#!/bin/bash`
4. now define a new `function myMvnClone`
    ```shell
    function myMvnClone {
      #shrenddLog is the mechanism for "verbose" logging.
      #most things should not be printing or echoing out trace/debug/info style messages
      #this is because `echo` is used as the return for functions.
      #so if you want to capture some information for debugging purposes, please use `shrenddLog`
      shrenddLog "maven clone!"
      #get artifact id, the 3rd parameter comes from the libraries "settings" specified in the `shrendd.yml`
      #in the libraries `get.parameters` entry
      #in this case, the `package:artifactid:version`
      _artifact="$(echo "${3}" | cut -d':' -f2)"
      shrenddLog "mvn: artifact: ${_artifact}"
      #get just the destination directory is part of the first parameter which is the full path to download the artifact to
      #to get just the directory, the artifact must be stripped from that value.
      _destination="$(echo "${1}" | sed -e "s/\/${_artifact}\.zip//g")"
      shrenddLog "mvn: destination: ${_destination}"
      #the maven command to get/copy the artifact from the remote repository
      #the output is captured for verbose logging and so as to not mess up the return, and any errors are redirected to the error log
      _mvn=$(mvn -s $_STARTING_DIR/mvn/maven-settings.xml dependency:get dependency:copy -DremoteRepositories=${2} -Dartifact=${3}:zip -DrepositoryId=nexus-snapshots -DoutputDirectory=${_destination} -Dmdep.stripClassifier=true -Dmdep.stripVersion=true 2>> $_DEPLOY_ERROR_DIR/config_error.log)
      shrenddLog "mvn: \n${_mvn}"
    }
    ```
5. this is leveraging the predefined `mvn/maven-settings.xml` file to make life a bit easier for this tutorial. as such, go ahead and add the following to `boot.shrendd` after the function:
    ```shell
    #below is for testing purposes and you shouldn't need to do this as you should be using proper maven config file.
    #this is a simple hack to make the tutorial a bit easier to use and require less manual setup on your part.
    export MVN_USERNAME="splinter"
    export MVN_PASSWORD="tmnt"
    ```
6. And while we are at it, let's go ahead and add a custom method for retrieving the curl credentials, so go ahead and also add this to the `boot.shrendd` file:
    ```shell
    function getCustomCredentials {
    #you could pull them from a secret manager
    #you could read them from a file
    #you could do what ever you want from shell
    echo "splinter:tmnt"
    }
    ```
7. With `getCustomCredentials` defined, open `shrendd.yml` and update `simpleRawLibrary.get.parameters` to `"-u '$(getCustomCredentials)'"`
8. Now let's add the library definition, add `simpleMavenLibrary` under `shrendd.library`
9. under `simpleMavenLibrary` add `get`
10. under `get` add the `src` and set the value to the url.
11. under `simpleMavenLibrary` add `version` and set the value to the version to be used.
12. under `simpleMavenLibrary` add `type` and set the value to `"text"`
13. this time, we do want to specify the get.method, so under `get` add the `method` and set the value to the method we want to use, which is the bootstrapped `myMvnClone`.
14. under `get` add the `parameters` and set the value to the maven package identifier.
15. save the changes.
16. edit an existing template file: `deploy/render/templates/myrawimport.txt.srd`
17. on a new line, import `render/templates/simple.txt.srd` from simpleMavenLibrary
    1. be mindful of the fact that the file path is the same from simpleRawLibrary, but the library is not.
18. go ahead and run `./shrendd` now. if you are importing the correct file from simpleMavenLibrary, assuming you have not updated the input schema or input file, it should fail.
18. remember: if you render now, it will likely fail, so do an extract first: `./shrendd -extract`
    1. Running extract again will simply update in place the existing config-template.yml, including reducing if necessary. Extract is covered in more detail in a separate tutorial/example.
19. update the config-template.yml file or add the missing values to the localdev.yml file
20. run `./shrendd`

## Text is cool and all, but you got any of that yaml?
Yaml has certain advantages (and some disadvantages, but we aren't going to talk about those) over plain text. One of those is that it is structured and the keys are unique.
Yaml is also used by many different deployment and infrastructure tools, like kubernetes. While this tutorial is not going to actually deploy the rendered templates, it will
use the configmap object as the example.

You don't actually have to use the `k8s` target to work with yaml, only to deploy. If you check the shrendd.yml file, you will see only `render` specified.

The previous steps you have added all the necessary library definitions needed. Keep in mind that they all set their type to `text` but the following steps will be importing yaml.

### YATT (yet another templating tool)? No it's YAML.
1. Create a new file: `./deploy/render/templates/iheartyaml.yml.srd`
2. Open up the file in a text editor
3. on the first line import `k8s/tempaltes/simple_configmap.yml.srd` from the `simpleRawLibrary` as `yaml`
   1. remember, the pattern for declaring the import is: `libraryName:path/to/template/inside/library.txt.srd:type:map`
   2. `map` is not needed here
4. let's update the input schema by running `./shrendd -extract`
5. open the `config/config-template.yml` file and edit the new entries or add the new parameters to the `localdev.yml` file.
6. run `./shrendd`
7. open up `deploy/target/render/render/iheartyaml.yml.srd`

## So that's cool and all, but right now that could have been done with the regular text import.
1. in the `iheartyaml.yml.srd` file, after the import line, add
    ```yaml
    metadata:
      name: "$(getConfig my.name)"
      labels:
        app.kubernetes.io/name: "$(getConfig my.name)"
        app.kubernetes.io/component: "$(getConfig my.name)"
        app.kubernetes.io/part-of: "$(getConfig my.name)"
    ```
2. add `my.name` with some value to `config/localdev.yml`
3. run `./shrendd`

If you defined the import propery, the newly rendered file should look almost the same as before, except now, all the things referencing `SIMPLE_RAW_LIBRARY_NAME` are now referencing `my.name`
This is possible because of the structured nature of yaml. There is an order of precedence for keys and imported yaml templates. If you consider the template file defined
in the project as the lowest, or first, file in the import hierarchy, in this case `iheartyaml.yml.srd` and then each import (and their nested imports), are processed in order they are defined in the file.
So the lowest, or first, instance of the key being defined will be what ends up in the built template before rendering.

This also means the import order relative to the yaml defined in the local template does not matter, but the order of the imports relative to each other does.

# Congratulations, you have now defined text and yaml based templates and used importShrendd to import template files from external libraries and from the local source.
You can check your work against the files in the `solution` directory. Don't fret if it is not an exact match. A lot of the structure is up to your decisions, especially the config-template.yml file.
While not an exact match, the solution files should give you a pretty good idea of whether you were correct or not.

## Halfway there...
Importing templates is great and all, but there isn't any ide support. Single imports are easy enough to grok, but multiple imports or multiple files with imports or both, 
can be difficult to keep track of and form a mental picture of the full template. Shrendd provides the **"build"** action that will build the full template without rendering so that you can review the full template file. 
To run shrendd with the build action you can specify the `-b` or `--build` parameters. The built files will be put in the `target` directory just like the rendered files.

1. Run `./shrendd -b` or `./shrendd --build`
2. Check the `deploy/target/render` directory


## Teardown
local instance of nexus3 running in docker
1. cd to `shrendd/build/test/teardown/nexus`
2. run `./teardown.sh`
