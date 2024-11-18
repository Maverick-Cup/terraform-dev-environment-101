#Azure provider source and verson being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Create a resource group
resource "azurerm_resource_group" "rg-sndbx-mm-centralindia" {
  name     = "rg-sndbx-mm-centralindia"
  location = "Central India"
  tags = {
    enviornment = "hpsdev"
  }
}

resource "azurerm_virtual_network" "vn-sndbx-mm-centralindia" {
  name                = "vn-sndbx-mm-centralindia"
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  location            = azurerm_resource_group.rg-sndbx-mm-centralindia.location
  address_space       = ["10.123.0.0/16"]
  tags = {
    enviornment = "hpsdev"
  }
}

resource "azurerm_subnet" "subnet-sndbx-mm-centralindia" {
  name                 = "subnet-sndbx-mm-centralindia"
  resource_group_name  = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  virtual_network_name = azurerm_virtual_network.vn-sndbx-mm-centralindia.name
  address_prefixes     = ["10.123.1.0/24"]

}

resource "azurerm_network_security_group" "nsg-sndbx-mm-centralindia" {
  name                = "nsg-sndbx-mm-centralindia"
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  location            = azurerm_resource_group.rg-sndbx-mm-centralindia.location
  tags = {
    enviornment = "hpsdev"
  }
}

resource "azurerm_network_security_rule" "nsr-sndbx-mm-centralindia" {
  name                        = "nsr-sndbx-mm-centralindia"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  network_security_group_name = azurerm_network_security_group.nsg-sndbx-mm-centralindia.name
}

resource "azurerm_subnet_network_security_group_association" "sga-sndbx-mm-centralindia" {
  subnet_id                 = azurerm_subnet.subnet-sndbx-mm-centralindia.id
  network_security_group_id = azurerm_network_security_group.nsg-sndbx-mm-centralindia.id
}

resource "azurerm_public_ip" "ip-sndbx-mm-centralindia" {
  name                = "ip-sndbx-mm-centralindia"
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  location            = azurerm_resource_group.rg-sndbx-mm-centralindia.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "hpsdev"
  }
}

resource "azurerm_network_interface" "nic-sndbx-mm-centralindia" {
  name                = "nic-sndbx-mm-centralindia"
  location            = azurerm_resource_group.rg-sndbx-mm-centralindia.location
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-sndbx-mm-centralindia.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-sndbx-mm-centralindia.id
  }
  tags = {
    enviornment = "hpsdev"
  }
}

resource "azurerm_linux_virtual_machine" "vm-sndbx-mm-centralindia" {
  name                = "vm-sndbx-mm-centralindia"
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name
  location            = azurerm_resource_group.rg-sndbx-mm-centralindia.location
  size                = "Standard_D2s_v3"
  admin_username      = "hpsq"
  network_interface_ids = [
    azurerm_network_interface.nic-sndbx-mm-centralindia.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "hpsq"
    public_key = file("~/.ssh/sndbxmmterraformazure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "hpsq"
      identityfile = "~/.ssh/sndbxmmterraformazure" ##access to linux ssh -i "~/.ssh/sndboxmmterraformazure" hpsq@20.244.127.52
    })

    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
data "azurerm_public_ip" "ip-data-mm-centralindia" {
  name                = azurerm_public_ip.ip-sndbx-mm-centralindia.name
  resource_group_name = azurerm_resource_group.rg-sndbx-mm-centralindia.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.vm-sndbx-mm-centralindia.name}: ${data.azurerm_public_ip.ip-data-mm-centralindia.ip_address}"
}