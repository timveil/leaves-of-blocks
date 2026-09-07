#!/usr/bin/env ruby
#
# ai_helper_test.rb - Exercise the pure response handling in fastlane/AIHelper.rb.
#
# No network: every case feeds parse_prose_response a synthetic API payload.
# What is worth testing here is the part that differs per locale, because none
# of it was visible while every listing got English -- a Latin-only sentence
# scan, and a closing sentence appended in English regardless of the language
# around it.
#
#   ruby fastlane/test/ai_helper_test.rb

require_relative '../AIHelper'

$pass = 0
$fail = 0

def ok(desc)
  $pass += 1
  puts "  ok    #{desc}"
end

def bad(desc, detail)
  $fail += 1
  puts "  FAIL  #{desc}"
  puts "        #{detail}"
end

def assert_equal(expected, actual, desc)
  expected == actual ? ok(desc) : bad(desc, "expected #{expected.inspect}, got #{actual.inspect}")
end

# Every block the API returns carries a "type". The fixtures here used to omit
# it, which is how a parser that trusted index 0 passed a suite that never
# built the payload the API actually sends.
def parse(text, locale = nil)
  AIHelper.send(:parse_prose_response,
                { 'content' => [{ 'type' => 'text', 'text' => text }] }, locale)
end

CLOSING = 'Thank you for playing'.freeze

puts "the English closing"

# The prompt asks for this closing, but a model that drops it should not ship
# notes without one. Previously this only ran when the text was long enough to
# be truncated, so short English notes missing it went out as they came back.
assert_equal(true, parse('Short and sweet.').include?(CLOSING),
             "short English notes still get a closing")
assert_equal(true, parse('Short and sweet.', 'en-US').include?(CLOSING),
             "an explicit English locale gets one too")

already = "All good. #{CLOSING} Leaves of Blocks!"
# The net matched the literal "Thank you for playing", so a model that closed
# with "Thanks so much for playing" was judged to have no closing and got a
# second one bolted on. The 2.1.0 English notes went out of the generator with
# two thank-yous, one under the other.
thanked = 'All good things. Thanks so much for playing Leaves of Blocks!'
assert_equal(1, parse(thanked).scan(/[Tt]hank/).length,
             "any closing thanks counts as one; no second is appended")

assert_equal(1, parse(already).scan(CLOSING).length,
             "a closing already present is not doubled")

puts
puts "translated notes are not given an English closing"

# Appending an English sentence to German or Japanese prose is worse than
# having no closing at all, so a translated listing simply goes without.
assert_equal(false, parse('Kurz und gut.', 'de-DE').include?(CLOSING),
             "German notes are left alone")
assert_equal(false, parse('短くていい感じです。', 'ja').include?(CLOSING),
             "Japanese notes are left alone")
assert_equal('Kurz und gut.', parse('Kurz und gut.', 'de-DE'),
             "and come back exactly as written")

puts
puts "truncation finds a sentence boundary in either script"

long_english = ('This is a sentence about blocks. ' * 200)
truncated = parse(long_english, 'en-US')
assert_equal(true, truncated.length <= 4000, "English is brought under the limit")
assert_equal(true, truncated.include?(CLOSING), "and still closes")

# U+3002 is the Japanese full stop. A Latin-only scan finds no boundary in this
# text at all and would cut it mid-sentence.
long_japanese = ('ブロックを置いてラインを消します。' * 300)
truncated_ja = parse(long_japanese, 'ja')
assert_equal(true, truncated_ja.length <= 4000, "Japanese is brought under the limit")
assert_equal(true, truncated_ja.end_with?('。'), "Japanese is cut at a sentence end, not mid-sentence")
assert_equal(false, truncated_ja.include?(CLOSING), "and gets no English closing")

puts
puts "payload handling"

assert_equal(nil, AIHelper.send(:parse_prose_response, { 'content' => [] }, nil),
             "an empty payload yields nil")
assert_equal(nil, AIHelper.send(:parse_prose_response, {}, nil),
             "a malformed payload yields nil")
assert_equal(true, parse("**Bold opening.**").start_with?('Bold'),
             "stray markdown is stripped")

# A response is a list of blocks, not a text block with extras after it. The
# model may emit a thinking block first, and that block carries no "text" key
# -- so reading index 0 returned nil while the prose sat in index 1. Every
# fixture above builds a single text block, which is the shape that cannot
# fail, so nothing here could see it. Ten App Store listings shipped the
# English template because of it.
thinking = {
  'content' => [
    { 'type' => 'thinking', 'thinking' => 'Considering the tone...' },
    { 'type' => 'text', 'text' => 'Kurz und gut.' }
  ]
}
assert_equal('Kurz und gut.', AIHelper.send(:parse_prose_response, thinking, 'de-DE'),
             "prose is read from the text block, not from index 0")

changelog_thinking = {
  'content' => [
    { 'type' => 'thinking', 'thinking' => 'Grouping the commits...' },
    { 'type' => 'text', 'text' => '{"added":["A feature"],"changed":[],"fixed":[],"removed":[]}' }
  ]
}
assert_equal(['A feature'],
             AIHelper.send(:parse_changelog_response, changelog_thinking)&.fetch(:added, nil),
             "the changelog parser reads the text block too")

puts
puts "bullets"

# App Store notes are scanned, not read (#164), so the prompt asks for bullet
# lines. The markdown cleanup used to delete them: Ruby anchors ^ at every
# line start, so gsub(/^\*++/, '') stripped an asterisk bullet down to bare
# indentation. A model reaching for "*" instead of the requested "•" would
# have produced bullet-less lines, intermittently and per locale -- the same
# shape of failure as #162.
starred = "Neu:\n* Zehn Sprachen\n* Absturz behoben"
assert_equal("Neu:\n• Zehn Sprachen\n• Absturz behoben", parse(starred, 'de-DE'),
             "asterisk bullets are normalised, not deleted")

dashed = "Neu:\n- Zehn Sprachen\n- Absturz behoben"
assert_equal("Neu:\n• Zehn Sprachen\n• Absturz behoben", parse(dashed, 'de-DE'),
             "dash bullets are normalised too")

dotted = "Neu:\n• Zehn Sprachen\n• Absturz behoben"
assert_equal(dotted, parse(dotted, 'de-DE'),
             "the requested bullet character is left alone")

# A hyphen that is not a bullet has no space after it and must survive: a
# score line reading "-5 Punkte" is prose, not a list item.
assert_equal("Abzug: -5 Punkte.", parse("Abzug: -5 Punkte.", 'de-DE'),
             "a hyphen without a following space is not a bullet")

# The product name is not a word to be translated. zh-Hans came back calling
# the game 《叶块消消乐》 -- a name it is not published under, and one whose
# 消消乐 announces a match-3 game this is not -- while ko transliterated it to
# 리브즈 오브 블록스. A player searching the store for what the notes call the
# game would not find it.
name_prompt = AIHelper.send(:build_prose_prompt, "### Added\n- A thing", '2.1.0', 'zh-Hans')
assert_equal(true, name_prompt.include?('never translated'),
             "the prompt keeps the product name in English")

# Four listings described the escape-sequence fix by printing the escape
# sequence. "\n" is a thing a developer reads, not a thing a player does.
assert_equal(true, name_prompt.include?('escape sequence'),
             "the prompt asks for the player's terms, not the code's")

# The prompt is what asks for the format, so it is asserted here rather than
# left to whoever next reads the file.
prompt = AIHelper.send(:build_prose_prompt, "### Added\n- A thing", '2.1.0', 'de-DE')
assert_equal(true, prompt.include?('•'), "the prompt pins the bullet character")
assert_equal(false, prompt.include?('Do NOT use bullet points'),
             "the prompt no longer forbids the format it now asks for")

puts
puts "payload handling, continued"

# The blocks a response actually carries, when none of them is text.
assert_equal(nil,
             AIHelper.send(:parse_prose_response,
                           { 'content' => [{ 'type' => 'thinking', 'thinking' => 'only this' }] }, nil),
             "a payload with no text block yields nil")

puts
if $fail.zero?
  puts "All #{$pass} checks passed."
  exit 0
end
puts "#{$fail} failed, #{$pass} passed."
exit 1
