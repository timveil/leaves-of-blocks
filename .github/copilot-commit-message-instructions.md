# Commit Message Instructions for GitHub Copilot

Generate commit messages following the **Conventional Commits** specification.

## Format

```
<type>(<scope>): <description>
```

## Types (required)

| Type | Description | Changelog Section |
|------|-------------|-------------------|
| `feat` | New feature or functionality | Added |
| `fix` | Bug fix | Fixed |
| `docs` | Documentation changes | (ignored) |
| `style` | Code style/formatting (no logic change) | Changed |
| `refactor` | Code refactoring | Changed |
| `perf` | Performance improvement | Changed |
| `test` | Adding or updating tests | (ignored) |
| `chore` | Maintenance, dependencies, configs | (ignored) |
| `build` | Build system or external dependencies | (ignored) |
| `ci` | CI/CD configuration changes | (ignored) |
| `revert` | Reverting a previous commit | Removed |

## Scope (optional)

Use scope to indicate the area affected:
- `game` - Game logic, gameplay
- `ui` - User interface components
- `grid` - Grid system
- `blocks` - Block shapes and placement
- `score` - Scoring system
- `settings` - Settings and preferences
- `fastlane` - Fastlane and deployment
- `ci` - CI/CD workflows
- `deps` - Dependencies

## Rules

1. Use **lowercase** for type and scope
2. Use **imperative mood** in description ("Add feature" not "Added feature")
3. Keep description under **72 characters**
4. Do NOT end description with a period
5. Be specific about what changed

## Examples

**Good:**
- `feat: Add dark mode support`
- `fix(grid): Resolve block placement overlap`
- `refactor(game): Simplify score calculation logic`
- `docs: Update README installation steps`
- `chore(deps): Update fastlane to 2.220`
- `perf(ui): Optimize grid rendering performance`
- `feat(blocks): Add new L-shaped block variant`

**Bad:**
- `Updated stuff` (no type, vague)
- `Fix bug.` (no type, ends with period)
- `FEAT: Add feature` (uppercase type)
- `feat: added new feature` (past tense, vague)
