pe_version = '2016.2.1'
os         = 'el'
release    = '7'
arch       = 'x86_64'
pe_dir     = "puppet-enterprise-#{pe_version}-#{os}-#{release}-#{arch}"
pe_tarball = "#{pe_dir}.tar.gz"
hostname   = "puppet#{pe_version}.puppetlabs.vm"
nodecount  = 2

Vagrant.configure(2) do |config|

  # Master
  config.vm.define 'master' do |master|

    # Base box
    master.vm.box = 'puppetlabs/centos-7.2-64-nocm'
    
    # Specs
    master.vm.provider 'virtualbox' do |v|
      v.memory = 8192
      v.cpus   = 4
    end

    # Network stuff
    #master.vm.network 'forwarded_port', guest: 443, host: 8443
    master.vm.hostname = hostname

    # Share networks
    master.vm.network :private_network, :ip => '10.20.1.2'
    master.vm.provision :hosts, :sync_hosts => true

    # Add host entry
    #master.vm.provision :hosts do |prov|
    #  prov.autoconfigure = true
    #end

    # Install PE
    master.vm.provision 'shell', inline: <<-SHELL
      cd /root

      # Grab tarball if it doesn't exist
      test -f #{pe_tarball} || (
        cp /vagrant/#{pe_tarball} . &> /dev/null \
        || wget --quiet --content-disposition "https://pm.puppetlabs.com/puppet-enterprise/#{pe_version}/#{pe_tarball}" > /dev/null
      )

      # Expand tarball if you haven't
      test -f #{pe_dir} \
      || tar zxpf #{pe_tarball}

      # Install PE if not
      cd #{pe_dir}
      which puppetserver &> /dev/null \
      || ./puppet-enterprise-installer -c /vagrant/all-in-one.pe.conf

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
      while [ -f /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock ]; do
        echo 'Waiting for current Agent run to end...'
        sleep 10
      done
      echo '*' > /etc/puppetlabs/puppet/autosign.conf
      rm -f /opt/puppetlabs/puppet/cache/client_data/catalog/#{hostname}.json

      # Run puppet
      puppet agent -t

      # Changes exit with 2, which Vagrant doesn't like
      if [ $? -eq 0 ] || [ $? -eq 2 ]; then
        /bin/true
      fi
    SHELL

  end

  nodecount.times do |i|
    nodename = "node#{i+1}"
    nodeip   = "10.20.1.#{i+3}"

    # Node1
    config.vm.define nodename do |node|

      # Base box
      node.vm.box = 'puppetlabs/centos-7.2-64-nocm'
      
      # Share networks
      node.vm.network :private_network, :ip => nodeip
      node.vm.provision :hosts, :sync_hosts => true

      # Install PE
      node.vm.provision 'shell', inline: <<-SHELL

        curl -s -k https://#{hostname}:8140/packages/current/install.bash | sudo bash

        # Stop firewall
        puppet resource service firewalld ensure=stopped

        # No SELinux
        test $(getenforce) == 'Disabled' \
        || setenforce 0

        # Changes exit with 2, which Vagrant doesn't like
        if [ $? -eq 0 ] || [ $? -eq 2 ]; then
          /bin/true
        fi
      SHELL
      
    end
  end

end
