# add_drop.py
# CSC 370 - Spring 2018
#
# Matt Stewart V00218956
# Based on starter code by B. Bird - 02/26/2018

import sys, csv, psycopg2

if len(sys.argv) < 2:
	print("Usage: %s <input file>",file=sys.stderr)
	sys.exit(0)

input_filename = sys.argv[1]

# Open your DB connection here
psql_user = 'stewartm'
psql_db = 'stewartm'
psql_password = 'pineappleisokay'
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432

conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

with open(input_filename) as f:
	for row in csv.reader(f):
		if len(row) == 0:
			continue #Ignore blank rows
		if len(row) != 5:
			print("Error: Invalid input line \"%s\""%(','.join(row)), file=sys.stderr)
			#Maybe abort the active transaction and roll back at this point?
			conn.rollback()
			cursor.close()
			conn.close()
			exit()
		add_or_drop,student_id,student_name,course_code,term = row

		#Do something with the data here
		#Make sure to catch any exceptions that occur and roll back the transaction if a database error occurs.
		try:
			if add_or_drop == 'ADD':
				insert_statement = cursor.mogrify("""start transaction;
									insert into students values(%s,%s);
									insert into enrollment values(%s,%s,%s,%s,NULL);
									update course_offerings set total_enrollment = total_enrollment + 1 where course_code = %s and term_code = %s;
									commit;""",(student_id,student_name,student_id,student_name,course_code,term,course_code,term))
				cursor.execute(insert_statement)
			elif add_or_drop == 'DROP':
				insert_statement = cursor.mogrify("""start transaction;
				delete from enrollment
				  where student_ID = %s and course_code = %s and term_code = %s;
				update course_offerings set total_enrollment = total_enrollment - 1 
				  where course_code = %s and term_code = %s;
				commit;""",(student_id, course_code, term, course_code, term))
				cursor.execute(insert_statement)
			else:
				raise Exception
		except Exception as err:
			print("Error:",file=sys.stderr)
			print(err,file=sys.stderr)
			conn.rollback()

cursor.close()
conn.close()
