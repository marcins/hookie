# Hookie

Hookie is a pluggable framework for creating git hooks using Ruby. It was
originally designed for writing hooks for gitolite, but should work for any
hooks, including local ones.

## Installation

Install the gem on your git server

    gem install hookie

To add a post-receive hook, in your ~git/repositories/REPO/hooks directory
create a file called post-receive with the contents:

    #!/bin/sh
    hookie post_receive

Make sure this file is executable.

Note that by itself this won't cause any plugins to run, they either need to be
configured first.

## Base Configuration

Hookie was written such that it can be configured using Gitolite's ability to
set git config keys via the gitolite-admin repository.

The following core keys are used by the framework:

* **hookie.core.allowedplugins** - comma separated list of plugins that are run
  for this repo
* **hookie.core.repo.name** - set the name of the repository used when
  generating URLs or for display purposes. Normally it can be determined from
  the path.
* **hookie.core.web.browse** - URL to a web based repo browser. The special
  variable %REPO% will be replaced with the repo name.
* **hookie.core.web.commit** - URL to a web based view of a single commit. The
  special variables %REPO% and %COMMIT% will be replaced with the repo name and
  commit id respectively.
* **hookie.core.web.proxy** - optional proxy to use when making HTTP calls in
  plugins (example syntax: "proxy.example.com:8080")

## Plugins

The following plugins are shipped with Hookie:

* HipChat - posts a notification to a HipChat room in response to a commit
* Jenkins - triggers a Jenkins build in reponse to a commit

### HipChat

The following config keys apply to the HipChat plugin:

* **hookie.hipchat.apikey** - your HipChat API key
* **hookie.hipchat.room** - the HipChat room to post your message to - you can get
    a list of rooms using the following API call:
    http://api.hipchat.com/v1/rooms/list?auth_token=YOUR_TOKEN
* **hookie.hipchat.from** - who the notification appears from (default: git)
* **hookie.hipchat.notify** - set to 1 to trigger a notification (default: 0)


## Writing Plugins

A minimal plugin is:

    require_relative "base_plugin"

    module Hookie
      module Plugin
        class EmptyPlugin < BasePlugin
          def post_receive
            log "Empty Plugin - post_receive"
          end
        end
      end
    end

BasePlugin provides useful instance variables such as config and framework.
config is a symbol keyed hash of your plugins config. By convention your 
config key is the lowercased first part of your plugin name (eg. EmptyPlugin ->
empty), so config keys are, for example, hookie.empty.blah
