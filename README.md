# AWS Serverless Terraform Template

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

**This is an opinionated boilerplate for AWS Serverless based on my experience migrating legacy systems to Cloud.**

## 🎯 Purpose

The goal of this repository is to provide a "production-ready" starting point for serverless applications, focusing on:

1.  **Infrastructure as Code (IaC):** Strict separation of concerns using Terraform modules.
2.  **Security:** Least Privilege Access (IAM) principles applied to Lambda and DynamoDB.
3.  **Scalability:** Utilizing DynamoDB On-Demand and API Gateway v2 (HTTP API) for efficient, event-driven architectures.
4.  **Modernization:** A structure designed to decouple monolithic logic into micro-functions.

## 🏗 Architecture

- **Compute:** AWS Lambda (Node.js)
- **Database:** Amazon DynamoDB (Single Table Design ready)
- **Networking:** API Gateway v2 (HTTP API)
- **IaC:** Terraform with modular design

## 📂 Project Structure

I follow a modular structure to separate reusable infrastructure logic (`modules`) from environment-specific configurations (`environments`), which is crucial for managing Dev, Staging, and Prod lifecycles in enterprise environments.

```text
├── src/                  # Application Logic (Decoupled from Infra)
├── terraform/
│   ├── modules/          # Reusable components (DB, Compute, Network)
│   └── environments/     # Environment instantiation (dev, prod)
```

## 🚀 Usage

1. Navigate to the environment folder:
   ```bash
   cd terraform/environments/dev
   ```
2. Initialize and Apply:
   ```bash
   terraform init
   terraform apply
   ```

---

_Note: This repository serves as a technical artifact demonstrating modernization patterns and IaC best practices._
