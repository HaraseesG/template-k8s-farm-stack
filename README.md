# Start cluster
`make start`

# Build frontend & backend everything
`make build`

# Deploy everything
`make deploy`

# Get frontend URL
`make expose`

# Monitor logs
`kubectl logs -f backend-5b6cdd7b5f-9sd89`

# Stop the cluster
`make stop`

# Delete everything
`make clean`

### K8 Cheat Sheet ###

# List all services
`kubectl get services`

# List all deployments
`kubectl get deployments`

# List all runnings pods
`kubectl get pods`

# View pod logs
`kubectl logs <pod-name>`
# Or follow with 
`kubectl logs -f <pod-name>`

# Pause a service
`kubectl scale deployment <pod-name> --replicas=0`

# Restart a service
`kubectl scale deployment <pod-name> --replicas=1`

# Delete a service
`kubectl delete deployment <pod-name>`

# Check K8 Events
`kubectl get events --sort-by=.metadata.creationTimestamp`

# Detailed debugging with pod descriptions
`kubectl describe pod <pod-name>`

# List pod errors
`kubectl logs <pod-name> | grep "ERROR"`

# Interactive pod access
`kubectl exec -it $(kubectl get pod -l app=mysql -o jsonpath="{.items[0].metadata.name}") -- mysql -u root -p`