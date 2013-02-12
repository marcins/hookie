require 'spec_helper'
require 'hookie'
require 'hookie/plugins/hipchat_plugin'

describe Hookie::Plugin::HipChatPlugin do
  before :each do
    @hookie = double(Hookie::Framework)
    @config = double(Grit::Config)
    @config.stub(:keys).and_return([])

    @hookie.stub(:config).and_return(@config)
    @hookie.stub(:log)
  end
  context "HipChat plugin" do
    before :each do
      @plugin = Hookie::Plugin::HipChatPlugin.new @hookie
    end

    context "config" do
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
        @config.should_receive(:keys).and_yield('hookie.hipchat.apikey').and_yield('hookie.hipchat.room')
        @config.should_receive('[]').with('hookie.hipchat.apikey').and_return("ABC123")
        @config.should_receive('[]').with('hookie.hipchat.room').and_return("1234")
        plugin = Hookie::Plugin::HipChatPlugin.new @hookie
        @hookie.should_receive(:changes).once.and_return(["something"])
        @hookie.should_not_receive(:log)
        plugin.should_run?.should be_true
      end
    end

    it "sends the correct message" do
      # FIXME this neds to be better
      @plugin.stub(:format_message).and_return("message")
      @plugin.should_receive(:speak).with("message").and_return({"status" => "sent"})
      @hookie.should_receive(:log).twice
      @plugin.post_receive
    end

  end
end