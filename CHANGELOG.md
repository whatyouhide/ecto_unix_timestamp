# Changelog

## v1.0.0

  * Add default support for accepting Unix timestamps as strings as well, with an optional `:accept_strings` option to disable the behavior (it's enabled by default).

## v0.3.0

  * Support `DateTime` and `NaiveDateTime` structs when casting.

## v0.2.0

  * Add the `t:EctoUnixTimestamp.t/0` type.
  * Fix casting, loading, and dumping of non-integer terms.
