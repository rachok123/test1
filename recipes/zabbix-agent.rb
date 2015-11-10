
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



end
