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

def parse(text, locale = nil)
  AIHelper.send(:parse_prose_response, { 'content' => [{ 'text' => text }] }, locale)
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

puts
if $fail.zero?
  puts "All #{$pass} checks passed."
  exit 0
end
puts "#{$fail} failed, #{$pass} passed."
exit 1
