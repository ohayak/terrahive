# TerraHive Project Structure

TerraHive is a project structure designed to assist DevOps teams in managing Terraform code across multiple environments and teams. Terraform is an infrastructure-as-code (IaC) tool that allows users to define and provision data center infrastructure using a declarative configuration language.

In large organizations, managing Terraform configurations for multiple environments (e.g., development, staging, production) and multiple teams can be challenging. TerraHive aims to streamline this process by defining **Hives**. Each Hive may represent a different product, team, or functional group, and may have unique infrastructure requirements.

## Directory Structure

```
TerraHive/
│
├── tfgh                                # CLI to execute terraform/terragrunt commands (type `tfgh -h` for help)
│
├── terraform/                          # Terraform modules
│   ├── network/                        # Reusable Terraform modules
│   └── hive1/mymodule                  # Hive-specific Terraform modules
│
├── terragrunt/                         # Terragrunt configurations
│   ├── backend/                        # Reusable backend definitions
│   ├── modules/                        # Terragrunt declaration of terraform modules (module path dependencies, default inputs)
│   └── providers/                      # Reusable providers definitions
│
└── terrahive/                          # TerraHive configurations
    ├── root.hcl
    └── dev/                            # Deployment environment
         ├── env.hcl                    # Environment-specific configurations like iam_role
         └── hive1/                     # Hive-specific deployment
             ├── network/  
             │   └── terragrunt.hcl  
             └── mymodule  
                 └── terragrunt.hcl  
```

## terraform/

This directory contains all the Terraform modules.

### terraform/network/

This subdirectory should contain reusable Terraform modules that can be used across different hives.

### terraform/hive1/mymodule

This subdirectory should contain Hive-specific Terraform modules. Each Hive may represent a different product, team, or functional group.

## terragrunt/

This directory contains Terragrunt configuration files. Terragrunt is a thin wrapper that provides extra tools for keeping your configurations DRY, working with multiple Terraform modules, and managing remote state.

### terragrunt/backend/

This subdirectory should contain reusable backend definitions.

### terragrunt/modules/

This subdirectory should contain Terragrunt declarations of Terraform modules. This includes specifying module path dependencies and default inputs.

### terragrunt/providers/

This subdirectory should contain reusable provider definitions.

## terrahive/

This directory contains TerraHive specific configurations.

### terrahive/root.hcl

This file should contain the root configuration for TerraHive.

### terrahive/dev/

This subdirectory should contain deployment environments. Within each environment, there should be environment-specific configurations and Hive-specific deployments.

## 📝 Acknowledgements

* script created with [bashew](https://github.com/pforret/bashew)

&copy; 2022 omar hayak
