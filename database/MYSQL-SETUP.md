# MySQL Setup Guide

This project has been refactored from MongoDB to **MySQL** (local Docker or AWS RDS).  
Sequelize ORM handles the connection and auto-creates tables on first startup.

---

## Prerequisites


| Tool                    | Version                 |
| ----------------------- | ----------------------- |
| Docker & Docker Compose | v2.0+                   |
| Node.js                 | v18+                    |
| AWS CLI + Terraform     | Only for Option 3 (RDS) |


---

## Option 1 — Full Stack with Docker Compose

> Starts MySQL + Backend + Frontend + Redis all together.  
> Recommended for local development.

### Step 1 — Install backend dependencies

```bash
cd Devops-Mega-Project-Jenkins-ArgoCD-EKS/backend
npm install
```

> This installs `sequelize` and `mysql2` and removes the old `mongoose` lockfile entry.

### Step 2 — Start everything

```bash
cd Devops-Mega-Project-Jenkins-ArgoCD-EKS
docker compose up --build
```

Docker Compose will automatically:

- Pull and start `mysql:8.0` as `mysql-service`
- Run `database/init.sql` on first boot — creates the `wanderlust` database and tables
- Build and start the backend — Sequelize connects and `sync()` confirms the schema
- Build and start the frontend and Redis

### Step 3 — Verify MySQL is running

```bash
docker exec -it mysql-service mysql -u wanderlust_user -pwanderlust_pass wanderlust
```

Inside the MySQL shell:

```sql
SHOW TABLES;
```

Expected output:

```
+---------------------+
| Tables_in_wanderlust |
+---------------------+
| posts               |
| users               |
+---------------------+
```

---

## Option 2 — MySQL Container Only (Backend via `npm start`)

> Use this when you want to run the backend with `nodemon` directly for faster iteration.

### Step 1 — Start only MySQL and Redis

```bash
cd Devops-Mega-Project-Jenkins-ArgoCD-EKS
docker compose up mysql redis -d
```

### Step 2 — Create a local `.env` in the backend folder

```bash
cd backend
cp .env.sample .env
```

Edit `.env` with the following values (matching the Docker Compose MySQL service):

```env
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=wanderlust_user
MYSQL_PASSWORD=wanderlust_pass
MYSQL_DATABASE=wanderlust
REDIS_URL=127.0.0.1:6379
PORT=5000
JWT_SECRET=any_long_random_string_here
ACCESS_TOKEN_EXPIRES_IN=120s
REFRESH_TOKEN_EXPIRES_IN=7d
ACCESS_COOKIE_MAXAGE=120000
REFRESH_COOKIE_MAXAGE=604800000
NODE_ENV=Development
```

### Step 3 — Start the backend

```bash
npm install
npm start
```

Expected terminal output:

```
MySQL database connected: 127.0.0.1:3306/wanderlust
Server is running on port 5000
```

---

## Option 3 — AWS RDS MySQL (Production)

### Step 1 — Provision the RDS instance with Terraform

```bash
cd Devops-Mega-Project-Jenkins-ArgoCD-EKS/terraform

terraform init

terraform apply \
  -var="vpc_id=vpc-xxxxxxxx" \
  -var='db_subnet_ids=["subnet-aaa","subnet-bbb"]' \
  -var="db_password=YourStrongPassword123"
```

After `apply` completes, the RDS endpoint is printed as an output:

```
rds_endpoint = "wanderlust-mysql.abc123.us-east-2.rds.amazonaws.com:3306"
rds_port     = 3306
```

### Step 2 — Run the schema on RDS (one-time)

```bash
mysql -h wanderlust-mysql.abc123.us-east-2.rds.amazonaws.com \
      -u wanderlust_user -p wanderlust \
      < database/init.sql
```

> The application's `sequelize.sync()` also handles this automatically on first startup,
> but running `init.sql` manually gives you full control over the schema state.

### Step 3 — Update the Kubernetes Secret

Edit `kubernetes/rds-secret.yaml` with your actual RDS values:

```yaml
stringData:
  MYSQL_HOST: "wanderlust-mysql.abc123.us-east-2.rds.amazonaws.com"
  MYSQL_PORT: "3306"
  MYSQL_USER: "wanderlust_user"
  MYSQL_PASSWORD: "YourStrongPassword123"
  MYSQL_DATABASE: "wanderlust"
```

Apply to your EKS cluster:

```bash
kubectl apply -f kubernetes/rds-secret.yaml
kubectl apply -f kubernetes/backend.yaml
```

> The backend pod reads credentials from the secret at runtime via `envFrom`.  
> No MongoDB pod, no PersistentVolume, no in-cluster database.

---

## Environment Variables Reference


| Variable                   | Description                    | Default (Docker)             |
| -------------------------- | ------------------------------ | ---------------------------- |
| `MYSQL_HOST`               | MySQL hostname or RDS endpoint | `mysql-service`              |
| `MYSQL_PORT`               | MySQL port                     | `3306`                       |
| `MYSQL_USER`               | Database username              | `wanderlust_user`            |
| `MYSQL_PASSWORD`           | Database password              | `wanderlust_pass`            |
| `MYSQL_DATABASE`           | Database name                  | `wanderlust`                 |
| `REDIS_URL`                | Redis connection URL           | `redis://redis-service:6379` |
| `PORT`                     | Backend HTTP port              | `8080`                       |
| `JWT_SECRET`               | Secret key for JWT signing     | —                            |
| `ACCESS_TOKEN_EXPIRES_IN`  | Access token TTL               | `120s`                       |
| `REFRESH_TOKEN_EXPIRES_IN` | Refresh token TTL              | `120s`                       |


---

## Quick Troubleshooting


| Symptom                         | Cause                        | Fix                                                               |
| ------------------------------- | ---------------------------- | ----------------------------------------------------------------- |
| `ECONNREFUSED 127.0.0.1:3306`   | MySQL container not running  | `docker compose up mysql -d`                                      |
| `Access denied for user`        | Password mismatch            | Verify `.env` matches `MYSQL_PASSWORD` in `docker-compose.yml`    |
| `Unknown database 'wanderlust'` | `init.sql` did not run       | Connect as root and run `source database/init.sql` manually       |
| Tables missing after restart    | Expected first-run behaviour | `sequelize.sync()` recreates tables automatically on next startup |
| `ER_NOT_SUPPORTED_AUTH_MODE`    | MySQL 8 auth plugin mismatch | Add `authPlugins` or use `mysql2` driver (already configured)     |


---

## File Reference

```
Devops-Mega-Project-Jenkins-ArgoCD-EKS/
├── database/
│   └── init.sql                  # Schema — runs automatically on first Docker boot
├── backend/
│   ├── config/db.js              # Sequelize connection setup
│   ├── config/utils.js           # MySQL env var exports
│   ├── models/user.js            # users table model
│   ├── models/post.js            # posts table model
│   ├── .env.sample               # Local env template
│   └── .env.docker               # Docker env (mysql-service hostname)
├── kubernetes/
│   ├── rds-secret.yaml           # Kubernetes Secret for RDS credentials
│   └── backend.yaml              # Backend deployment (reads secret via envFrom)
├── terraform/
│   ├── rds.tf                    # RDS instance + security group + subnet group
│   └── variables.tf              # EC2 variables (unchanged)
└── docker-compose.yml            # mysql-service replaces mongo-service
```

