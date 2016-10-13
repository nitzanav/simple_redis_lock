require "spec_helper"
require 'redis'
require "fakeredis"

describe SimpleRedisLock do

  # when using fakeredis 1ms works well, when using real redis when < 0.003 you will se that the test will fail
  THREAD_SYNC_DELAY_FAKE_REDIS = 0.001 # (in seconds, 0.001 is 1ms)
  THREAD_SYNC_DELAY_REAL_REDIS = 0.005 # (in seconds, 0.001 is 1ms)
  THREAD_SYNC_DELAY = defined?(FakeRedis) ? THREAD_SYNC_DELAY_FAKE_REDIS : THREAD_SYNC_DELAY_REAL_REDIS
  EX = THREAD_SYNC_DELAY * 10

  subject { SimpleRedisLock.create(Redis.new) }

  # Using random keys and expiration of 50ms to avoid conflict between tests and between testing suites running in parallel on the same machine, although it is likely
  let(:key) { "simple_redis_lock_spec_key_#{Random.rand}" }

  it 'Executes block when lock acquired successfully' do
    expect(subject.lock(key, EX) { 'executed' }).to eq 'executed'
  end

  it 'holds lock till blocked completed, when giving a block.' do
    Thread.new do
      subject.lock(key, EX) { sleep THREAD_SYNC_DELAY * 2 }
    end
    sleep THREAD_SYNC_DELAY
    expect(subject.lock(key, EX) { 'executed' }).to be_nil
  end

  it 'releases when blocked completed' do
    Thread.new do
      subject.lock(key, EX) { sleep THREAD_SYNC_DELAY }
    end
    sleep THREAD_SYNC_DELAY * 2
    expect(subject.lock(key, EX) { 'executed' }).to eq 'executed'
  end

  it 'it expires after timeout' do
    Thread.new do
      subject.lock(key, THREAD_SYNC_DELAY) { sleep THREAD_SYNC_DELAY * 4 }
    end
    sleep THREAD_SYNC_DELAY * 2
    expect(subject.lock(key, EX) { 'executed' }).to eq 'executed'
  end

  it 'releases when exception raised' do
    Thread.new do
      subject.lock(key, EX) { raise 'error will release lock' }
    end
    sleep THREAD_SYNC_DELAY
    expect(subject.lock(key, EX) { 'executed' }).to eq 'executed'
  end

  it 'has acquired_at attribute that returns the time of lock' do
    expect(subject.acquired_at(key)).to be_nil

    expected_lock_time = Time.now
    Thread.new do
      subject.lock(key, EX) { sleep THREAD_SYNC_DELAY * 2 }
    end
    sleep THREAD_SYNC_DELAY
    expect(subject.acquired_at(key)).to be_within(0.001).of(expected_lock_time)
    sleep THREAD_SYNC_DELAY
    expect(subject.acquired_at(key)).to be_nil
  end

  it 'has ttl that returns the remaining time till expiration of lock.' do
    expect(subject.ttl(key)).to be_nil

    Thread.new do
      subject.lock(key, EX) { sleep THREAD_SYNC_DELAY * 2 }
    end
    sleep THREAD_SYNC_DELAY
    expect(subject.ttl(key)).to be_within(THREAD_SYNC_DELAY * 2).of(EX)
    sleep THREAD_SYNC_DELAY * 2
    expect(subject.ttl(key)).to be_nil
  end

  it 'when no block given, the lock is held until #release is called.' do
    expected_lock_time = Time.now
    expect(subject.lock(key, EX)).to eq true
    expect(subject.acquired_at(key)).to be_within(THREAD_SYNC_DELAY).of(expected_lock_time)
    expect(subject.ttl(key)).to be_within(THREAD_SYNC_DELAY * 2).of(EX)
    expect(subject.lock(key, EX)).to be_nil
    subject.release(key)
    expect(subject.lock(key, EX)).to eq true
  end

end
