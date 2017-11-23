class v8js::extension(
	$config
) {
	$v8_version = '5.2'
	apt::ppa { "ppa:pinepain/libv8-${v8_version}":
		require => [ Package[ $::apt::ppa_package ] ],
	}

	package { [ "libv8-${v8_version}", "libv8-${v8_version}-dev" ]:
		ensure => installed,
		require => [ Apt::Ppa["ppa:pinepain/libv8-${v8_version}"] ],
	}

	$version = $config[php]

	if $version =~ /^(\d+)\.(\d+)$/ {
		$package_version = "${version}.*"
		$short_ver = $version
	}
	else {
		$package_version = "${version}*"
		$short_ver = regsubst($version, '^(\d+\.\d+)\.\d+$', '\1')
	}

	if versioncmp( $version, '5.4') <= 0 {
		$php_package = 'php5'
	}
	else {
		$php_package = "php${short_ver}"
	}

	if !defined(Package["${php_package}-dev"]) {
		apt::pin { "${php_package}-dev":
			packages => [ "${php_package}-dev" ],
			version  => $package_version,
			priority => 1001,
		}
		package { "${php_package}-dev":
			ensure  => installed,
			require => [
				Apt::Pin["${php_package}-dev"],
				# Class['chassis::php'],
			],
		}
	}

	package { 'php-pear':
		ensure => installed,
		# require => Class['chassis::php'],
	}

	exec { 'pecl channel-update pecl.php.net':
		path    => '/usr/bin',
		require => Package['php-pear'],
	}

	exec { 'pecl install v8js':
		command => "/bin/echo '/opt/libv8-${v8_version}' | /usr/bin/pecl install v8js",
		# environment => [
		# 	'LDFLAGS="-lstdc++"'
		# ],
		unless  => '/usr/bin/pecl info v8js',
		logoutput => true,
		require => [
			Package["libv8-${v8_version}"],
			Package["libv8-${v8_version}-dev"],
			Package['php-pear'],
			Exec['pecl channel-update pecl.php.net'],
		],
	}

	file { "/etc/php/7.1/mods-available/v8js.ini":
		ensure => file,
		content => "extension=v8js.so",
		require => Exec['pecl install v8js'],
	}

	file { [
		'/etc/php/7.1/fpm/conf.d/99-v8js.ini',
		'/etc/php/7.1/cli/conf.d/99-v8js.ini'
	]:
		ensure => link,
		require => File['/etc/php/7.1/mods-available/v8js.ini'],
		target => '/etc/php/7.1/mods-available/v8js.ini',
		notify => Service["${php_package}-fpm"],
	}
}
