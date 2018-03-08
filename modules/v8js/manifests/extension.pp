# A class to setup the v8js extension and dependencies.
class v8js::extension(
	$config
) {
	$v8_version = '5.2'
	apt::ppa { "ppa:pinepain/libv8-${v8_version}":
		require => [ Package[ $::apt::ppa_package ] ],
	}

	package { [ "libv8-${v8_version}", "libv8-${v8_version}-dev" ]:
		ensure  => installed,
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
		$php_package = "php${version}"
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
			],
		}
	}

	package { 'php-pear':
		ensure => installed,
	}

	exec { 'pecl channel-update pecl.php.net':
		path    => '/usr/bin',
		require => Package['php-pear'],
	}

	exec { 'pecl install v8js':
		command   => "/bin/echo '/opt/libv8-${v8_version}' | /usr/bin/pecl install v8js",
		unless    => '/usr/bin/pecl info v8js',
		logoutput => true,
		require   => [
			Package["libv8-${v8_version}"],
			Package["libv8-${v8_version}-dev"],
			Package['php-pear'],
			Package["${php_package}-dev"],
			Exec['pecl channel-update pecl.php.net'],
		],
	}

	file { "/etc/php/${version}/mods-available/v8js.ini":
		ensure  => file,
		content => 'extension=v8js.so',
		require => Exec['pecl install v8js'],
	}

	file { [
		"/etc/php/${version}/fpm/conf.d/99-v8js.ini",
		"/etc/php/${version}/cli/conf.d/99-v8js.ini"
	]:
		ensure  => link,
		require => File["/etc/php/${version}/mods-available/v8js.ini"],
		target  => "/etc/php/${version}/mods-available/v8js.ini",
		notify  => Service["${php_package}-fpm"],
	}
}
