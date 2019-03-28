source 'http://rubygems.org'
ruby '2.3.8'

# db gems
gem 'data_mapper'

# scraper gems
gem 'mechanize'

# web gems
gem 'sinatra'
gem 'slim'
gem 'sass'

# word processing
gem 'uea-stemmer'
gem 'stopwords-filter', require: 'stopwords'

# monitoring gems
gem 'newrelic_rpm'

group :production do
#  gem 'dm-postgres-adapter'
  gem 'dm-mysql-adapter' # We get more db space on the free heroku plan by using sharkdb instead of postgres
end

group :development, :test do
  gem 'dm-sqlite-adapter'
  gem 'shotgun'
  gem 'pry'
  gem 'terminal-table'
  gem 'watir'
end
