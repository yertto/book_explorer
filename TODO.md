TODO
---
- [x] graph /books/loans
- [x] drop /books namespace (to save some real estate on mobile)
- [x] add a dropdown to /books/:associations (see http://slimselectjs.com)
- [x] calendar heatmap (http://cal-heatmap.com or https://github.com/DKirwan/calendar-heatmap)
  - [x] loans - borrows & returns
  - [ ] reads
  - [ ] prc reads
  - [ ] zoom in/out month
  - [ ] orientation/rotation
  - [ ] onMinDomainReached(reached)
- [ ] tricky words index/glossary
- [ ] record books read (ie. digitize paper logs)
  - [ ] zoom out to calendar heatmap
  - [ ] links between books <->  tricky words
  - [ ] pop up for tricky word definitions
- [ ] button to trigger scans
- [ ] BUGFIX: books dissappearing from current_loans scan
   -> use a transaction?
   -> collect all new books before deleting everything?
- [ ] OPTIMIZE: cache index.css
   -> split it off?
- [ ] OPTIMIZE: package js & css
- [ ] OPTIMIZE: for ipad
   -> slightly smaller tiles
- [x] moar indexes
      ** dewey_class (eg. [E])
      ** audience (eg. For children)
      ** series_title (eg. ["Victorian Premier's Reading Challenge"])
      ** awards (eg. "Caldecott Medal 2013.")
      * edition
      * imprint (eg. Fitzroy, Vic. : Black Dog Books, 2007.)
      * collation (eg. 34 unnumbered pages : colour illustrations ; 21 x 27 cm)
        * parse collation
      * notes (eg. Cover title.)
      * word cloud on description
      * lc_class (eg. PZ7.V827)
      * language
- [x] rename books_saved to saved
- [ ] cache scraped pages while developing
- [ ] save raw_html for book#authors book#main_title (to mine that tricky stuff later)
- [ ] authors
  - [ ] parse (first_name, last_name)
  - [ ] consolidate duplicates
      * perhaps use `Author#aliases` ?
        (see https://wml.spydus.com/cgi-bin/spydus.exe/ENQ/OPAC/BIBENQ/24457500?AUH_TYPE=B&AUH_NS=1&AUH=MORGAN%20SALLY)
  - [ ] parse author & illustrator separately
  - [ ] flag authors_books as author and/or illustrator
      * Main Title: Ordinary Albert / story Nancy Antle ; pictures Pamela Allen.
      * Author: Antle, Nancy Allen, Pamela
      * Main Title: Little Mouse''s big secret / by Eric Battut.
      * Main Title: A splash of red : the life and art of Horace Pippin / written by Jen Bryant ; illustrated by Melissa Sweet.
      * Author: Bryant, Jennifer Sweet, Melissa, 1956-, illustrator
      * Main Title: Counting on Frank / written and illustrated by Rod Clement.
      * Main Title: Chooks in space / written by Chris Collin ; illustrated by Megan Kitchin.
      * Author: Collin, Chris E., author Kitchin, Megan, illustrator
      * Author: Chin, Jason, 1978-, author, illustrator
      * Author: Badescu, Ramona Durand, Delphine, ill
- [ ] search library for books by same author
      * add to saved list
- [ ] also scrape "Tags" and "Similar Searches" when scraping book
- [ ] also scrape "Similar Titles" and "People Who Borrowed this Also Borrowed" and "Titles in this Series"
- [ ] scrape PRC - https://wml.spydus.com/cgi-bin/spydus.exe/ENQ/OPAC/BIBENQ/24457798?NRECS=10&QRY=SER%3A%20%27.%20VICTORIAN%20PREMIERS%20READING%20CHALLENGE%20.%27&SQL=&QRYTEXT=Series%3A%20Victorian%20Premier%27s%20Reading%20Challenge
- [ ] remove from saved list
- [ ] add authentication for read-write access
- [ ] investigate other menus
      * https://www.w3schools.com/howto/howto_js_sidenav.asp#
      * https://1stwebdesigner.com/jquery-menu/
- [ ] abort scraping previous loans
- [ ] de-obtrusify loan due warnings
- [ ] *much* smaller book_short view
- [ ] BUG: dropdown brings up keyboard on mobile
- [ ] BUG: dont skip "Picturebooks" because they have a CD (ie. Subject: talking book)
- [ ] rename prc_year_levels to prc
- [ ] collapseable breadcrumbs (eg. "a..> Willems, Mo")
- [ ] saved list availabilites json
      * display
- [ ] star ratings
- [ ] add alpha index ui to /books/authors & /books/
      * or tabulate /books/authors (eg. http://tablesorter.com/docs/)
      * and tabulate /books (add *moar* fields make sortable, filterable)
- [ ] smaller font for loans
- [ ] put assets on CDN
- [ ] directory structure for subjects
- [ ] dont load jqcloud on *every* page
- [ ] use better stemmer (eg. https://github.com/aurelian/ruby-stemmer)
      * heroku postgres extenstion
      (see https://devcenter.heroku.com/articles/heroku-postgres-extensions-postgis-full-text-search#full-text-search-dictionaries)
- [ ] use nlp libraries (see https://github.com/diasks2/ruby-nlp)
- [ ] use a heroku (free) search plugin
      * https://elements.heroku.com/addons/swiftype
      * https://elements.heroku.com/addons/constructor-io
      * https://elements.heroku.com/addons/bonsai
      * https://elements.heroku.com/addons/algoliasearch
      * https://elements.heroku.com/addons/searchbox
- [ ] use a heroku (free) redis plugin
- [ ] fragment caching
- [ ] single page app?
- [ ] show "New DVDs" and allow saving
