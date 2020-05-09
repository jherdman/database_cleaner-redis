require 'redis'
require 'database_cleaner/redis/truncation'
require 'yaml'

RSpec.describe DatabaseCleaner::Redis::Truncation do
  around do |example|
    config = YAML::load(File.open("spec/support/redis.yml"))
    @redis = ::Redis.new :url => config['test']['url']

    example.run

    @redis.flushdb
  end

  before do
    @redis.set 'Widget', 1
    @redis.set 'Gadget', 1
  end

  context "by default" do
    it "truncates all keys" do
      expect { subject.clean }.to change { @redis.keys.size }.from(2).to(0)
    end
  end

  context "with the :only option" do
    context "with concrete keys" do
      subject { described_class.new(only: ['Widget']) }

      it "only truncates the specified keys" do
        expect { subject.clean }.to change { @redis.keys.size }.from(2).to(1)
        expect(@redis.get('Gadget')).to eq '1'
      end
    end

    context "with wildcard keys" do
      subject { described_class.new(only: ['Widge*']) }

      it "only truncates the specified keys" do
        expect { subject.clean }.to change { @redis.keys.size }.from(2).to(1)
        expect(@redis.get('Gadget')).to eq '1'
      end
    end
  end

  context "with the :except option" do
    context "with concrete keys" do
      subject { described_class.new(except: ['Widget']) }

      it "truncates all but the specified keys" do
        expect { subject.clean }.to change { @redis.keys.size }.from(2).to(1)
        expect(@redis.get('Widget')).to eq '1'
      end
    end

    context "with wildcard keys" do
      subject { described_class.new(except: ['Widg*']) }

      it "truncates all but the specified keys" do
        expect { subject.clean }.to change { @redis.keys.size }.from(2).to(1)
        expect(@redis.get('Widget')).to eq '1'
      end
    end
  end

  context "when passing url" do
    it "still works" do
      url = @redis.connection[:id]
      subject.db = url
      expect(subject.db).to eq url
      expect { subject.clean }.to change { @redis.keys.size }.from(2).to(0)
    end
  end

  context "when passing connection" do
    it "still works" do
      connection = Redis.new(url: @redis.connection[:id])
      subject.db = connection
      expect(subject.db).to eq connection
      expect { subject.clean }.to change { @redis.keys.size }.from(2).to(0)
    end
  end

  it "should default to :default" do
    expect(subject.db).to eq :default
  end
end
