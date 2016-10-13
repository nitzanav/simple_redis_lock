require 'redis'
require 'simple_redis_lock/version'

# @author Nitzan Aviram
# Locks a critical code using redis SET NX|EX/PX, it is fast and simple.
#

module SimpleRedisLock

  def self.create(redis = Redis.new)
    SimpleLock.new(redis)
  end

  class SimpleLock

    def initialize(redis = Redis.new)
      @redis = redis
    end

    # Tries to acquire a lock using redis and execute the given block.
    # if lock was acquired
    #   when a block was given, it will execute the given block.
    #   when no block given it will hold the lock until [release] is called.
    # if lock cannot be acquired, given block.
    #
    # == Returns:
    # if lock was acquired, the returned value of the given block or [true] if no block given.
    # if lock cannot be acquired, nil is returned
    #
    # Locks on a key using redis SET NX|EX/PX.
    # Lock will be released when:
    #   1. Block execution completed
    #   2. Block raise an exception
    #   3. Expiration reached
    #
    # == Parameters:
    # key::
    #   The key of the lock, two threads/processes should use the same key.
    # expiration::
    #   Expiration to release the lock, useful when using sidekiq/rescue workers that can be just killed.
    #   expected value is in seconds, milliseconds are accepted as float. 0.001 is 1ms. The lock will be released by the [expiration] interval.
    # block:
    #   A block to be executed when lock is acquired.
    #
    def lock(key, expiration)
      timeout = (expiration * 1000).to_i
      if @redis.set("SimpleRedisLock:#{key}", Time.now.strftime('%Y-%m-%d %H:%M:%S.%L %z'), nx: true, px: timeout)
        if block_given?
          begin
            yield
          ensure
            release key
          end
        else
          true
        end
      end
    end

    def release(key)
      @redis.del "SimpleRedisLock:#{key}"
    end

    # time
    def acquired_at(key)
      time_string = @redis.get("SimpleRedisLock:#{key}")
      return nil unless time_string

      Time.strptime(time_string, '%Y-%m-%d %H:%M:%S.%L %z')
    end

    # remaining time till lock expiration
    def ttl(key)
      pttl = @redis.pttl("SimpleRedisLock:#{key}")
      return nil if pttl == -2

      pttl.to_f / 1000
    end

  end
end
