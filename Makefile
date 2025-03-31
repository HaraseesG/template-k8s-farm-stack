# Define variables
ENV ?= dev
PROFILE=minikube
NAMESPACE := $(ENV)-farm-stack
SEED_PATH := database/seeds/$(ENV).sql
CONFIGMAP_TEMPLATE := k8s/configmaps/mysql-seed.yaml.template
CONFIGMAP_OUTPUT := k8s/configmaps/mysql-seed.yaml
MYSQL_SERVICE_HOST := $(shell minikube ip --profile=$(PROFILE))
MYSQL_SERVICE_PORT=30036

include .env
export

# Force Docker to use Minikube's Docker daemon
export DOCKER_BUILDKIT := 1

.PHONY: set-docker-env generate-seed-configmap check-env check-minikube-ip start create-secrets deploy healthcheck ip connect-mysql restart clean stop status

# Automatically configure Minikube's Docker environment
define SET_DOCKER_ENV
	eval $(minikube docker-env)
endef

define generate_seed_configmap
	@echo "Injecting seed data for '$(ENV)'..."
	@printf "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: mysql-seed\ndata:\n  env-seed.sql: |\n" > $(CONFIGMAP_OUTPUT)
	@sed 's/^/    /' $(SEED_PATH) >> $(CONFIGMAP_OUTPUT)
endef

set-docker-env:
	$(call SET_DOCKER_ENV)

generate-seed-configmap:
	$(call generate_seed_configmap)

check-env:
	@echo "Validating required environment variables..."
	@if [ -z "$(MYSQL_ROOT_PASSWORD)" ]; then \
		echo "MYSQL_ROOT_PASSWORD is not set in .env"; exit 1; \
	fi
	@if [ -z "$(MYSQL_DATABASE)" ]; then \
		echo "MYSQL_DATABASE is not set in .env"; exit 1; \
	fi
	@echo "All required environment variables are set."

check-minikube-ip:
	@if [ -z "$(MYSQL_SERVICE_HOST)" ]; then \
		echo "❌ Minikube IP is empty. Is the cluster running?"; \
		exit 1; \
	fi

# Start Minikube
start: set-docker-env
	minikube start --driver=docker --profile $(PROFILE)
	minikube addons enable ingress --profile $(PROFILE)
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl config set-context --current --namespace=$(NAMESPACE)

create-secrets:
	kubectl create secret generic secrets \
		--from-literal=MYSQL_ROOT_PASSWORD=$(MYSQL_ROOT_PASSWORD) \
		--from-literal=MYSQL_DATABASE=$(MYSQL_DATABASE) \
		--dry-run=client -o yaml | kubectl apply -n $(NAMESPACE) -f -

# Apply Kubernetes manifests
deploy: check-env create-secrets generate-seed-configmap
	kubectl apply -n $(NAMESPACE) -f $(CONFIGMAP_OUTPUT)
	kubectl apply -n $(NAMESPACE) -f k8s/mysql-deployment.yaml

healthcheck: check-minikube-ip
	@echo "Running MYSQL healthcheck..."
	kubectl wait --for=condition=ready pod -l app=mysql -n $(NAMESPACE) --timeout=60s
	@echo "Pod is ready. Testing DB connection..."
	mysql -h $(MYSQL_SERVICE_HOST) -P ${MYSQL_SERVICE_PORT} -uroot -p -e "SHOW DATABASES;" $(MYSQL_DATABASE)
	@echo "DB connection successful."

ip: check-minikube-ip
	@echo "Minikube IP: $(MYSQL_SERVICE_HOST)"
	@echo "MYSQL service URL: $(MYSQL_SERVICE_HOST):$(MYSQL_SERVICE_PORT)"
	@echo "Connect with: mysql -h $(MYSQL_SERVICE_HOST) -P $(MYSQL_SERVICE_PORT) -uroot -p"

connect-mysql: check-minikube-ip
	@echo "Connection to MYSQL at $(MYSQL_SERVICE_HOST)..."
	mysql -h $(MYSQL_SERVICE_HOST) -P ${MYSQL_SERVICE_PORT} -uroot -p

restart:
	@echo "Restarting MySQL deployment without deleting volumes or Minikube..."
	kubectl delete deployment mysql -n $(NAMESPACE) --ignore-not-found
	kubectl delete svc mysql-service -n $(NAMESPACE) --ignore-not-found
	kubectl delete configmap mysql-seed -n $(NAMESPACE) --ignore-not-found
	kubectl delete secret secrets -n $(NAMESPACE) --ignore-not-found
	@echo "Cleaned deployment, preserving PVCs and cluster. Run 'make deploy' to redeploy."

# Delete all Kubernetes resources
clean:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found
	minikube delete --profile $(PROFILE)

# Stop Minikube
stop:
	minikube stop

# Check status
status:
	minikube status --profile $(PROFILE)