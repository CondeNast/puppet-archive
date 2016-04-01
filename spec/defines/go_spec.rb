require 'spec_helper'

describe 'voxpupuliarchive::go' do
  let!(:go_md5) do
    MockFunction.new('go_md5') do |f|
      f.stub.returns('0d4f4b4b039c10917cfc49f6f6be71e4')
    end
  end

  let(:facts) { { :osfamily => 'RedHat', :puppetversion => '3.7.3' } }

  context 'go voxpupuliarchive with defaults' do
    let(:title) { '/opt/app/example.zip' }
    let(:params) { {
      :server => 'home.lan',
      :port => '8081',
      :url_path => 'go/example.zip',
      :md5_url_path => 'go/example.zip/checksum',
      :username => 'username',
      :password => 'password',
    } }

    it do
      should contain_voxpupuliarchive('/opt/app/example.zip').with(
        :path => '/opt/app/example.zip',
        :source => 'http://home.lan:8081/go/example.zip',
        :checksum => '0d4f4b4b039c10917cfc49f6f6be71e4',
        :checksum_type => 'md5',
      )
    end

    it do
      should contain_file('/opt/app/example.zip').with(
        :owner => '0',
        :group => '0',
        :mode => '0640',
        :require => 'voxpupuliArchive[/opt/app/example.zip]',
      )
    end
  end

  context 'go voxpupuliarchive with path' do
    let(:title) { 'example.zip' }
    let(:params) { {
      :voxpupuliarchive_path => '/opt/app',
      :server => 'home.lan',
      :port => '8081',
      :url_path => 'go/example.zip',
      :md5_url_path => 'go/example.zip/checksum',
      :username => 'username',
      :password => 'password',
      :owner => 'app',
      :group => 'app',
      :mode => '0400',
    } }

    it do
      should contain_voxpupuliarchive('/opt/app/example.zip').with(
        :path => '/opt/app/example.zip',
        :source => 'http://home.lan:8081/go/example.zip',
        :checksum => '0d4f4b4b039c10917cfc49f6f6be71e4',
        :checksum_type => 'md5',
      )
    end

    it do
      should contain_file('/opt/app/example.zip').with(
        :owner => 'app',
        :group => 'app',
        :mode => '0400',
        :require => 'voxpupuliArchive[/opt/app/example.zip]',
      )
    end
  end
end
