-- ==============================================================================
-- GOODREADS DATA TRANSFORMATION
-- File: 02_goodreads_duckdb_transformation.sql
-- Engine: DuckDB
-- Purpose: Clean, standardize, and deduplicate raw data (Silver / Staging Layer).
-- Methodology: All transformations are idempotent (tables are dropped and recreated).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. Clean environment
-- ------------------------------------------------------------------------------
-- Dropping existing tables ensures the script can be rerun multiple times safely.
DROP TABLE IF EXISTS books_transformation;
DROP TABLE IF EXISTS book_tags_transformation;
DROP TABLE IF EXISTS ratings_transformation;
DROP TABLE IF EXISTS tags_transformation;
DROP TABLE IF EXISTS to_read_transformation;

-- ------------------------------------------------------------------------------
-- 1. Books transformation
-- ------------------------------------------------------------------------------
-- Purpose: Handle missing values, standardize strings, and fix formatting anomalies.
create table books_transformation as
select
    book_id,
    goodreads_book_id,
    best_book_id,
    work_id,
    books_count,

    -- string cleaning: casting to varchar, trimming spaces, replacing empty strings
    -- with null (via nullif), and finally assigning a default 'unknown'.
    coalesce(
        nullif(trim(cast(isbn as varchar)), ''),
        'unknown'
    ) as isbn,

    -- regex formatting: some isbn-13s were corrupted into scientific notation (e.g., '9.78e+12').
    -- duckdb's native regex functions fix this efficiently.
    case
        when regexp_matches(cast(isbn13 as varchar), 'e\+') then
            lpad(
                regexp_replace(
                    cast(cast(isbn13 as numeric) as varchar),
                    '\.0$', ''
                ),
                13, '0'
            )
        when nullif(trim(cast(isbn13 as varchar)), '') is null then 'unknown'
        else cast(isbn13 as varchar)
    end as isbn13,

    authors,

    -- default values: replacing missing numeric values with -1.
    coalesce(original_publication_year, -1) as original_publication_year,
    
    -- fallback logic: if the original title is missing, fallback to the standard title.
    coalesce(nullif(trim(original_title), ''), title) as original_title,
    title,
    coalesce(nullif(trim(language_code), ''), 'unknown') as language_code,

    average_rating,
    ratings_count,
    work_ratings_count,
    work_text_reviews_count,
    ratings_1,
    ratings_2,
    ratings_3,
    ratings_4,
    ratings_5,
    image_url,
    small_image_url
from books;

-- ------------------------------------------------------------------------------
-- 2. Book‑tags transformation (Deduplication)
-- ------------------------------------------------------------------------------
-- DUCKDB SUPERPOWER: The QUALIFY clause.
-- Filters the result of the ROW_NUMBER() window function without needing a CTE.
-- We keep the row with the highest "count" for each book-tag combination.
create table book_tags_transformation as
select goodreads_book_id, tag_id, "count"
from book_tags
qualify row_number() over (
    partition by goodreads_book_id, tag_id
    order by "count" desc
) = 1;

-- ------------------------------------------------------------------------------
-- 3. Ratings transformation (Conflict Resolution)
-- ------------------------------------------------------------------------------
-- Assumption: If a user has rated the same book multiple times, keep the highest rating.
create table ratings_transformation as
select user_id, book_id, rating
from ratings
qualify row_number() over (
    partition by user_id, book_id
    order by rating desc
) = 1;

-- ------------------------------------------------------------------------------
-- 4. Tags transformation
-- ------------------------------------------------------------------------------
-- The tags table doesn't need heavy cleaning for now, a straight copy is fine.
create table tags_transformation as
select * from tags;

-- ------------------------------------------------------------------------------
-- 5. To‑read transformation (Exact Deduplication)
-- ------------------------------------------------------------------------------
-- OPTIMIZATION: SELECT DISTINCT is incredibly fast in columnar databases for 
-- removing exact duplicate rows.
create table to_read_transformation as
select distinct user_id, book_id
from to_read;