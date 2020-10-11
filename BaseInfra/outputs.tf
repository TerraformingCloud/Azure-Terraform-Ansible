

output "rgname" {
    value   =   azurerm_resource_group.rg.name
}

output "location" {
    value   =   azurerm_resource_group.rg.location
}

output "subnetid" {
    value   =   azurerm_subnet.web.id
}