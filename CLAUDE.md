# Vanilla Forums - Platform Application

**Status**: Production-Ready Application (Kubernetes Deployment)
**Access**: https://vanilla.lab.hq.solidrust.net
**Type**: PHP-based forum application with React frontend

**Shaun's Golden Rule**: No workarounds, complete solutions only. Full manifests, production-ready.

---

## ⚡ AGENT QUICK START

- **What**: Vanilla Forums - modern, customizable discussion forum platform
- **Stack**: PHP 8.1 + MySQL + React + Nginx
- **Architecture**: Multi-container pod (PHP-FPM + Nginx)
- **Deploy**: `.\deploy.ps1 -Build -Push` (from this directory)
- **Database**: MySQL 8.0 in `data-platform` namespace
- **Storage**: TrueNAS NFS for uploads (20Gi PVC)

---

## 📚 PLATFORM INTEGRATION (ChromaDB Knowledge Base)

**When working in this submodule**, you cannot access the parent srt-hq-k8s repository files. Use ChromaDB to query platform capabilities and integration patterns.

**Collection**: `srt-hq-k8s-platform-guide`

**Why This Matters for Vanilla Forums**:
- Integrates with platform MySQL (data-platform namespace)
- Uses platform ingress (Nginx Ingress Controller + cert-manager)
- Uses platform storage (TrueNAS NFS for persistent uploads)
- Monitored by platform Prometheus/Grafana
- Can integrate with platform Valkey for caching (future enhancement)

**Query When You Need**:
- Platform architecture and three-tier taxonomy
- MySQL data-platform connection details
- Storage classes and TrueNAS NFS configuration
- Ingress patterns and SSL certificate management
- Monitoring integration (Prometheus metrics)

**Example Queries**:
```
"What is the srt-hq-k8s platform architecture?"
"How do I connect to MySQL in the data-platform?"
"What storage classes are available for persistent volumes?"
"How does cert-manager issue SSL certificates?"
```

**When NOT to Query**:
- ❌ Vanilla Forums configuration (see README-K8S.md)
- ❌ PHP/React development (use Vanilla docs)
- ❌ Docker build process (use build-and-push.ps1)
- ❌ Deployment steps (use deploy.ps1)

---

## 📍 PROJECT OVERVIEW

Vanilla Forums is a powerful, customizable discussion forum platform used by tens of thousands of communities worldwide.

**Key Features**:
- Modern React-based rich editor
- Customizable themes and plugins
- User roles and permissions
- Email notifications
- File attachments and uploads
- Mobile-responsive design
- API-first architecture
- SSO integration support

**Deployment Model**:
- **Multi-container pod**: PHP-FPM + Nginx
- **Shared volumes**: Application code via init container
- **Persistent storage**: TrueNAS NFS for uploads
- **Database**: MySQL 8.0 in data-platform
- **HA**: 2 replicas with anti-affinity

---

## 🗂️ LOCATIONS

**Repository**: Submodule of srt-hq-k8s
**Submodule Path**: `manifests/apps/vanilla-forums/`
**Standalone Repo**: `/mnt/c/Users/shaun/repos/vanilla-forums`
**Namespace**: `vanilla-forums`
**URL**: https://vanilla.lab.hq.solidrust.net

**Docker Images**:
- App: `suparious/vanilla-forums:latest`
- Nginx: `nginx:1.27-alpine`

**Database**:
- Host: `mysql.data-platform.svc.cluster.local:3306`
- Database: `vanilla`
- User: `vanilla`

**Storage**:
- Uploads: `/var/www/html/uploads` (20Gi TrueNAS NFS)
- Cache: `/var/www/html/cache` (ephemeral)
- Config: `/var/www/html/conf` (ConfigMap + ephemeral)

---

## 🛠️ TECH STACK

**Backend**:
- PHP 8.1-FPM (Alpine)
- Composer dependency management
- MySQL 8.0 database
- Vanilla Forums application framework

**Frontend**:
- React 17
- TypeScript
- Yarn package manager
- Vite build tool
- Rich text editor (Plate/Slate)

**Infrastructure**:
- Kubernetes multi-container deployment
- Nginx 1.27 web server
- TrueNAS NFS persistent storage
- Let's Encrypt SSL certificates
- Platform MySQL database

**PHP Extensions Required**:
- curl, dom, fileinfo, gd, intl, json, mbstring
- mysqli, pdo, pdo_mysql, xml, zip

---

## 📁 PROJECT STRUCTURE

```
manifests/apps/vanilla-forums/
├── Dockerfile                  # Multi-stage build (Node + PHP)
├── .dockerignore              # Build exclusions
├── build-and-push.ps1         # Docker build automation
├── deploy.ps1                 # Kubernetes deployment automation
├── CLAUDE.md                  # This file (agent context)
├── README-K8S.md              # Deployment guide
└── k8s/
    ├── 01-namespace.yaml       # vanilla-forums namespace
    ├── 02-configmap-nginx.yaml # Nginx web server config
    ├── 03-configmap-vanilla.yaml # Vanilla application config
    ├── 04-secret.yaml          # Database credentials
    ├── 05-pvc.yaml             # Persistent storage for uploads
    ├── 06-deployment.yaml      # Multi-container pod (init + PHP + Nginx)
    ├── 07-service.yaml         # ClusterIP service
    └── 08-ingress.yaml         # HTTPS ingress with TLS
```

**Key Files**:
- **Dockerfile**: Builds assets with Node, installs PHP dependencies, creates app image
- **06-deployment.yaml**: Init container copies code, PHP-FPM runs app, Nginx serves requests
- **02-configmap-nginx.yaml**: Nginx config with FastCGI proxy to PHP-FPM
- **03-configmap-vanilla.yaml**: Vanilla config reading from environment variables

---

## 🚀 DEVELOPMENT WORKFLOW

### Local Development (Docker)
```bash
# Build image
.\build-and-push.ps1

# Test locally
docker run --rm -p 8080:80 --name vanilla-test \
  -e DB_HOST=host.docker.internal \
  -e DB_NAME=vanilla \
  -e DB_USER=vanilla \
  -e DB_PASSWORD=password \
  suparious/vanilla-forums:latest

# Access: http://localhost:8080
```

### Building Frontend Assets (Standalone Repo)
```bash
cd /mnt/c/Users/shaun/repos/vanilla-forums

# Install dependencies
yarn install

# Build production assets
yarn run build

# Development build with watch
yarn run build:dev
```

### Testing PHP Changes
```bash
# Exec into running pod
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c php-fpm -- sh

# Check PHP version
php -v

# Test database connection
php -r "new PDO('mysql:host=mysql.data-platform.svc.cluster.local;dbname=vanilla', 'vanilla', 'vanilla_user_password_2025');"
```

---

## 📋 DEPLOYMENT

### Quick Deploy
```powershell
# Deploy with existing image
.\deploy.ps1

# Build, push, and deploy
.\deploy.ps1 -Build -Push

# Build only (no push)
.\build-and-push.ps1
```

### Manual Deployment
```bash
# 1. Initialize MySQL database (if not already done)
kubectl run -i --rm mysql-init --image=mysql:8.0 --restart=Never -- \
  mysql -h mysql.data-platform.svc.cluster.local -u root -p<root-password> -e "
  CREATE DATABASE IF NOT EXISTS vanilla CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'vanilla'@'%' IDENTIFIED BY 'vanilla_user_password_2025';
  GRANT ALL PRIVILEGES ON vanilla.* TO 'vanilla'@'%';
  FLUSH PRIVILEGES;"

# 2. Apply Kubernetes manifests
kubectl apply -f k8s/

# 3. Wait for rollout
kubectl rollout status deployment/vanilla-forums -n vanilla-forums

# 4. Check certificate
kubectl get certificate -n vanilla-forums

# 5. Access application
# https://vanilla.lab.hq.solidrust.net
```

### Uninstall
```powershell
.\deploy.ps1 -Uninstall
```

---

## 🔧 COMMON TASKS

### View Logs
```bash
# PHP-FPM logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c php-fpm -f

# Nginx logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c nginx -f

# Init container logs (troubleshoot app copying)
kubectl logs -n vanilla-forums -l app=vanilla-forums -c copy-app
```

### Update Deployment
```bash
# Rebuild and redeploy
.\deploy.ps1 -Build -Push

# Restart pods (use latest image)
kubectl rollout restart deployment/vanilla-forums -n vanilla-forums
```

### Database Operations
```bash
# Connect to MySQL
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -- \
  mysql -h mysql.data-platform.svc.cluster.local -u vanilla -pvanilla_user_password_2025 vanilla

# Backup database
kubectl exec -n data-platform mysql-0 -- \
  mysqldump -u vanilla -pvanilla_user_password_2025 vanilla > vanilla-backup.sql

# Restore database
kubectl exec -i -n data-platform mysql-0 -- \
  mysql -u vanilla -pvanilla_user_password_2025 vanilla < vanilla-backup.sql
```

### Shell Access
```bash
# PHP-FPM container
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c php-fpm -- sh

# Nginx container
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c nginx -- sh
```

### Check Certificate Status
```bash
kubectl get certificate vanilla-forums-tls -n vanilla-forums

# If not ready, check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f
```

### Troubleshooting
```bash
# Pod status
kubectl get pods -n vanilla-forums

# Pod details and events
kubectl describe pod -n vanilla-forums -l app=vanilla-forums

# Service endpoints
kubectl get endpoints -n vanilla-forums

# Ingress status
kubectl describe ingress vanilla-forums -n vanilla-forums

# PVC status
kubectl get pvc -n vanilla-forums
```

---

## 🎯 USER PREFERENCES (CRITICAL)

**Context**: Shaun is a cloud engineer building production-quality lab infrastructure

**Solutions Must Be**:
- ✅ Complete, immediately deployable
- ✅ Production-ready (no dev shortcuts)
- ✅ Full manifests (not patches)
- ✅ Reproducible via scripts
- ❌ NO workarounds, temp fixes, disabled features

**Workflow**:
- Run PowerShell/Makefile directly (don't ask permission)
- Validate end-to-end
- Document in appropriate location
- Update CLAUDE.md when platform integration changes

---

## 💡 KEY DECISIONS

### Why Multi-Container Pod (not separate deployments)?
- **Tight coupling**: PHP-FPM and Nginx must communicate via localhost FastCGI
- **Shared filesystem**: Both need access to same application files
- **Atomic scaling**: Scale PHP+Nginx together as a unit
- **Simplified networking**: No service mesh needed for intra-pod communication

### Why Init Container for Application Code?
- **Immutable application image**: Same image for dev/staging/prod
- **Shared code volume**: PHP-FPM and Nginx both access via emptyDir
- **Fast startup**: Code copied once at pod start, not on every container restart
- **Consistency**: Ensures both containers use exact same code version

### Why TrueNAS NFS (not OpenEBS)?
- **Multi-pod access**: ReadWriteMany needed for HA deployment
- **Reliability**: NFS more stable for shared file access
- **Persistence**: Uploads survive pod restarts and redeployments
- **Backup integration**: TrueNAS snapshots for data protection

### Why MySQL (not PostgreSQL)?
- **Official support**: Vanilla Forums primarily tested with MySQL
- **Better compatibility**: Some Vanilla features MySQL-specific
- **Performance**: MySQL optimized for forum workloads
- **Community patterns**: Most Vanilla deployments use MySQL

### Why Separate ConfigMaps (Nginx + Vanilla)?
- **Separation of concerns**: Web server config vs application config
- **Independent updates**: Change Nginx config without touching app config
- **Clarity**: Easier to understand and maintain
- **Reusability**: Nginx config pattern can be reused for other PHP apps

---

## 🔍 VALIDATION

**Post-Deployment Checks**:

1. **Pods Running**:
   ```bash
   kubectl get pods -n vanilla-forums
   # Expected: 2/2 Running (init, php-fpm, nginx)
   ```

2. **Service Resolvable**:
   ```bash
   kubectl get svc vanilla-forums -n vanilla-forums
   # Expected: ClusterIP assigned
   ```

3. **Ingress Configured**:
   ```bash
   kubectl get ingress vanilla-forums -n vanilla-forums
   # Expected: ADDRESS shows ingress IP
   ```

4. **Certificate Issued**:
   ```bash
   kubectl get certificate vanilla-forums-tls -n vanilla-forums
   # Expected: READY=True
   ```

5. **Database Connectivity**:
   ```bash
   kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
     php -r "new PDO('mysql:host=mysql.data-platform.svc.cluster.local;dbname=vanilla', 'vanilla', 'vanilla_user_password_2025');"
   # Expected: No errors
   ```

6. **Web Access**:
   ```bash
   curl -I https://vanilla.lab.hq.solidrust.net
   # Expected: HTTP/2 200 or 302 (redirect to setup)
   ```

7. **Uploads Directory Writable**:
   ```bash
   kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
     touch /var/www/html/uploads/test && rm /var/www/html/uploads/test
   # Expected: Success
   ```

---

## 🎓 AGENT SUCCESS CRITERIA

**Vanilla Forums deployment is successful when**:
- ✅ All pods running and healthy (2/2 Ready)
- ✅ Database connection works (can query MySQL)
- ✅ Nginx serves requests (can curl ingress)
- ✅ Certificate issued (READY=True)
- ✅ Uploads directory persistent (survives pod restart)
- ✅ Application accessible via HTTPS with green padlock
- ✅ Installation wizard loads (first-time) or forum loads (after setup)
- ✅ Can create test discussion and upload file

---

## 📅 CHANGE HISTORY

### 2025-11-13 - Initial Deployment
- Created Kubernetes deployment infrastructure
- Multi-container pod design (init + PHP-FPM + Nginx)
- Integrated with platform MySQL (data-platform)
- TrueNAS NFS persistent storage for uploads
- SSL via cert-manager + Let's Encrypt
- Deployment automation via PowerShell scripts
- Comprehensive documentation (CLAUDE.md, README-K8S.md)

---

**Last Updated**: 2025-11-13
**Platform Tier**: Apps
**Database**: MySQL (data-platform)
**Status**: Ready for first-time setup
