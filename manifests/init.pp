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

  include systemd::systemctl::daemon_reload

  if $package_manage {
    package { $package_name:
      ensure => $package_ensure,
      notify => Service[$service_name],
      before => Service[$service_name],
    }
  }

  if $service_ensure == 'running' or $service_enable {
    file {"/usr/lib/systemd/system/${service_name}":
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }

    file {"/usr/lib/systemd/system/${service_name}.d":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file {"/usr/lib/systemd/system/${service_name}.d/puppet.conf":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('irqbalance/usr/lib/systemd/system/irqbalance.service.d/puppet.conf.epp'),
      notify  => [ Class['systemd::systemctl::daemon_reload'], Service[$service_name] ],
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
      notify  => Service[$service_name],
    }
  }

  service { $service_name:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}

