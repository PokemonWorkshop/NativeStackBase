# Helper test suite
Tests for the CMake helpers in `cmake/helpers/`. They are off by default.

```bash
cmake -S . -B build -DHELPER_TEST_SUITE=ON
cd build && ctest -j8
ctest -R options               # only the cases whose name matches
ctest --output-on-failure      # show the configure output of failing cases
ctest -N                       # list the cases without running them
```

## Why it is built this way

The helpers do their work at **configure** time, and they record declarations in
internal ENV variables that live as long as the `cmake` process. Two cases in
one process would see each other's records, so a case cannot be a function call
inside a shared project. Each case is instead **its own `cmake` configure run**,
which also means cases are isolated by construction and can run in parallel.

There is nothing to compile: the suite judges each case on what its configure
printed, and on whether it failed.

```
tests/
  CMakeLists.txt            registers the cases, packs the fixture
  harness/CMakeLists.txt    the project every case is configured as
  fixtures/demodep/         the fake dependency, packed into an archive
  cases/<name>.cmake        one case: just the declarations under test
```

`harness/CMakeLists.txt` sets the module path, includes the helpers, then
`include()`s the case file. A case therefore contains only the calls it is about,
and can use these variables:

| Variable | Meaning |
| --- | --- |
| `ND_DEP_ARCHIVE` | path to the packed fixture, for `SOURCE_URL`/`BIN_URL` |
| `ND_DEP_HASH` | its `SHA256=...`, for `SOURCE_HASH`/`BIN_HASH` |
| `ND_CASE` | the case file's own path |
| `ND_HELPERS_DIR` | `cmake/helpers/` |

## The fixture

`fixtures/demodep/` is a stand-in for a real dependency, packed into a
`.tar.gz` at configure time by `file(SHA256)` + `cmake -E tar`. Packing it rather
than committing it keeps the repository text-only and still gives `source_url`
mode a real archive and a real hash to verify.

It declares `cmake_minimum_required(VERSION 3.10)` **on purpose**. Anything below
3.13 without the `...<max>` range form leaves CMP0077 at `OLD`, so `option()`
ignores a normal variable of the same name set by the parent — which is exactly
the trap `_nd_apply_options()` works around. A fixture that asked for 3.28 would
pass whether or not the helper handled it.

It prints `DEP SEES DEMO_OPT='...' DEMO_OTHER='...'`, which is what most cases
assert on.

## Adding a case

Write `cases/<name>.cmake` with the declarations, then register it:

```cmake
nd_add_case(<name> PASS "<regex>")                 # expected to configure cleanly
nd_add_case(<name> EXPECT_ERROR PASS "<regex>")    # expected to FATAL_ERROR
```

`PASS` is a CTest `PASS_REGULAR_EXPRESSION`: the case passes when the output
matches. Without `EXPECT_ERROR`, a `FAIL_REGULAR_EXPRESSION` of `CMake Error` is
added as well, so a case cannot pass while quietly erroring somewhere else.

Two things to watch:

- **Keep each regex short.** CMake line-wraps the text of warnings and errors, so
  a long pattern can end up straddling a line break and never match.
  `message(STATUS)` output is *not* wrapped, which is why the fixture reports
  through it.
- **`(` and `)` are regex metacharacters.** Either avoid them or use `.` — the
  conflict cases match `OPTIONS DEMO_OPT: 'ON'` rather than trying to include
  `(previous)`.

A case that asserts something CTest cannot see from the outside can check it
itself and call `message(FATAL_ERROR ...)`, then assert on a `STATUS` line it
prints on success. `cases/options-not-leaked.cmake` does that to prove the
options reached neither the consumer's scope nor the cache.

## Checking the tests actually test something

A green suite proves nothing until a case has been seen to fail. Copy the repo
somewhere disposable, break the helper, and confirm the right cases go red:

```bash
work=$(mktemp -d)
tar -cf - -C . --exclude=./.git --exclude=./build . | tar -xf - -C "$work"
sed -i '/set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)/d' \
  "$work/cmake/helpers/DeclareNativeDependency.cmake"
cmake -S "$work" -B "$work/b" -DHELPER_TEST_SUITE=ON && (cd "$work/b" && ctest)
```

Removing that one line fails the four behaviour cases that need an option to
reach the dependency, and leaves the rest green. Dropping the
`_nd_diff_options()` calls fails exactly the three option-conflict cases.
