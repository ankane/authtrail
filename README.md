# AuthTrail

Track Devise login activity

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

[![Build Status](https://github.com/ankane/authtrail/workflows/build/badge.svg?branch=master)](https://github.com/ankane/authtrail/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'authtrail'
```

And run:

```sh
rails generate authtrail:install
rails db:migrate
```

## How It Works

A `LoginActivity` record is created every time a user tries to login. You can then use this information to detect suspicious behavior. Data includes:

- `scope` - Devise scope
- `strategy` - Devise strategy
- `identity` - email address
- `success` - whether the login succeeded
- `failure_reason` - if the login failed
- `user` - the user if the login succeeded
- `context` - controller and action
- `ip` - IP address
- `user_agent` and `referrer` - from browser
- `city`, `region`, `country`, `latitude`, and `longitude` - from IP
- `created_at` - time of event

## Features

Exclude certain attempts from tracking - useful if you run acceptance tests

```ruby
AuthTrail.exclude_method = lambda do |data|
  data[:identity] == "capybara@example.org"
end
```

Add or modify data - also add new fields to the `login_activities` table if needed

```ruby
AuthTrail.transform_method = lambda do |data, request|
  data[:request_id] = request.request_id
end
```

Store the user on failed attempts

```ruby
AuthTrail.transform_method = lambda do |data, request|
  data[:user] ||= User.find_by(email: data[:identity])
end
```

Write data somewhere other than the `login_activities` table

```ruby
AuthTrail.track_method = lambda do |data|
  # code
end
```

Use a custom identity method

```ruby
AuthTrail.identity_method = lambda do |request, opts, user|
  if user
    user.email
  else
    request.params.dig(opts[:scope], :email)
  end
end
```

Associate login activity with your user model

```ruby
class User < ApplicationRecord
  has_many :login_activities, as: :user # use :user no matter what your model name
end
```

The `LoginActivity` model uses a [polymorphic association](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations) so it can be associated with different user models.

## Geocoding

AuthTrail uses [Geocoder](https://github.com/alexreisner/geocoder) for geocoding. We recommend configuring [local geocoding](#local-geocoding) so IP addresses are not sent to a 3rd party service. If you do use a 3rd party service and adhere to GDPR, be sure to add it to your subprocessor list.

To enable geocoding, update `config/initializers/authtrail.rb`:

```ruby
AuthTrail.geocode = true
```

Geocoding is performed in a background job so it doesn’t slow down web requests. Set the job queue with:

```ruby
AuthTrail.job_queue = :low_priority
```

### Local Geocoding

For privacy and performance, we recommend geocoding locally. Add this line to your application’s Gemfile:

```ruby
gem 'maxminddb'
```

For city-level geocoding, download the [GeoLite2 City database](https://dev.maxmind.com/geoip/geoip2/geolite2/) and create `config/initializers/geocoder.rb` with:

```ruby
Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: "path/to/GeoLite2-City.mmdb"
  }
)
```

For country-level geocoding, install the `geoip-database` package. It’s preinstalled on Heroku. For Ubuntu, use:

```sh
sudo apt-get install geoip-database
```

And create `config/initializers/geocoder.rb` with:

```ruby
Geocoder.configure(
  ip_lookup: :maxmind_local,
  maxmind_local: {
    file: "/usr/share/GeoIP/GeoIP.dat",
    package: :country
  }
)
```

## Data Protection

Protect the privacy of your users by encrypting fields that contain personal data, such as `identity` and `ip`. [Lockbox](https://github.com/ankane/lockbox) is great for this. Use [Blind Index](https://github.com/ankane/blind_index) so you can still query the fields.

```ruby
class LoginActivity < ApplicationRecord
  encrypts :identity, :ip
  blind_index :identity, :ip
end
```

## Other Notes

We recommend using this in addition to Devise’s `Lockable` module and [Rack::Attack](https://github.com/kickstarter/rack-attack).

Check out [Hardening Devise](https://ankane.org/hardening-devise) and [Secure Rails](https://github.com/ankane/secure_rails) for more best practices.

## Upgrading

### 0.2.0

To store latitude and longitude, create a migration with:

```ruby
add_column :login_activities, :latitude, :float
add_column :login_activities, :longitude, :float
```

## History

View the [changelog](https://github.com/ankane/authtrail/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/authtrail/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/authtrail/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development and testing:

```sh
git clone https://github.com/ankane/authtrail.git
cd authtrail
bundle install
bundle exec rake test
```
