# Quickstart: a walkthrough tutorial on getting started.
Follow the steps below to see how easy it is to get started with shrendd.

**This tutorial is written from the perspective of having cloned shrendd and running from the `shrendd/documents/tutorials/quickstart` folder. You can follow the tutorial steps and use your project instead. Just use your project's directory in place of `shrendd/documents/tutorials/quickstart`.**
*The path is relative to wherever you have cloned the `shrendd` project to.*

1. download the latest version of [`shrendd`](https://github.com/gtque/shrendd/releases/latest/download/shrendd) from releases.
2. copy this file to the directory `shrendd/documents/tutorials/quickstart`
3. open a bash command line
4. navigate to `shrendd/documents/tutorials/quickstart`
5. run: `./shrendd -init`
   1. this will run shrendd with default config
   2. it will download shrendd source for render only
   3. it will stub the `./shrendd.yml` with default values. It is strongly encouraged to just use the defaults, and that is what will be used for the rest of this quickstart tutorial.
   4. if you are missing a required application/tool, the init will fail and inform you of what is missing.
   5. Make sure to have `curl` or `wget` installed
   6. Make sure to have [mikefarrah's yq](https://github.com/mikefarah/yq) v4 (>=4.19.1) installed.
   7. Make sure to have `unzip` installed
6. shrendd is, by default, put into the `./.shrendd` directory. It is recommended that this directory be added to your source control's ignore list.
7. you can now open the `./shrendd.yml` file and...
   1. set a specific version if your project (or business) requires using a locked/specified version for some reason.
      1. while shrendd will strive to maintain backwards compatibility, sometimes that just is not possible. For that purpose, it is strongly encouraged to set a specific version, especially for production purposes.
8. run `./shrendd ?` to see a list of shrendd arguments/parameters.
   1. shrendd does not have a `man` page, as it is not intended to be "installed", and instead side loaded on a project by project basis.

## upshrendd
once it has been run once, and if you set a specific shrendd version, you can now run `./.shrendd/upshrendd` to update or change the shrendd version.
1. Open up `./shrendd.yml`
2. set `shrendd.version` to 0.12.0-beta
   1. this will actually force a downgrade.
3. save the change
4. if not already open, open a bash command line
5. navigate to `shrendd/documents/tutorials/quickstart`
6. run `./.shrendd/upshrendd`
   1. you should see the output from `upshrendd`
7. in the `./shrendd.yml` file, set the version back to the latest version
8. save the change
9. run `./.shrendd/upshrendd`
   1. you should see the output from `upshrendd`
10. `upshrendd` will print out some messaging based on direction and compatibility.
    1. Hopefully there won't ever be backwards compatibility issues, but never say never.
    2. It is however possible for new features or functionality to not be available if you downgrade.
    3. Downgrading should be a last resort, reserved for emergency or security remediation purposes.
    4. Ever forward.
11. You can check the locally download version in the `./.shrendd/version.yml` file.

## your first template
1. define your templates (see also [Hello, World](https://github.com/gtque/shrendd/tree/main/docuemtns/examples/helloWorld))
   1. basic templating is handle with shell string substitution and the files are treated as plain text.
   2. simple templating is basic variable substitution using either the `$(getConfig name.of.property)` or `${NAME_OF_PROPERTY}` pattern.
   3. it is encouraged that basic value templating be done using the `$(getConfig ...)` approach.
      1. example: `hello, $(getConfig hello.world)!`
   4. properties/variables in the input file (`./config/localdev.yml`) are expected to be lower case and refrenced using `.` notation and those passed as a system or environment variable should be uppercase and use `_` instead of `.`
      1. `NAME_OF_PROPERTY` is equivalent to `name.of.property` which maps to the yaml:
        ```yaml
        name:
          of:
            property: some, value.
        ```
   5. while not strictly required, it is recommended to avoid using spaces or special characters in the property/variable names.
   6. template files, regardless of final type, must use the `.srd` extension.
   7. don't just copy the files from helloWorld, that misses the point of the tutorial.
2. create, if it does not already exist, the `./deploy/render/templates` directory
3. create `./deploy/render/templates/basic.txt.srd` text file
4. open `./deploy/render/templates/basic.txt.srd` in a text editor of your choice.
5. add the line: `hello, $(getConfig my.first.shrendd)!`
6. add the line: `${SIMPLE_QUESTION}`
7. save the file
8. open a bash command line
9. navigate to `shrendd/documents/tutorials/quickstart`
10. run `./shrendd`
11. This should fail.
12. create, if it does not already exist, `./config/localdev.yml`
    1. this should have been automatically stubbed when you ran `./shrendd`, if not you will need to manually create it.
13. open `./config/localdev.yml` in a text editor.
14. add the properties/variables:
    ```yaml
    my:
      first:
        shrendd: Keanu
    simple:
      question: "How much wood could a woodchuck chuck, if a woodchuck could chuck wood?"
    ```
15. save the file
16. run `./shrendd` again
    1. there should be no errors this time.
    2. You should see some warning though.
    3. shrendd supports defining an [input file schema](https://github.com/gtque/shrendd/tree/main/docuemtns/examples/helloWorld) that is used for validating the input files.
17. you can now open `./deploy/target/render/render` and see the rendered output.
18. play around with the template file, add additional templated values, change the values in the localdev.yml file, see what happens.
    1. try changing the second line in `basic.txt.srd` from `${SIMPLE_QUESTION}` to using the `$(getConfig ...)` pattern.
