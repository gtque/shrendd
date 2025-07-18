# extractTemplate: 
This is intended to be run from `shrendd/documents/tutorials/extractTemplate`. This dives deeper into the config-template file, ie the input schema,
as well as "building" the templates without rendering to see what the full template with imports processed looks like.

*the path is relative to wherever you have cloned the `shrendd` project to.* 

## Prerequisites
1. docker must be installed and running
2. local instance of nexus3 running in docker
   1. cd to `shrendd/build/test/init/nexus`
   2. run `./init.sh`
   3. open a browser and navigate to [http://localhost:8081](http://localhost:8081)
   4. wait for nexus to load, you may have to refresh a few times. it can take a few minutes for it to come up completely.
3. libraries published to the nexus repo
   1. You must do the [simpleRawLibrary](https://github.com/gtque/shrendd/tree/main/documents/examples/simpleRawLibrary) and [simpleMavenLibrary](https://github.com/gtque/shrendd/tree/main/documents/examples/simpleMavenLibrary) examples.
4. public internet access to [https://github.com/gtque/shrendd-lib-test](https://github.com/gtque/shrendd-lib-test)

## -extract
Shrendd provides support for defining an input schema to validate the input variables file. The file is optional, but strongly encouraged.

The input schema itself is defined in yaml, and by default is a file called `config/config-template.yml`. You may change this by setting `shrendd.config.definition` in the `shrendd.yml` file, but like everything else, it is recommended to use the default values.
The `-extract` parameter tells shrendd to upsert the config-template.yml file. That means it will create or update the file. It walks all the templates and extracts all the referenced input variables. It looks for `${...}` and `$(getConfig...)` references.
Please note, it does not consider `"$"`, you need to use `"${...}"` pattern, but it is recommended to just use `$(getConfig...)` approach as that is more explicit.

Each key will be stubbed, if not already present, with:
```yaml
keyname: |-
   required: true
   description: "something to summarize or express what this value is and used for"
   sensitive: false #whether the field should be considered sensitive or not, any matching values will be masked in the output.
   indirect: false #whether this field is indirectly referenced or not. If true, will not be deleted on reduce. Not required, if not present assumes false.
   #default: "the default value to use, uncomment and set a value if required is false, delete or leave commented out if required is true"
```
You can manually edit the config-template.yml file to add additional keys.
You should also edit it to define the key properly.
* required indicates whether the key must be specified in the input variable file or not
* description is just that, a comment about the key and what it is used for. it will be included in error logging if present.
* sensitive marks the key as a sensitive value and will be masked, hopefully so please let us know if you find a case where it is not, in the log output.
* indirect marks the key as not being directly referenced using `${...}` or `$(getConfig...)`, but still used. This is optional, but should absolutely be set if the key is required as it will prevent the key from being reduced the next time `-extract` is run.
* default is commented out by default and can be uncommented and set. It defines a default value to use if the key is not required, ie `required: false`

Extract does work with imports as well. It will walk the template and process any imports and extract all variable references from imported templates to be included in the input schema.

Extract does a reduce. If a key is not marked as `indirect: true` and is no longer found in the templates, or imports, it will be removed from `config-template.yml`

### let's try it out...
1. open a terminal and navigate to `shrendd/documents/tutorials/extractTemplate`
2. run `./shrendd -extract`
3. open `config/config-template.yml` in a text editor.

Congratulations, you know have a `config/config-template.yml` file.

### using the input schema
Now to actually use the input schema.

1. run `./shrendd`
   1. assuming you didn't jump the gun and edit `config/config-template.yml` or `config/localdev.yml` the rendering should fail and you should see a list of missing input variables
2. let's resolve those errors
   1. open `config/config-template.yml` in a text editor
   2. set some of the keys to not be required: `required: false`
   3. for the ones you set to not be required, uncomment `default` and set some value for them.
   4. open `config/localdev.yml` in a text editor
   5. for all the schema entries that are still required, add a corresponding entry with some value in the `config/localdev.yml` file
   6. save both files
3. run `./shrendd`
   1. this time it should pass
   2. if there are still errors because of missing values, update `config/config-template.yml` and set them to not be required, or add them to `config/localdev.yml`



## Halfway there...
Importing templates is great and all, but there isn't any ide support. Single imports are easy enough to grok, but multiple imports or multiple files with imports or both,
can be difficult to keep track of and form a mental picture of the full template. Shrendd provides the **"build"** action that will build the full template without rendering so that you can review the full template file.
To run shrendd with the build action you can specify the `-b` or `--build` parameters. The built files will be put in the `target` directory just like the rendered files.

1. Run `./shrendd -b` or `./shrendd --build`
2. Check the `deploy/target/render` directory
