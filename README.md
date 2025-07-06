# shrendd
A template rendering and deployment tool using shell (bash) scripting.
A basic alternative to other template rendering tooling. It uses things you (likely) already have installed in your shell terminal.
This uses bash shell and is all shell based, which means anything you can script in bash shell, you can, in theory, use for templating and deploying.

* Why?
  * because other templating tools usually require very specific libraries and run times, as well as their own proprietary syntax and language
  * shrendd lets you use bash scripting with only some specific syntax required.
* Why `yq`, doesn't that kind of fall under the "require very specific libraries"?
  * because yaml is fairly straightforward and an improvement over flat properties file, but a pure flat properties approach is planned
  * because you probably already have yq installed if you are here looking for a templating and deployment tool.
  * the initial kubernetes support uses yaml.
    * sorry there is no json support for kubernetes in shrendd at this time.
* Why `unzip`?
  * because the files needed to be bundled together somehow, and `unzip` is a pretty standard utility.
* Why `curl` or `wget`?
  * needed a way to actually retrieve files from an online source, and almost all modern bash shells come with one or the other.
  * it does not really matter which you use, both have been tested on windows git bash and ubuntu terminals.
* Right now, only windows git bash and Ubuntu are tested and verified. But any modern `bash` terminal with the expected versions of the required tools should work.

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
    build:
      dir: $_MODULE_DIR/deploy/target/build/${target}
    render:
      dir: $_MODULE_DIR/deploy/target/render/${target}
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
  * If possible, provide sample code, or a link to a project to replicate the issue.
  * Ideally, you can fork shrendd and add a new test under the `test` folder.
  * [writing a new test](https://github.com/gtque/shrendd/tree/main/test/README.md)
* Please do check in discussions before filing a bug report to see if the problem has already been addressed, especially if it is just a question of usage.
* Please be mindful, respectful, and patient.
### New Feature request
* add a [new issue](https://github.com/gtque/shrendd/issues) and select Feature request.
* Fill out as much information as you can.
* Describe in as much detail what it is you are wanting to accomplish.
* Please avoid providing suggestions on implementation, unless specifically asked.
### Code Changes
1. Fork the repository: Create your own copy of the original repository under your GitHub account. 
2. Clone your fork locally: Bring the forked repository to your local machine. 
3. Create a new branch: Work on your changes in a separate branch within your local fork. 
4. Make and commit your changes: Implement your desired changes and commit them to the new branch. 
5. Push the branch to your fork: Upload your updated branch with the changes to your forked repository on GitHub. 
6. Create a pull request: On GitHub, navigate to the original repository and propose your changes by creating a pull request from your fork's branch to the original repository's desired branch (often the main or master branch). 
7. Please be respectful of time.
8. Please be courteous in any discussions on the pull request.
9. All tests must be passing before the pull request will be accepted.
   1. Any changes to existing tests will be heavily scrutinized, as that is usually an indication of subverting the test process to achieve falsely passing tests or more critically, a breaking change to existing shrendd functionality.
   2. Any new code changes need to be covered by any existing or net new test as appropriate.