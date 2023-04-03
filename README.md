[![Gem Version](https://badge.fury.io/rb/activerecord-slotted_counters.svg)](https://rubygems.org/gems/activerecord-slotted_counters) [![Build](https://github.com/evilmartians/activerecord-slotted_counters/workflows/Build/badge.svg)](https://github.com/evilmartians/activerecord-slotted_counters/actions)

# Active Record slotted counters

This gem adds **slotted counters** support to [Active Record counter cache][counter-cache]. Slotted counters help to reduce contention on a single row update in case you have many concurrent operations (like updating a page views counter during traffic spikes).

Read more about slotted counters in [this post](https://planetscale.com/blog/the-slotted-counter-pattern).

<p align="center">
  <a href="https://evilmartians.com/?utm_source=active-record-slotted-counters">
    <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg"
         alt="Sponsored by Evil Martians" width="236" height="54">
  </a>
</p>

## Installation

Add to your project:

```ruby
# Gemfile
gem "activerecord-slotted_counters"
```

### Supported Ruby versions

- Ruby (MRI) >= 2.7.0

## Usage

First, add and apply the required migration(-s):

```sh
bin/rails generate slotted_counters:install
bin/rails db:migrate
```

Then, add the following line to the model to add a slotted counter:

```ruby
class User < ApplicationRecord
  has_slotted_counter :comments
end
```

Now you can use all the common counter cache APIs as before:

```ruby
# Manipulating the counter explicitly
user = User.first

User.increment_counter(:comments_count, user.id)
User.decrement_counter(:comments_count, user.id)
User.reset_counters(user.id, :comments)
# etc.

# Reading the value
user.comments_count
```

Under the hood, a row in the `slotted_counters` table is created associated with the record.

**NOTE:** Reading the current value performs SQL query once:

```ruby
user.comments_count #=> select * from slotted_counters where ...
user.comments_count #=> no sql
```

If you want to want preload counters for multiple records, you can use a convenient `#with_slotted_counters` method:

```ruby
User.all.with_slotted_counters(:comments).find_each do
  _1.comments_count #=> no sql
end
```

Using `counter_cache: true` on `belongs_to` associations also works as expected.

## Limitations / TODO

- Gem supports only PostgreSQL for Rails 6

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/evilmartians/activerecord-slotted_counters](https://github.com/evilmartians/activerecord-slotted_counters).

## Credis

This gem is generated via [new-gem-generator](https://github.com/palkan/new-gem-generator).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[counter-cache]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html
