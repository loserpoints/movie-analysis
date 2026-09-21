### step 3 of 3 in building the movies database
###
### writes the data downloaded in step 1 into the tables created in step 2.
### expects imdb_data and ml_data to already exist in the session - run
### "Data gathering (public).R" first or this will fail.

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
  
  dbWriteTable(
    movies_db,
    value = ml_data$tags,
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


### update imdb tables in mysql

update_imdb()


### update movie lens data in mysql

update_ml()

