"""
calcium baseline, ca influx, ca outflux, indicator backward, indicator forward, total indicator,
endogeneous backward, endogeneous forward, total endogeneous buffer,
immobile backward, immobile forward, total immobile,
excitation rate, release rate, calcium peaks, spike times
noise variance, figure title, capture rate, capture variance,
from_file, frequency, debug, excited buffered calcium
"""
function parseParams()
  s = ArgParseSettings()
  @add_arg_table s begin
  "--perturb_params"
    help = "The parameters to be perturbed."
    arg_type = String
    default = "indicator,immobile"
  "--perturb_values"
    help = "The values to which the perturbed parameter will be set. Length must be a multiple of the number of parameters to be perturbed."
    arg_type = Float64
    nargs = '*'
    default = [100e-5, 100e-6, 100e-7, 7.87e-4, 7.87e-5, 7.87e-6]
  "--save_name"
    help = "The filename under which the file will be saved."
    arg_type = String
    default = ""
  "--cell_radius"
    help = "The radius of the model cell."
    arg_type = Float64
    default = 10e-6
  "--dataset"
    help = "The spike finder dataset we are working from."
    arg_type = String
    default = "8"
  "--colname"
    help = "The column we're analysing here."
    arg_type = Symbol
    default = Symbol("18")
  "--opt_files"
    help = "A comma separated list of absolute file paths"
    arg_type = String
    default = "/space/td16954/optimisation_csvs/8_2_0.1_0.01_indicator_100e-5.csv,/space/td16954/optimisation_csvs/8_2_0.1_0.01_indicator_100e-6.csv,/space/td16954/optimisation_csvs/8_2_0.1_0.01_indicator_100e-7.csv"
  "--spike_file"
    help = "The file from which to load the spike train."
    arg_type = String
    default = homedir() * "/Spike_finder/train/8.train.spikes.csv"
  "--calcium_file"
    help = "The file from which to load the calcium trace."
    arg_type = String
    default = homedir() * "/Spike_finder/train/8.train.calcium.csv"
  "--frequency"
    help = "The frequency at which the data was sampled. (Hz)"
    arg_type = Float64
    default = 100.0
  "--debug"
    help = "Enter debug mode."
    action = :store_true
  end
  p = parse_args(s)
  p["opt_files"] = split(p["opt_files"], ",")
  if length(p["opt_files"]) == 1
    p["opt_files"] = repeat(p["opt_files"], inner=length(p["perturb_values"]))
  end
  if p["save_name"] == ""
    p["save_name"] = "/space/td16954/h5/"*p["perturb_param"]*"_"*p["dataset"]*"_"*string(p["colname"])[2:end]*".h5"
  end
  return p
end

