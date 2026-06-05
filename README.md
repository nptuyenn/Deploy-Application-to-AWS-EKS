# Microservices Deployment on AWS EKS Through DevOps pipeline: "Todo Application"

## This project demonstrates a production-grade, secure, and fully automated **GitOps** pipeline on AWS EKS. It features a private networking architecture, internal image registry, cluster-native CI/CD, and full observability.

## Architecture Overview

![Architecture Diagram](docs/architecture.svg)

### 1. 🌍 Infrastructure (AWS & Terraform)

- **VPC:** Custom VPC with **Private** and **Public** subnets.
- **Security:**
  - **Worker Nodes:** Run in **Private Subnets** (No Public IPs). Secure from the internet.
  - **Public Access:** Via **Application Load Balancers (ALB)** in Public Subnets.
  - **Outbound:** Private nodes access the internet via **NAT Gateway**.
- **Compute:** AWS EKS Cluster with `t3.large` Node Group (Auto-Scaling enabled).

### 2. Networking & Access

- **Ingress:** AWS Application Load Balancer (ALB) routes traffic to the Frontend and Microservices.
- **Tools Access:** Dedicated Load Balancers for Ops tools:
  - **Harbor:** Private Image Registry.
  - **ArgoCD:** GitOps Controller.
  - **Tekton:** CI Event Listener.
  - **Grafana:** Monitoring Dashboard.

---

## Prerequisites

- **AWS CLI** (`aws configure`)
- **Terraform** (v1.3+)
- **Kubectl**
- **Helm** (v3+)

---

## Setup Guide

### Phase 1: Infrastructure Provisioning

Create the secure network and cluster.

1.  **Initialize Backend:**
    ```bash
    cd EKS-TF/backend-setup
    terraform init && terraform apply --auto-approve
    ```
2.  **Deploy EKS Cluster:**
    ```bash
    cd ../
    terraform init
    terraform apply -var-file variable.tfvars --auto-approve
    ```
3.  **Connect Kubectl:**
    ```bash
    aws eks update-kubeconfig --region us-east-1 --name ToDo-EKS-Cluster
    ```

### Phase 2: System Components Installation

Install the critical "Ops" software.

1.  **Install AWS Load Balancer Controller:**
    ```bash
    ./infra/install_alb.sh
    ```
2.  **Install Harbor (Registry):**
    ```bash
    # Ensure you create the 'prod' project in Harbor UI after installation.
    # Default Pass: Harbor12345
    ```
3.  **Install Monitoring (Prometheus/Grafana):**
    ```bash
    ./infra/install_monitoring.sh
    ```
4.  **Install ArgoCD:**
    ```bash
    ./infra/install_argocd.sh
    ```

### Phase 3: Configure CI/CD (Tekton)

Deploy the build pipeline.

1.  **Configure Secrets:**
    Edit `tekton-pipeline/secrets.yaml` with your **GitHub Token** and **Harbor Password**.
2.  **Apply Pipeline:**

    ```bash
    # Install Git-Clone Task
    kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml

    # Deploy Custom Pipeline
    kubectl apply -f tekton-pipeline/
    ```

3.  **Expose Listener:**
    ```bash
    kubectl annotate service el-cd-listener service.beta.kubernetes.io/aws-load-balancer-scheme=internet-facing --overwrite
    ```
4.  **Connect GitHub:**
    - Get the Listener URL: `kubectl get svc el-cd-listener`
    - Add secret `TEKTON_EL_URL` to GitHub Repository Secrets.

### Phase 4: Deploy Applications (GitOps)

We use **Kustomize** for multi-environment deployment.

1.  **Create Namespaces:**
    ```bash
    kubectl apply -f k8s/namespaces.yml
    ```
2.  **Configure ArgoCD:**
    Connect ArgoCD to your Git repo and point it to the overlays:
    - **Dev App:** `k8s/overlays/dev` -> Namespace `dev`
    - **Prod App:** `k8s/overlays/prod` -> Namespace `prod`

---

## Monitoring & Maintenance

- **Grafana:** View Node/Pod health. Login with `admin` / (See secret).
- **Harbor:** Manage Docker images.
- **ArgoCD:** View deployment status.
