# A class to setup the v8js extension and dependencies.
class v8js::extension(
	$config
) {
	if ( ! empty( $config[disabled_extensions] ) and 'chassis/v8js' in $config[disabled_extensions] ) {
		$package = absent
	} else {
		$package = installed
	}

	$v8_version = '6.6'
	apt::ppa { 'ppa:pinepain/libv8':
		require => Class['apt'],
	}

	package { [ "libv8-${v8_version}", "libv8-${v8_version}-dev" ]:
		ensure  => $package,
		require => [ Apt::Ppa['ppa:pinepain/libv8'] ],
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
			ensure  => $package,
			require => [
				Apt::Pin["${php_package}-dev"],
			],
		}
	}

	if ! defined( Package['php-pear'] ) {
		package { 'php-pear':
			ensure => installed,
		}
	}

	if ( installed == $package ) {
		exec { 'pecl install v8js':
			command => "/bin/echo '/opt/libv8-${v8_version}
				' | /usr/bin/pecl install v8js",
			unless  => '/usr/bin/pecl info v8js',
			require => [
				Package["libv8-${v8_version}"],
				Package["libv8-${v8_version}-dev"],
				Package['php-pear'],
				Package["${php_package}-dev"],
				Exec['pecl channel-update pecl.php.net'],
			],
		}

		exec { 'pecl channel-update pecl.php.net':
			path    => '/usr/bin',
			require =>  [
				Package['php-pear'],
				Package["${php_package}-xml"],
			]
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
			require => [ File["/etc/php/${version}/mods-available/v8js.ini"], [
				Package["${php_package}-fpm"] ] ],
			target  => "/etc/php/${version}/mods-available/v8js.ini",
			notify  => Service["${php_package}-fpm"],
		}
	} else {
		exec { 'pecl uninstall v8js':
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			command => 'pecl uninstall v8js',
			require => Package['php-pear'],
		}
		file { [
			"/etc/php/${version}/mods-available/v8js.ini",
			"/etc/php/${version}/fpm/conf.d/99-v8js.ini",
			"/etc/php/${version}/cli/conf.d/99-v8js.ini"
		]:
			ensure => absent,
			notify => Service["${php_package}-fpm"],
		}
	}
}
