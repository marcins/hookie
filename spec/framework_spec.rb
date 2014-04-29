require 'spec_helper'

describe Hookie do
  before(:each) do
      @repo = double('Grit::Repo')
      @config = double('Grit::Config')
      Grit::Repo.should_receive(:new).once.and_return(@repo)
      @repo.stub(:commits).and_return([])
      @repo.stub(:config).and_return(@config)
      STDIN.should_receive(:each_line).and_yield("bf6245eb3f1fa4cadff4299cb45e3ed85bc3337e b37c9728362ec39ce57adaab6ad9f0225d3513fe refs/heads/master").and_yield("0000000000000000000000000000000000000000 09e6a76d20ae8c8e1d40ce21b6ea586ff860e5d3 refs/heads/develop")
  end

  context 'initialisation' do
    it "intialises" do
      hookie = Hookie::Framework.new "test_hook", Dir.getwd
      hookie
    end

    it "can can use the hook static" do
      @config.stub(:[])
      begin
        Hookie::Framework.hook "foo"
      rescue SystemExit => e
        e.status.should be 255
      end
    end

    it "reads changes" do
      commit = double('Grit::Commit')
      @repo.should_receive(:commits).with("b37c9728362ec39ce57adaab6ad9f0225d3513fe", 1).once.and_return([commit])

      hookie = Hookie::Framework.new "test_hook", Dir.getwd

      hookie.changes.should have(2).items
      change = hookie.changes[0]

      change[:old_hash].should eq "bf6245eb3f1fa4cadff4299cb45e3ed85bc3337e"
      change[:new_hash].should eq "b37c9728362ec39ce57adaab6ad9f0225d3513fe"
      change[:ref].should eq "refs/heads/master"

      change[:commit].should be commit

      change2 = hookie.changes[1]
      change2[:old_hash].should eq "0000000000000000000000000000000000000000"
      change2[:new_hash].should eq "09e6a76d20ae8c8e1d40ce21b6ea586ff860e5d3"
      change2[:ref].should eq "refs/heads/develop"
    end
  end

  context "runner" do
    before(:each) do
      @config.stub(:keys).and_return([])
      @hookie = Hookie::Framework.new "test_hook", Dir.getwd
    end

    it "exits if no allowed plugins set" do
      @config.stub(:[]).with("hookie.core.allowedplugins").and_return(nil)
      begin
        @hookie.run_plugins("test")
      rescue SystemExit => e
        e.status.should be 255
      end
    end

    module Hookie
      module Plugin
        class TestPlugin < BasePlugin
          def test
            log "ran test"
          end
          def errors
            raise "Fudge"
          end
        end
      end
    end

   it "runs a plugin" do
      @config.stub(:keys).and_return(["hookie.core.allowedplugins"])
      @config.stub(:[]).with("hookie.core.allowedplugins").and_return(["test"])
      @hookie.should_receive(:log).with(anything, "ran test")
      @hookie.run_plugins("test")
    end

   it "handles plugin failure" do
      @config.stub(:keys).and_return(["hookie.core.allowedplugins"])
      @config.stub(:[]).with("hookie.core.allowedplugins").and_return(["test"])
      @hookie.should_receive(:log).with(anything, /exception/i)
      @hookie.run_plugins("errors")
    end

  end

  context "helpers" do
    before(:each) do
      @hookie = Hookie::Framework.new "test_hook", Dir.getwd
    end

    it "should not return a repo browsing url if it's not set" do
      @repo.should_receive(:config).once.and_return(@config)
      @config.should_receive('[]').with('hookie.core.web.browse').and_return(nil)
      @hookie.repo_url.should be_nil
    end

    it "should return a repo browsing url if it's set" do
      @repo.config.should_receive('[]').with("hookie.core.web.browse").at_least(:once).and_return("TEST %REPO% TEST")
      @repo.config.should_receive('[]').with("hookie.core.repo.name").at_least(:once).and_return("testrepo")
      @hookie.repo_url.should eq "TEST testrepo TEST"
    end

    it "should not return a commit url if it's not set" do
      @repo.config.should_receive('[]').with("hookie.core.web.commit").at_least(:once).and_return(nil)
      commit = double('Grit::Commit')
      @hookie.commit_url(commit).should be_nil
    end

    it "should return a commit url if it's set" do
      @repo.config.should_receive('[]').with("hookie.core.web.commit").at_least(:once).and_return("TEST %REPO% TEST %COMMIT%")
      @repo.config.should_receive('[]').with("hookie.core.repo.name").at_least(:once).and_return("testrepo")
      commit = double('Grit::Commit')
      commit.stub(:id).and_return("ABC")
      @hookie.commit_url(commit).should eq "TEST testrepo TEST ABC"
    end

    it "correctly gets the name of a bare repo" do
      @repo.stub(:bare).and_return(true)
      @repo.stub(:path).and_return("/foo/bar/baz.git")
      @config.stub(:[]).with('hookie.core.repo.name').and_return(nil)
      @hookie.repo_name.should eq "baz"
    end

    it "correctly gets the name of a non-bare repo" do
      @repo.stub(:bare).and_return(false)
      @repo.stub(:path).and_return("/foo/bar/baz/.git")
      @config.stub(:[]).with('hookie.core.repo.name').and_return(nil)
      @hookie.repo_name.should eq "baz"
    end

    it "collects heads" do
      def head_helper(name, commit_id)
        head = double("Grit::Head")
        head.stub(:name).and_return(name)
        commit = double("Grit::Commit")
        commit.stub(:id).and_return(commit_id)
        head.stub(:commit).and_return(commit)
        head
      end
      heads = [
        head_helper("one", "1"),
        head_helper("two", "2"),
        head_helper("three", "2")
      ]

      @repo.stub(:heads).with(any_args).and_return(heads)
      commit = double("Grit::Commit")
      commit.stub(:id).and_return("1")
      @hookie.head_names_for_commit(commit).should have(1).items
    end

    it "logs stuff" do
      class TestPlugin
        def to_s
          "Test"
        end
      end
      plugin = TestPlugin.new
      Time.stub(:now).and_return(Time.parse("01/04/2013 09:00:00"))
      @hookie.should_receive(:puts).with("[2013-04-01 09:00:00] Test: test")
      @hookie.log(plugin, "test")
    end

  end
end