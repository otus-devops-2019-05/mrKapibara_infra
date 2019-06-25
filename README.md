# mrKapibara_infra

  testapp_IP = 104.198.71.233  
  testapp_port = 9292  

## Lab02. Локальное окружение инженера. ChatOps и визуализация рабочих процессов. Командная работа с Git. Работа в GitHub.</summary>

### ChatOps:

Для получения уведомлений будем использовать [Slack](https://slack.com/).   

[Подключаем GitHub в Slack](https://get.slack.help/hc/en-us/articles/232289568-GitHub-for-Slack)

Подключаем чат:

    /github subscribe <owner>/<repo> [feature] 

добавляем отправку оповещений из Travis CI в Slack   

[Travis CI:](https://travis-ci.org/)

За сборку и тестирование отвечает файл [.travis.yml](.travis.yml), добавляем его в проект

[Регистрируемся в системе](https://travis-ci.com/)  

Устанавливаем [ruby](https://www.ruby-lang.org/ru/documentation/installation/), [rubygems](https://rubygems.org/pages/download) и с помощью gem установить [travis](https://github.com/travis-ci/travis.rb#installation).  

[Авторизируемся через утилиту travis:](https://github.com/travis-ci/travis.rb#login)    

    travis login --com
[Шифруем пароль:](https://github.com/travis-ci/travis.rb#encrypt)  

    travis encrypt "<команда>:<токен>#<имя_канала>" --add notifications.slack.rooms --com

## Lab03. Знакомство с облачной инфраструктурой и облачными сервисами.

### Поиграемся с gcloud

Устанавливаем по [инструкции]("https://cloud.google.com/sdk/docs")

Авторизируемся в системе:
```
gcloud init
```
Создаём новый проект и переключаемся на него:
```
gcloud projects create infra-999999
gcloud config set project infra-999999
```
Сгенерируем ключи `ssh-keygen -t rsa -f ~/.ssh/gcloud-iowa-key1 -C gcloud-test-usr`,
Добавим приватный ключ в агент: `ssh-add ~/.ssh/gcloud-iowa-key1`
приведём публичную часть к виду:
```
[USERNAME]:ssh-rsa [KEY_VALUE] [USERNAME]
```
и добавим их в gcloud:

```
gcloud compute project-info add-metadata --metadata-from-file ssh-keys=~/.ssh/gcloud-iowa-key1.pub
```

Создаём инстансы:
```
gcloud compute instances create bastion --image-project ubuntu-os-cloud --image-family ubuntu-1604-lts  --zone us-central1-c --preemptible --machine-type f1-micro
...
gcloud compute instances create --image-project ubuntu-os-cloud --image-family ubuntu-1604-lts  --zone us-central1-c --preemptible --machine-type f1-micro --no-address
```
Открываем http & https на bastion:

```
gcloud compute instances add-tags bastion --tags http-server,https-server --zone us-central1-c
```
[документация](https://cloud.google.com/sdk/gcloud/reference/)

### SSH:

для удобного подключения 
добавляем в файл `~/.ssh/config` информацию о серверах:

```
Host bastion
  Hostname 34.66.166.158
  IdentityFile  ~/.ssh/gcloud-iowa-key1
  User gcloud-test-usr

Host someinternalhost
  Hostname 10.128.0.10
  IdentityFile  ~/.ssh/gcloud-iowa-key1
  ForwardAgent yes
  User gcloud-test-usr
  ProxyCommand ssh -W %h:%p gcloud-test-usr@bastion

```

теперь к someinternalhost можно подключиться командой: `ssh someinternalhost`

### VPN:

[Устанавливаем Pritunl](https://docs.pritunl.com/docs/installation#section-linux-repositories)

Создаём правило для фаервола и применяем к хосту bastion

```
gcloud compute firewall-rules create pritunl --allow udp:15526 --target-tags pritunl
gcloud compute instance add-tags bastion --zone us-central1-c --tags pritunl
```

### Lets encrypt для Pritunl:

В настройках Pritunl в поле `Lets Encrypt Domain` вводим: `34.66.166.158.sslip.io`, сохраняем настройки и обращаемся по адресу `https://34.66.166.158.sslip.io`. Теперь панелька секьюрна.

## Lab04. Основные сервисы Google Cloud Platform (GCP)</summary>


Написаны простейшие скрипты для установки [ruby](install_ruby.sh), [mogodb](install_mongodb.sh), [puma_app](deploy.sh) и объединены в один скрипт [startup-script](startup-script.sh)  

Пример отправки скрипта в GCP хранилище:

```
gsutil mb gs://gcloud-test-user-bckt/  
gsutil cp startup-script.sh gs://gcloud-test-user-bckt/
```

Создаём правило в фаерове:

```
gcloud compute firewall-rules create puma-port --allow=tcp:9292 --target-tags=puma
```
Создаём инстанс cо скриптом автозапуска и открываем порт: 

```
gcloud compute instances create reddit-app\            
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma \
  --restart-on-failure \
  --zone us-central1-c \
  --metadata startup-script-url=gs://gcloud-test-user-bckt/startup-script.sh
```

[Инструкция gsutil](https://cloud.google.com/storage/docs/quickstart-gsutil)
