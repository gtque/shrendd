# Contributing
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
5. Add a "release_note" file with bullet point list of changes.
   1. The file name should follow the pattern: `<targeted.version>-alpha+<branch-name>.txt` 
   2. the file should be added to `build/release_notes` dir
6. Push the branch to your fork: Upload your updated branch with the changes to your forked repository on GitHub.
7. Create a pull request: On GitHub, navigate to the original repository and propose your changes by creating a pull request from your fork's branch to the original repository's desired branch (often the main or master branch).
   1. Manually squash all the commits or set the pull request to squash.
8. Please be respectful of time.
9. Please be courteous in any discussions on the pull request.
10. All tests must be passing before the pull request will be accepted.
    1. Any changes to existing tests will be heavily scrutinized, as that is usually an indication of subverting the test process to achieve falsely passing tests or more critically, a breaking change to existing shrendd functionality.
    2. Any new code changes need to be covered by any existing or net new test as appropriate.