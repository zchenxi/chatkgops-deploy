HIGHLIGHT = \033[1;34m
END = \033[0m

NAMESPACE = obs

TEMPO_CHART_NAME = tempo
LOKI_CHART_NAME = loki
PROMETHEUS_CHART_NAME = prometheus

TEMPO_CHART_PATH = ./tempo
LOKI_CHART_PATH = ./loki-stack
PROMETHEUS_CHART_PATH = ./kube-prometheus-stack

install: helm_install

uninstall: helm_uninstall

reinstall: helm_uninstall helm_install

helm_install:
	@echo -e "$(HIGHLIGHT)helm install...$(END)"
	@echo -e "$(HIGHLIGHT)helm install $(TEMPO_CHART_NAME) $(TEMPO_CHART_PATH) -n $(NAMESPACE)$(END)"
	- helm install $(TEMPO_CHART_NAME) $(TEMPO_CHART_PATH) -n $(NAMESPACE)
	@echo -e "$(HIGHLIGHT)helm install $(LOKI_CHART_NAME) $(LOKI_CHART_PATH) -n $(NAMESPACE)$(END)"
	- helm install $(LOKI_CHART_NAME) $(LOKI_CHART_PATH) -n $(NAMESPACE)
	@echo -e "$(HIGHLIGHT)helm install $(PROMETHEUS_CHART_NAME) $(PROMETHEUS_CHART_PATH) -n $(NAMESPACE)$(END)"
	- helm install $(PROMETHEUS_CHART_NAME) $(PROMETHEUS_CHART_PATH) -n $(NAMESPACE)
helm_uninstall:
	@echo -e "$(HIGHLIGHT)helm uninstall...$(END)"
	@echo -e "$(HIGHLIGHT)helm uninstall $(TEMPO_CHART_NAME) -n $(NAMESPACE)$(END)"
	- helm uninstall $(TEMPO_CHART_NAME) -n $(NAMESPACE)
	@echo -e "$(HIGHLIGHT)helm uninstall $(LOKI_CHART_NAME) -n $(NAMESPACE)$(END)"
	- helm uninstall $(LOKI_CHART_NAME) -n $(NAMESPACE)
	@echo -e "$(HIGHLIGHT)helm uninstall $(PROMETHEUS_CHART_NAME) -n $(NAMESPACE)$(END)"
	- helm uninstall $(PROMETHEUS_CHART_NAME) -n $(NAMESPACE)
