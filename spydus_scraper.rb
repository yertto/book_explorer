require 'mechanize'
require './models'

class SpydusScraper
  HOME_URL_PAT="https://wml.spydus.com/cgi-bin/spydus.exe/MSGTRN/WPAC/LOGINB"
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
    @login_form = agent.get(home_url).form_with(id: 'frmLogin').tap { |f|
      f.BRWLID = card.number
      f.BRWLPWD = card.pin
    }
  end

  def home
    @home ||= login_form.submit.meta_refresh.first.click
  end

  def my_savedlist
    @my_savedlist ||= home.link_with(text: "View all savedlists").click
  end

  def history
    @history ||= home.link_with(text: 'History').click
  end

  def previous_loans
    @previous_loans ||= history.link_with(text: /Previous loans/).click
  end

  def current_loans
    @current_loans ||= home.link_with(text: 'Current loans').click
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
    book_page_full = book_page.link_with(text: link.text).click
    book_attributes = book_page_full.search('//div[@class="col-sm-3 col-md-3 fd-caption"]').inject({}) { |h, row|
      key = snake_sym(row.parent.elements[0].text[/(.*): /, 1])
      value = row.next
      value = value.elements.size > 1 ? value.elements.map(&:text).select { |v| v.size > 0 }: value.text
      h.update(key => value)
    }

    if (img = book_page.image_with(src: /mc.gif/))
      book_attributes[:img_url] = img.src
    end

    # TODO - test this works
    book_attributes[:list_saved] = !book_page.search('//a[@title="Remove this item from your current list"]/i[@class="fa fa-bookmark-o"]')
    book_attributes[:irn] = irn
    book_attributes
  end

  def first_or_create_book(link, irn = nil)
    book_attributes = book_attributes_from(link, irn)
    p book_attributes if ENV['DEBUG']
    Book.first_or_new(
      { irn: book_attributes[:irn] },
      book_attributes
    ).tap { |book|
      book[:list_saved] = book_attributes[:list_saved]
    }
  end

  def scrape(page)
    begin
      page.links_with(href: /.*IRN\(\d+\)&NAVLVL=SET/).each do |link|
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
    rescue => error
      p error
    end while (next_page = page.link_with(text: 'Next')) && page = next_page.click
  end

  def do_scrape
    CurrentLoan.destroy
    scrape(current_loans) do |book, link|
      due, status = link.node.parent.parent.parent.parent.children[-3..-2].map(&:text)
      book.current_loans.first_or_new(due: due, status: status)
    end

    scrape(previous_loans) do |book, link|
      issued, returned = link.node.parent.parent.parent.children[3..4].map(&:text)
      book.loans.first_or_new(issued: issued, returned: returned)
    end
  end

  def scrape_loans
    last_scraped_at = Scrape.last&.created_at
    # last_scraped_threshold = DateTime.now - ONE_DAY # ??? why no worky?
    last_scraped_threshold = Date.parse((Time.now - ONE_DAY).to_s)
    if last_scraped_at.nil? || last_scraped_at < last_scraped_threshold || ENV['FORCE_SCRAPE']
      puts "Scraping...  (Last scraped at: #{last_scraped_at})"
      do_scrape
      Scrape.create
    else
      puts "Skipping scrape.  (Last scraped at: #{last_scraped_at}) (#{last_scraped_threshold})"
    end
  end

  def update_locations_for_title(h, table, title)
    rows = table.xpath('//tr')
    if rows.empty?
      puts "no rows for #{title.inspect}"
      return
    end

    rows[1..-1].each do |row|
      location, collection, call_number, status = row.xpath('td').map(&:text)
      if status == "Available"
        h[location] ||= {}
        h[location][title] = [collection, call_number]
      end
    end
  end

  def update_holdings(h, page)
    page.links_with(text: 'View availability').each do |availability_link|
      title = availability_link.node.parent.parent.parent.parent.children[0].text
      update_locations_for_title(h, availability_link.click, title)
    end
    return

    page.links_with(text: /see full display for details/).each do |holdings_link|
      holdings_page = holdings_link.click
      title = holdings_page.xpath('//table/tr/td[2]/table/tr/td[3]/a').first.text
      table = holdings_page.xpath('//table/tr/th[text()="Location"]/../..').first
      update_locations_for_title(h, table, title)
    end
  end

  def update_locations(h, page)
    page.xpath('//table/tr/th[text()="Location"]/../..').each do |table|
      title = table.xpath('../..//a')[2].text
      update_locations_for_title(h, table, title)
    end
  end

  def location_availabilities
    @location_availabilities ||= begin
      h = {}
      my_savedlist.links_with(xpath: '//td[@data-caption="Description"]/span/a').each do |list|
        page = list.click
        begin
          update_holdings(h, page)
          update_locations(h, page)
        end while (next_page = page.link_with(text: 'Next')) && page = next_page.click
      end
      h
    end
  end

  def call
    scrape_loans
  end
end
