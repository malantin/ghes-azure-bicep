# GitHub Enterprise Server Bicep Template for Microsoft Azure
This repository contains sample Azure Bicep (Infrastructure as Code) files to set up GitHub Enterprise Server on Microsoft Azure. The files in this repository should be considered as what they are - samples to help your get started with a Bicep template. The configuration has not been officially vetted or endorsed by GitHub or Microsoft. 

To get started, create a resource group, if you do not have one ready:

`az group create -n <groupname> -l <region>`

Now your can run the template. The region of your deployment will match your resource group:

`az deployment group create -g <groupname> -f ghes.bicep -p ghes.parameters.json`

You will then be asked for an ssh public key and admin password. You will have to set one of those. SSH public key authentication is recommended. After the machine is booted you will have set up ssh credentials for the GHES appliance through the GHES configuration portal.

Please visit the following pages for more information on setting up GitHub Enterprise Server through the CLI or ARM and the required configuration.

If your want to learn more about GitHub Enterprise Server on Azure, the recommended VM sizes, storage configuratioin, required ports and how to set it up using the Azure CLI, visit the [Official GitHub Docs: Installing GitHub Enterprise Server on Azure](https://docs.github.com/en/enterprise-server@3.0/admin/installation/setting-up-a-github-enterprise-server-instance/installing-github-enterprise-server-on-azure)

For the Microsoft Azure Quickstart ARM Template for GHES on Azure visit this page: [GitHub Enterprise Server on Azure Quickstart Template](https://azure.microsoft.com/en-us/resources/templates/github-enterprise/) 

You can check out the Quickstart ARM Template on GitHub.com: [GitHub Enterprise Server Quickstart Template](https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/github-enterprise/github-enterprise)
