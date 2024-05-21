
init_cavity = 300.0
init_pressure = 1.0135e5 # Pa
outer_pressure = 3.45e6
[Mesh]
  patch_size = 100
  partitioner = centroid
  centroid_partitioner_direction = y
  patch_update_strategy = always
  [simple_mesh]
    type = FileMeshGenerator
    file = IFA-513r6_acc.e
  []
  allow_renumbering = false
[]

[Problem]
  coord_type = RZ
[]

[GlobalParams]
  displacements = 'disp_r disp_z'
[]

[AuxVariables]
  [temp]
    order = FIRST
    family = LAGRANGE
    initial_condition = 300.0
  []
  [burnup_per]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.
  []
  [burnup]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.0
  []
  [porosity]
    order = FIRST
    family = MONOMIAL
    initial_condition = 0.0
  []
  [neu_flux]
    order = FIRST
    family = MONOMIAL
    initial_condition = 0.0
  []
## gas release auxkernel
  [input_material]
     order = FIRST
     family = MONOMIAL
     initial_condition = 0.0
  []
  [axial_power]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.
  []
  [radial_power]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.
  []
  [average_radial_power]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.
  []
  [power]
    order = FIRST
    family = MONOMIAL
    initial_condition = 1.
  []
  [fission_rate]
    order = FIRST
    family = MONOMIAL
    initial_condition = 0.0
  []
  [rating]
    order = FIRST
    family =  MONOMIAL
  []
  [gas_released_density]
    order = FIRST
    family =  MONOMIAL
  []
[]

[AuxKernels]
  [burnup_per_aux]
    type = BurnupPerAux
    block = 'fuel'
    power = power
    variable = burnup_per
  []
  [burnup_aux]
    type = EnginerringBurnupAux
    block = 'fuel'
    power = axial_power
    variable = burnup
  []
  [porosity]
    type = ParsedAux
    expression = 0.05
    variable = porosity
    block = 'fuel'
  []
  [neu_flux_aux]
    type = FunctionAux
    function = neu_flux_fun
    variable = neu_flux
  [] 
## gas release auxkernel
  [gas_release_aux]
    type = ParsedAux
    coupled_variables = 'gas_released_density'
    expression = 'gas_released_density*0.000069615'
    variable = input_material
  []
  [axial_power]
    type = FunctionAux
    function = axial_power
    variable = axial_power
    block = 'fuel'
  []
  [radial_power]
    type = RadialPowerAux
    function = radial_power
    variable = radial_power
    burnup = burnup
    block = 'fuel'
  []
  [average_radial_power]
    type = SpatialUserObjectAux
    variable = average_radial_power
    execute_on = 'initial timestep_end'
    user_object = average_radial_power
  []
  [power]
    type = PowerAux
    radial_power = radial_power
    ave_radial_power = average_radial_power
    axial_power = axial_power
    variable = power
  []
  [fission_rate_aux]
    type = ParsedAux
    variable = fission_rate
    coupled_variables = 'power'
    expression = 'power / 3.28451e-11' # 3.28451e-11 is once fission release energy
  []
  [rating]
    type = ParsedAux
    variable = rating
    coupled_variables = 'power'
    expression = 'power/10.96e6'
  []
  [gas_released_density_aux]
    type = MaterialRealAux
    property = gas_released_density
    variable = gas_released_density
  []
[]

[Contact]
  inactive = 'gap_contact2'
  [gap_contact]
    secondary = 'clad_inside'
    primary = 'fuel_outer'
    model = frictionless
    correct_edge_dropping = true
    formulation = mortar
    c_normal = 1e2
  []
  [gap_contact2]
    primary = 'fuel_outer'
    secondary = 'clad_inside'
    model = frictionless
    penalty = 1e12
    formulation = penalty
    normalize_penalty = true
  []
  [gap_contact_top]
    primary = 'plenum_top'
    secondary = 'fuel_top'
    model = frictionless
    penalty = 1e9
    formulation = penalty
    tangential_tolerance = 1e-6
    normal_smoothing_distance = 1e-6
  []
  [element]
    primary = 'down'
    secondary = 'up'
    model = glued
    penalty = 1e9
    normalize_penalty = true
    tangential_tolerance = 1e-3
  []
[]

[Modules/TensorMechanics/Master]
  [fuel]
    strain = FINITE
    add_variables = true
    eigenstrain_names = 'thermal_expansion_eigenstrain relocation_eigenstrain densification_eigenstrain solid_swelling_eigenstrain gas_swelling_eigenstrain'
    generate_output = 'vonmises_stress strain_zz strain_xx strain_yy axial_strain hoop_strain radial_strain'
    block = 'fuel'
  []
  [clad]
    strain = FINITE
    add_variables = true
    eigenstrain_names = 'thermal_expansion_eigenstrain irradiation_growth_eigenstrain'
    generate_output = 'vonmises_stress creep_strain_xx strain_zz strain_xx strain_yy creep_strain_zz axial_strain hoop_strain radial_strain axial_creep_strain hoop_creep_strain radial_creep_strain'
    block = 'clad'
  []
[]

[Materials]
  inactive = 'UO2_radial_return_stress UO2_power_law_creep'
  [ForMas]
    type = ForMas
    temperature = temp
    rating = rating
  []
  [UO2_density]
    type = UO2Density
    temperature = temp
    block = 'fuel'
  []
  [Zr4_density]
    type = Zr4Density
    temperature = temp
    block = 'clad'
  []
  [UO2_elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    args = temp
    youngs_modulus = youngs_modulus
    poissons_ratio = poissons_ratio
    block = 'fuel'
  []
  [UO2_elasticity_material]
    type = UO2ElasticityMaterial
    temperature = temp
    density_per = 95
    block = 'fuel'
  []
  [Zr4_elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    args = temp
    youngs_modulus = youngs_modulus
    poissons_ratio = poissons_ratio
    block = 'clad'
  []
  [Zr4_elasticity_material]
    type = Zr4ElasticityMaterial
    temperature = temp
    block = 'clad'
  []
  
  [UO2_thermal_expansion]
    type = ComputeUO2InstantaneousThermalExpansionEigenstrain
    stress_free_temperature = 293.
    temperature = temp
    eigenstrain_name = thermal_expansion_eigenstrain
    block = 'fuel'
  []
  [Relocation]
    type = RelocationEigenstrain
    burnup = burnup
    power = power
    r = 0.005347
    gap = 0.00010795
    eigenstrain_name = relocation_eigenstrain
    block = 'fuel'
  []
  [Densification]
    type = ComputeDensityEigenstrain
    temperature = temp
    burnup = burnup
    eigenstrain_name = densification_eigenstrain
    block = 'fuel'
  []
  [UO2_radial_return_stress]
    type = ComputeMultipleInelasticStress
    inelastic_models = 'UO2_power_law_creep'
    tangent_operator = elastic
    block = 'fuel'
  []
  [UO2_power_law_creep]
    type = UO2CreepStressUpdate
    temperature = temp
    fission_rate = fission_rate
    q_v_fun = power
    density_percent = 95
    block = 'fuel'
  []
  [UO2_solid_swelling]
    type = ComputeInstantaneousSolidSwellingEigenstrain
    burnup = burnup_per
    eigenstrain_name = solid_swelling_eigenstrain
    block = 'fuel'
  []
  [UO2_gas_swelling]
    type = ComputeInstantaneousGasSwellingEigenstrain
    burnup = burnup_per
    temperature = temp
    eigenstrain_name = gas_swelling_eigenstrain
    block = 'fuel'
  []
  
  [Zr4_thermal_expansion]
    type = ComputeZr4ThermalExpansionEigenstrain
    stress_free_temperature = 293.
    temperature = temp
    eigenstrain_name = thermal_expansion_eigenstrain
    block = 'clad'
  []
  [Irradiation_growth]
    type = ZrIrradiationGrowth
    fast_neutron_flux = neu_flux
    temperature = temp
    eigenstrain_name = irradiation_growth_eigenstrain
    block = 'clad'
  []
  [Zr4_radial_return_stress]
    type = ComputeMultipleInelasticStress
    inelastic_models = 'Zr4_power_law_creep'
    tangent_operator = elastic
    block = 'clad'
  []
  [Zr4_power_law_creep]
    type = Zr4CreepStressUpdate
    temperature = temp
    neu_flux_function = neu_flux_fun
    block = 'clad'
    max_inelastic_increment = 0.01
    absolute_tolerance = 1e-5
    relative_tolerance = 1e-5
    substep_strain_tolerance = 0.001
  []
  [small_stress]
    type = ComputeFiniteStrainElasticStress
    block = 'fuel'
  []
[]

[BCs]
  #active = 'coolant_pressure pellet_bottom_disp Cavity_pressure'
  [coolant_pressure]
    type = Pressure
    function = outer_pressure
    boundary = outer
    variable = disp_r
  []

  [CavityPressure]
    [cavity_pressure]
      boundary = 'fuel_outer fuel_top center clad_inside plenum_top down_left down_right'
      initial_temperature = ${init_cavity}
      temperature = ave_temp_clad_inside_top# use clad top temperature as average temperature
      material_input = inputmaterial 
      volume = 'volume_tol butterfly'
      initial_pressure = ${init_pressure} 
      R = 8.314472
      output = ppress
      execute_on = TIMESTEP_BEGIN
    []
  []
  [pellet_bottom_disp]
    type = DirichletBC
    variable = disp_z
    boundary = 'pin_bottom'
    value = 0.0
    preset = true
  []
  [pellet_bottom_disp1]
    type = DirichletBC
    variable = disp_r
    boundary = 'pin_bottom'
    value = 0.0
    preset = true
  []
[]

[UserObjects]
  [average_radial_power]
    type = LayeredAverage
    variable = radial_power
    direction = x
    num_layers = 1
    execute_on = 'initial timestep_end'
  []
[]

[Functions]
  [axial_power]
    type = PiecewiseMultilinear
    data_file = axial_power.txt
  []
  [radial_power]
    type = PiecewiseMultilinear
    data_file = radial_power.txt
  []
  [neu_flux_fun]
    type = PiecewiseLinear
    x = '0 1.'
    y = '5e15 5e15'
    axis = y
  []
  [outer_pressure]
    type = PiecewiseLinear
    x = '0 15209850'
    y = '${outer_pressure} ${outer_pressure}'
  []
[]

[Postprocessors]
## gas release postprocessors
  [q_max] ## get the mox volume power
    type = ElementExtremeValue
    variable = power
    value_type = max
  []
  [vol_fission] ## get the volume fission unit[fission/s]
    type = ElementIntegralVariablePostprocessor
    variable = fission_rate
    block = 'fuel'
  []
  [inputmaterial]
    type = ElementIntegralVariablePostprocessor
    variable = gas_released_density
    block = fuel
    execute_on = 'timestep_end'
  []
  [ave_temp_clad_inside_top]
    type = SideAverageValue
    boundary = 'plenum_top'
    execute_on = 'initial linear'
    variable = temp
  []
  [volume_tol]
    type = InternalVolume
    boundary = 'fuel_outer fuel_top center up clad_inside plenum_top downline'
    execute_on = 'initial linear'
  []
  [volume_fuel]
    type = InternalVolume
    boundary = 'fuel_outer fuel_top center up'
    execute_on = 'initial linear'
  []
  [volume_clad_inside]
    type = InternalVolume
    boundary = 'clad_inside plenum_top downline'
    execute_on = 'initial linear'
  []
  [volume_tol_minus]
    type = ParsedPostprocessor
    function = 'volume_fuel + volume_clad_inside'
    pp_names = 'volume_fuel volume_clad_inside'
  []
  [butterfly]
    type = ConstantPostprocessor
    value = 1e-8
  []
[]

[Preconditioning/smp]
  type = SMP
  full = true
[]

[Executioner]
  type = Transient
  #solve_type = 'PJFNK'
  solve_type = 'NEWTON'
  [TimeStepper]
    type = TimeSequenceStepper
    time_sequence ='8640 17280 25920 34560 43200 51840 60480 267840 604800 1296000 1555200 2937600 3196800 3456000 3888000 5184000 6220800 6652800 6998400 7171200 7776000 8640000 9072000 9504000 9936000 10368000 12009600 12787200 13651200 14688000'
  []
  #start_time = 0.
  end_time = 14688000

  nl_abs_tol = 1e-4
  nl_rel_tol = 1e-4
  l_tol = 1e-4
  l_max_its = 15
  nl_max_its = 15

  #petsc_options_iname = '-pc_type -pc_fator_mat_solver_package'
  #petsc_options_value = 'lu        superlu_dist'
  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       nonzero'
  line_search = 'none'
[]

[Outputs]
  exodus = true
  print_linear_residuals = true
[]

[Debug]
 show_var_residual_norms = true
 #show_actions = true
[]