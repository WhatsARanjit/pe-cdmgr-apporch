pe_version = '2016.1.1'
os         = 'el'
release    = '7'
arch       = 'x86_64'
pe_dir     = "puppet-enterprise-#{pe_version}-#{os}-#{release}-#{arch}"
pe_tarball = "#{pe_dir}.tar.gz"
hostname   = 'puppet2016.1.1.puppetlabs.vm'

Vagrant.configure(2) do |config|

  # Base box
  config.vm.box = 'puppetlabs/centos-7.2-64-nocm'
  
  # Specs
  config.vm.provider 'virtualbox' do |v|
    v.memory = 8192
    v.cpus   = 4
  end

  # Network stuff
  config.vm.network 'forwarded_port', guest: 443, host: 8443
  config.vm.hostname = hostname

  # Add host entry
  config.vm.provision :hosts do |prov|
    prov.autoconfigure = true
  end

  # Install PE
  config.vm.provision 'shell', inline: <<-SHELL
    cd /root

    # Grab tarball if it doesn't exist
    test -f #{pe_tarball} || (
      cp /vagrant/#{pe_tarball} .\
      || wget --quiet --content-disposition "https://pm.puppetlabs.com/puppet-enterprise/#{pe_version}/#{pe_tarball}" > /dev/null
    )

    # Expand tarball if you haven't
    test -f #{pe_dir} \
    || tar zxpf #{pe_tarball}

    # Install PE if not
    cd #{pe_dir}
    which puppetserver > /dev/null \
    || ./puppet-enterprise-installer -a /vagrant/all-in-one.answers.txt

    # Stop firewall
    puppet resource service firewalld ensure=stopped

    # No SELinux
    test $(getenforce) == 'Disabled' \
    || setenforce 0

    # Setup deploy role/user
    /vagrant/code/deploy.rb

    # Setup app orchestrator
    puppet resource package puppetclassify ensure=installed provider=puppet_gem
    puppet module install WhatsARanjit/node_manager --modulepath /opt/puppetlabs/puppet/modules
    puppet module install puppetlabs/inifile --modulepath /opt/puppetlabs/puppet/modules
    puppet apply /vagrant/code/app_orch.pp
    rm -f /opt/puppetlabs/puppet/cache/client_data/catalog/#{hostname}.json
    puppet agent -t

    # Changes exit with 2, which Vagrant doesn't like
    if [ $? -eq 0 ] || [ $? -eq 2 ]; then
      /bin/true
    fi
  SHELL

end
