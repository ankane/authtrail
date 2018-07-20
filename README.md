# AuthTrail

Track Devise account activity

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

Then, add `:trailable` to your Devise models:

```ruby
class User < ApplicationRecord
  devise :trailable, ...
end
```

## How It Works

A `AccountActivity` record is created when certain activities occur. You can then use this information to detect suspicious behavior. Data includes:

- `activity_type` - can be `sign_in`, `sign_out`, `password_reset_request`, `email_change`, `password_change`
- `user` - the user
- `ip` - IP address
- `user_agent` and `referrer` - from browser
- `context` - controller and action
- `city`, `region`, and `country` - from IP
- `created_at` - time of event

There a number of attributes specific to sign in activity.

- `scope` - Devise scope
- `strategy` - Devise strategy
- `identity` - identity that was used - typically email or username
- `success` - whether the sign in succeeded
- `failure_reason` - for failures

## Features

Exclude certain attempts from tracking - useful if you run acceptance tests

```ruby
AuthTrail.exclude_method = lambda do |info|
  info[:identity] == "capybara@example.org"
end
```

Write data somewhere other than the `account_activities` table

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

Track your own custom activities

```ruby
AuthTrail.track(activity_type: "phone_change", user: user)
```

Associate account activity with your user model

```ruby
class Admin < ApplicationRecord
  has_many :login_activities, as: :user
end
```

The `AccountActivity` model uses a [polymorphic association](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations) so it can be associated with different user models.

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

## Upgrading

### 0.2.0

Create a migration with:

```ruby
add_column :login_activities, :activity_type, :string
```

Change the `LoginActivity` model to:

```ruby
class AccountActivity < ApplicationRecord
  self.table_name = "login_activities"
  belongs_to :user, polymorphic: true, optional: true
end
```

Be sure to rename the file to `account_activity.rb` as well.

## History

View the [changelog](https://github.com/ankane/authtrail/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/authtrail/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/authtrail/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
