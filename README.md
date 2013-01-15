[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/joelhelbling/stepladder)

# The Stepladder Framework

_"How many Ruby fibers does it take to screw in a lightbulb?"_

## Quick Start

### Workers have tasks...

Initialize with a block of code:

```ruby
source_worker = Stepladder::Worker.new { "hulk" }

source_worker.product #=> "hulk"
```
If you supply a worker with another worker as its supplier, then you
can give it a task which accepts a value:

```ruby
relay_worker = Stepladder::Worker.new { |name| name.upcase }
relay_worker.supplier = source_worker

relay_worker.product #=> "HULK"
```

You can also initialize a worker by passing in a callable object
as its task:

```ruby
capitalizer = Proc.new { |name| name.capitalize }
relay_worker = Stepladder::Worker.new(task: capitalizer, supplier: source_worker)

relay_worker.product #=> 'Hulk'
```

A worker also has an accessor for its @task:

```ruby
doofusizer = Proc.new { |name| name.gsub(/u/, 'oo') }
relay_worker.task = doofusizer

relay_worker.product #=> 'hoolk'
```

And finally, you can provide a task by directly overriding the
worker's #task instance method:

```ruby
def relay_worker.task(name)
  name.to_sym
end

relay_worker.product #=> :hulk
```

Even workers without a task have a task; all workers actually come
with a default task which simply passes on the received value unchanged:

```ruby
useless_worker = Stepladder::Worker.new(supplier: source_worker)

useless_worker.product #=> 'hulk'
```

This turns out to be helpful in implementing filter workers, which are up next.

### Workers can have filters...

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

filter_worker.product #=> 1
filter_worker.product #=> 3
filter_worker.product #=> nil
```

### The pipeline DSL

You can stitch your workers together using the vertical pipe ("|") like so:

```ruby
pipeline = source_worker | filter_worker | relay_worker | another worker
```

...and then just call on that pipeline (it's actually the last worker in the
chain):

```ruby
while next_value = pipeline.product do
  do_something_with next_value
  # etc.
end
```

## Origins of Stepladder

Stepladder grew out of experimentation with Ruby fibers, after readings
[Dave Thomas' demo of Ruby fibers](http://pragdave.blogs.pragprog.com/pragdave/2007/12/pipelines-using.html), wherein he created a
pipeline of fiber processes, emulating the style and syntax of the
\*nix command line.  I noticed that, courtesy of fibers' extremely
low surface area, fiber-to-fiber collaborators could operate with
extremely low coupling.  That was the original motivation for creating
the framework.

After playing around with the new framework a bit, I began to notice
other interesting characteristics of this paradigm.

### Escalator vs Elevator

Suppose we are performing several operations on the members of a largish
collection. If we daisy-chain enumerable operators together (which is so
easy and fun with Ruby) we will notice that if something goes awry with
item number two during operation number seven, we nonetheless had to wait
through a complete run of all items through operations 1 - 6 before we
receive the bad news early in operation seven.  Imagine if the first six
operations take a long time to each complete?  Furthermore, what if the
operations on all incomplete items must be reversed in some way (e.g.
cleaned up or rolled back)?  It would be far less messy and far more
expedient if each item could be processed though all operations before
the next one is begun.

This is the design paradigm which stepladder makes easy.  Although all
the workers in your assembly line can be coded in the same context (which
is one of the big selling points of the daisy-chaining of enumerable
methods,incidentally), you also get the advantage of passing each item
though the entire op-chain before starting the next.

### Think Locally, Act Globally

Because stepladder workers use fibers as their basic API, the are almost
unaware of the outside world.  And they can pretty much be written as such.
At the heart of each Stepladder worker is a task which you provide, which
is a callable ruby object (such as a Proc or a lambda).

The scope of the work is whatever scope existed in the task when you
initially created the worker.  And if you want a worker to maintain its
own internal state, you can simply include a loop within the worker's
task, and use the `#handoff` method to pass along the worker's product at
the appropriate point in the loop.

For example:

```ruby
realestate_maker = Stepladder::Worker.new do
  oceans = %w[Atlantic Pacific Indiana Arctic]
  previous_ocean = "Atlantic"
  while current_ocean = oceans.sample
    drain current_ocean  #=> let's posit that this is a long-running async process!
    handoff previous_ocean
    previous_ocean = current_ocean
  end
```

Anything scoped to the outside of that loop but inside the worker's task
will essentially become that worker's initial state.  This means we often
don't need to bother with instance variables, accessors, and other
features of classes which deal with maintaining instances' state.

### The Wormhole Effect

Despite the fact that the work is done in separate threads, the _scope_
of the work is the scope of the coordinating body of code.  This means
that even the remaining coupling in such systems --which is primarily
just _common objects_ coupling-- this little remaining coupling is
mitigated by the possibility of having coupled code _live together_.
I call this feature the _folded collaborators_ effect.

Consider the following -code- vaporware:

```ruby
ME = "joelhelbling"

module Stepladder
  tweet_getter = Worker.new do
    twitter_api.fetch_my_tweets
  end

  about_me_filter      = Proc.new { |tweet| tweet.referenced.include? ME }
  just_about_me_getter = Worker.new filter: about_me_filter

  tweet_formatter = Worker.new do |tweet|
    apply_format_to tweet
  end

  formatted_tweets = tweet_getter | just_about_me_getter | tweet_formatter
end
```

None of these tasks have hard coupling with each other.  If we were to
insert another worker between the filter and the formatter, neither of those
workers would need changes in their code, assuming the inserted worker plays
nicely with the objects they're all passing along.

Which brings me to the point: these workers to have a dependency upon the
objects they're handing off and receiving.  But we have the capability to
coordinate those workers in a centralized location (such as in this code
example).

## Ok, but why is it called "Stepladder"?

This framework's name was inspired by a conversation with Tim Wingfield
in which we joked about the profusion of new frameworks in the Ruby
community.  We quickly began riffing on a fictional framework called
"Stepladder" which all the cool kids, we asserted, were (or would soon
be) using.

I have waited a long time to make that farce a reality, but hey, I take
joke frameworks very seriously. ;)
([Really?](http://github.com/joelhelbling/really))

## Roadmap

- add a nicer top-layer to the DSL --no reason we should have to do
  all that `Worker.new` stuff
