### step 2 of 2 in building the movies database
###
### writes the data downloaded in step 1 into mysql, then indexes the columns
### the analysis scripts join on. dbWriteTable(overwrite = TRUE) creates each
### table from the data frame, so no separate CREATE TABLE step is needed.
###
### expects imdb_data and ml_data to already exist in the session - run
### "01_download_source_data.R" first or this will fail.

### load required packages

library(RMariaDB)
library(tidyverse)


### define function to update the imdb tables in mysql

update_imdb <- function(x) {
  
  ## connect to movies database
  
  movies_db <-
    dbConnect(
      MariaDB(),
      user = "root",
      password = Sys.getenv("MOVIES_DB_PASSWORD"),
      dbname = "movies",
      host = "localhost"
    )
  
  
  ## update titles table
  
  dbWriteTable(
    movies_db,
    value = imdb_data$titles,
    row.names = FALSE,
    name = "imdb_titles",
    overwrite = TRUE
  )
  
  ## update basics table
  
  dbWriteTable(
    movies_db,
    value = imdb_data$basics,
    row.names = FALSE,
    name = "imdb_basics",
    overwrite = TRUE
  )
  
  ## update crew table
  
  dbWriteTable(
    movies_db,
    value = imdb_data$crew,
    row.names = FALSE,
    name = "imdb_crew",
    overwrite = TRUE
  )
  
  ## update names table
  
  names_sql <- imdb_data$names %>%
    
    mutate(nchar = nchar(primaryName)) %>%
    
    filter(nchar != max(nchar)) %>%
    
    select(-nchar)
  
  dbWriteTable(
    movies_db,
    value = names_sql,
    row.names = FALSE,
    name = "imdb_names",
    overwrite = TRUE
  )
  
  
  ## update tv episodes table
  
  dbWriteTable(
    movies_db,
    value = imdb_data$episodes,
    row.names = FALSE,
    name = "imdb_episodes",
    overwrite = TRUE
  )
  
  dbDisconnect(movies_db)
  
}
  

### define function to update movie lens data in mysql

update_ml <- function(x) {
  
  ## connect to movies database
  
  movies_db <-
    dbConnect(
      MariaDB(),
      user = "root",
      password = Sys.getenv("MOVIES_DB_PASSWORD"),
      dbname = "movies",
      host = "localhost"
    )
  
  
  ## update titles table
  
  dbWriteTable(
    movies_db,
    value = ml_data$movies,
    row.names = FALSE,
    name = "movie_lens_titles",
    overwrite = TRUE
  )
  
  ## update tags table
  ##
  ## movielens tags.csv carries only movieId, but the analysis scripts query
  ## this table by imdbId, so the ids are joined on from links.csv first
  
  tags_sql <- ml_data$tags %>%
    
    left_join(ml_data$links, by = "movieId")
  
  
  dbWriteTable(
    movies_db,
    value = tags_sql,
    row.names = FALSE,
    name = "movie_lens_tags",
    overwrite = TRUE
  )
  
  ## update ratings table
  
  dbWriteTable(
    movies_db,
    value = ml_data$ratings,
    row.names = FALSE,
    name = "movie_lens_ratings",
    overwrite = TRUE
  )
  
  ## update links table
  
  dbWriteTable(
    movies_db,
    value = ml_data$links,
    row.names = FALSE,
    name = "movie_lens_links",
    overwrite = TRUE
  )
  
  ## update genome tags table
  
  dbWriteTable(
    movies_db,
    value = ml_data$genome_tags,
    row.names = FALSE,
    name = "movie_lens_genome_tags",
    overwrite = TRUE
  )
  
  ## update genome scores table
  
  dbWriteTable(
    movies_db,
    value = ml_data$genome_scores,
    row.names = FALSE,
    name = "movie_lens_genome_scores",
    overwrite = TRUE
  )
  
  dbDisconnect(movies_db)
  
}


### define function to index the columns the analysis scripts join on

add_indexes <- function(x) {
  
  ## connect to movies database
  
  movies_db <-
    dbConnect(
      MariaDB(),
      user = "root",
      password = Sys.getenv("MOVIES_DB_PASSWORD"),
      dbname = "movies",
      host = "localhost"
    )
  
  
  ## text columns need a prefix length, integer columns do not
  
  index_statements <- c(
    "CREATE INDEX idx_imdb_titles_tconst ON imdb_titles (tconst(12))",
    "CREATE INDEX idx_imdb_basics_tconst ON imdb_basics (tconst(12))",
    "CREATE INDEX idx_imdb_crew_tconst ON imdb_crew (tconst(12))",
    "CREATE INDEX idx_imdb_names_nconst ON imdb_names (nconst(12))",
    "CREATE INDEX idx_imdb_episodes_parent ON imdb_episodes (parentTconst(12))",
    "CREATE INDEX idx_ml_links_movie ON movie_lens_links (movieId)",
    "CREATE INDEX idx_ml_links_imdb ON movie_lens_links (imdbId)",
    "CREATE INDEX idx_ml_tags_movie ON movie_lens_tags (movieId)",
    "CREATE INDEX idx_ml_tags_imdb ON movie_lens_tags (imdbId)",
    "CREATE INDEX idx_ml_ratings_movie ON movie_lens_ratings (movieId)",
    "CREATE INDEX idx_ml_genome_scores_movie ON movie_lens_genome_scores (movieId)",
    "CREATE INDEX idx_ml_genome_scores_tag ON movie_lens_genome_scores (tagId)",
    "CREATE INDEX idx_ml_genome_tags_tag ON movie_lens_genome_tags (tagId)"
  )
  
  
  ## every load drops and recreates the tables, so the indexes go with them
  ## and are created fresh rather than updated
  
  for (statement in index_statements) {
    
    results <- dbSendQuery(movies_db, statement)
    
    dbClearResult(results)
    
  }
  
  dbDisconnect(movies_db)
  
}


### update imdb tables in mysql

update_imdb()


### update movie lens data in mysql

update_ml()


### index the join columns

add_indexes()
