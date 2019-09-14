## For converting a hdf5 file containing perturbed traces to a 'spikefinder like' csv file

## julia jl/perturb_h5_to_calcium_csv.jl --h5_file indicator_8_2.h5 

using ArgParse
using CSV
using DataFrames
using HDF5
using Glob

function parseParams()
  s = ArgParseSettings()
  @add_arg_table s begin
  "--h5_dir"
    help = "The file to be converted to csvs."
    arg_type = String
    default = "/space/td16954/h5/"
  "--perturbed_dir"
    help = "The place to save the perturbed file."
    arg_type = String
    default = homedir() * "/Spike_finder/perturbed_fluoro/"
  "--perturb_param"
    help = "The paramater that was perturbed."
    arg_type = String
    default = "indicator"
  "--num_perturbations"
    help = "The number of perturbations that we expect to see here."
    arg_type = Int
    default = 3
  "--optimised"
    help = "Flag for using the optimised perturbation files."
    action = :store_true
  "--debug"
    help = "Enter debug mode."
    action = :store_true
  end
  p = parse_args(s)
  return p
end

function getH5FilesInOrder(h5_dir::String, optimised::Bool, perturb_param::String)
  file_pattern = optimised ? perturb_param * "*optimised*" : perturb_param * "*[0-9].h5"
  h5_filenames = glob(file_pattern, h5_dir)
  unsorted_filedict = Dict(parse(Int, split(split(replace(f, "_optimised", ""), ".")[1], "_")[end]) => f for f in h5_filenames)
  return [kv[2] for kv in sort(unsorted_filedict)]
end

function hasPerturbations(fid::HDF5.HDF5File)
  return !all("info" .== names(fid))
end

function getModelFluoroFromFile(fid::HDF5.HDF5File)
  perturb_names = names(fid)["info" .!= names(fid)]
  single_trace_model_fluoro_frame = DataFrame()
  for p in perturb_names
    model_calcium = read(fid[p]["fluoro"]["model_fluorescence"])
    single_trace_model_fluoro_frame[Symbol(p)] = model_calcium
  end
  return single_trace_model_fluoro_frame
end

function getSaveName(is_optimised::Bool, perturb_param::String, perturb_value::String, perturbed_dir::String)
  save_name_elements = is_optimised ? ("8", perturb_param, perturb_value, "optimised", "model", "calcium", "csv") : ("8", perturb_param, perturb_value, "model", "calcium", "csv")
  save_name = perturbed_dir * join(save_name_elements, ".")
  return save_name
end

function main()
  info("Starting main function...", prefix=string(now(), " INFO: "))
  params = parseParams()
  if params["debug"]; info(" Entering debug mode.", prefix=string(now(), " INFO: ")); return nothing; end
  h5_files = getH5FilesInOrder(params["h5_dir"], params["optimised"], params["perturb_param"])
  fluoro_frames = [DataFrame() for i in 1:params["num_perturbations"]]
  for h5f in h5_files
    info("processing "*h5f*"...", prefix=string(now(), " INFO: "))
    colname = Symbol("x"*split(split(replace(h5f, "_optimised", ""), ".")[1], "_")[end])
    fid = h5open(h5f)
    !hasPerturbations(fid) && continue
    single_trace_model_fluoro_frame = getModelFluoroFromFile(fid)
    [fluoro_frames[i][colname] = single_trace_model_fluoro_frame[Symbol(i)] for i in 1:params["num_perturbations"]]
  end
  perturbed_values = h5read(h5_files[1], "info")["values"]
  for i in 1:params["num_perturbations"]
    fluoro_frame = fluoro_frames[i]
    str_p_value = string(perturbed_values[i])
    save_name = getSaveName(params["optimised"], params["perturb_param"], str_p_value, params["perturbed_dir"])
    info("saving "*save_name, prefix=string(now(), " INFO: "))
    CSV.write(save_name, fluoro_frame)
  end
  info("Done.", prefix=string(now(), " INFO: "))
end

main()
