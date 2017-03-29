# Very simple deployment of a 5 Node secure Service Fabric Cluster with Azure Diagnostics enabled


This template allows you to deploy a secure 5 node, Single Node Type Service fabric Cluster running Windows server 2012 R2 Data center on Standard_D2 Size VMs with Windows Azure diagnostics turned on. This template assumes that you already have certificates uploaded to your keyvault, else I strongly suggest you follow one of the two links below.

The accompanying "DeploySFCluster.ps1" will let you select an existing certificate or create a self-signed certificate, that will then be exported (with password), encoded, and uploaded to an existing Azure Key Vault.

Your Key Vault must be in the same region as your Service Fabric Cluster.

The certificate is then deployed to the service fabric cluster and cluster nodes as they are being created.  

## Creating a custom ARM template

If you are wanting to create a custom ARM template for your cluster, then you have to choices.

1. You can acquire this sample template make changes to it. 
2. Log into the azure portal and use the service fabric portal pages to generate the template for you to customize.
3. Log on to the Azure Portal [http://aka.ms/servicefabricportal](http://aka.ms/servicefabricportal).
4. Go through the process of creating the cluster as described in [Creating Service Fabric Cluster via portal](https://docs.microsoft.com/azure/service-fabric/service-fabric-cluster-creation-via-portal) , but do not click on ***create**, instead go to Summary and download the template and parameters.





