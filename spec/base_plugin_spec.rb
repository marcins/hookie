require 'spec_helper'
require 'hookie'
require 'hookie/plugins/base_plugin'

class ThisHasALongNamePlugin < Hookie::BasePlugin
end

describe Hookie::BasePlugin do
  before :each do
    @hookie = double(Hookie::Framework)
    @config = double(Grit::Config)
    @config.stub(:keys).and_return([])
    @hookie.stub(:config).and_return(@config)
  end
  context "base plugin" do
    before :each do
      @plugin = Hookie::BasePlugin.new @hookie
    end
    it "should initialise" do

    end

    it "is runnable" do
      @plugin.should_run?.should be_true
    end

    it "should correctly derive the plugin name" do
      @plugin.to_s.should eq "Base"
      @plugin.config_key.should eq "base"

      plugin = ThisHasALongNamePlugin.new @hookie
      plugin.to_s.should eq "ThisHasALongName"
      plugin.config_key.should eq "thishasalongname"
    end

    it "should read the correct config" do
      @config.should_receive(:keys).once.and_return(["core.key","hookie.base.mykey"])
      @config.should_receive('[]').with('hookie.base.mykey').and_return("value")
      @plugin = Hookie::BasePlugin.new @hookie
      @plugin.config.should have(1).items
    end

    it "should send log messages" do
      @hookie.should_receive(:log).once.with(@plugin, "message")
      @plugin.log "message"
    end
  end
end