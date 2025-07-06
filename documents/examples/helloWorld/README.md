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
