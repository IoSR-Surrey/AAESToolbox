function [C] = matrix_product(A,B)

    C = einsum('fik,fkj -> fij', A, B);
    
end