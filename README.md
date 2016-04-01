CondeNast fork note: This is a fork as of 5e457c5af67681bfbcbd3d6bd3b58d06cd71f80d of voxpupuli/puppet-voxpupuliarchive. The fork's purpose is to allow us to have both camptocamp/puppet-voxpupuliarchive and voxpupli/puppet-voxpupuliarchive available to us, as Jenkins, for one, depends on the former, and consul, for another, depends on the latter.

In order to not conflict with camptocamp, references to the keyword 'voxpupuliarchive' in this module will be changed to voxpupulivoxpupuliarchive. To utilize this with puppet modules that depend on voxpupuli/puppet-voxpupuliarchive, please fork those into /CondeNast, and then change references within those puppet modules.

As necessary, pulls from upstream will be done in case of necessary voxpupuli/puppet-voxpupuliarchive module updates.

# Puppet voxpupuliArchive

[![Puppet Forge](http://img.shields.io/puppetforge/v/puppet/voxpupuliarchive.svg)](https://forge.puppetlabs.com/puppet/voxpupuliarchive)
[![Puppet Forge downloads](https://img.shields.io/puppetforge/dt/puppet/voxpupuliarchive.svg)](https://forge.puppetlabs.com/puppet/voxpupuliarchive)
[![Puppet Forge score](https://img.shields.io/puppetforge/f/puppet/voxpupuliarchive.svg)](https://forge.puppetlabs.com/puppet/voxpupuliarchive)
[![Build Status](https://travis-ci.org/voxpupuli/puppet-voxpupuliarchive.png)](https://travis-ci.org/voxpupuli/puppet-voxpupuliarchive)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
4. [Usage](#usage)
   * [Example](#usage-example)
   * [File permission](#file-permission)
   * [Network files](#network-files)
   * [Extract customization](#extract-customization)
   * [S3 Bucket](#s3-bucket)
5. [Reference](#reference)
6. [Development](#development)

_*Warning*_:

Release 0.5.x contains significant changes:

* faraday, faraday_middleware no longer required.
* ruby provider is the default for windows (using net::http).
* voxpupuliarchive gem_provider attribute deprecated.
* voxpupuliarchive::artifactory server, port, url_path attributes deprecated.
* S3 bucket support (experimental).

Release 0.3.x contains breaking changes

* The parameter 7zip have been changed to seven_zip to conform to Puppet 4.x variable name requirements.
* The namevar name have been changed to path to allow files with the same filename to exists in different filepath.
* This project have been migrated to [voxpupuli](https://github.com/voxpupuli/puppet-voxpupuliarchive), please adjust your repo git source.

_*Experimental*_:

The following define type/features are experimental and subject to change:

* voxpupuliarchive::artifactory
* voxpupuliarchive::go
* voxpupuliarchive::nexus
* checksum_url (to support nexus files)

## Overview

This module manages download, deployment, and cleanup of voxpupuliarchive files.

## Module Description

This module uses types and providers to download and manage compress files,
with optional lifecycle functionality such as checksum, extraction, and
cleanup. The benefits over existing modules such as
[puppet-staging](https://github.com/voxpupoli/puppet-staging):

* Implemented via types and provider instead of exec resource.
* Follows 302 redirect and propagate download failure.
* Optional checksum verification of voxpupuliarchive files.
* Automatic dependency to parent directory.
* Support Windows file extraction via 7zip.
* Able to cleanup voxpupuliarchive files after extraction.

## Setup

The module requires 7zip for windows clients which is installed via `include
'::voxpupuliarchive'`. On posix systems, curl is the default provider. The default
provider can be overwritten by configuring resource defaults in site.pp:

```puppet
voxpupuliArchive {
  provider => 'ruby',
}
```

Users of the module is responsbile for voxpupuliarchive package dependencies for
alternative providers and all extraction utilities such as tar, gunzip, bunzip:

```puppet
if $::facts['osfamily'] != 'windows' {
  package { 'wget':
    ensure => present,
  }

  package { 'bunzip':
    ensure => present,
  }

  voxpupuliArchive {
    provider => 'wget',
    require  => Package['wget', 'bunzip'],
  }
}
```

## Usage

voxpupuliArchive module dependency is managed by the voxpupuliarchive class. This is only
required for windows platform. By default 7zip is installed via chocolatey, but
can be adjusted to use the msi package instead:

```puppet
class { 'voxpupuliarchive':
  seven_zip_name     => '7-Zip 9.20 (x64 edition)',
  seven_zip_source   => 'C:/Windows/Temp/7z920-x64.msi',
  seven_zip_provider => 'windows',
}
```

### Usage Example

```puppet
include '::voxpupuliarchive' # NOTE: optional for posix platforms

voxpupuliarchive { '/tmp/jta-1.1.jar':
  ensure        => present,
  extract       => true,
  extract_path  => '/tmp',
  source        => 'http://central.maven.org/maven2/javax/transaction/jta/1.1/jta-1.1.jar',
  checksum      => '2ca09f0b36ca7d71b762e14ea2ff09d5eac57558',
  checksum_type => 'sha1',
  creates       => '/tmp/javax',
  cleanup       => true,
}

voxpupuliarchive { '/tmp/test100k.db':
  source   => 'ftp://ftp.otenet.gr/test100k.db',
  username => 'speedtest',
  password => 'speedtest',
}
```

### File permission

When extracting files as non-root user, either ensure the target directory
exists with the appropriate permission (see [tomcat.pp](tests/tomcat.pp) for
full working example):

```puppet
$dirname = 'apache-tomcat-9.0.0.M3'
$filename = "${dirname}.zip"
$install_path = "/opt/${dirname}"

file { $install_path:
  ensure => directory,
  owner  => 'tomcat',
  group  => 'tomcat',
  mode   => '0755',
}

voxpupuliarchive { $filename:
  path          => "/tmp/${filename}",
  source        => 'http://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.0.M3/bin/apache-tomcat-9.0.0.M3.zip',
  checksum      => 'f2aaf16f5e421b97513c502c03c117fab6569076',
  checksum_type => 'sha1',
  extract       => true,
  extract_path  => '/opt',
  creates       => "${install_path}/bin",
  cleanup       => true,
  user          => 'tomcat',
  group         => 'tomcat',
  require       => File[$install_path],
}
```

or use an subscribing exec to chmod the directory afterwards:

```puppet
$dirname = 'apache-tomcat-9.0.0.M3'
$filename = "${dirname}.zip"
$install_path = "/opt/${dirname}"

file { '/opt/tomcat':
  ensure => 'link',
  target => $install_path
}

voxpupuliarchive { $filename:
  path          => "/tmp/${filename}",
  source        => "http://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.0.M3/bin/apache-tomcat-9.0.0.M3.zip",
  checksum      => 'f2aaf16f5e421b97513c502c03c117fab6569076',
  checksum_type => 'sha1',
  extract       => true,
  extract_path  => '/opt',
  creates       => $install_path,
  cleanup       => 'true',
  require       => File[$install_path],
}

exec { 'tomcat permission':
  command   => "chown tomcat:tomcat $install_path",
  path      => $::path,
  subscribe => voxpupuliArchive[$filename],
}
```

### Network files

For large binary files that needs to be extracted locally, instead of copying
the file from the network fileshare, simply set the file path to be the same as
the source and voxpupuliarchive will use the network file location:

```puppet
voxpupuliarchive { '/nfs/repo/software.zip':
  source        => '/nfs/repo/software.zip'
  extract       => true,
  extract_path  => '/opt',
  checksum_type => 'none', # typically unecessary
  cleanup       => false,  # keep the file on the server
}
```

### Extract Customization

The `extract_flag` or `extract_command` parameters can be used to override the
default extraction command/flag (defaults are specified in
[achive.rb](lib/puppet_x/bodeco/voxpupuliarchive.rb)).

```puppet
# tar striping directories:
voxpupuliarchive { '/var/lib/kafka/kafka_2.10-0.8.2.1.tgz':
  ensure          => present,
  extract         => true,
  extract_command => 'tar xfz %s --strip-components=1',
  extract_path    => '/opt/kafka_2.10-0.8.2.1',
  cleanup         => true,
  creates         => '/opt/kafka_2.10-0.8.2.1/config',
}

# zip freshen existing files (zip -of %s instead of zip -o %s):
voxpupuliarchive { '/var/lib/example.zip':
  extract      => true,
  extract_path => '/opt',
  extract_flag => '-of',
  cleanup      => true,
  subscribe    => ...,
}
```

### S3 bucket

S3 support is implemented via the [AWS
CLI](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).
By default this dependency is only installed for Linux VMs running on AWS, or
enabled via `aws_cli_install` option:

```puppet
class { '::voxpupuliarchive':
  aws_cli_install => true,
}

# See AWS cli guide for credential and configuration settings:
# http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
file { '/root/.aws/credential':
  ensure => file,
  ...
}

voxpupuliarchive { '/tmp/gravatar.png':
  ensure => present,
  source => 's3://bodecoio/gravatar.png',
}
```

NOTE: Alternative s3 provider support can be implemented by overriding the [s3_download method](lib/puppet/provider/voxpupuliarchive/ruby.rb):

## Reference

### Classes

* `voxpupuliarchive`: install 7zip package (Windows only) and aws cli for s3 support.
* `voxpupuliarchive::staging`: install package dependencies and creates staging directory for backwards compatibility. Use the voxpupuliarchive class instead if you do not need the staging directory.

### Define Resources

* `voxpupuliarchive::artifactory`: voxpupuliarchive wrapper for [JFrog Artifactory](http://www.jfrog.com/open-source/#os-arti) files with checksum.
* `voxpupuliarchive::go`: voxpupuliarchive wrapper for [GO Continuous Delivery](http://www.go.cd/) files with checksum.
* `voxpupuliarchive::nexus`: voxpupuliarchive wrapper for [Sonatype Nexus](http://www.sonatype.org/nexus/) files with checksum.

### Resources

#### voxpupuliArchive

* `ensure`: whether voxpupuliarchive file should be present/absent (default: present)
* `path`: namevar, voxpupuliarchive file fully qualified file path.
* `filename`: voxpupuliarchive file name (derived from path).
* `source`: voxpupuliarchive file source, supports http|https|ftp|file|s3 uri.
* `username`: username to download source file.
* `password`: password to download source file.
* `cookie`: voxpupuliarchive file download cookie.
* `checksum_type`: voxpupuliarchive file checksum type (none|md5|sha1|sha2|sh256|sha384|sha512). (default: none)
* `checksum`: voxpupuliarchive file checksum (match checksum_type)
* `checksum_url`: voxpupuliarchive file checksum source (instead of specify checksum)
* `checksum_verify`: whether checksum will be verified (true|false). (default: true)
* `extract`: whether voxpupuliarchive will be extracted after download (true|false). (default: false)
* `extract_path`: target folder path to extract voxpupuliarchive.
* `extract_command`: custom extraction command ('tar xvf example.tar.gz'), also support sprintf format ('tar xvf %s') which will be processed with the filename: sprintf('tar xvf %s', filename)
* `extract_flags`: custom extraction options, this replaces the default flags. A string such as 'xvf' for a tar file would replace the default xf flag. A hash is useful when custom flags are needed for different platforms. {'tar' => 'xzf', '7z' => 'x -aot'}.
* `user`: extract command user (using this option will configure the voxpupuliarchive file permission to 0644 so the user can read the file).
* `group`: extract command group (using this option will configure the voxpupuliarchive file permission to 0644 so the user can read the file).
* `cleanup`: whether voxpupuliarchive file will be removed after extraction (true|false). (default: true)
* `creates`: if file/directory exists, will not download/extract voxpupuliarchive.
* `proxy_server`: specify a proxy server, with port number if needed. ie: https://example.com:8080.
* `proxy_type`: proxy server type (none|http|https|ftp)

#### voxpupuliArchive::Artifactory

* `path`: fully qualified filepath for the download the file or use voxpupuliarchive_path and only supply filename. (namevar).
* `ensure`: ensure the file is present/absent.
* `url`: artifactory download url filepath. NOTE: replaces server, port, url_path parameters.
* `server`: artifactory server name (deprecated).
* `port`: artifactory server port (deprecated).
* `url_path`: artifactory file path http`:`://{server}`:{port}/artifactory/{url_path} (deprecated).
* `owner`: file owner (see voxpupuliarchive params for defaults).
* `group`: file group (see voxpupuliarchive params for defaults).
* `mode`: file mode (see voxpupuliarchive params for defaults).
* `voxpupuliarchive_path`: the parent directory of local filepath.
* `extract`: whether to extract the files (true/false).
* `creates`: the file created when the voxpupuliarchive is extracted (true/false).
* `cleanup`: remove voxpupuliarchive file after file extraction (true/false).

#### voxpupuliArchive::Artifactory Example:
```puppet
$dirname = 'gradle-1.0-milestone-4-20110723151213+0300'
$filename = "${dirname}-bin.zip"

voxpupuliarchive::artifactory { $filename:
  voxpupuliarchive_path => '/tmp',
  url          => "http://repo.jfrog.org/artifactory/distributions/org/gradle/${filename}",
  extract      => true,
  extract_path => '/opt',
  creates      => "/opt/${dirname}",
  cleanup      => true,
}

file { '/opt/gradle':
  ensure => link,
  target => "/opt/${dirname}",
}
```

#### voxpupuliArchive::Nexus

#### voxpupuliArchive::Nexus Example:
```puppet
voxpupuliarchive::nexus { '/tmp/jtstand-ui-0.98.jar':
  url        => 'https://oss.sonatype.org',
  gav        => 'org.codehaus.jtstand:jtstand-ui:0.98',
  repository => 'codehaus-releases',
  packaging  => 'jar',
  extract    => false,
}
```

## Development

We highly welcome new contributions to this module, especially those that
include documentation, and rspec tests ;) but will happily guide you through
the process, so, yes, please submit that pull request!

Note: If you are writing a dependent module that include specs in it, you will
need to set the puppetversion fact in your puppet-rspec tests. You can do that
by adding it to the default facts of your spec/spec_helper.rb:

```ruby
RSpec.configure do |c|
  c.default_facts = { :puppetversion => Puppet.version }
end
```
