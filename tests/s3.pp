class { '::voxpupuliarchive':
  aws_cli_install => true,
}

voxpupuliarchive { '/tmp/gravatar.png':
  ensure => present,
  source => 's3://bodecoio/gravatar.png',
}
