# alexmarychev_infra
alexmarychev Infra repository

bastion_IP = 35.210.165.37
someinternalhost_IP = 10.132.0.3

#HW3
Для того, чтобы подключиться к someinternalhost в одну команду я сделал следующее:

1. Сделал проброс с локальной машины до хоста bastion:
```ssh -i ~/.ssh/alexmar -AL 2222:localhost:2222 35.210.165.37 -l alexmar```

2. Сделал проброс с хоста bastion до хоста someinternal:
```ssh -L 2222:localhost:22 10.132.0.3```

Таким образом на someinternal можно попасть непосредственно с локальной машины:
```ssh -p 2222 localhost```

Для использования алиаса для подключения по ssh, я выполнил следующее:

1. Создал файл ```~/.ssh/config```
2. Записал туда:
```
Host someinternalhost
Port 2222
HostName localhost
```
Таким образом, на someinternalhost можно попасть командой ssh someinternalhost

########################################################################################

#HW4

testapp_IP = 34.76.71.121
testapp_port = 9292

1. Команда для передачи startup_script при создании инстанса:

```--metadata-from-file startup-script=startup_script.sh```

Таким образом, общая команда создания инстанса будет выглядить так:

```
gcloud compute instances create reddit-app \
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure \
--metadata-from-file startup-script=startup_script.sh
```

2. Команда для создания правила файерволла:

```
gcloud compute firewall-rules create default-puma-server \
--allow=tcp:9292 \
--target-tags=puma-server
```

##########################################################################################

#HW5

1. Установил Packer и создал шаблон ubuntu16.json

2. Создал файл с обязательными пользовательскими переменными variables.json:
```
"project_id": "infra-xxxxxx",
"source_image_family": "ubuntu-1604-lts"
```

3. Добавил в шаблон ubuntu16.json переменную ```"machine_type": "f1-micro"```

4. Добавил в шаблон ubuntu16.json следующие опции:
```
"disk_type": "pd-standard",
"disk_size": "10",
"network": "default",
"tags": "puma-server"
```

5. Создал шаблон immutable.json и скрипт install_puma (лежит в директории scripts) для создания образа с уже предустановленным приложением puma-server.

6. Создал скрипт create-redditvm.sh для создания инстанса с образом reddit-full.
 
##########################################################################################

#HW6

1. Установил Terraform и создал файл main.tf в котором описано создание инстанса с работающим приложением.

2. Создал файлы variables.tf, terraform.tfvars и outputs.tf для описания входных и исходящих переменных.

3. Создал с помощью Terraform несколько пользователей и добавил публичные ключи:
```
resource "google_compute_project_metadata_item" "default" {
  key = "ssh-keys"
  value = "appuser:${file(var.public_key_path)}appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key_path)}"
}
```
4. Добавил через веб-интерфейс ключ пользователя appuser-web. Проблема в том, что при изменении инфраструктуры с помощью Terraform, добавляются ключи описанные в нем, а созданные с помощью веб-интерфейса - удаляются.

5. Создал файл lb.tf и описал в нем создание балансировщика нагрузки, который направляет трафик на приложение на инстансах.

6. Описал в main.tf создание второго инстанса. Проверил работу приложения через балансировщик, при остановке одного инстанса. Проблема в том, что при добавлении нового инстанса приходится полностью описывать каждый, а это сильно затрудняет чтение конфигурации и увеличивает вероятность ошибок.

7. Описал создание нескольких инстансов через ```node_count```, создал переменную для измения этого параметра.

###########################################################################################

#HW7

1. Создал ресурсы файерволла и ip-адреса.

2. Разбил конфиг terraform на две VM

3. Создал модули для создания VM базы, VM приложения и правила файерволла.

4. Создал два storage-bucket

5. Настроил хранение стейт файла в удаленном бекенде. Для этого создал отдельный файл backend.tf с содержимым:
```
terraform {
  backend "gcs" {
    bucket = "tested-bucket-1"
  }
}
```
Для PROD и 
```
terraform {
  backend "gcs" {
    bucket = "tested-bucket-2"
  }
}
```
Для STAGE

tested-bucket-1 и tested-bucket-2 ранее содзданные storage-bucket

6. Добавил provisioners в модули app и db для того, чтобы при создании инстансов сразу же разворачивалось бы приложение. 

##модуль app:

###параметры соединения для запуска provisioners:
```
connection {
    type  = "ssh"
    user  = "alexmar"
    private_key = "${file(var.private_key_path)}"
    host  = "${google_compute_address.app_ip.address}"
  }
```
###сами provisioners:
```
provisioner "file" {
      source      = "../modules/app/files/deploy.sh"
      destination = "/tmp/deploy.sh"
  }

  provisioner "file" {
      source      = "../modules/app/files/puma.service"
      destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
      inline = [
        "sed 's/Environment=/Environment=DATABASE_URL=${var.db_ip}:27017/' /tmp/puma.service -i",
        "bash /tmp/deploy.sh",
      ]
  }
```
Сначала копируются файлы deploy.sh и puma.service, затем добавляем в юнит параметр с переменной окружения ```DATABASE_URL``` беря внутренний адрес БД из переменной ```var.db_ip```
Затем выполняется скрипт deploy.sh

##модуль db:

###параметры соединения для запуска provisioners:
```
connection {
    type  = "ssh"
    user  = "alexmar"
    private_key = "${file(var.private_key_path)}"
    host  = "${google_compute_instance.db.network_interface.0.access_config.0.nat_ip}"
  }
```

###сами provisioners:
```
provisioner "remote-exec" {
      inline = [
        "sudo sed 's/bindIp: 127.0.0.1/bindIp: ${google_compute_instance.db.network_interface.0.network_ip}/' /etc/mongod.conf -i",
        "sudo systemctl restart mongod",
      ]
  }
```
Заменяем в файле конфигурации /etc/mongod.conf ip-адрес локалхоста на назначенный внутренний адрес инстанса. Затем рестартуем сервис mongodb.

################################################################################################################################################

#HW8

1. Создал файл inventory с данными хостов app и db

2. Создал файл ansible.cfg с настройками ansible

3. Создал файл inventory.yml

4. Написал плейбук clone.yml

5. При выполнении ```ansible app -m command -a 'rm -rf ~/reddit'``` и новом запуске плейбука, мы видим, что changed=1. Это значит, что ansible что-то изменило на хосте, а именно создала удаленную нами директорию.

#####################################################################################################################################################

#HW9

1. Создал плейбуки со сценариями для приложения и MongoDB и шаблоны к ним

2. Создал плейбук со сценарием для деплоя приложения.

3. Создал главный плейбук для управления остальными.

4. Для использования динамического инвентори я использовал GCE dynamic inventory plugin. Для этого сначала установил библиотеку google-auth.
Затем в файле настроек ansible.cfg включил использование плагина gcp_compute:
```
[inventory]
enable_plugins = gcp_compute
```
Создал ключ сервисного аккаунта infra-xxxxxx.json.
Создал шаблон инвентарный файл inventory.gcp.yml (для тогоЮ чтобы не коммитить личную информацию создал пример файла inventory.gcp.yml.example). Указал в нем путь к ключу сервисного аккаунта и поля из которых брать ip для хостов:
```
plugin: gcp_compute
projects:
  - infra-xxxxxx
auth_kind: serviceaccount
service_account_file: /home/appuser/infra-xxxxxx.json
groups:
    app: "'reddit-app' in name"
    db: "'reddit-db' in name"
```

5. Изменил провижинги в пакере для использования ansible вместо скриптов.

6. Создал новые образы пакером.

#####################################################################################################################################################

#HW10

1. Создал две роли ansible app и db.

2. Реализовал вызов соответствующих ролей в плейбуках app и db.

3. Определил и сконфигурировал два окружения prod и stage.

4. Добавил вывод информации об окружении.

5. Установил роль jdauphant.nginx.

6. Добавил создание правила открытия порта 80 в файерволле через terraform.

7. Добавил вызов роли jdauphant.nginx в плейбук app.

8. Применил плейбук site.yml. Приложение доступно по адресу инстанса app на 80 порту.

9. Создал vault.key с ключом и вынес его за пределы репозитория.

10. Создал плейбук для создания юзеров users.yml.

11. Создал и зашифровал с помощью ansible-vault файл с данными пользователей credentials.yml.

12. Настроил использование динамического инвентори для окружений prod и stage аналогично предыдущему ДЗ. (С помощью GCE dynamic inventory plugin). Примеры инвентори файлов inventory.gcp.yml.example.

######################################################################################################################################################

#HW11

1. Установил Vagrant и создал VM.

2. Добавил провиженеры в Vagrand для роли db.

3. Создал плейбук base.yml и добавил в него установку python.

4. Доработал роль db для полной установки БД.

5. Доработал роль app и добавил ее в провиженеры Vagrant.

6. Для корректной работы проксирования приложения с помощью nginx я создал директорию group_vars в директории playbooks и добавил туда:
```
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
      proxy_pass http://127.0.0.1:9292;
      }
```
Лучшим вариантом вижу добавление этих переменных непосредственно в роль nginx, но, поскольку мы ее не коммитим, добавил сюда.

7. Установил molecula, создал тестовую конфигурацию, VM и прогнал тесты.

8. Написал тест к роли db для проверки того, что БД слушает по нужному порту (27017):
```
# check listen port
def test_listen_port(host):
    db = host.socket("tcp://0.0.0.0:27017")
    assert db.is_listening
```

9. Использовал роли app и db в шаблонах пакера.


