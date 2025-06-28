# shrendd
template rendering and deployment using shell scripting.
A basic alternative to other template rendering tooling that uses everything you (likely) already have installed in your shell terminal.
This uses bash shell.
All shell based, which means anything you can script in bash shell, you can use for templating.

If you are curious about planned work, please take a look at our [roadmap.](https://github.com/users/gtque/projects/1/views/3)

## Getting Started
* download the appropriate version of `shrendd` from releases. it is recommended just grab the latest version.
* this should go in the root of your project.
* open a command line and navigate to the root of your project
* run: `./shrendd -init`
  * this will run shrendd with default config
  * it will download shrendd source for render only
  * it will stub the `./shrendd.yml`
* you can now open the `./shrendd.yml` file and...
  * set a specific version if your project (or business) requires using a locked/specified version for some reason.
  * add a new target to the list of targets, currently the only other target/module supports is `k8s`
  * change any of the properties as needed for your setup or whims.
    * it is recommended to just use the default values if at all possible.
* you can run `./shrendd ?` to see a list of shrendd arguments/parameters.
* once it has been run once, and if you set a specific shrendd version, you can now run `.shrendd/upshrendd` to update or change the shrendd version
  * to use a specific version of shrendd, you can specify the shrendd.version in the shrendd.yml file.
  * if version is not specified, it assumes "latest"
* define your templates (see also [Hello, World](https://github.com/gtque/shrendd/tree/main/examples/helloWorld))
  * basic templating is handle with shell string substitution and the files are treated as plain text.
    * note: importing templates is not considered basic, and provides some more advanced support for specific protocols like yaml.
  * templated values are wrapped in `${}`.
    * it is encouraged that basic value templating be done using the `getConfig` command.
    * example: `hello, ${getConfig hello.world}!`
    * then in the config input file, you would add
```yaml
hello:
  world: Jimmy
```
  * the default config input file is `./config/localdev.yml`
    * create this file if necessary and add any templated properties with their values
  * template files should end with the `.srd` extension
  * template files should be in the template directory and will be rendered to the render directory
  * default template and render directories:
```yaml
    template:
      dir: $_MODULE_DIR/deploy/${target}/templates
    render:
      dir: $_MODULE_DIR/deploy/${target}/rendered
```
  * the default target is `render` so template files go in: `$_MODULE_DIR/deploy/render/templates` and rendered files go in `$_MODULE_DIR/deploy/render/rendered`
  * `$_MODULE_DIR` is the specified module directory if using `--module modulename` otherwise it is just `./`
    * so if you specify `--module helloWorld` then template files should be in: `./helloWorld/deploy/render/templates` and the rendered files would end up in `$_MODULE_DIR/deploy/render/rendered`
  * run `./shrendd`
    * the `shrendd.default.action` is `-r`, aka `render only`, unless you have overridden this in your shrendd.yml file
  * check the render directory for the rendered template(s)
* Please see the [Examples](https://github.com/gtque/shrendd/tree/main/examples) (coming soon, nothing is there yet) and the [Wiki]() (coming soon)

## Contributing
### The first place to visit is our [discussions](https://github.com/gtque/shrendd/discussions)
### Bug report
* add a [new issue](https://github.com/gtque/shrendd/issues) and select bug report.
* fill out as much information as you can.
* Please do check in discussions before filing a bug report to see if the problem has already been addressed, especially if it is just a question of usage.
* Please be mindful, respectful, and patient.
### New Feature request
* add a [new issue](https://github.com/gtque/shrendd/issues) and select Feature request.
* fill out as much information as you can.
### Code Changes
* ...