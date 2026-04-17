# Changelog

All notable changes to this project will be documented in this file.

## Release 2.0.1

**Bug Fixes**

- Drop `hintpolicy` since it is obsolete

## Release 2.0.0

**Bug Fixes**

- Arguments via sysconfig now actually passed

**Features**

- Use `ban_cpu_list` to block CPUs
- Use `systemd::manage_dropin` to define dropins
- Default to `-j` for logging
- Now able to set `migrateval`
- Now able to set `interval`

**Breaking Changes**

- Raise minimum puppet to 8.0.0, older versions may still work
- Raise minimum puppet-systemd to 8.0.0
- `ban_cpu` arg removed
- NOTE: Changes in this module will cause irqbalance.service to be restarted


## Release 1.1.0

**Features**

- Add support for `--banmod`

## Release 1.0.7

**Features**

- Note puppet-systemd 8.0.0 compatibility

## Release 1.0.6

**Features**

- Note puppet-systemd 7.0.0 compatibility

## Release 1.0.5

**Features**

- Note puppet/systemd 6.0.0 compatibility

## Release 1.0.4

**Features**

- Note puppet8 compatibility

## Release 1.0.3

**Features**

- Note compatibility with puppet/systemd 4.x.x

## Release 1.0.2

**Features**

**Bugfixes**

- Fix facter 3.x compatibility

**Known Issues**

## Release 1.0.1

**Features**

**Bugfixes**

- Don't try to start on systems with one core

**Known Issues**

## Release 1.0.0

**Features**

- Fully utilizing puppet-systemd defined types

**Bugfixes**

**Known Issues**
