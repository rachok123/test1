
case node["platform"]
  when "centos"
    execute 'zabbix_repo_configure' do
      command <<-EOH
        rpm -i  http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/zabbix-release-2.4-1.el7.noarch.rpm
      EOH
      action :run
      only_if do
        !File.exists?('/etc/yum.repos.d/zabbix.repo')
      end
    end
    package zabbix-agent  do
      action :install
    end

    template '/etc/zabbix/zabbix-agent.conf' do
      source 'zabbix-agent.conf.erb'
      owner "root"
      mode "0754"
      notifies :restart, "service[zabbix-agent]", :delayed
    end
  when "windows"

    windows_zipfile 'c:/zabbix' do
      source 'http://www.zabbix.com/downloads/2.4.1/zabbix_agents_2.4.1.win.zip'
      action :unzip
      not_if {::File.exists?('c:/zabbix/bin/win64/zabbix_agentd.exe')}
    end

    template 'c:/zabbix/bin/win64/zabbix_agentd.exe' do
      source  'zabbix-agent.conf.erb'
      action :create_if_missing
      inherits true
    end

    windows_package 'Zabbix agentd' do
      source 'c:/zabbix/bin/win64/zabbix_agentd.exe'
      options '--config c:/zabbix/conf/zabbix_agentd.win.conf  --install'
      action :install
    end

    execute 'Zabbix add rules port in 10050' do
      timeout 5
      command "netsh advfirewall firewall add rule name='Zabbix agent port 10050' dir=in action=allow program='C:\Zabbix\bin\win64\zabbix_agentd.exe' protocol=TCP localport=10050 enable=yes"
    end

    execute 'Zabbix add rules port out 10050' do
      timeout 5
      command "netsh advfirewall firewall add rule name='Zabbix agent port 10050' dir=out action=allow program='C:\Zabbix\bin\win64\zabbix_agentd.exe' protocol=TCP localport=10050 enable=yes"
    end

    service "Zabbix Agent" do
      supports :status => true, :start => true, :stop => true, :restart => true
      action [ :enable ]
      action [ :start ]
    end

end
