require 'spec_helper'
require 'hookie'
require 'hookie/plugins/fisheye_plugin'

describe Hookie::Plugin::FishEyePlugin do
  before :each do
    @hookie = double(Hookie::Framework)
    @config = double(Grit::Config)
    @config.stub(:keys).and_return([])

    @hookie.stub(:config).and_return(@config)
    @hookie.stub(:log)
  end

  context "FishEye plugin" do
    before :each do
      @plugin = Hookie::Plugin::FishEyePlugin.new @hookie
    end

    context "config" do
      it "identifies itself" do
        @plugin.to_s.should eq "FishEye Notifier"
      end

      it "shouldn't run only when there are no changes" do
        @hookie.should_receive(:changes).once.and_return([])
        @plugin.should_run?.should be_false
      end

      it "shouldn't run when there are changes but config is missing" do
        @hookie.should_receive(:changes).once.and_return(["something"])
        @hookie.should_receive(:log).once
        @plugin.should_run?.should be_false
      end

      it "should run when there are no changes and config is correct" do
        @config.should_receive(:keys).and_return(['hookie.fisheye.apikey','hookie.fisheye.url'])
        @config.should_receive('[]').with('hookie.fisheye.apikey').and_return("ABC123")
        @config.should_receive('[]').with('hookie.fisheye.url').and_return("http://localhost/test/%REPO%/")
        plugin = Hookie::Plugin::FishEyePlugin.new @hookie
        @hookie.should_receive(:changes).once.and_return(["something"])
        @hookie.should_not_receive(:log)
        plugin.should_run?.should be_true
      end
    end

    it "responds to success" do
      # FIXME this neds to be better
      @plugin.should_receive(:notify).and_return([])
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /sent/)
      @plugin.post_receive
    end

    it "responds to failure" do
      @plugin.should_receive(:notify).and_return({code: 401,  message: "ERROR"})
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /ERROR/)
      @plugin.post_receive
    end

    it "responds to an unknown response" do
      @plugin.should_receive(:notify).and_return({foo: 'bar'})
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /unknown/i)
      @plugin.post_receive
    end
  end
end