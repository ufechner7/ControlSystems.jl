# Length not defined for StateSpace, so use custom function
function Base.Test.test_approx_eq(va::StateSpace, vb::StateSpace, Eps, astr, bstr)
    fields = [:Ts, :nx, :ny, :nu, :inputnames, :outputnames, :statenames]
    for field in fields
        if getfield(va, field) != getfield(vb, field)
            return false
        end
    end
    diff = 0.0
    valfields = [:A, :B, :C, :D]
    for field in valfields
        mata = getfield(va, field)
        matb = getfield(vb, field)
        diff = max(diff, maximum(abs.(mata - matb)))
    end
    if !isnan(Eps) && !(diff <= Eps)
        sdiff = string("|", astr, " - ", bstr, "| <= ", Eps)
        return false
    end
    return true
end

Base.Test.test_approx_eq(va::StateSpace, vb::StateSpace, astr, bstr) =
    Base.Test.test_approx_eq(va, vb, 1E4*length(va.A)*max(Base.Test.array_eps(va.A),
    Base.Test.array_eps(vb.A)), astr, bstr)

# Length not defined for TransferFunction, so use custom function
Base.Test.test_approx_eq(a::TransferFunction, b::TransferFunction, meps, astr, bstr) = isapprox(a, b, rtol=meps)

Base.Test.test_approx_eq(a::TransferFunction, b::TransferFunction, astr, bstr) = (a ≈ b)

#Base.isapprox{T<:Number,N}(x::Array{T,N}, y::Array{T,N}; atol=sqrt(eps())) = all(abs.(x.-y) .< atol)


function run_tests(my_tests)
    @testset "All tests" begin
        for test in my_tests
            println(test)
            include("$(test).jl")
        end
    end
end

function vecarray(T::Type, ny::Int,nx::Int, args::AbstractArray...)
    if ny*nx != length(args)
        error("Number of vectors must fit dimensions")
    end
    array = reshape(collect(Array{T,1},args),nx,ny)
    permutedims(array,[2,1])
end
vecarray{T}(ny::Int,nx::Int, args::AbstractArray{T}...) = vecarray(T, ny, nx, args...)

function vecarray(ny::Int,nx::Int, args::AbstractArray...)
    args2 = promote(args...)
    vecarray(eltype(args2[1]), ny, nx, args2...)
end

# Sort a complex vector by real, breaking ties with imag
sortcomplex(a) = sort!(sort(a, by=imag), alg=MergeSort, by=real)
# Compare each vector in an array of vectors
macro test_array_vecs_eps(a, b, tol)
    quote
        @test size($(esc(a))) == size($(esc(b)))
        for (res, sol) = zip($(esc(a)), $(esc(b)))
            @test isapprox(sortcomplex(res), sol, atol=$(esc(tol)))
        end
    end
end

macro test_c2d(ex, sys_sol, mat_sol)
    quote
        sys, mat = $(esc(ex))
        @test sys ≈ $(esc(sys_sol))
        @test mat ≈ $(esc(mat_sol))
    end
end


approxin(el,col;kwargs...) = reduce(|,false,isapprox.(el,col;kwargs...))
approxsetequal(s1,s2;kwargs...) = all(approxin(p,s1;kwargs...) for p in s2) && all(approxin(p,s2;kwargs...) for p in s1)
