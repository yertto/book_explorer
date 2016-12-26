#!/usr/bin/env ruby
require 'mechanize'
require './models'

class SpydusScraper
  PREMIERS_READING_CHALLENGE_LIST="https://boroondara.spydus.com/cgi-bin/spydus.exe/ENQ/OPAC/ALLENQ?ENTRY=premiers+reading+challenge&ENTRY_NAME=BS&ENTRY_TYPE=K&SEARCH_FORM=%2Fcgi-bin%2Fspydus.exe%2FMSGTRN%2FOPAC%2FBSEARCH_ALL%3FHOMEPRMS%3DALLPARAMS&ISGLB=0&GQ=premiers+reading+challenge"

  def agent
    @agent ||= Mechanize.new #(follow_meta_refresh: true)
  end

  def list_url
    @list_url ||= ENV['HOME_URL'] || PREMIERS_READING_CHALLENGE_LIST
  end

  def list
    @list ||= agent.get(list_url)
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

  def book_attributes_from(link)
    book_page = link.click
    book_attributes = book_page.search('//span[@class="bold"]').inject({}) { |h, row|
      key = snake_sym(row.parent.parent.elements[0].text[/(.*): /, 1])
      value = row.parent.parent.elements[2]
      value = value.elements.size > 1 ?
        value.elements.map(&:text).select { |v| v.size > 0 } :
        value.text.strip
      puts "#{value.size} #{key.inspect}" if value.size > 49
      h.update(key => value)
    }

    book_attributes[:img_url] = book_page.image_with(src: /mc.gif/).src

    book_attributes[:isbn] = [book_attributes[:isbn]].flatten.first&.split&.first ||
      book_attributes[:img_url][/isbn=([^\/]+)/, 1]

    # book_attributes = book_attributes.select { |k, v| Book.properties.map(&:name).include?(k) }

    book_attributes
  end


  def first_or_create_book(link, isbn = nil)
    return if isbn && Book.first(isbn: isbn)

    book_attributes = book_attributes_from(link)
    Book.first_or_create(
      { isbn: book_attributes[:isbn] },
      book_attributes
    )
  end

  def scrape(page)
    begin
      page.links_with(href: %r{/FULL/OPAC/ALLENQ/}).each do |link|
        # isbn = link.href[/isbn=\((\d+)\)/, 1]
        # book = first_or_create_book(link, isbn)
        book = first_or_create_book(link)
        book.save!
        puts "#{book.isbn} : #{book.main_title}"
      end
    end while (next_page = page.link_with(text: 'Next')) && page = next_page.click
  end

  def call
    scrape(list)
  end
end

SpydusScraper.new.call
