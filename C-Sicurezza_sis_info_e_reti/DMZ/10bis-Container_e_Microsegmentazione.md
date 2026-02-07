# Capitolo 10bis - Container e Microsegmentazione

## Introduzione

L'adozione massiva di **container** e **microservizi** ha rivoluzionato il modo in cui le applicazioni vengono sviluppate, distribuite e protette. Le architetture tradizionali basate su DMZ devono evolversi per abbracciare questi nuovi paradigmi, introducendo concetti come **microsegmentazione**, **service mesh** e **zero trust networking**.

## 10bis.1 Container e Sicurezza

### Cosa sono i Container

I **container** sono unità di software leggere e portabili che impacchettano un'applicazione e tutte le sue dipendenze, permettendo di eseguirla in modo consistente su qualsiasi ambiente.

**Differenze rispetto a VM tradizionali:**

| Caratteristica | Virtual Machine | Container |
|----------------|-----------------|-----------|
| **Isolamento** | Completo (hypervisor) | Processo-level (namespace) |
| **Footprint** | GB (OS completo) | MB (solo app + dipendenze) |
| **Startup** | Minuti | Secondi/millisecondi |
| **Overhead** | Alto | Basso |
| **Portabilità** | Limitata | Elevata |

### Architettura Container

```
┌─────────────────────────────────────┐
│        Application Layer            │
├─────────────────────────────────────┤
│  Container 1  │ Container 2 │ ...   │
│  [App + Libs] │ [App + Libs]│       │
├─────────────────────────────────────┤
│     Container Runtime (Docker)      │
├─────────────────────────────────────┤
│           Host OS (Linux)           │
├─────────────────────────────────────┤
│     Infrastructure (VM o Bare)      │
└─────────────────────────────────────┘
```

### Sfide di Sicurezza nei Container

#### 1. Superficie di Attacco Espansa
- **Container escape**: vulnerabilità nel runtime possono permettere accesso all'host
- **Kernel condiviso**: tutti i container condividono lo stesso kernel Linux
- **Privilege escalation**: container privilegiati possono compromettere l'host

#### 2. Immagini Vulnerabili
- Dipendenze obsolete
- CVE non patchate
- Immagini da repository non fidati
- Secrets hardcoded nelle immagini

#### 3. Network Complexity
- Comunicazione container-to-container
- Service discovery dinamico
- Overlay networks
- East-West traffic non filtrato

#### 4. Ephemeral Nature
- Container breve durata complica logging e forensics
- Autoscaling dinamico
- IP addressing dinamico

### Docker Security Best Practices

#### Immagini Sicure

```dockerfile
# BAD: immagine base non specifica
FROM ubuntu

# GOOD: immagine base specifica e minimale
FROM ubuntu:22.04-slim

# Ancora meglio: distroless o scratch
FROM gcr.io/distroless/static-debian11

# Creare user non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Non includere secrets
# BAD
ENV DB_PASSWORD=mysecretpassword

# GOOD: usare secrets management
# Passare DB_PASSWORD a runtime o usare Docker secrets

# Installare solo pacchetti necessari
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    curl \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Eseguire come utente non privilegiato
USER appuser

# Esporre solo porte necessarie
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

#### Runtime Security

```bash
# NO privilegi di root
docker run --user 1000:1000 myapp

# Read-only filesystem
docker run --read-only --tmpfs /tmp myapp

# Limitare capabilities
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp

# No new privileges
docker run --security-opt=no-new-privileges myapp

# Resource limits
docker run \
  --memory="512m" \
  --cpus="1.0" \
  --pids-limit=100 \
  myapp

# Network isolation
docker run --network=isolated_network myapp
```

#### Scanning delle Immagini

```bash
# Trivy - vulnerability scanner
trivy image nginx:latest

# Clair - static analysis
clairctl analyze nginx:latest

# Snyk - security scanning
snyk container test nginx:latest

# Docker Scout (integrato in Docker Desktop)
docker scout cves nginx:latest
```

## 10bis.2 Kubernetes e DMZ

### Kubernetes Architecture Overview

```
┌────────────────────────────────────────────────┐
│              Kubernetes Cluster                │
│                                                │
│  ┌────────────────────────────────────────┐    │
│  │         Control Plane                  │    │
│  │  - API Server                          │    │
│  │  - Scheduler                           │    │
│  │  - Controller Manager                  │    │
│  │  - etcd                                │    │
│  └────────────────────────────────────────┘    │
│                                                │
│  ┌────────────────────────────────────────┐    │
│  │         Worker Nodes                   │    │
│  │                                        │    │
│  │  Node 1        Node 2        Node 3    │    │
│  │  ┌────────┐   ┌────────┐   ┌────────┐  │    │
│  │  │Pod DMZ │   │Pod App │   │Pod DB  │  │    │
│  │  │Web     │   │Backend │   │        │  │    │
│  │  └────────┘   └────────┘   └────────┘  │    │
│  └────────────────────────────────────────┘    │
└────────────────────────────────────────────────┘
```

### DMZ Pattern in Kubernetes

#### Approccio 1: Namespace-based DMZ

```yaml
# Namespace per DMZ
apiVersion: v1
kind: Namespace
metadata:
  name: dmz
  labels:
    security-zone: dmz
---
# Namespace per applicazioni interne
apiVersion: v1
kind: Namespace
metadata:
  name: internal-apps
  labels:
    security-zone: internal
```

#### Approccio 2: Cluster separati

```
┌─────────────────────┐     ┌─────────────────────┐
│  Internet           │     │                     │
└──────────┬──────────┘     │                     │
           │                │                     │
     ┌─────▼────────┐       │                     │
     │ Load Balancer│       │                     │
     └─────┬────────┘       │                     │
           │                │                     │
  ┌────────▼─────────┐      │  ┌────────────────┐ │
  │ K8s Cluster DMZ  │      │  │ K8s Cluster    │ │
  │                  │      │  │ Internal       │ │
  │ - Web Frontend   │◄───────►│                │ │
  │ - API Gateway    │      │  │ - Backend      │ │
  │ - Public APIs    │      │  │ - Databases    │ │
  └──────────────────┘      │  └────────────────┘ │
                            │                     │
                            │  Corporate Network  │
                            └─────────────────────┘
```

#### Approccio 3: Node pools dedicati

```yaml
# Node pool per DMZ
apiVersion: v1
kind: Node
metadata:
  name: dmz-node-1
  labels:
    zone: dmz
    node-pool: dmz-public
spec:
  taints:
  - key: zone
    value: dmz
    effect: NoSchedule
---
# Deployment in DMZ node pool
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: dmz
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        zone: dmz
    spec:
      # Tolerate DMZ taint
      tolerations:
      - key: zone
        operator: Equal
        value: dmz
        effect: NoSchedule
      # Affinity per DMZ nodes
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: zone
                operator: In
                values:
                - dmz
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "250m"
```

## 10bis.3 Network Policies per Microsegmentazione

### Cos'è una Network Policy

Le **Network Policy** in Kubernetes permettono di definire regole di comunicazione tra Pod, implementando **microsegmentazione** a livello di container.

### Default Deny Policy

```yaml
# Nega tutto il traffico in ingresso nel namespace DMZ
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: dmz
spec:
  podSelector: {}  # Applica a tutti i pod
  policyTypes:
  - Ingress
---
# Nega tutto il traffico in uscita nel namespace DMZ
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: dmz
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

### Allow Specific Traffic

```yaml
# Permettere traffico HTTPS da Internet verso web frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-ingress
  namespace: dmz
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}  # Da qualsiasi namespace
    ports:
    - protocol: TCP
      port: 443
---
# Permettere traffico da DMZ verso backend interno
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dmz-to-backend
  namespace: dmz
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  # Permettere DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Permettere traffico verso backend app
  - to:
    - namespaceSelector:
        matchLabels:
          security-zone: internal
      podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8080
---
# Backend può accettare solo da DMZ
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow-from-dmz
  namespace: internal-apps
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          security-zone: dmz
    ports:
    - protocol: TCP
      port: 8080
```

### Bloccare Comunicazione Laterale (East-West)

```yaml
# I pod DMZ non possono parlare tra loro
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-dmz-lateral
  namespace: dmz
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchExpressions:
        - key: security-zone
          operator: NotIn
          values:
          - dmz
```

## 10bis.4 Service Mesh e Sicurezza

### Cos'è un Service Mesh

Un **service mesh** è un layer di infrastruttura dedicato che gestisce la comunicazione service-to-service in modo trasparente, offrendo:
- **mTLS automatico** tra servizi
- **Traffic management** avanzato
- **Observability** (tracing, metrics, logging)
- **Policy enforcement** granulare

### Istio - Service Mesh Popolare

#### Architettura Istio

```
┌─────────────────────────────────────────┐
│           Istio Control Plane           │
│  ┌────────┐  ┌────────┐  ┌───────────┐  │
│  │ Pilot  │  │Citadel │  │  Galley   │  │
│  └────────┘  └────────┘  └───────────┘  │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
   ┌────▼────┐ ┌──▼─────┐ ┌──▼─────┐
   │ Pod A   │ │ Pod B  │ │ Pod C  │
   │┌───────┐│ │┌──────┐│ │┌──────┐│
   ││ App   ││ ││ App  ││ ││ App  ││
   │└───────┘│ │└──────┘│ │└──────┘│
   │┌───────┐│ │┌──────┐│ │┌──────┐│
   ││Envoy  ││◄┼┤Envoy ││◄┼┤Envoy ││
   ││Proxy  ││ ││Proxy ││ ││Proxy ││
   │└───────┘│ │└──────┘│ │└──────┘│
   └─────────┘ └────────┘ └────────┘
```

### mTLS Automatico con Istio

```yaml
# Abilitare mTLS STRICT per namespace DMZ
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: dmz-mtls
  namespace: dmz
spec:
  mtls:
    mode: STRICT  # Richiede mTLS per tutto il traffico
---
# Authorization Policy - Zero Trust
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: web-authz
  namespace: dmz
spec:
  selector:
    matchLabels:
      app: web
  action: ALLOW
  rules:
  # Permettere solo da ingress gateway
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/*"]
---
# Permettere web -> backend con JWT validation
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: backend-authz
  namespace: internal-apps
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["dmz"]
        principals: ["cluster.local/ns/dmz/sa/web"]
    to:
    - operation:
        methods: ["POST"]
    when:
    - key: request.auth.claims[role]
      values: ["admin", "user"]
```

### Traffic Shaping

```yaml
# Virtual Service per canary deployment
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-vs
  namespace: dmz
spec:
  hosts:
  - web.dmz.svc.cluster.local
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: web
        subset: v2
  - route:
    - destination:
        host: web
        subset: v1
      weight: 90
    - destination:
        host: web
        subset: v2
      weight: 10  # 10% traffico alla nuova versione
---
# Destination Rule
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: web-dr
  namespace: dmz
spec:
  host: web
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http2MaxRequests: 1000
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

## 10bis.5 Microsegmentazione Avanzata

### Zero Trust Network Architecture

Il modello **Zero Trust** rimuove il concetto di "trusted network", richiedendo autenticazione e autorizzazione per ogni connessione.

**Principi Zero Trust:**
1. **Verify explicitly**: autenticare sempre
2. **Least privilege access**: accesso minimo necessario
3. **Assume breach**: assumere che la rete sia già compromessa

### Implementazione Microsegmentazione

#### Layer 1: Network Segmentation (Namespace)

```yaml
# Struttura namespace per zone di fiducia
apiVersion: v1
kind: Namespace
metadata:
  name: zone-public
  labels:
    trust-level: "0"
---
apiVersion: v1
kind: Namespace
metadata:
  name: zone-dmz
  labels:
    trust-level: "1"
---
apiVersion: v1
kind: Namespace
metadata:
  name: zone-internal
  labels:
    trust-level: "2"
---
apiVersion: v1
kind: Namespace
metadata:
  name: zone-data
  labels:
    trust-level: "3"
```

#### Layer 2: Pod-level Segmentation

```yaml
# Fine-grained network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: microsegment-web
  namespace: zone-dmz
spec:
  podSelector:
    matchLabels:
      app: web
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Solo da load balancer
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Solo verso API gateway in DMZ
  - to:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 443
  # DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

#### Layer 3: Service-to-Service Authentication

```yaml
# Istio RequestAuthentication per JWT validation
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: zone-internal
spec:
  selector:
    matchLabels:
      app: backend-api
  jwtRules:
  - issuer: "https://auth.example.com"
    jwksUri: "https://auth.example.com/.well-known/jwks.json"
    audiences:
    - "backend-api"
```

### Cilium - Advanced Network Security

**Cilium** è una soluzione CNI (Container Network Interface) che offre microsegmentazione basata su **eBPF** (extended Berkeley Packet Filter).

#### Vantaggi di Cilium
- **Identity-based security**: policy basate su identità service, non IP
- **API-aware filtering**: filtraggio L7 (HTTP, gRPC, Kafka, etc.)
- **Observability**: network flow visibility completa
- **Performance**: eBPF kernel-level processing

#### Cilium Network Policy - L7

```yaml
# HTTP-aware policy
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: web-api-policy
  namespace: dmz
spec:
  endpointSelector:
    matchLabels:
      app: web
  egress:
  - toEndpoints:
    - matchLabels:
        app: backend-api
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/api/v1/users/.*"
        - method: "POST"
          path: "/api/v1/orders"
          headers:
          - "Authorization: Bearer .*"
  - toFQDNs:
    - matchPattern: "*.googleapis.com"
    toPorts:
    - ports:
      - port: "443"
        protocol: TCP
```

#### Cilium Cluster Mesh - Multi-cluster

```yaml
# Connettere multiple cluster per DMZ distribuita
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: cross-cluster-dmz
spec:
  endpointSelector:
    matchLabels:
      zone: dmz
  egress:
  - toEndpoints:
    - matchLabels:
        zone: internal
    - matchCluster: "cluster-west"  # Cluster remoto
```

## 10bis.6 Container Runtime Security

### Falco - Runtime Threat Detection

**Falco** monitora il comportamento dei container a runtime, rilevando attività anomale.

```yaml
# Falco rules per DMZ
- rule: Unexpected Network Connection from DMZ
  desc: Detect unexpected outbound connection from DMZ container
  condition: >
    container and 
    container.label.zone = "dmz" and
    outbound and 
    not fd.sip in (allowed_ips) and
    not fd.sport in (443, 53)
  output: >
    Unexpected connection from DMZ 
    (container=%container.name ip=%fd.cip port=%fd.cport)
  priority: WARNING

- rule: Unexpected Shell in DMZ Container
  desc: Shell spawned in DMZ container
  condition: >
    container and
    container.label.zone = "dmz" and
    proc.name in (shell_binaries)
  output: >
    Shell spawned in DMZ container
    (container=%container.name shell=%proc.name)
  priority: CRITICAL
```

### gVisor - Sandboxed Runtime

**gVisor** fornisce isolamento kernel-level aggiuntivo per container ad alto rischio.

```yaml
# RuntimeClass per gVisor
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
# Pod usando gVisor per maggiore isolamento
apiVersion: v1
kind: Pod
metadata:
  name: web-frontend
  namespace: dmz
spec:
  runtimeClassName: gvisor  # Usa gVisor invece di runc
  containers:
  - name: web
    image: nginx:alpine
```

## 10bis.7 Best Practices per Container DMZ

### Checklist Deployment

- [ ] **Immagini**: Scansionate e prive di CVE critiche
- [ ] **Non-root**: Container eseguono con user non privilegiato
- [ ] **Read-only FS**: Filesystem read-only dove possibile
- [ ] **Resource limits**: CPU e memoria limitati
- [ ] **Network Policies**: Default deny + allow espliciti
- [ ] **mTLS**: Crittografia service-to-service
- [ ] **Secrets management**: Usare Vault, Sealed Secrets, non env vars
- [ ] **Logging**: Centralizzato su SIEM
- [ ] **Runtime monitoring**: Falco o equivalente attivo
- [ ] **Vulnerability scanning**: Integrato in CI/CD
- [ ] **Pod Security Standards**: Enforced (Restricted profile)
- [ ] **Network segmentation**: Microsegmentazione implementata
- [ ] **Egress filtering**: Traffico uscente controllato
- [ ] **Admission control**: OPA/Gatekeeper per policy enforcement

### Pod Security Standards

```yaml
# Enforced Restricted Pod Security
apiVersion: v1
kind: Namespace
metadata:
  name: dmz
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### OPA Gatekeeper Policies

```yaml
# Constraint: bloccare immagini da registry non fidati
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: allowedregistries
spec:
  crd:
    spec:
      names:
        kind: AllowedRegistries
      validation:
        openAPIV3Schema:
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package allowedregistries
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        not startswith(container.image, input.parameters.registries[_])
        msg := sprintf("Image %v not from approved registry", [container.image])
      }
---
# Constraint instance
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AllowedRegistries
metadata:
  name: dmz-registries
spec:
  match:
    namespaces: ["dmz"]
  parameters:
    registries:
    - "gcr.io/my-project/"
    - "docker.io/library/"
```

## 10bis.8 Esempi Pratici

### Scenario 1: Web Application in Kubernetes DMZ

```yaml
# Namespace DMZ
apiVersion: v1
kind: Namespace
metadata:
  name: web-dmz
  labels:
    security-zone: dmz
---
# Deployment web frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: web-dmz
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: nginx
        image: gcr.io/my-project/web:1.0
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: web-dmz
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
---
# Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-netpol
  namespace: web-dmz
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Backend API
  - to:
    - namespaceSelector:
        matchLabels:
          security-zone: internal
      podSelector:
        matchLabels:
          app: backend-api
    ports:
    - protocol: TCP
      port: 8080
  # DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### Scenario 2: API Gateway con Rate Limiting

```yaml
# Istio VirtualService con rate limiting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-gateway
  namespace: web-dmz
spec:
  hosts:
  - api.example.com
  gateways:
  - public-gateway
  http:
  - match:
    - uri:
        prefix: /api/v1
    route:
    - destination:
        host: api-gateway
        port:
          number: 80
---
# EnvoyFilter per rate limiting
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: rate-limit
  namespace: web-dmz
spec:
  workloadSelector:
    labels:
      app: api-gateway
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.local_ratelimit
        typed_config:
          "@type": type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
          value:
            stat_prefix: http_local_rate_limiter
            token_bucket:
              max_tokens: 100
              tokens_per_fill: 100
              fill_interval: 60s
            filter_enabled:
              runtime_key: local_rate_limit_enabled
              default_value:
                numerator: 100
                denominator: HUNDRED
```

## 10bis.9 Monitoring e Observability

### Prometheus Metrics

```yaml
# ServiceMonitor per Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: web-metrics
  namespace: web-dmz
spec:
  selector:
    matchLabels:
      app: web
  endpoints:
  - port: metrics
    interval: 30s
```

### Grafana Dashboard Example

```json
{
  "dashboard": {
    "title": "DMZ Container Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(istio_requests_total{destination_namespace=\"web-dmz\"}[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(istio_requests_total{destination_namespace=\"web-dmz\",response_code=~\"5..\"}[5m])"
          }
        ]
      }
    ]
  }
}
```

## 10bis.10 Autovalutazione

### Domande

**1. Qual è la principale differenza tra container e VM in termini di sicurezza?**

**2. Perché le Network Policy sono essenziali in un ambiente Kubernetes DMZ?**

**3. Cos'è mTLS e come un service mesh lo implementa automaticamente?**

**4. Spiega il concetto di microsegmentazione e come si differenzia dalla segmentazione tradizionale di rete.**

**5. Quali sono i vantaggi di usare gVisor per container in DMZ?**

### Esercizio Pratico

**Scenario:**
Devi deployare un'applicazione e-commerce in Kubernetes con:
- Frontend web (React app)
- API Gateway
- Backend microservizi (3 servizi)
- Database PostgreSQL

**Requisiti:**
1. Implementare segmentazione a 3 tier (DMZ, App, Data)
2. Network Policies con default deny
3. Solo frontend esposto su Internet
4. API Gateway autentica con JWT
5. Comunicazione service-to-service con mTLS

**Compiti:**
- Disegna l'architettura
- Scrivi i manifest Kubernetes (Namespace, Deployments, Services)
- Definisci Network Policies appropriate
- Implementa Istio configuration per mTLS e AuthZ

---

*Questo capitolo fornisce le basi per implementare DMZ moderne basate su container e microsegmentazione, essenziali per architetture cloud-native sicure.*
