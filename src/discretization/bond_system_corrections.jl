
"""
    NoCorrection <: AbstractCorrection

A correction handler for `AbstractBondSystemMaterial`s that does nothing. No correction
methods will apply and if someone tries to calculate a correction factor, they will be 1.
"""
struct NoCorrection <: AbstractCorrection end

function correction_type(::AbstractBondSystemMaterial{Correction}) where {Correction}
    return Correction
end

function get_correction(::AbstractBondSystemMaterial{NoCorrection}, ::Int, ::Int, ::Int)
    return NoCorrection()
end

@inline function surface_correction_factor(::NoCorrection, ::Int)
    return 1
end


#===========================================================================================
    ENERGY BASED SURFACE CORRECTION
===========================================================================================#

"""
    EnergySurfaceCorrection <: AbstractCorrection

A correction handler for `AbstractBondSystemMaterial`s that uses the strain energy density
to calculate surface correction factors.
"""
struct EnergySurfaceCorrection <: AbstractCorrection
    mfactor::Matrix{Float64} # multiplication factor mfactor[ndims, npoints]
    scfactor::Vector{Float64} # surface correction factor scfactor[nbonds]
end

function get_correction(::AbstractBondSystemMaterial{EnergySurfaceCorrection},
                        n_loc_points::Int, n_points::Int, n_bonds::Int)
    mfactor = zeros(3, n_points)
    scfactor = ones(n_bonds)
    return EnergySurfaceCorrection(mfactor, scfactor)
end

@inline function surface_correction_factor(correction::EnergySurfaceCorrection,
                                           bond_id::Int)
    return correction.scfactor[bond_id]
end

function initialize!(dh::AbstractThreadsDataHandler{BondSystem{EnergySurfaceCorrection}})
    @threads :static for chunk in dh.chunks
        calc_mfactor!(chunk)
    end
    @threads :static for chunk_id in eachindex(dh.chunks)
        exchange_loc_to_halo!(get_mfactor, dh, chunk_id)
        calc_scfactor!(dh.chunks[chunk_id])
    end
    return nothing
end

function initialize!(dh::AbstractMPIDataHandler{BondSystem{EnergySurfaceCorrection}})
    calc_mfactor!(dh.chunk)
    exchange_loc_to_halo!(get_mfactor, dh)
    calc_scfactor!(dh.chunk)
    return nothing
end

function calc_mfactor!(chunk::AbstractBodyChunk{BondSystem{EnergySurfaceCorrection}})
    system = chunk.system
    mfactor = system.correction.mfactor
    stendens = zeros(3, n_points)
    for d in 1:3
        defposition .= copy(system.position)
        defposition[d,:] .*= 1.001
        @views calc_stendens!(stendens[d,:], defposition, chunk)
        for i in each_point_idx(chunk)
            param = get_params(chunk, i)
            mfactor[d,i] = 0.5 * param.G * 1e-6 / stendens[d,i]
        end
    end
    return nothing
end

function calc_stendens!(stendens, defposition, chunk)
    system = chunk.system
    for i in each_point_idx(chunk)
        param = get_params(chunk, i)
        temp = 15 * param.G /(2π * param.δ * param.δ * param.δ * param.δ)
        for bond_id in each_bond_idx(system, i)
            bond = system.bonds[bond_id]
            j, L = bond.neighbor, bond.length
            Δxijx = defposition[1, j] - defposition[1, i]
            Δxijy = defposition[2, j] - defposition[2, i]
            Δxijz = defposition[3, j] - defposition[3, i]
            l = sqrt(Δxijx * Δxijx + Δxijy * Δxijy + Δxijz * Δxijz)
            ε = (l - L) / L
            stendens[i] += temp * ε * ε * L * system.volume[j]
        end
    end
    return nothing
end

@inline get_mfactor(chunk::AbstractBodyChunk) = chunk.system.correction.mfactor

function calc_scfactor!(chunk::AbstractBodyChunk)
    system = chunk.system
    scfactor = system.correction.scfactor
    for i in each_point_idx(chunk)
        for bond_id in each_bond_idx(system, i)
            bond = system.bonds[bond_id]
            j, L = bond.neighbor, bond.length
            Δxijx = system.position[1, j] - system.position[1, i]
            Δxijy = system.position[2, j] - system.position[2, i]
            Δxijz = system.position[3, j] - system.position[3, i]
            if abs(Δxijz) <= 1e-10
                if abs(Δxijy) <= 1e-10
                    θ = 0.0
                elseif abs(Δxijx) <= 1e-10
                    θ = 90 * π / 180
                else
                    θ = atan(abs(Δxijy)/abs(Δxijx))
                end
                ϕ = 90 * π / 180
                scx = (h[1,i] + h[1,j]) / 2
                scy = (h[2,i] + h[2,j]) / 2
                scz = (h[3,i] + h[3,j]) / 2
                scr = sqrt(
                    1/(
                        (cos(θ) * sin(ϕ))^2 / scx^2 +
                        (sin(θ) * sin(ϕ))^2 / scy^2 +
                        cos(ϕ)^2 / scz^2
                    )
                )
            elseif abs(Δxijx) <= 1e-10 && abs(Δxijy) <= 1e-10
                scz = (h[3,i] + h[3,j]) / 2
                scr = scz
            else
                θ = atan(abs(Δxijy)/abs(Δxijx))
                ϕ = acos(abs(Δxijz)/L)
                scx = (h[1,i] + h[1,j]) / 2
                scy = (h[2,i] + h[2,j]) / 2
                scz = (h[3,i] + h[3,j]) / 2
                scr = sqrt(
                    1/(
                        (cos(θ) * sin(ϕ))^2 / scx^2 +
                        (sin(θ) * sin(ϕ))^2 / scy^2 +
                        cos(ϕ)^2 / scz^2
                    )
                )
            end
            scfactor[bond_id] = scr
        end
    end
    return nothing
end
