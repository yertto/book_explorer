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
  slim :books, locals: { books: books }
end

get '/books/authors' do
  slim :authors
end

get '/books/subjects' do
  slim :subjects
end

get '/books/words' do
  slim :words
end

get '/books/:association/:value' do |association, value|
  slim :books, locals: {
    association: association,
    value: value,
    books: books(association => value)
  }
end

get '/books/:id' do |id|
  slim :book, locals: { book: Book.get(id) }
end

get '/index.css' do
  # cache_control :public, max_age: 600
  sass :style
end


def my_books
  # TODO - scope books to some kind of user
  Book.all
end

def books(opts = {})
  if opts.empty?
    my_books.all(:isbn.not => nil, :order => :main_title)
#      .preload(my_books.authors, my_books.subjects)
  else
    association, value = *opts.flatten
    if association == 'words'
      current_books_by_word(value)
    else
      my_books.send(association).first(value: value).books(order: :main_title)
    end
  end
end

def current_books_by_word(value)
  ['%% %s', '%s %%', "%%%s'%%", "%% %s'%%", "%s, %%", "%% %s,%%", "%% %s!%%"]
    .inject(my_books.all(:main_title.like => '%% %s %%' % value, order: :main_title)) { |collection, pat|
      collection | my_books.all(:main_title.like => pat % value, order: :main_title)
    }
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
      h.update(author => author.author_books.size)
    }
    .reject { |k, v| v < MIN_BOOKS_WITH_AUTHOR }
    .sort_by { |k, v| [0 - v, k] }
    .to_h
end

def subject_book_counts
  @subject_book_counts ||= my_books.subjects.all(order: :value) #    .preload(Subject.book_subjects)
    .inject({}) { |h, subject|
      h.update(subject => subject.book_subjects.size)
    }
    .reject { |k, v| v < MIN_BOOKS_WITH_SUBJECT }
    .sort_by { |k, v| [0 - v, k] }
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

html
  box-sizing: border-box

*, *:before, *:after
  box-sizing: inherit

body
  background-color: #f2f5f7
  color: #434f59
  font-family: Helvetica, Arial, sans-serif

.books
  margin: 0
  padding: 0
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

  @media (min-width: 600px)
    width: 31.12%

  img
    box-shadow: 0 0 8px rgba(0,0,0,.25)
    width: 50%

    @media (min-width: 600px)
      width: 100%

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
  font: 500 1.4em 'Quicksand', sans-serif
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

.book__tags
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
  a.book-cover href="/books/#{book.id}" title=book.main_title
    img src=img_url(get_isbn(book)) alt=book.main_title
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
          = author
    .book__subjects
      span.subject__title Subject(s):
      ul.subject__list
        - book.book_subjects.subject.each do |subject|
          - subject_color = "%06x" % (subject.id * (0xffffff / subject_count))
          - subject_count = subject_book_counts[subject]
          li
            a.subject__tag(
              rel="tag"
              href="/books/subjects/#{subject}"
              title=subject
            )
              | #{subject}
              span.counter = "%03s" % subject_count
  .book__tags
    span.title
      = "Filter keywords:"
    - book.main_title.split.each do |word|
      a rel="tag" href="/books/words/#{normalize_word(word)}"
        = word

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
table
  - Book.properties.map(&:name).each do |prop|
    tr
      th= prop
      td= book.send(prop)



@@ books
header#page-title
  h1
    - if params.empty?
      = "/books"
    - else
      a href="/books" = "/books"
      | /
      a href="/books/#{association}" = association
      | /
      = value
main == slim :_books, locals: { books: books }


@@ authors
h1
  a href="/books" = "/books"
  | /authors
- author_book_counts.each do |author, count|
  h2
    a(href="/books/authors/#{author}")= "#{author} (#{count})"
  == slim :_books, locals: { books: books(authors: author) }


@@ subjects
h1
  a href="/books" = "/books"
  | /subjects
- subject_book_counts.each do |subject, count|
  h2
    a(href="/books?subjects=#{subject}")= "#{subject} (#{count})"
  == slim :_books, locals: { books: books(subjects: subject) }


@@ words
h1
  a href="/books" = "/books"
  | /words
  - word_book_counts.each do |word, count|
    h2
      a(href="/books/words/#{word}")= "#{word} (#{count})"
    == slim :_books, locals: { books: current_books_by_word(word) }


@@ _header


@@ _footer
footer


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
