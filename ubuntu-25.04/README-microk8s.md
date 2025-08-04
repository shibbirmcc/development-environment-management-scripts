# microK8s Installation and Management Guide for Ubuntu 25.04

This guide provides comprehensive information about installing, configuring, and managing microK8s on Ubuntu 25.04.

## 🚀 Quick Start

### Prerequisites
Before running the microK8s installation script, ensure you have installed the required dependencies:

```bash
# 1. Install core dependencies first
./core.sh

# 2. Install Docker (includes containerd runtime)
./docker.sh

# 3. Install Kubernetes tools (kubectl, helm, k9s)
./kubernetes.sh

# 4. Finally, install microK8s
chmod +x microk8s.sh
./microk8s.sh
```

### Standalone Installation
If you prefer to install microK8s without the other scripts, the installation will check for dependencies and warn you if they're missing.

### Post-Installation
```bash
# Reload your shell configuration
source ~/.bashrc  # or ~/.zshrc

# Verify installation
kubectl get nodes
microk8s status
```

## 📋 What Gets Installed

### Core Components
- **microK8s**: Lightweight Kubernetes distribution
- **kubectl**: Kubernetes command-line tool (aliased to microk8s kubectl)
- **Helm**: Kubernetes package manager
- **k9s**: Terminal-based Kubernetes dashboard

### Enabled Add-ons
- **DNS**: CoreDNS for service discovery
- **Dashboard**: Kubernetes web dashboard
- **Storage**: Default storage class
- **Ingress**: NGINX ingress controller
- **Registry**: Local container registry

### Management Scripts
- `microk8s-start`: Start microK8s cluster
- `microk8s-stop`: Stop microK8s cluster
- `microk8s-reset`: Reset cluster (with confirmation)

## 🛠️ Management Commands

### Cluster Management
```bash
# Start microK8s
microk8s-start
# or
sudo microk8s start

# Stop microK8s
microk8s-stop
# or
sudo microk8s stop

# Check status
microk8s status

# Reset cluster (removes all data)
microk8s-reset
```

### kubectl Commands
```bash
# Get cluster information
kubectl cluster-info

# List nodes
kubectl get nodes

# List all pods
kubectl get pods --all-namespaces

# List services
kubectl get services --all-namespaces
```

### Add-on Management
```bash
# List available add-ons
microk8s enable --help

# Enable additional add-ons
sudo microk8s enable metallb:10.64.140.43-10.64.140.49
sudo microk8s enable prometheus
sudo microk8s enable grafana

# Disable add-ons
sudo microk8s disable dashboard
```

## 🌐 Accessing Services

### Kubernetes Dashboard
```bash
# Start dashboard proxy
microk8s dashboard-proxy

# Get dashboard token
microk8s kubectl describe secret -n kube-system microk8s-dashboard-token
```

### Registry
```bash
# Push to local registry
docker tag my-image localhost:32000/my-image
docker push localhost:32000/my-image

# Use in deployments
kubectl create deployment my-app --image=localhost:32000/my-image
```

## 🔧 Configuration

### Kubeconfig
The installation script automatically configures kubectl to work with microK8s:
- Config location: `~/.kube/config`
- Aliases: `kubectl` and `k` point to `microk8s kubectl`

### Shell Integration
Added to your shell profile (`~/.bashrc` or `~/.zshrc`):
```bash
alias kubectl='microk8s kubectl'
alias k='microk8s kubectl'
source <(microk8s kubectl completion bash)
```

## 📊 Monitoring and Debugging

### Using k9s
```bash
# Launch k9s terminal dashboard
k9s

# Navigate with:
# :pods    - View pods
# :svc     - View services
# :deploy  - View deployments
# :ns      - View namespaces
```

### Logs and Troubleshooting
```bash
# View microK8s logs
microk8s inspect

# Check specific pod logs
kubectl logs <pod-name> -n <namespace>

# Describe resources
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🔒 Security Considerations

### User Permissions
- Current user is added to `microk8s` group
- No sudo required for `microk8s` commands after group membership

### Network Security
- Default setup uses host networking
- Consider firewall rules for production use
- Registry is accessible on localhost:32000

### RBAC
```bash
# Create service account
kubectl create serviceaccount my-service-account

# Create role binding
kubectl create clusterrolebinding my-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:my-service-account
```

## 🚀 Common Use Cases

### Development Environment
```bash
# Create a development namespace
kubectl create namespace development

# Deploy a simple application
kubectl create deployment nginx --image=nginx -n development
kubectl expose deployment nginx --port=80 --type=NodePort -n development

# Get service URL
kubectl get service nginx -n development
```

### Local Testing
```bash
# Build and push to local registry
docker build -t localhost:32000/my-app:latest .
docker push localhost:32000/my-app:latest

# Deploy from local registry
kubectl create deployment my-app --image=localhost:32000/my-app:latest
```

### CI/CD Integration
```bash
# Export kubeconfig for CI/CD
microk8s config > kubeconfig.yaml

# Use in CI/CD pipelines
export KUBECONFIG=./kubeconfig.yaml
kubectl apply -f deployment.yaml
```

## 🔄 Backup and Recovery

### Backup Cluster State
```bash
# Backup etcd data
sudo cp -r /var/snap/microk8s/current/var/kubernetes/backend /backup/location/

# Export resources
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
```

### Restore Cluster
```bash
# Stop microK8s
sudo microk8s stop

# Restore etcd data
sudo cp -r /backup/location/backend /var/snap/microk8s/current/var/kubernetes/

# Start microK8s
sudo microk8s start

# Apply resources
kubectl apply -f cluster-backup.yaml
```

## 🐛 Troubleshooting

### Common Issues

#### microK8s won't start
```bash
# Check system resources
free -h
df -h

# Check logs
journalctl -u snap.microk8s.daemon-containerd
microk8s inspect
```

#### DNS not working
```bash
# Restart DNS
sudo microk8s disable dns
sudo microk8s enable dns

# Test DNS
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default
```

#### Registry issues
```bash
# Check registry status
kubectl get pods -n container-registry

# Restart registry
sudo microk8s disable registry
sudo microk8s enable registry
```

#### Permission denied
```bash
# Verify group membership
groups $USER

# Re-add to group if needed
sudo usermod -a -G microk8s $USER
newgrp microk8s
```

### Performance Tuning
```bash
# Increase resource limits
sudo snap set microk8s memory=4Gi
sudo snap set microk8s cpu=2

# Restart after changes
sudo microk8s stop
sudo microk8s start
```

## 📚 Additional Resources

### Official Documentation
- [microK8s Documentation](https://microk8s.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

### Useful Commands Reference
```bash
# Quick reference
kubectl cheat-sheet
microk8s --help

# Get resource definitions
kubectl explain pod
kubectl explain service
kubectl explain deployment
```

### Community and Support
- [microK8s GitHub](https://github.com/canonical/microk8s)
- [Kubernetes Community](https://kubernetes.io/community/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/microk8s)

## 🔧 Customization

### Custom Add-ons
Create custom add-ons in `/var/snap/microk8s/current/addons/`:
```bash
# Example custom addon structure
/var/snap/microk8s/current/addons/my-addon/
├── enable
├── disable
└── addons.yaml
```

### Configuration Files
- Main config: `/var/snap/microk8s/current/args/`
- Certificates: `/var/snap/microk8s/current/certs/`
- Data: `/var/snap/microk8s/current/var/kubernetes/backend/`

---

## 📝 Notes

- This installation avoids using snap store as requested
- All tools are installed via official repositories or binary releases
- Management scripts are created for easy cluster operations
- Shell aliases and completions are automatically configured
- The setup is optimized for development and testing environments

For production deployments, consider additional security hardening and resource allocation based on your specific requirements.
