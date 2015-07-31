#!/bin/sh
USER="root"
DATABASE="test"
TABLE="test_2001"
VIEW="test"
STR=""

# drop view
DROP_SQL="DROP VIEW IF EXISTS $VIEW"
/data/mysql/bin/mysql -u$USER<<EOF
use $DATABASE;
$DROP_SQL;
EOF

#create view sql
for TNAME in `/data/mysql/bin/mysql -u$USER -e"SHOW TABLES FROM $DATABASE"`;do
	if [ $TNAME != "Tables_in_test" ];then
		COLUMN=""
		if [ ${#STR} -gt 0  ];then
			STR="${STR} UNION ALL "
		fi
		for CNAME in `/data/mysql/bin/mysql -u$USER -e"SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='$DATABASE' AND TABLE_NAME = '$TNAME'"`;do
			if [ $CNAME != "COLUMN_NAME" ];then
				if [ ${#COLUMN} -gt 0  ];then
					COLUMN="$COLUMN,"
				fi
				COLUMN="$COLUMN$CNAME"	
			fi
		done
		STR="${STR}SELECT $COLUMN FROM $TNAME"
	fi
done
CREATE_SQL="CREATE VIEW $VIEW AS $STR"

# create view
/data/mysql/bin/mysql -u$USER<<EOF
use $DATABASE;
$CREATE_SQL;
EOF
