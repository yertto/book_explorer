require 'data_mapper'

DataMapper::Logger.new(STDOUT, :debug) if ENV['DEBUG']

# DataMapper.setup(:default, ENV.fetch('DATABASE_URL', 'sqlite:db.sqlite'))
DataMapper.setup(:default, ENV.fetch('JAWSDB_URL', 'sqlite:db.sqlite'))

class PremiersReadingChallengeList

  class << self
    include Enumerable
    extend Forwardable

    def [](isbn)
      items[isbn.gsub(/-/, '')]
    end

    def items
      @items ||= begin
        CSV.foreach("premiers_reading_challenge-2017.tsv", col_sep: "\t", headers: true).inject({}) do |items, row|
          if (isbn = row["ISBN"])
            items[isbn.gsub(/-/, '')] = {
              author: row["Author"],
              title: row["Book Title"],
              isbn: isbn,
              year_levels: row["Year Level"]
            }
          end
          items
        end
      end
    end
  end
end

class Scrape
  include DataMapper::Resource

  property :id, Serial
  timestamps :created_at
end

class SkippedIsbn
  include DataMapper::Resource

  property :id    , Serial
  property :value , String , unique_index: true

  timestamps :at

  class << self
    def seed
      (ENV['SKIPPED_ISBN'] || "").split(",").each do |value|
        first_or_create(value: value)
        print 'i'
      end
      puts
    end
  end
end

class Book
  include DataMapper::Resource

  has n, :authors  , through: Resource
  has n, :subjects , through: Resource

  has n, :prc_year_levels , through: Resource
  has n, :current_loans
  has n, :loans

  property :id                  , Serial
  property :isbn                , String , unique_index: true

  property :img_url             , String , length: 255

  property :main_title          , String , length: 255

  property :irn                 , String

  property :edition             , String
  property :imprint             , String , length: 255
  property :collation           , String , length: 255
  property :variant_title       , String , length: 255
  property :notes               , String , length: 255
  property :contents            , Text
  property :credits             , String , length: 255
  property :performers          , String , length: 255
  property :access_restrictions , String , length: 255
  property :linking_notes       , String , length: 255
  property :audience            , String , length: 255
  property :restrictions_on_use , String , length: 255
  property :system_details      , String , length: 255
  property :summary             , Text
  property :series_title        , String , length: 255
  property :series              , String , length: 255
  property :awards              , String , length: 255
  property :dewey_class         , String
  property :lc_class            , String
  property :language            , String
  property :added_title         , String , length: 255
  property :subject             , String , length: 255
  property :other_names         , String , length: 255
  property :index_terms         , String , length: 255
  property :average_rating      , String
  property :brn                 , String
  property :bookmark_link       , String , length: 255
  property :more_information    , String , length: 255
  property :other_editions      , String , length: 255
  property :similar_titles      , String , length: 255
  property :citations           , String , length: 255
  property :biography_history   , String , length: 255
  property :related_title       , String , length: 255
  property :list_saved          , Boolean

  timestamps :at

  # TODO: get these hooks working
  # before :save, :set_prc_year_levels
  # before :initialize, :fix_isbn

  class << self
    def not_skipped
      all(:isbn.not => SkippedIsbn.all.map(&:value))
    end
  end

  def set_prc_year_levels
    if (prc_entry = PremiersReadingChallengeList[self.isbn])
      if (year_levels = prc_entry[:year_levels])
        self.prc_year_levels = year_levels.split(", ").map do |v|
          PrcYearLevel.first_or_create({ value: v })
        end
      end
    end
  end

  def main_title=(values)
    super values.first
  end

  def author=(values)
    self.authors = values.map { |v| Author.first_or_create({ value: v }) }
  end

  def subject=(values)
    self.subjects = values.map { |v| Subject.first_or_create({ value: v }) }
  end

  def bookmark_link=(value)
    super(value.join)
  end

  def fix_isbn
    @isbn = img_url[/isbn=([^\/]+)/, 1] if img_url
  end

  def isbn
    fix_isbn
    super
  end

  def video_recording?
    main_title.end_with?("[video recording]") ||
      main_title.end_with?("[videodis]") ||
      collation =~ /video/
  end

  def sound_recording?
    main_title.end_with?("[sound recording]") ||
      collation =~ /audio/
  end

  def skip?
    video_recording? ||
      sound_recording? ||
      isbn.nil? ||
      SkippedIsbn.first(value: isbn)
  end

  def to_s
    "#{isbn} : #{main_title}#{loans.empty? ? "" : " (loans: #{loans.count})"}#{list_saved? ? " [S]" : ""}#{"[L]" unless current_loans.empty?}"
  end
end

class Author
  include DataMapper::Resource

  property :id         , Serial
  property :value , String , length: 255, key: true , unique: true

  has n, :books, through: Resource

  timestamps :at

  alias :to_s :value

  def <=>(other)
    value <=> other.value
  end
end

class Subject
  include DataMapper::Resource

  property :id         , Serial
  property :value      , String , length: 255, key: true , unique: true

  timestamps :at

  has n, :books, through: Resource

  alias :to_s :value

  def <=>(other)
    value <=> other.value
  end
end

class PrcYearLevel
  include DataMapper::Resource

  property :id    , Serial
  property :value , String , length: 255, key: true , unique: true

  has n, :books, through: Resource

  timestamps :at

  alias :to_s :value

  def <=>(other)
    value <=> other.value
  end
end

class Loan
  include DataMapper::Resource

  belongs_to :book

  property :id , Serial

  property :issued   , Date   , key: true , required: false
  property :returned , Date   , key: true , required: false

  timestamps :at
end

class CurrentLoan
  include DataMapper::Resource

  belongs_to :book

  property :id , Serial

  property :due    , Date   , key: true , required: false
  property :status , String , key: true , required: false

  timestamps :at
end


# Blow everything away while developing ...
# DataMapper.finalize.auto_migrate!
DataMapper.finalize.auto_upgrade!
