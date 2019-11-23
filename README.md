# CWTools Action
Run CWTools on your Clausewitz mod PDXScript code in parallel to your builds.

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
      with:
        game: hoi4
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # required

```

The full `output.json` log is saved to `$GITHUB_WORKSPACE`, and can be recovered with [actions/upload-artifact](https://github.com/actions/upload-artifact).
```yml
    - uses: cwtools/CWTools-action@master
      with:
        game: hoi4
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    - name: Upload artifact
      if: always() # so even if the check fails, the log is uploaded
      uses: actions/upload-artifact@v1.0.0
      with:
        name: cwtools_output
        path: output.json
```

## Inputs
### game (required)
What game to use. Allowed values: `hoi4`, `ck2`, `eu4`, `ir`, `stellaris`, `vic2`.
```yml
    - uses: cwtools/CWTools-action@master
      with:
        game: hoi4
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
### cache (optional)
Path to the full cache file (`cwb.bz2`) in $GITHUB_WORKSPACE (root of repository). Use an empty string to use metadata from cwtools/cwtools-cache-files (Default: use metadata)
```yml
    - uses: cwtools/CWTools-action@master
      with:
        game: hoi4
        cache: "cache/hoi4.cwb.bz2"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
### changedFilesOnly (optional)
By default will only annotate changed files, in order to annotate all files set `changedFilesOnly` input to `"0"`.
```yml
    - uses: cwtools/CWTools-action@master
      with:
        game: hoi4
        changedFilesOnly: "0"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
### suppressedOffenceCategories (optional)
You can choose to suppress annotations with chosen CWTools offence category IDs (`CW###`) per Github severity type (failure, warning, notice).
```yml
    - uses: cwtools/CWTools-action@master
      with:
        game: hoi4
        suppressedOffenceCategories: '{"failure":["CW110", "CW210"], "warning":[], "notice":[]}' # will suppress CW110 and CW210 category failures, but will show those for warnings and notices
      env:
        default: ${{ secrets.GITHUB_TOKEN }}
```

## Credits
Using [tboby/cwtools](https://github.com/tboby/cwtools).

Based on [gimenete/rubocop-action](https://github.com/gimenete/rubocop-action) by Alberto Gimeno.