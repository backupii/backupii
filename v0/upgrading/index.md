---
layout: main
title: Upgrading
---

Upgrading Backup v3 to BackupII v0
==================================

In order to upgrade to BackupII from the old version of Backup, you need to
first upgrade to Backup v4.x, by following the [backup-upgrade] documentation.

It's recommended you update to the latest Backup v3.x release first, or be sure you
understand the changes since your current release.

Upgrading Backup v4/v5 to BackupII v0
=====================================

BackupII is a fork of the last release of Backup v5.0.0.beta.1, so BackupII v0.x
should be a close to a drop-in replacement for Backup v4.x or v5.x.

The following changes are required to make your Backup 4/5 config work with
BackupII:

- The binary was renamed to `backupii`. Any script refering to `backup` should
  be changed to use the new name. Performing a backup is now done with `backupii
  perform -t model`
- The default config path has changed from `~/Backup` to `~/.backupii`. If you
  were relying on the previous default config path, you'll need to either rename
  the folder or specify the config file path when invoking `backupii`. Example:
  `backupii check --config-file=~/Backup/config.rb`
- The configuration file needs to have the magic comment `#
  backupii_config_version: 0` somewhere. Although not mandatory, the `# Backup
  v5.x Configuration` comment should probably be updated to `# BackupII v0.x
  Configuration`

[backup-upgrade]: https://backup.github.io/backup/v4/upgrading/

{% include markdown_links %}
