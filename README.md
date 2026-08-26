# Goodreads Data Warehouse: PostgreSQL & DuckDB

An end-to-end data engineering project: from raw CSV files to an analytical star schema, featuring a dual-engine architecture (PostgreSQL & DuckDB) and a Power BI dashboard.

##  Why This Project?
As an aspiring data engineer, I built this project to demonstrate my ability to:
* Explore and assess raw, messy data.
* Design an idempotent ETL pipeline using SQL.
* Model a Kimball-style star schema with many-to-many relationships.
* Handle real-world data quality issues (scientific notation, missing values, duplicates).
* **Compare a traditional relational engine (PostgreSQL) with a modern columnar OLAP engine (DuckDB) for high-speed analytical queries.**
* Create a clean, well-documented repository suitable for a professional portfolio.

This project mimics the typical workflow in a data team: import CSVs, clean anomalies, normalize entities, and deliver a ready-to-query dimensional model.

## 📊 Dataset
Source: [goodbooks-10k on GitHub](https://github.com/zygmuntz/goodbooks-10k). A dataset of 10,000 books, 6M+ ratings, tags, and to-read lists from Goodreads.

## Original tables:
- `books.csv`
- `ratings.csv`
- `book_tags.csv`
- `tags.csv`
- `to_read.csv`

## 🏗️ Architecture & Dual Pipeline
To highlight different Data Engineering techniques, the repository is split into two implementations:

### 1. PostgreSQL Pipeline (The BI Backend)
Used as the robust backend for Data Visualization. 
* **Integration:** Natively connected to **Power BI** to power the final dashboard.
* **Methodology:** Standard relational DDL, manual `COPY` ingestion, and traditional CTEs for data cleaning.

### 2. DuckDB Pipeline (The Analytical Engine)
Built to demonstrate blazing-fast local OLAP analytics, processing 6M+ rows in seconds via DBeaver.
* **Exploration:** Advanced EDA, anomaly detection, and array unnesting (`01_exploration.sql`).
* **Transformation:** Leverages DuckDB's `QUALIFY` clause for elegant deduplication (`02_transformation.sql`).
* **Star Schema:** Generates surrogate keys on the fly using Window Functions, building an idempotent Kimball model with explicit Primary and Foreign Keys (`03_dimensions_facts.sql`).

##  Technologies
* **Databases:** PostgreSQL, DuckDB
* **Languages:** SQL
* **Tools:** DBeaver, Power BI, Git

##  Key Design Decisions
* **Idempotency:** All scripts use `DROP TABLE IF EXISTS` + `CREATE TABLE ... INSERT` (or CTAS) to guarantee reproducible results on multiple runs.
* **ISBN13 Cleaning:** Scientific notation (e.g., '9.78E+12') is converted back to 13-digit strings with zero-padding using Regex.
* **Missing Values:** Assigned `'unknown'` for text fields, `-1` for missing publication years.
* **Duplicate Handling:** Resolved via Window Functions (`ROW_NUMBER()`) keeping the most relevant row (e.g., highest rating).
* **Many-to-Many Relationships:** Resolved via bridge tables (book–authors, book–tags) to avoid inflating fact table aggregations.
* **Two Fact Tables:** Segregated events into `fact_ratings` (transactional, measurable) and `fact_to_read` (factless, tracking state/intent).
