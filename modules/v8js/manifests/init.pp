# A class to install v8js on your Chassis server.
class v8js(
 	$config
) {
	if ( $config[php] == 5.6 ) {
		alert('V8JS requires Php 7.0 or higher. This extension will not be installed.')
	} else {
		include apt

		class { 'v8js::extension':
			config  => $config,
			require => [
				Class['apt'],
			],
		}
	}
}
