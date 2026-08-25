-- ==============================================================================
-- GOODREADS STAR SCHEMA
-- Purpose: Build the dimensional model from cleaned transformation tables.
-- This script is idempotent: it drops existing tables and recreates them.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. Clean environment
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_ratings         CASCADE;
DROP TABLE IF EXISTS fact_to_read        CASCADE;
DROP TABLE IF EXISTS bridge_book_tags    CASCADE;
DROP TABLE IF EXISTS bridge_book_authors CASCADE;
DROP TABLE IF EXISTS dim_books           CASCADE;
DROP TABLE IF EXISTS dim_authors         CASCADE;
DROP TABLE IF EXISTS dim_tags            CASCADE;

-- ------------------------------------------------------------------------------
-- 1. Dimension tables
-- ------------------------------------------------------------------------------

-- 1.1 Books dimension
--     Contains descriptive attributes for each book.
--     The textual 'authors' column is removed; authors are handled via a bridge.
create table dim_books as
select
    book_id,
    goodreads_book_id,
    isbn,
    isbn13,
    original_publication_year,
    original_title,
    title,
    language_code,
    average_rating,
    image_url
from books_transformation;

alter table dim_books
    add primary key (book_id);

alter table dim_books
    add constraint uq_goodreads_id unique (goodreads_book_id);

-- 1.2 Authors dimension
--     Extracted from the comma‑separated authors field in books_transformation.
create table dim_authors (
    author_id   serial primary key,
    author_name varchar(255) not null unique
);

insert into dim_authors (author_name)
select distinct
    trim(unnest(string_to_array(authors, ',')))
from books_transformation
where authors is not null;

-- 1.3 tags dimension
--     simple copy from the already clean tags_transformation.
create table dim_tags as
select
    tag_id,
    tag_name
from tags_transformation;

alter table dim_tags
    add primary key (tag_id);

-- ------------------------------------------------------------------------------
-- 2. Bridge tables (many‑to‑many relationships)
-- ------------------------------------------------------------------------------

-- 2.1 Books ↔ Authors bridge
--     Each row links a book to one of its authors.
create table bridge_book_authors (
    book_id   int,
    author_id int,
    primary key (book_id, author_id)
);

-- The lateral unnest() returns a column named 'unnest'; we alias it as 'author_name'
-- so that we can join cleanly with dim_authors.
insert into bridge_book_authors (book_id, author_id)
select distinct
    bt.book_id,
    a.author_id
from books_transformation bt
cross join lateral unnest(string_to_array(bt.authors, ',')) as sa(author_name)
join dim_authors a on a.author_name = trim(sa.author_name);

-- 2.2 Books ↔ Tags bridge
--     Links books (via goodreads_book_id) to tags.
--     The "count" column indicates how many times the tag was applied.
create table bridge_book_tags as
select
    goodreads_book_id,
    tag_id,
    "count"
from book_tags_transformation;

alter table bridge_book_tags
    add primary key (goodreads_book_id, tag_id);

-- ------------------------------------------------------------------------------
-- 3. Fact tables
-- ------------------------------------------------------------------------------

-- 3.1 Ratings fact
--     Each row is a rating given by a user to a book.
create table fact_ratings as
select
    user_id,
    book_id,
    rating
from ratings_transformation;

-- 3.2 to‑read factless fact
--     each row indicates a user has marked a book as "to read".
create table fact_to_read as
select
    user_id,
    book_id
from to_read_transformation;

-- ------------------------------------------------------------------------------
-- 4. Foreign key constraints
-- ------------------------------------------------------------------------------

-- Bridge book‑authors → dim_books and dim_authors
alter table bridge_book_authors
    add constraint fk_bba_book   foreign key (book_id)   references dim_books(book_id),
    add constraint fk_bba_author foreign key (author_id) references dim_authors(author_id);

-- Bridge book‑tags → dim_books (via goodreads_book_id) and dim_tags
alter table bridge_book_tags
    add constraint fk_bridge_books foreign key (goodreads_book_id)
        references dim_books(goodreads_book_id),
    add constraint fk_bridge_tags  foreign key (tag_id)
        references dim_tags(tag_id);

-- Fact tables → dim_books
alter table fact_ratings
    add constraint fk_fact_ratings_book foreign key (book_id)
        references dim_books(book_id);

alter table fact_to_read
    add constraint fk_fact_to_read_book foreign key (book_id)
        references dim_books(book_id);

-- ==============================================================================
-- WHY TWO FACT TABLES?
-- ==============================================================================
-- This star schema intentionally separates two distinct user actions:
--
-- 1. fact_ratings   – a user **rates** a book (numeric measure: rating 1-5).
--                     This table answers: "What score did a user give?"
--                     It supports aggregations like AVG(rating), COUNT(*), etc.
--
-- 2. fact_to_read   – a user **marks a book as "to read"** (no numeric measure).
--                     This is a classic "factless fact table": the mere presence
--                     of a row indicates the event. The measure is the count
--                     of rows, not a value.
--
-- If we merged them into a single fact table, we would introduce semantic noise:
-- some rows would have a rating, others would not, requiring NULLs or sentinel
-- values. This would make queries more complex and less reliable.
--
-- Keeping them separate follows Kimball methodology: each fact table represents
-- one distinct business process. This makes the model easier to query,
-- understand, and maintain.
--
-- Therefore, the DWH contains:
--   - Dimensions (who/what): books, authors, tags
--   - Bridge tables (many-to-many relationships): book_authors, book_tags
--   - Fact tables (events): ratings (measurable), to_read (factless)
--
-- This design is a classic star schema, ready for analytical queries and BI tools.