begin
  require 'puppet_x/bodeco/voxpupuliarchive'
  require 'puppet_x/bodeco/util'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  voxpupuliarchive = Puppet::Module.find('voxpupuliarchive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find voxpupuliarchive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless voxpupuliarchive
  require File.join voxpupuliarchive.path, 'lib/puppet_x/bodeco/voxpupuliarchive'
  require File.join voxpupuliarchive.path, 'lib/puppet_x/bodeco/util'
end

require 'securerandom'
require 'tempfile'

Puppet::Type.type(:voxpupuliarchive).provide(:ruby) do
  optional_commands :aws => 'aws'
  defaultfor :feature => :microsoft_windows
  attr_reader :voxpupuliarchive_checksum

  def exists?
    if extracted?
      if File.exist? voxpupuliarchive_filepath
        checksum?
      else
        cleanup
        true
      end
    else
      checksum?
    end
  end

  def create
    transfer_download(voxpupuliarchive_filepath) unless checksum?
    extract
    cleanup
  end

  def destroy
    FileUtils.rm_f(voxpupuliarchive_filepath) if File.exist?(voxpupuliarchive_filepath)
  end

  def voxpupuliarchive_filepath
    resource[:path]
  end

  def tempfile_name
    if resource[:checksum] == 'none'
      "#{resource[:filename]}_#{SecureRandom.base64}"
    else
      "#{resource[:filename]}_#{resource[:checksum]}"
    end
  end

  def creates
    if resource[:extract] == :true
      extracted? ? resource[:creates] : 'voxpupuliarchive not extracted'
    else
      resource[:creates]
    end
  end

  def creates=(_value)
    extract
  end

  def checksum
    resource[:checksum] || remote_checksum
  end

  def remote_checksum
    @remote_checksum ||= begin
      PuppetX::Bodeco::Util.content(
        resource[:checksum_url],
        :username => resource[:username],
        :password => resource[:password],
        :cookie => resource[:cookie]
      )[/\b[\da-f]{32,128}\b/i] if resource[:checksum_url]
    end
  end

  # Private: See if local voxpupuliarchive checksum matches.
  # returns boolean
  def checksum?(store_checksum = true)
    voxpupuliarchive_exist = File.exist? voxpupuliarchive_filepath
    if voxpupuliarchive_exist && resource[:checksum_type] != :none
      voxpupuliarchive = PuppetX::Bodeco::voxpupuliArchive.new(voxpupuliarchive_filepath)
      voxpupuliarchive_checksum = voxpupuliarchive.checksum(resource[:checksum_type])
      @voxpupuliarchive_checksum = voxpupuliarchive_checksum if store_checksum
      checksum == voxpupuliarchive_checksum
    else
      voxpupuliarchive_exist
    end
  end

  def cleanup
    return unless extracted? && resource[:cleanup] == :true
    Puppet.debug("Cleanup voxpupuliarchive #{voxpupuliarchive_filepath}")
    destroy
  end

  def extract
    return unless resource[:extract] == :true
    raise(ArgumentError, 'missing voxpupuliarchive extract_path') unless resource[:extract_path]
    PuppetX::Bodeco::voxpupuliArchive.new(voxpupuliarchive_filepath).extract(
      resource[:extract_path],
      :custom_command => resource[:extract_command],
      :options => resource[:extract_flags],
      :uid => resource[:user],
      :gid => resource[:group]
    )
  end

  def extracted?
    resource[:creates] && File.exist?(resource[:creates])
  end

  def transfer_download(voxpupuliarchive_filepath)
    tempfile = Tempfile.new(tempfile_name)
    temppath = tempfile.path
    tempfile.close!

    case resource[:source]
    when /^(http|ftp)/
      download(temppath)
    when /^file/
      uri = URI(resource[:source])
      FileUtils.copy(Puppet::Util.uri_to_path(uri), temppath)
    when /^s3/
      s3_download(temppath)
    else
      raise(Puppet::Error, "Source file: #{resource[:source]} does not exists.") unless File.exist?(resource[:source])
      FileUtils.copy(resource[:source], temppath)
    end

    # conditionally verify checksum:
    if resource[:checksum_verify] == :true && resource[:checksum_type] != :none
      voxpupuliarchive = PuppetX::Bodeco::voxpupuliArchive.new(temppath)
      raise(Puppet::Error, 'Download file checksum mismatch') unless voxpupuliarchive.checksum(resource[:checksum_type]) == checksum
    end

    FileUtils.mkdir_p(File.dirname(voxpupuliarchive_filepath))
    FileUtils.mv(temppath, voxpupuliarchive_filepath)
  end

  def download(filepath)
    PuppetX::Bodeco::Util.download(resource[:source], filepath, :username => resource[:username], :password => resource[:password], :cookie => resource[:cookie], :proxy_server => resource[:proxy_server], :proxy_type => resource[:proxy_type])
  end

  def s3_download(path)
    params = [
      's3',
      'cp',
      resource[:source],
      path
    ]

    aws(params)
  end

  def optional_switch(value, option)
    if value
      option.collect { |flags| flags % value }
    else
      []
    end
  end
end
