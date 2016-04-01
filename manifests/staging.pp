# Class: voxpupuliarchive::staging
# =======================
#
# backwards compatibility class for staging module.
#
class voxpupuliarchive::staging (
  $path  = $voxpupuliarchive::params::path,
  $owner = $voxpupuliarchive::params::owner,
  $group = $voxpupuliarchive::params::group,
  $mode  = $voxpupuliarchive::params::mode,
) inherits voxpupuliarchive::params {
  include '::voxpupuliarchive'

  if !defined(File[$path]) {
    file { $path:
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
  }
}
