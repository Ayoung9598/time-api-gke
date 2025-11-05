# PowerShell script to set up Terraform GCS backend
# This creates the GCS bucket and configures Terraform to use it

$ErrorActionPreference = "Stop"

Write-Host "Setting up Terraform GCS Backend..." -ForegroundColor Green
Write-Host ""

# Check if project_id is set
if (-not $env:PROJECT_ID) {
    Write-Host "PROJECT_ID not set. Reading from terraform.tfvars..." -ForegroundColor Yellow
    if (Test-Path "terraform.tfvars") {
        $tfvarsContent = Get-Content "terraform.tfvars" -Raw
        if ($tfvarsContent -match 'project_id\s*=\s*"([^"]+)"') {
            $env:PROJECT_ID = $matches[1].Trim()
        }
    }
    
    if (-not $env:PROJECT_ID) {
        Write-Host "Error: PROJECT_ID not found. Please set it:" -ForegroundColor Red
        Write-Host '  $env:PROJECT_ID = "your-project-id"'
        Write-Host "  Or set it in terraform.tfvars"
        exit 1
    }
}

Write-Host "Using Project ID: $env:PROJECT_ID" -ForegroundColor Green

# Generate bucket name
$BUCKET_NAME = "$env:PROJECT_ID-terraform-state"
$LOCATION = "us-central1"  # Can be customized

Write-Host ""
Write-Host "Creating GCS bucket: $BUCKET_NAME" -ForegroundColor Yellow

# Check if bucket already exists
$bucketExists = $false
try {
    gsutil ls -b "gs://$BUCKET_NAME" 2>$null | Out-Null
    $bucketExists = $true
} catch {
    $bucketExists = $false
}

if ($bucketExists) {
    Write-Host "Bucket $BUCKET_NAME already exists!" -ForegroundColor Green
} else {
    # Create bucket
    Write-Host "Creating bucket in location: $LOCATION" -ForegroundColor Yellow
    gsutil mb -p "$env:PROJECT_ID" -l "$LOCATION" "gs://$BUCKET_NAME"
    
    # Enable versioning for state history
    Write-Host "Enabling versioning..." -ForegroundColor Yellow
    gsutil versioning set on "gs://$BUCKET_NAME"
    
    # Set uniform bucket-level access
    Write-Host "Setting uniform bucket-level access..." -ForegroundColor Yellow
    gsutil uniformbucketlevelaccess set on "gs://$BUCKET_NAME"
    
    Write-Host "Bucket created successfully!" -ForegroundColor Green
}

# Create backend config file
$BACKEND_CONFIG_FILE = "backend.tfconfig"
Write-Host ""
Write-Host "Creating backend configuration..." -ForegroundColor Yellow
@"
bucket = "$BUCKET_NAME"
prefix = "time-api-gke/terraform.tfstate"
"@ | Out-File -FilePath $BACKEND_CONFIG_FILE -Encoding utf8

Write-Host "Backend configuration created in: $BACKEND_CONFIG_FILE" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Initialize Terraform with backend:"
Write-Host "   terraform init -backend-config=$BACKEND_CONFIG_FILE"
Write-Host ""
Write-Host "2. If you have existing local state, migrate it:"
Write-Host "   terraform init -backend-config=$BACKEND_CONFIG_FILE -migrate-state"
Write-Host ""
Write-Host "Backend setup complete!" -ForegroundColor Green

