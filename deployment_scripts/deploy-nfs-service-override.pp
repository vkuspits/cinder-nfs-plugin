notice('MODULAR: nfs-service.pp')


$nfs_plugin    = hiera('nfs-service', {})
$metadata      = pick($nfs_plugin['metadata'], {})
$data_folder   = $metadata['nfs-share-dir']
$network       = hiera('network_metadata', {})
$storage_net   = $network['storage']

$hiera_dir     = '/etc/hiera/override'
$plugin_yaml   = 'nfs-service.yaml'
$plugin_name   = 'nfs-service'
$role          = hiera('role', 'none')

if $metadata['enabled'] {
  $corosync_roles=['nfs-service']
  $content = inline_template('
corosync_roles:
<%
@corosync_roles.each do |crole|
%>  - <%= crole %>
<% end -%>
')

  file { '/etc/hiera/override':
    ensure  => directory,
  }

  file { "${hiera_dir}/${plugin_yaml}":
    ensure  => file,
    content => $content,
    require => File['/etc/hiera/override'],
  }

  file_line {"${plugin_name}_hiera_override":
    path  => '/etc/hiera.yaml',
    line  => "  - override/${plugin_name}",
    after => '  - override/module/%{calling_module}',
  }
  
  module {'haraldsk-nfs':
    ensure => present,
  }
  
  node server {
    include nfs::server
    nfs::server::export{ '/$data_folder':
       ensure  => 'mounted',
       clients => '${storage_net}(rw,insecure,async,no_root_squash) localhost(rw)'
    }
    require => Module['haraldsk-nfs'],
  }  
}
