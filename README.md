# Solving TSPs with Neighborhoods using MINLP

The code for `tspn.jl` is explained in my blog article on [opensourc.es](http://opensourc.es/blog/minlp-tspn)

To run it you have to download [Julia](https://julialang.org/downloads/) and install [JuMP](https://github.com/JuliaOpt/JuMP.jl), [Juniper](http://github.com/lanl-ansi/Juniper.jl),
[Ipopt](https://github.com/JuliaOpt/Ipopt.jl) and [Distances](https://github.com/JuliaStats/Distances.jl). 

You can use 
```
Pkg.add("JuMP")
Pkg.add("Junipper")
Pkg.add("Ipopt")
Pkg.add("Distances")
```

I visualized the problem using [d3](https://d3js.org).

