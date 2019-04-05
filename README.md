# AuthTrail

Track Devise login activity

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

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
- `city`, `region`, and `country` - from IP
- `latitude` and `longitude` - from IP (see "Coordinates" below)
- `created_at` - time of event

## Features

Exclude certain attempts from tracking - useful if you run acceptance tests

```ruby
AuthTrail.exclude_method = lambda do |info|
  info[:identity] == "capybara@example.org"
end
```

Write data somewhere other than the `login_activities` table

```ruby
AuthTrail.track_method = lambda do |info|
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

The `LoginActivity` model uses a [polymorphic association](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations) so it can be associated with different user models.

## Geocoding

IP geocoding is performed in a background job so it doesn’t slow down web requests. You can disable it entirely with:

```ruby
AuthTrail.geocode = false
```

Set job queue for geocoding

```ruby
AuthTrail::GeocodeJob.queue_as :low
```

### Coordinates

If you want to store latitude/longitude coordinates, but you installed version 0.1.3 or before, you need to add coordinates columns to your database. Generate another migration:
```ruby
bundle exec rails g migration AddCoordinatesToLoginActivities latitude:float longitude:float
```

### Geocoding Performance

To avoid calls to a remote API, download the [GeoLite2 City database](https://dev.maxmind.com/geoip/geoip2/geolite2/) and configure Geocoder to use it.

Add this line to your application’s Gemfile:

```ruby
gem 'maxminddb'
```

And create an initializer at `config/initializers/geocoder.rb` with:

```ruby
Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: Rails.root.join("lib", "GeoLite2-City.mmdb")
  }
)
```

## Data Protection

Protect the privacy of your users by encrypting fields that contain personal information, such as `identity` and `ip`. [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) is great for this. Use [blind_index](https://github.com/ankane/blind_index) if you need to query fields.

```ruby
class LoginActivity < ApplicationRecord
  attr_encrypted :identity, key: ...
  attr_encrypted :ip, key: ...

  blind_index :identity, key: ...
  blind_index :ip, key: ...
end
```

You should also make it clear that you collect this information in your privacy policy.

## Other Notes

We recommend using this in addition to Devise’s `Lockable` module and [Rack::Attack](https://github.com/kickstarter/rack-attack).

Check out [Hardening Devise](https://ankane.org/hardening-devise) and [Secure Rails](https://github.com/ankane/secure_rails) for more best practices.

Works with Rails 4.2+

## History

View the [changelog](https://github.com/ankane/authtrail/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/authtrail/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/authtrail/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
