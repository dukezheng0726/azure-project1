resource "azurerm_resource_group" "FW-ResourceGroup" {
  name     = var.fw_resource_group_name
  location = var.location
}

resource "azurerm_lb" "gwlb" {
  name                = "gwlb"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name
  sku                 = "Gateway"

  frontend_ip_configuration {
    name      = "gwlb-frontend"
    subnet_id = var.dmz_subnet_id
  }
}

resource "azurerm_lb_backend_address_pool" "nva_backend_pool" {
  loadbalancer_id = azurerm_lb.gwlb.id
  name            = "nva-backend-pool"

  tunnel_interface {
    identifier = 800  # 隧道 ID (1-8000)，需与 NVA 配置匹配
    type       = "Internal"  # 或 "External"（取决于 NVA 部署方式）
    protocol   = "VXLAN"     # 或 "Geneve"（NVA 需支持）
    port = 1234
  }  
}

# NVA 网络接口（放在 DMZ 子网）
resource "azurerm_network_interface" "nva_nic" {
  name                = "nva-nic"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.dmz_subnet_id
  }
}

# 关联 NIC 到 GWLB 后端池
resource "azurerm_network_interface_backend_address_pool_association" "nva_assoc" {
  network_interface_id    = azurerm_network_interface.nva_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nva_backend_pool.id
}


# NVA 虚拟机（Ubuntu 示例）
resource "azurerm_linux_virtual_machine" "nva" {
  name                = "nva-vm"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nva_nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/zy/.ssh/id_rsa.pub") # 替换为您的公钥路径
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # 启用IP转发
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p

    GWLB_IP="${azurerm_lb.gwlb.frontend_ip_configuration[0].private_ip_address}"
    NVA_IP=$(hostname -I | awk '{print $1}')
    ip link add vxlan800 type vxlan id 800 remote $GWLB_IP local $NVA_IP dev eth0 dstport 1234
    ip link set vxlan800 up
  EOF
  )

}


resource "azurerm_network_security_group" "nva_nsg" {
  name                = "nva-nsg"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-gwlb-traffic"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80-443"  # 允许 HTTP/HTTPS
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 关联 NSG 到 NIC
resource "azurerm_network_interface_security_group_association" "nva_nic_nsg" {
  network_interface_id      = azurerm_network_interface.nva_nic.id
  network_security_group_id = azurerm_network_security_group.nva_nsg.id
}