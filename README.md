# Time API on Google Kubernetes Engine (GKE)

This project demonstrates a complete cloud engineering solution that deploys a simple Time API to Google Kubernetes Engine using Infrastructure as Code (Terraform) and CI/CD with GitHub Actions.

## Project Overview

The Time API is a simple Flask application that returns the current UTC time in JSON format. It's containerized with Docker and deployed to a GKE cluster using Terraform for infrastructure provisioning and GitHub Actions for continuous deployment.

### Architecture

- **Application**: Python Flask API that returns current time
- **Container**: Docker container running the Flask application
- **Infrastructure**: Google Kubernetes Engine (GKE) cluster
- **Networking**: Existing VPC with custom subnet and NAT gateway
- **CI/CD**: GitHub Actions for automated deployment
- **Security**: Service account with least privilege access, firewall rules

## Prerequisites

Before you begin, ensure you have the following:

- Google Cloud Platform account with billing enabled
- GitHub account
- Local development environment with:
  - Git
  - Docker
  - Terraform (v1.0+)
  - Google Cloud SDK
  - Python 3.9+

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/ayoung9598/time-api-gke.git
cd time-api-gke
```

### 2. Set Up Google Cloud

```bash
# Install Google Cloud SDK if not already installed
# https://cloud.google.com/sdk/docs/install

# Authenticate with Google Cloud
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Create a service account for Terraform
export PROJECT_ID=your-project-id
gcloud iam service-accounts create terraform-sa --display-name="Terraform Service Account"

# Get the service account email
export SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:Terraform Service Account" --format='value(email)')

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/editor"

# Create and download service account key
gcloud iam service-accounts keys create terraform-sa-key.json --iam-account=$SA_EMAIL
```

### 3. Configure GitHub Secrets

In your GitHub repository, add the following secrets:

- `GCP_PROJECT_ID`: Your Google Cloud project ID
- `GCP_SA_KEY`: Content of the `terraform-sa-key.json` file
- `NETWORK_NAME`: Name of your existing VPC network

### 4. Local Testing

```bash
# Test the API locally
pip install -r requirements.txt
python app.py

# In another terminal, test the endpoint
curl http://localhost:8080/time
```

### 5. Build and Test Docker Image

```bash
# Build the Docker image
docker build -t time-api:latest .

# Run the container locally (uses Gunicorn in production)
docker run -p 8080:8080 time-api:latest

# Test the containerized API
curl http://localhost:8080/time
```

**Note**: The Dockerfile uses Gunicorn WSGI server for production (2 workers, 2 threads). For local development with Flask dev server, you can override the CMD:

```bash
# Run with Flask dev server instead of Gunicorn
docker run -p 8080:8080 --entrypoint python time-api:latest app.py
```

Or modify the Dockerfile CMD line to:
```dockerfile
CMD ["python", "app.py"]
```

### 6. Set Up Terraform Backend (Remote State)

The project uses GCS backend for remote state storage. Set it up before deploying:

**Linux/Mac:**
```bash
chmod +x setup-backend.sh
./setup-backend.sh
```

**Windows:**
```powershell
.\setup-backend.ps1
```

**Manual Setup:**

If you prefer to set up manually:

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"

# Create the bucket
gsutil mb -p $PROJECT_ID -l us-central1 gs://${PROJECT_ID}-terraform-state

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Create backend config file
cat > backend.tfconfig << EOF
bucket = "${PROJECT_ID}-terraform-state"
prefix = "time-api-gke/terraform.tfstate"
EOF
```

**Benefits of Remote State:**
- State locking prevents concurrent Terraform runs
- Team collaboration with shared state
- Versioning preserves state history
- Security: state not in git repository

### 7. Deploy Infrastructure

```bash
# Initialize Terraform with backend
terraform init -backend-config=backend.tfconfig

# Plan the deployment
terraform plan -var="project_id=$PROJECT_ID" \
               -var="credentials_file=./terraform-sa-key.json" \
               -var="network_name=your-existing-network-name"

# Apply the configuration
terraform apply -var="project_id=$PROJECT_ID" \
                -var="credentials_file=./terraform-sa-key.json" \
                -var="network_name=your-existing-network-name"
```

**Note:** If you have existing local state, use `-migrate-state` flag:
```bash
terraform init -backend-config=backend.tfconfig -migrate-state
```

### 8. Access the Deployed API

After successful deployment, get the external IP:

```bash
kubectl get service time-api -n time-api
```

Then access your API at: `http://EXTERNAL-IP/time`

## Project Structure

```
time-api-gke/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions workflow
├── app.py                      # Flask API application
├── Dockerfile                  # Docker configuration
├── requirements.txt            # Python dependencies
├── providers.tf                # Terraform providers configuration
├── variables.tf                # Terraform variables
├── network.tf                  # VPC and networking resources
├── gke.tf                      # GKE cluster configuration
├── kubernetes.tf               # Kubernetes resources
├── firewall.tf                 # Security rules
├── outputs.tf                  # Terraform outputs
├── backend.tf                  # Active Terraform backend config (GCS)
├── setup-backend.sh            # Backend setup script (Linux/Mac)
├── setup-backend.ps1          # Backend setup script (Windows)
├── terraform.tfvars.example     # Example Terraform variables
├── terraform-sa-key.json       # Service account key (not in git)
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Detailed Configuration

### Infrastructure Components

1. **VPC Networking**: Uses existing VPC with custom subnet
2. **GKE Cluster**: Private cluster with public endpoint
3. **Node Pool**: Single node pool with preemptible instances
4. **NAT Gateway**: For outbound internet access from private nodes
5. **Load Balancer**: Kubernetes LoadBalancer service for external access
6. **Firewall Rules**: Allow HTTP traffic and health checks

### Security Features

- Private GKE nodes with NAT gateway for outbound access
- Service account with minimal required permissions
- Firewall rules restricting access to necessary ports only
- Container resource limits and requests defined
- Network policies for pod-to-pod communication control

### API Endpoints

- `GET /time`: Returns current UTC time in JSON format

Example response:
```json
{
  "current_time": "2024-01-15T10:30:45.123456+00:00"
}
```

## CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Build**: Creates Docker image from source code
2. **Push**: Uploads image to Google Container Registry
3. **Plan**: Shows infrastructure changes to be made
4. **Apply**: Provisions infrastructure with Terraform
5. **Deploy**: Updates Kubernetes deployment with new image
6. **Test**: Verifies API accessibility and functionality

### Workflow Triggers

- Push to `main` branch
- Manual workflow dispatch

## Customization

### Changing the API

To modify the API functionality:

1. Edit `app.py` with your changes
2. Update `requirements.txt` if new dependencies are needed
3. Commit and push to trigger deployment

### Scaling the Application

To change the number of replicas:

1. Edit the `replicas` value in `kubernetes.tf`
2. Apply changes with `terraform apply`

### Resource Limits

Adjust container resources in `kubernetes.tf`:

```hcl
resources {
  limits = {
    cpu    = "0.5"
    memory = "512Mi"
  }
  requests = {
    cpu    = "250m"
    memory = "50Mi"
  }
}
```

## Troubleshooting

### Common Issues

1. **403 Errors**: Check service account permissions
   ```bash
   gcloud projects get-iam-policy $PROJECT_ID
   ```

2. **Connection Refused**: Ensure GKE cluster is running and accessible
   ```bash
   gcloud container clusters get-credentials time-api-cluster --zone=us-central1-a
   ```

3. **Image Pull Errors**: Verify image exists in Container Registry
   ```bash
   gcloud container images list --repository=gcr.io/$PROJECT_ID
   ```

4. **Load Balancer Timeout**: Check firewall rules and health checks
   ```bash
   kubectl describe service time-api -n time-api
   ```

5. **Backend Configuration Issues**: 
   - Ensure GCS bucket exists: `gsutil ls gs://${PROJECT_ID}-terraform-state`
   - Check backend config: `cat backend.tfconfig`
   - Re-initialize: `terraform init -backend-config=backend.tfconfig -reconfigure`

### Debugging Commands

```bash
# Check cluster status
gcloud container clusters describe time-api-cluster --zone=us-central1-a

# View pod logs
kubectl logs -l app=time-api -n time-api

# Check service status
kubectl get services -n time-api

# Describe deployment for issues
kubectl describe deployment time-api -n time-api

# Check pod status
kubectl get pods -n time-api

# View pod events
kubectl describe pod <pod-name> -n time-api
```

## Monitoring and Observability

### Built-in Monitoring

The deployment includes basic monitoring through Google Cloud's operations suite:

- Container insights for cluster monitoring
- Application logs aggregation
- Basic health checks via Kubernetes probes

### Adding Custom Monitoring

To extend monitoring capabilities:

1. Enable additional Google Cloud APIs
2. Add monitoring resources to Terraform configuration
3. Configure alerting policies for critical metrics

## Cost Optimization

This configuration is designed for development/testing with cost optimization in mind:

- Preemptible node instances (up to 80% cost savings)
- Single-node cluster (can be scaled up as needed)
- Efficient resource allocation with defined limits

## Security Best Practices

- **Service Accounts**: Minimal required permissions (roles/editor for Terraform)
- **Private Cluster**: Private GKE nodes with NAT gateway for outbound access
- **Container Security**: Non-root user in Docker containers
- **Resource Limits**: CPU and memory limits defined for all pods
- **Health Checks**: Liveness and readiness probes configured
- **Network Security**: Firewall rules restricting access to necessary ports
- **Secrets Management**: GitHub repository secrets for sensitive data
- **State Security**: Remote state in GCS (not in git), versioning enabled

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and test locally
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Cleanup

To destroy the infrastructure and avoid ongoing costs:

```bash
terraform destroy -var="project_id=$PROJECT_ID" \
                  -var="credentials_file=./terraform-sa-key.json" \
                  -var="network_name=your-existing-network-name"
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions workflow logs
3. Examine Terraform plan output for configuration issues
4. Check Google Cloud Console for resource status

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Cloud Platform for infrastructure services
- Kubernetes community for orchestration platform
- Terraform by HashiCorp for infrastructure as code
- GitHub Actions for CI/CD capabilities

---

**Live API Endpoint**: [Your deployed API URL will appear here after deployment]

**GitHub Actions Status**: [![Deploy to GKE](https://github.com/your-username/time-api-gke/workflows/Deploy%20to%20GKE/badge.svg)](https://github.com/your-username/time-api-gke/actions)
