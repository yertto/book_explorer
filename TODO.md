TODO
---
- [x] graph /books/loans
- [x] drop /books namespace (to save some real estate on mobile)
- [x] add a dropdown to /books/:associations (see http://slimselectjs.com)
- [x] calendar heatmap (http://cal-heatmap.com or https://github.com/DKirwan/calendar-heatmap)
  - [x] loans - borrows & returns
  - [ ] reads
  - [ ] prc reads
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
- [ ] record books read (ie. digitize paper logs)
- [ ] rename prc_year_levels to prc
- [ ] collapseable breadcrumbs (eg. "a..> Willems, Mo")
- [ ] saved list availabilites json
      * display
- [ ] authors
      * parse (first_name, last_name)
      * consolidate duplicates
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
