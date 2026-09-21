### load dependencies

library(tidyverse)
library(RMariaDB)


### define function to create imdb tables

create_imdb_tables <- function(x) {


## connect to movies db 
  
  movies_db <-
    dbConnect(
      MariaDB(),
      user = "root",
      password = Sys.getenv("MOVIES_DB_PASSWORD"),
      dbname = "movies",
      host = "localhost"
    )
  
  
  ## create titles table
  
  create_table_imdb_titles <- "CREATE TABLE imdb_titles (
  tconst TEXT,
  averageRating DECIMAL(2, 1),
  numVotes BIGINT);"
  
  results <- dbSendQuery(movies_db, create_table_imdb_titles)
  
  dbClearResult(results)
  
  
  ## create basics table
  
  create_table_imdb_basics <- "CREATE TABLE imdb_basics (
  tconst TEXT,
  titleType TEXT,
  primaryTitle TEXT,
  originalTitle TEXT,
  isAdult TEXT,
  startYear TEXT,
  endYear TEXT,
  runtimeMinutes TEXT,
  genres LONGTEXT);"
  
  results <- dbSendQuery(movies_db, create_table_imdb_basics)
  
  dbClearResult(results)
  
  
  ## create crew table
  
  create_table_imdb_crew <- "CREATE TABLE imdb_crew (
  tconst TEXT,
  directors TEXT,
  writers TEXT);"
  
  results <- dbSendQuery(movies_db, create_table_imdb_crew)
  
  dbClearResult(results)
  
  
  ## create names table
  
  create_table_imdb_names <- "CREATE TABLE imdb_names (
  nconst TEXT,
  primaryName TEXT,
  birthYear TEXT,
  deathYear TEXT,
  primaryProfession TEXT,
  knownForTitles TEXT);"
  
  results <- dbSendQuery(movies_db, create_table_imdb_names)
  
  dbClearResult(results)
  
  
  ## create tv episode table
  
  create_table_imdb_episodes <- "CREATE TABLE imdb_episodes (
  tconst TEXT,
  parentTconst TEXT,
  seasonNumber BIGINT,
  episodeNumber BIGINT);"
  
  results <- dbSendQuery(movies_db, create_table_imdb_episodes)
  
  dbClearResult(results)
  
  dbDisconnect(movies_db)
  
}



### define function to create movie lens tables

create_ml_tables <- function(x) {
  ## connect to movies db
  
  movies_db <-
    dbConnect(
      MariaDB(),
      user = "root",
      password = Sys.getenv("MOVIES_DB_PASSWORD"),
      dbname = "movies",
      host = "localhost"
    )
  
  
  ## create titles table
  
  create_table_ml_titles <- "CREATE TABLE movie_lens_titles (
  movieId BIGINT,
  title TEXT,
  genres TEXT);"
  
  results <- dbSendQuery(movies_db, create_table_ml_titles)
  
  dbClearResult(results)
  
  
  ## create ratings table
  
  create_table_ml_ratings <- "CREATE TABLE movie_lens_ratings (
  userId BIGINT,
  movieId BIGINT,
  rating DECIMAL(2, 1),
  timestamp BIGINT);"
  
  results <- dbSendQuery(movies_db, create_table_ml_ratings)
  
  dbClearResult(results)
  
  
  ## create tags table
  
  create_table_ml_tags <- "CREATE TABLE movie_lens_tags (
  userId BIGINT,
  movieId BIGINT,
  tag TEXT,
  timestamp BIGINT,
  imdbId BIGINT,
  tmdbId BIGINT);"
  
  results <- dbSendQuery(movies_db, create_table_ml_tags)
  
  dbClearResult(results)
  
  
  ## create links table
  create_table_ml_links <- "CREATE TABLE movie_lens_links (
  movieId BIGINT,
  imdbId BIGINT,
  tmdbId BIGINT);"
  
  results <- dbSendQuery(movies_db, create_table_ml_links)
  
  dbClearResult(results)
  
  
  ## create genome tags table
  create_table_ml_genome_tags <- "CREATE TABLE movie_lens_genome_tags (
  tagId BIGINT,
  tag TEXT);"
  
  results <- dbSendQuery(movies_db, create_table_ml_genome_tags)
  
  dbClearResult(results)
  
  
  ## create genome scores table
  create_table_ml_genome_scores <- "CREATE TABLE movie_lens_genome_scores (
  movieId BIGINT,
  tagId BIGINT,
  relevance DECIMAL(10, 9));"
  
  results <- dbSendQuery(movies_db, create_table_ml_genome_scores)
  
  dbClearResult(results)
  
  dbDisconnect(movies_db)
  
}


### create imdb tables

create_imdb_tables()


### create movie lens tables

create_ml_tables()

