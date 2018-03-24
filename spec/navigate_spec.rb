require 'watir'

browser = Watir::Browser.new :chrome
browser.goto ENV.fetch('HOME_URL', 'http://localhost:9292')

%w(
  saved
  borrows
  returns
  prc_year_levels
  edition
  dewey_class
  series_title
).each do |resource|
  browser.div(text: resource).fire_event :click
end

[
  /Carle, Eric/,
  '1, 2, 3 to the zoo',
  'Title keywords:',
  'zoo',
  /zoo/,
  'Subjects:',
  /Counting/,
  /201\d-\d{2}-\d{2}/
].each do |link_text|
  puts link_text
  p browser.link(text: link_text).click
end
sleep 5
