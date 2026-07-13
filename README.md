# Passenger Journey Optimization Pipeline

An end-to-end data engineering and predictive analytics pipeline designed to identify terminal bottlenecks, model passenger satisfaction decay, and deploy proactive operational flags using BigQuery, Python, and Looker Studio.

## System Architecture & Pipeline
The system operates across three core architectural stages to move data from raw logs to live business execution:
1. **Data Infrastructure (BigQuery SQL):** Ingests raw passenger surveys and timestamps, handles anomalies, and applies *Composite Index Synthesis* to engineer a uniform 0–100 scale **Terminal Comfort Index (TCI)**.
2. **Predictive Engine (Python on Google Colab):** Performs *Vectorized One-Hot Encoding* into a 54-column matrix, executes *Stratified Data Partitioning* (80:20 split), and trains a **Random Forest Classifier** to map non-linear operational satisfaction boundaries.
3. **BI & Field Execution (Google Data Studio):** Establishes a live streaming data connection to dynamically monitor flight cohorts and trigger real-time operational alerts.

---

## Key Engineering Techniques
* **Composite Index Synthesis:** Compresses multi-dimensional passenger friction data (crowding, navigability, amenity access) into a single continuous tracking metric.
* **Stratified Data Partitioning:** Splits data into 46,011 training rows and 11,503 testing rows while strictly locking target class proportions to eliminate data leakage.
* **Ensemble Machine Learning:** Deploys a 100-tree Random Forest architecture capable of discovering non-linear behavioral cliffs that traditional linear models miss.
* **Proactive Threshold Flagging:** Translates backend model probabilities into automated operational risk alerts to catch service decay before it occurs.

---

## Key Analytical Insights
### 1. Complete Bottleneck Exposure & Strategic Directives
* **Eliminating the Illusion:** Stripping away artificial baseline floors completely removes ghost "Moderate Delay" slices, proving that checkpoint delays are a permanent structural bottleneck rather than an occasional issue.
* **Universal Friction:** Under high-load periods, 99.9% of highly impacted passengers drop directly into the "Systemic Bottlenecks" category, exposing severe, universal friction at key checkpoints.
* **Leadership Mandate:** This drastic shift reveals a critical reality for management: security screening and passport control require immediate operational intervention and a total workflow overhaul.

### 2. Permanent Polarized Split & Operational Drop
* **Polarized Tracks:** Passenger sentiment is locked into two distinct tracks—a high-satisfaction cohort tracking optimally between 65.78 and 67.38, and a low-satisfaction cohort trapped below 51.00.
* **The Mid-Dwell Cliff:** At exactly the 1.75-hour mark, the low-satisfaction segment plummets to an absolute floor of 48.48, exposing a severe bottleneck during mid-dwell peak periods.
* **Divergent Realities:** Conversely, the high-satisfaction segment peaks at 67.38 within that same 1.75-to-2.75-hour window, proving that identical operational conditions maximize comfort for one passenger profile while completely breaking another.

---

## Model Performance Validation

* **Global Accuracy:** **79.73%** accurate classification rate on passenger satisfaction states.
* **ROC-AUC Score:** **0.8648**, indicating an **Excellent Separation** capability to reliably distinguish between stable and vulnerable passenger cohorts.

---

## Operational Deployment

The final pipeline connects the predictive backend directly to **Google Data Studio**, shifting terminal management from historical auditing to real-time field mitigation. The platform automatically flags operations teams the moment an active passenger cohort begins moving toward the critical **51.00 comfort floor** or hits the **1.75-hour decay wall**.
