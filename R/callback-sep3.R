#' Sepsis 3 label
#'
#' The sepsis 3 label consists of a suspected infection combined with an acute
#' increase in SOFA score.
#'
#' @param ... Data objects
#' @param si_window Switch that can be used to filter SI windows
#' @param delta_fun Function used to determine the SOFA increase during an SI
#' window
#' @param sofa_thresh Required SOFA increase to trigger Sepsis 3
#' @param si_lwr,si_upr Lower/upper extent of SI windows
#' @param keep_components Logical flag indicating whether to return the
#' individual components alongside the aggregated score
#' @param interval Time series interval (only used for checking consistency
#' of input data)
#'
#' @details The Sepsis-3 Consensus (Singer et. al.) defines sepsis as an acute
#' increase in the SOFA score (see [sofa_score()]) of 2 points or more within
#' the suspected infection (SI) window (see [susp_inf()]):
#'
#' ```{tikz}
#' #| sofa-sep-3,
#' #| echo = FALSE,
#' #| engine.opts = list(
#' #|   extra.preamble = c(
#' #|     "\\usepackage{pgfplots}", "\\pgfplotsset{compat=newest}"
#' #|   )
#' #| )
#'
#' \begin{tikzpicture}
#'
#'   \draw (-5.5, 0) -- (3.5, 0);
#'   \draw (-5.5, -0.2) -- (-5.5, 0.2);
#'   \draw (3.5, -0.2) -- (3.5, 0.2);
#'   \draw (0.5, -0.2) -- (0.5, 0.2);
#'
#'   \node[align = center] at (0.5, 0.5) {SI time};
#'   \node[align = center] at (3.5, 0.5) {SI window end};
#'   \node[align = center] at (-5.5, -0.5) {SI window start};
#'
#'   \draw (-1.5, -0.2) -- (-1.5, 0.2);
#'   \draw[dashed] (-1.5, 2) -- (-1.5, 0);
#'   \node[align = center] at (-1.5, -0.5) {Sepsis-3 time};
#'
#'   \node[align = center] at (-2.75, 0.5) {-48 hours};
#'   \node[align = center] at (2, -0.5) {24 hours};
#'
#'   \draw[dashed] (0.5, 0) -- (0.5, -1);
#'
#'   \draw (0.5, -1) -- (3.5, -1);
#'   \draw (3.5, -1.2) -- (3.5, -0.8);
#'   \draw (0.5, -1.2) -- (0.5, -0.8);
#'
#'   \node at (5.25, -1) {within 24 hours};
#'
#'   \node[align = center] at (0.5, -1.5) {ABX};
#'   \node[align = center] at (3.5, -1.5) {Sampling};
#'
#'   \draw (0.5, -2) -- (9.5, -2);
#'   \draw (9.5, -2.2) -- (9.5, -1.8);
#'   \draw (0.5, -2.2) -- (0.5, -1.8);
#'
#'   \node[align = center] at (5.25, -2.5) {within 72 hours};
#'
#'   \node[align = center] at (0.5, -2.5) {Sampling};
#'   \node[align = center] at (9.5, -2.5) {ABX};
#'
#'   \draw [decorate, decoration = {brace, mirror, amplitude=5pt, raise=4pt},
#'          yshift=0pt] (0, -0.9) -- (0, -2.1);
#'   \node at (-3, -1.5) {Either option is permissible};
#'
#'   \filldraw  (-6, 1.5) circle (1pt);
#'   \draw (-6, 1.5) -- (-5.5, 1.5);
#'   \filldraw (-5.5, 1.5) circle (1pt);
#'   \draw (-5.5, 1.5) -- (-5, 1);
#'   \filldraw (-5, 1) circle (1pt);
#'   \draw (-5, 1) -- (-4.5, 1);
#'   \filldraw (-4.5, 1) circle (1pt);
#'   \draw (-4.5, 1) -- (-4, 1);
#'   \filldraw (-4, 1) circle (1pt);
#'   \draw (-4, 1) -- (-3.5, 1);
#'   \filldraw (-3.5, 1) circle (1pt);
#'   \draw (-3.5, 1) -- (-3, 1.5);
#'   \filldraw (-3, 1.5) circle (1pt);
#'   \draw (-3, 1.5) -- (-2.5, 1.5);
#'   \filldraw (-2.5, 1.5) circle (1pt);
#'   \draw (-2.5, 1.5) -- (-2, 1.5);
#'   \filldraw (-2, 1.5) circle (1pt);
#'   \draw (-2, 1.5) -- (-1.5, 2.0);
#'   \filldraw (-1.5, 2.0) circle (1pt);
#'
#'   \draw [decorate, decoration = {brace, amplitude=5pt, mirror, raise=4pt},
#'          yshift=0pt] (-1.25, 1) -- (-1.25, 2);
#'   \node [black] at (0.25, 1.5) {$\Delta$SOFA $\geq 2$};
#'
#'   \draw (-6.5, 1) -- (-6.5, 2.5);
#'   \node at (-6.5, 3) {SOFA};
#'   \draw (-6.5, 1) -- (-6.6, 1) node[left]{0};
#'   \draw (-6.5, 1.5) -- (-6.6, 1.5) node[left]{1};
#'   \draw (-6.5, 2) -- (-6.6, 2) node[left]{2};
#'   \draw (-6.5, 2.5) -- (-6.6, 2.5) node[left]{3};
#'
#' \end{tikzpicture}
#' ```
#'
#' A patient can potentially have multiple SI windows. The argument
#' `si_window` is used to control which SI window we focus on (options are
#' `"first", "last", "any"`).
#'
#' Further, although a 2 or more point increase in the SOFA score is defined,
#' it is not perfectly clear to which value the increase refers. For this the
#' `delta_fun` argument is used. If the increase is required to happen with
#' respect to the minimal SOFA value (within the SI window) up to the current
#' time, the `delta_cummin` function should be used. If, however, we are
#' looking for an increase with respect to the start of the SI window, then
#' the `delta_start` function should be used. Lastly, the increase might be
#' defined with respect to values of the previous 24 hours, in which case the
#' `delta_min` function is used.
#'
#' @references
#' Singer M, Deutschman CS, Seymour CW, et al. The Third International
#' Consensus Definitions for Sepsis and Septic Shock (Sepsis-3). JAMA.
#' 2016;315(8):801–810. doi:10.1001/jama.2016.0287
#'
#' @rdname label_sep3
#' @export
#'
sep3 <- function(..., si_window = c("first", "last", "any"),
                 delta_fun = delta_cummin, sofa_thresh = 2L,
                 si_lwr = hours(48L), si_upr = hours(24L),
                 keep_components = FALSE, interval = NULL) {

  cnc <- c("sofa", "susp_inf")
  res <- collect_dots(cnc, interval, ...)

  assert_that(is.count(sofa_thresh), is.flag(keep_components),
              not_null(delta_fun))

  si_lwr <- as_interval(si_lwr)
  si_upr <- as_interval(si_upr)

  delta_fun <- str_to_fun(delta_fun)
  si_window <- match.arg(si_window)

  sofa <- res[["sofa"]]
  susp <- res[["susp_inf"]]

  id <- id_vars(sofa)
  ind <- index_var(sofa)

  sus_cols <- setdiff(data_vars(susp), "susp_inf")

  sofa <- sofa[, c("join_time1", "join_time2") := list(
    get(ind), get(ind)
  )]

  on.exit(rm_cols(sofa, c("join_time1", "join_time2"), by_ref = TRUE))

  susp <- susp[is_true(get("susp_inf")), ]
  susp <- susp[, c("susp_inf") := NULL]

  susp <- susp[, c("si_lwr", "si_upr") := list(
    get(index_var(susp)) - si_lwr,
    get(index_var(susp)) + si_upr
  )]

  if (si_window %in%  c("first", "last")) {
    susp <- dt_gforce(susp, si_window, id)
  }

  join_clause <- c(id, "join_time1 >= si_lwr", "join_time2 <= si_upr")

  res <- sofa[susp,
    c(list(delta_sofa = delta_fun(get("sofa"))), mget(c(ind, sus_cols))),
    on = join_clause, by = .EACHI, nomatch = NULL]

  res <- res[is_true(get("delta_sofa") >= sofa_thresh), ]

  cols_rm <- c("join_time1", "join_time2")

  if (!keep_components) {
    cols_rm <- c(cols_rm, "delta_sofa", "samp_time", "abx_time")
  }

  res <- rm_cols(res, cols_rm, skip_absent = TRUE, by_ref = TRUE)
  res <- res[, head(.SD, n = 1L), by = c(id_vars(res))]
  res <- res[, c("sep3") := TRUE]

  res
}

#' @param x Vector of SOFA scores
#'
#' @rdname label_sep3
#' @export
#'
delta_cummin <- function(x) {
  x - cummin(ifelse(is.na(x), .Machine$integer.max, x))
}

#' @rdname label_sep3
#' @export
#'
delta_start <- function(x) x - x[!is.na(x)][1L]

#' @param shifts Vector of time shifts (multiples of the current interval) over
#' which [base::pmin()] is evaluated
#'
#' @rdname label_sep3
#' @export
#'
delta_min <- function(x, shifts = seq.int(0L, 23L)) {
  if (length(x) == 0L) x
  else {
    x - do.call(pmin.int, c(data.table::shift(x, shifts), list(na.rm = TRUE)))
  }
}

#' Suspicion of infection label
#'
#' Suspected infection is defined as co-occurrence of of antibiotic treatment
#' and body-fluid sampling.
#'
#' @param ... Data and further arguments are passed to `si_calc()`
#' @param abx_count_win Time span during which to apply the `abx_min_count`
#' criterion
#' @param abx_min_count Minimal number of antibiotic administrations
#' @param positive_cultures Logical flag indicating whether to require
#' cultures to be positive
#' @param si_mode Switch between `and`, `or`, `abx`, `samp` modes
#' @param abx_win Time-span within which sampling has to occur
#' @param samp_win Time-span within which antibiotic administration has to
#' occur
#' @param by_ref Logical flag indicating whether to process data by reference
#' @param keep_components Logical flag indicating whether to return the
#' individual components alongside the aggregated score
#' @param interval Time series interval (only used for checking consistency
#' of input data)
#'
#' @details Suspected infection can occur in one of the two following ways:
#' - administration of antibiotics followed by a culture sampling within
#'   `samp_win` hours
#'
#'    ```
#'           abx_win
#'       |---------------|
#'      ABX           sampling (last possible)
#'    ```
#'
#' - culture sampling followed by an antibiotic administration within
#'   `abx_win` hours
#'
#'    ```
#'                         samp_win
#'       |---------------------------------------------|
#'    sampling                                        ABX (last possible)
#'    ```
#'
#' The default values of `samp_win` and `abx_win` are 24 and 72 hours
#' respectively, as per [Singer et.al.
#' ](https://jamanetwork.com/journals/jama/fullarticle/2492881).
#'
#' The earlier of the two times (fluid sampling, antibiotic treatment) is taken
#' as the time of suspected infection (SI time). The suspected infection
#' window (SI window) is defined to start `si_lwr` hours before the SI time
#' and end `si_upr` hours after the SI time. The default values of 48 and 24
#' hours (respectively) are chosen as used by [Seymour et.al.
#' ](https://jamanetwork.com/journals/jama/fullarticle/2492875) (see
#' Supplemental Material).
#'
#' ```
#'                 48h                       24h
#'   |------------------------------(|)---------------|
#'                                 SI time
#' ```
#'
#' For some datasets, however, information on body fluid sampling is not
#' available for majority of the patients (eICU data). Therefore, an
#' alternative definition of suspected infection is required. For this, we use
#' administration of multiple antibiotics (argument `abx_min_count` determines
#' the required number) within `abx_count_win` hours. The first time of
#' antibiotic administration is taken as the SI time in this case.
#'
#' @references
#' Singer M, Deutschman CS, Seymour CW, et al. The Third International
#' Consensus Definitions for Sepsis and Septic Shock (Sepsis-3). JAMA.
#' 2016;315(8):801–810. doi:10.1001/jama.2016.0287
#'
#' Seymour CW, Liu VX, Iwashyna TJ, et al. Assessment of Clinical Criteria for
#' Sepsis: For the Third International Consensus Definitions for Sepsis and
#' Septic Shock (Sepsis-3). JAMA. 2016;315(8):762–774.
#' doi:10.1001/jama.2016.0288
#'
#' @rdname label_si
#' @export
#'
susp_inf <- function(..., abx_count_win = hours(24L), abx_min_count = 1L,
                     positive_cultures = FALSE,
                     si_mode = c("and", "or", "abx", "samp"),
                     abx_win = hours(24L), samp_win = hours(72L),
                     by_ref = TRUE, keep_components = FALSE, interval = NULL) {

  rename_si <- function(x) {
    rename_cols(x, "susp_inf", data_vars(x), by_ref = TRUE)
  }

  si_mode <- match.arg(si_mode)

  abx_count_win <- as_interval(abx_count_win)

  abx_win  <- as_interval(abx_win)
  samp_win <- as_interval(samp_win)

  assert_that(is.count(abx_min_count), is.flag(positive_cultures),
              is.flag(by_ref), is.flag(keep_components))

  cnc <- c("abx", "samp")
  res <- collect_dots(cnc, interval, ...)

  time_unit <- units(attr(res, "ival_checked"))

  if (positive_cultures) {
    samp_fun <- "sum"
  } else {
    samp_fun <- quote(list(samp = .N))
  }

  if (!isTRUE(by_ref)) {
    res <- lapply(res, copy)
  }

  cmbn_fun <- switch(si_mode,
    and = si_and,
    or = si_or,
    abx = function(abx, samp, ...) rename_si(abx),
    samp = function(abx, samp, ...) rename_si(samp)
  )

  cmbn_fun(
    si_abx(res[["abx"]], abx_count_win, abx_min_count),
    si_samp(aggregate(res[["samp"]], samp_fun)),
    `units<-`(abx_win, time_unit),
    `units<-`(samp_win, time_unit),
    keep_components
  )
}

si_abx <- function(x, count_win, min_count) {

  if (min_count > 1L) {

    x <- slide(x, list(abx = sum(get("abx"), na.rm = TRUE)),
               before = hours(0L), after = count_win)
  }

  set(x, j = "abx", value = x[["abx"]] >= min_count)
}

si_samp <- function(x) {
  set(x, j = "samp", value = x[["samp"]] > 0L)
}

si_and <- function(abx, samp, abx_win, samp_win, keep) {

  assert_that(has_rows(abx), has_rows(samp), msg = "
    calling `susp_inf()` with `si_mode = and` requires data from both `abx`
    and `samp` concepts"
  )

  do_roll <- function(x, y, win) {

    met_y <- meta_vars(y)

    if (keep) {

      y[x, c(met_y, "samp_time", "abx_time"), with = FALSE, roll = -win,
        nomatch = NULL, on = paste(met_y, meta_vars(x), sep = " == ")]

    } else {

      y[x, met_y, with = FALSE, roll = -win, nomatch = NULL,
        on = paste(met_y, meta_vars(x), sep = " == ")]
    }
  }

  if (keep) {

    samp_idx <- index_var(samp)
    abx_idx  <- index_var(abx)

    samp <- samp[, c("samp_time") := get(samp_idx)]
    abx <-  abx[,  c("abx_time")  := get(abx_idx)]
  }

  res <- rbind(do_roll(abx, samp, abx_win),
               do_roll(samp, abx, samp_win))

  if (keep) {

    rmv <- duplicated(res, by = meta_vars(res))

    if (any(rmv)) {
      msg_progress("removing {sum(rmv)} duplicate si events")
      res <- res[!rmv, ]
    }

  } else {

    res <- unique(res)
  }

  res <- res[, c("susp_inf") := TRUE]

  res
}

si_or <- function(abx, samp, abx_win, samp_win, keep) {

  if (keep) {

    samp_idx <- index_var(samp)
    abx_idx  <- index_var(abx)

    samp <- samp[, c("samp_time") := get(samp_idx)]
    abx <-  abx[,  c("abx_time")  := get(abx_idx)]
  }

  res <- merge(abx, samp, all = TRUE)
  res <- res[get("abx") | get("samp"), ]
  res <- rm_cols(res, c("abx", "samp"))
  res <- res[, c("susp_inf") := TRUE]

  res
}

#' Suspected infection (antibiotics-only)
#'
#' Alternative definition of suspected infection based solely on antibiotic
#' administration. This is useful for datasets lacking microbiology/sampling
#' data (e.g., HiRID, SIC).
#'
#' @param ... Data objects
#' @param abx_count_win Time span during which to count antibiotic
#' administrations
#' @param abx_min_count Minimal number of antibiotic administrations required
#' @param by_ref Logical flag indicating whether to process data by reference
#' @param keep_components Logical flag indicating whether to return time
#' components
#' @param interval Time series interval (only used for checking consistency)
#'
#' @details Suspected infection is defined as administration of at least
#' `abx_min_count` (default: 2) antibiotics within `abx_count_win` hours
#' (default: 24). The first antibiotic administration time is taken as the
#' suspected infection (SI) time.
#'
#' This alternative definition is used when body fluid sampling data is not
#' available in the dataset.
#'
#' @references
#' Singer M, Deutschman CS, Seymour CW, et al. The Third International
#' Consensus Definitions for Sepsis and Septic Shock (Sepsis-3). JAMA.
#' 2016;315(8):801–810. doi:10.1001/jama.2016.0287
#'
#' @rdname label_si
#' @export
#'
susp_inf_abx <- function(..., abx_count_win = hours(24L), abx_min_count = 2L,
                         by_ref = TRUE, keep_components = FALSE,
                         interval = NULL) {

  abx_count_win <- as_interval(abx_count_win)

  assert_that(is.count(abx_min_count), is.flag(by_ref),
              is.flag(keep_components))

  # Extract only the "abx" data from ... (handles extra args from parent callbacks)
  dots <- list(...)
  
  abx_data <- if ("abx" %in% names(dots)) {
    dots[["abx"]]
  } else if (length(dots) >= 1L && is_ts_tbl(dots[[1L]])) {
    dots[[1L]]
  } else {
    stop_ricu("susp_inf_abx requires 'abx' data")
  }

  if (!isTRUE(by_ref)) {
    abx_data <- copy(abx_data)
  }

  abx <- si_abx(abx_data, abx_count_win, abx_min_count)

  # Filter to rows where abx criterion is met
  abx <- abx[is_true(get("abx")), ]

  if (keep_components && nrow(abx) > 0L) {
    # Store index_var result before using in data.table expression
    # to avoid name collision with "abx" column
    idx_col <- index_var(abx)
    abx <- abx[, c("abx_time") := get(idx_col)]
  }

  # Rename abx column to susp_inf_abx to match concept name
  abx <- rename_cols(abx, "susp_inf_abx", "abx", by_ref = TRUE)

  abx
}

#' Sepsis-3 (antibiotics-only alternative)
#'
#' Alternative Sepsis-3 definition using antibiotics-only suspected infection.
#' This is useful for datasets lacking microbiology/sampling data.
#'
#' @inheritParams sep3
#'
#' @details This function implements the same SOFA-based Sepsis-3 criterion
#' as [sep3()], but uses [susp_inf_abx()] for the suspected infection
#' component instead of [susp_inf()]. This allows computation of a sepsis
#' label for datasets without microbiology sampling data.
#'
#' @seealso [sep3()], [susp_inf_abx()]
#'
#' @rdname label_sep3
#' @export
#'
sep3_alt <- function(..., si_window = c("first", "last", "any"),
                     delta_fun = delta_cummin, sofa_thresh = 2L,
                     si_lwr = hours(48L), si_upr = hours(24L),
                     keep_components = FALSE, interval = NULL) {

  cnc <- c("sofa", "susp_inf_abx")
  res <- collect_dots(cnc, interval, ...)

  assert_that(is.count(sofa_thresh), is.flag(keep_components),
              not_null(delta_fun))

  si_lwr <- as_interval(si_lwr)
  si_upr <- as_interval(si_upr)

  delta_fun <- str_to_fun(delta_fun)
  si_window <- match.arg(si_window)

  sofa <- res[["sofa"]]
  susp <- res[["susp_inf_abx"]]

  id <- id_vars(sofa)
  ind <- index_var(sofa)
  susp_ind <- index_var(susp)

  sus_cols <- setdiff(data_vars(susp), "susp_inf_abx")

  sofa <- sofa[, c("join_time1", "join_time2") := list(
    get(ind), get(ind)
  )]

  on.exit(rm_cols(sofa, c("join_time1", "join_time2"), by_ref = TRUE))

  # Use explicit column access for filtering
  susp <- susp[susp[[susp_ind]] >= hours(0L) & susp[["susp_inf_abx"]] == TRUE, ]
  susp <- susp[, c("susp_inf_abx") := NULL]
  
  # Handle empty susp case
  if (nrow(susp) == 0L) {
    # Return empty result with correct structure
    res <- sofa[0L, ]
    res <- res[, c("sep3_alt") := logical(0L)]
    res <- rm_cols(res, c("join_time1", "join_time2", "sofa"), 
                   skip_absent = TRUE, by_ref = TRUE)
    return(res)
  }

  susp <- susp[, c("si_lwr", "si_upr") := list(
    get(susp_ind) - si_lwr,
    get(susp_ind) + si_upr
  )]

  if (si_window %in%  c("first", "last")) {
    susp <- dt_gforce(susp, si_window, id)
  }

  join_clause <- c(id, "join_time1 >= si_lwr", "join_time2 <= si_upr")

  res <- sofa[susp,
    c(list(delta_sofa = delta_fun(get("sofa"))), mget(c(ind, sus_cols))),
    on = join_clause, by = .EACHI, nomatch = NULL]

  res <- res[is_true(get("delta_sofa") >= sofa_thresh), ]

  cols_rm <- c("join_time1", "join_time2")

  if (!keep_components) {
    cols_rm <- c(cols_rm, "delta_sofa", "abx_time")
  }

  res <- rm_cols(res, cols_rm, skip_absent = TRUE, by_ref = TRUE)
  res <- res[, head(.SD, n = 1L), by = c(id_vars(res))]
  res <- res[, c("sep3_alt") := TRUE]

  res
}
