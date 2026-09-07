Review one language's translations against the project's translation rules.

Takes a language code as an argument — `fr`, `de`, `ja`, `ko`, `nl`, `es`. With
no argument, review every language the catalog carries, one at a time, and do
not merge the reports.

## Read the rules first, do not recall them

- [`conventions/translation.md`](../../conventions/translation.md) — the rules this review applies
- [`conventions/localization.md`](../../conventions/localization.md) — `.localized`, `.locales`, and why the verse stays English

Anything below is a procedure for applying those rules, not a replacement for
reading them.

## Start with what the machine already knows

Run these before reading a single string. They cover the mechanical failures,
and repeating that work by eye wastes the part of the review only a reader can
do:

```
./scripts/check-locales.sh          # registries agree; per-language coverage
./scripts/check-docs-versions.sh    # no locale states a stale iOS floor
./scripts/build.sh test-unit        # format specifiers, cited verse, grade ladders
```

Report what they say. If coverage is short, the missing keys are the review.

## Then read the strings

```bash
python3 -c "
import json
d = json.load(open('LeavesOfBlocks/Resources/Localizable.xcstrings'))['strings']
lang = 'fr'
for k, v in sorted(d.items()):
    loc = v.get('localizations', {})
    if lang in loc:
        print(k)
        print('  en:', loc['en']['stringUnit']['value'])
        print('  %s: %s' % (lang, loc[lang]['stringUnit']['value']))
"
```

Read all of them. A translation review is not a spot check: the defects that
matter — a term used two ways, a register that slips — are only visible across
the whole set.

## What to look for, in order

1. **Anything still in English** that is not the cited verse, a poem title, a
   brand, or an entry in `attestedCognates` in `GradeLadderLocalizationTests`.
2. **Glossary drift.** Build the list of the game's nouns and verbs as this
   language renders them — block, grid, row, column, line, clear, place, combo,
   score, undo, hint, cancel — and check each is one word throughout. French
   once had `undo` and `cancel` both as *Annuler*.
3. **Register slips.** One form of address, everywhere. A single *vous* among
   *tu*, one 합니다 among 해요, is the tell.
4. **Platform terms.** Where iOS has its own word for a thing, the app should
   use it. `Game Center` and the app name are never translated.
5. **Claims that are checkable.** Counts, rates, version floors, difficulty
   mode names — verify against the code, not against the English string. The
   English has been wrong three times.
6. **Privacy and destructive strings.** `technical_description`,
   `game_center_enable_description`, `clear_history_warning`,
   `reset_data_warning`. Translate each back into English and compare the
   strength of the claim, not its shape. "Cannot be undone" must still say
   that.
7. **Length.** Flag any UI label much longer than its English source —
   `CompactStatCard` shrinks rather than wraps. Confirm suspicion by capturing
   the screen, not by counting characters alone.
8. **Invention.** Coined words, idiom you cannot attest, regionalisms in a
   locale that is not regional. Prefer the plainer construction.
9. **Metadata.** `keywords.txt` is a search set for that territory, not a
   translation of the English keywords. `name.txt` keeps the brand.

## Reporting

One table: key, current value, what is wrong, suggested value, and how sure you
are. Sort by severity — a wrong privacy claim first, an awkward preposition
last.

**Do not edit strings as part of the review.** Propose. The person who reads
the language decides, and a review that has already made the change gives them
nothing to review.

State your confidence honestly per finding. "This reads oddly to me but may be
idiomatic" is useful; a confident-sounding correction that is wrong is worse
than silence, because nobody here can check it.

If the same defect appears in several keys, say so once and list the keys —
that is a glossary problem, and fixing it key by key will miss the next one.
