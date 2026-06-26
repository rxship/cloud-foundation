# CloudFoundation — Azure Enterprise Landing Zone (Terraform)

A governed, reusable Azure foundation built entirely with Terraform, and deployed by a GitHub Actions pipeline that authenticates to Azure with **no stored secrets** (OIDC).

A *landing zone* is the networking, security, and governance base you build **before** deploying any application — so every workload lands in a consistent, secure, policy-controlled environment. Think of it as laying the roads, utilities, security gate, and zoning rules of a neighborhood before any houses get built.

---

## What it builds

| Layer | What it is, in plain terms | Key Azure resources |
|-------|----------------------------|---------------------|
| **Remote state** | Terraform's "memory" of what it built, stored safely in Azure instead of on a laptop | Storage Account + Blob container |
| **Networking** | A central "hub" network and an isolated "spoke" network, connected | Hub & spoke VNets, subnets, VNet peering |
| **Network security** | A firewall on the workload subnet — allow web traffic in, block admin ports | Network Security Group (NSG) |
| **Secrets** | A vault for passwords/keys so they never live in code | Key Vault (RBAC mode) |
| **Private access** | The vault reached over a private IP inside the network, not the public internet | Private Endpoint + Private DNS Zone |
| **Governance** | Rules for *what* can exist and *who* can do things | Azure Policy (Canada-only), custom RBAC role |

---

## Tech stack

- **IaC:** Terraform (reusable modules + per-environment config)
- **Cloud:** Microsoft Azure (region: Canada Central)
- **State:** Azure Blob Storage, with isolated state per environment
- **CI/CD:** GitHub Actions
- **Auth:** OpenID Connect (OIDC) federation — passwordless GitHub → Azure
- **Identity & security:** Microsoft Entra ID, RBAC, Azure Policy, NSGs, Private Link

---

## Repository structure

```
cloud-foundation/
├── modules/                  # reusable building blocks (like functions)
│   ├── networking/           # hub + spoke VNets, subnets, peering, NSG
│   ├── security/             # Key Vault, private endpoint, private DNS
│   └── governance/           # Azure Policy + custom RBAC role
├── environments/             # callers that use the modules with real values
│   ├── dev/                  # dev environment (applied)
│   └── prod/                 # prod environment (proven by plan, not applied)
└── .github/workflows/
    └── terraform.yml         # plan-on-PR, apply-on-merge pipeline
```

**Mental model:** a module is a *function* — `variables.tf` are its inputs, `main.tf` is the body, `outputs.tf` is what it returns. An environment is the *caller* that runs those functions with its own values and its own state file.

---

## How the pipeline works

The pipeline follows a **plan-on-PR, apply-on-merge** pattern:

1. **Open a pull request** → the `plan` job runs `terraform plan` and shows what *would* change. Nothing is applied — it's a preview for review.
2. **Merge to `main`** → the `apply` job runs `terraform apply` and makes the change real.

Authentication uses **OIDC federation**: instead of storing an Azure password in GitHub, an Azure identity is configured to *trust GitHub's own token* for this specific repo. For each run, GitHub issues a short-lived token, Azure verifies it against a trust rule, and grants temporary access. **No long-lived secret is stored anywhere.**

---

## Design decisions (and why)

These are deliberate trade-offs, each defensible in an interview:

- **OIDC instead of a stored client secret** — a pasted secret can leak and never expires. OIDC stores nothing, and every token expires in minutes.
- **Separate state file per environment** — dev and prod use the same code but different state files (different "keys") in the same storage account. This keeps their records fully isolated so they can never overwrite each other.
- **`Owner` role on the pipeline identity (not `Contributor`)** — the Terraform manages RBAC and Policy, and `Contributor` is explicitly *not allowed* to manage those. In production this would be narrowed to least privilege; here it keeps the focus on the architecture.
- **`purge_protection` disabled on Key Vault** — it's a one-way switch that blocks full deletion. Kept off so the portfolio can be torn down cleanly; in production it would be on.
- **Key Vault admin pinned to an explicit object ID** — see the debugging story below.
- **NSG resource names not parameterized per environment** — names only need to be unique *within* a resource group, and each environment has its own. Parameterizing every name would be over-engineering; only the names that would *lie* (e.g. the spoke VNet) are made environment-aware.

---

## A real bug I root-caused

The Key Vault secrets-admin role assignment was originally written as:

```hcl
principal_id = data.azurerm_client_config.current.object_id
```

That data source returns **whoever is currently authenticated**. When run from my laptop, "current" was my user account. When the pipeline ran it, "current" was the OIDC service principal. So the role assignment flip-flopped on every run — local runs pointed it at me, CI runs pointed it at the robot — and the two would have churned against each other indefinitely.

**Fix:** pin the value to an explicit, named object ID instead of "whoever's running." A hardcoded value is the same regardless of the driver, so the churn stopped. Local `plan` and CI now agree.

**Lesson:** don't tie a resource to "current identity" when more than one identity will run the same code.

---

## How to run it

**Prerequisites:** an Azure subscription, the Azure CLI (`az login`), and Terraform.

1. **Bootstrap the state backend** (one-time, with the Azure CLI) — create a resource group, storage account, and blob container to hold Terraform state.
2. **Point `environments/dev/backend.tf`** at that storage account.
3. **Deploy:**
   ```bash
   cd environments/dev
   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   terraform init
   terraform plan
   terraform apply
   ```
4. **Tear down** when finished: `terraform destroy`.

For automated deploys, the GitHub Actions workflow handles plan/apply once the OIDC identity and the `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` repo secrets are configured.

---

## Status

- **dev** — fully deployed and verified.
- **prod** — proven by `terraform plan` (full environment ready to build from the same modules); not applied, to stay within free-tier limits.
- **Pipeline** — live; authenticates via OIDC and gates changes through pull requests.