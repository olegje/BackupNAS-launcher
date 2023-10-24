FROM ubuntu:20.04

RUN apt-get update && apt-get -y install cron
RUN apt-get install ipmitool -y
ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get install -y tzdata

# Copy cron file to the cron.d directory and script to home folder
COPY cronjobs /etc/cron.d/cronjobs
COPY Power-up.sh /home/Power-up.sh
 
# Give execution rights on the cron jobs and script
RUN chmod 0644 /etc/cron.d/cronjobs
RUN chmod 0744 /home/Power-up.sh
RUN chmod +x /home/Power-up.sh

# Apply cron job
RUN crontab /etc/cron.d/cronjobs
 
# Create the log file to be able to run tail
RUN touch /var/log/cron.log
 
# Run the command on container startup
CMD cron && tail -f /var/log/cron.log