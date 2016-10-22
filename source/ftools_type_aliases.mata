// Type aliases --------------------------------------------------------------

        // Numeric
        local Boolean                   real scalar
        local Integer                   real scalar
        local Real                      real scalar

        local Vector                    real colvector
        local RowVector                 real rowvector
        local Matrix                    real matrix

        // String
        local String                    string scalar

        local StringVector              string colvector
        local StringRowVector           string rowvector
        local StringMatrix              string matrix

        // Stata-specific
        local Varname                   string scalar
        local Varlist                   string rowvector // after tokens()

        local Variable                  real colvector // N * 1
        local Variables                 real matrix // N * K

        local DataRow                   transmorphic rowvector // 1 * K
        local DataCol                   transmorphic colvector // N * 1
        local DataFrame                 transmorphic matrix // N * K

        // Classes
        local Handle                    transmorphic scalar
        local Dict                      transmorphic scalar
        local Factor                    class Factor scalar
        local Anything                  transmorphic matrix
