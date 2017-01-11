
#' Initiate master problem
#' 
#' \code{initiate_master} copy the AMPL files into the temporary 
#' folder of the expansion planning optimisation and create the other input
#' and output file of the master problem
#' 
#' @param candidates
#'   list of investment candidates, as returned by
#'   \code{\link{read_candidates}}
#' @param exp_options 
#'   list of options related to the expansion planning, as returned
#'   by the function \code{\link{read_options()}}
#' @param opts
#'   list of simulation parameters returned by the function
#'   \code{antaresRead::setSimulationPath}
#'
#' @return This function does not return anything.
#' 
#' @import assertthat antaresRead
#' @export
#' 
initiate_master <- function(candidates = read_candidates(opts), exp_options = read_options(opts), opts = simOptions())
{
  # ampl file names (stored in inst folder)
  run_file <- "ampl/master_run.ampl"
  mod_file <- "ampl/master_mod.ampl"
  dat_file <- "ampl/master_dat.ampl"
  
  # master input/output files (interface with AMPL is ensured with .txt files)
  in_out_files <- list()
  in_out_files$n_mc <- "in_nmc.txt"
  in_out_files$n_w <- "in_nw.txt"
  in_out_files$candidates <- "in_candidates.txt"
  in_out_files$cut  <- "in_cut.txt"
  in_out_files$z0 <- "in_z0.txt"
  in_out_files$avg_rentability <- "in_avgrentability.txt"
  in_out_files$yearly_rentability <- "in_yearlyrentability.txt"
  in_out_files$weekly_rentability <- "in_weeklyrentability.txt"
  in_out_files$yearly_costs <- "in_yearlycosts.txt"
  in_out_files$weekly_costs <- "in_weeklycosts.txt"
  in_out_files$options <- "in_options.txt"
  in_out_files$sol_master <- "out_solutionmaster.txt"
  in_out_files$underestimator <- "out_underestimator.txt"
  in_out_files$log <- "out_log.txt"
  
  
  # check if temporary folder exists, if not create it
  tmp_folder <- paste(opts$studyPath,"/user/expansion/temp",sep="")
  if(!dir.exists(tmp_folder))
  {
    dir.create(tmp_folder)
  }
  
  # copy AMPL files into the temporary folder
  run_file <- system.file(run_file, package = "antaresXpansion")
  mod_file <- system.file(mod_file, package = "antaresXpansion")
  dat_file <- system.file(dat_file, package = "antaresXpansion")
  
  assert_that(file.copy(from = run_file, to = tmp_folder, overwrite = TRUE))
  assert_that(file.copy(from = mod_file, to = tmp_folder, overwrite = TRUE))
  assert_that(file.copy(from = dat_file, to = tmp_folder, overwrite = TRUE))
  
  # create empty in_out files
  lapply(in_out_files, FUN = function(x, folder){file.create(paste0(folder, "/", x))}, folder = tmp_folder)
  
  # fill files which will be similar for every iteration of the benders decomposition
  # 1 - in_nmc.txt
  n_mc <- length(opts$mcYears)
  write(n_mc, file = paste0(tmp_folder, "/", in_out_files$n_mc))
  
  # 2 - in_nw.txt
  n_w <- floor((opts$parameters$general$simulation.end - opts$parameters$general$simulation.start + 1)/7)
  write(n_w, file = paste0(tmp_folder, "/", in_out_files$n_w))
  
  # 3 - in_candidates.txt
  script <- ""
  for(i in 1:length(candidates))
  {
    script <- paste0(script, candidates[[i]]$name, " ", candidates[[i]]$cost, " ", candidates[[i]]$unit_size, " ", candidates[[i]]$max_unit)
    if(i != length(candidates))
    {
      script <- paste0(script, "\n")
    }
  }
  write(script, file = paste0(tmp_folder, "/", in_out_files$candidates))
  
  # 4 - in_options.txt
  if(exp_options$master == "relaxed")
  {
    write("option relax_integrality 1;", file = paste0(tmp_folder, "/", in_out_files$options))
  }
}


#' Solver master problem
#' 
#' \code{solver_master} execute the AMPL file master_run.ampl
#' located in the temporary folder of the current expansion 
#' planning optimisation
#' 
#' @param opts
#'   list of simulation parameters returned by the function
#'   \code{antaresRead::setSimulationPath}
#'
#' @return This function does not return anything.
#' 
#' @import assertthat antaresRead
#' @export
#' 
solve_master <- function(opts = simOptions())
{
  tmp_folder <- paste(opts$studyPath,"/user/expansion/temp",sep="")
  
  assert_that(file.exists(paste0(tmp_folder, "/master_run.ampl")))
  assert_that(file.exists(paste0(tmp_folder, "/master_mod.ampl")))
  assert_that(file.exists(paste0(tmp_folder, "/master_dat.ampl")))
  
  cmd <- paste0("cd ", tmp_folder, " & ampl ", tmp_folder, "/master_run.ampl")
  shell(cmd, wait = TRUE, intern = TRUE)
}