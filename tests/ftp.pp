include '::voxpupuliarchive'

voxpupuliarchive { '/tmp/test100k.db':
  source   => 'ftp://ftp.otenet.gr/test100k.db',
  username => 'speedtest',
  password => 'speedtest',
}
