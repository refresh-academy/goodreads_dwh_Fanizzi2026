-- Use the paths copied using the Option key on macOS. The CSV file are imported locally in this process.
-- Load raw CSV files using relative paths so the project is fully portable on any machine
-- (Replaces the absolute local path /Users/Franco/... used during initial development)

CREATE TABLE books AS 
SELECT * FROM read_csv_auto('/Users/Franco/Desktop/syllabus/goodbooks-10k/books.csv', header=True, ignore_errors=True);

CREATE TABLE ratings AS 
SELECT * FROM read_csv_auto('/Users/Franco/Desktop/syllabus/goodbooks-10k/ratings.csv', header=True, ignore_errors=True);

CREATE TABLE book_tags AS 
SELECT * FROM read_csv_auto('/Users/Franco/Desktop/syllabus/goodbooks-10k/book_tags.csv', header=True, ignore_errors=True);

CREATE TABLE tags AS 
SELECT * FROM read_csv_auto('/Users/Franco/Desktop/syllabus/goodbooks-10k/tags.csv', header=True, ignore_errors=True);

CREATE TABLE to_read AS 
SELECT * FROM read_csv_auto('/Users/Franco/Desktop/syllabus/goodbooks-10k/to_read.csv', header=True, ignore_errors=True);