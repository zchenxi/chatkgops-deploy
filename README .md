# chatops-deploy
## 1. deploy
### a. trace
1. Configue `Opentelemetry Instrumentation`
```
kubectl apply -f ./opentelemetry/cert-manager.yaml
# (or kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml)

kubectl apply -f ./opentelemetry/opentelemetry-operator.yaml
# (or kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml)

kubectl apply -f ./opentelemetry/instrumentation.yaml -n obs
```
2. Install `Opentelemetry Collector`
```
helm install otelcol ./opentelemetry/opentelemetry-collector -n obs
```

3. Install `tempo`
```
helm install tempo ./tempo -n obs
```

### b. Loki
```
helm install loki ./loki-stack -n obs
```

### c. Metrics
```
helm install prometheus ./kube-prometheus-stack -n obs
```

## 2. Trainticket
```
cd ts-deploy
make deploy
```

## 3. grafana datasources
```
http://prometheus-kube-prometheus-prometheus:9090
http://loki:3100
http://tempo:3100
```
## Port
```
loki: 30001
prometheus: 30002
tempo: 30003
trainticket: 32677
```
## Upgrade
```
helm upgrade tempo ./tempo -n obs
helm upgrade loki ./loki-stack -n obs
helm upgrade prometheus ./kube-prometheus-stack -n obs
```
