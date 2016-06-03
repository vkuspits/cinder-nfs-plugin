class nfs { 
  package {'nfs-kernel-server':
    ensure => installed
  } 
  
  file {'nfs':
    ensure => directory,
    path => '/var/nfs',
    owner => nobody,
    group => nogroup,
    mode => 777
  } 
  
  file_line {'/etc/exports'
    ensure => present,
    line => '/var/nfs   0.0.0.0(rw,sync,no_subtree_check)',
    path => '/etc/exports'
  } 
  
  exec { 'update_nfs_exports':
    command     => 'exportfs -ra',
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    refreshonly => true
  } 
  
  service {'nfs-server':
    name => 'nfs-kernel-server',
    ensure => running,
    enable => true
  }
}
