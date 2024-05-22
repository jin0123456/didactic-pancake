## Units in the input file: m-Pa-s-K

[Mesh]
  [left_rectangle]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 40
    ny = 10
    xmax = 1
    ymin = 0
    ymax = 0.5
    boundary_name_prefix = moving_block
  []
  [left_block]
    type = SubdomainIDGenerator
    input = left_rectangle
    subdomain_id = 1
  []
  [right_rectangle]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 40
    ny = 10
    xmin = 1
    xmax = 2
    ymin = 0
    ymax = 0.5
    boundary_name_prefix = fixed_block
    boundary_id_offset = 4
  []
  [right_block]
    type = SubdomainIDGenerator
    input = right_rectangle
    subdomain_id = 2
  []
  [two_blocks]
    type = MeshCollectionGenerator
    inputs = 'left_block right_block'
  []
  [block_rename]
    type = RenameBlockGenerator
    input = two_blocks
    old_block = '1 2'
    new_block = 'left_block right_block'
  []
  [secondary]
    type = LowerDBlockFromSidesetGenerator
    sidesets = '7'
    new_block_id = 10001
    new_block_name = 'interface_secondary_subdomain'
    input = block_rename
  []
  [primary]
    type = LowerDBlockFromSidesetGenerator
    sidesets = '1'
    new_block_id = 10000
    new_block_name = 'interface_primary_subdomain'
    input = secondary
  []
  patch_update_strategy = iteration
[]

[Variables]
  [temperature]
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
[]
[Kernels]
  [HeatDiff_steel]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = steel_thermal_conductivity
    block = 'left_block'
  []
  [HeatTdot_steel]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = steel_heat_capacity
    density_name = steel_density
    block = 'left_block'
  []
  [HeatDiff_aluminum]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = aluminum_thermal_conductivity
    block = 'right_block'
  []
  [HeatTdot_aluminum]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = aluminum_heat_capacity
    density_name = aluminum_density
    block = 'right_block'
  []
[]

[BCs]
  [temperature_left]
    type = ADDirichletBC
    variable = temperature
    value = 300
    boundary = 'moving_block_left'
  []
  [temperature_right]
    type = ADDirichletBC
    variable = temperature
    value = 800
    boundary = 'fixed_block_right'
  []
[]

[Constraints]
  [ced]
    type = ModularGapConductanceConstraint
    variable = lm
    secondary_variable = temperature
    primary_boundary = moving_block_right
    primary_subdomain = interface_primary_subdomain
    secondary_boundary = fixed_block_left
    secondary_subdomain = interface_secondary_subdomain
    gap_flux_models = 'conduction radiation contact'
  []
[]

[Materials]
  [steel_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'steel_density steel_thermal_conductivity steel_heat_capacity steel_hardness'
    prop_values = ' 8e3            16.2                     0.5                 129' ## for stainless steel 304
    block = 'left_block'
  []
  [aluminum_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'aluminum_density aluminum_thermal_conductivity aluminum_heat_capacity aluminum_hardness'
    prop_values = ' 2.7e3            210                           0.9                   15' #for 99% pure Al
    block = 'right_block'
  []
[]

[UserObjects]
  [conduction]
    type = GapFluxModelConduction
    temperature = temperature
    boundary = moving_block_right
    gap_conductivity = 0.15
  []
  [radiation]
    type = GapFluxModelRadiation
    temperature = temperature
    boundary = moving_block_right
    primary_emissivity = 1.0
    secondary_emissivity = 0.5
    use_displaced_mesh = true
  []
  [contact]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = steel_thermal_conductivity
    secondary_conductivity = aluminum_thermal_conductivity
    temperature = temperature
    contact_pressure = contact_pressure
    primary_hardness = steel_hardness
    secondary_hardness = aluminum_hardness
    boundary = moving_block_right
  []
[]

[Postprocessors]
  [steel_pt_interface_temperature]
    type = NodalVariableValue
    nodeid = 245
    variable = temperature
  []
  [aluminum_pt_interface_temperature]
    type = NodalVariableValue
    nodeid = 657
    variable = temperature
  []
  [interface_heat_flux_steel]
    type = ADSideDiffusiveFluxAverage
    variable = temperature
    boundary = moving_block_right
    diffusivity = steel_thermal_conductivity
  []
  [interface_heat_flux_aluminum]
    type = ADSideDiffusiveFluxAverage
    variable = temperature
    boundary = fixed_block_left
    diffusivity = aluminum_thermal_conductivity
  []
[]

[MultiApps]
  [sub]
    type = TransientMultiApp
    input_files = closed_gap_mech.i
    positions = '0 0 0'
    sub_cycling = true
    execute_on = 'initial timestep_end'
  []
[]

[Transfers]
  [to_sub]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = temperature
    variable = temperature
    to_multi_app = sub
  []

  [from_sub_x]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = disp_x
    variable = disp_x
    from_multi_app = sub
  []
  [from_sub_y]
    type = MultiAppGeometricInterpolationTransfer
    source_variable = disp_y
    variable = disp_y
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
  solve_type = NEWTON
  automatic_scaling = false
  line_search = 'none'

  # mortar contact solver options
  petsc_options = '-snes_converged_reason -pc_svd_monitor'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = ' lu       superlu_dist'
  snesmf_reuse_base = false

  nl_rel_tol = 1e-8
  nl_max_its = 20
  l_max_its = 50

  dt = 2
  end_time = 10
[]

[Outputs]
  exodus = true
[]
