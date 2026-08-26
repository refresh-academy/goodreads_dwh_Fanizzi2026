-- ==============================================================================
-- ADVANCED EDA (DuckDB) - Deep Dive into 5 CSVs
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BOOKS: Distribution & Percentiles
-- ------------------------------------------------------------------------------
-- Analyzing the true distribution of ratings using percentiles (Quartiles)
select 
    round(quantile_cont(average_rating, 0.25), 2) as p25_rating,
    round(quantile_cont(average_rating, 0.50), 2) as median_rating,
    round(quantile_cont(average_rating, 0.75), 2) as p75_rating,
    round(quantile_cont(average_rating, 0.99), 2) as p99_rating
from books;



-- Finding extreme anomalies in publication years (e.g., negative years or future)
select original_publication_year, count(*) as book_count, title
from books 
where original_publication_year < 1500 or original_publication_year > 2026
group by 1, 3 order by 1;

-- ------------------------------------------------------------------------------
-- 2. RATINGS: Bot Detection & Variance
-- ------------------------------------------------------------------------------
-- Finding highly suspicious users (e.g., users who rated > 50 books with ONLY 5 stars)
select user_id, count(*) as total_ratings, avg(rating) as mean_rating
from ratings 
group by user_id 
having count(*) >= 50 and avg(rating) >= 4.9
order by total_ratings desc limit 10;

-- ------------------------------------------------------------------------------
-- 3. TAGS: Quality and Noise detection
-- ------------------------------------------------------------------------------
-- Finding "noisy" tags containing numbers or strange characters using Regex
select tag_name, count(*) as occurrences
from tags
where regexp_matches(tag_name, '[0-9]') or regexp_matches(tag_name, '[^a-za-z0-9\-\_ ]')
group by 1 order by 2 desc limit 15;

-- ------------------------------------------------------------------------------
-- 4. BOOK_TAGS: Tag Density 
-- ------------------------------------------------------------------------------
-- How many tags are applied to a book on average? Are there books with zero tags?
with tag_counts as (
    select goodreads_book_id, sum("count") as total_applications, count(tag_id) as unique_tags
    from book_tags group by 1
)
select 
    min(unique_tags) as min_unique_tags,
    max(unique_tags) as max_unique_tags,
    round(avg(unique_tags), 0) as avg_unique_tags,
    round(quantile_cont(total_applications, 0.50), 0) as median_total_applications
from tag_counts;

-- ------------------------------------------------------------------------------
-- 5. TO_READ: User Backlog Analysis
-- ------------------------------------------------------------------------------
-- Analyzing the size of user backlogs (how many books people want to read)
with backlog_size as (
    select user_id, count(*) as books_in_backlog
    from to_read group by 1
)
select 
    max(books_in_backlog) as max_backlog,
    round(quantile_cont(books_in_backlog, 0.50), 0) as median_backlog,
    round(quantile_cont(books_in_backlog, 0.90), 0) as p90_backlog
from backlog_size;