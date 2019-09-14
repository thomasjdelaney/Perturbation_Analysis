## For making the fluroescence comparison plots for perturbed data

push!(LOAD_PATH, homedir() * "/Simulate_Spike_Trains/jl")
using HDF5
using SimulateSpikeTrains
using ArgParse

function parseParams()
  s = ArgParseSettings()
  @add_arg_table s begin
    "--debug"
      help = "Enter debug mode."
      action = :store_true
    "--file_name"
      help = "The hdf5 file name."
      arg_type = String
      default = "indicator_8_18.h5"
    "--save_name"
      help = "The name of the file to be saved"
      arg_type = String
      default = "indicator/not_optimised/indicator_perturbed_fluorescence_18.png"
    "--parameter_name"
      help = "name of parameter being perturbed"
      arg_type = String
      default = "Indicator"
  end
  p = parse_args(s)
  h5_dir = ENV["SPACE"] * "/h5/"
  p["file_path"] = h5_dir * p["file_name"]
  p["save_name"] = ENV["SPACE"] * "/Perturbation_Analysis/images/traces/" *p["save_name"]
  return p
end

params = parseParams();
file_handle = h5open(params["file_path"], "r");
spike_train = convert(Array{Int64,1}, read(file_handle["1"]["fluoro"]["spike_train"]));
frequency = read(file_handle["info"]["frequency"]);
observed_fluorescence = read(file_handle["1"]["fluoro"]["zscore_observed"]);
time_points = collect(0:(length(observed_fluorescence)-1))/frequency;
PyPlot.figure(figsize=(9,7));
PyPlot.subplot(7,1,1)
plotFluorescence(time_points, observed_fluorescence, fluorescence_label="Observed fluorescence", has_ylabel=true, has_xticks=false)
PyPlot.legend()
labels = ["x0.01", "x0.1", "exp. value", "x10", "x100"];
colours = ["red", "orangered", "orange", "gold", "yellow"];
for i in 1:5
  fluorescence = read(file_handle[string(i)]["fluoro"]["zscore_model"]);
  label = labels[i];
  colour = colours[i];
  PyPlot.subplot(7,1,i+1);
  plotFluorescence(time_points, fluorescence, fluorescence_label=label, has_ylabel=true, has_xticks=false, colour=colour);
  PyPlot.legend(loc="upper right")
end
PyPlot.subplot(7,1,7);
plotSpikeTrain(time_points, spike_train, has_xlabel=true, has_ylabel=true)
PyPlot.ylabel("Spikes");
PyPlot.tight_layout();
PyPlot.savefig(params["save_name"]);
