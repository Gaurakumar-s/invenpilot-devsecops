# k8s/ — bootstrap manifests

Only cluster-level bootstrap objects live here. Application workloads are
packaged in the Helm chart under `helm/stockpilot`.

```bash
kubectl apply -f k8s/namespace.yaml
```
