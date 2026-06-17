# Infrastructure Decisions & Session Log

**Project:** Cloud-Agnostic Qwen LLM Deployment  
**Stack:** Terraform · AKS / EKS · ArgoCD · KServe · vLLM  
**Session date:** 2026-06-03  
**Author:** Andy (andyroosberg@gmail.com)  
**Branch:** feat/Andy-AZURE

---

## Project Overview

This project deploys the Qwen generative AI model across multiple cloud providers (AWS, Azure, GCP) in a cloud-agnostic way. The infrastructure layer uses Terraform; the application layer uses ArgoCD for GitOps-driven delivery of KServe, vLLM, cert-manager, NVIDIA device plugin, and the Qwen model itself.

```
/
├── apps/
│   ├── argocd/          ArgoCD bootstrap
│   ├── bootstrap/       App-of-apps pattern
│   ├── cert-manager/    TLS certificate management
│   ├── kserve/          Model serving runtime
│   ├── nvidia/          NVIDIA device plugin (GPU nodes)
│   ├── qwen/            Qwen model deployment manifests
│   └── vllm-runtime/    vLLM inference runtime
└── infra/
    ├── aws/             EKS-based infrastructure (reference implementation)
    ├── azure/           AKS-based infrastructure (this session)
    └── gcp/             (not yet implemented)
```

---

## Session Summary — 2026-06

Three major tasks were completed:

1. **Analysis** — Compared `infra/aws` and `infra/azure`, identified gaps
2. **Refactor** — Built production-ready `infra/azure` from 3 skeletal files → 9 structured files
3. **Pivot & Revert** — Explored a VM-based IaaS approach, then reverted to AKS

---

## Part 1: AWS vs Azure — Initial State Analysis

### AWS structure (reference, 7 files)

| File | Contents |
|---|---|
| `providers.tf` | S3 backend, AWS provider, Kubernetes provider |
| `backend.hcl` | Remote state pointer (S3 + DynamoDB) |
| `variables.tf` | 13 variables (no descriptions) |
| `vpc.tf` | `aws_vpc` + `aws_internet_gateway` |
| `subnets.tf` | 2 private + 2 public subnets, NAT gateway, route tables |
| `iam.tf` | EKS cluster role, node role, OIDC provider |
| `eks.tf` | EKS cluster, node group (r5.4xlarge), security groups, access entries |
| `outputs.tf` | Empty — outputs were incorrectly placed inside `eks.tf` |

### Azure structure (before refactor, 3 files)

| File | Contents |
|---|---|
| `versions.tf` | Provider only — no backend, outdated azurerm `~>3.0` |
| `variables.tf` | 6 variables, no descriptions, hyphenated names (`sue-vnet-subnet-1-name`) |
| `vnet.tf` | Resource group, 1 VNet, 1 subnet — no AKS, no NSGs, no outputs |

### Gaps identified

| Concern | AWS | Azure (before) |
|---|---|---|
| Files | 7 focused files | 3 files |
| Variables | 13, no descriptions | 6, no descriptions |
| Remote state backend | S3 + DynamoDB + `backend.hcl` | None |
| Outputs | Misplaced in `eks.tf` | None |
| Compute cluster | EKS + node group + security groups | None |
| IAM / Identity | 3 IAM roles + OIDC provider | None |
| Network Security | 2 security groups with rules | None |
| Subnets | 4 (2 private + 2 public) | 1 |
| `terraform.tfvars` | None | None |
| Tagging | `merge(var.tags, { Name = … })` | No tags at all |

## Part 2: Azure Refactor — Production-Ready AKS

### Final file structure (9 files)

| File | Purpose | AWS equivalent |
|---|---|---|
| `versions.tf` | Provider (`azurerm ~>4.0`) + empty backend block | `providers.tf` |
| `backend.hcl` | Azure Storage remote state pointer | `backend.hcl` |
| `variables.tf` | 40+ variables with descriptions and validation | `variables.tf` |
| `terraform.tfvars` | Variable values  |
| `vnet.tf` | Resource group, VNet, 2 subnets, NSG associations | `vpc.tf` + `subnets.tf` |
| `nsg.tf` | 2 NSGs with ingress rules | Security groups in `eks.tf` |
| `identity.tf` | User Assigned Managed Identity + Network Contributor role | `iam.tf` |
| `aks.tf` | AKS cluster + node pool | `eks.tf` |
| `outputs.tf` | All outputs in one place | Outputs from `eks.tf` |

### AWS ↔ Azure resource equivalences

| AWS | Azure | Notes |
|---|---|---|
| `aws_vpc` | `azurerm_virtual_network` | Same CIDR `10.0.0.0/16` |
| Private subnets (×2) | `sue-nodes-subnet` (`10.0.1.0/24`) | AKS nodes placed here |
| Public subnets (×2) | `sue-public-subnet` (`10.0.101.0/24`) | Ingress LBs placed here |
| `aws_security_group` eks_nodes_sg | `azurerm_network_security_group` sue_nsg_nodes | Control plane → nodes, node-to-node |
| `aws_security_group` eks_cluster_sg | `azurerm_network_security_group` sue_nsg_public | HTTPS/HTTP ingress |
| `aws_eks_cluster` | `azurerm_kubernetes_cluster` | — |
| `aws_eks_node_group` | `default_node_pool` (inside AKS resource) | — |
| `aws_iam_role` eks_cluster_role | `azurerm_user_assigned_identity` | Control plane identity |
| `aws_iam_role_policy_attachment` eks_vpc_resource_controller | `azurerm_role_assignment` Network Contributor | Allows AKS to manage NICs/LBs |
| `aws_iam_openid_connect_provider` | `oidc_issuer_enabled = true` | OIDC for Workload Identity |
| `aws_eks_access_entry` admin_users | `azure_active_directory_role_based_access_control` | AAD group → cluster admin |
| `r5.4xlarge` (16 vCPU / 128 GiB) | `Standard_E16s_v5` | Memory-optimised, LLM inference |

### Key design decisions

**UserAssigned identity (not SystemAssigned)**  
AKS needs Network Contributor on the resource group to create load balancers for node pools. With SystemAssigned, the cluster must exist before its identity is known — a chicken-and-egg problem. UserAssigned lets the role assignment be created first, then the cluster is given `depends_on = [azurerm_role_assignment.aks_network_contributor]`.

**kubenet CNI (not azure CNI)**  
Simpler IP management: pods get IPs from `pod_cidr` (`10.244.0.0/16`), which is separate from the VNet address space. Azure CNI requires far more IP addresses allocated in the subnet upfront.

**azurerm `~> 4.0` (not 3.x)**  
v4 renamed several boolean attributes (`enable_auto_scaling` → `auto_scaling_enabled`, etc.) and added `gpu_driver` support on node pools. All resources in this module use v4 attribute names.

**Backend storage (Azure Storage Account)**  
Equivalent to the AWS S3 + DynamoDB pattern. Requires a pre-existing storage account (`suetfstate`) in resource group `sue-tf-state-rg`. Create with:
```bash
az group create -n sue-tf-state-rg -l germanywestcentral
az storage account create -n suetfstate -g sue-tf-state-rg -l germanywestcentral --sku Standard_LRS
az storage container create -n tfstate --account-name suetfstate
```
Then: `terraform init -backend-config=backend.hcl`

### Variables summary (40+ declared, all with descriptions)

| Group | Variables |
|---|---|
| General | `location`, `environment`, `project_name`, `tags` |
| Resource Group | `resource_group_name` |
| VNet | `vnet_name`, `vnet_address_space`, `node_subnet_name`, `node_subnet_address_prefix`, `public_subnet_name`, `public_subnet_address_prefix` |
| NSG | `nsg_node_name`, `nsg_public_name`, `allowed_https_cidr_blocks`, `allowed_http_cidr_blocks` |
| AKS Cluster | `cluster_name`, `kubernetes_version`, `dns_prefix`, `private_cluster_enabled`, `sku_tier`, `admin_group_object_ids`, `local_account_disabled`, `azure_rbac_enabled` |
| Node Pool | `default_node_pool_name`, `default_node_pool_vm_size`, `default_node_pool_node_count`, `default_node_pool_min_count`, `default_node_pool_max_count`, `default_node_pool_os_disk_size_gb`, `default_node_pool_os_disk_type`, `default_node_pool_max_pods`, `enable_auto_scaling`, `node_labels` |
| Network Profile | `network_plugin`, `network_policy`, `service_cidr`, `dns_service_ip`, `pod_cidr`, `outbound_type`, `load_balancer_sku` |
| Identity | `identity_name` |
| Security | `oidc_issuer_enabled`, `workload_identity_enabled`, `enable_azure_policy` |
| Monitoring | `enable_oms_agent`, `log_analytics_workspace_id` |

---

## Part 3: VM Pivot (Explored, then Reverted)

### What happened

A decision was made to pivot from AKS (PaaS Kubernetes) to a plain IaaS Virtual Machine approach. The following changes were made to `infra/azure`:

**Files replaced/created:**
- `aks.tf` → replaced with `azurerm_public_ip` + `azurerm_network_interface` + `azurerm_linux_virtual_machine`
- `nsg.tf` → AKS control-plane rules replaced with SSH rule (port 22)
- `outputs.tf` → AKS outputs replaced with `vm_public_ip`, `vm_private_ip`, `ssh_connection_string`
- `identity.tf` → `azurerm_role_assignment` removed (not needed for plain VM)
- `variables.tf` → 30 AKS variables removed, 8 VM variables added
- `terraform.tfvars` → AKS values removed, VM values added

**VM spec that was configured:**
- Size: `Standard_E4s_v3` (4 vCPU / 32 GiB RAM)
- Image: Ubuntu 22.04 LTS Gen2 (`Canonical / 0001-com-ubuntu-server-jammy / 22_04-lts-gen2`)
- Auth: SSH key only (`disable_password_authentication = true`)
- OS disk: 128 GiB Premium_LRS
- Identity: UserAssigned managed identity (for ACR / Key Vault access)

**Old AKS config was moved to `_archive/`** (3 files: `identity.aks.tf`, `aks_variables.tf`, `aks.tfvars`)

### Why it was reverted

The decision was made to revert to the original AKS-based approach. On revert:
- `_archive/` was deleted
- `aks.tf`, `identity.tf`, `nsg.tf`, `outputs.tf`, `variables.tf`, `terraform.tfvars` were all fully restored
- `errored.tfstate` and `tfplan` leftover artifacts were also deleted

---

## Part 4: Current State — infra/azure

### Active configuration (as of session end)

```
infra/azure/
├── .terraform/              Provider cache (gitignored)
├── .terraform.lock.hcl      Provider version lock
├── backend.hcl              Remote state: Azure Storage (sue-tf-state-rg / suetfstate / tfstate)
├── versions.tf              azurerm ~>4.0, backend "azurerm" {}
├── variables.tf             40+ variables
├── terraform.tfvars         Active variable values (see below)
├── vnet.tf                  Resource group, VNet, 2 subnets, NSG associations
├── nsg.tf                   sue_nsg_nodes (AKS rules) + sue_nsg_public (HTTP/HTTPS)
├── identity.tf              sue_aks_identity + Network Contributor role assignment
├── aks.tf                   azurerm_kubernetes_cluster (sue_aks)
└── outputs.tf               cluster_name, cluster_endpoint, kube_config_raw, oidc_issuer_url, etc.
```

### Active terraform.tfvars values

| Variable | Value | Notes |
|---|---|---|
| `location` | `germanywestcentral` | Matches AWS eu-central-1 (Frankfurt) |
| `kubernetes_version` | `1.35` | Latest used in testing |
| `default_node_pool_vm_size` | `Standard_E16s_v5` | 16 vCPU / 128 GiB, matches r5.4xlarge |
| `enable_auto_scaling` | `true` | min 1, max 4 |
| `network_plugin` | `kubenet` | Simpler IP management |
| `oidc_issuer_enabled` | `true` | Required for Workload Identity |
| `sku_tier` | `Free` | No SLA — upgrade to Standard for production |

### Deployment commands

```bash
# 1. Authenticate
az login

# 2. Create state storage (first time only)
az group create -n sue-tf-state-rg -l germanywestcentral
az storage account create -n suetfstate -g sue-tf-state-rg -l germanywestcentral --sku Standard_LRS
az storage container create -n tfstate --account-name suetfstate

# 3. Init and deploy
cd infra/azure
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# 4. Get kubeconfig
terraform output -raw kube_config_raw > ~/.kube/config
```

---

## Appendix: File-by-File Reference

### versions.tf

```hcl
terraform {
  backend "azurerm" {}          # values supplied via backend.hcl
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
provider "azurerm" {
  features {
    resource_group { prevent_deletion_if_contains_resources = false }
  }
}
```

### backend.hcl

```hcl
resource_group_name  = "sue-tf-state-rg"
storage_account_name = "suetfstate"
container_name       = "tfstate"
key                  = "infra/azure/terraform.tfstate"
use_azuread_auth     = true
```

### Key resource names

| Terraform resource | Azure name |
|---|---|
| `azurerm_resource_group.sue_resource_group` | `sue-resource-group` |
| `azurerm_virtual_network.sue_vnet` | `sue-vnet` |
| `azurerm_subnet.sue_nodes_subnet` | `sue-nodes-subnet` |
| `azurerm_subnet.sue_public_subnet` | `sue-public-subnet` |
| `azurerm_network_security_group.sue_nsg_nodes` | `sue-nsg-nodes` |
| `azurerm_network_security_group.sue_nsg_public` | `sue-nsg-public` |
| `azurerm_user_assigned_identity.sue_aks_identity` | `sue-aks-identity` |
| `azurerm_role_assignment.aks_network_contributor` | *(no name — RBAC assignment)* |
| `azurerm_kubernetes_cluster.sue_aks` | `sue-aks-cluster` |
