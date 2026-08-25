-- ==============================================================================
-- GOODREADS DATA EXPLORATION
-- Purpose: Assess data quality, structure, and uncover patterns.
-- This script performs only read operations (SELECT). No data modifications.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. book_tags query exploration
-- ------------------------------------------------------------------------------
select count(*) as total_rows from book_tags;

-- null checks
select
    count(*) filter (where goodreads_book_id is null) as null_book_id,
    count(*) filter (where tag_id is null)            as null_tag_id,
    count(*) filter (where "count" is null)           as null_count
from book_tags;

-- duplicates (same book, same tag)
select goodreads_book_id, tag_id, count(*) as occurrences
from book_tags
group by goodreads_book_id, tag_id
having count(*) > 1
order by occurrences desc;

-- --- Deeper Analysis ---
-- Top 20 most applied tags (overall)
select tag_id, sum("count") as total_uses
from book_tags
group by tag_id
order by total_uses desc
limit 20;

-- Books with the highest number of distinct tags
select goodreads_book_id, count(distinct tag_id) as distinct_tags
from book_tags
group by goodreads_book_id
order by distinct_tags desc
limit 10;

-- Distribution of the "count" field (how many times a tag is applied to a book)
select
    case
        when "count" = 1 then '1'
        when "count" between 2 and 5 then '2-5'
        when "count" between 6 and 20 then '6-20'
        else '20+'
    end as count_range,
    count(*) as num_tag_assignments
from book_tags
group by 1
order by 1;

-- ------------------------------------------------------------------------------
-- 2. books
-- ------------------------------------------------------------------------------
select count(*) as total_rows from books;

-- NULL and empty checks

select
    count(*) filter (where book_id is null)                     as null_book_id,
    count(*) filter (where isbn is null)                        as null_isbn,
    count(*) filter (where trim(cast(isbn as text)) = '')       as empty_isbn,
    count(*) filter (where isbn13 is null)                      as null_isbn13,
    count(*) filter (where trim(cast(isbn13 as text)) = '')     as empty_isbn13,
    count(*) filter (where original_publication_year is null)   as null_pub_year,
    count(*) filter (where original_title is null)              as null_original_title,
    count(*) filter (where trim(original_title) = '')           as empty_original_title,
    count(*) filter (where language_code is null)               as null_language,
    count(*) filter (where trim(language_code) = '')            as empty_language
from books;

-- ISBN anomalies
select count(*) as isbn_with_x from books where isbn like '%x';

select count(*) as scientific_notation_isbn13
from books
where isbn13::text like '%e+%';

-- Books missing both identifiers

select count(*) as missing_both_isbn
from books
where (trim(cast(isbn as text)) = '' or isbn is null)
  and (trim(cast(isbn13 as text)) = '' or isbn13 is null);

-- Language distribution
select language_code, count(*) as num_books
from books
group by language_code
order by num_books desc;

--  Deeper Analysis
-- Publication year distribution by decade

select
    case
        when original_publication_year < 0 then 'missing'
        when original_publication_year < 1900 then 'before 1900'
        else ((original_publication_year / 10) * 10)::text || 's' -- 's' very useful for finding the correct amount of books
    end as decade,
    count(*) as num_books
from books
group by decade
order by decade;

-- Top 10 most rated books (by ratings_count)
select book_id, title, ratings_count, average_rating
from books
order by ratings_count desc
limit 10;

-- Highly rated books with at least 1000 ratings (credibility threshold)
select book_id, title, average_rating, ratings_count
from books
where average_rating > 4.5 and ratings_count >= 1000
order by average_rating desc, ratings_count desc
limit 10;

-- Relationship between number of ratings and average rating (binned)
select
    case
        when ratings_count < 10 then '1-9'
        when ratings_count < 100 then '10-99'
        when ratings_count < 1000 then '100-999'
        when ratings_count < 10000 then '1000-9999'
        else '10000+'
    end as rating_bin,
    count(*) as num_books,
    round(avg(average_rating)::numeric, 2) as avg_of_avg_rating
from books
group by rating_bin
order by min(ratings_count);

-- Books with missing language but English-sounding title (heuristic)
select book_id, title, language_code
from books
where (language_code is null or trim(language_code) = '')
  and title ~ '^[a-za-z0-9 ,.!?;:\''"()-]+$'
limit 10;

-- Authors with most books (handling comma-separated list)
select
    trim(author) as author_name,
    count(*) as book_count
from books,
lateral unnest(string_to_array(authors, ',')) as author
where authors is not null
group by author_name
order by book_count desc
limit 10;

-- ------------------------------------------------------------------------------
-- 3. ratings
-- ------------------------------------------------------------------------------
select count(*) as total_rows from ratings;

-- NULL checks
select
    count(*) filter (where user_id is null) as null_user_id,
    count(*) filter (where book_id is null) as null_book_id,
    count(*) filter (where rating is null)  as null_rating
from ratings;

-- Rating distribution
select rating, count(*) as num_ratings
from ratings
group by rating
order by rating;

-- Duplicate ratings
select user_id, book_id, count(*) as occurrences
from ratings
group by user_id, book_id
having count(*) > 1
order by occurrences desc;

-- --- Deeper Analysis ---
-- User activity: number of ratings per user (top 10)
select user_id, count(*) as ratings_given
from ratings
group by user_id
order by ratings_given desc
limit 10;

-- Book popularity by number of ratings (top 10)
select book_id, count(*) as num_ratings, round(avg(rating)::numeric, 2) as avg_rating
from ratings
group by book_id
order by num_ratings desc
limit 10;

-- Books with the most polarized opinions (high variance, minimum 50 ratings)
select book_id, count(*) as num_ratings,
       round(avg(rating)::numeric, 2) as avg_rating,
       round(stddev(rating)::numeric, 2) as rating_stddev
from ratings
group by book_id
having count(*) >= 50
order by rating_stddev desc
limit 10;

-- Overall average rating (global bias)
select round(avg(rating)::numeric, 2) as global_avg_rating from ratings;

-- ------------------------------------------------------------------------------
-- 4. tags
-- ------------------------------------------------------------------------------
select count(*) as total_rows from tags;

-- NULL and empty checks
select
    count(*) filter (where tag_id is null)          as null_tag_id,
    count(*) filter (where tag_name is null)        as null_tag_name,
    count(*) filter (where trim(tag_name) = '')     as empty_tag_name
from tags;

-- Duplicate tag IDs
select tag_id, count(*) as occurrences
from tags
group by tag_id
having count(*) > 1;

-- Potential duplicate names (case-insensitive)
select lower(trim(tag_name)) as normalised_name, count(*) as occurrences
from tags
group by lower(trim(tag_name))
having count(*) > 1;

-- --- Deeper Analysis ---
-- Most common tag names
select tag_name, count(*) as num_tags
from tags
group by tag_name
order by num_tags desc
limit 20;

-- Tag length distribution (name length)
select
    case
        when length(tag_name) < 5 then 'short (<5)'
        when length(tag_name) between 5 and 10 then 'medium (5-10)'
        else 'long (>10)'
    end as length_range,
    count(*) as num_tags
from tags
group by length_range;

-- ------------------------------------------------------------------------------
-- 5. to_read
-- ------------------------------------------------------------------------------
select count(*) as total_rows from to_read;

-- NULL checks
select
    count(*) filter (where user_id is null) as null_user_id,
    count(*) filter (where book_id is null) as null_book_id
from to_read;

-- Duplicates
select user_id, book_id, count(*) as occurrences
from to_read
group by user_id, book_id
having count(*) > 1
order by occurrences desc;

-- --- Deeper Analysis ---
-- Users with the largest to-read lists (top 10)
select user_id, count(*) as to_read_count
from to_read
group by user_id
order by to_read_count desc
limit 10;

-- Books most often marked as to-read (top 10)
select book_id, count(*) as times_wanted
from to_read
group by book_id
order by times_wanted desc
limit 10;

-- ------------------------------------------------------------------------------
-- 6. Cross-table analysis
-- ------------------------------------------------------------------------------
-- Books present in to_read but never rated (unread gems?), in this query there aren't results.
select tr.book_id, b.title
from to_read tr
left join ratings r on tr.book_id = r.book_id
inner join books b on tr.book_id = b.book_id
where r.book_id is null
group by tr.book_id, b.title
limit 10;

-- Books with many tags but low average rating (misleading tags?)
select b.book_id, b.title, b.average_rating, count(bt.tag_id) as tag_count
from books b
inner join book_tags bt on b.goodreads_book_id = bt.goodreads_book_id
group by b.book_id, b.title, b.average_rating
having count(bt.tag_id) > 20 and b.average_rating < 3.5
order by tag_count desc
limit 10;

-- Overlap: books that are both highly rated and often marked to-read
select b.book_id, b.title, b.average_rating, b.ratings_count, tr.wanted
from books b
inner join (
    select book_id, count(*) as wanted
    from to_read
    group by book_id
) tr on b.book_id = tr.book_id
where b.average_rating > 4.0 and b.ratings_count > 100
order by tr.wanted desc
limit 10;