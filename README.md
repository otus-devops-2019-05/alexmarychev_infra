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



