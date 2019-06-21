# mrKapibara_infra
<details><summary> Lab02. Локальное окружение инженера. ChatOps и визуализация рабочих процессов. Командная работа с Git. Работа в GitHub.</summary>
<p>
ChatOps:

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

<details><summary> Lab03. Знакомство с облачной инфраструктурой и облачными сервисами.</summary>
<p>

<details><summary>Поиграемся с gcloud</summary>
<p>

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

</p>
</details>

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

VPN:

[Устанавливаем Pritunl](https://docs.pritunl.com/docs/installation#section-linux-repositories)

Создаём правило для фаервола и применяем к хосту bastion

```
gcloud compute firewall-rules create pritunl --allow udp:15526 --target-tags pritunl
gcloud compute instance add-tags bastion --zone us-central1-c --tags pritunl
```

Lets encrypt для Pritunl:

В настройках Pritunl в поле `Lets Encrypt Domain` вводим: `34.66.166.158.sslip.io`, сохраняем настройки и обращаемся по адресу `https://34.66.166.158.sslip.io`. Теперь панелька секьюрна.

bastion_IP = 34.67.122.138  
someinternalhost_IP = 10.128.0.10  

</p>
</details>
