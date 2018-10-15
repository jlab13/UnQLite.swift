//
//  unqlite_wraper.h
//  CUnQLite
//
//  Created by JLab13 on 8/28/18.
//  Copyright © 2018 Eugene Vorobkalo. All rights reserved.
//

#ifndef unqlite_wraper_h
#define unqlite_wraper_h

#include "unqlite.h"

int unqlite_config_err_log(unqlite *p_db, const int flag, char **buf, int *len);
int unqlite_vm_config_create_var(unqlite_vm *p_vm, const char *name, unqlite_value *val);
int unqlite_vm_config_output(unqlite_vm *p_vm, int (*p_fn)(void *p_output, unsigned int n_len, void *p_userdata), void *p_userdata);

#endif /* unqlite_wraper_h */
