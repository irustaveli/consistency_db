Шаг 1 - Установка Бармена
Для этого вам сначала необходимо установить следующие репозитории:

- Дополнительные пакеты для репозитория Enterprise Linux (EPEL)

- RPM-репозиторий PostgreSQL Global Development Group

Выполните следующую команду для установки EPEL:
sudo yum -y install epel-release

Запустите эти команды для установки репозитория PostgreSQL:
sudo wget http://yum.postgresql.org/version_intasll_pgsql/redhat/rhel-7Server-x86_64/version_intasll_pgsql
sudo rpm -ivh version_intasll_pgsql

Наконец, запустите эту команду для установки Barman:
sudo yum -y install barman

Шаг 2 - Настройка SSH-соединения между серверами
Для соединения между сервером PostgreSQL и Barman необходимо сгенерировать ключи.
Пример с PostgreSQL:
sudo su - postgres
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
Вывод: "author_keys_postgressql"
chmod 700 ~/.ssh
echo "author_keys_barman" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

Пример с Barman:
sudo su - barman
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
Вывод: "author_keys_barman"
chmod 700 ~/.ssh
echo "author_keys_postgressql" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

Шаг 3 - Настройка Barman для резервного копирования
sudo vi /etc/barman.conf

Выдержки из /etc/barman.conf
[barman]
barman_home = /var/lib/barman

. . .

barman_user = barman
log_file = /var/log/barman/barman.log
compression = gzip
reuse_backup = link

. . .

immediate_checkpoint = true

. . .

basebackup_retry_times = 3
basebackup_retry_sleep = 30
last_backup_maximum_age = 1 DAYS

. . .

[name_db_server]
description = "Main DB Server"
ssh_command = ssh postgres@
conninfo = host= user=postgres
retention_policy_mode = auto
retention_policy = RECOVERY WINDOW OF  days
wal_retention_policy = main

Шаг 4 - Настройка файла postgresql.conf
На сервере Barman переключитесь на пользователя * barman *:
sudo su - barman

Запустить эту команду, чтобы найти каталог для входящей резервной копии:
barman show-server main-db-server | grep incoming_wals_directory

Это должно вывести что-то вроде этого:
barman show-server command out put: "incoming_wals_directory": /var/lib/barman/main-db-server/incoming

Переключиться на сервер с PostgreSQL
Переключитесь на пользователя * postgres *, если он еще не является текущим пользователем.
Откройте файл postgresql.conf в текстовом редакторе:
vi $PGDATA/postgresql.conf

Выдержки из postgresql.conf
wal_level = archive                     # minimal, archive, hot_standby, or logical

. . .

archive_mode = on               # allows archiving to be done

. . .

archive_command = 'rsync -a %p barman@barman-backup-server-ip:"incoming_wals_directory"%f'   # command to use to archive a logfile segment

Перезапустить PostgreSQL.

Шаг 5 - Тестирование Бармена
Переключиться на сервер с Barman
barman check

Если все в порядке, вывод должен выглядеть так:
barman check command outputServer main-db-server:
       PostgreSQL: OK
       archive_mode: OK
       wal_level: OK
       archive_command: OK
       continuous archiving: OK
       directories: OK
       retention policy settings: OK
       backup maximum age: FAILED (interval provided: 1 day, latest backup age: No available backups)
       compression settings: OK
       minimum redundancy requirements: OK (have 0 backups, expected at least 0)
       ssh: OK (PostgreSQL server)
       not in recovery: OK

Чтобы получить список серверов PostgreSQL, настроенных с помощью Barman, выполните следующую команду:
barman list-server
Вывод:
main-db-server - Main DB Server

Шаг 6 - Планирование резервного копирования
crontab -e

30 03 * * * /usr/bin/barman backup
* * * * * /usr/bin/barman cron

Шаг 7 - Настройка на проверку целостности резервной копии БД
Файл "check_backup_consistency.py" необходимо поместить в директорию Barman
/var/lib/barman
Далее настроить Планирование
crontab -e

00 10 * * * /usr/bin/python /var/lib/barman/check_backup_consistency.py >> ~/cron.log 2>&1

Шаг 8 - Настройка Zabbix и Zabbix-agent для мониторинга целостности резервной копии
Из каталога "zabbix_agent" скопировать конфигурационные файлы в директорию где установлен zabbix_agent

Из каталога "zabbix_templates" загрузить на сервер с Zabbix шаблон с проверкой целостности резервной копии

Все примеры с мониторинга находятся в каталоге "images"
Пример выгрузки по целостности находится в каталоге "example_data"






