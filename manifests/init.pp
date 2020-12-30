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
  Optional[Array[Regexp[^[0-9a-fA-F]+$]]] $ban_cpu = [],  #this is a special format for hex, no leading 0x
  Optional[Integer[0,3]] $deepestcache = undef,
  Optional[Stdlib::Absolutepath] $policyscript = undef,
  Optional[String] $extra_args = undef,
) {

  if $package_manage {
    package { $package_name:
      ensure => $package_ensure,
      notify => Service[$service_name],
      before => Service[$service_name],
    }
  }

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
    content => ,
    notify  => Service[$service_name],
  }

  file {'/etc/sysconfig/irqbalance':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => ,
    notify  => Service[$service_name],
  }

  service { $service_name:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
