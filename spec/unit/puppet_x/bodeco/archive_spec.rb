require 'spec_helper'
require 'puppet_x/bodeco/voxpupuliarchive'

describe PuppetX::Bodeco::voxpupuliArchive do
  let(:zipfile) do
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'test.zip'))
  end

  it '#checksum' do
    Dir.mktmpdir do |dir|
      tempfile = File.join(dir, 'test.zip')
      FileUtils.cp(zipfile, tempfile)

      voxpupuliarchive = PuppetX::Bodeco::voxpupuliArchive.new(tempfile)
      expect(voxpupuliarchive.checksum(:none)).to be nil
      expect(voxpupuliarchive.checksum(:md5)).to eq '557e2ebb67b35d1fddff18090b6bc26b'
      expect(voxpupuliarchive.checksum(:sha1)).to eq '377ec712d7fdb7266221db3441e3af2055448ead'
    end
  end

  it '#parse_flags' do
    voxpupuliarchive = PuppetX::Bodeco::voxpupuliArchive.new('test.tar.gz')
    expect(voxpupuliarchive.send(:parse_flags, 'xf', :undef, 'tar')).to eq 'xf'
    expect(voxpupuliarchive.send(:parse_flags, 'xf', 'xvf', 'tar')).to eq 'xvf'
    expect(voxpupuliarchive.send(:parse_flags, 'xf', { 'tar' => 'xzf', '7z' => '-y x' }, 'tar')).to eq 'xzf'
  end

  it '#command on RedHat' do
    Facter.stubs(:value).with(:osfamily).returns 'RedHat'

    tar = PuppetX::Bodeco::voxpupuliArchive.new('test.tar.gz')
    expect(tar.send(:command, :undef)).to eq 'tar xzf test.tar.gz'
    expect(tar.send(:command, 'xvf')).to eq 'tar xvf test.tar.gz'
    tar = PuppetX::Bodeco::voxpupuliArchive.new('test.tar.bz2')
    expect(tar.send(:command, :undef)).to eq 'tar xjf test.tar.bz2'
    expect(tar.send(:command, 'xjf')).to eq 'tar xjf test.tar.bz2'
    tar = PuppetX::Bodeco::voxpupuliArchive.new('test.tar.xz')
    expect(tar.send(:command, :undef)).to eq 'unxz -dc test.tar.xz | tar xf -'
    gunzip = PuppetX::Bodeco::voxpupuliArchive.new('test.gz')
    expect(gunzip.send(:command, :undef)).to eq 'gunzip -d test.gz'
    zip = PuppetX::Bodeco::voxpupuliArchive.new('test.zip')
    expect(zip.send(:command, :undef)).to eq 'unzip -o test.zip'
    expect(zip.send(:command, '-a')).to eq 'unzip -a test.zip'
  end

  it '#command on Windows' do
    Facter.stubs(:value).with(:osfamily).returns 'windows'

    tar = PuppetX::Bodeco::voxpupuliArchive.new('test.tar.gz')
    tar.stubs(:win_7zip).returns('7z.exe')
    expect(tar.send(:command, :undef)).to eq '7z.exe x -aoa test.tar.gz'
    expect(tar.send(:command, 'x -aot')).to eq '7z.exe x -aot test.tar.gz'

    zip = PuppetX::Bodeco::voxpupuliArchive.new('test.zip')
    zip.stubs(:win_7zip).returns('7z.exe')
    expect(zip.send(:command, :undef)).to eq '7z.exe x -aoa test.zip'
  end
end
