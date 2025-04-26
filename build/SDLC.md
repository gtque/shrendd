# Software Development Life Cycle

### Branching Strategy
This project uses a hybrid version of trunk based development and git flow. New work will be
done in a branch created off of main. When the work is completed, it will be merged back to main.
Once a decision has been made in regard to when or what features should be in a new release,
a release branch will be created off of main. Only Major.Minor releases will get a release branch.
Any patches/hotfixes for a given Major.Minor release will follow a mini-trunk based branching strategy.
The "fix" will be implemented in a branch off of the given release branch, merged back to that release
branch, and a new release will be published from the release branch. Any required changes will be 
cherry-picked back to main if possible, otherwise the changes will be replicated as necessary
following the new feature work branching strategy. There will be no dev/development branch.

### Versioning
shrendd uses a variation of Semantic Versioning (see: https://semver.org/). All minor and patch releases are promised to be backwards compatible for that
major release. `-alpha` and `-beta` versions are pre-release versions. `-alpha` are development releases.
`-beta` is a more stable release candidate version. There will be no `-rc` versions. `-alpha` versions
will include feature branch name if built from a feature branch.

## Process
### Main Development
1. Branch feature from main
2. Work on feature
   1. Feature branches should use the `-alpha+[branch-name]` version pattern
   2. should always be marked as pre-release
   3. should never be marked as latest
   4. branch name must have all spaces (` `) changed to `.`
   5. branch name must have all underscores (`_`) changed to `-`
   6. publish a `-alpha` version for experimental consumption and testing
3. Merge feature back to main
   1. all tests must pass or be accepted as failing
   2. publish a `-beta` version for early adoption and validation testing
   3. should always be marked as pre-release
   4. should never be explicitly set as latest
4. create new release
   1. branch for release
   2. remove `-beta` from version
   3. publish a "release" version as latest version
   4. should never be marked pre-release
   5. should always be marked as latest

### Patches/Hotfixes
1. Branch feature from release branch
2. Work on feature
   1. Feature branches should use the `-alpha+[branch-name]` version pattern
   2. should always be marked as pre-release
   3. should never be marked as latest
   4. branch name must have all spaces (` `) changed to `.`
   5. branch name must have all underscores (`_`) changed to `-`
   6. publish a `-alpha` version for experimental consumption and testing
3. Merge feature back to release branch
   1. all tests must pass or be accepted as failing
   2. publish a "release" version as latest version
   3. should never be marked pre-release
   4. should never be marked as latest
4. Merge fix to main if required
   1. cherry-pick if possible
   2. if cherry-pick is not possible, follow main development process

#### Notes
While patching will be supported with the branching, versioning, and development processes,
the expectation is that it will not be frequent, if at all. One of the primary tenants
those working on this project follow is to be as backwards compatible as possible. It is
acknowledged, however, that it is not always possible and that there will be breaking changes
at some point. It is also understood that adopting breaking changes is not always possible
when desired, so sometimes fixing something in the previous versions is a show of support and
appreciation for those using this project.