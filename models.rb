require 'data_mapper'

DataMapper::Logger.new(STDOUT, :debug) if ENV['DEBUG']

DataMapper.setup(:default, ENV.fetch('DATABASE_URL', 'sqlite:db.sqlite'))

class Book
  include DataMapper::Resource

  has n, :authors  , through: Resource
  has n, :subjects , through: Resource

  property :id                  , Serial

  property :img_url             , String , length: 255

  property :main_title          , String , length: 255
  property :isbn                , String

  property :edition             , String
  property :imprint             , String , length: 255
  property :collation           , String , length: 255
  property :variant_title       , String , length: 255
  property :notes               , String , length: 255
  property :contents            , Text
  property :credits             , String , length: 255
  property :performers          , String , length: 255
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

  property :created_at          , DateTime
  property :updated_at          , DateTime

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

#  def isbn
#    img_url ? img_url[/isbn=([^\/]+)/, 1] : super
#  end
end

class Author
  include DataMapper::Resource

  property :id         , Serial
  property :value , String , length: 255, key: true

  has n, :books, through: Resource

  property :created_at , DateTime
  property :updated_at , DateTime

  alias :to_s :value

  def <=>(other)
    value <=> other.value
  end
end

class Subject
  include DataMapper::Resource

  property :id         , Serial
  property :value      , String , length: 255, key: true

  property :created_at , DateTime
  property :updated_at , DateTime

  has n, :books, through: Resource

  alias :to_s :value

  def <=>(other)
    value <=> other.value
  end
end


# Blow everything away while developing ...
# DataMapper.finalize.auto_migrate!
DataMapper.finalize.auto_upgrade!
