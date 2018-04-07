--TODO:
-- prereq check trigger
-- test test test

-- Drop all existing tables, start fresh
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS course_offerings CASCADE;
DROP TABLE IF EXISTS prerequisites CASCADE;
DROP TABLE IF EXISTS enrollment CASCADE;

-- Initialize tables
CREATE TABLE students(student_ID varchar(9) not null,
                      name varchar(255),
                      primary key(student_ID));

CREATE TABLE courses(course_code varchar(10) primary key);

CREATE TABLE course_offerings(course_code varchar(10),
                              course_name varchar(128) not null,
                              term_code integer,
                              total_enrollment integer,
                              maximum_capacity integer,
                              instructor_name varchar(255) not null,
                              primary key(course_code, term_code),
                              foreign key(course_code)
                              references courses(course_code)
                                on delete restrict
                                on update cascade
                                deferrable);

CREATE TABLE prerequisites(course_code varchar(10),
                           term_code integer,
                           prerequisite varchar(10),
                           primary key(course_code, term_code),
                           foreign key(course_code, term_code)
                           references course_offerings(course_code, term_code)
                            on delete restrict
                            on update cascade
                            deferrable);

CREATE TABLE enrollment(student_ID varchar(9) not null,
                        course_code varchar(10),
                        term_code integer,
                        grade integer,
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

-- Initialize constraints & triggers:
-- Every course offering & prerequisite needs a valid course_code (i.e. appears in courses)
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

-- Maximum_capacity can't be less than 0
create function negative_capacity_trigger()
  returns trigger as
  $BODY$
  begin
  if new.maximum_capacity < 0
  then
    raise exception 'Maximum capacity below 0';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger negative_capacity_constraint
  after insert or update on course_offerings
  deferrable
  for each row
  execute procedure negative_capacity_trigger();

-- Total_enrollment can't exceed maximum_capacity after a student is enrolled
create function capacity_exceeded_trigger()
  returns trigger as
  $BODY$
  begin
  if new.total_enrollment > new.maximum_capacity
  then
    raise exception 'Total enrollment exceeds maximum capacity';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger capacity_exceeded_constraint
  after insert or update on course_offerings
  deferrable
  for each row
  execute procedure capacity_exceeded_trigger();

-- Every student must fulfil prerequisite requirements when enrolling in course
-- TODO

-- Every student enrolling in course must be valid (i.e. appears in students)
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

-- Every student's grade must be either null or between 0 and 100 inclusive
create function valid_grade_trigger()
  returns trigger as
  $BODY$
  begin
  if new.grade is not null and (new.grade < 0 or new.grade > 100)
  then
    raise exception 'Invalid grade';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger valid_grade_constraint
  after insert or update on enrollment
  deferrable
  for each row
  execute procedure valid_grade_trigger();

-- Students can only be removed from enrollment if they do not yet have a grade
create function grade_drop_trigger()
  returns trigger as
  $BODY$
  begin
  if (select count(*) from enrollment
      where student_ID = new.student_ID and grade = not null) > 0
  then
    raise exception 'Student has received a grade';
  end if;
  return new;
  end
  $BODY$
  language plpgsql;

create constraint trigger grade_drop_constraint
  before delete on enrollment
  for each row
  execute procedure grade_drop_trigger();

-- Enrolling a student in a course must succeed if the student is already in students, but must not insert a new student into students
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

create constraint trigger add_student_check
  before insert or update on enrollment
  for each row
  execute procedure add_student_trigger();
