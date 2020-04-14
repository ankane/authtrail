## 0.3.0 (unreleased)

- Expanded to more activities - sign outs, email changes, password changes, password reset requests, locks, unlocks, and confirmations
- Raise an exception when auditing fails

## 0.2.0 (2019-06-23)

- Added latitude and longitude
- `AuthTrail::GeocodeJob` now inherits from `ActiveJob::Base` instead of `ApplicationJob`
- Removed support for Rails 4.2

## 0.1.3 (2018-09-27)

- Added support for Rails 4.2

## 0.1.2 (2018-07-30)

- Added `identity_method` option
- Fixed geocoding

## 0.1.1 (2018-07-13)

- Improved strategy detection for failures
- Fixed migration for MySQL

## 0.1.0 (2017-11-07)

- First release
