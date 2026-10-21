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
### download movielens.
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


### define the movielens tables
###
### movie_lens_tags gets imdbId and tmdbId joined on from links.csv, because
### the analysis scripts look tags up by imdb id

movielens_tables <- list(

  movie_lens_titles = "SELECT * FROM read_csv('data/movielens/ml-25m/movies.csv')",

  movie_lens_links = "SELECT * FROM read_csv('data/movielens/ml-25m/links.csv')",

  movie_lens_tags = "SELECT tags.*, links.imdbId, links.tmdbId
                     FROM read_csv('data/movielens/ml-25m/tags.csv') AS tags
                     LEFT JOIN read_csv('data/movielens/ml-25m/links.csv') AS links
                     USING (movieId)",

  movie_lens_ratings = "SELECT * FROM read_csv('data/movielens/ml-25m/ratings.csv')",

  movie_lens_genome_tags = "SELECT * FROM read_csv('data/movielens/ml-25m/genome-tags.csv')",

  movie_lens_genome_scores = "SELECT * FROM read_csv('data/movielens/ml-25m/genome-scores.csv')"

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


### define function to download movielens and load any missing tables

load_movielens <- function(movies_db) {

  missing <- setdiff(names(movielens_tables), dbListTables(movies_db))

  if (length(missing) == 0) return(invisible())

  dir.create("data/movielens", recursive = TRUE, showWarnings = FALSE)

  if (!file.exists("data/movielens/ml-25m/movies.csv")) {

    message("downloading movielens ml-25m")

    download.file("https://files.grouplens.org/datasets/movielens/ml-25m.zip",
                  destfile = "data/movielens/ml-25m.zip", mode = "wb")

    unzip("data/movielens/ml-25m.zip", exdir = "data/movielens")

  }

  for (table in missing) {

    message("loading ", table)

    dbExecute(movies_db, paste0("CREATE TABLE ", table, " AS ", movielens_tables[[table]]))

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
