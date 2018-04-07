/* create_schema.sql
*  CSC 370 - Spring 2018
*  Matt Stewart V00218956
*/
-- Initialize tables (re-initialize if prior instances exist)
DROP TABLE IF EXISTS students CASCADE;
CREATE TABLE students(student_ID varchar(9) not null,
                      name varchar(255),
                      primary key(student_ID));

DROP TABLE IF EXISTS courses CASCADE;
CREATE TABLE courses(course_code varchar(10) primary key);

DROP TABLE IF EXISTS course_offerings CASCADE;
CREATE TABLE course_offerings(course_code varchar(10),
                              course_name varchar(128) not null,
                              term_code integer,
                              total_enrollment integer,
                              maximum_capacity integer 
				check (maximum_capacity >= 0 and 
					maximum_capacity >= total_enrollment),
                              instructor_name varchar(255) not null,
                              primary key(course_code, term_code),
                              foreign key(course_code)
                              references courses(course_code)
                                on delete restrict
                                on update cascade
                                deferrable);

DROP TABLE IF EXISTS prerequisites CASCADE;
CREATE TABLE prerequisites(course_code varchar(10),
                           term_code integer,
                           prerequisite varchar(10),
                           primary key(course_code, term_code, prerequisite),
                           foreign key(course_code, term_code)
                           references course_offerings(course_code, term_code)
                            on delete restrict
                            on update cascade
                            deferrable);

DROP TABLE IF EXISTS enrollment CASCADE;
CREATE TABLE enrollment(student_ID varchar(9) not null,
			name varchar(255),
                        course_code varchar(10),
                        term_code integer,
                        grade integer 
			  check (grade is null or (grade >= 0 and grade <= 100)),
                        primary key(student_ID,course_code,term_code),
                        foreign key(student_ID)
                        references students(student_ID)
                          on delete restrict
                          on update cascade
                          deferrable,
                        foreign key(course_code, term_code)
                        references course_offerings(course_code, term_code)
                          on delete restrict
                          on update cascade
                          deferrable);

-- Initialize constraints & triggers (re-initialize if prior instances exist)
-- Every course offering & prerequisite needs a valid course_code (i.e. appears in courses)
DROP FUNCTION IF EXISTS valid_course_trigger();
create function valid_course_trigger()
  returns trigger as
  $BODY$
  begin
  if (select count(*) from courses
    where course_code = new.course_code) < 1
  then
    raise exception 'Invalid course code';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger valid_course_constraint
  after insert or update on course_offerings
  deferrable
  for each row
  execute procedure valid_course_trigger();

create constraint trigger valid_prerequisite_constraint
  after insert or update on prerequisites
  deferrable
  for each row
  execute procedure valid_course_trigger();

-- Every student must fulfil prerequisite requirements when enrolling in course
-- TODO
DROP FUNCTION IF EXISTS prereq_check_trigger();
create function prereq_check_trigger()
  returns trigger as
  $BODY$
  begin
  if (with prereqs as (select prerequisite as course_code 
			from prerequisites 
          		where course_code = new.course_code and 
			term_code = new.term_code),
      student_prereqs as (select * from prereqs
        		    natural join
          		    enrollment
        		    where student_ID = new.student_ID)
      select count(*) from
	student_prereqs
      where (grade is not null and grade < 50)) > 0
      or
      (with prereqs as (select prerequisite as course_code 
			from prerequisites 
          		where course_code = new.course_code and 
			term_code = new.term_code),
       student_prereqs as (select course_code from prereqs
        		    natural join
          		    enrollment
        		    where student_ID = new.student_ID)
      select count(*) from prereqs 
      where not exists 
	(select 1 from student_prereqs 
	where student_prereqs.course_code = prereqs.course_code)) > 0
  then
    raise exception 'Prerequisites not satisfied';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger prereq_check_constraint
  after insert on enrollment
  deferrable
  for each row
  execute procedure prereq_check_trigger();

-- Every student enrolling in course must be valid (i.e. appears in students)
DROP FUNCTION IF EXISTS valid_student_trigger();
create function valid_student_trigger()
  returns trigger as
  $BODY$
  begin
  if (select count(*) from students
    where student_ID = new.student_ID) < 1
  then
    raise exception 'Invalid student ID';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger valid_student_constraint
  after insert or update on enrollment
  deferrable
  for each row
  execute procedure valid_student_trigger();

-- Students can only be removed from enrollment if they do not yet have a grade

DROP FUNCTION IF EXISTS grade_drop_trigger();
create function grade_drop_trigger()
  returns trigger as
  $BODY$
  begin
  if (select grade from enrollment
      where student_ID = old.student_ID and course_code = old.course_code and term_code = old.term_code) is not null
  then
    raise exception 'Student has received a grade';
  end if;
  return old;
  end
  $BODY$
  language plpgsql;

create trigger grade_drop_constraint
  before delete on enrollment
  for each row
  execute procedure grade_drop_trigger();

-- Enrolling a student in a course must succeed if the student is already in students, but must not insert a new student into students
DROP FUNCTION IF EXISTS add_student_trigger();
create function add_student_trigger()
  returns trigger as
  $BODY$
  begin
  if (select count(*) from students
      where student_ID = new.student_ID and name = new.name) > 0
  then
    return null;
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create trigger add_student_check
  before insert or update on students
  for each row
  execute procedure add_student_trigger();

-- Creating a new course offering must succeed if the course is already in courses, but must not insert a new course into courses
DROP FUNCTION IF EXISTS add_course_trigger();
create function add_course_trigger()
  returns trigger as
  $BODY$
  begin
  if (select count(*) from courses
      where course_code = new.course_code) > 0
  then
    return null;
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create trigger add_course_check
  before insert or update on courses
  for each row
  execute procedure add_course_trigger();
