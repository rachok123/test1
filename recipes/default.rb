##Prepeare
%w{epel-release ntp mc  vim wget curl net-tools}.each do |packages|
  package packages do
    action :install
  end
end
execute 'gnutls downgrade' do
  command <<-EOH
  rpm -Uvh --force ftp://bo.mirror.garr.it/pub/1/slc/centos/7.0.1406/updates/x86_64/Packages/gnutls-3.1.18-10.el7_0.x86_64.rpm
  echo "exclude=gnutls*" >> /etc/yum.conf
  touch /root/.gnutls_downgrade
  EOH
  action :run
  only_if do
    !File.exists?('/root/.gnutls_downgrade')
  end
end



execute 'zabbix_repo_configure' do
  command <<-EOH
    rpm -i  http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/zabbix-release-2.4-1.el7.noarch.rpm
  EOH
  action :run
  only_if do
   !File.exists?('/etc/yum.repos.d/zabbix.repo')
  end
end


%w{mariadb-server mariadb zabbix-server-mysql zabbix-web-mysql }.each do |packages|
  package packages do
    action :install
  end
end


service 'mariadb' do
  supports :restart => true
  action [:enable, :start]
end

execute 'mysql_secure_installation' do
  command 'mysql -uroot < /tmp/mysql_prepeare.sql && touch /root/.mysql_secure_instaled'
  action :nothing
end

template '/tmp/mysql_prepeare.sql' do
  source 'mysql-secure.sql.erb'
  notifies :run, 'execute[mysql_secure_installation]', :immediately
  only_if do
    !File.exists?('/root/.mysql_mysql_installation_complete')
  end
end

execute 'zabbix-import' do
  command '/tmp/zabix-import.sh'
  action :nothing
end

template '/tmp/zabix-import.sh' do
  source 'zabbix-import.sh.erb'
  mode '0755'
  notifies :run, 'execute[zabbix-import]', :immediately
  only_if do
    !File.exists?(' /root/.mysql_import_complete')
  end
end

template "/etc/zabbix/zabbix_server.conf" do
  source "zabbix_server.conf.erb"
  owner "root"
  group "zabbix"
  mode "0755"
end

cookbook_file "/etc/httpd/conf.d/zabbix.conf" do
  source "zabbix.conf"
  owner "root"
  group "root"
  mode "0644"
end


%w{mariadb zabbix-server httpd}.each do |zabbix_service|
  service "#{zabbix_service}" do
  action :restart
  end
end