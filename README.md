# Udacity-DevOps-Azure-Project-1

Deploying a scalable IaaS web server in Azure using Azure CLi, Packer &amp; Terraform.

## Dependencies

1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Getting Started

1. Clone this repository
2. Setting the Azure Policy
3. Create environment variables
4. Modify the packer file
5. Modify terraform variable files if necessary

## Instructions

### Clone this repo

git clone https://github.com/jfcb853/Udacity-DevOps-Azure-Project-1.git

### Login to Azure CLI

```sh
az login
```

### Policy

Connected to Azure CLI ( or Azure PwerShell), perform the following:

a. Create the Policy Definition

```sh
az policy definition create --name tagging-policy  --rules Policy\tagging_policy.rules.json \
   --param Policy/tagging_policy.params.json
```

b. Show the Policy definition

```sh
az policy definition show --name tagging-policy
```

c. Assign the Policy ( naming "tagging-policy") to the global Scope ( subscription scope in this case)

```sh
az policy assignment create --name tagging-policy --policy tagging-policy --param Policy/tagging_assignment.params.json
```

d. Check the policy was assigned:

```sh
az policy assignment show --name tagging-policy
```

or

```sh
az policy assignment list
```

Note: Check the image uploaded on the direc=tory "Policy" (must be similar to that)

### Packer

a. Create a resource group for your image. It will be used as a variable with default value into packer file "server.json" ( example: `udacity-packerimage-rg`), also will be used in terraform

```sh
az group create -l centralus -n udacity-packerimage-rg
```

b. Modify the variable sections into packer file `server.json` so the image builds in your preferred region, and use the resource group name created above

c. Create a RBAC ( Service principal) account , using the following command:

```sh
az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```

and check your subscription id

```sh
az account show --query "{ subscription_id: id }"
```

Note: take notes of the results since you will need export the variables to your ENV , so Packer `server.json` file could use it ( see variable {env `CLIENT_ID`})

d. Export ( set) the following variables that will be used in `server.json`

```sh
export CLIENT_ID="<rbac account client_id value from above command>"
export CLIENT_SECRET="<rbac account client_secret value from above command>"
export TENANT_ID="<rbac  account tenant_id value from above command>"
export SUBSCRIPTION_ID="<subscription_id value from above command> "

Note: check with echo $CLIENT_ID ( for example)
```

e. Run the following command to build your server image. This may take a while ( approx 10 minutes) so grab a cup of coffee.

```sh
packer build Packer/server.json
```

Note: results could be similar to this

```bash
...

Build 'azure-arm' finished after 10 minutes 33 seconds.

==> Wait completed after 10 minutes 33 seconds

==> Builds finished. The artifacts of successful builds are:
--> azure-arm: Azure.ResourceManagement.VMImage:

OSType: Linux
ManagedImageResourceGroupName: udacity-packerimage-rg
ManagedImageName: udacity-server-image
ManagedImageId: /subscriptions/69c056e3-3492-4df2-9184-9b34ec11c1ba/resourceGroups/udacity-packerimage-rg/providers/Microsoft.Compute/images/udacity-server-image
ManagedImageLocation: centralus
...
```

### Terraform

The terraform file creates the following resources listed below:

- resource group
- virtual network
- subnet
- network security group limiting access ( 4 minimum rules now!!!)
- network interfaces
- a public ip
- load balancer
- availability set for the virtual machines
- Linux virtual machines (3 by default)
- 1 managed disk per instance

to do that use the files:
| Files | Description|
| ------ | ------ |
|main.tf| Provider and resources|
|vars.tf| Variables|
|locals.tf| Security Rules block for our Net Security Group Rules|
|terraform.tfvars| to provide default variable values|

Note:

- Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration. That's why we are using here in `locals.tf` file ( as a block that will be used in a resource "azurerm_network_security_rule" multiple times )

a. Therefore, basically use the `terraform.tfvars` to add yor variables ( location , client_id, client_secret, tenant_id, subscription_id; some network settings, some vm settings)

- use the same values , for example, of the commands that you executed already in packer

```sh
az account show --query "{ subscription_id: id }"
az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```

a. Go to `Terraform` directory and Run `terraform init` to prepare your directory for terraform

```sh
cd Terraform
pwd
terraform init

```

b. validate the files

```sh
terraform validate
```

c. to create an execution plan named "solution.plan"

```sh
terraform plan -out solution.plan
```

d. Create the Infrastructure ( wait some minutes) :

```sh
terraform apply solution.plan
```

e. You can get as an output result , the URL of the Load balancer
Example:

```sh
Outputs:

lb_url = "http://52.165.135.210/"
```

f. You can check your IaaC is working with `curl` command or going to that URL in your browser

```sh
curl http://40.77.66.54/

result:
Hello World!!!
```

g. Many resources were created ( 17 in total in our case, using 3 VM)

### Destroying the Resources ( deletion process)

- delete the Terraform resources first ( you are still inside the Terraform directory)

```sh
pwd
terraform plan -destroy -out solution.destroy.plan
terraform apply solution.destroy.plan
```

- delete the packer image

```sh
az image delete --name udacity-server-image  --resource-group udacity-packerimage-rg
```

- delete the Resource Group used in Packer

```sh
az group delete -n udacity-packerimage-rg
```

- delete the Policy Assignment

```sh
az policy assignment delete --name tagging-policy
```

- delete the Policy Definition

```sh
az policy definition delete --name tagging-policy
```

That's all!!!!!!!!!

## License

MIT

**Free Software, Hell Yeah!**
