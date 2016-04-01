include ::voxpupuliarchive

voxpupuliarchive { '/tmp/test.zip':
  source => 'file:///vagrant/files/test.zip',
}

voxpupuliarchive { '/tmp/test2.zip':
  source => '/vagrant/files/test.zip',
}

# NOTE: expected to fail
voxpupuliarchive { '/tmp/test3.zip':
  source => '/vagrant/files/invalid.zip',
}
