Author: hankwojteczko@davidkentconsulting.com

Last Updated: 08-AUGUST-2022

Author: Hank Wojteczko

OVERVIEW
========
This public repository has been created to show cloud programmers how to create an Azure
automation account using Terraform. We cover all of the steps that Microsoft had once
covered in Azure Issue 4431. Unfortunately Microsoft removed the issue report with
what was an excellent code example. This is our way of helping the developer community
who has helped us on so many times.

REQUIREMENTS
============
These are the package minimum package requirements as of the time of this code creation.
This is the hard way. These days we run container instances. Microsoft explains this best
with an Azure Ubuntu AZ CLI interface with everything you need except for Terraform,
which is quite easy to make available to the container instance via a persistent
storage mount from yourn local developer desktop. A simple example of a pull to run this
container instance would look like:

docker run -u $(id -u):$(id -g) -v ${HOME}:/home/az -e HOME=/home/az --rm -it mcr.microsoft.com/azure-cli:2.38.0

| Package Name                   | Required\nVersion | Package Source                                                                      |
|--------------------------------|-------------------|-------------------------------------------------------------------------------------|
| Python                         | 3.8.13            | Your OS provider or from https://www.python.org/downloads/                          |
| Terraform                      | 1.2.4             | https://www.terraform.io/downloads                                                  |
| Azure CLI                      | 2.38.0            | https://docs.microsoft.com/en-us/cli/azure/install-azure-cli                        |
| Docker Desktop                 | 20.10.17          | If using AZ CLI container instance, https://www.docker.com/products/docker-desktop/ |
| Terraform azurerm plugin       | 2.38.0            | Download using terraform init                                                       |
| Terraform azureread plugin     | 2.26.1            | Download using terraform init                                                       |

