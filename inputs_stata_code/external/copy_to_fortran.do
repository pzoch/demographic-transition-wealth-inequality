foreach f in _data_Nn_US_1935_2100.txt _data_Nn_US_1935_init_old.txt _data_rho_1935.txt {
    capture copy "external/`f'" "../fortran_code/Data/`f'", replace
}
