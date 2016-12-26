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
.class1
  display: inline-table
  height: 100
  margin: 3

.class2
  width: 100
  height: 200
  overflow: auto

.book_title
  background-color: yellowgreen

.book_subjects
  overflow: auto

.book_author
  background-color: lightgrey


@@ _book
figure class="class1"
  a href="/books/#{book.id}"
    img src=img_url(get_isbn(book))
  figcaption(class="class2")
    dl
      dt(class="book_title")
        - book.main_title.split.each do |word|
          a href="/books/words/#{normalize_word(word)}" = word
          = " "
      dt(class="book_subjects")
      - book.book_subjects.subject.each do |subject|
        - subject_color = "%06x" % (subject.id * (0xffffff / subject_count))
        - subject_count = subject_book_counts[subject]
        a(
          href="/books/subjects/#{subject}"
          title=subject
          style="font-size: x-small; background-color: ##{subject_color};"
        )= "%03s" % subject_count
        = " "
      - book.author_books.each do |author_book|
        - author = author_book.author
        dt(class="book_author")
          - book_count = author_book_counts[author]
          - if book_count && book_count > 1
            a(href="/books/authors/#{author}")= "#{author} (#{book_count})"
          - else
            = author

@@ _books
- books.each do |book|
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
h1
  - if params.empty?
    = "/books"
  - else
    a href="/books" = "/books"
    | /
    a href="/books/#{association}" = association
    | /
    = value
== slim :_books, locals: { books: books }


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
html
  head
    link href="/index.css" rel="stylesheet" type="text/css"
    script src="http://www.archive.org/includes/jquery-1.6.1.min.js"
  body
    == slim :_header
    == yield
    == slim :_footer
