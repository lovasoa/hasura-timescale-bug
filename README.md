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

### As a query

Go to the "API" tab in the Hasura Console and execute the following query:

```graphql
query MyQuery($min: Int, $max:Int) {
  conditions(where:{id:{_gte: $min, _lte: $max}}) {
    value
  }
}

```

#### Hasura-Generated SQL

```sql
SELECT
  coalesce(json_agg("root"), '[]') AS "root"
FROM
  (
    SELECT
      row_to_json(
        (
          SELECT
            "_e"
          FROM
            (
              SELECT
                "_root.base"."value" AS "value"
            ) AS "_e"
        )
      ) AS "root"
    FROM
      (
        SELECT
          *
        FROM
          "public"."conditions"
        WHERE
          (
            (
              ("public"."conditions"."id") >= (('123456') :: integer)
            )
            AND (
              ("public"."conditions"."id") <= (('123456') :: integer)
            )
          )
      ) AS "_root.base"
  ) AS "_root"
```

Execution time: 1.429 ms

#### Query plan

```
Aggregate  (cost=8.31..8.32 rows=1 width=32)
  ->  Index Scan using "124_124_conditions_pkey" on _hyper_1_124_chunk  (cost=0.28..8.29 rows=1 width=23)
        Index Cond: ((id >= 123456) AND (id <= 123456))
  SubPlan 1
    ->  Result  (cost=0.00..0.01 rows=1 width=32)
```

### As a subscription

and compare with running the subscription

```graphql
subscription MyQuery($min: Int, $max:Int) {
  conditions(where:{id:{_gte: $min, _lte: $max}}) {
    value
  }
}
```
#### Hasura-Generated SQL

```sql
SELECT "__subs"."result_id",
       "__fld_resp"."root" AS "result"
FROM UNNEST(($1) :: UUID [], ($2) :: JSON []) AS "__subs"("result_id",
                                                            "result_vars")
LEFT OUTER JOIN LATERAL
  (SELECT json_build_object('conditions', "_conditions"."root") AS "root"
   FROM
     (SELECT coalesce(json_agg("root"), '[]') AS "root"
      FROM
        (SELECT row_to_json(
                              (SELECT "_e"
                               FROM
                                 (SELECT "_root.base"."value" AS "value") AS "_e")) AS "root"
         FROM
           (SELECT *
            FROM "public"."conditions"
            WHERE ((("public"."conditions"."id") >= ((("__subs"."result_vars" #>>ARRAY['synthetic','0']))::integer))
                   AND (("public"."conditions"."id") <= ((("__subs"."result_vars"#>>ARRAY['synthetic','1']))::integer))
                  )) AS "_root.base") AS "_root"
        ) AS "_conditions"
    ) AS "__fld_resp"
ON ('true')
```

Execution time: 311.832 ms

#### Query plan

```
Nested Loop Left Join  (cost=42338.90..42338.94 rows=1 width=48)
  ->  Function Scan on __subs  (cost=0.01..0.01 rows=1 width=48)
  ->  Subquery Scan on _conditions  (cost=42338.89..42338.92 rows=1 width=32)
        ->  Aggregate  (cost=42338.89..42338.90 rows=1 width=32)
              ->  Custom Scan (ChunkAppend) on conditions  (cost=0.29..41963.80 rows=25006 width=23)
                    ->  Index Scan using "1_1_conditions_pkey" on _hyper_1_1_chunk  (cost=0.29..8.39 rows=5 width=23)
                          Index Cond: ((id >= ((__subs.result_vars #>> '{synthetic,0}'::text[]))::integer) AND (id <= ((__subs.result_vars #>> '{synthetic,1}'::text[]))::integer))
                    ->  Index Scan using "2_2_conditions_pkey" on _hyper_1_2_chunk  (cost=0.29..8.39 rows=5 width=23)
                          Index Cond: ((id >= ((__subs.result_vars #>> '{synthetic,0}'::text[]))::integer) AND (id <= ((__subs.result_vars #>> '{synthetic,1}'::text[]))::integer))

                        [... thousands of index scans...]

                    ->  Index Scan using "5000_5000_conditions_pkey" on _hyper_1_5000_chunk  (cost=0.29..8.39 rows=5 width=23)
                          Index Cond: ((id >= ((__subs.result_vars #>> '{synthetic,0}'::text[]))::integer) AND (id <= ((__subs.result_vars #>> '{synthetic,1}'::text[]))::integer))
                    ->  Bitmap Heap Scan on _hyper_1_5001_chunk  (cost=4.23..13.80 rows=6 width=32)
                          Recheck Cond: ((id >= ((__subs.result_vars #>> '{synthetic,0}'::text[]))::integer) AND (id <= ((__subs.result_vars #>> '{synthetic,1}'::text[]))::integer))
                          ->  Bitmap Index Scan on "5001_5001_conditions_pkey"  (cost=0.00..4.23 rows=6 width=0)
                                Index Cond: ((id >= ((__subs.result_vars #>> '{synthetic,0}'::text[]))::integer) AND (id <= ((__subs.result_vars #>> '{synthetic,1}'::text[]))::integer))
              SubPlan 1
                ->  Result  (cost=0.00..0.01 rows=1 width=32)
```
