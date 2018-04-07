# report_enrollment.py
# CSC 370 - Spring 2018
#
# Matt Stewart V00218956
# Based on starter code by B. Bird - 02/26/2018

import psycopg2, sys

def print_row(term, course_code, course_name, instructor_name, total_enrollment, maximum_capacity):
	print("%6s %10s %-35s %-25s %s/%s"%(str(term), str(course_code), str(course_name), str(instructor_name), str(total_enrollment), str(maximum_capacity)) )

import psycopg2

psql_user = 'stewartm' #Change this to your username
psql_db = 'stewartm' #Change this to your personal DB name
psql_password = 'pineappleisokay' #Put your password (as a string) here
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432

conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

#The .execute method sends one or more SQL statements to the server.

cursor.execute("""select term_code, course_code, course_name, instructor_name, total_enrollment, maximum_capacity from course_offerings
					  order by term_code, course_code;
			   """ )

while True:
	row = cursor.fetchone()
	if row is None:
		break
	print_row(row[0],row[1],row[2],row[3],row[4],row[5])

cursor.close()
conn.close()

# Mockup: Print some data for a few made up classes
#
#print_row(201709, 'CSC 106', 'The Practice of Computer Science', 'Bill Bird', 203, 215)
#print_row(201709, 'CSC 110', 'Fundamentals of Programming: I', 'Jens Weber', 166, 200)
#print_row(201801, 'CSC 370', 'Database Systems', 'Bill Bird', 146, 150)
