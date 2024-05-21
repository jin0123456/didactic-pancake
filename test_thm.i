## Units in the input file: m-Pa-s-K
[Mesh]
  [simple_mesh]
    type = FileMeshGenerator
    file = IFA-513r6_acc.e
  []
  [secondary]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'clad_inside'
    new_block_id = 10001
    new_block_name = 'interface_secondary_subdomain'
    input = simple_mesh
  []
  [primary]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'fuel_outer'
    new_block_id = 10000
    new_block_name = 'interface_primary_subdomain'
    input = secondary
  []
  patch_update_strategy = iteration
[]

[Problem]
  coord_type = RZ
[]

[Variables]
  [temp]
    initial_condition = 300.0
  []
  [lm]
    block = 'interface_secondary_subdomain'
  []
[]

[AuxVariables]
  [disp_x]
  []
  [disp_y]
  []
  [contact_pressure]
  []
  [burnup_per]
    order = FIRST
    family = MONOMIAL
  []
  [burnup]
    order = FIRST
    family = MONOMIAL
  []
  [porosity]
    order = FIRST
    family = MONOMIAL
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
[]

[AuxKernels]
  [burnup_per_aux]
   type = ADBurnupPerAux
   block = 'fuel'
   power = power
   variable = burnup_per
  []
  [burnup_aux]
    type = ADEnginerringBurnupAux
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
[]


[Kernels]
  [heat_diff]
    type = ADHeatConduction
    variable = temp

  []
  [heat_source]
    type = ADCustomHeatSource
    block = 'fuel'
    variable = temp
    power = power
  []
  [time_derivative]
    type = ADHeatConductionTimeDerivative
    variable = temp

  []
[]

[BCs]
  [temperature_right]
    type = DirichletBC
    variable = temp
    value = 500
    boundary = 'outer'
  []
[]

[Constraints]
  [thermal_contact]
    type = ModularGapConductanceConstraint
    variable = lm
    secondary_variable = temp
    primary_boundary = fuel_outer
    primary_subdomain = interface_primary_subdomain
    secondary_boundary = clad_inside
    secondary_subdomain = interface_secondary_subdomain
    gap_flux_models = 'side_conduction'
    use_displaced_mesh = true
    gap_geometry_type = 'CYLINDER'
  []
[]

[Materials]
  [UO2thermal]
    type = ADUO2HeatConductionMaterial
    temperature = temp
    burnup = burnup_per
    porosity = porosity
    block = 'fuel'
  []
  [UO2Density]
    type = ADUO2HeatDensity
    temperature = temp
    block = 'fuel'
  []

  [Zr4thermal]
    type = ADZr4HeatConductionMaterial
    temperature = temp
    block = 'clad'
  []
  [Zr4Density]
    type = ADZr4Density
    temperature = temp
    block = 'clad'
  []
  [power]
    type = ParsedMaterial
    property_name = power
    coupled_variables = 'power'
    expression = 'power'
  []
  [steel_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'steel_hardness'
    prop_values = '129' ## for stainless steel 304
    block = 'fuel'
  []
  [aluminum_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'aluminum_hardness'
    prop_values = '15' #for 99% pure Al
    block = 'clad'
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
[]

[UserObjects]
  [average_radial_power]
    type = LayeredAverage
    variable = radial_power
    direction = x
    num_layers = 1
    execute_on = 'initial timestep_end'
  []
  [side_contact]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = thermal_conductivity
    secondary_conductivity = thermal_conductivity
    temperature = temp
    contact_pressure = contact_pressure
    primary_hardness = steel_hardness
    secondary_hardness = aluminum_hardness
    boundary = fuel_outer
  []
  [side_radiation]
    type = GapFluxModelRadiation
    temperature = temp
    boundary = fuel_outer
    primary_emissivity = 0.8
    secondary_emissivity = 0.325
    use_displaced_mesh = true
  []
  [side_conduction]
    type = GapFluxModelConduction
    temperature = temp
    boundary = fuel_outer
    gap_conductivity = 0.15
  []
[]

[MultiApps]
  [sub]
    type = TransientMultiApp
    input_files = test_mech.i
    positions = '0 0 0'
    sub_cycling = true
    execute_on = 'initial timestep_end'
  []
[]

[Transfers]
  [to_sub]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = temp
    variable = temp
    to_multi_app = sub
  []

  [from_sub_x]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = disp_r
    variable = disp_r
    from_multi_app = sub
  []
  [from_sub_y]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = disp_z
    variable = disp_z
    from_multi_app = sub
  []
  [from_sub_contact]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = interface_normal_lm
    variable = contact_pressure
    from_multi_app = sub
  []
[]


[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  #start_time = 0.
  end_time = 14688000
  [TimeStepper]
    type = TimeSequenceStepper
    time_sequence ='8640 17280 25920 34560 43200 51840 60480 267840 604800 1296000 1555200 2937600 3196800 3456000 3888000 5184000 6220800 6652800 6998400 7171200 7776000 8640000 9072000 9504000 9936000 10368000 12009600 12787200 13651200 14688000'
  []
  nl_abs_tol = 1e-4
  nl_rel_tol = 1e-4
  l_tol = 1e-4
  l_max_its = 30
  nl_max_its = 30

  petsc_options_iname = '-pc_type -pc_fator_mat_solver_package'
  petsc_options_value = 'lu        superlu_dist'
  line_search = 'none'
[]

[Outputs]
  exodus = true
[]