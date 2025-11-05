#!/bin/bash

# Script to set up Terraform GCS backend
# This creates the GCS bucket and configures Terraform to use it

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Terraform GCS Backend...${NC}\n"

# Check if project_id is set
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}PROJECT_ID not set. Reading from terraform.tfvars...${NC}"
    if [ -f "terraform.tfvars" ]; then
        PROJECT_ID=$(grep -E '^\s*project_id' terraform.tfvars | sed 's/.*= *"\([^"]*\)".*/\1/' | tr -d '[:space:]')
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}Error: PROJECT_ID not found. Please set it:${NC}"
        echo "  export PROJECT_ID=your-project-id"
        echo "  Or set it in terraform.tfvars"
        exit 1
    fi
fi

echo -e "${GREEN}Using Project ID: ${PROJECT_ID}${NC}"

# Generate bucket name
BUCKET_NAME="${PROJECT_ID}-terraform-state"
LOCATION="us-central1"  # Can be customized

echo -e "\n${YELLOW}Creating GCS bucket: ${BUCKET_NAME}${NC}"

# Check if bucket already exists
if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    echo -e "${GREEN}Bucket ${BUCKET_NAME} already exists!${NC}"
else
    # Create bucket
    echo -e "${YELLOW}Creating bucket in location: ${LOCATION}${NC}"
    gsutil mb -p "${PROJECT_ID}" -l "${LOCATION}" "gs://${BUCKET_NAME}"
    
    # Enable versioning for state history
    echo -e "${YELLOW}Enabling versioning...${NC}"
    gsutil versioning set on "gs://${BUCKET_NAME}"
    
    # Set uniform bucket-level access
    echo -e "${YELLOW}Setting uniform bucket-level access...${NC}"
    gsutil uniformbucketlevelaccess set on "gs://${BUCKET_NAME}"
    
    echo -e "${GREEN}Bucket created successfully!${NC}"
fi

# Create backend config file
BACKEND_CONFIG_FILE="backend.tfconfig"
echo -e "\n${YELLOW}Creating backend configuration...${NC}"
cat > "${BACKEND_CONFIG_FILE}" << EOF
bucket = "${BUCKET_NAME}"
prefix = "time-api-gke/terraform.tfstate"
EOF

echo -e "${GREEN}Backend configuration created in: ${BACKEND_CONFIG_FILE}${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Initialize Terraform with backend:"
echo "   terraform init -backend-config=${BACKEND_CONFIG_FILE}"
echo ""
echo "2. If you have existing local state, migrate it:"
echo "   terraform init -backend-config=${BACKEND_CONFIG_FILE} -migrate-state"
echo ""
echo -e "${GREEN}Backend setup complete!${NC}"

