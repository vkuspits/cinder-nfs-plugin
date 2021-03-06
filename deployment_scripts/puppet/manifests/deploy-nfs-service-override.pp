notice('MODULAR: nfs-service.pp')


$nfs_plugin_data = hiera('nfs-service', {})
$nfs_share = $nfs_plugin_data['nfs_share']
if $::osfamily == 'Debian' {
  $required_packages = [ 'rpcbind', 'nfs-kernel-server' ]
  $services_name = 'nfs-kernel-server'

  package { $required_packages:
    ensure => present,
  }

  file { '/opt/${nfs_share}':
    ensure => 'directory',
    owner  => 'nobody',
    group  => 'nogroup',
    mode   => '0777',
  }

  firewall { '150 allow tcp access to nfs service':
    dport  => [111, 2049],
    proto  => ['tcp', 'udp'],
    action => accept,
  }

  service { $services_name:
    ensure => running,
    enable => true,
  }

  file { '/etc/exports':
    content => "${nfs_share} ${::network_br_storage}/${::netmask_br_storage}(rw,sync,no_subtree_check)",
    notify  => Service[$services_name]
  }

  exec { 'update_nfs_exports':
      command     => 'exportfs -ra',
      path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      refreshonly => true,
    }
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}
