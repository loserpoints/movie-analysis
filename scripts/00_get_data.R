### gets the movies database ready and connects to it
###
### every script sources this file and calls connect_movies_db() instead of
### connecting to a database server. the first time it runs, it downloads the
### imdb source files into data/imdb and loads them into a duckdb database
### file, data/movies.duckdb. after that it reuses the file, so later runs
### start straight away.
###
### the movielens tables are only built when a script asks for them, with
### connect_movies_db(movielens = TRUE), so the imdb-only scripts never
### need movielens. they come from a clone of the private data repo if there
### is one, and from grouplens if not.
###
### to refresh the data, delete the data folder and run any script.


### load required packages

library(DBI)
library(duckdb)


### downloads are large (title.basics and name.basics are a few hundred MB
### each), so allow well past R's default 60 second timeout

options(timeout = max(3600, getOption("timeout")))


### define the imdb tables
###
### imdb publishes tab-separated files with no quoting and \N for missing
### values. everything is read as text and cast afterwards, so a stray value
### can't stop the load - try_cast turns it into NA instead.

imdb_tables <- list(

  imdb_titles = list(
    file = "title.ratings.tsv.gz",
    columns = "tconst, try_cast(averageRating AS DOUBLE) AS averageRating,
               try_cast(numVotes AS INTEGER) AS numVotes"
  ),

  imdb_basics = list(
    file = "title.basics.tsv.gz",
    columns = "tconst, titleType, primaryTitle, originalTitle,
               try_cast(isAdult AS INTEGER) AS isAdult,
               try_cast(startYear AS INTEGER) AS startYear,
               try_cast(endYear AS INTEGER) AS endYear,
               try_cast(runtimeMinutes AS INTEGER) AS runtimeMinutes,
               genres"
  ),

  imdb_crew = list(
    file = "title.crew.tsv.gz",
    columns = "tconst, directors, writers"
  ),

  imdb_names = list(
    file = "name.basics.tsv.gz",
    columns = "nconst, primaryName,
               try_cast(birthYear AS INTEGER) AS birthYear,
               try_cast(deathYear AS INTEGER) AS deathYear,
               primaryProfession, knownForTitles"
  ),

  imdb_episodes = list(
    file = "title.episode.tsv.gz",
    columns = "tconst, parentTconst,
               try_cast(seasonNumber AS INTEGER) AS seasonNumber,
               try_cast(episodeNumber AS INTEGER) AS episodeNumber"
  )

)


### define where the movielens files come from
###
### if loserpoints/private-data is cloned next to this repo, its copy of
### movielens is used: the same files, converted to parquet. set
### MOVIELENS_DIR to point somewhere else. otherwise the files are downloaded
### from grouplens into data/movielens.

movielens_private_dir <- Sys.getenv("MOVIELENS_DIR", "../private-data/movielens/ml-25m")

movielens_source <- function(file) {
  
  if (file.exists(file.path(movielens_private_dir, "movies.parquet"))) {
    
    return(paste0("read_parquet('", file.path(movielens_private_dir, paste0(file, ".parquet")), "')"))
    
  }
  
  ## links.csv writes imdb ids with leading zeros (0114709), which would
  ## otherwise be read as text. the analysis scripts join on them as numbers.
  
  options <- if (file == "links") ", types = {'imdbId': 'INTEGER', 'tmdbId': 'INTEGER'}" else ""
  
  paste0("read_csv('data/movielens/ml-25m/", file, ".csv'", options, ")")
  
}


### define the movielens tables
###
### movie_lens_tags gets imdbId and tmdbId joined on from links, because
### the analysis scripts look tags up by imdb id. the ratings file isn't
### loaded, since no script uses it.

movielens_tables <- list(
  
  movie_lens_titles = function() paste("SELECT * FROM", movielens_source("movies")),
  
  movie_lens_links = function() paste("SELECT * FROM", movielens_source("links")),
  
  movie_lens_tags = function() paste("SELECT tags.*, links.imdbId, links.tmdbId FROM",
                                     movielens_source("tags"), "AS tags LEFT JOIN",
                                     movielens_source("links"), "AS links USING (movieId)"),
  
  movie_lens_genome_tags = function() paste("SELECT * FROM", movielens_source("genome-tags")),
  
  movie_lens_genome_scores = function() paste("SELECT * FROM", movielens_source("genome-scores"))
  
)


### define function to download the imdb files and load any missing tables

load_imdb <- function(movies_db) {

  dir.create("data/imdb", recursive = TRUE, showWarnings = FALSE)

  for (table in names(imdb_tables)) {

    if (dbExistsTable(movies_db, table)) next

    file <- imdb_tables[[table]]$file

    path <- file.path("data/imdb", file)

    if (!file.exists(path)) {

      message("downloading ", file)

      ## download under a temporary name, so a broken download isn't
      ## mistaken for a finished one next time
      
      download.file(paste0("https://datasets.imdbws.com/", file), destfile = paste0(path, ".part"), mode = "wb")
      
      file.rename(paste0(path, ".part"), path)

    }

    message("loading ", table)

    dbExecute(movies_db, paste0(
      "CREATE TABLE ", table, " AS SELECT ", imdb_tables[[table]]$columns,
      " FROM read_csv('", path, "', delim = '\t', header = true, quote = '',
      escape = '', nullstr = '\\N', all_varchar = true)"
    ))

  }

}


### define function to get movielens and load any missing tables

load_movielens <- function(movies_db) {
  
  missing <- setdiff(names(movielens_tables), dbListTables(movies_db))
  
  if (length(missing) == 0) return(invisible())
  
  if (file.exists(file.path(movielens_private_dir, "movies.parquet"))) {
    
    message("using movielens from ", movielens_private_dir)
    
  } else if (!file.exists("data/movielens/ml-25m/movies.csv")) {
    
    message("downloading movielens ml-25m")
    
    dir.create("data/movielens", recursive = TRUE, showWarnings = FALSE)
    
    download.file("https://files.grouplens.org/datasets/movielens/ml-25m.zip",
                  destfile = "data/movielens/ml-25m.zip", mode = "wb")
    
    unzip("data/movielens/ml-25m.zip", exdir = "data/movielens")
    
  }
  
  for (table in missing) {
    
    message("loading ", table)
    
    dbExecute(movies_db, paste0("CREATE TABLE ", table, " AS ", movielens_tables[[table]]()))
    
  }
  
}


### define function to connect, building whatever is missing first
###
### disconnect with dbDisconnect(movies_db, shutdown = TRUE) when done

connect_movies_db <- function(movielens = FALSE) {

  dir.create("data", showWarnings = FALSE)

  movies_db <- dbConnect(duckdb(shared_home = FALSE), dbdir = "data/movies.duckdb")

  load_imdb(movies_db)

  if (movielens) load_movielens(movies_db)

  movies_db

}
