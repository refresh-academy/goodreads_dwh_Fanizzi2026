-- ==============================================================================
-- GOODREADS STAR SCHEMA (Gold Layer / Data Mart)
-- File: 03_goodreads_duckdb_dimensions_facts.sql
-- Engine: DuckDB
-- Purpose: Idempotent script to build dimensional model with explicit PKs/FKs.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. CLEANUP (Ensures idempotency by dropping old tables in reverse dependency order)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_ratings;
DROP TABLE IF EXISTS fact_to_read;
DROP TABLE IF EXISTS bridge_book_tags;
DROP TABLE IF EXISTS bridge_book_authors;
DROP TABLE IF EXISTS dim_books;
DROP TABLE IF EXISTS dim_authors;
DROP TABLE IF EXISTS dim_tags;

-- ------------------------------------------------------------------------------
-- 1. DIMENSION TABLES (With Primary Keys)
-- ------------------------------------------------------------------------------

-- 1.1 Books Dimension
create table dim_books (
    book_id integer primary key,
    goodreads_book_id integer unique,
    isbn varchar,
    isbn13 varchar,
    original_publication_year integer,
    original_title varchar,
    title varchar,
    language_code varchar,
    average_rating double,
    image_url varchar
);

insert into dim_books
select book_id, goodreads_book_id, isbn, isbn13, original_publication_year,
       original_title, title, language_code, average_rating, image_url
from books_transformation;


-- 1.2 Authors Dimension
create table dim_authors (
    author_id integer primary key,
    author_name varchar unique
);

insert into dim_authors
select row_number() over () as author_id, author_name
from (
    select distinct trim(unnest(string_split(authors, ','))) as author_name
    from books_transformation where authors is not null
);


-- 1.3 Tags Dimension
create table dim_tags (
    tag_id integer primary key,
    tag_name varchar
);

insert into dim_tags
select tag_id, tag_name from tags_transformation;


-- ------------------------------------------------------------------------------
-- 2. BRIDGE TABLES (Resolving Many-to-Many Relationships)
-- ------------------------------------------------------------------------------
-- ARCHITECTURAL NOTE: Why do we need Bridge Tables?
-- In a traditional Kimball Star Schema, Many-to-Many relationships (e.g., one book 
-- can have multiple authors/tags, and one author/tag can belong to multiple books) 
-- cannot be linked directly to the Fact table. If we did, we would artificially 
-- duplicate the fact rows, inflating our aggregations (like total ratings). 
-- Bridge tables act as intermediaries, allowing BI tools to safely filter facts 
-- by authors or tags without compromising the integrity of the metrics.

-- 2.1 Books <-> Authors Bridge
create table bridge_book_authors (
    book_id integer,
    author_id integer,
    primary key (book_id, author_id),
    foreign key (book_id) references dim_books(book_id),
    foreign key (author_id) references dim_authors(author_id)
);

insert into bridge_book_authors
with exploded_books as (
    select book_id, trim(unnest(string_split(authors, ','))) as author_name
    from books_transformation where authors is not null
)
select distinct e.book_id, a.author_id
from exploded_books e
join dim_authors a on e.author_name = a.author_name;


-- 2.2 Books <-> Tags Bridge
create table bridge_book_tags (
    goodreads_book_id integer,
    tag_id integer,
    "count" integer,
    primary key (goodreads_book_id, tag_id),
    foreign key (goodreads_book_id) references dim_books(goodreads_book_id),
    foreign key (tag_id) references dim_tags(tag_id)
);

insert into bridge_book_tags
select goodreads_book_id, tag_id, "count"
from book_tags_transformation;


-- ------------------------------------------------------------------------------
-- 3. FACT TABLES (The Events and Measurements)
-- ------------------------------------------------------------------------------
-- ARCHITECTURAL NOTE: Why do we have two separate Fact Tables?
-- We separated the events into two distinct tables because they represent 
-- fundamentally different business processes with different behaviors:
--
-- 1. fact_ratings (Transaction Fact Table): This records a concrete, measurable 
--    event. It contains a numeric measure (the 'rating' value) that can be 
--    mathematically aggregated (averaged, summed, etc.).
--
-- 2. fact_to_read (Factless Fact Table): This records an intent or state 
--    (a user wants to read a book). It contains no numeric measures. The "fact" 
--    is simply the existence of the row itself. We analyze it by counting the rows.
--
-- Mixing these two completely different granularities into a single fact table 
-- would result in a heavily sparse table filled with NULLs and complex BI logic.

-- 3.1 Ratings Fact
create table fact_ratings (
    user_id integer,
    book_id integer,
    rating integer,
    foreign key (book_id) references dim_books(book_id)
);

insert into fact_ratings
select user_id, book_id, rating from ratings_transformation;


-- 3.2 To-Read Fact
create table fact_to_read (
    user_id integer,
    book_id integer,
    foreign key (book_id) references dim_books(book_id)
);

insert into fact_to_read
select user_id, book_id from to_read_transformation;