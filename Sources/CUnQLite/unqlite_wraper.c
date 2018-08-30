//
//  unqlite_wraper.c
//  CUnQLite
//
//  Created by JLab13 on 8/28/18.
//  Copyright © 2018 Eugene Vorobkalo. All rights reserved.
//

#include "include/unqlite_wraper.h"

int unqlite_last_error(unqlite *p_db, char *buf[], int *len) {
    int rc = unqlite_config(p_db, UNQLITE_CONFIG_ERR_LOG, buf, len);
    if (*len > 0 && (*buf)[(*len) - 1] == '\n') {
        (*len)--;
    }
    return rc;
}
