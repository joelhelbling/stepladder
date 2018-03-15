# Stepladder::Worker

_The workhorse of the Stepladder framework._

## Workers have tasks...

Initialize with a block of code:

```ruby
source_worker = Stepladder::Worker.new { "hulk" }

source_worker.shift #=> "hulk"
```
If you supply a worker with another worker as its supplier, then you
can give it a task which accepts a value:

```ruby
relay_worker = Stepladder::Worker.new { |name| name.upcase }
relay_worker.supplier = source_worker

relay_worker.shift #=> "HULK"
```

You can also initialize a worker by passing in a callable object
as its task:

```ruby
capitalizer = Proc.new { |name| name.capitalize }
relay_worker = Stepladder::Worker.new(task: capitalizer, supplier: source_worker)

relay_worker.shift #=> 'Hulk'
```

A worker also has an accessor for its @task:

```ruby
doofusizer = Proc.new { |name| name.gsub(/u/, 'oo') }
relay_worker.task = doofusizer

relay_worker.shift #=> 'hoolk'
```

And finally, you can provide a task by directly overriding the
worker's #task instance method:

```ruby
def relay_worker.task(name)
  name.to_sym
end

relay_worker.shift #=> :hulk
```

Even workers without a task have a task; all workers actually come
with a default task which simply passes on the received value unchanged:

```ruby
useless_worker = Stepladder::Worker.new(supplier: source_worker)

useless_worker.shift #=> 'hulk'
```

This turns out to be helpful in implementing filter workers, which are up next.

## Workers can have filters...

Given a source worker which provides integers 1-3:

```ruby
source = Stepladder::Worker.new do
  (1..3).each { |number| handoff number }
end
```

...we can define a subscribing worker with a filter:

```ruby
odd_number_filter = Proc.new { |number| number % 2 > 0 }
filter_worker = Stepladder::Worker.new filter: odd_number_filter

filter_worker.shift #=> 1
filter_worker.shift #=> 3
filter_worker.shift #=> nil
```

## The pipeline DSL

You can stitch your workers together using the vertical pipe ("|") like so:

```ruby
pipeline = source_worker | filter_worker | relay_worker | another worker
```

...and then just call on that pipeline (it's actually the last worker in the
chain):

```ruby
while next_value = pipeline.shift do
  do_something_with next_value
  # etc.
end
```

