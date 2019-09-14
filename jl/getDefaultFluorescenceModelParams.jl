"""
For getting the default parameter dictionary for the fluorescence model.

Arguments:  None
Returns:    Dict
"""
function getDefaultFluorescenceModelParams()
  p=Dict( "cell_radius"       =>      10e-6,
          "baseline"          =>      0.045e-6,
          "influx"            =>      0.049,
          "outflux"           =>      0.00011,
          "b_i"               =>      160.0,
          "f_i"               =>      7.766990291262137e8,
          "indicator"         =>      100e-6,
          "b_e"               =>      10000.0,
          "f_e"               =>      100e6,
          "endogeneous"       =>      100e-6,
          "b_im"              =>      524.0,
          "f_im"              =>      2.47e8,
          "immobile"          =>      78.7e-6,
          "excitation"        =>      0.15,
          "release"           =>      0.11,
          "peak"              =>      2.9e-7,
          "title"             =>      "",
          "capture_rate"      =>      0.62,
          "capture_variance"  =>      0.038,
          "frequency"         =>      100.0,
          "spike_file"        =>      "",
          "calcium_file"      =>      "",
          "colname"           =>      Symbol(""),
          "BCa"               =>      0)
  return p
end

