# CWTools Action

## Example workflow yml
```yml
name: CWTools CI

on: [pull_request] # also works with push

jobs:
  cwtools_job:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - uses: cwtools/CWTools-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # required

```

## Inputs
### changedFilesOnly
By default will only annotate changed files, in order to annotate all files set `changedFilesOnly` input to `"0"`.
```yml
    - uses: cwtools/CWTools-action@master
      with:
        changedFilesOnly: "0"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
### suppressedOffenceCategories
You can choose to suppress annotations with chosen CWTools offence category IDs (`CW###`) per Github severity type (failure, warning, notice).
```yml
    - uses: cwtools/CWTools-action@master
      with:
        suppressedOffenceCategories: '{"failure":["CW110", "CW210"], "warning":[], "notice":[]}' # will suppress CW110 and CW210 category failures, but will show those for warnings and notices
      env:
        default: ${{ secrets.GITHUB_TOKEN }}
```

## Credits
Using [tboby/cwtools](https://github.com/tboby/cwtools).

Based on [gimenete/rubocop-action](https://github.com/gimenete/rubocop-action) by Alberto Gimeno.