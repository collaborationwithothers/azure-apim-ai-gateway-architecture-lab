# Failure Modes: Load Balancing and Failover

## Purpose

This page supports the Load Balancing and Failover scenario. It captures active-active backends, priority selection, weighted routing, circuit breaker behavior, 429 and 503 handling, and regional failover in a format that can be expanded during later implementation.

## Current content

The Load Balancing and Failover scenario focuses on active-active backends, priority selection, weighted routing, circuit breaker behavior, 429 and 503 handling, and regional failover. The first-pass content is intentionally descriptive and safe. It avoids real endpoints and keeps implementation details as TODOs until the lab has mock services and deployment inputs.

## TODOs

- Replace placeholders with environment-specific values during a controlled deployment pass.
- Add tests against a mock backend before importing policies into APIM.
- Update citations and policy syntax if Microsoft Learn changes relevant APIM AI gateway behavior.
