####################
# Common Variables #
####################
environment = "development"
location    = "centralus"

##############################
# Authentication             #
# (need replace these values #
##############################
azure-subscription-id = "<insert your subscription-id here>"
azure-client-id       = "<insert your client-id here>"
azure-client-secret   = "<insert your client-secret here>"
azure-tenant-id       = "<insert your tenant-id here>"

###########
# Network #
###########
network-vnet-cidr   = "10.128.0.0/16"
network-subnet-cidr = "10.128.1.0/24"

######
# VM #
######
vm-hostname       = "tfvmsrv"
vm-size           = "Standard_B1ls"
vm-admin-username = "udacity-admin"
vm-admin-password = "S3cr3ts24"
