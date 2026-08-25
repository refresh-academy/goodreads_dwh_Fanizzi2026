-- ==============================================================================
-- GOODREADS DATA TRANSFORMATION
-- Purpose: Clean, standardize, and deduplicate raw data.
-- All transformations are idempotent: tables are dropped and recreated.
-- No UPDATE or INSERT statements are used — only CREATE TABLE AS SELECT.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. Clean environment
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS books_transformation     CASCADE;
DROP TABLE IF EXISTS book_tags_transformation CASCADE;
DROP TABLE IF EXISTS ratings_transformation   CASCADE;
DROP TABLE IF EXISTS tags_transformation      CASCADE;
DROP TABLE IF EXISTS to_read_transformation   CASCADE;

-- ------------------------------------------------------------------------------
-- 1. Books transformation
-- ------------------------------------------------------------------------------
create table books_transformation as
select
    book_id,
    goodreads_book_id,
    best_book_id,
    work_id,
    books_count,

    -- isbn10: cast to text, then trim, then handle empty/null
    coalesce(
        nullif(trim(cast(isbn as text)), ''),
        'unknown'
    ) as isbn,

    -- isbn13: handle scientific notation and empty/null
    case
        when cast(isbn13 as text) ~ 'e\+' then
            lpad(
                regexp_replace(
                    (cast(isbn13 as text)::numeric)::text,
                    '\.0$', ''
                ),
                13, '0'
            )
        when nullif(trim(cast(isbn13 as text)), '') is null then 'unknown'
        else cast(isbn13 as text)
    end as isbn13,

    authors,

    coalesce(original_publication_year, -1) as original_publication_year,
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
-- 2. Book‑tags transformation (deduplicate, keep highest count)
-- ------------------------------------------------------------------------------
create table book_tags_transformation as
with ranked as (
    select
        goodreads_book_id,
        tag_id,
        "count",
        row_number() over (
            partition by goodreads_book_id, tag_id
            order by "count" desc
        ) as rn
    from book_tags
)
select goodreads_book_id, tag_id, "count"
from ranked
where rn = 1;

-- ------------------------------------------------------------------------------
-- 3. Ratings transformation (deduplicate, keep highest rating)
-- ------------------------------------------------------------------------------
/*
   Assumption: when a user has rated the same book multiple times,
   we keep the highest rating. Without a timestamp, this is a
   reasonable default but introduces a slight upward bias.
   An alternative would be to keep the lowest or the first occurrence.
   In the original dataset there is no timestamp, so i choose the highest rating.
*/
create table ratings_transformation as
with ranked as (
    select
        user_id,
        book_id,
        rating,
        row_number() over (
            partition by user_id, book_id
            order by rating desc       -- highest rating kept
        ) as rn
    from ratings
)
select user_id, book_id, rating
from ranked
where rn = 1;

-- ------------------------------------------------------------------------------
-- 4. Tags transformation (straight copy, already clean)
-- ------------------------------------------------------------------------------
create table tags_transformation as
select * from tags;

-- ------------------------------------------------------------------------------
-- 5. To‑read transformation (deduplicate, for data quality)
-- ------------------------------------------------------------------------------
create table to_read_transformation as
with ranked as (
    select
        user_id,
        book_id,
        row_number() over (
            partition by user_id, book_id
            order by (select null)   -- order does not matter
        ) as rn
    from to_read
)
select user_id, book_id
from ranked
where rn = 1;