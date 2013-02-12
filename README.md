# Hookie

Hookie is a pluggable framework for creating git hooks using Ruby. It was originally designed for writing hooks for gitolite, but should work for any hooks, including local ones.

## Background

After we had setup [HipChat](http://hipchat.com) at our organisation I wanted to get notifications from gitolite pushes pushed to HipChat. I found the [gitolite-hipchat-notification](https://github.com/peplin/gitolite-hipchat-notification) project, and [forked it](https://github.com/marcins/gitolite-hipchat-notification) and cleaned it up a bit for my purposes. However this script wasn't very flexible in that you needed to add it individually to each repo (or suffer with a single config). Then I wanted to add Jenkins build notifications as well, so had to enhance the script to support running multiple tasks. Eventually it was all getting too crufty and so Hookie was born!

Hookie is designed so that you can have multiple actions take place as a result of a git hook (usually post-receive), these actions are built as plugins, and configured via git - the beauty of this is that for gitolite you define the hook globally and then configure which plugins run where via git config keys, which can be defined in your gitolite-admin repository. So once Hookie is setup you don't need to make changes on the server.

Hookie includes those aforementioned plugins for HipChat and Jenkins in the base build.

## Acknowledgements

Hookie is built on the base of @peplin's (gitolite-hipchat-notification)[https://github.com/peplin/gitolite-hipchat-notification] project, which was originally forked from (gitolite-campfire-notification)[https://github.com/LegionSB/gitolite-campfire-notification] - the magic of Open Source!

Hookie uses [grit](https://github.com/mojombo/grit) for accessing information in git repositories.

## Installation

Install the gem on your git server

    gem install hookie

You then need to create a post-receive script in your repository's hooks directory, there are a couple of ways to do this, see below for some options. The post-receive hook will look like this:

    #!/usr/bin/env ruby
    require 'hookie'

    # Add your plugins here
    # require 'my_plugin'

    Hookie::Framework.hook "post_receive"

### Installing hooks with gitolite

The idea is that you install hookie as a post_receive hook for all your repositories, but configuration determines when the hook is actually run. To install for all repositories you create the post-receive script in the .gitolite/hooks/common/ directory.  Make sure the script is exectuable.

### Installing hooks manually

You can also install Hookie hooks manually, by adding them to the hooks directory within your repository. Note that the same configuration still applies.  You should also be able to install Hookie for local repository hooks, but I haven't tried this yet!  Currently Hookie assumes it will be receiving changeset information on STDIN in the format gitolite provides it, I'm not sure if other git servers and/or local hooks also receive information the same way?

## Configuration

Hookie was written such that it can be configured using Gitolite's ability to set git config keys via the gitolite-admin repository.

You can set "global" config keys using the special repository @all in gitolite, and override or set project specific keys within the repository itself. This makes it easy to, for example, set your HipChat API key for all repos, but then set the room that gets notified in each repo separately - and this can all be done via the gitolite-admin repository, without requiring access to the git server.

An example conf/gitolite.conf:

    repo gitolite-admin
        RW+     =   marcin

    repo testing
        RW+     =   @all
        config hookie.core.allowedplugins = hipchat,jenkins
        config hookie.hipchat.room = 123456
        config hookie.jenkins.url = http://jenkins.example.com/job/Test%20Job/build?token=test
        config hookie.jenkins.branches=develop
        config hookie.jenkins.auth=jenkins:TOKEN

    repo @all
        config hookie.hipchat.apikey = APIKEY
        config hookie.hipchat.from = "Git Test"
        config hookie.core.web.commit = https://fisheye.example.com/changelog/%REPO%?cs=%COMMIT%
        config hookie.core.web.browse = https://fisheye.example.com/browse/%REPO%

The following core keys are used by the framework:

* **hookie.core.allowedplugins** - comma separated list of plugins that are run for this repo - by default NO plugins get run.
* **hookie.core.repo.name** - set the name of the repository used when generating URLs or for display purposes. Normally it can be determined from the path and the key isn't required
* **hookie.core.web.browse** - URL to a web based repo browser. The special variable %REPO% will be replaced with the repo name.
* **hookie.core.web.commit** - URL to a web based view of a single commit. The special variables %REPO% and %COMMIT% will be replaced with the repo name and commit id respectively.
* **hookie.core.web.proxy** - optional proxy to use when making HTTP calls in plugins (example syntax: "proxy.example.com:8080")

## Plugins

The following plugins are shipped with Hookie:

* HipChat - posts a notification to a HipChat room in response to a commit
* Jenkins - triggers a Jenkins build in reponse to a commit

### HipChat

The following config keys apply to the HipChat plugin:

* **hookie.hipchat.apikey** - your HipChat API key
* **hookie.hipchat.room** - the HipChat room to post your message to - you can get a list of rooms using the following API call:
    http://api.hipchat.com/v1/rooms/list?auth_token=YOUR_TOKEN
* **hookie.hipchat.from** - who the notification appears from (default: git)
* **hookie.hipchat.notify** - set to 1 to trigger a notification (default: 0)

### Jenkins

The following config keys apply to the Jenkins plugin:

* **hookie.jenkins.url** - the trigger URL to be called for this repostiory (you should set this per-repository)
* **hookie.jenkins.branches** - only trigger a build if the change set includes commits to the branches in this list. Comma separated. Default is to build for any commit.
* **hookie.jenkins.auth** - the username:token combo to use to authenticate with Jenkins

## Writing Plugins

Hookie was designed to be extensible by writing your own plugins.

A minimal plugin is:

    require 'hookie/plugins/base_plugin'

    module Hookie
      module Plugin
        class EmptyPlugin < BasePlugin
          def post_receive
            log "Empty Plugin - post_receive"
          end
        end
      end
    end

BasePlugin provides useful instance variables such as config and framework.config is a symbol keyed hash of your plugins config. By convention your config key is the lowercased first part of your plugin name (eg. EmptyPlugin -> empty), so config keys are, for example, hookie.empty.blah

Your plugin will be called if it has a method matching the name of the hook being run (eg. "post_receive" above).  See the HipChat and Jenkins plugins for vaguely more complex examples.
