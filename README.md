Docker image som starter backupNAS via IPMI ved hjelp av en cron job.

Før docker image bygges må nl.sh kjøres:
chmod +x nl.sh
Deretter:
./nl.sh

før image bygges og kjøres:

 sudo docker build --rm -t backup-server .
 sudo docker run -d --name Ole-backupNAS-launcher --restart unless-stopped backup-server

 Slette image:
 sudo docker image rm -f backup-server

 Dersom docker ikke vil stoppe container kan docker restartes med:
 sudo systemctl restart docker.socket docker.service


 Oppsett for backup løsning:

 Timeplan:
 Hver dag ved midnatt: MAIN NAS tar snapshot av data. intisieres av en snapshot task av MAIN NAS.
 Første dag hver mnd 01:00: Docker image starter backup server.
 01:15: backup server henter alle nye snapshots fra MAIN NAS. Initsieres av backupserver
 02:00: Backup server starter shutdown script. Initsieres av backupserver
 ca 02:05: Backup server slår seg av. Så lenge scriptet lykkes.
