//
//  unqlite_wraper.c
//  CUnQLite
//
//  Created by JLab13 on 8/28/18.
//  Copyright © 2018 Eugene Vorobkalo. All rights reserved.
//

#include "include/unqlite_wraper.h"

int unqlite_config_err_log(unqlite *p_db, const int flag, char **buf, int *len) {
    int rc = unqlite_config(p_db, flag, buf, len);
    if (*len > 0 && (*buf)[(*len) - 1] == '\n') {
        (*len)--;
    }
    return rc;
}

int unqlite_vm_config_create_var(unqlite_vm *p_vm, const char *name, unqlite_value *val) {
    return unqlite_vm_config(p_vm, UNQLITE_VM_CONFIG_CREATE_VAR, name, val);
}

int unqlite_vm_config_output(unqlite_vm *p_vm, int (*p_fn)(void *p_output, unsigned int n_len, void *p_userdata),
                             void *p_userdata) {
    return unqlite_vm_config(p_vm, UNQLITE_VM_CONFIG_OUTPUT, p_fn, p_userdata);
}
