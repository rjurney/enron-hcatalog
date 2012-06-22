/* HCatalog */
register /usr/local/hcat/share/hcatalog/hcatalog-0.4.0.jar
register /home/hadoop/hive-0.9.0/lib/*.jar

/* Avro */
register /home/hadoop/pig-0.10.0/build/ivy/lib/Pig/avro-1.5.3.jar
register /home/hadoop/pig-0.10.0/build/ivy/lib/Pig/json-simple-1.1.jar
register /home/hadoop/pig-0.10.0/contrib/piggybank/java/piggybank.jar
register /home/hadoop/pig-0.10.0/build/ivy/lib/Pig/jackson-core-asl-1.7.3.jar
register /home/hadoop/pig-0.10.0/build/ivy/lib/Pig/jackson-mapper-asl-1.7.3.jar

define AvroStorage org.apache.pig.piggybank.storage.avro.AvroStorage();

/* Date rounding into weekly buckets */
define ISOToWeek org.apache.pig.piggybank.evaluation.datetime.truncate.ISOToWeek();

/* Cleanup the last run */
rmf /tmp/test

/* Load the enron emails from s3 */
emails = load 's3://rjurney.public/enron.avro' using AvroStorage();

/* Only include emails with both a from and at least one to address (some emails are only bcc) */
emails = filter emails by (from is not null) and (tos is not null);

/* Project all pairs and round to the week */
pairs = foreach emails generate from.(address) as from, 
                                FLATTEN(tos.(address)) as to, 
                                ISOToWeek(date) as week;

/* Count the emails between pairs per week */
from_to_weekly_counts = foreach (group pairs by (from, to, week) parallel 10) generate 
                                FLATTEN(group) as (from, to, week), 
                                COUNT_STAR($1) as total;

store from_to_weekly_counts into '/tmp/test';
