#!/usr/bin/env ruby
require 'mechanize'
require './models'

class SpydusScraper
  HOME_URL_PAT="https://%s/cgi-bin/spydus.exe/MSGTRN/OPAC/HOME"
  ONE_DAY = 60*60*24

  attr_reader :card

  def initialize(card)
    @card = card
  end

  def agent
    @agent ||= Mechanize.new #(follow_meta_refresh: true)
  end

  def home_url
    @home_url ||= HOME_URL_PAT % card.host
  end

  def login_form
    @login_form = agent.get(home_url).form.tap { |f|
      f.BRWLID = card.number
      f.BRWLPWD = card.pin
    }
  end

  def home
    @home ||= login_form.submit.meta_refresh.first.click
  end

  def my_account
    @my_account ||= home.link_with(text: "My Account").click.meta_refresh.first.click
  end

  def previous_loans
    @previous_loans ||= my_account.link_with(text: 'Previous loans').click
  end

  def current_loans
    @current_loans ||= my_account.link_with(text: 'Current loans').click
  end

  def snake_sym(value)
    value
      .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      .gsub(/([a-z\d])([A-Z])/,'\1_\2')
      .tr("-'()/,", '_')
      .gsub(/\s/, '_')
      .gsub(/__+/, '_')
      .downcase
      .to_sym
  end

  def book_attributes_from(link, irn)
    book_page = link.click
    book_attributes = book_page.search('//span[@class="bold"]').inject({}) { |h, row|
      key = snake_sym(row.parent.parent.elements[0].text[/(.*): /, 1])
      value = row.parent.parent.elements[2]
      value = value.elements.size > 1 ? value.elements.map(&:text).select { |v| v.size > 0 }: value.text
      h.update(key => value)
    }

    if (img = book_page.image_with(src: /mc.gif/))
      book_attributes[:img_url] = img.src
    end

    book_attributes[:irn] = irn

    book_attributes
  end

  def first_or_create_book(link, irn = nil)
    book_attributes = book_attributes_from(link, irn)
    p book_attributes if ENV['DEBUG']
    Book.first_or_new(
      { irn: book_attributes[:irn] },
      book_attributes
    )
  end

  def scrape(page)
    begin
#      page.links_with(href: %r{/FULL/OPAC/ALLENQ/}).each do |link|
      page.links_with(href: /.*IRN\(\d+\).*/).each do |link|
        irn = link.href[/IRN\((\d+)\)/, 1]
        book = first_or_create_book(link, irn)
        if book.skip?
          print "\e[33m[skip] "
        else
          print "\e[32m" if book.new?
          book.set_prc_year_levels
          yield book, link if block_given?
          print "#{book.save ? "✔" : "✕"} "
        end
        puts book
        print "\e[m"
      end
    end while (next_page = page.link_with(text: 'Next')) && page = next_page.click
  end

  def do_scrape
    scrape(current_loans)
    scrape(previous_loans) do |book, link|
      issued, returned = link.node.parent.parent.children[3..4].map(&:text)
      book.loans.first_or_new(issued: issued, returned: returned)
    end
  end

  def call
    last_scraped_at = Scrape.last&.created_at
    if last_scraped_at.nil? || last_scraped_at < (DateTime.now - ONE_DAY)
      puts "Scraping...  (Last scraped at: #{last_scraped_at})"
      do_scrape
      Scrape.create
    else
      puts "Skipping scrape.  (Last scraped at: #{last_scraped_at})"
    end
  end
end

if __FILE__ == $0
  require 'ostruct'
  card = OpenStruct.new(
    host: ENV.fetch('CARD_HOST'),
    number: ENV.fetch('CARD_NUMBER'),
    pin: ENV.fetch('CARD_PIN')
  )

  SpydusScraper.new(card).call
end
