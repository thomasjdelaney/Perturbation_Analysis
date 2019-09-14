# module for performing perturbation analysis on the fluorescence model

push!(LOAD_PATH, homedir() * "/Fluorescence_Model/jl")
push!(LOAD_PATH, homedir() * "/Julia_Utils/jl")

module PerturbationAnalysis

using ArgParse
using CSV
using DataFrames
using JuliaUtils: sphereVolume, smoothen, sphereVolume, getPowerSpectrum
using PyPlot
using StatsBase

import FluorescenceModel

export getAllParams,
  getDefaultFluorescenceModelParams,
  getOptimisedDict,
  getParamValueDict,
  parseParams,
  perturbParamTraces,
  runModelReturnAll

include("getAllParams.jl")
include("getDefaultFluorescenceModelParams.jl")
include("getOptimisedDict.jl")
include("getParamValueDict.jl")
include("parseParams.jl")
include("perturbParamTraces.jl")
include("runModelReturnAll.jl")

end
