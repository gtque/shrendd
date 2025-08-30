# How to write a test

1. copy the `build/test/template` folder to `test/[new_test_name]` folder. example: `cp -r build/test/template test/my_new_test`
2. update the shrendd.yml file as necessary
   1. add any libraries, targets, plugins, etc... needed for the test
3. define a config-template.yml file if necessary
4. update/add values to localdev.yml if necessary
5. update test.sh
   1. add any necessary actions to clean up or reset before the actual test execution, ie before running shrendd
   2. update the shrendd command with necessary parameters
   3. capture values to be validated
   4. add necessary if statements with calls to passed/failed as appropriate for validating/asserting the values.
6. from the test's folder (example: test/my_new_test), run `test.sh` and validate the test results.
7. update build/test.sh
   1. add the new test folder to the test list by adding to an existing `export _TESTS` line, with a space between, or adding a new line following the pattern
      1. `export _TESTS="$_TESTS my_new_test"`
8. all tests can be executed by running `build/test.sh` from the root `shrendd` folder.