# Enterprise HA Prometheus Cluster on Kubernetes

This reference implementation deploys an enterprise-grade, highly-available Prometheus stack using:

- **kube-prometheus-stack** (Prometheus Operator + Prometheus + Alertmanager + Grafana)
- **Prometheus HA replicas** (2 replicas scraping the same targets)
- **Thanos sidecars + object storage** for durable metrics and global deduplication
- **Thanos Query + Query Frontend** for a unified query plane
- **PodDisruptionBudgets, anti-affinity, retention tuning, and WAL compression**

## Architecture

- Two Prometheus replicas (`prometheus.prometheusSpec.replicas=2`) run in the same cluster.
- Each replica has local PVC-backed TSDB storage.
- Each replica uploads blocks to object storage via Thanos sidecar.
- Thanos Query deduplicates data from both replicas using external labels.
- Thanos Query Frontend adds caching and query splitting.

## Prerequisites

- Kubernetes 1.26+
- Helm 3.12+
- A working StorageClass for StatefulSets
- An object storage bucket for Thanos (S3-compatible, GCS, or Azure)

## Files

- `helm-values/prometheus-ha-values.yaml` - HA and enterprise settings for `kube-prometheus-stack`
- `k8s/thanos-query.yaml` - Thanos Query deployment/service/PDB
- `k8s/thanos-query-frontend.yaml` - Query Frontend deployment/service
- `k8s/namespace.yaml` - Monitoring namespace
- `k8s/thanos-objectstore-secret.example.yaml` - Template secret for object-store config
- `scripts/deploy-ha-prometheus.sh` - Opinionated deploy script

## Configure object storage

Create a secret from the provided template:

```bash
cp k8s/thanos-objectstore-secret.example.yaml k8s/thanos-objectstore-secret.yaml
# edit object storage config values
kubectl apply -f k8s/thanos-objectstore-secret.yaml
```

## Deploy

```bash
./scripts/deploy-ha-prometheus.sh
```

## Access

```bash
kubectl -n monitoring port-forward svc/thanos-query-frontend 9091:9091
```

Query endpoint:

- http://localhost:9091

## Production hardening checklist

- Add mTLS between components (service mesh or explicit TLS + cert-manager)
- Restrict ingress with authn/authz (OIDC + RBAC)
- Configure encrypted PVC + bucket encryption + KMS
- Set backup/restore policies for object storage metadata and secrets
- Configure alert routing by severity/team and multi-channel on-call
- Add network policies if your cluster enforces zero-trust networking
