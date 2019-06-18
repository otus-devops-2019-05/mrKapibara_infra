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
