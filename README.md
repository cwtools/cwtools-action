# CWTools Action

Example workflow yml:
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
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```

By default will only annotate changed files, in order to annotate all files set `changedFilesOnly` input to `"0"`.
```yml
    - uses: cwtools/CWTools-action@master
      with:
        changedFilesOnly: "0"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Using [tboby/cwtools](https://github.com/tboby/cwtools).

Based on [gimenete/rubocop-action](https://github.com/gimenete/rubocop-action) by Alberto Gimeno.