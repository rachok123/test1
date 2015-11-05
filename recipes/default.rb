##Prepeare
%w{ntp mc  vim wget curl net-tools}.each do |packages|
  package packages do
    action :install
  end
end
bash 'gnutls downgrade' do
  code <<-EOH
  yum downgrade ftp://bo.mirror.garr.it/pub/1/slc/centos/7.0.1406/updates/x86_64/Packages/gnutls-3.1.18-10.el7_0.x86_64.rpm
  echo "exclude=gnutls*" >> /etc/yum.conf
  EOH
end



bash 'zabbix_repo_configure' do
  code <<-EOH
    rpm -i  http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/zabbix-release-2.4-1.el7.noarch.rpm
  EOH
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





bash 'mysql_secure_installation' do
  code <<-EOH
    mysql -uroot<<EOF  &&  touch /root/.mysql_secure_installation_complete
-- remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- create user zabbix
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
GRANT ALL PRIVILEGES ON *.* TO 'zabbix'@'localhost';
-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database and access to it
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables now
FLUSH PRIVILEGES;
-- Create Database
CREATE DATABASE zabbix;
EOF
  EOH
  only_if do
    !File.exists?('/root/.mysql_secure_installation_complete')
  end
end

bash 'mysql_zabbix_installation' do
  code <<-EOH
    cd /usr/share/doc/zabbix-server-mysql-2.4.6//create
    mysql -uroot zabbix < schema.sql
    mysql -uroot zabbix < images.sql
    mysql -uroot zabbix < data.sql
    touch /root/.mysql_secure_installation_complete
  EOH
  only_if do
    !File.exists?('/root/.mysql_mysql_installation_complete')
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


"#{%w{mariadb zabbix-server httpd}.each do |zabbix_service|
  service "#{zabbix_service}" do
    action :restart
  end
end}"