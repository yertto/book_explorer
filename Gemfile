source 'http://rubygems.org'
ruby '2.3.1'

# db gems
gem 'data_mapper'

# scraper gems
gem 'mechanize'

# web gems
gem 'sinatra'
gem 'slim'
gem 'sass'

# monitoring gems
gem 'newrelic_rpm'

group :production do
  gem 'dm-postgres-adapter'
end

group :development, :test do
  gem 'dm-sqlite-adapter'
  gem 'shotgun'
  gem 'pry'
  gem 'terminal-table'
end
