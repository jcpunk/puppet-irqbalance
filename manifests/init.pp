# @summary Manages the irqbalance daemon, which distributes hardware interrupts
#   across CPUs on SMP systems to improve performance.
#
# @example Minimal — accept all defaults
#   include irqbalance
#
# @example Pin specific IRQs and exclude CPUs from balancing
#   class { 'irqbalance':
#     ban_irq      => [24, 25],
#     ban_cpu_list => ['0', '56-63'],
#   }
#
# @example One-shot rebalancing at boot only
#   class { 'irqbalance':
#     oneshot => true,
#   }
#
# @param package_manage
#   Whether this module should manage the irqbalance package. Set to false if
#   package installation is handled externally (e.g. a base image or another module).
#
# @param package_ensure
#   The ensure value passed to the package resource. Use 'latest' to track updates
#   or a specific version string to pin the package.
#
# @param package_name
#   The name of the irqbalance package as it appears in the distribution repository.
#
# @param service_name
#   The systemd service unit name. Override if the unit is named differently on a
#   non-standard installation.
#
# @param service_ensure
#   The desired state of the irqbalance service. Accepts 'running' or 'stopped'.
#
# @param service_enable
#   Whether the irqbalance service should be enabled to start on boot.
#
# @param irqbalance_binary
#   Absolute path to the irqbalance executable. Override if irqbalance is installed
#   outside the standard system paths (e.g. via Spack or a custom prefix).
#
# @param irqbalance_env_file
#   Absolute path to the environment file read by the systemd service unit. This
#   file is fully managed by Puppet; manual edits will be overwritten.
#
# @param oneshot
#   When true, irqbalance performs a single rebalancing pass at startup then exits.
#   Useful for systems where interrupt affinity should be set once at boot rather
#   than continuously adjusted. Equivalent to --oneshot.
#
# @param hintpolicy
#   Controls how irqbalance interprets IRQ locality hints from device drivers.
#   'exact' places the IRQ on the exact CPU indicated by the hint, 'subset' places
#   it on a CPU within the hinted set, and 'ignore' disregards hints entirely.
#   Equivalent to --hintpolicy.
#
# @param powerthresh
#   Number of CPUs below which irqbalance will consolidate interrupts onto fewer
#   CPUs to reduce power consumption. When undef, the irqbalance default applies.
#   Equivalent to --powerthresh.
#
# @param ban_irq
#   List of IRQ numbers irqbalance should never assign to any CPU.
#   Equivalent to passing one --banirq flag per entry.
#
# @param ban_mod
#   List of kernel module names whose IRQs irqbalance should never rebalance.
#   Equivalent to passing one --banmod flag per entry.
#
# @param ban_cpu_list
#   List of CPU numbers and ranges to exclude from interrupt balancing, expressed
#   as strings (e.g. ['0', '6-11', '56-63']). Sets IRQBALANCE_BANNED_CPULIST in
#   the environment file.
#
# @param deepestcache
#   Deepest cache level (0–3) at which irqbalance will attempt to group IRQs.
#   When undef, irqbalance uses its compiled-in default. Equivalent to --deepestcache.
#
# @param policyscript
#   Absolute path to a script irqbalance will call to determine the balancing
#   policy for each IRQ. When undef, no script is used. Equivalent to --policyscript.
#
# @param migrateval
#   Minimum load distribution improvement ratio required to trigger an IRQ
#   migration. Higher values require greater improvement (e.g. 2 requires 50%
#   improvement, 4 requires 25%). When undef, any improvement triggers migration.
#   Equivalent to --migrateval.
#
# @param interval
#   Seconds between irq load samples. When undef, irqbalance defaults to 10.
#   Equivalent to --interval.
#
# @param extra_args
#   Additional command-line flags passed verbatim to irqbalance. Each array
#   element is appended as a separate argument.
class irqbalance (
  Boolean $package_manage = true,
  String $package_ensure = 'installed',
  String $package_name = 'irqbalance',
  String $service_name = 'irqbalance.service',
  Stdlib::Ensure::Service $service_ensure = 'running',
  Stdlib::Absolutepath $irqbalance_binary = '/usr/sbin/irqbalance',
  Stdlib::Absolutepath $irqbalance_env_file = '/etc/sysconfig/irqbalance',
  Boolean $service_enable = true,
  Boolean $oneshot = false,
  Enum['exact','subset','ignore'] $hintpolicy = 'ignore',
  Array[Integer] $ban_irq = [],
  Array[String] $ban_mod = [],
  Array[Pattern[/^\d+(-\d+)?$/]] $ban_cpu_list   = [],
  Array[String] $extra_args = ['-j'],
  Optional[Integer] $powerthresh = undef,
  Optional[Integer[0,3]] $deepestcache = undef,
  Optional[Stdlib::Absolutepath] $policyscript = undef,
  Optional[Integer[1]] $migrateval = undef,
  Optional[Integer[1]] $interval   = undef,
) {
  if $package_manage {
    package { $package_name:
      ensure => $package_ensure,
      notify => Service[$service_name],
    }
  }

  if $service_ensure == 'running' {
    $_service_enable = true
  } else {
    $_service_enable = false
  }

  if $facts['processors']['count'] < 2 {
    # systems with 1c/1t can't run irqbalance
    # it is part of the internal logic of the binary itself
    service { $service_name:
      ensure => 'stopped',
      enable => false,
    }
  } else {
    service { $service_name:
      ensure => $service_ensure,
      enable => $_service_enable,
    }
  }

  if $oneshot {
    systemd::manage_dropin { 'puppet-oneshot.conf':
      ensure        => 'present',
      unit          => $service_name,
      service_entry => {
        'Type'            => 'oneshot',
        'RemainAfterExit' => true,
      },
    }
  } else {
    systemd::manage_dropin { 'puppet-oneshot.conf':
      ensure => 'absent',
      unit   => $service_name,
    }
  }

  systemd::manage_dropin { 'puppet.conf':
    ensure        => 'present',
    unit          => $service_name,
    service_entry => {
      'EnvironmentFile' => $irqbalance_env_file,
      'ExecStart'       => [
        '',
        "${irqbalance_binary} --foreground \$IRQBALANCE_ARGS",
      ],
    },
  }

  $sysconfig_params = {
    'oneshot'      => $oneshot,
    'hintpolicy'   => $hintpolicy,
    'powerthresh'  => $powerthresh,
    'ban_irq'      => $ban_irq,
    'ban_mod'      => $ban_mod,
    'ban_cpu_list' => $ban_cpu_list,
    'deepestcache' => $deepestcache,
    'policyscript' => $policyscript,
    'migrateval'   => $migrateval,
    'interval'     => $interval,
    'extra_args'   => $extra_args,
  }

  file { '/etc/sysconfig/irqbalance':
    ensure  => 'file',
    path    => $irqbalance_env_file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('irqbalance/etc/sysconfig/irqbalance.epp', $sysconfig_params),
    notify  => Service[$service_name],
  }
}
