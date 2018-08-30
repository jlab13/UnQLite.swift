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

int unqlite_last_error(unqlite *p_db, char *buf[], int *len);

#endif /* unqlite_wraper_h */
