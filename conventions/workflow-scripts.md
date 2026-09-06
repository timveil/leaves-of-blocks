# No inline scripting in GitHub Actions

**A `run:` step invokes a command. It does not implement logic.**

Anything with branching, iteration, or parsing goes in `scripts/` and gets
called from the workflow.

## Why

Logic inside a `run:` block can only be executed by pushing a commit. You
cannot run it, cannot test it, and cannot reproduce a failure locally — the
feedback loop for a one-character fix is a full CI round trip. It is also
invisible to every tool that would otherwise help: no shellcheck, no syntax
highlighting worth the name, no `bash -n`.

The cost compounds quietly, because the code that ends up in workflows is
exactly the code most likely to be subtly wrong: range semantics, path
matching, empty-input edge cases. That logic deserves tests more than most
application code does, and inline it can have none.

## The threshold

Extract when a step does any of:

- loops over data
- branches on data
- parses or transforms text
- runs past roughly ten lines

Dispatching on `github.event_name` to decide *which script to call* is glue,
not logic — that can stay inline. So can a single command, however long its
argument list.

## Wrong

```yaml
- name: Validate each commit in the PR
  run: |
    mapfile -t SUBJECTS < <(git log --no-merges --format='%s' "$BASE..$HEAD")
    fail=0
    for subject in "${SUBJECTS[@]}"; do
      if ./scripts/check-commit-subject.sh "$subject"; then
        echo "ok"
      else
        fail=1
      fi
    done
    [ "$fail" -eq 0 ] || exit 1
```

## Right

```yaml
- name: Validate each commit in the PR
  env:
    BASE_SHA: ${{ github.event.pull_request.base.sha }}
    HEAD_SHA: ${{ github.event.pull_request.head.sha }}
  run: ./scripts/lint-commit-range.sh "$BASE_SHA" "$HEAD_SHA"
```

## Make the extracted script testable

Extraction is only half the win. A script that can *only* be driven by real CI
state has moved the problem rather than solved it, so give it a mode that takes
fixed input:

- `lint-commit-range.sh --stdin` takes subjects directly, so the iteration can
  be tested without constructing git history.
- `codeql-languages.sh` reads changed paths on stdin, so the path→language
  mapping can be tested without a pull request.

Both have a companion `test-*.sh` covering the cases that matter.

## Enforcement

Partly automated. [`.github/workflows/tooling.yml`](../.github/workflows/tooling.yml)
runs every `scripts/test-*.sh` and verifies the fastlane configuration loads, so
an extracted script that breaks fails a PR.

What is still review-only is the extraction itself: nothing fails a PR that
inlines a loop instead of extracting it. A linter over `run:` step bodies would
close that, and the audit query in the section below is the shape it would take.

Current state, audited at the time of writing: every `run:` step in the
repository is at most ten lines with at most one conditional. The two in
`codeql.yml` that come closest are deliberate — `Detect affected languages`
branches on `github.event_name` to choose a script invocation, and `Report
selection` is straight-line `echo` into `$GITHUB_STEP_SUMMARY` with no logic at
all.

## See also

- [One rule, one definition](shared-rule-single-source.md)
