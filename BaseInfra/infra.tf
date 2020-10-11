#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
# Provision Infrastructure 
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

#
# - Provider
#

provider "azurerm" {
    version         =   ">= 2.25"
    client_id       =   var.client_id
    client_secret   =   var.client_secret
    subscription_id =   var.subscription_id
    tenant_id       =   var.tenant_id

    features {}
} 


#
# - Create a Resource Group
#

resource "azurerm_resource_group" "rg" {
    name                  =   "${var.prefix}-rg"
    location              =   var.location
    tags                  =   var.tags
}

#
# - Create a Virtual Network
#

resource "azurerm_virtual_network" "vnet" {
    name                  =   "${var.prefix}-vnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    location              =   azurerm_resource_group.rg.location
    address_space         =   [var.vnet_address_range]
    tags                  =   var.tags
}

#
# - Create a Subnet inside the virtual network
#

resource "azurerm_subnet" "web" {
    name                  =   "${var.prefix}-web-subnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    virtual_network_name  =   azurerm_virtual_network.vnet.name
    address_prefixes      =   [var.subnet_address_range]
}

#
# - Create a Network Security Group
#

resource "azurerm_network_security_group" "nsg" {
    name                        =       "${var.prefix}-web-nsg"
    resource_group_name         =       azurerm_resource_group.rg.name
    location                    =       azurerm_resource_group.rg.location
    tags                        =       var.tags

    security_rule {
    name                        =       "Allow_RDP"
    priority                    =       1000
    direction                   =       "Inbound"
    access                      =       "Allow"
    protocol                    =       "Tcp"
    source_port_range           =       "*"
    destination_port_range      =       3389
    source_address_prefix       =       "49.206.40.168" 
    destination_address_prefix  =       "*"
    
    }
}


#
# - Subnet-NSG Association
#

resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
    subnet_id                    =       azurerm_subnet.web.id
    network_security_group_id    =       azurerm_network_security_group.nsg.id
}

#
# - Public IPs
#

resource "azurerm_public_ip" "pip" {
    count                           =     length(var.vmname)
    name                            =     "pub-ip-${count.index+1}"
    resource_group_name             =     azurerm_resource_group.rg.name
    location                        =     azurerm_resource_group.rg.location
    allocation_method               =     var.allocation_method[0]
    tags                            =     var.tags
}

#
# - Create Network Interface Cards for Virtual Machine
#

resource "azurerm_network_interface" "nic" {
    count                               =     length(var.vmname)
    name                                =     "winvm-nic-${count.index+1}"
    resource_group_name                 =     azurerm_resource_group.rg.name
    location                            =     azurerm_resource_group.rg.location
    tags                                =     var.tags
    ip_configuration                  {
        name                            =     "nic-ipconfig-${count.index+1}"
        subnet_id                       =     azurerm_subnet.web.id
        public_ip_address_id            =     element(azurerm_public_ip.pip.*.id, count.index)
        private_ip_address_allocation   =     var.allocation_method[1]
    }
}


#
# - Create a Windows 10 Virtual Machine
#

resource "azurerm_windows_virtual_machine" "vm" {
    count                             =   length(var.vmname)
    name                              =   var.vmname[count.index]
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    network_interface_ids             =   [element(azurerm_network_interface.nic.*.id, count.index)]
    size                              =   var.virtual_machine_size
    computer_name                     =   var.computer_name[count.index]
    admin_username                    =   var.admin_username[count.index]
    admin_password                    =   var.admin_password

    os_disk  {
        name                          =   "winvm-os-disk-${count.index+1}"
        caching                       =   var.os_disk_caching
        storage_account_type          =   var.os_disk_storage_account_type
        disk_size_gb                  =   var.os_disk_size_gb
    }

    source_image_reference {
        publisher                     =   var.publisher[count.index]
        offer                         =   var.offer[count.index]
        sku                           =   var.sku[count.index]
        version                       =   var.vm_image_version
    }

    tags                              =   var.tags

}
