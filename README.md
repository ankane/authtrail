# AuthTrail

Track Devise login activity

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

[![Build Status](https://github.com/ankane/authtrail/workflows/build/badge.svg?branch=master)](https://github.com/ankane/authtrail/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "authtrail"
```

To encrypt email and IP addresses with Lockbox, install [Lockbox](https://github.com/ankane/lockbox) and [Blind Index](https://github.com/ankane/blind_index) and run:

```sh
rails generate authtrail:install --encryption=lockbox
rails db:migrate
```

To use Active Record encryption (Rails 7+, experimental), run:

```sh
rails generate authtrail:install --encryption=activerecord
rails db:migrate
```

If you prefer not to encrypt data, run:

```sh
rails generate authtrail:install --encryption=none
rails db:migrate
```

To enable geocoding, see the [Geocoding section](#geocoding).

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

AuthTrail uses [Geocoder](https://github.com/alexreisner/geocoder) for geocoding. We recommend configuring [local geocoding](#local-geocoding) or [load balancer geocoding](#load-balancer-geocoding) so IP addresses are not sent to a 3rd party service. If you do use a 3rd party service and adhere to GDPR, be sure to add it to your subprocessor list.

To enable geocoding, add this line to your application’s Gemfile:

```ruby
gem "geocoder"
```

And update `config/initializers/authtrail.rb`:

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
gem "maxminddb"
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

### Load Balancer Geocoding

Some load balancers can add geocoding information to request headers.

- [nginx](https://nginx.org/en/docs/http/ngx_http_geoip_module.html)
- [Google Cloud](https://cloud.google.com/load-balancing/docs/custom-headers)
- [Cloudflare](https://support.cloudflare.com/hc/en-us/articles/200168236-Configuring-Cloudflare-IP-Geolocation)

```ruby
AuthTrail.geocode = false

AuthTrail.transform_method = lambda do |data, request|
  data[:country] = request.headers["<country-header>"]
  data[:region] = request.headers["<region-header>"]
  data[:city] = request.headers["<city-header>"]
end
```

Check out [this example](https://github.com/ankane/authtrail/issues/40)

## Data Retention

Delete older data with:

```ruby
LoginActivity.where("created_at < ?", 2.years.ago).in_batches.delete_all
```

Delete data for a specific user with:

```ruby
LoginActivity.where(user_id: 1, user_type: "User").in_batches.delete_all
```

## Other Notes

We recommend using this in addition to Devise’s `Lockable` module and [Rack::Attack](https://github.com/kickstarter/rack-attack).

Check out [Hardening Devise](https://ankane.org/hardening-devise) and [Secure Rails](https://github.com/ankane/secure_rails) for more best practices.

## Upgrading

### 0.4.0

There are two notable changes to geocoding:

1. Geocoding is now disabled by default (this was already the case for new installations with 0.3.0+). Check out the instructions for [how to enable it](#geocoding) (you may need to create `config/initializers/authtrail.rb`).

2. The `geocoder` gem is now an optional dependency. To use geocoding, add it to your Gemfile:

  ```ruby
  gem "geocoder"
  ```

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
