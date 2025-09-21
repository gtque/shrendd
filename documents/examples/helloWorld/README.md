# helloWorld: A simple example.
This is intended to be run from `shrendd/documents/examples/helloWorld` and 
provide the basic examples of using a `config-template.yml` file for defining the input schema.

*the path is relative to wherever you have cloned the `shrendd` project to.* 

## localdev
1. open a bash command line if not already open
2. navigate to `shrendd/documents/examples/helloWorld`
3. run `./shrendd`
4. observe the log output
5. check the `./deploy/target/render/render/basic.txt` file to see the rendered file.

## relying on default from config-template.yml
1. open a bash command line if not already open
2. navigate to `shrendd/documents/examples/helloWorld`
3. run `./shrendd --config defaultdev.yml`
4. observe the log output
   1. you should see a warning in the output.
5. check the `./deploy/target/render/render/basic.txt` file to see the rendered file.
6. run `./shrendd --config defaultdev.yml -S`
   1. This runs in "strict" mode.
   2. This time it should fail because of the warning.

## missing required from config-template.yml
1. open a bash command line if not already open
2. navigate to `shrendd/documents/examples/helloWorld`
3. run `./shrendd --config missingdev.yml`
4. observe the log output
   1. you should see an error in the output.
   2. rendering should have failed.


## Modules
The above can be repeated for `mymodule` and `mymodule2` by specifying `--module mymodule` and `--module mymodule2`.
You should take a look at their shrendd.yml files to see how they are configured. I will admit these were added as an after thought as a way to test the `shrendditor` plugin for vscode. 

## Shrendditor
That's right, there is a shrendd plugin for vscode that allows you to edit a template and preview the full pre-render or full rendered template in the same editor. It uses shrendd through a terminal configuration in vscode. Shrendd runs slower on a shell terminal running on windows than it does on a native os with a shell terminal. It provides a convenient way to see the full template after resolving the imports.

1. install the `shrendditor` vsix plugin, downloaded from [releases.](https://github.com/gtque/shrendd/releases) >= v0.17.0-beta.
2. see the [vscode shrendditor readme](https://github.com/gtque/shrendd/tree/main/plugins/vscode/README.md) for setting up shrendditor.
3. after installing, restart or reload vscode
4. open `deploy/render/templates/basic.txt.srd`
5. click on the preview tab
6. wait for it to finish loading and rendering

It may take a bit, but you should eventually see either the built or rendered file or error output from shrendd.
The plugin defaults to `pre-render`, aka built but not rendered templates. After the initial module loading, there should
be a list of available "configs" to choose from. Selecting something other than `pre-render` will do a full render using the selected config. Changing this selection and clicking preview again will trigger the templates to be re-rendered.

You can also force the re-building/rendering the templates by checking the `Force Refresh` box.

Feel free to play around with the config choice and the templates in mymodule and mymodule2.