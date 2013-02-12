require 'spec_helper'
require 'hookie'
require 'hookie/plugins/jenkins_plugin'

describe Hookie::Plugin::JenkinsPlugin do
  before :each do
    @hookie = double(Hookie::Framework)
    @config = double(Grit::Config)
    @config.stub(:keys).and_return([])

    @hookie.stub(:config).and_return(@config)
    @hookie.stub(:log)

    @plugin = Hookie::Plugin::JenkinsPlugin.new @hookie
  end
  context "Jenkins plugin" do

    context "config" do
      it "shouldn't run when not configured" do
        @plugin.stub(:config).and_return({})
        @plugin.should_run?.should be_false
      end
      it "should run when it is configured" do
        @plugin.should_receive(:config).at_least(:once).and_return({url: "foo"})
        @plugin.should_run?.should be_true
      end
      it "should check for branches if configured" do
        commit = double("Grit::Commit")
        @hookie.should_receive(:changes).at_least(:once).and_return([
          {old_hash: "", new_hash: "", ref: "", commit: commit}
          ])
        @hookie.should_receive(:head_names_for_commit).with(commit).and_return(['develop'])
        @plugin.should_receive(:config).at_least(:once).and_return({
            url: "foo",
            branches: "develop,master"
          })
        @plugin.should_run?.should  be_true

        @hookie.should_receive(:head_names_for_commit).with(commit).and_return(['develop','foob'])
        @plugin.should_run?.should be_true

        @hookie.should_receive(:head_names_for_commit).with(commit).and_return(['develop','master'])
        @plugin.should_run?.should be_true

      end
    end
  end
end