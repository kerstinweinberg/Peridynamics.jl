using Test
using SafeTestsets

@testset "Peridynamics" verbose=true begin

    # unit tests
    @safetestset "PointCloud" begin include(joinpath("unit_tests","PointCloud.jl")) end
    @safetestset "PreCrack" begin include(joinpath("unit_tests","PreCrack.jl")) end
    @safetestset "MultiMaterial" begin include(joinpath("unit_tests","MultiMaterial.jl")) end
    @safetestset "ForceDensityBC" begin include(joinpath("unit_tests","ForceDensityBC.jl")) end
    @safetestset "PosDepVelBC" begin include(joinpath("unit_tests","PosDepVelBC.jl")) end
    @safetestset "VelocityBC" begin include(joinpath("unit_tests","VelocityBC.jl")) end
    @safetestset "VelocityIC" begin include(joinpath("unit_tests","VelocityIC.jl")) end
    @safetestset "Contact" begin include(joinpath("unit_tests","Contact.jl")) end
    @safetestset "BodySetup" begin include(joinpath("unit_tests","BodySetup.jl")) end
    @safetestset "PDSingleBodyAnalysis" begin include(joinpath("unit_tests","PDSingleBodyAnalysis.jl")) end
    @safetestset "PDContactAnalysis" begin include(joinpath("unit_tests","PDContactAnalysis.jl")) end
    @safetestset "TimeDiscretization" begin include(joinpath("unit_tests","TimeDiscretization.jl")) end
    @safetestset "ExportSettings" begin include(joinpath("unit_tests","ExportSettings.jl")) end
    @safetestset "BondBasedMaterial" begin include(joinpath("unit_tests","BondBasedMaterial.jl")) end
    @safetestset "sphere_radius" begin include(joinpath("unit_tests","sphere_radius.jl")) end
    @safetestset "pcmerge" begin include(joinpath("unit_tests","pcmerge.jl")) end
    @safetestset "define_precrack!" begin include(joinpath("unit_tests","define_precrack!.jl")) end
    @safetestset "defaultdist" begin include(joinpath("unit_tests","defaultdist.jl")) end
    @safetestset "export_vtk" begin include(joinpath("unit_tests","export_vtk.jl")) end
    @safetestset "calc_stable_timestep" begin include(joinpath("unit_tests","calc_stable_timestep.jl")) end
    @safetestset "calc_stable_user_timestep" begin include(joinpath("unit_tests","calc_stable_user_timestep.jl")) end
    @safetestset "velocity_verlet!" begin include(joinpath("unit_tests","velocity_verlet!.jl")) end
    @safetestset "dynamic_relaxation_finite_difference!" begin include(joinpath("unit_tests","dynamic_relaxation_finite_difference!.jl")) end

    # integration tests
    @safetestset "Symmetry tests BondBasedMaterial" begin include(joinpath("integration_tests","symmetry_bond_based.jl")) end
    @safetestset "Symmetry tests ContinuumBasedMaterial" begin include(joinpath("integration_tests","symmetry_continuum_based.jl")) end
    @safetestset "Bonds" begin include(joinpath("integration_tests","bonds.jl")) end
    @safetestset "Force density calculation BondBased" begin include(joinpath("integration_tests","b_int_bond_based.jl")) end
    @safetestset "create_simmodel BondBased" begin include(joinpath("integration_tests","create_simmodel_bond_based.jl")) end
    @safetestset "Contact example 4 points" begin include(joinpath("integration_tests","contact_example_4p.jl")) end

    # VtkReader
    @safetestset "read_vtk" begin include(joinpath("VtkReader","read_vtk.jl")) end

    # AbaqusMeshConverter
    @safetestset "midpoint" begin include(joinpath("AbaqusMeshConverter","midpoint.jl")) end
    @safetestset "tetvol" begin include(joinpath("AbaqusMeshConverter","tetvol.jl")) end
    @safetestset "get_points" begin include(joinpath("AbaqusMeshConverter","get_points.jl")) end
    @safetestset "read_inp" begin include(joinpath("AbaqusMeshConverter","read_inp.jl")) end

end
