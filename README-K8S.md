# Vanilla Forums - Kubernetes Deployment

Modern discussion forum platform deployed on srt-hq-k8s.

**URL**: https://vanilla.lab.hq.solidrust.net
**Namespace**: `vanilla-forums`
**Image**: `suparious/vanilla-forums:latest`

---

## Quick Start

### Deploy
```powershell
# Build, push, and deploy
.\deploy.ps1 -Build -Push

# Deploy with existing image
.\deploy.ps1

# Uninstall
.\deploy.ps1 -Uninstall
```

### Build Only
```powershell
# Build locally
.\build-and-push.ps1

# Build and push to Docker Hub
.\build-and-push.ps1 -Login -Push
```

---

## Architecture

### Stack
- **Backend**: PHP 8.1-FPM + Vanilla Forums framework
- **Frontend**: React 17 + TypeScript + Vite
- **Web Server**: Nginx 1.27
- **Database**: MySQL 8.0 (data-platform namespace)
- **Storage**: TrueNAS NFS (20Gi for uploads)

### Pod Design
Multi-container pod with shared volumes:

1. **Init Container** (`copy-app`):
   - Copies application code to shared emptyDir
   - Runs once at pod startup

2. **PHP-FPM Container**:
   - Executes PHP application code
   - Connects to MySQL database
   - Listens on port 9000 (FastCGI)

3. **Nginx Container**:
   - Serves static files
   - Proxies PHP requests to PHP-FPM via FastCGI
   - Listens on port 80 (HTTP)

### Volumes
- **app** (emptyDir): Shared application code
- **uploads** (PVC): Persistent user uploads (TrueNAS NFS)
- **cache** (emptyDir): Temporary cache files
- **conf** (ConfigMap + emptyDir): Configuration files

### Resources
- **PHP-FPM**: 500m-2000m CPU, 512Mi-2Gi memory
- **Nginx**: 100m-500m CPU, 128Mi-256Mi memory
- **Replicas**: 2 (HA)

---

## Maintenance

### Logs
```bash
# PHP application logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c php-fpm -f

# Web server logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c nginx -f

# Init container (troubleshoot startup)
kubectl logs -n vanilla-forums -l app=vanilla-forums -c copy-app
```

### Shell Access
```bash
# PHP container
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c php-fpm -- sh

# Nginx container
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c nginx -- sh

# Inside container
cd /var/www/html
ls -la uploads/  # Check persistent storage
php -v          # PHP version
```

### Update Deployment
```bash
# Rebuild and redeploy
.\deploy.ps1 -Build -Push

# Restart (pull latest image)
kubectl rollout restart deployment/vanilla-forums -n vanilla-forums

# Check rollout status
kubectl rollout status deployment/vanilla-forums -n vanilla-forums
```

### Database Access
```bash
# Connect to vanilla database
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -- \
  mysql -h mysql.data-platform.svc.cluster.local -u vanilla -pvanilla_user_password_2025 vanilla

# Backup
kubectl exec -n data-platform mysql-0 -- \
  mysqldump -u vanilla -pvanilla_user_password_2025 vanilla > backup.sql

# Restore
kubectl exec -i -n data-platform mysql-0 -- \
  mysql -u vanilla -pvanilla_user_password_2025 vanilla < backup.sql
```

---

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -n vanilla-forums

# Describe pod
kubectl describe pod -n vanilla-forums -l app=vanilla-forums

# Check events
kubectl get events -n vanilla-forums --sort-by='.lastTimestamp'

# Common issues:
# - Image pull failure: Check Docker Hub credentials
# - PVC not binding: Check storage class availability
# - Init container failing: Check logs with -c copy-app
```

### Database Connection Errors
```bash
# Verify MySQL is running
kubectl get pods -n data-platform -l app=mysql

# Test connection from pod
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  php -r "new PDO('mysql:host=mysql.data-platform.svc.cluster.local;dbname=vanilla', 'vanilla', 'vanilla_user_password_2025');"

# Check secret
kubectl get secret vanilla-secrets -n vanilla-forums -o yaml

# Verify database exists
kubectl run -it --rm mysql-check --image=mysql:8.0 --restart=Never -- \
  mysql -h mysql.data-platform.svc.cluster.local -u root -p<password> -e "SHOW DATABASES LIKE 'vanilla';"
```

### Certificate Not Issuing
```bash
# Check certificate status
kubectl get certificate vanilla-forums-tls -n vanilla-forums

# Describe certificate
kubectl describe certificate vanilla-forums-tls -n vanilla-forums

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Common issues:
# - DNS validation failing: Check Cloudflare API token
# - Ingress annotation wrong: Should be letsencrypt-prod-dns01
# - Waiting for propagation: Can take 1-5 minutes
```

### Application Errors (500/404)
```bash
# Check PHP-FPM logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c php-fpm --tail=100

# Check Nginx logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c nginx --tail=100

# Verify file permissions
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  ls -la /var/www/html/

# Check if uploads directory is writable
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  touch /var/www/html/uploads/test && rm /var/www/html/uploads/test

# Common issues:
# - Permission errors: Check volume mounts
# - Missing files: Check init container logs
# - PHP errors: Check application logs
```

### Uploads Not Persisting
```bash
# Check PVC status
kubectl get pvc vanilla-uploads -n vanilla-forums

# Check PVC is mounted
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  df -h /var/www/html/uploads

# Verify NFS mount
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  mount | grep uploads

# Test write
kubectl exec -n vanilla-forums deployment/vanilla-forums -c php-fpm -- \
  sh -c 'echo "test" > /var/www/html/uploads/test.txt && cat /var/www/html/uploads/test.txt'
```

---

## Configuration

### Environment Variables (Secret)
- `DB_HOST`: MySQL host (mysql.data-platform.svc.cluster.local)
- `DB_PORT`: MySQL port (3306)
- `DB_NAME`: Database name (vanilla)
- `DB_USER`: Database user (vanilla)
- `DB_PASSWORD`: Database password
- `VANILLA_COOKIE_SALT`: Cookie encryption salt
- `VANILLA_TITLE`: Forum title
- `VANILLA_DOMAIN`: Primary domain

### ConfigMaps
- **nginx-config**: Nginx web server configuration
- **vanilla-config**: Vanilla application configuration (config.php)

### Customization
```bash
# Edit Nginx config
kubectl edit configmap nginx-config -n vanilla-forums

# Edit Vanilla config
kubectl edit configmap vanilla-config -n vanilla-forums

# Edit secrets (database, cookies, etc.)
kubectl edit secret vanilla-secrets -n vanilla-forums

# Restart pods after config changes
kubectl rollout restart deployment/vanilla-forums -n vanilla-forums
```

---

## File Structure

```
manifests/apps/vanilla-forums/
├── Dockerfile                      # Multi-stage build
├── .dockerignore                   # Build exclusions
├── build-and-push.ps1              # Build automation
├── deploy.ps1                      # Deployment automation
├── CLAUDE.md                       # Agent context documentation
├── README-K8S.md                   # This file
└── k8s/
    ├── 01-namespace.yaml           # Namespace
    ├── 02-configmap-nginx.yaml     # Nginx config
    ├── 03-configmap-vanilla.yaml   # Vanilla config
    ├── 04-secret.yaml              # Credentials
    ├── 05-pvc.yaml                 # Persistent storage
    ├── 06-deployment.yaml          # Multi-container pod
    ├── 07-service.yaml             # ClusterIP service
    └── 08-ingress.yaml             # HTTPS ingress
```

---

## Useful Commands

```bash
# Status
kubectl get all,certificate,ingress,pvc -n vanilla-forums

# Logs
kubectl logs -n vanilla-forums -l app=vanilla-forums -c php-fpm -f

# Shell
kubectl exec -it -n vanilla-forums deployment/vanilla-forums -c php-fpm -- sh

# Restart
kubectl rollout restart deployment/vanilla-forums -n vanilla-forums

# Scale
kubectl scale deployment vanilla-forums -n vanilla-forums --replicas=3

# Port Forward (for testing)
kubectl port-forward -n vanilla-forums svc/vanilla-forums 8080:80
```

---

## First-Time Setup

1. **Deploy**:
   ```powershell
   .\deploy.ps1 -Build -Push
   ```

2. **Wait for certificate**:
   ```bash
   kubectl get certificate -n vanilla-forums -w
   # Wait for READY=True (1-2 minutes)
   ```

3. **Access application**:
   - Navigate to: https://vanilla.lab.hq.solidrust.net
   - Complete Vanilla Forums installation wizard
   - Database settings should auto-configure from environment variables

4. **Create admin account** when prompted by installer

5. **Verify uploads**:
   - Create a test discussion
   - Upload a file
   - Verify file persists after pod restart

---

## Links

- **Production**: https://vanilla.lab.hq.solidrust.net
- **Docker Hub**: https://hub.docker.com/r/suparious/vanilla-forums
- **Source**: https://github.com/suparious/vanilla-forums
- **Vanilla Docs**: https://docs.vanillaforums.com/

---

**Last Updated**: 2025-11-13
**Deployed By**: Claude Code (Sonnet 4.5)
