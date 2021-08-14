## 0.4.1 (2021-08-14)

- Improved error message when `geocoder` gem not installed

## 0.4.0 (2021-08-13)

- Disabled geocoding by default
- Made the `geocoder` gem an optional dependency
- Added `country_code` to geocoding

## 0.3.1 (2021-03-03)

- Added `--lockbox` option to install generator

## 0.3.0 (2021-03-01)

- Disabled geocoding by default for new installations
- Raise an exception instead of logging when auditing fails
- Removed support for Rails < 5.2 and Ruby < 2.6

## 0.2.2 (2020-11-21)

- Added `transform_method` option

## 0.2.1 (2020-08-17)

- Added `job_queue` option

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
