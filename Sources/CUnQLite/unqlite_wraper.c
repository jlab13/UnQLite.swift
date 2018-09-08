//
//  unqlite_wraper.c
//  CUnQLite
//
//  Created by JLab13 on 8/28/18.
//  Copyright © 2018 Eugene Vorobkalo. All rights reserved.
//

#include "include/unqlite_wraper.h"

int unqlite_config_err_log(unqlite *p_db, char *buf[], int *len) {
    int rc = unqlite_config(p_db, UNQLITE_CONFIG_ERR_LOG, buf, len);
    if (*len > 0 && (*buf)[(*len) - 1] == '\n') {
        (*len)--;
    }
    return rc;
}

int unqlite_vm_config_create_var(unqlite *p_db, const char *name, unqlite_value *val) {
    return unqlite_config(p_db, UNQLITE_VM_CONFIG_CREATE_VAR, name, val);
}
