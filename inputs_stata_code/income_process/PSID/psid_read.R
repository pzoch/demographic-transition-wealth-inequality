rm(list = ls())

# Optional helper for rebuilding psid.dta from PSID public-use files.
# The main replication pipeline starts from psid.dta. For journal replication,
# use the publication extract or the packaged psid.dta when available.

required_packages <- c("psidR", "data.table", "foreign")
missing_packages <- required_packages[
    !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
    stop(
        "Install required R packages before running this helper: ",
        paste(missing_packages, collapse = ", "),
        call. = FALSE
    )
}

library(psidR)
library(data.table)
library(foreign)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
    dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
} else {
    normalizePath(getwd(), winslash = "/")
}

psidr_root <- system.file(package = "psidR")

find_required_file <- function(env_name, candidates, description) {
    env_value <- Sys.getenv(env_name, unset = "")
    if (nzchar(env_value)) {
        candidates <- c(env_value, candidates)
    }

    candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
    found <- candidates[file.exists(candidates)]

    if (length(found) == 0) {
        stop(
            description,
            " not found. Looked in:\n  ",
            paste(candidates, collapse = "\n  "),
            "\n\nIf your installed psidR version does not include famvars_big.txt ",
            "(for example psidR 2.3), use the packaged psid.dta/publication ",
            "extract or supply the authors' variable-list file via ",
            env_name,
            ".",
            call. = FALSE
        )
    }

    found[1]
}

famvars_file <- find_required_file(
    "PSID_FAMVARS",
    c(
        file.path(script_dir, "famvars_big.txt"),
        file.path(psidr_root, "psid-lists", "famvars_big.txt")
    ),
    "Family variable list famvars_big.txt"
)

indvars_file <- find_required_file(
    "PSID_INDVARS",
    c(
        file.path(script_dir, "indvars.txt"),
        file.path(psidr_root, "psid-lists", "indvars.txt")
    ),
    "Individual variable list indvars.txt"
)

psid_datadir <- Sys.getenv("PSID_DATADIR", unset = "C:/psid_temp/psid_new")
psid_datadir <- normalizePath(psid_datadir, winslash = "/", mustWork = FALSE)

if (!dir.exists(psid_datadir)) {
    stop(
        "PSID_DATADIR does not exist: ",
        psid_datadir,
        "\nSet PSID_DATADIR to the folder containing the downloaded PSID files.",
        call. = FALSE
    )
}

output_dta <- Sys.getenv(
    "PSID_OUTPUT_DTA",
    unset = file.path(script_dir, "psid.dta")
)
output_rdata <- Sys.getenv(
    "PSID_OUTPUT_RDATA",
    unset = file.path(script_dir, "psid.RData")
)

message("Using psidR version: ", as.character(utils::packageVersion("psidR")))
message("Using PSID data directory: ", psid_datadir)
message("Using family variable list: ", famvars_file)
message("Using individual variable list: ", indvars_file)

famvars_long <- fread(famvars_file)
indvars_long <- fread(indvars_file)

setkey(indvars_long, "name")
setkey(famvars_long, "name")

famvars <- dcast(
    famvars_long[, list(year, name, variable)],
    year ~ name,
    value.var = "variable"
)

indvars <- dcast(
    indvars_long[, list(year, name, variable)],
    year ~ name,
    value.var = "variable"
)

psid_panel <- build.panel(
    datadir = psid_datadir,
    fam.vars = famvars,
    ind.vars = indvars,
    heads.only = TRUE,
    sample = "SRC",
    design = "all"
)

save(psid_panel, file = output_rdata)
write.dta(psid_panel, output_dta)

message("Wrote: ", normalizePath(output_rdata, winslash = "/", mustWork = FALSE))
message("Wrote: ", normalizePath(output_dta, winslash = "/", mustWork = FALSE))
