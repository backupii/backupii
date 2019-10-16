---
layout: main
title: Installation
---

Installation
============

BackupII is distributed using [RubyGems](https://rubygems.org) and supports
[Ruby](https://www.ruby-lang.org) versions `2.3.0+`, `2.4.0+` and `2.5.0+`.
Older versions (>= `2.0.0`) might work but aren't tested.

To install the pre-release version, run:

    $ gem install --pre backupii

This will install BackupII, along with all of it's required dependencies.

See [Release Notes][release-notes] for changes in the latest version.

If you're upgrading from Backup v3.x, see [Upgrading][upgrading].

### Using Bundler

**Do not add `gem backupii` to another application's Gemfile.**
This means you **should not add BackupII to a Rails** application's Gemfile.
BackupII is not a _gem library_ and should not be treated as a _dependency_ of
another application. Bundler _can_ be used to manage an installation of BackupII,
but the reasons for why you might want to do this is beyond the scope of this
document.

See also [this issue](https://github.com/meskyanichi/backup/issues/635) for
more information.

### Using sudo

The `gem` commands shown here may need to be run using `sudo`, depending on how
Ruby is installed on your system. If you're using [RVM][], [rbenv][] or
[chruby][], then you would most likely _not_ want to use `sudo`. However, if
your installation of Ruby came with your system, or was installed using your
system's package manager (yum, apt, etc...), then you most likely need to use
`sudo`. For example, running `gem install backupii` as a non-root user with a
system installed Ruby would install Backup only for that user's use. This may or
may not be what you want.

Updating
========

To update BackupII to the latest version, run:

    $ gem install backupii

Changes in the latest version may be found on the [Release Notes][release-notes] page.

If you wish to install a specific version of BackupII, you can specify the version as follows:

    # Install version 0.1.0
    $ gem install backupii -v '0.1.0'

    # Install the latest 0.1.x version
    $ gem install backupii -v '~> 0.1.0'

    # Install the latest 0.x version
    $ gem install backupii -v '~> 0.0'

When you update BackupII, the new version of the BackupII gem will be installed,
but older versions are not removed. If you were to install BackupII at version
`0.1.1`, then update to `0.2.0`, both will exist on your system.

    $ gem list backupii

    *** LOCAL GEMS ***

    backupii (0.1.0, 0.2.0)

The same is true for any of BackupII's gem dependencies. This is normal and how
the RubyGems system works. When you run `backupii` it will always load the latest
version.

    $ backupii version
    Backup 0.2.0

You can clean up old versions using `gem cleanup`.

    $ gem cleanup backup
    Cleaning up installed gems...
    Attempting to uninstall backupii-0.1.0
    Successfully uninstalled backupii-0.1.0
    Clean Up Complete

`gem cleanup` may be used to remove old versions of BackupII's dependencies as well.


[RVM]: https://rvm.io/
[rbenv]: https://github.com/sstephenson/rbenv/
[chruby]: https://github.com/postmodern/chruby

{% include markdown_links %}
