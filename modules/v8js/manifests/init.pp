# A class to install v8js on your Chassis server.
class v8js(
 	$config
) {
	include apt

	class { 'v8js::extension':
		config  => $config,
		require => [
			Class['apt'],
		],
	}
}
