resource "azurerm_resource_group" "BASTION-ResourceGroup" {
  name     = var.bastion_resource_group_name
  location = var.location
}


resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name
  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}


# 创建NSG并允许Bastion的ssh访问web_vmss
resource "azurerm_network_security_group" "web_vmss_subnet_nsg" {
  name                = "web-vmss-subnet-nsg"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name

  security_rule {
    name                       = "allow-bastion-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # 新增HTTP规则
  security_rule {
    name                       = "allow-http-internet"
    priority                   = 200 # 注意优先级要高于或低于现有规则
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*" # 允许所有Internet访问
    destination_address_prefix = "*"
  }
}


# 创建NSG并允许Bastion的ssh访问business_vmss
resource "azurerm_network_security_group" "business_vmss_subnet_nsg" {
  name                = "business-vmss-subnet-nsg"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name

  security_rule {
    name                       = "allow-gateway-manager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-azure-cloud"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "AzureCloud"
    destination_address_prefix = "*"
  }

  # 新增HTTP规则
  security_rule {
    name                       = "allow-http-internet"
    priority                   = 200 # 注意优先级要高于或低于现有规则
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*" # 允许所有Internet访问
    destination_address_prefix = "*"
  }

}


# 将NSG关联到WEB-VMSS所在的子网
resource "azurerm_subnet_network_security_group_association" "web_vmss_subnet_nsg_association" {
  subnet_id                 = var.web_subnet_id
  network_security_group_id = azurerm_network_security_group.web_vmss_subnet_nsg.id
}


# 将NSG关联到Business-VMSS所在的子网
resource "azurerm_subnet_network_security_group_association" "business_vmss_subnet_nsg_association" {
  subnet_id                 = var.business_subnet_id
  network_security_group_id = azurerm_network_security_group.business_vmss_subnet_nsg.id
}