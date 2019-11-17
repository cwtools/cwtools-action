# CWTools Action

Example workflow yml:
```yml
name: CI

on: [push]

jobs:
  cwtools_job:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
      with:
        fetch-depth: 1
    - uses: Yard1/CWTools-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```