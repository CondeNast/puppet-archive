# Define: voxpupuliarchive::artifactory
# ============================
#
# voxpupuliarchive wrapper for downloading files from artifactory
#
# Parameters
# ----------
#
# * path: fully qualified filepath for the download the file or use voxpupuliarchive_path and only supply filename. (namevar).
# * ensure: ensure the file is present/absent.
# * url: artifactory download url filepath. NOTE: replaces server, port, url_path parameters.
# * server: artifactory server name (deprecated).
# * port: artifactory server port (deprecated).
# * url_path: artifactory file path http:://{server}:{port}/artifactory/{url_path} (deprecated).
# * owner: file owner (see voxpupuliarchive params for defaults).
# * group: file group (see voxpupuliarchive params for defaults).
# * mode: file mode (see voxpupuliarchive params for defaults).
# * voxpupuliarchive_path: the parent directory of local filepath.
# * extract: whether to extract the files (true/false).
# * creates: the file created when the voxpupuliarchive is extracted (true/false).
# * cleanup: remove voxpupuliarchive file after file extraction (true/false).
#
# Examples
# --------
#
# voxpupuliarchive::artifactory { '/tmp/logo.png':
#   url   => 'https://repo.jfrog.org/artifactory/distributions/images/Artifactory_120x75.png',
#   owner => 'root',
#   group => 'root',
#   mode  => '0644',
# }
#
# $dirname = 'gradle-1.0-milestone-4-20110723151213+0300'
# $filename = "${dirname}-bin.zip"
#
# voxpupuliarchive::artifactory { $filename:
#   voxpupuliarchive_path => '/tmp',
#   url          => "http://repo.jfrog.org/artifactory/distributions/org/gradle/${filename}",
#   extract      => true,
#   extract_path => '/opt',
#   creates      => "/opt/${dirname}",
#   cleanup      => true,
# }
#
define voxpupuliarchive::artifactory (
  $path         = $name,
  $ensure       = present,
  $url          = undef,
  $server       = undef,
  $port         = undef,
  $url_path     = undef,
  $owner        = undef,
  $group        = undef,
  $mode         = undef,
  $voxpupuliarchive_path = undef,
  $extract      = undef,
  $extract_path = undef,
  $creates      = undef,
  $cleanup      = undef,
) {

  include ::voxpupuliarchive::params

  if $voxpupuliarchive_path {
    $file_path = "${voxpupuliarchive_path}/${name}"
  } else {
    $file_path = $path
  }

  validate_absolute_path($file_path)

  if $url {
    $file_url = $url
    $sha1_url = regsubst($url, '/artifactory/', '/artifactory/api/storage/')
  } elsif $server and $port and $url_path {
    warning('voxpupuliarchive::artifactory attribute: server, port, url_path are deprecated')
    $art_url = "http://${server}:${port}/artifactory"
    $file_url = "${art_url}/${url_path}"
    $sha1_url = "${art_url}/api/storage/${url_path}"
  } else {
    fail('Please provide fully qualified url path for artifactory file.')
  }

  voxpupuliarchive { $file_path:
    ensure        => $ensure,
    path          => $file_path,
    extract       => $extract,
    extract_path  => $extract_path,
    source        => $file_url,
    checksum      => artifactory_sha1($sha1_url),
    checksum_type => 'sha1',
    creates       => $creates,
    cleanup       => $cleanup,
  }

  $file_owner = pick($owner, $voxpupuliarchive::params::owner)
  $file_group = pick($group, $voxpupuliarchive::params::group)
  $file_mode  = pick($mode, $voxpupuliarchive::params::mode)

  file { $file_path:
    owner   => $file_owner,
    group   => $file_group,
    mode    => $file_mode,
    require => voxpupuliArchive[$file_path],
  }
}
