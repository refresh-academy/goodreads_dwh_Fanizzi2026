-- Load the Goodbooks-10k CSV files from the project directory.
--
-- Relative paths make this script portable across operating systems.
-- Run DuckDB from the root directory of the project, where the CSV files
-- are located.

create table books as
select *
from read_csv_auto(
    './books.csv',
    header = true,
    ignore_errors = true
);

create table ratings as
select *
from read_csv_auto(
    './ratings.csv',
    header = true,
    ignore_errors = true
);

create table book_tags as
select *
from read_csv_auto(
    './book_tags.csv',
    header = true,
    ignore_errors = true
);

create table tags as
select *
from read_csv_auto(
    './tags.csv',
    header = true,
    ignore_errors = true
);

create table to_read as
select *
from read_csv_auto(
    './to_read.csv',
    header = true,
    ignore_errors = true
);