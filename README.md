# mrKapibara_infra

<details><summary>01. Система контроля версий как основа разработки и поставки ПО. Знакомство с Git.</summary>
<p>
Ознакомительное задание про git [про гит](https://try.github.io/)
</p>
</details>

<details><summary>02. Локальное окружение инженера. ChatOps и визуализация рабочих процессов. Командная работа с Git. Работа в GitHub.</summary>
<p>

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

</p>
</details>

<details><summary>03. Знакомство с облачной инфраструктурой и облачными сервисами.</summary>
<p>
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

</p>
</details>

<details><summary>04. Основные сервисы Google Cloud Platform (GCP)</summary>
<p>


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
gcloud compute instances create reddit-app \
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

</p>
</details>

<details><summary>05. Модели управления инфраструктурой.</summary>
<p>

### Packer:

[Устанавливаем Packer](https://www.packer.io/downloads.html).

[Настраиваем GCP](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login) для работы с Packer:

    $ gcloud auth application-default login

Пишем шаблон [ubuntu 16](packer/ubuntu16.json) для создания образа Packer`ом, ключи можно посмотреть в [документации](https://www.packer.io/docs/). Важные переменные выносим в отдельный файл [variables.json.example](packer/variables.json.example).

Проверяем шаблон и собираем образ:

    $ packer validate -var-file=./packer/variables.json ./packer/ubuntu16.json &&
    packer build -var-file=./packer/variables.json ./packer/ubuntu16.json 

Посмотрим на созданные образы:

    $ gcloud compute images list --filter="family=( 'reddit-base' )"
    NAME                    PROJECT       FAMILY       DEPRECATED  STATUS
    reddit-base-1561565774  my-infra      reddit-base              READY

### Immutable infrastructure - Bake:

Теперь из имеющегося образа можно создать "bake" с нашим приложением. Для начала подготовим шаблон нашего сервиса [immutable.json](packer/immutable.json). Напишем [Unit-файл](packer/files/puma.service) для удобного управления сервисом, отредактируем скрипт развёртывания приложения [deploy.sh](packer/files/deploy.sh).

Напишем файл для запуска сервера из имеющегося образа: [create-reddit-vm.sh](config-scripts/create-reddit-vm.sh)

</p>
</details>

<details><summary>06. Практика Infrastructure as a Code (IaC).</summary>
<p>

### Terraform:

[Устанавливается, копированием одного файлика](https://www.terraform.io/downloads.html)

В проекте рекомендуется использовать имена файлов:
- main.tf - основной файл
- [variables.tf](https://www.terraform.io/docs/configuration/variables.html) - файл для переменных
- [outputs.tf](https://www.terraform.io/docs/configuration/outputs.html) - для вывода информации
- *.tf - файлы terraform загружающиеся при запуске

После создания файлов, в основной вносим информацию о [провайдере](https://www.terraform.io/docs/configuration/providers.html) и если требуется, версию:

    terraform {
    required_version = "0.11.11"
    }

    provider "google" {
    version = "2.0.0"
    project = "${var.project}"
    region  = "${var.region}"

после чего даём комманду терраформу, скачать необходимые для работы файлы: `terraform init`

Можно приступать к чтению [документации для GCP](https://www.terraform.io/docs/providers/google/)

Чувствительные переменные выносим в отдельный файл например имя пользователя и приватную часть ключа:

    connection {
      type        = "ssh"
      user        = "${var.ssh_user}"
      agent       = "false"
      private_key = "${file(var.private_key_path)}"

### Ключи для подключения:

Рекомендуется хранить ключи для подключения на уровне проекта:

    resource "google_compute_project_metadata" "reddit-app-ssh-keys" {
      metadata = {
        ssh-keys = "${var.ssh_user}:${file(var.public_key_path)} ${var.ssh_user}1:${file(var.public_key_path)} ${var.ssh_user}2:${file(var.public_key_path)}"
      }
    }

### Балансировщик:

Создадим отдельный файл для описания tcp балансировщика - [lb.tf](terraform/lb.tf)


Настроим правила проверки доступности порта "[health-check](https://www.terraform.io/docs/providers/google/r/compute_http_health_check.html)":


    resource "google_compute_http_health_check" "reddit-app-health-check" {
      name               = "reddit-app-health-check"
      check_interval_sec = 1
      timeout_sec        = 1
      port               = "9292"
    }


для удобства объединим все машины, в одну группу [https://www.terraform.io/docs/providers/google/r/compute_target_pool.html](https://cloud.google.com/load-balancing/docs/target-pools):


    resource "google_compute_target_pool" "reddit-app-pool" {
      name = "reddit-app-pool"
      instances = [
        "${google_compute_instance.reddit-app-instances.*.self_link}",
      ]
      health_checks = [
        "${google_compute_http_health_check.reddit-app-health-check.self_link}",
      ]
      region = "${var.region}"
    }


и настроим правила для маршрутизации пакетов "[forwarding-rules](https://www.terraform.io/docs/providers/google/r/compute_forwarding_rule.html)":

    resource "google_compute_forwarding_rule" "reddit-app-balancer" {
      name                  = "reddit-app-balancer"
      region                = "${var.region}"
      load_balancing_scheme = "EXTERNAL"
      ip_protocol           = "TCP"
      port_range            = "9292"
      network_tier = "STANDARD"
      target       = "${google_compute_target_pool.reddit-app-pool.self_link}"
    }

</p>
</details>
