# alexmarychev_infra
alexmarychev Infra repository

bastion_IP = 35.210.165.37
someinternalhost_IP = 10.132.0.3


Для того, чтобы подключиться к someinternalhost в одну команду я сделал следующее:

1. Сделал проброс с локальной машины до хоста bastion:
ssh -i ~/.ssh/alexmar -AL 2222:localhost:2222 35.210.165.37 -l alexmar

2. Сделал проброс с хоста bastion до хоста someinternal:
ssh -L 2222:localhost:22 10.132.0.3

Таким образом на someinternal можно попасть непосредственно с локальной машины:
ssh -p 2222 localhost

Для использования алиаса для подключения по ssh, я выполнил следующее:

1. Создал файл ~/.ssh/config
2. Записал туда:
	Host someinternalhost
	Port 2222
	HostName localhost
Таким образом, на someinternalhost можно попасть командой ssh someinternalhost


