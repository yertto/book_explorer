require 'watir'

browser = Watir::Browser.new :chrome
browser.goto ENV.fetch('HOME_URL', 'http://localhost:9292')
[
  /Carle, Eric/,
  "1, 2, 3 to the zoo",
  "Title keywords:",
  "zoo",
  /zoo/,
  "Subjects:",
  /Counting/,
  /201\d-\d{2}-\d{2}/,
  "Loan(s):"
].each do |link_text|
  puts link_text
  p browser.link(text: link_text).click
end
sleep 5
