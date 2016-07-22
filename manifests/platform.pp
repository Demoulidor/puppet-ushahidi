class ushahidi::platform(
  $mysql_root_pass      = 'strong@pass',
  $mysql_ushahidi_user  = 'ushahidi_user',
  $mysql_ushahidi_pass  = 'ushahidi_pass',
  $mysql_ushahidi_name  = 'ushahidi',
  $mysql_ushahidi_host  = 'localhost',
  $ushahidi_www_dir     = '/srv/ushahidi',
  $ushahidi_git_source  = 'https://github.com/ushahidi/platform.git',
  ) {

  $php_packages = [ 'php5', 'php5-cli', 'php5-curl', 'php5-gd', 'php5-imap', 'php5-mcrypt', 'php5-json' ]

  include apt
  include apt::update

  class { 'apache':
    mpm_module => 'prefork'
  }

  include apache::mod::php
  include apache::mod::rewrite

  apache::vhost { 'ushahidi.dev':
    port          => '80',
    docroot       => $ushahidi_www_dir,
    docroot_owner => 'www-data',
    docroot_group => 'www-data',
    options       => ['Indexes','FollowSymLinks','MultiViews'],
    override      => ['None'],
  }

  package { $php_packages:
    ensure => installed,
    notify => Exec['enable-php-modules'],
  }

  exec { 'enable-php-modules':
    command     => '/usr/sbin/php5enmod mcrypt imap',
    refreshonly => true,
  }

  include composer

  package { 'git':
    ensure => installed,
  }

  class { '::mysql::server':
    root_password => $mysql_root_pass,
  }

  include mysql::bindings
  include mysql::bindings::php

  mysql::db { $mysql_ushahidi_name:
    user     => $mysql_ushahidi_user,
    password => $mysql_ushahidi_pass,
    host     => $mysql_ushahidi_host,
    grant    => ['all'],
  }

  vcsrepo { $ushahidi_www_dir:
    ensure   => present,
    provider => 'git',
    source   => $ushahidi_git_source,
  }

  file { "${ushahidi_www_dir}/.env":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('ushahidi/env.erb'),
  }

  file { "${ushahidi_www_dir}/.htaccess":
    ensure  => present,
    content => template('ushahidi/htaccess.erb'),
  }

  file { "${ushahidi_www_dir}/application/logs":
    mode  => '0775',
    owner => 'www-data',
    group => 'www-data',
  }

  file { "${ushahidi_www_dir}/application/cache":
    mode  => '0775',
    owner => 'www-data',
    group => 'www-data',
  }

  file { "${ushahidi_www_dir}/application/media/uploads":
    mode  => '0775',
    owner => 'www-data',
    group => 'www-data',
  }

  file { "${ushahidi_www_dir}/application/config/environments":
    ensure => directory
  }

  file { "${ushahidi_www_dir}/application/config/environments/development":
    ensure  => directory,
    require => File["${ushahidi_www_dir}/application/config/environments"]
  }

}
