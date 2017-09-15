#!/usr/bin/env ruby
require './spydus_scraper'

require 'ostruct'
card = OpenStruct.new(
  host: ENV.fetch('CARD_HOST'),
  number: ENV.fetch('CARD_NUMBER'),
  pin: ENV.fetch('CARD_PIN')
)

SpydusScraper.new(card).call
