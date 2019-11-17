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
Using [tboby/cwtools](https://github.com/tboby/cwtools).

Based on [gimenete/rubocop-action](https://github.com/gimenete/rubocop-action) by Alberto Gimeno.