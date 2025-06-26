# 🏦 Microservicio de Saldos y Pagos – Banco Etheria (POC)

Este repositorio contiene una prueba de concepto (POC) para el microservicio principal del sistema de pagos del **Banco Etheria**. La aplicación simula las operaciones de **consulta de saldo**, **pagos** y **retiros** para clientes, y está diseñada para ejecutarse en contenedores bajo AWS ECS Fargate.

---

## 🚀 Objetivo de la POC

- Mostrar la viabilidad de una arquitectura basada en contenedores.
- Demostrar alta disponibilidad y bajo acoplamiento.
- Servir como guía para el despliegue automatizado (CI/CD).
- Simular comportamiento del sistema productivo de forma simple y clara.

---

## 🧱 Tecnologías utilizadas

- Python 3.13
- Flask
- Docker
- Simulación de almacenamiento en memoria (`dict`)

---

## 📦 Endpoints disponibles

### `GET /saldo/<usuario>`
Consulta el saldo actual de un usuario. Si el usuario no existe, se inicializa con **100000 CLP**.

📌 Ejemplo:
```bash
curl http://localhost:5000/saldo/usuario1
```

📤 Respuesta:
```json
{
  "usuario": "usuario1",
  "saldo": 100000
}
```

---

### `POST /pago`
Realiza un pago desde la cuenta del usuario. Si no existe, se inicializa con 100000 CLP.

📌 Payload:
```json
{
  "usuario": "usuario1",
  "monto": 5000
}
```

📤 Respuesta:
```json
{
  "usuario": "usuario1",
  "monto_pagado": 5000,
  "nuevo_saldo": 95000
}
```

---

### `POST /retiro`
Realiza un retiro con el mismo criterio que el pago, pero validando que no se exceda el saldo.

📌 Payload:
```json
{
  "usuario": "usuario2",
  "monto": 20000
}
```

📤 Posible respuesta:
```json
{
  "error": "El monto excede el saldo disponible.",
  "saldo_disponible": 15000
}
```

---

### `GET /health`
Verifica que el servicio esté corriendo correctamente.

---

## 🐳 Uso con Docker

### 1. Construir la imagen

```bash
docker build -t banco-etheria-poc .
```

### 2. Ejecutar localmente

```bash
docker run -p 5000:5000 banco-etheria-poc
```

---

## 🛡️ Consideraciones

- Esta aplicación no persiste datos (usa memoria volátil).
- Pensada exclusivamente para entornos de desarrollo y pruebas.
- Cumple con los pilares del **AWS Well-Architected Framework**: simplicidad, trazabilidad, disponibilidad y eficiencia.

---

## 📁 Estructura del repositorio

```
.
├── app.py                # Aplicación principal Flask
├── requirements.txt      # Dependencias
├── Dockerfile            # Imagen base para despliegue
└── README.md             # Esta documentación
```

## 🗺️ Arquitectura de la implementación del POC (Mermaid Diagram)
```mermaid
---
config:
  layout: elk
---
flowchart TD
    %% Subredes y VPC
    subgraph subGraph0["Subred 1"]
        D1["Tarea Fargate:<br>Microservicio Saldos"]
    end
    subgraph subGraph1["Subred 2"]
        D2["Tarea Fargate:<br>Microservicio Pagos"]
    end
    subgraph subGraph2["Subred 3"]
        D3["Tarea Fargate:<br>Microservicio Notificaciones"]
    end
    subgraph subGraph3["VPC Privada"]
        subGraph0
        subGraph1
        subGraph2
    end

    %% Infraestructura y flujo
    A["Clientes web<br>API"]
    B["ALB<br>DNS URL"]
    C["AWS WAF + ALB"]
    D["ECS Cluster"]
    J["Build & Push a ECR"]
    G["Terraform"]
    H["Github repository"]

    %% Conexiones
    A -- "HTTPS:5000" --> B
    B --> C --> D
    D --> D1 & D2 & D3
    J --> C
    H -- "git clone" --> J
    G --> H
    G --> C

    %% Estilos por función
    style A fill:#e6f7ff,stroke:#3399ff       %% Entrada
    style B fill:#d9f7be,stroke:#52c41a       %% Routing
    style C fill:#d9f7be,stroke:#52c41a       %% WAF + ALB
    style D fill:#ffe7ba,stroke:#fa8c16       %% ECS Cluster
    style D1 fill:#f9f0ff,stroke:#9254de      %% Fargate
    style D2 fill:#f9f0ff,stroke:#9254de
    style D3 fill:#f9f0ff,stroke:#9254de
    style J fill:#e6f7ff,stroke:#13c2c2       %% Build&Push
    style G fill:#fff1b8,stroke:#faad14       %% Terraform
    style H fill:#f0f0f0,stroke:#8c8c8c       %% GitHub repo
```


---

## 🗺️ Arquitectura completa del caso (Mermaid Diagram)

```mermaid
---
config:
  layout: elk
---
flowchart TD
 subgraph subGraph0["Subred 1"]
        D1["Tarea Fargate:<br>Microservicio Saldos"]
  end
 subgraph subGraph1["Subred 2"]
        D2["Tarea Fargate:<br>Microservicio Pagos"]
  end
 subgraph subGraph2["Subred 3"]
        D3["Tarea Fargate:<br>Microservicio Notificaciones"]
  end
 subgraph subGraph3["VPC Privada"]
        subGraph0
        subGraph1
        subGraph2
        E["Amazon RDS Multi-AZ"]
        G3["Exportación a S3<br> logs históricos"]
  end
    A["Visitas Web/Móvil"] --> B["Amazon Route 53"]
    B --> C["AWS WAF + ALB"]
    C --> D["ECS Cluster"]
    D --> D1 & D2 & D3
    D1 --> E & G1["CloudWatch Logs<br> Retención corta"] & G2["X-Ray Tracing<br> con muestreo"]
    D2 --> E & G1 & G2
    D3 --> E & G1 & G2
    E --> F["AWS Secrets Manager"]
    G1 --> G3
    L["AWS CloudTrail<br> Write-only, multi-región"] --> G3
    H["Repositorio GitHub/GitLab"] --> I["CodePipeline + CodeBuild"]
    I --> J["Build & Push a ECR"]
    J --> K["aws ecs update-service"]
    K --> D
    style A fill:#e6f7ff,stroke:#3399ff
    style B fill:#e6f7ff,stroke:#3399ff
    style C fill:#d9f7be,stroke:#52c41a
    style D fill:#ffe7ba,stroke:#fa8c16
    style D1 fill:#f9f0ff,stroke:#9254de
    style D2 fill:#f9f0ff,stroke:#9254de
    style D3 fill:#f9f0ff,stroke:#9254de
    style E fill:#ffd6e7,stroke:#eb2f96
    style F fill:#fff1b8,stroke:#d48806
    style G1 fill:#d6e4ff,stroke:#2f54eb
    style G2 fill:#cceeff,stroke:#13c2c2
    style G3 fill:#fafafa,stroke:#000000
    style L fill:#ffe7f0,stroke:#eb2f96
    style H fill:#d3f261,stroke:#389e0d
    style I fill:#cceeff,stroke:#1890ff
    style J fill:#e6f7ff,stroke:#13c2c2
    style K fill:#f6ffed,stroke:#52c41a
```

---
