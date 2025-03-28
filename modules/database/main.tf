resource "azurerm_resource_group" "DB-ResourceGroup" {
  name     = var.db_resource_group_name
  location = var.location
}

# 创建内部负载均衡器 (ILB)
resource "azurerm_lb" "db-lb" {
  name                = "DB-LB"
  location            = azurerm_resource_group.DB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.DB-ResourceGroup.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "DBStaticIPAddress"
    subnet_id                     = var.data_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.4.100"
  }
}

resource "azurerm_lb_backend_address_pool" "db_lb_backend" {
  loadbalancer_id = azurerm_lb.db-lb.id
  name            = "BackendPool"
}

resource "azurerm_lb_probe" "db_lb_probe" {
  loadbalancer_id     = azurerm_lb.db-lb.id
  name                = "sql-health-probe"
  port                = 1433
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# 创建负载均衡规则
resource "azurerm_lb_rule" "sql_rule" {
  loadbalancer_id                = azurerm_lb.db-lb.id
  name                           = "sql-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "DBStaticIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.db_lb_backend.id]
  probe_id                       = azurerm_lb_probe.db_lb_probe.id
}

# 创建NSG规则（仅允许业务子网访问1433）
resource "azurerm_network_security_group" "sql_nsg" {
  name                = "sql-nsg"
  location            = azurerm_resource_group.DB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.DB-ResourceGroup.name

  security_rule {
    name                       = "allow-business-to-sql"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.3.0/24" 
    destination_address_prefix = "10.0.4.0/24" 
  }
}

# 关联NSG到数据子网（假设子网已存在）
resource "azurerm_subnet_network_security_group_association" "data_subnet_nsg_association" {
  subnet_id                 = var.data_subnet_id
  network_security_group_id = azurerm_network_security_group.sql_nsg.id
}

# 创建2台SQL Server VM（简化版）
resource "azurerm_network_interface" "sql_vm_nics" {
  count               = 2
  name                = "sql-vm-${count.index}-nic"
  location            = azurerm_resource_group.DB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.DB-ResourceGroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.data_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "sql_vm" {
  count               = 2
  name                = "sql-vm-${count.index}"
  location            = azurerm_resource_group.DB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.DB-ResourceGroup.name
  size                = "Standard_DS2_v2"
  admin_username      = "yan"
  admin_password      = "Yan123456"
  network_interface_ids = [
    azurerm_network_interface.sql_vm_nics[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2019"
    sku       = "Enterprise"
    version   = "latest"
  }

 # 显式启用 VM 代理（Windows 默认已启用，但建议声明）
 # provision_vm_agent = true  # 此参数对 Windows VM 可选，对 Linux VM 必需
}

/*
resource "azurerm_virtual_machine_extension" "monitoring" {
  count                = 2
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.sql_vm[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}
*/


# 将VM NICs添加到LB后端池
resource "azurerm_network_interface_backend_address_pool_association" "sql_lb_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.sql_vm_nics[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.db_lb_backend.id
}


