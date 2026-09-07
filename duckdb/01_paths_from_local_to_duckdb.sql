-- ==============================================================================
-- GOODBOOKS-10K CSV IMPORT
-- Engine: DuckDB
-- SQL client: DBeaver
-- ==============================================================================
--
-- PREREQUISITES
--
-- 1. Install and open DBeaver.
--
-- 2. Create a DuckDB connection in DBeaver:
--
--    a. Select:
--       Database > New Database Connection
--
--    b. Search for and select:
--       DuckDB
--
--    c. In the "Path" field, select or specify a persistent DuckDB database
--       file. For example:
--
--       macOS/Linux:
--       /path/to/project/goodbooks_dwh.duckdb
--
--       Windows:
--       C:/path/to/project/goodbooks_dwh.duckdb
--
--    d. Click "Test Connection".
--
--    e. If requested, allow DBeaver to download the DuckDB JDBC driver.
--
--    f. Click "Finish".
--
-- 3. In DBeaver's Database Navigator, right-click the DuckDB connection and
--    select:
--
--       SQL Editor > New SQL Script
--
-- 4. Verify that this SQL script is associated with the DuckDB connection
--    created above.
--
-- CSV PATH CONFIGURATION
--
-- Before running this script, replace <YOUR_LOCAL_PATH> in every
-- read_csv_auto() query with the absolute path of the local folder containing
-- the Goodbooks-10k CSV files.
--
-- The selected folder must contain:
--
--   - books.csv
--   - ratings.csv
--   - book_tags.csv
--   - tags.csv
--   - to_read.csv
--
-- Examples of the CSV folder path:
--
-- macOS:
--   /Users/your_username/Documents/goodbooks-10k
--
-- Windows:
--   C:/Users/your_username/Documents/goodbooks-10k
--
-- Linux:
--   /home/your_username/goodbooks-10k
--
-- Example of a complete path used in a query:
--
--   '/Users/your_username/Documents/goodbooks-10k/books.csv'
--
-- Replace only <YOUR_LOCAL_PATH>, keeping the slash and CSV filename unchanged.
--
-- IMPORTANT:
-- The DuckDB database path configured in DBeaver and the CSV folder path used
-- below are two different paths:
--
--   - DBeaver connection path: location of the .duckdb database file.
--   - read_csv_auto() path: location of the source CSV files.
--
-- After configuring the paths, execute the entire script in DBeaver.
-- ==============================================================================

create table books as
select *
from read_csv_auto(
    '<YOUR_LOCAL_PATH>/books.csv',
    header = true,
    ignore_errors = true
);

create table ratings as
select *
from read_csv_auto(
    '<YOUR_LOCAL_PATH>/ratings.csv',
    header = true,
    ignore_errors = true
);

create table book_tags as
select *
from read_csv_auto(
    '<YOUR_LOCAL_PATH>/book_tags.csv',
    header = true,
    ignore_errors = true
);

create table tags as
select *
from read_csv_auto(
    '<YOUR_LOCAL_PATH>/tags.csv',
    header = true,
    ignore_errors = true
);

create table to_read as
select *
from read_csv_auto(
    '<YOUR_LOCAL_PATH>/to_read.csv',
    header = true,
    ignore_errors = true
);