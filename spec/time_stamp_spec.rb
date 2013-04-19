require "viera_play/time_stamp"

describe TimeStamp do
  describe ".parse" do
    it "creates a new instance" do
      TimeStamp.parse('00:00:00').should be_instance_of(TimeStamp)
    end

    it "parses positive timestamps" do
      TimeStamp.parse('00:00:00').to_i.should eq 0
      TimeStamp.parse('00:00:01').to_i.should eq 1
      TimeStamp.parse('00:01:01').to_i.should eq 61
      TimeStamp.parse('01:01:01').to_i.should eq 3_661
    end

    it "parses negative timestamps" do
      TimeStamp.parse('-00:00:00').to_i.should eq 0
      TimeStamp.parse('-00:00:01').to_i.should eq(-1)
      TimeStamp.parse('-00:01:01').to_i.should eq(-61)
      TimeStamp.parse('-01:01:01').to_i.should eq(-3_661)
    end

    it "parses timestamps with a single hour digit" do
      TimeStamp.parse('0:00:00').to_i.should eq 0
      TimeStamp.parse('0:00:01').to_i.should eq 1
      TimeStamp.parse('0:01:01').to_i.should eq 61
      TimeStamp.parse('1:01:01').to_i.should eq 3_661
    end
  end

  describe "#to_s" do
    it "formats positive timestamps" do
      TimeStamp.parse('01:01:01').to_s.should eq '01:01:01'
    end

    it "formats negative timestamps" do
      TimeStamp.parse('-01:01:01').to_s.should eq '-01:01:01'
    end
  end

  describe "#to_i" do
    it "coerses positive timestamps" do
      TimeStamp.new(100).to_i.should == 100
    end

    it "coerses negative timestamps" do
      TimeStamp.new(-100).to_i.should == -100
    end
  end

  describe "#+" do
    it "adds another integer" do
      (TimeStamp.new(-100) + TimeStamp.new(20)).to_i.should == -80
    end
  end
end
