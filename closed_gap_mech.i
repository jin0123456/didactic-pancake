## Units in the input file: m-Pa-s-K

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

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
  patch_update_strategy = iteration
[]

[Variables]
  [disp_x]
    block = 'left_block right_block'
  []
  [disp_y]
    block = 'left_block right_block'
  []
  
[]

[AuxVariables]
  [temperature]
  []
[]
[Modules]
  [TensorMechanics/Master]
    [steel]
      strain = FINITE
      add_variables = false
      use_automatic_differentiation = true
      generate_output = 'strain_xx strain_xy strain_yy stress_xx stress_xy stress_yy'
      additional_generate_output = 'vonmises_stress'
      additional_material_output_family = 'MONOMIAL'
      additional_material_output_order = 'FIRST'
      eigenstrain_names = steel_thermal_expansion
      block = 'left_block'
    []
    [aluminum]
      strain = FINITE
      add_variables = false
      use_automatic_differentiation = true
      generate_output = 'strain_xx strain_xy strain_yy stress_xx stress_xy stress_yy'
      additional_generate_output = 'vonmises_stress'
      additional_material_output_family = 'MONOMIAL'
      additional_material_output_order = 'FIRST'
      eigenstrain_names = aluminum_thermal_expansion
      block = 'right_block'
    []
  []
[]

[BCs]
  [fixed_bottom_edge]
    type = ADDirichletBC
    variable = disp_y
    value = 0
    boundary = 'moving_block_bottom fixed_block_bottom'
  []
  [fixed_outer_edge]
    type = ADDirichletBC
    variable = disp_x
    value = 0
    boundary = 'fixed_block_right'
  []
  [displacement_left_block]
    type = ADFunctionDirichletBC
    variable = disp_x
    function = '2.0e-7*t'
    boundary = 'moving_block_left'
  []
[]

[Contact]
  [interface]
    primary = moving_block_right
    secondary = fixed_block_left
    model = frictionless
    formulation = mortar
    correct_edge_dropping = true
  []
[]


[Materials]
  [steel_elasticity_tensor]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 1.93e11 #in Pa, 193 GPa, stainless steel 304
    poissons_ratio = 0.29
    block = 'left_block'
  []
  [steel_stress]
    type = ADComputeFiniteStrainElasticStress
    block = 'left_block'
  []
  [steel_thermal_expansion]
    type = ADComputeThermalExpansionEigenstrain
    thermal_expansion_coeff = 17.3e-6 # stainless steel 304
    stress_free_temperature = 300.0
    temperature = temperature
    eigenstrain_name = 'steel_thermal_expansion'
    block = 'left_block'
  []

  [aluminum_elasticity_tensor]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 6.8e10 #in Pa, 68 GPa, aluminum
    poissons_ratio = 0.36
    block = 'right_block'
  []
  [aluminum_stress]
    type = ADComputeFiniteStrainElasticStress
    block = 'right_block'
  []
  [aluminum_thermal_expansion]
    type = ADComputeThermalExpansionEigenstrain
    thermal_expansion_coeff = 24.0e-6 # aluminum
    stress_free_temperature = 300.0
    temperature = temperature
    eigenstrain_name = 'aluminum_thermal_expansion'
    block = 'right_block'
  []
[]


[Postprocessors]
  [steel_element_interface_stress]
    type = ElementalVariableValue
    variable = vonmises_stress
    elementid = 199
  []
  [aluminum_element_interface_stress]
    type = ElementalVariableValue
    variable = vonmises_stress
    elementid = 560
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
