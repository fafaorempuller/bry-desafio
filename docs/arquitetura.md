# Arquitetura do Lab SRE

- Cluster k3d com 1 server + 2 workers
- Aplicação `whoami` em 3 réplicas
- Ingress Nginx com TLS (Let's Encrypt)
- Monitoramento com Prometheus + Grafana
- Logs centralizados (Sugestão: Loki)
- Teste de estresse com k6
