#!/bin/bash

echo "🚀 Starting Harbor Installation..."

# 1. Add Helm Repo
echo "Adding Harbor Helm repository..."
helm repo add harbor https://helm.goharbor.io
helm repo update

# 2. Install Harbor (Step 1: with placeholder URL)
echo "Installing Harbor (Step 1 - with placeholder URL)..."
helm upgrade --install harbor harbor/harbor \
  --namespace harbor --create-namespace \
  --set expose.type=loadBalancer \
  --set "expose.loadBalancer.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-scheme=internet-facing" \
  --set expose.tls.enabled=false \
  --set externalURL=http://placeholder.local \
  --set harborAdminPassword=Harbor12345 \
  --set persistence.enabled=true \
  --set persistence.persistentVolumeClaim.registry.storageClass=gp2-csi \
  --set persistence.persistentVolumeClaim.database.storageClass=gp2-csi \
  --set persistence.persistentVolumeClaim.redis.storageClass=gp2-csi

# 3. Wait for Harbor pods to be ready
echo "Waiting for Harbor pods to start (this may take 2-3 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/harbor-core -n harbor
kubectl wait --for=condition=available --timeout=300s deployment/harbor-portal -n harbor

# 4. Get the real ALB URL
echo "Waiting for LoadBalancer URL..."
sleep 30
HARBOR_URL=""
for i in $(seq 1 10); do
  HARBOR_URL=$(kubectl get svc harbor -n harbor -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$HARBOR_URL" ]; then
    break
  fi
  echo "  Attempt $i: LoadBalancer not ready yet, waiting 15s..."
  sleep 15
done

if [ -z "$HARBOR_URL" ]; then
  echo "❌ Could not get Harbor LoadBalancer URL. Please run Step 2 manually."
  exit 1
fi

echo "  Found Harbor URL: $HARBOR_URL"

# 5. Re-install Harbor with the real URL
echo "Re-installing Harbor with real URL..."
helm upgrade --install harbor harbor/harbor \
  --namespace harbor \
  --set expose.type=loadBalancer \
  --set "expose.loadBalancer.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-scheme=internet-facing" \
  --set expose.tls.enabled=false \
  --set externalURL=http://$HARBOR_URL \
  --set harborAdminPassword=Harbor12345 \
  --set persistence.enabled=true \
  --set persistence.persistentVolumeClaim.registry.storageClass=gp2-csi \
  --set persistence.persistentVolumeClaim.database.storageClass=gp2-csi \
  --set persistence.persistentVolumeClaim.redis.storageClass=gp2-csi

# 6. Wait for Harbor to be fully ready
echo "Waiting for Harbor to be fully ready..."
sleep 60

# 7. Auto-create the 'prod' project in Harbor
echo "Creating Harbor project 'prod'..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "http://$HARBOR_URL/api/v2.0/projects" \
  -u "admin:Harbor12345" \
  -H "Content-Type: application/json" \
  -d '{"project_name":"prod","public":true}')

if [ "$RESPONSE" = "201" ]; then
  echo "✅ Harbor project 'prod' created successfully!"
elif [ "$RESPONSE" = "409" ]; then
  echo "✅ Harbor project 'prod' already exists."
else
  echo "⚠️  Unexpected response when creating project: HTTP $RESPONSE"
  echo "  Please create the 'prod' project manually in Harbor UI."
fi

echo "------------------------------------------------------------"
echo "✅ Harbor Installation Complete!"
echo "------------------------------------------------------------"
echo "Harbor URL:      http://$HARBOR_URL"
echo "Username:        admin"
echo "Password:        Harbor12345"
echo "Project 'prod':  http://$HARBOR_URL/harbor/projects"
echo "------------------------------------------------------------"
echo "IMPORTANT: Save this URL for configuring Tekton and GitHub Actions:"
echo "  HARBOR_URL=$HARBOR_URL"
echo "------------------------------------------------------------"
