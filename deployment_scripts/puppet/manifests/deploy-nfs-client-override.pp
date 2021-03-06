notice('MODULAR: nfs-client-cinder.pp')

$nodes              = hiera('nodes', {})
$nfs_plugin_data    = hiera('nfs-service', {})
$cinder_nfs_share   = '/etc/cinder/nfs_shares.txt'

$nfs_service_name   = 'nfs'

#path to nfs folder on cinder server
$nfs_mount_point    = $nfs_plugin_data['nfs_mount_point']

#path to nfs folder on nfs server
$nfs_share       = $nfs_plugin_data['nfs_share']

#$nfs_mount_options = $nfs_plugin_data['nfs_mount_options']


#get storage IP of NFS
define nfs_server_ip {
  if $name['role'] == 'nfs-service' {
    file_line { "nfs_line${name['uid']}":
      line => "${name['storage_address']}:${nfs_share}",
      path => $cinder_nfs_share,
    }
  }
}

if $::osfamily == 'Debian' {
  $required_packages = [ 'nfs-common', 'cinder-volume' ]
  $service_name      = 'cinder-volume'

  package { $required_packages:
    ensure => present,
  }

  service { $service_name:
    ensure      => running,
    provider    => upstart,
    hasrestart  => true,
    hasstatus   => false,
    restart     => 'service cinder-volume restart',
  }

  file { $cinder_nfs_share:
    ensure => present,
    owner  => 'cinder',
    group  => 'cinder',
    force  => true,
    notify => Service['cinder-volume'],
  }

  file { $nfs_mount_point:
    ensure => 'directory',
    mode   => '0755',
    owner  => 'cinder',
    group  => 'cinder',
  }

#cinder config
#openstack/cinder module installation required
  cinder_config {
    'DEFAULT/volume_driver' :
      value => 'cinder.volume.drivers.nfs.NfsDriver';
    'DEFAULT/nfs_shares_config' :
      value => $cinder_nfs_share;
    'DEFAULT/nfs_oversub_ratio' :
      value => '1.0';
    'DEFAULT/nfs_used_ratio' :
      value => '0.95';
    "${nfs_service_name}/nfs_mount_attempts" :
      value => '3';
    'DEFAULT/nfs_sparsed_volumes' :
      value => true;
    'DEFAULT/nfs_mount_point_base' :
      value => $nfs_mount_point;
    'DEFAULT/default_volume_type' :
      value => $nfs_service_name;
    'DEFAULT/volume_backend_name' :
      value => $nfs_service_name;
    'DEFAULT/enabled_backends' :
      value => $nfs_service_name;
  }

  nfs_server_ip { $nodes: }

}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

