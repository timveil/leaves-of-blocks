# Test first

**Write the failing test, watch it fail, then make it pass.** For every change
that alters observable behavior — features, bug fixes, refactors that change
what the code does, and review remediations.

## The cadence

1. Write a test that demonstrates the behavior you want, or for a bug, the bug.
2. **Run it and confirm it fails.** Say so where the work is reported: *"`X` fails as expected: `<actual>`"*.
3. Implement.
4. Confirm it passes.
5. Run the rest of the suite for regressions.

Step 2 is the one that gets skipped, and it is the one that carries the value.
A test written after the code passes on the first run, which tells you nothing:
you cannot distinguish a test that verifies the behavior from a test that
verifies nothing. Watching it fail for the *right reason* is the receipt.

## When there is nothing to assert

Cosmetic view changes, `MARK:` comments, file moves, documentation. Say so
explicitly — *"no test possible; verified by build and inspection"* — rather
than skipping the step quietly. The distinction between "untestable" and
"untested" should be visible in the record.

## Prove the test can fail

A test that cannot fail is worse than no test: it reports confidence it has not
earned, and it survives every refactor that breaks the thing it claims to
cover. When a test passes on the first run, or covers something subtle, break
the implementation on purpose and confirm it goes red.

This is not theoretical here. Working through the CI and release tooling, five
separate assertions turned out to be incapable of failing:

| What looked fine | What was actually true |
| --- | --- |
| A suite reporting "all passed" | `>/dev/null` was swallowing the assertion results |
| A green runner | It aborted non-zero on the *success* path (bash 3.2 empty array) |
| A failure message | It reported `1` whatever the command returned |
| A boundary test | Its fixtures were never checked to be on the boundary |
| A "not the target size" assertion | Also true of the wrong answer, `0B` |

Three were caught by deliberately breaking the code, not by the suite going red
on its own.

## Where the tests live

- **Swift** — `LeavesOfBlocksTests/`, Swift Testing. See [testing](testing.md) for the shape.
- **Shell** — a `test-*.sh` beside the script, discovered by `scripts/run-script-tests.sh`.
- **Ruby** — `fastlane/test/`, run through `scripts/test-release-helpers.sh`.

`./scripts/run-script-tests.sh` runs everything except the Swift suites; those
run through `./scripts/build.sh test`.

## Enforcement

Review. CI runs the tests but cannot tell whether they were written first — the
honesty of step 2 is on the author.

## See also

- [Testing](testing.md) — how to write the test once you have decided to
