# WIP

## Installing
```
bundle
```

## Seeding
```
bundle exec ./scraper.rb
```

## Running
```
bundle exec shotgun app.rb
```

## Deploying to Heroku
```
heroku create
git push heroku master
heroku open
```

Alternatively, you can deploy your own copy of the app using this button:

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Seeding on heroku
```
heroku run bundle exec ./scraper.rb
```

## Troubleshooting
* While messing round with the schema use:
    `DataMapper.finalize.auto_migrate!`
  instead of
    `DataMapper.finalize.auto_upgrade!`
  to blow the database away completely.
