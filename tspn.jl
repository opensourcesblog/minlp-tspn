using Logging, JuMP, Juniper, Ipopt, Cbc, Distances

Logging.configure(level=ERROR)

file_name = "tspn_el_25"
f = open("./data/" * file_name);
lines = readlines(f)
N = length(lines)
println("N: ", N)

cx  = [0 for _ in 1:N]
cy  = [0 for _ in 1:N]
rx  = [0 for _ in 1:N]
ry  = [0 for _ in 1:N]

for i = 1:N
    x_str, y_str, rx_str, ry_str = split(lines[i])
    cx[i] = parse(Float64, x_str)
    cy[i] = parse(Float64, y_str)
    rx[i] = parse(Float64, rx_str)
    ry[i] = parse(Float64, ry_str)
end

println("cx: ", cx)
println("cy: ", cy)
println("cr: ", cr)

function get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;i=1,used=Dict{Int64,Bool}(),cycle_det=false,bcycle=false)
    idx = 0
    m_idx = 0
    for j = i+1:N
        if isapprox(x_vals[i,j]-1, 0, atol=1e-6)
            m_idx = 0
            if !haskey(used,j)
                idx = j
                used[j] = true
                to_vec[i] = string(j)
                x_vals[i,j] = 0
                objective += euclidean([px_vals[i],py_vals[i]],[px_vals[j],py_vals[j]])
                to_vec, objective, bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;i=idx,used=used,cycle_det=cycle_det,bcycle=bcycle)
                break
            end
        end
    end
    if idx == 0
        for j = 1:i-1
            if isapprox(x_vals[j,i]-1, 0, atol=1e-6)
                m_idx = 0
                if !haskey(used,j)
                    idx = j
                    used[j] = true
                    x_vals[i,j] = 0
                    to_vec[i] = string(j)
                    objective += euclidean([px_vals[i],py_vals[i]],[px_vals[j],py_vals[j]])
                    to_vec, objective, bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;i=idx,used=used,cycle_det=cycle_det,bcycle=bcycle)
                    break
                end
            end
        end
    end
    if idx == 0 && cycle_det
        for y=1:N
            if !isassigned(to_vec,y)
                return to_vec, objective, 1
            end
        end
        return to_vec, objective, bcycle
    end

    if idx == 0 
        for y=1:N
            if !isassigned(to_vec,y)
                to_vec, objective, bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;i=y,used=used,cycle_det=cycle_det,bcycle=bcycle)
                break
            end
        end
    end
    return to_vec, objective, bcycle
end

function solved(m)
    x_sparse = getvalue(x)

    x_vals = zeros(N,N)
    for i=1:N, j=i+1:N
        x_vals[i,j] = x_sparse[i,j]
    end

    # find cycle
    to_vec = Vector{String}(N)
    px_vals = getvalue(px)
    py_vals = getvalue(py)
    used = Dict{Int64,Bool}()
    objective = 0
    cycle_vars = Dict{Int64,Bool}()
    to_vec,obj, bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;cycle_det=true)
    if bcycle == 1
        first = true
        while length(cycle_vars) != N
            cycle_idx = Array{Int}(0)
            
            if !first
                # get next cycle
                found_another = 
                for y=1:N
                    if !haskey(cycle_vars,y)
                        push!(cycle_idx, y)
                        to_vec,obj,bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals;cycle_det=true,i=y)
                        break
                    end
                end
            else
                push!(cycle_idx, 1)
            end

            first = false
            while true
                idx = parse(Int64,to_vec[cycle_idx[end]])
                cycle_vars[idx] = true
                push!(cycle_idx, idx)
                if idx == cycle_idx[1]
                    break
                end
            end
            println("cycle_idx: ", cycle_idx)
            println("Length: ", length(cycle_idx)-1)
            sumx = 0
            last = cycle_idx[1]
            for i=2:length(cycle_idx)
                if last < cycle_idx[i]
                    sumx += x[last,cycle_idx[i]]
                else 
                    sumx += x[cycle_idx[i],last]
                end
                last = cycle_idx[i]
            end
        
            if length(cycle_idx)-1 < N
                @constraint(m, sumx <= length(cycle_idx)-2)
            end
        end
        return false
    end
    return true
end 

relax = false

if relax
    m = Model(solver=IpoptSolver(print_level=0))
else
    m = Model(solver=JuniperSolver(IpoptSolver(print_level=0);
        branch_strategy=:StrongPseudoCost))
end
@variable(m, x[f=1:N,t=f+1:N], Bin)
@variable(m, px[1:N]) 
@variable(m, py[1:N]) 
@NLobjective(m, Min, sum(x[f=i,t=j]*((px[i]-px[j])^2+(py[i]-py[j])^2) for i=1:N,j=i+1:N))
for i=1:N
    @constraint(m, sum(x[f=j,t=i] for j=1:i-1)+sum(x[f=i,t=j] for j=i+1:N) == 2)
end
@NLconstraint(m, inarea[i=1:N], sqrt((px[i]-cx[i])^2/rx[i]^2+(py[i]-cy[i])^2/ry[i]^2) <= 1)

start = time()
if relax 
    status = solve(m, relaxation=true)
    xs = getvalue(x)
    x_vals = -1*ones(N,N)
    for i=1:N, j=i+1:N
        x_vals[i,j] = xs[i,j]
    end
    for i = 1:N
        for v in x_vals[i,:]
            @printf("%.1f ", v)
        end
        print("\n")
    end
    error("1")
else
    status = solve(m)
end
# println(getvalue(x))
solves = 1

# error("1")
while !solved(m)
    status = solve(m)
    solves += 1
end
println("Solved in: ", time()-start)
println("Solves: ", solves)

if status == :Optimal
    optimal = 1
else
    optimal = 0
end
optimal = 0
open("./sol/" * file_name, "w") do file
    objective = 0
    to_vec = Vector{String}(N)
    x_sparse = getvalue(x)
    x_vals = zeros(N,N)
    for i=1:N, j=i+1:N
        x_vals[i,j] = x_sparse[i,j]
    end
    #=
    for i=1:N
        for j=1:N
            @printf("%.1f ", x_vals[i,j])
        end
        print("\n")
    end
    =#
    px_vals = getvalue(px)
    py_vals = getvalue(py)
    used = Dict{Int64,Bool}()
    to_vec, objective, bcycle = get_vec_and_obj(to_vec,objective,x_vals,px_vals,py_vals)
    println("Obj: ", objective)
    println("to_vec: ", to_vec)
    write(file, string(objective) * " " * string(optimal) * " " * string(N) * "\n")
    for j in 1:N
        write(file, string(px_vals[j])*","*string(py_vals[j]) * "\n")
    end
    write(file,  join(to_vec, " "))
end