function update_vel_half!(b::AbstractBodyChunk, Δt½::Float64)
    _update_vel_half!(b.store.velocity_half, b.store.velocity, b.store.acceleration, Δt½,
                      each_point_idx(b))
    return nothing
end

function _update_vel_half!(velocity_half, velocity, acceleration, Δt½, each_point)
    for i in each_point
        velocity_half[1, i] = velocity[1, i] + acceleration[1, i] * Δt½
        velocity_half[2, i] = velocity[2, i] + acceleration[2, i] * Δt½
        velocity_half[3, i] = velocity[3, i] + acceleration[3, i] * Δt½
    end
    return nothing
end

function update_disp_and_pos!(b::AbstractBodyChunk, Δt::Float64)
    _update_disp_and_pos!(b.store.displacement, b.store.position, b.store.velocity_half, Δt,
                          each_point_idx(b))
    return nothing
end

function _update_disp_and_pos!(displacement, position, velocity_half, Δt, each_point)
    for i in each_point
        u_x = velocity_half[1, i] * Δt
        u_y = velocity_half[2, i] * Δt
        u_z = velocity_half[3, i] * Δt
        displacement[1, i] += u_x
        displacement[2, i] += u_y
        displacement[3, i] += u_z
        position[1, i] += u_x
        position[2, i] += u_y
        position[3, i] += u_z
    end
    return nothing
end

function update_acc_and_vel!(b::BodyChunk, Δt½::Float64)
    _update_acc_and_vel!(b.store.acceleration, b.store.b_int, b.store.b_ext,
                         b.store.velocity_half, b.store.velocity, b.param.rho, Δt½,
                         each_point_idx(b))
    return nothing
end

function update_acc_and_vel!(b::MultiParamBodyChunk, Δt½::Float64)
    s = b.store
    for i in each_point
        param = get_param(b, i)
        _update_acc!(s.acceleration, s.b_int, s.b_ext, param.rho, i)
        _update_vel!(s.velocity, s.velocity_half, s.acceleration, Δt½, i)
    end
    return nothing
end

function _update_acc_and_vel!(acc, b_int, b_ext, vel_half, vel, rho, Δt½, each_point)
    for i in each_point
        _update_acc!(acc, b_int, b_ext, rho, i)
        _update_vel!(vel, vel_half, acc, Δt½, i)
    end
    return nothing
end

function _update_acc!(acceleration, b_int, b_ext, rho, i)
    acceleration[1, i] = (b_int[1, i] + b_ext[1, i]) / rho
    acceleration[2, i] = (b_int[2, i] + b_ext[2, i]) / rho
    acceleration[3, i] = (b_int[3, i] + b_ext[3, i]) / rho
    return nothing
end

function _update_vel!(velocity, velocity_half, acceleration, Δt½, i)
    velocity[1, i] = velocity_half[1, i] + acceleration[1, i] * Δt½
    velocity[2, i] = velocity_half[2, i] + acceleration[2, i] * Δt½
    velocity[3, i] = velocity_half[3, i] + acceleration[3, i] * Δt½
    return nothing
end

function solve!(dh::ThreadsDataHandler, vv::VelocityVerlet, options::ExportOptions)
    _export_results(dh, options, 0, 0.0)

    Δt = vv.Δt
    Δt½ = 0.5 * vv.Δt
    p = Progress(vv.n_steps; dt=1, desc="solve...", color=:normal, barlen=20,
                 enabled=progress_enabled())
    for n in 1:vv.n_steps
        t = n * Δt
        @threads :static for chunk_id in eachindex(dh.chunks)
            body_chunk = dh.chunks[chunk_id]
            update_vel_half!(body_chunk, Δt½)
            apply_bcs!(body_chunk, t)
            update_disp_and_pos!(body_chunk, Δt)
        end
        @threads :static for chunk_id in eachindex(dh.chunks)
            halo_exchange!(dh, chunk_id)
            body_chunk = dh.chunks[chunk_id]
            calc_force_density!(body_chunk)
            calc_damage!(body_chunk)
            update_acc_and_vel!(body_chunk, Δt½)
        end
        export_results(dh, options, n, t)
        next!(p)
    end
    finish!(p)

    return dh
end