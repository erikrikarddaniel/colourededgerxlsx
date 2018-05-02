# Integration tests

This directory contains simple integration tests setup in a `Makefile`. Each
test is a target in the `Makefile` and aims to test that the script works well
on defined input both in terms of files/tables and command line arguments.

In addition to individual tests, there's a `colourededgerxslx` target that runs
all tests:

```
$ make colouredgegxslx
```

The tests are *not* automated, and no check if output corresponds to what can
be expected is performed. After a successful test run, i.e. one that doesn't
produce exceptions, the output xlsx file needs to be manually checked to make
sure it looks like expected.

Any new functionality in the script should be covered by a test. In the case of
major new functions, a new test case is advisable.
