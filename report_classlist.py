# report_classlist.py
# CSC 370 - Spring 2018
#
# Matt Stewart V00218956
# Based on starter code by B. Bird - 02/26/2018

import psycopg2, sys

def print_header(course_code, course_name, term, instructor_name):
	print("Class list for %s (%s)"%(str(course_code), str(course_name)) )
	print("  Term %s"%(str(term), ) )
	print("  Instructor: %s"%(str(instructor_name), ) )

def print_row(student_id, student_name, grade):
	if grade is not None:
		print("%10s %-25s   GRADE: %s"%(str(student_id), str(student_name), str(grade)) )
	else:
		print("%10s %-25s"%(str(student_id), str(student_name),) )

def print_footer(total_enrolled, max_capacity):
	print("%s/%s students enrolled"%(str(total_enrolled),str(max_capacity)) )

if len(sys.argv) < 3:
	print('Usage: %s <course code> <term>'%sys.argv[0], file=sys.stderr)
	sys.exit(0)

course_code, term = sys.argv[1:3]

psql_user = 'stewartm' #Change this to your username
psql_db = 'stewartm' #Change this to your personal DB name
psql_password = 'pineappleisokay' #Put your password (as a string) here
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432

conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

#The .execute method sends one or more SQL statements to the server.
try:
	insert_statement = cursor.mogrify("""select course_name, instructor_name, total_enrollment, maximum_capacity from course_offerings
					  	where course_code = %s and term_code = %s;
				   		""", (course_code, term) )
	cursor.execute(insert_statement)
	course = cursor.fetchone()
	print_header(course_code, course[0], term, course[1])
	total = course[2]
	maximum = course[3]

	insert_statement = cursor.mogrify("""select student_ID, name, grade
										from course_offerings natural join enrollment natural join students
										where course_code = %s and term_code = %s
										order by student_ID;
						""", (course_code, term))
	cursor.execute(insert_statement)

	while True:
		row = cursor.fetchone()
		if row is None:
			break
		print_row(row[0],row[1],row[2])

	print_footer(total,maximum)

except Exception as err:
	print("Error:",file=sys.stderr)
	print(err,file=sys.stderr)
	exit()

cursor.close()
conn.close()

# Mockup: Print a class list for CSC 370
#course_code = 'CSC 370'
#course_name = 'Database Systems'
#course_term = 201801
#instructor_name = 'Bill Bird'
#print_header(course_code, course_name, course_term, instructor_name)

#Print records for a few students
#print_row('V00123456', 'Rebecca Raspberry', 81)
#print_row('V00123457', 'Alissa Aubergine', 90)
#print_row('V00123458', 'Neal Naranja', 83)

#Print the last line (enrollment/max_capacity)
#print_footer(3,150)
