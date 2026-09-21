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
    value = imdb_data[[1]],
    row.names = FALSE,
    name = "imdb_titles",
    overwrite = TRUE
  )
  
  ## update basics table
  
  dbWriteTable(
    movies_db,
    value = imdb_data[[2]],
    row.names = FALSE,
    name = "imdb_basics",
    overwrite = TRUE
  )
  
  ## update crew table
  
  dbWriteTable(
    movies_db,
    value = imdb_data[[3]],
    row.names = FALSE,
    name = "imdb_crew",
    overwrite = TRUE
  )
  
  ## update names table
  
  names_sql <- imdb_data[[4]] %>%
    
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
    value = imdb_data[[5]],
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
    value = ml_data[[1]],
    row.names = FALSE,
    name = "movie_lens_titles",
    overwrite = TRUE
  )
  
  ## update tags table
  
  dbWriteTable(
    movies_db,
    value = ml_data[[2]],
    row.names = FALSE,
    name = "movie_lens_tags",
    overwrite = TRUE
  )
  
  ## update ratings table
  
  dbWriteTable(
    movies_db,
    value = ml_data[[3]],
    row.names = FALSE,
    name = "movie_lens_ratings",
    overwrite = TRUE
  )
  
  ## update links table
  
  dbWriteTable(
    movies_db,
    value = ml_data[[4]],
    row.names = FALSE,
    name = "movie_lens_links",
    overwrite = TRUE
  )
  
  ## update genome tags table
  
  dbWriteTable(
    movies_db,
    value = ml_data[[5]],
    row.names = FALSE,
    name = "movie_lens_genome_tags",
    overwrite = TRUE
  )
  
  ## update genome scores table
  
  dbWriteTable(
    movies_db,
    value = ml_data[[6]],
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

