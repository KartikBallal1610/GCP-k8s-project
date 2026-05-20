# Automated Kubernetes Deployment on GKE

A production-ready CI/CD setup that automatically builds, containerizes, and deploys a Node.js web application to Google Kubernetes Engine whenever code is pushed to `main`.

---

## Live Application

> **URL:** `http://<EXTERNAL_IP>` — filled in after first deploy

---

## Repository Structure

```
.
├── app/
│   ├── server.js          # Node.js Hello World app
│   └── package.json
├── terraform/
│   ├── main.tf            # GKE cluster, VPC, Artifact Registry
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── k8s/
│   ├── deployment.yaml    # Kubernetes Deployment (2 replicas, rolling update)
│   └── service.yaml       # LoadBalancer Service (port 80 → 3000)
├── .github/workflows/
│   └── deploy.yml         # GitHub Actions: build → scan → deploy
├── Dockerfile             # Multi-stage, non-root, Alpine-based
└── README.md
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- A GCP project with billing enabled
- `kubectl` installed

---

## Step 1 — Provision Infrastructure (Terraform)

### 1.1 One-time GCP setup

```bash
# Authenticate
gcloud auth application-default login

# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  --project YOUR_PROJECT_ID

# Create GCS bucket for Terraform state
gsutil mb -p YOUR_PROJECT_ID gs://YOUR_PROJECT_ID-tfstate
gsutil versioning set on gs://YOUR_PROJECT_ID-tfstate
```

### 1.2 Configure variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your project_id
```

Update the `backend "gcs"` bucket name in `main.tf` to match your bucket.

### 1.3 Apply Terraform

```bash
terraform init
terraform plan
terraform apply
```

This provisions:
- A VPC with a private subnet (pods + services secondary ranges)
- A private GKE cluster with a 2-node preemptible node pool
- An Artifact Registry Docker repository
- A least-privilege GKE node service account

---

## Step 2 — Configure GitHub Actions Secrets

The pipeline uses **Workload Identity Federation** (no long-lived JSON keys).

### 2.1 Create a WIF Provider and Service Account

```bash
PROJECT_ID=YOUR_PROJECT_ID
GITHUB_REPO=YOUR_GITHUB_USERNAME/YOUR_REPO_NAME

# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --project $PROJECT_ID

# Grant required roles
for ROLE in \
  roles/container.developer \
  roles/artifactregistry.writer; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role=$ROLE
done

# Create Workload Identity Pool
gcloud iam workload-identity-pools create github-pool \
  --location=global --project $PROJECT_ID

POOL_ID=$(gcloud iam workload-identity-pools describe github-pool \
  --location=global --project $PROJECT_ID \
  --format="value(name)")

# Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --issuer-uri=https://token.actions.githubusercontent.com \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --project $PROJECT_ID

# Allow GitHub repo to impersonate the SA
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GITHUB_REPO}"
```

### 2.2 Add GitHub Secrets

In your GitHub repo → **Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WIF_PROVIDER` | Output of: `gcloud iam workload-identity-pools providers describe github-provider --location=global --workload-identity-pool=github-pool --project $PROJECT_ID --format="value(name)"` |
| `WIF_SERVICE_ACCOUNT` | `github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com` |

---

## Step 3 — Deploy

Push any change to `main`:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

The pipeline will:
1. **Build** the Docker image (multi-stage, cached)
2. **Push** to Artifact Registry
3. **Scan** for vulnerabilities with Trivy (results in Security tab)
4. **Deploy** to GKE via rolling update
5. **Print** the public IP of the LoadBalancer

---

## Design Choices

### Infrastructure
- **Private GKE cluster** — nodes have no public IPs; only the master endpoint is reachable. Reduces attack surface.
- **Preemptible nodes** — up to 80% cost reduction; acceptable for demo/dev workloads.
- **Secondary IP ranges** — VPC-native networking for pods and services (required for GKE best practices).
- **Workload Identity** — avoids long-lived service account JSON keys entirely.

### Container
- **Multi-stage Dockerfile** — builder installs deps; runtime image is minimal Alpine. Final image is ~50MB vs 500MB+ for a full Node image.
- **Non-root user** — `appuser:appgroup` with read-only filesystem; `allowPrivilegeEscalation: false`.
- **Health endpoint** — `/health` used by both Docker HEALTHCHECK and Kubernetes liveness/readiness probes.

### Kubernetes
- **2 replicas + RollingUpdate** (`maxUnavailable: 0`) — zero-downtime deploys.
- **Resource limits** — prevents any one pod from starving the node.
- **LoadBalancer Service** — simplest way to get a public IP on GKE without an Ingress controller.

### CI/CD
- **Three-job pipeline** — build → scan → deploy. Scan runs in parallel with build output; deploy only runs if scan completes.
- **Image tag = Git SHA** — every image is traceable back to an exact commit. `latest` tag is also pushed on `main`.
- **BuildKit cache** — `cache-from/to: type=gha` uses GitHub Actions cache to speed up subsequent builds.
- **Trivy vulnerability scan** — results uploaded to GitHub Security tab as SARIF; pipeline does not fail on findings (set `exit-code: 1` to enforce).

---

## Cleanup

```bash
# Remove Kubernetes resources
kubectl delete -f k8s/

# Destroy GCP infrastructure
cd terraform && terraform destroy
```
