# shrendd
template rendering and deployment

## ToDo
1. build
   1. ~~package~~
   2. ~~run tests~~
   3. ~~version bump support~~
   4. ~~branch and remove beta version.~~
   5. run tests as part of build, don't build if tests fail.
   6. ~~publish upshrendd compatibility~~
      1. ~~this is needed before even considering 1.0~~
      2. ~~indicate if version is backwards compatible or not~~
      3. ~~upshrendd needs to check for targeted version and see if version is compatible~~
      4. ~~if downgrading, need to check if downgrade is compatible~~
      5. ~~interactive prompt to allow user to force upshrendd if version not compatible~~
         1. ~~instead of prompting, will just provide the hint that it can be forced with -f~~
      6. ~~support `-f` flag for silent force, aka no interactive prompting~~
   7. release notes file
2. ~~publish~~
   1. ~~upload to github~~
   2. ~~check if release already exists~~
3. ~~bootstrap shrendd~~
4. ~~custom module source~~
5. **tests**
   1. ~~latest version~~
      1. ~~upshrendd~~
      2. ~~version specified~~
      3. ~~latest - specified by default~~
      4. ~~latest - explicitly set to latest~~
   2. render value with ${...} or $(getConfig ...) approach
      1. ~~just the provided config, no template~~
      2. ~~just the template, no values from config, ie: default value from config-template~~
      3. a mix of provided and template defaults
      4. ~~render with default render target~~
   3. custom render targets
   4. custom template targets
   5. complex rendering
      1. native bash functions
      2. custom functions
   6. config template
      1. utilize template
      2. ~~extract template~~
      3. ~~generate config from template~~
   7. k8s
   8. ~~custom module source~~
   9. bootstrap
6. **how to**
7. additional modules
   1. ~~k8s~~
   2. docker
   3. terraform
   4. scp
   5. aws
   6. google cloud
   7. azure
8. additional functionality
   1. ~~stub templates for deployment module types~~
   2. ~~delete all render directories~~
   3. ~~make k8s teardown identifier configurable~~
   4. ~~custom config location~~
   5. ~~custom module configs~~
      1. ~~a "module" is a separate folder in the root that contains templates~~
      2. ~~each "module" may have its own configuration~~
      3. ~~template dir, rendered dir, config dir~~
   6. ~~default config in shrendd.yml~~
   7. ~~warning if shrendd file is out of date~~
   8. ~~stub config template from existing complete config yml~~
   9. ~~support and use description field in config template~~
   10. ~~warn if extra properties in config file not defined in template, with optional strict mode to fail~~
   11. ~~color code log output~~
       1. ~~implement color coding of log output~~
       2. ~~support customizing colors for log output~~
   12. **config-template**
       1. ~~include description in error/warning logs~~
       2. stub config-template from template files.
           1. ~~stub everything as required~~
           2. add description as comment
           3. ~~add commented out default value to config-template~~
           4. ~~update config-template~~
       3. ~~generate a <config>.yml file from config-template~~
   13. support setting configuration(s) in shrendd.yml by running `shrendd -set <key>=<value>`
       1. main shrendd properties by default
          1. will still respect custom location for shrendd.yml
       2. module properties if --module <module> specified
   14. **support "plugins"**
       1. plugin configs
           1. may have a default
           2. may be included in the shrendd.yml file
           3. may be its own file
   15. ~~support multiple modules at one time~~
   16. ~~just "render" support~~
   17. ~~sensitive values~~
       1. ~~mark as sensitive in config-template~~
       2. ~~mask when logging~~
9. how to contribute documentation
   1. submitting bugs
   2. requesting features
   3. contributing

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
