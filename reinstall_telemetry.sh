helm uninstall tempo ./tempo -n obs
helm uninstall loki ./loki-stack -n obs
helm uninstall prometheus ./kube-prometheus-stack -n obs

helm install tempo ./tempo -n obs
helm install loki ./loki-stack -n obs
helm install prometheus ./kube-prometheus-stack -n obs