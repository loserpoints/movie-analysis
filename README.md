# Movies

Exploratory analysis of film data, mostly horror — director careers, franchise
trajectories, and how ratings distribute across genres and years.

Written in R in 2019–2020. This is finished work, kept for reference rather
than actively maintained.

## Data

Two public sources, downloaded the first time a script needs them:

- **IMDb datasets** (`datasets.imdbws.com`) — titles, ratings, crew, episodes
  and names, published by IMDb as gzipped TSVs and refreshed daily.
- **MovieLens** (GroupLens Research) — ratings, tags, links and the tag genome,
  from the `ml-25m` release.

`scripts/00_get_data.R` handles both. Every script sources it and calls
`connect_movies_db()`, which downloads whatever is missing into `data/`, loads
it into a [DuckDB](https://duckdb.org) database file at `data/movies.duckdb`,
and connects to it. DuckDB runs inside R, so there is no database server to
install and no password to set. The first run downloads about 1 GB of IMDb
files and takes several minutes; after that, scripts reuse the database file
and start straight away.

MovieLens (another 250 MB or so) is only fetched by the two scripts that use
it, `top_99_slashers.R` and `top_99_sports_movies.R`, which call
`connect_movies_db(movielens = TRUE)`.

To refresh the data, delete `data/` and run any script. It is gitignored.

A note on the table names, which follow IMDb's own file naming and are
confusing as a result: `imdb_titles` holds the **ratings** file
(`title.ratings.tsv`) — average rating and vote count. The actual title
metadata is in `imdb_basics`.

Until 2026 the data lived in a local MariaDB database, built by two scripts
that had to run in the same session. Those are in the git history.

## What's here

`scripts/03_horror_base.R` builds the data set the horror analyses share — the
horror movies with their ratings and directors, plus popularity and quality
scores derived from them. Each analysis script sources it, so it runs first
automatically.

The analyses live in `scripts/analysis/`:

| Script | Question it answers |
|---|---|
| `best_horror_directors.R` | Which horror directors have the strongest body of work? |
| `director_careers.R` | How does one director's rating trajectory look over a career? |
| `top_99_horror.R` | The best horror movies since 1960 |
| `top_99_slashers.R` | The same, narrowed to slashers via MovieLens tags |
| `best_horror_by_year.R` | The strongest horror movie of each year |
| `horror_ratings_scatter.R` | How a single year's horror releases spread across popularity and rating |
| `horror_franchises.R` | How franchises hold up across sequels |
| `top_99_sports_movies.R` | The same treatment applied to sports movies |
| `tv_series_ratings.R` | Episode ratings across the run of a series |

`horror_franchises.R`, `top_99_sports_movies.R` and `tv_series_ratings.R` run
their own queries and don't depend on the shared base.

`horror_franchises.R` can't run as things stand. It needs a franchise list
exported from an IMDb user list (`ls022487858`) that no longer exists, and no
copy was kept.

`scripts/exploration.R` is scratch work — earlier versions of several of these
analyses, kept for reference. It writes to `data/` rather than `viz/` so
running it can't overwrite the committed charts.

Charts are in `viz/`, named after the script that produces them. Every script
writes there; paths are relative to the repository root, so run R from there.
The committed charts were made from 2020 data. Running a script today
overwrites its chart with one built from current IMDb data, so rankings
shift: newer releases appear, and IMDb has since added Horror to the genres
of films like *Jaws* and *The Silence of the Lambs*.

From a terminal, run a script with `source()`:

```
Rscript -e 'source("scripts/analysis/top_99_horror.R")'
```

`Rscript scripts/analysis/top_99_horror.R` also works if Trebuchet MS is
installed. Without it, that form fails: it prints each plot to a PDF as well,
and the PDF device stops at the missing font, while `ggsave` falls back to a
default font.

## Running these

### Packages

```r
install.packages(c("tidyverse", "duckdb", "ggthemes", "ggrepel",
                   "scales", "extrafont", "rvest"))

# not on CRAN
remotes::install_github("johannesbjork/LaCroixColoR")
```

`rvest` is only needed for `exploration.R`, and `LaCroixColoR` only for
`tv_series_ratings.R`.

These were written against the package versions current in 2019–2020 and use
some idioms that have since been superseded — `summarize_all`, `top_n`,
`..count..`. They still run, and have been deliberately left as written.

### Fonts

The charts use Trebuchet MS via `extrafont`. Font registration is guarded so
the scripts don't error on macOS or Linux, but the font itself needs to be
installed for the charts to render as they were designed — otherwise the
saved charts fall back to a default font.

## License

No license specified — personal analysis work, shared for reference.
