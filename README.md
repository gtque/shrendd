# shrendd
template rendering and deployment

## ToDo
1. build
   1. package
   2. run tests
   3. version bump support
2. upload
3. ~~bootstrap shrendd~~
4. ~~custom module source~~
5. tests
   1. latest version
      1. upshrendd
      2. version specified
      3. latest
   2. custom render targets
   3. custom template targets
   4. default values
   5. config template
   6. k8s
   7. custom module source
   8. bootstrap
6. how to
7. additional modules
   1. docker
   2. terraform


## Getting Started
* download the appropriate version of `shrendd` from releases. it is recommended just grab the latest version.
* this should go in the root of your project.
* create a shrendd.yml file and specify the targets, or don't and just use the default.
```yaml
shrendd:
  targets:
  - name: k8s
  - name: docker
  - name: terraform
```
* open a command line and navigate to the root of your project
* run: `./shrendd -r`
  * this will run shrendd with default config and only attempt to render templates
  * it will download shrendd source for specified targets
* once it has been run once, you can now run `.shrendd/upshrendd` to update or change the shrendd version
  * to use a specific version of shrendd, you can specify the shrendd.version in the shrendd.yml file.
  * if version is not specified, it assumes "latest"
* define your templates
  * default template and render directories:
```yaml
    template:
      dir: $_MODULE_DIR/deploy/${target}/templates
    render:
      dir: $_MODULE_DIR/deploy/${target}/rendered
```

## Bootstrap
You can bootstrap shrendd by adding a boot.shrendd file to the same directory as the "shrendd" file.
This is where you can define functions for getting custom shrendd target modules
or anything else that needs to be done prior to shrendd running. 
Please note: this will have access to the loaded functions from "shrendd" but not the templating, rendering, or deployment functions.