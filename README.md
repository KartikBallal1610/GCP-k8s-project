# Automated Kubernetes Deployment on GKE
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform) ![GCP](https://img.shields.io/badge/GCP-4285F4?style=flat&logo=googlecloud) ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes) ![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=githubactions)
A CI/CD pipeline that automatically builds, containerizes, and deploys a Node.js Hello World app to Google Kubernetes Engine on every push to `main`.

## Live Application
**URL:** http://34.133.119.102/

## Overview
- **App:** Node.js Hello World served on port 3000
- **Infrastructure:** GKE cluster provisioned via Terraform on GCP
- **Pipeline:** GitHub Actions — build → vulnerability scan → deploy
- **Registry:** GCP Artifact Registry
- **Secrets:** GCP Secret Manager synced to Kubernetes Secrets
- **Packaging:** Helm chart for Kubernetes manifests

## Design Choices

**Infrastructure**
- Private GKE cluster with preemptible nodes — reduces attack surface and cost
- Workload Identity Federation — no long-lived JSON keys needed

**Container**
- Multi-stage Alpine Dockerfile — final image ~50MB
- Runs as non-root user with least privilege

**Kubernetes**
- 2 replicas with `maxUnavailable: 0` — zero-downtime rolling deploys
- Helm chart for templated, reusable manifests

**CI/CD**
- Trivy vulnerability scan on every build — results in GitHub Security tab
- Image tagged with Git SHA — every deploy traceable to a commit
- GCP Secret Manager for secrets — never stored in code or GitHub

## How to Run

### 1. Provision Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Set your project_id in terraform.tfvars
terraform init
terraform apply
```

### 2. Configure GitHub Secrets
Add these 3 secrets in GitHub → Settings → Secrets → Actions:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WIF_PROVIDER` | Workload Identity Provider resource name |
| `WIF_SERVICE_ACCOUNT` | `github-actions-sa@PROJECT_ID.iam.gserviceaccount.com` |

### 3. Deploy
Push to `main` — the pipeline triggers automatically:
```bash
git push origin main
```



## Cleanup
```bash
cd terraform && terraform destroy
```
