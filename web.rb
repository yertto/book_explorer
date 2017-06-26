#!/usr/bin/env ruby
require 'sinatra'
require 'sass'

require './models'

MIN_BOOKS_WITH_AUTHOR = 2
MIN_BOOKS_WITH_SUBJECT = 2
MIN_BOOKS_WITH_WORD = 2


get '/' do
  redirect to('/books')
end

get '/books' do
  slim :books, locals: { books: books, count: books.count }
end

get '/books/authors' do
  slim :authors
end

get '/books/subjects' do
  slim :subjects
end

get '/books/prc_year_levels' do
  slim :prc_year_levels
end

get '/books/loans' do
  slim :loans
end

get '/books/words' do
  slim :words
end

get '/books/:association/:value' do |association, value|
  books = books(association => value)
  slim :books, locals: {
    association: association,
    value: value,
    count: books.count,
    books: books
  }
end

get '/books/:id' do |id|
  slim :book, locals: { book: Book.get(id) }
end

post '/skip_isbn' do
  isbn = params[:isbn]
  # TODO: simpler way?
  if (skipped_isbn = SkippedIsbn.first(value: isbn))
    skipped_isbn.destroy!
  else
    SkippedIsbn.create(value: isbn)
    Book.first(isbn: isbn).destroy
  end
  redirect to('/books')
end

get '/index.css' do
  # cache_control :public, max_age: 600
  sass :style
end


def my_books
  # TODO - scope books to some kind of user
  Book.not_skipped
end

def books(opts = {})
  if opts.empty?
    my_books.all(:isbn.not => nil, :order => :main_title)
#      .preload(my_books.authors, my_books.subjects)
  else
    association, value = *opts.flatten
    case association.to_s
    when 'words'
      current_books_by_word(value)
    when 'loans'
      current_books_by_loan_issued(value)
    else
      if (parent = my_books.send(association).first(value: value))
        parent.books(order: :main_title)
      else
        []
      end
    end
  end
end

def current_books_by_word(value)
  ['%% %s', '%s %%', "%%%s'%%", "%% %s'%%", "%s, %%", "%% %s,%%", "%% %s!%%"]
    .inject(my_books.all(:main_title.like => '%% %s %%' % value, order: :main_title)) { |collection, pat|
      collection | my_books.all(:main_title.like => pat % value, order: :main_title)
    }
end

def current_books_by_loan_issued(value)
  my_books.loans(issued: value).map(&:book).sort_by(&:main_title)
end

def get_isbn(book)
  (book.img_url || '')[/isbn=([^\/]+)/, 1]
end

def author_path(author)
  "/author/#{author}"
end

def subject_path(subject)
  "/subject/#{subject}"
end

def img_url(isbn)
  "https://secure.syndetics.com/index.aspx?isbn=#{isbn}/sc.gif"
end

def author_book_counts
  @author_book_counts ||= my_books.authors.all(order: :value) #    .preload(my_books)
    .inject({}) { |h, author|
      if ENV['USING_SQLITE']
        count = 1
      else
        count = author.author_books.size
      end
      h.update(author => count)
    }
    .reject { |k, v| v < MIN_BOOKS_WITH_AUTHOR }
    .sort_by { |k, v| [0 - v, k] }
    .to_h
end

def subject_book_counts
  @subject_book_counts ||= my_books.subjects.all(order: :value) #    .preload(Subject.book_subjects)
    .inject({}) { |h, subject|
      # h.update(subject => subject.book_subjects.size)
      h.update(subject => subject.books.size)
    }
    .reject { |k, v| v < MIN_BOOKS_WITH_SUBJECT }
    .sort_by { |k, v| [0 - v, k] }
    .to_h
end

def prc_year_level_book_counts
  @prc_year_level_book_counts ||= my_books.prc_year_levels.all(order: :value)
    .inject({}) { |h, prc_year_level|
      # h.update(prc_year_level => prc_year_level.book_prc_year_levels.size)
      h.update(prc_year_level => prc_year_level.books.size)
    }
    .sort_by { |k, v| [0 - v, k] }
    .to_h
end

def loan_book_counts
  @loan_book_counts ||= my_books.loans.all(order: :issued)
    .inject({}) { |h, loan|
      h[loan.issued] ||= 0
      h[loan.issued] += 1
      h
    }
    .to_h
end

def normalize_word(raw_word)
  raw_word.tr("'!", '').downcase
end

def word_book_counts
  @word_book_counts ||= (my_books.all(:isbn.not => nil) - my_books.all(:main_title.like => '%[sound recording]'))
   .map(&:main_title).inject(Hash.new(0)) { |h, title|
      title.split.map { |raw_word| normalize_word(raw_word) }.uniq.each { |normalized_word| h[normalized_word] += 1 }
      h
    }
    .reject { |k, v| v < MIN_BOOKS_WITH_WORD || %w{the a and to}.include?(k) }
    .sort_by { |k, v| [0 - v, k]}
    .to_h
end

def subject_count
  @subject_count ||= Subject.count
end


__END__


@@ style
$border-color: #e9ecef

$book-details-paragraph-font-color: #7e8f9d
$book-details-lite-font-color: #cdcdcd
$book-details-author-font-color: #989898

@mixin tag
  background-color: $border-color
  color: inherit
  display: inline-block
  font-size: .9em
  margin: 4px
  padding: 4px 8px
  text-decoration: none

  &:hover
    background-color: darken($border-color, 5%)

html,
body
  margin: 0
  padding: 0

html
  -moz-osx-font-smoothing: grayscale
  -webkit-font-smoothing: antialiased
  -webkit-tap-highlight-color: transparent
  box-sizing: border-box
  text-size-adjust: 100%

*, *:before, *:after
  box-sizing: inherit

body
  background-color: #f2f5f7
  color: #434f59
  font-family: Helvetica, Arial, sans-serif

.page-header
  background-color: #fff
  height: 50px
  overflow: hidden
  padding: 0 15px

  h1
    display: inline-block
    font: 600 1.5em Quicksand, sans-serif
    margin: 0
    height: 100%
    vertical-align: middle

    &::before
      content: ''
      height: 100%
      display: inline-block
      vertical-align: middle

  @media (max-width: 599px)
    height: 50px

.books
  margin: 0
  padding: 7px
  list-style: none

  @media (min-width: 600px)
    display: flex
    flex-wrap: wrap
    width: 100%

  > li
    display: block
    margin: 7px

    @media (min-width: 600px)
      flex: 1 50%
      max-width: 420px

.book
  background-color: #fff
  border-radius: 4px
  border: 1px solid $border-color
  display: block
  margin: 0
  overflow: hidden

  @media (max-width: 599px)
    text-align: center

  &::after
    clear: both
    content: ''
    display: table

  @media (min-width: 900px)
    width: 100%

.book-cover,
.book-details
  display: block
  width: 100%
  padding: 15px

  @media (min-width: 600px)
    float: left

.book-cover
  width: 100%

  @media (max-width: 599px)
    background-color: #1f2930

  @media (min-width: 600px)
    width: 31.12%

  img
    box-shadow: 0 0 15px #000
    width: 100%

    @media (max-width: 599px)
      max-width: 120px

    @media (min-width: 600px)
      box-shadow: 0 0 8px rgba(0,0,0,.25)

.book-details
  @media (min-width: 600px)
    width: 68.88%

  p
    color: $book-details-paragraph-font-color


.book__title,
.book__author
  @media (max-width: 599px)
    text-align: center

.book__title
  font: 500 1.4em Quicksand, sans-serif
  margin-bottom: 0
  margin-top: 0

  @media (min-width: 600px)
    margin-top: .5em

  a
    color: inherit
    text-decoration: none

.book__author
  color: $book-details-author-font-color
  margin-top: .5em

  [rel="author"]
    color: inherit

.book__subjects
  margin-top: 20px
  font-size: 14px

.subject__title
  display: block

.subject__list
  padding-left: 1.2em

  @media (max-width: 599px)
    margin: 0
    padding: 0
    list-style: none

    > li
      display: inline-block

  [rel="tag"]
    @media (max-width: 599px)
      @include tag

.book__prc_year_levels,
.book__tags,
.book__loans
  border-top: 1px solid $border-color
  clear: both
  padding: 8px 15px
  width: 100%

  [rel="tag"]
    @include tag

  .title
    display: block
    font-size: 13px

.subject__tag
  display: inline-block

@@ _book
.book(itemscope itemtype="http://schema.org/Book")
  .book-cover
    a href="/books/#{book.id}" title=book.main_title
      img src=img_url(get_isbn(book)) alt=book.main_title
    - if !book.prc_year_levels.empty?
      a href="/books/prc_year_levels"
        img src="http://www.malvernps.vic.edu.au/wp-content/uploads/prchomepage.gif"
  .book-details
    h2.book__title(itemprop="name")
      = book.main_title
    .book__author(itemprop="author")
      = "by "
      - book.author_books.each do |author_book|
        - author = author_book.author
        - book_count = author_book_counts[author]
        - if book_count && book_count > 1
          a(rel="author" href="/books/authors/#{author}")= "#{author} (#{book_count})"
        - else
          a(rel="author" href="/books/authors/#{author}")= author
        |&nbsp;
  - if !book.prc_year_levels.empty?
    .book__prc_year_levels
      span.title
        = "Premier's Reading Challenge - Year Levels:"
      - book.prc_year_levels.each do |prc_year_level|
        a(rel="tag" href="/books/prc_year_levels/#{prc_year_level}")= prc_year_level
        |&nbsp;
  .book__tags
    span.title
      a(href="/books/words")= "Filter keywords:"
    - book.main_title.split.each do |word|
      a rel="tag" href="/books/words/#{normalize_word(word)}"
        = word
  - if !book.loans.empty?
    .book__loans
      span.title
        a(href="/books/loans")= "Loan(s):"
      ol
        - book.loans(order: :issued).each do |loan|
          li
            a(href="/books/loans/#{loan.issued}")= loan.issued
            small= " (Returned #{loan.returned})"


@@ _books
ul.books
  - books.each do |book|
    li
      == slim :_book, locals: { book: book }


@@ book
h1
  a href="/books" = "/books"
  | /
  = book.main_title
== slim :_book, locals: { book: book }
form action="/skip_isbn" method="POST"
  input type="hidden" name="isbn" value=book.isbn
  input type="submit" value="[#{SkippedIsbn.first(value: book.isbn) ? "unskip" : "skip"}]"
table
  - Book.properties.map(&:name).each do |prop|
    tr
      th= prop
      td= book.send(prop)



@@ books
header#page-header.page-header
  h1
    - if params.empty?
      = "/books"
    - else
      a href="/books" = "/books"
      | /
      a href="/books/#{association}" = association
      | /
      = value
    = " (#{count} books)"
main == slim :_books, locals: { books: books }


@@ _association_header
header#page-header.page-header
  h1
    a href="/books" = "/books"
    | /#{association}


@@ authors
== slim :_association_header, locals: { association: "authors" }
- if ENV['USING_SQLITE']
  - my_books.authors(order: :value).each do |author|
    h2
      a(href="/books/authors/#{author}")= author
    == slim :_books, locals: { books: books(authors: author) }
- else
  - author_book_counts.each do |author, count|
    h2
      a(href="/books/authors/#{author}")= "#{author} (#{count} books)"
    == slim :_books, locals: { books: books(authors: author) }


@@ subjects
== slim :_association_header, locals: { association: "subjects" }
- subject_book_counts.each do |subject, count|
  h2
    a(href="/books/subjects/#{subject}")= "#{subject} (#{count} books)"
  == slim :_books, locals: { books: books(subjects: subject) }


@@ prc_year_levels
== slim :_association_header, locals: { association: "prc_year_levels" }
- prc_year_level_book_counts.each do |prc_year_level, count|
  h2
    a(href="/books/prc_year_levels/#{prc_year_level}")= "#{prc_year_level} (#{count} books)"
  == slim :_books, locals: { books: books(prc_year_levels: prc_year_level) }


@@ loans
== slim :_association_header, locals: { association: "loans" }
- loan_book_counts.each do |loan_issued, count|
  h2
    a(href="/books/loans/#{loan_issued}")= "#{loan_issued} (#{count} books)"
  == slim :_books, locals: { books: books(loans: { issued: loan_issued }) }


@@ words
== slim :_association_header, locals: { association: "words" }
- word_book_counts.each do |word, count|
  h2
    a(href="/books/words/#{word}")= "#{word} (#{count} books)"
  == slim :_books, locals: { books: current_books_by_word(word) }


@@ _header


@@ _footer
footer
  small
    - if (git_sha = ENV['SOURCE_VERSION'] || `git describe --always --tags`)
      | github://
      a href="https://github.com/yertto/bookexplorer/compare/#{git_sha}...master"= git_sha


@@ layout
doctype html
html lang="en"
  head
    title Book Explorer
    meta charset="utf-8"
    meta http-equiv="x-ua-compatible" content="ie=edge"
    meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=0, width=device-width"
    link href="/index.css" rel="stylesheet" type="text/css"
    link href="https://fonts.googleapis.com/css?family=Quicksand:500" rel="stylesheet"
    script src="http://www.archive.org/includes/jquery-1.6.1.min.js"
  body
    == slim :_header
    == yield
    == slim :_footer
