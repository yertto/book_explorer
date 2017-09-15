#!/usr/bin/env ruby
require './spydus_scraper'

require 'ostruct'
card = OpenStruct.new(
  host: ENV.fetch('CARD_HOST'),
  number: ENV.fetch('CARD_NUMBER'),
  pin: ENV.fetch('CARD_PIN')
)

def show_availabilites(location_availabilities)
  require 'terminal-table'
  puts Terminal::Table.new(rows: location_availabilities.sort.inject([]) { |a, (location, books)| a << [{value: "\n#{location}", colspan: 3, alignment: :center}]; a += books.to_a.map(&:flatten).map(&:reverse).sort.map { |row| row.map { |cell| cell[0..80]}  }; a })
end

show_availabilites(SpydusScraper.new(card).location_availabilities)
