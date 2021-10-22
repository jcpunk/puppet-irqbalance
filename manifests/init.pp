class irqbalance (
  Boolean $package_manage = true,
  String $package_ensure = 'installed',
  String $package_name = 'irqbalance',
  String $service_name = 'irqbalance.service',
  Stdlib::Ensure::Service $service_ensure = 'running',
  Boolean $service_enable = true,
  Boolean $oneshot = false,
  Enum['exact','subset','ignore'] $hintpolicy = 'ignore',
  Optional[Integer] $powerthresh = undef,
  Optional[Array[Integer]] $ban_irq = [],
  Optional[Array[Pattern[/^[0-9a-fA-F]+$/]]] $ban_cpu = [],
  Optional[Integer[0,3]] $deepestcache = undef,
  Optional[Stdlib::Absolutepath] $policyscript = undef,
  Optional[String] $extra_args = undef,
) {

  if $package_manage {
    package { $package_name:
      ensure => $package_ensure,
      notify => Systemd::Unit_file[$service_name],
    }
  }

  if $service_ensure == 'running' {
    $unitfile_active = true
  } else {
    $unitfile_active = false
  }

  systemd::unit_file { $service_name:
    path   => '/usr/lib/systemd/system',
    enable => $service_enable,
    active => $unitfile_active,
  }

  $dropin_params = {
    'oneshot' => $oneshot,
  }

  systemd::dropin_file { 'puppet.conf':
    unit           => $service_name,
    content        => epp('irqbalance/etc/systemd/system/irqbalance.service.d/puppet.conf.epp', $dropin_params),
    notify_service => true,
  }

  $sysconfig_params = {
    'oneshot'      => $oneshot,
    'hintpolicy'   => $hintpolicy,
    'powerthresh'  => $powerthresh,
    'ban_irq'      => $ban_irq,
    'ban_cpu'      => $ban_cpu,
    'deepestcache' => $deepestcache,
    'policyscript' => $policyscript,
    'extra_args'   => $extra_args,
  }

  file {'/etc/sysconfig/irqbalance':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('irqbalance/etc/sysconfig/irqbalance.epp', $sysconfig_params),
    notify  => Systemd::Unit_file[$service_name],
  }
}
