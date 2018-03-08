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
