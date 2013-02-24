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
      it "identifies itself" do
        @plugin.to_s.should eq "HipChat Notifier"
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
        @config.should_receive(:keys).and_return(['hookie.hipchat.apikey','hookie.hipchat.room'])
        @config.should_receive('[]').with('hookie.hipchat.apikey').and_return("ABC123")
        @config.should_receive('[]').with('hookie.hipchat.room').and_return("1234")
        plugin = Hookie::Plugin::HipChatPlugin.new @hookie
        @hookie.should_receive(:changes).once.and_return(["something"])
        @hookie.should_not_receive(:log)
        plugin.should_run?.should be_true
      end
    end

    it "responds to success" do
      # FIXME this neds to be better
      @plugin.stub(:format_message).and_return("message")
      @plugin.should_receive(:speak).with("message").and_return({:status => "sent"})
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /sent/)
      @plugin.post_receive
    end

    it "responds to failure" do
      @plugin.stub(:format_message).and_return("message")
      @plugin.should_receive(:speak).with("message").and_return({error: { message: "ERROR"}})
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /ERROR/)
      @plugin.post_receive
    end

    it "responds to an unknown response" do
      @plugin.stub(:format_message).and_return("message")
      @plugin.should_receive(:speak).with("message").and_return({})
      @hookie.should_receive(:log).with(any_args)
      @hookie.should_receive(:log).with(@plugin, /unknown/i)
      @plugin.post_receive
    end

    context "message" do
      def commit_stub(abbrev, author, message)
        commit = double(Grit::Commit)
        commit.stub(:id_abbrev).and_return(abbrev)
        commit.stub(:author).and_return(author)
        commit.stub(:short_message).and_return(message)
        commit
      end

      before :each do
        @hookie.stub(:repo_url).and_return(nil)
        @hookie.stub(:repo_name).and_return("REPO")
        @hookie.stub(:commit_url).and_return("")
        @hookie.stub(:head_names_for_commit).and_return([])
      end

      it "properly formats a message for one change" do
        change = {
          commit: commit_stub("00000", "Author", "Message")
        }

        @hookie.stub(:changes).and_return([change])
        expected_message = "Commits just pushed to REPO:<br/><a href=''>00000</a> Author: Message<br/>"

        @plugin.should_receive(:speak).with(expected_message).and_return({status: "sent"})
        @plugin.post_receive
      end

      it "properly formats a message for multiple changes" do
        stub = commit_stub("00001", "Author2", "Message2")
        change = [
          { commit: commit_stub("00000", "Author", "Message") },
          { commit: stub }
        ]

        @hookie.stub(:head_names_for_commit).with(stub).and_return(["test"])

        @hookie.stub(:changes).and_return(change)
        expected_message = "Commits just pushed to REPO:<br/><a href=''>00000</a> Author: Message<br/><a href=''>00001</a> (test) Author2: Message2<br/>"

        @plugin.should_receive(:speak).with(expected_message).and_return({status: "sent"})
        @plugin.post_receive

      end

    end
  end
end