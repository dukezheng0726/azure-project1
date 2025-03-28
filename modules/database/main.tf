# 1. 创建资源组
resource "azurerm_resource_group" "Yan-DB-ResourceGroup" {
  name     = var.db_resource_group_name
  location = var.location
}

resource "time_sleep" "wait" {
  depends_on      = [azurerm_resource_group.Yan-DB-ResourceGroup]
  create_duration = "10s"
}

# 2.1 创建 Primary SQL Server
resource "azurerm_mssql_server" "dbserver1" {
  name                          = var.dbserver1
  resource_group_name           = var.db_resource_group_name
  location                      = var.dblocation1
  version                       = var.dbversion
  administrator_login           = var.dblogin
  administrator_login_password  = var.dbpassword
  public_network_access_enabled = true
  depends_on                    = [time_sleep.wait]
}

resource "azurerm_mssql_firewall_rule" "allow_all_ips_db1" {
  name             = "allow-all-ips"
  server_id        = azurerm_mssql_server.dbserver1.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
  depends_on       = [azurerm_mssql_server.dbserver1]
}

# 2.2 创建 Secondary SQL Server（Geo-Replication）
resource "azurerm_mssql_server" "dbserver2" {
  name                          = var.dbserver2
  resource_group_name           = var.db_resource_group_name
  location                      = var.dblocation2
  version                       = var.dbversion
  administrator_login           = var.dblogin
  administrator_login_password  = var.dbpassword
  public_network_access_enabled = true
  depends_on                    = [time_sleep.wait]
}

resource "azurerm_mssql_firewall_rule" "allow_all_ips_db2" {
  name             = "allow-all-ips"
  server_id        = azurerm_mssql_server.dbserver2.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
  depends_on       = [azurerm_mssql_server.dbserver2]

}

# 3.1 创建 Primary SQL Database
resource "azurerm_mssql_database" "yandb1" {
  name                        = "yan-database1"
  server_id                   = azurerm_mssql_server.dbserver1.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
  depends_on                  = [azurerm_mssql_server.dbserver1]
}

# 3.2 创建 Secondary SQL Database
resource "azurerm_mssql_database" "yandb2" {
  name                        = "yan-database2"
  server_id                   = azurerm_mssql_server.dbserver2.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
  depends_on                  = [azurerm_mssql_server.dbserver2]
}

resource "azurerm_traffic_manager_profile" "sql_lb" {
  name                   = "yan-sql-traffic-manager"
  resource_group_name    = var.db_resource_group_name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "yan-db-lb"
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTPS"
    port     = 443
    path     = "/"
  }
}

/*
# 添加第一个 SQL Server 终结点 (yan-dbserver1)
resource "azurerm_traffic_manager_azure_endpoint" "sql_westus2" {
  name               = "dbserver1-westus2"
  profile_id         = azurerm_traffic_manager_profile.sql_lb.id
  #target_resource_id = azurerm_mssql_server.dbserver1.id
  target_resource_id = "/subscriptions/9eddc527-496a-4bbf-83a1-b1c0b9c0c12c/resourceGroups/Yan-DB-ResourceGroup/providers/Microsoft.Sql/servers/yan-dbserver1"
  weight             = 50
}

# 添加第二个 SQL Server 终结点 (dbserver2)
resource "azurerm_traffic_manager_azure_endpoint" "sql_westus3" {
  name               = "dbserver2-westus3"
  profile_id         = azurerm_traffic_manager_profile.sql_lb.id
  target_resource_id = azurerm_mssql_server.dbserver2.id
  weight             = 50

    depends_on                    = [azurerm_mssql_server.dbserver2]
}
*/




