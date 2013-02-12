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
  end
end