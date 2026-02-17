# Enterprise HA Prometheus Cluster Blueprint

This repository provides production-ready Kubernetes manifests for a **highly available Prometheus monitoring stack** with:

- **Prometheus HA pair** (2 replicas) scraping identical targets.
- **Thanos Sidecar + Query** for global deduplicated reads and long-term storage integration.
- **Alertmanager HA cluster** (3 replicas with gossip mesh).
- **Persistent volumes**, anti-affinity, probes, and strict security contexts.

## Architecture

```text
Targets -> Prometheus (replica A) --\
                                  +--> Thanos Query --> Grafana/Users
Targets -> Prometheus (replica B) --/

Prometheus replicas -> Thanos Sidecars -> Object Storage (S3-compatible)

Prometheus replicas -> Alertmanager HA cluster (3 nodes)
```

## What you must provide before deploy

1. **Object storage credentials** for Thanos in a Kubernetes secret named `thanos-objstore-config`.
2. **StorageClasses** suitable for your environment (`fast-ssd` in these manifests).
3. **Scrape targets and alerting rules** tailored to your systems.
4. Optional ingress/service exposure for the Thanos Query UI/API.

## Deployment

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/prometheus/prometheus-config.yaml
kubectl apply -f k8s/alertmanager/alertmanager-config.yaml
kubectl apply -f k8s/alertmanager/alertmanager-statefulset.yaml
kubectl apply -f k8s/prometheus/prometheus-statefulset.yaml
kubectl apply -f k8s/thanos/query-deployment.yaml
```

## Operational notes

- **Deduplication** happens in Thanos Query with `--query.replica-label=replica`.
- **Prometheus HA** intentionally duplicates scrape load; this is expected and required for failover.
- **Alertmanager HA** uses gossip peers so notifications are deduplicated.
- For enterprise hardening, add:
  - mTLS between components.
  - network policies.
  - OIDC auth in front of query endpoints.
  - PodDisruptionBudgets and topology spread constraints per platform policy.
