# Hasura and TimescaleDB Docker Setup

This repository contains a Docker Compose setup for running Hasura GraphQL Engine with a TimescaleDB database.

The database is initialized with a `conditions` hypertable containing some sample data.

## Prerequisites

- Docker
- Docker Compose

## Getting Started

### **Start the services:**

   ```bash
   docker-compose up -d
   ```

### **Access the Hasura Console:**

   Open your web browser and navigate to `http://localhost:8080`.

   The admin secret is `myadminsecretkey` (as defined in `docker-compose.yml`).

### **Run an example GraphQL query:**

Go to the "API" tab in the Hasura Console and execute the following query:

```graphql
query MyQuery($min: Int, $max:Int) {
  conditions(where:{id:{_gte: $min, _lte: $max}}) {
    value
  }
}

```

and compare with running the subscription

```graphql
subscription MyQuery($min: Int, $max:Int) {
  conditions(where:{id:{_gte: $min, _lte: $max}}) {
    value
  }
}
```
