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

Use a custom identity method [master]

```ruby
AuthTrain.identity_method = lambda do |request, opts, user|
  if user
    user.email
  else
    request.params.dig(opts[:scope], :email)
  end
end
```

Associate `LoginActivity` with your user model

```ruby
class Manager < ApplicationRecord
  has_many :login_activities, as: :user
end
```

The `LoginActivity` model uses a [polymorphic](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations) association out of the box, so login activities can belong to different models (User, Admin, Manager, etc).

## Geocoding

IP geocoding is performed in a background job so it doesn’t slow down web requests. You can disable it entirely with:

```ruby
AuthTrail.geocode = false
```

Set job queue for geocoding

```ruby
AuthTrail::GeocodeJob.queue_as :low
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

## Privacy

Protect the privacy of your users by encrypting fields that contain personal information, such as `identity` and `ip`. [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) is a great library for this.

```ruby
class LoginActivity < ApplicationRecord
  attr_encrypted :identity, ...
  attr_encrypted :ip, ...
end
```

## Other Notes

We recommend using this in addition to Devise’s `Lockable` module and [Rack::Attack](https://github.com/kickstarter/rack-attack).

Check out [Hardening Devise](https://github.com/ankane/shorts/blob/master/Hardening-Devise.md) and [Secure Rails](https://github.com/ankane/secure_rails) for more best practices.

Works with Rails 5+

## History

View the [changelog](https://github.com/ankane/authtrail/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/authtrail/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/authtrail/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
