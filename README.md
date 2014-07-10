# Utusemi

[![Build Status](https://secure.travis-ci.org/hyoshida/utusemi.png)](http://travis-ci.org/hyoshida/utusemi)
[![Code Climate](https://codeclimate.com/github/hyoshida/utusemi.png)](https://codeclimate.com/github/hyoshida/utusemi)
[![Coverage Status](https://coveralls.io/repos/hyoshida/utusemi/badge.png)](https://coveralls.io/r/hyoshida/utusemi)
[![Dependency Status](https://gemnasium.com/hyoshida/utusemi.svg)](https://gemnasium.com/hyoshida/utusemi)

Providing a flexible alias for column names in ActiveRecord.


## Installation

1. Add utusemi in the `Gemfile`:

  ```ruby
  gem 'utusemi'
  ```

2. Download and install by running:

  ```bash
  bundle install
  ```


## Usage

1. Create a file named `utusemi.rb` in `config/initializers` and add column names in this file.

  ```ruby
  Utusemi.configure do
    map :sample do
      name :first_name
    end
  end
  ```

2. Use `utusemi` method.

  ```ruby
  irb> User.utusemi(:sample).where(name: 'John')
  SELECT "users".* FROM "users" WHERE "users"."first_name" = 'John'
  ```


## Requirements

* Ruby on Rails 3.2, 4.1
* Ruby 2.1


## Development

To set up a development environment, simply do:

```bash
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake  # run the test suite
```
