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

<details><summary>07. Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform.</summary>
<p>

#### Импорт существующих ресурсов.
Для добавления действующего ресурса в файл terraform.tfstate сначало его необходимо описать в конфигурации, затем выполнить команду [terraform import](https://www.terraform.io/docs/import/).

#### Взаимосвязи ресурсов.
- неявная: когда ресурc terraform'а ссылается на объект внутри другого ресурса `'nat_ip = "${google_compute_address.reddit-app-ip.address}"'`
- явная: в описании ресурса присутствует ссылка на другой ресурс  - `"depends_on = [
      "google_compute_instance.reddit-db",
  ]"`

#### Работа с модулями:

Модули позволяют разделять ресурсы и облегчают управление ими. Инфраструктура разбита на 3 модуля:
- [app](terraform/modules/app) - web часть сервиса
- [db](terraform/modules/db) - модуль для работы с базами данных
- [vpc](terraform/modules/vpc) - модуль для управления доступом к проекту

После написания модулей их необходимо загрузить командой `terraform get`.
Настроим отображение выходных переменных из модулей:
```
output "app-external-ip" {
  value = "${module.app.reddit-app-external-ip}"
}
```
Пример вызова локального модуля c передачей в него переменных:
```
module "vpc" {
  source          = "../modules/vpc"
  ssh_user        = "${var.ssh_user}"
  public_key_path = "${var.public_key_path}"
}
```

#### Работа с реестром модулей

Пример вызова модуля [storage-bucket](https://registry.terraform.io/modules/SweetOps/storage-bucket/google/0.2.0) из [Terraform Module Registry](https://registry.terraform.io/) для создания бакета, где будем хранить .tfstate файл.
```
module "storage-bucket" {
  source = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name = ["${var.bucket-name}", "${var.bucket-name}2"]
}
```

#### Хранение стейт файла в удаленном бекенде
В GCP за хранение файла в удаленном реестре отвечает модуль [gcs](https://www.terraform.io/docs/backends/types/gcs.html)
```
terraform {
  backend "gcs" {
    bucket = "devops-otust-example-bckt"
    prefix = "infra/stage"
  }
}
```
для применения необходимо запустить процесс инициализации. После этого файл tfstate будет Находиться в удалённом хранилище. Модуль gcs поддерживает [блокировку](https://www.terraform.io/docs/state/locking.html) во время приминения конфигуации.

#### После разделения свервиса на разные хосты настроим компоненты:
На сервере с приложением добавим в [unit-файл](terraform/modules/app/puma.service) адрес сервера с базой данных:
```
...
ExecStart=/usr/local/bin/puma
Environment=DATABASE_URL=reddit-app-db:27017
...
```
В тераформе "provisioner file" не может перемещать файлы в директории, требующие повышенных привилегий, для перемещения воспользуемся раннее написанным скриптом:
```
  provisioner "file" {
    source      = "../modules/app/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "../modules/app/deploy.sh"
  }
}
```

Настроим базу данных на прослушивание нужного адреса.

Передадим в [шаблон](https://www.terraform.io/docs/providers/template/d/file.html) переменную с адресом хоста и отправим полученный файл на сервер:
```
data "template_file" "init" {
  template = "${file("../modules/db/mongod.conf.tpl")}"

  vars = {
    reddit-db-ip = "${google_compute_address.reddit-db-ip.address}"
  }
}
resource "google_compute_instance" "reddit-db-instances" {
  ...
  provisioner "file" {
  content     = "${data.template_file.init.rendered}"
  destination = "/tmp/mongod.conf"  
  }
  ...
}
```
В этот раз переместим файл с помощью простых комманд:
```
...
  provisioner "remote-exec" {
    inline = [
      "sudo mv -f /tmp/mongod.conf /etc/mongod.conf",
      "sudo systemctl restart mongod.service",
    ]
  }
...
```
</p>
</details>

<details><summary>08. Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible.</summary>
<p>

# Ansible

## Установка:
Из pip:

    pip install ansible
Также доступна из пакетов.

## Настройка:

В стандартном варианте работает на Python2, это можно изменить, установив:

    ansible_python_interpreter=/usr/bin/python3

Общие настройки для локального проека можно хранить в файле [ansible.cfg](ansible/ansible.cfg)

[Документация по переменным](https://docs.ansible.com/ansible/devel/reference_appendices/config.html#ansible-configuration-settings)


Описание управляемых хостов хранится в inventory файле, в форматах [.ini](ansible/inventory.ini) [.yml](ansible/inventory.yml), [.json](ansible/inventory.json) также есть возможность использовать JSON формат , из [динамического inventory файла](https://docs.ansible.com/ansible/2.8/dev_guide/developing_inventory.html).

Для взаимодействия с управляемыми машинами используются [модули](https://docs.ansible.com/ansible/2.8/modules/modules_by_category.html).
запуск модуля ping из командной строки:

    ansible all  -i inventory -m ping

[playbook](ansible/clone.yml) пишется на языке yaml:

    ---
    - name: Clone
      hosts: appservers
      tasks:
      - name: Clone repo
        git:
          repo: https://github.com/express42/reddit.git
          dest: /opt/reddit
          force: yes

Запуск плейбука:

    ansible-playbook --syntax-check clone.yml

Пример зпуска, без применения тзменений `dry run`:

    ansible-playbook --check --diff clone.yml

## Динамический inventory файл

Написан простой [скрипт](ansible/inventory.py) для сбора информации с локального .tfstate файла, согласно [документации](https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#id1)
вывод должен быть в формате:

    {
    "_meta": {
      "hostvars": {}
    },
    "all": {
      "children": [
        "ungrouped"
      ]
    },
    "ungrouped": {
      "children": [
      ]
    }
}

[пример вывода скрипта](ansible/dynamic_inventory.json)

</p>
</details>
<details><summary>09. Продолжение знакомства с Ansible: templates, handlers, dynamic inventory, vault, tags.</summary>
<p>

# Ansible: templates, handlers, dynamic inventory, vault, tags

## templates:
В качестве шаблонизатора в ansible выступает [jinja2](http://jinja.pocoo.org/docs/2.10/).
пример подстановки простой переменной:
назначаем переменную:

    vars:
      mongod_bind_ip: "0.0.0.0"
Для рендерига шаблона используется модуль [template](https://docs.ansible.com/ansible/latest/modules/template_module.html)

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /opt/db_config
Внутри шаблона можно установить дэфолтные значения

    port: {{ mongod_port | default('27017') }}
    bindIp: {{ mongod_bind_ip }}
Также можно получить информацию из [фактов](https://docs.ansible.com/ansible/latest/modules/setup_module.html). Например получить первый аддресс в группе серверов 'reddit-db-instances':

    {{ groups['reddit-db-instances'] | map('extract', hostvars, ['ansible_default_ipv4', 'address']) | first }}

[Документация по переменнм в ansible](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)

## handlers
Хэндлеры выполняются после всех задач в сценарии, по одному разу. Чтобы изменить это поведение, можно вызвать команду `flush_handlers`, в этом случае выполнятся все хэндлеры незамедлительно.

    - name: Run handlers
      meta: flush_handlers

## dynamic inventory:
[Документация](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)

[Скрипт](ansible/inventory.py) собирающий информацию из локального или удалённого tfstate файла. В таком варианте получаем во время запуска всегда актуальную инфраструктуру, имена ресурсов в тераформе преобразуются в название групп для ansible.

## vault 
`ansible-vault` Используется для шифрования важных данных. Запускаются такие задачи с ключами `--ask-vault-pass`, `--vault-id`, `--vault-password-file /path/to/file`. Так же можно исполькозать переменную `ANSIBLE_VAULT_PASSWORD_FILE`

[Документация](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vault.html)

## tags
С помощью тегов можно можно определять какие задачи запускать и на каких хостах.

### Packer
За установкой пакетов в пакере теперь будет отвечать Ansible.
Напишем плейбуки для [app](ansible/app.yml ) и [db](ansible/db.yml) шаблонов и приведём к секцию `provisioners` к виду:

    "provisioners": [
      {
          "type": "ansible",
          "playbook_file": "ansible/packer_app.yml",
          "host_alias": "app-packer"
      }

</p>
</details>
<details><summary>10. Принципы организации кода для управления конфигурацией.</summary>

# Принципы организации кода для управления конфигурацией

## Роли:
Роли в Ansible позволяют разделить таски, хэндлеры, переменные, шаблоныб файлы по отдельным задачам в роли и в дальнейшем переиспользовать их.

Создадим отдельную диреторию для ролей `roles` внутри `ansible`.
Для создания скелета роли выполняем комманду `ansible-galaxy ini app`

Задачи разбиваются по такому принцыпу:

    ├── defaults      # Переменные по умолчанию
    │   └── main.yml
    ├── files         # Статические файлы
    ├── handlers      # Хэндлеры
    │   └── main.yml
    ├── tasks         # Задачи
    │   └── main.yml  
    ├── templates     # Шаблоны
    └── vars          # Переменные
        └── main.yml

Разделим окружени по разным директориям [stage](ansible/environment/stage), [prod](ansible/environment/prod). И вынесим переменные в отдельную директорию group_vars

## Ansible Galaxy
[Ansible Galaxy](https://galaxy.ansible.com) - репозиторий комьюнити ролей, которые можно [установить](https://galaxy.ansible.com/docs/using/installing.html)


## Ansible Vault

[Ansible Vault](https://docs.ansible.com/ansible/devel/user_guide/vault.html) используется для шифрования данных.

    ansible-vault encrypt <file_name> # Зашифровать файл
    ansible-vault edit <file_name>    # Отредактировать шифрованный файл
    ansible-vault decrypt <file_name> # Расшифровать файл

Добавляем путь до ключа шифрования в [ansible.cfg](ansible/ansible.cfg)

    [defaults]
    ...
    vault_password_file = path/to/vault.key

## TravisCI

Добавим проверки в Travis. Выполнять проверки будем с помощью модуля [testinfra](https://testinfra.readthedocs.io/en/latest/). Напсан [shell-script](tests/run.sh) для установки зависимостей и запуска [тестов](tests/infra_tests.py): Packer, ansible-lint, terraform.

Для запуска скрипта внутри имеющегося контейнера, добавим в файл [.travis.yml](.travis.yml) строку:

    before_install:
    ...
    - docker exec hw-test bash -c './tests/run.sh'

</details>

<details><summary>11. Локальная разработка Ansible ролей с Vagrant. Тестирование конфигурации.</summary>
<p>

## Vagrant
Описание машин, создаваемых вагрантом находится в файле [Vagrantfile](ansible/Vagrantfile). Вагрант поддерживает разных [провайдеров](https://www.vagrantup.com/docs/providers/) для управления машинами. Также имеется большой выбор [провижнеров](https://www.vagrantup.com/docs/provisioning/).

[Документация](https://www.vagrantup.com/docs/index.html)

## Molecule
Используется для тестирования ansible ролей 
устанавливается из pip, пример для gcloud: `pip install 'molecule[gce]'`
Создает скелет тестов при инициализации: `molecule init scenario --scenario-name default -r　<rolename> -d gce`

    molecule
    └── default
    ├── create.yml
    ├── destroy.yml
    ├── INSTALL.rst
    ├── molecule.yml
    ├── playbook.yml
    ├── prepare.yml
    └── tests
        └── test_default.py

настройка производится в файле [molecule.yml](https://github.com/mrKapibara/ansible-role-with-travis/blob/master/molecule/default/molecule.yml)

Тесты лежат в директории [test](https://github.com/mrKapibara/ansible-role-with-travis/tree/master/molecule/default/tests) внутри созданной директории molecule

[Документация](https://molecule.readthedocs.io/en/stable/)

## Travis CI

#### Переменные для запуска тестов Molecule в GCP
##### Файл с учетными данными нужно создать в gcp
    travis encrypt GCE_SERVICE_ACCOUNT_EMAIL='<email>' --add
    travis encrypt GCE_PROJECT_ID='<project-id>' --add

#### Упаковываем файлы
    tar cvf secrets.tar credentials.json google_compute_engine
#### Шифруем архив
    travis encrypt-file secrets.tar --add

[.travis.yml](https://github.com/mrKapibara/ansible-role-with-travis/blob/master/.travis.yml) после добавления



</p>
</details>
