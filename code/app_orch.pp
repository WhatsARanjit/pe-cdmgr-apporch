node_group { 'PE Infrastructure':
  ensure               => present,
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  classes              => {
    'puppet_enterprise' => {
      'certificate_authority_host'   => $clientcert,
      'console_host'                 => $clientcert,
      'console_port'                 => '443',
      'database_host'                => $clientcert,
      'database_port'                => '5432',
      'database_ssl'                 => true,
      'mcollective_middleware_hosts' => [$clientcert],
      'pcp_broker_host'              => $clientcert,
      'puppet_master_host'           => $clientcert,
      'puppetdb_database_name'       => 'pe-puppetdb',
      'puppetdb_database_user'       => 'pe-puppetdb',
      'puppetdb_host'                => $clientcert,
      'puppetdb_port'                => '8081',
      'use_application_services'     => true,
    },
  },
}

file { '/etc/puppetlabs/client-tools/orchestrator.conf':
  ensure  => file,
  content => inline_template('{"options":{"service-url":"https://<%= @clientcert %>:8143"}}'),
  backup  => false,
}

ini_setting { 'use_cached_catalog':
  ensure  => present,
  path    => $settings::config,
  section => 'agent',
  setting => 'use_cached_catalog',
  value   => 'true',
}
