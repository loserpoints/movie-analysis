# Movies

Exploratory analysis of film data, mostly horror — director careers, franchise
trajectories, and how ratings distribute across genres and years.

Written in R in 2019–2020. This is finished work, kept for reference rather
than actively maintained.

## Data

Two public sources, loaded into a local MariaDB database:

- **IMDb datasets** (`datasets.imdbws.com`) — titles, ratings, crew, episodes
  and names, published by IMDb as gzipped TSVs.
- **MovieLens** (GroupLens Research) — ratings, tags, links and the tag genome.

Building the database is three steps. The numbered scripts run in order, in
the same session:

1. `scripts/01-download-source-data.R` — downloads the source files
2. `scripts/02-create-tables.R` — creates the empty tables
3. `scripts/03-load-tables.R` — writes the downloaded data into them

Step 3 reads objects left in the session by step 1, so they can't be run
independently.

**These scripts were last run in 2020.** The IMDb dataset URLs are unchanged,
but MovieLens release names and file layouts have shifted since, so expect the
loading scripts to need adjustment before they run today.

## What's here

`scripts/04-horror-base.R` builds the data set the horror analyses share — the
horror movies with their ratings and directors, plus popularity and quality
scores derived from them. Each analysis script sources it, so it runs first
automatically.

The analyses live in `scripts/analysis/`:

| Script | Question it answers |
|---|---|
| `best-horror-directors.R` | Which horror directors have the strongest body of work? |
| `director-careers.R` | How does one director's rating trajectory look over a career? |
| `top-99-horror.R` | The best horror movies since 1960 |
| `top-99-slashers.R` | The same, narrowed to slashers via MovieLens tags |
| `best-horror-by-year.R` | The strongest horror movie of each year |
| `horror-ratings-scatter.R` | How a single year's horror releases spread across popularity and rating |
| `horror-franchises.R` | How franchises hold up across sequels |
| `top-99-sports-movies.R` | The same treatment applied to sports movies |
| `tv-series-ratings.R` | Episode ratings across the run of a series |

`horror-franchises.R`, `top-99-sports-movies.R` and `tv-series-ratings.R` run
their own queries and don't depend on the shared base.

`scripts/exploration.R` is scratch work — earlier versions of several of these
analyses, kept for reference. It writes to `data/` rather than `viz/` so
running it can't overwrite the committed charts.

Charts are in `viz/`. Every script writes there; paths are relative to the
repository root, so run R from there.

## Running these

The database scripts read the password from an environment variable rather
than hardcoding it. Set it in `~/.Renviron`:

```
MOVIES_DB_PASSWORD=your_password_here
```

Then restart R. The scripts expect a local MariaDB instance with a `movies`
database.

## License

No license specified — personal analysis work, shared for reference.
