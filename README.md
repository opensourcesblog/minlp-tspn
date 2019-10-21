# Solving TSPs with Neighborhoods using MINLP

The code for `tspn.jl` is explained in my blog article on [opensourc.es](http://opensourc.es/blog/minlp-tspn)

To run it you have to download [Julia](https://julialang.org/downloads/) and install [JuMP](https://github.com/JuliaOpt/JuMP.jl), [Juniper](http://github.com/lanl-ansi/Juniper.jl),
[Ipopt](https://github.com/JuliaOpt/Ipopt.jl) and [Distances](https://github.com/JuliaStats/Distances.jl). 

You can use 
```
] add JuMP
] add Junipper
] add Ipopt
] add Distances

include("tspn.jl")
solve_tspn(;file_name="tspn_25", relax=false)
```

I visualized the problem using [d3](https://d3js.org).

