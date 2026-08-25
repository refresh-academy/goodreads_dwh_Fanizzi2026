# Goodreads Data Warehouse

An end-to-end data engineering project: from raw CSV files to an analytical star schema, with SQL transformations and a Power BI dashboard.

## Why This Project?

As an aspiring data engineer, I built this project to demonstrate my ability to:

- Explore and assess raw, messy data
- Design an idempotent ETL pipeline using pure SQL
- Model a Kimball-style star schema with many-to-many relationships
- Handle real-world data quality issues (scientific notation, missing values, duplicates)
- Create a clean, well-documented repository suitable for a professional portfolio

This project mimics the typical workflow in a data team: import CSVs, clean anomalies, normalize entities, and deliver a ready-to-query dimensional model.

## Dataset

Source: https://github.com/zygmuntz/goodbooks-10k 
A dataset of 10,000 books, ratings, tags, and to-read lists from Goodreads.

Original tables:
- `books.csv`
- `ratings.csv`
- `book_tags.csv`
- `tags.csv`
- `to_read.csv`

## Architecture

1. **Exploration** — goodreads_query_exploration.sql  
   Assess data quality, distributions, anomalies, and relationships.

2. **Transformation** — goodreads_dwh_transformation.sql 
   Idempotent cleaning and deduplication using CTAS (no UPDATE/INSERT).

3. **Star Schema** — goodreads_dimensions_facts.sql 
   Build dimensions, facts, and bridge tables with primary/foreign keys.

**Technologies** 

-- PostgreSQL
-- SQL
-- PowerBI

**Key Design Decisions**

**Idempotency**: All transformation scripts use DROP IF EXISTS ... CASCADE + CREATE TABLE AS SELECT to guarantee reproducible results.

**ISBN13 cleaning**: Scientific notation is converted back to 13-digit strings with zero-padding.

**Missing values**: 'UNKNOWN' for text fields, -1 for publication year.

**Duplicate handling**: ROW_NUMBER() with appropriate ordering (highest count for tags, highest rating for ratings).

**Many-to-many relationships**: Resolved via bridge tables (book–authors, book–tags).

**Two fact tables**: fact_ratings (measurable) and fact_to_read (factless) to separate distinct user actions.




