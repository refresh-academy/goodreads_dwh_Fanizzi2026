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

##  Dataset
Source: [goodbooks-10k on GitHub](https://github.com/zygmuntz/goodbooks-10k). A dataset of 10,000 books, 6M+ ratings, tags, and to-read lists from Goodreads.

## Original tables:
- `books.csv`
- `ratings.csv`
- `book_tags.csv`
- `tags.csv`
- `to_read.csv`

##  Architecture & Dual Pipeline
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

## 📊 Data Visualization & Business Insights (Power BI)

To complete the end-to-end data pipeline, I connected Power BI to the underlying data warehouse to build an interactive dashboard. This layer translates the modeled data into actionable business insights, demonstrating how the backend structure supports front-end analytics.

### 1. Dashboard Overview: Key Metrics & Top Authors
The initial view provides a high-level snapshot of the dataset's scale and highlights the most critically acclaimed authors.

![Dashboard Overview](data_visualization/dashboard_overview.png)

**Key Insights:**
* **Massive User Engagement:** The dataset encompasses over 6 million individual ratings across 10,000 books, maintaining a solid average global rating of 3.92.
* **Top Tier Authors:** Bill Watterson leads the global ranking with a stellar 4.7 average rating, outperforming other highly acclaimed authors.

---

### 2. Popularity vs. Quality (Top 10 Books)
This visual investigates the relationship between a book's mass appeal (total volume of reviews) and its critical reception (average rating score). 

![Popularity vs Appreciation](data_visualization/populary_vs_appreciation.png)

**Key Insights:**
* **Volume vs. Score:** The most reviewed books are not necessarily the highest-rated. For example, *The Hunger Games* leads in total reviews, but its average rating is lower compared to some other top 10 blockbusters.

---

### 📂 Explore the Dashboard Files
For a deeper dive into the Data Visualization phase, all related files are available in the [`data_visualization/`](data_visualization/) directory:
* 📊 **[Interactive Power BI File (.pbix)](data_visualization/goodreads_datavisualization.pbix)** - The original Power BI Desktop file (under 20MB, containing the data model and DAX measures).
* 📄 **[Static Dashboard Export (.pdf)](data_visualization/goodreads_fanizzi_datavisualization.pdf)** - A lightweight PDF export, perfect for a quick review without needing Power BI installed.
