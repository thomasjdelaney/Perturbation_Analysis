"""
For reading the optimisation spreadsheet, extracting the optimised parameters,
and creating a dictionary out of those parameters.

Arguments:  opt_file, the absolute file path
Returns:    optimised_params, dictionary
"""
function getOptimisedDict(opt_file::AbstractString)
  opt_table = CSV.read(opt_file)
  opt_row = opt_table[findmin(opt_table[:rms])[2], :]
  optimised_params = Dict(string(name) => opt_row[name][1] for name in names(opt_table))
  return optimised_params
end

