# Hookie

Hookie is a pluggable framework for creating git hooks using Ruby. It was originally designed for writing hooks for gitolite, but should work for any hooks, including local ones.

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

The idea is that you install hookie as a post_receive hook for all your repositories, but configuration determines when the hook is actually run. To install for all repositories you add it to the hooks/ directory inside your gitolite-admin repository.

### Installing hooks manually

You can also install hookie hooks manually, by adding them to the hooks directory within your repository

Make sure this file is executable.

Note that by itself this won't cause any plugins to run, they either need to be configured first.

## Configuration

Hookie was written such that it can be configured using Gitolite's ability to set git config keys via the gitolite-admin repository.

You can set "global" config keys using the special repository @all in gitolite, and override or set project specific keys within the repository itself. This makes it easy to, for example, set your HipChat API key for all repos, but then set the room that gets notified in each repo separately - and this can all be done via the gitolite-admin repository, without requiring access to the git server.

The following core keys are used by the framework:

* **hookie.core.allowedplugins** - comma separated list of plugins that are run for this repo - by default NO plugins get run.
* **hookie.core.repo.name** - set the name of the repository used when generating URLs or for display purposes. Normally it can be determined from the path.
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
