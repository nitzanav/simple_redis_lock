# Simple Redis Lock

Simple and fast lock using one single redis call of 'SET k v NX EX'
It is non blocking, meaning that if you cannot acquire the lock, the given block will not be executed.

While the alternatives are awesome, I wanted a simple solution, kind of 5 lines of code, and a simple single redis solution.

This is the code of the gem, nice and knit:
```ruby
if @redis.set(key, Time.now, nx: true, px: timeout)
  begin
    yield
  ensure
    @redis.del key
  end
end
```

And here is a more extensive usage:
```ruby
simple_lock = SimpleRedisLock.create(Redis.new) # or just SimpleRedisLock.create
Thread.new do
  simple_lock.lock('task_384', 10) do
    sleep 0.100
    # Run critical code section...
    'return value'
  end # => 'return value'
end
sleep 0.001 # wait for threads to sync
simple_lock.acquired_at('task_384') # => 2016-10-12 03:25:19.287 +0300
simple_lock.ttl('task_384') # => 9.989 # remainging seconds
simple_lock.lock('task_384', 10) # => nil # lock is still held.
sleep 0.100 # wait for block to completed and release lock

# block execution completed, lock released.
simple_lock.lock('task_384', 0.100) # => true, no block given, expecting it to expire in 100ms even if not released.
simple_lock.lock('task_384', 10) # => nil # cannot acquire lock, it is still held
sleep 0.100 # wait for expiration to pass

# Expiration passed, lock released
simple_lock.lock('task_384', 10) # => true
# Run critical code section...
simple_lock.release('task_384')
simple_lock.acquired_at('task_384') # => nil
simple_lock.ttl('task_384') # => nil
```



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_redis_lock'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_redis_lock

## Alternatives:

I explored some other awesome alternatives before creating this gem:

1. [mlanett/redis-lock](https://github.com/mlanett/redis-lock)
2. [PatrickTulskie/redis-lock](https://github.com/PatrickTulskie/redis-lock)
3. [leandromoreira/redlock-rb](https://github.com/leandromoreira/redlock-rb)
4. [dv/redis-semaphore](https://github.com/dv/redis-semaphore)

but they had too many features of blocking to acquire lock and didn't use this single ```SET KEY 1 NX EX 3600``` awesome atomic redis statement.

