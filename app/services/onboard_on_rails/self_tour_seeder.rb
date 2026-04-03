module OnboardOnRails
  class SelfTourSeeder
    def self.seed!
      new.seed!
    end

    def seed!
      create_lesson_1_overview
      create_lesson_2_create_tour
      create_lesson_3_configure_steps
    end

    private

    def create_lesson_1_overview
      tour = upsert_tour(
        name: "Урок 1: Знакомство с панелью",
        description: "Обзор основных элементов панели управления турами.",
        url_pattern: ["/onboard/admin"],
        priority: 100
      )

      tour.steps.destroy_all

      create_step(tour, 1,
        title: "Добро пожаловать!",
        body: "Это панель управления OnboardOnRails. Здесь вы создаёте и управляете онбординг-турами для ваших пользователей.",
        selector: ".oor-admin-nav",
        placement: "bottom"
      )

      create_step(tour, 2,
        title: "Список туров",
        body: "Здесь отображаются все ваши туры. Вы можете фильтровать их по статусу: черновик, активный или в архиве.",
        selector: ".oor-page-header",
        placement: "bottom"
      )

      create_step(tour, 3,
        title: "Создание тура",
        body: "Нажмите эту кнопку чтобы создать новый тур. Вы сможете настроить название, URL-паттерн, триггер и тему оформления.",
        selector: ".oor-page-header__actions",
        placement: "left"
      )

      create_step(tour, 4,
        title: "Уроки",
        body: "В разделе 'Уроки' вы найдёте обучающие туры и сможете повторить их в любое время.",
        selector: ".oor-admin-nav__links",
        placement: "bottom"
      )
    end

    def create_lesson_2_create_tour
      tour = upsert_tour(
        name: "Урок 2: Создание тура",
        description: "Научитесь создавать и настраивать онбординг-тур с нуля.",
        url_pattern: ["/onboard/admin/tours/new"],
        priority: 99
      )

      tour.steps.destroy_all

      create_step(tour, 1,
        title: "Название тура",
        body: "Введите понятное название для тура. Оно видно только в админке и помогает отличать туры друг от друга.",
        selector: "input[name='tour[name]']",
        placement: "bottom"
      )

      create_step(tour, 2,
        title: "Статус тура",
        body: "<b>Черновик</b> — тур не показывается пользователям, можно спокойно редактировать.<br><b>Активный</b> — тур виден пользователям на целевых страницах.<br><b>В архиве</b> — тур скрыт, но данные сохранены.",
        selector: "select[name='tour[status]']",
        placement: "bottom"
      )

      create_step(tour, 3,
        title: "URL паттерн",
        body: "На каких страницах показывать тур. Примеры:<br><code>/dashboard</code> — точное совпадение<br><code>/dashboard/*</code> — все подстраницы<br><code>/projects/**</code> — любая вложенность",
        selector: "input[name='tour[url_pattern]']",
        placement: "bottom"
      )

      create_step(tour, 4,
        title: "Тема: Тултип",
        body: "Компактная всплывающая подсказка рядом с целевым элементом. Идеально для пошаговых инструкций, привязанных к конкретным кнопкам и полям.",
        selector: "select[name='tour[theme]']",
        placement: "bottom"
      )

      create_step(tour, 5,
        title: "Тема: Модальное окно",
        body: "Появляется по центру экрана поверх контента. Подходит для важных объявлений, приветственных сообщений и шагов, не привязанных к элементам.",
        selector: "select[name='tour[theme]']",
        placement: "bottom"
      )

      create_step(tour, 6,
        title: "Тема: Баннер",
        body: "Полоса внизу экрана на всю ширину. Хорош для ненавязчивых уведомлений и анонсов новых функций.",
        selector: "select[name='tour[theme]']",
        placement: "top"
      )

      create_step(tour, 7,
        title: "Тема: Выдвижная панель",
        body: "Панель справа на всю высоту экрана. Подходит для подробных инструкций с большим количеством текста.",
        selector: "select[name='tour[theme]']",
        placement: "left"
      )

      create_step(tour, 8,
        title: "Частота показа",
        body: "<b>Один раз</b> — тур покажется пользователю только один раз.<br><b>Каждая сессия</b> — раз за сессию браузера.<br><b>Всегда</b> — при каждом посещении страницы.",
        selector: "select[name='tour[frequency]']",
        placement: "bottom"
      )

      create_step(tour, 9,
        title: "Приоритет",
        body: "Если несколько туров подходят для одной страницы, покажется тур с наибольшим приоритетом. По умолчанию: 0.",
        selector: "input[name='tour[priority]']",
        placement: "bottom"
      )

      create_step(tour, 10,
        title: "Готово!",
        body: "Заполните форму и нажмите 'Создать тур'. После этого добавьте шаги — об этом расскажет Урок 3.",
        selector: ".oor-form-actions",
        placement: "top"
      )
    end

    def create_lesson_3_configure_steps
      tour = upsert_tour(
        name: "Урок 3: Настройка шагов",
        description: "Узнайте как добавлять шаги к туру, выбирать элементы и настраивать стили.",
        url_pattern: ["/onboard/admin/tours/*/steps/new", "/onboard/admin/tours/*/steps/*/edit"],
        priority: 98
      )

      tour.steps.destroy_all

      create_step(tour, 1,
        title: "Заголовок шага",
        body: "Введите короткий заголовок. Он отображается жирным шрифтом в верхней части подсказки.",
        selector: "input[name='step[title]']",
        placement: "bottom"
      )

      create_step(tour, 2,
        title: "Текст шага",
        body: "Опишите что пользователь должен сделать или на что обратить внимание. Поддерживается HTML: <code>&lt;b&gt;</code>, <code>&lt;br&gt;</code>, <code>&lt;a&gt;</code> и другие теги.",
        selector: "textarea[name='step[body]']",
        placement: "bottom"
      )

      create_step(tour, 3,
        title: "CSS селектор",
        body: "К какому элементу на странице привяжется подсказка. Примеры: <code>#header</code>, <code>.sidebar-nav</code>, <code>button.btn-primary</code>. Нажмите 'Выбрать' для визуального выбора элемента.",
        selector: "input[name='step[selector]']",
        placement: "bottom"
      )

      create_step(tour, 4,
        title: "Расположение",
        body: "Где появится подсказка относительно элемента:<br><b>Сверху/Снизу</b> — горизонтально<br><b>Слева/Справа</b> — вертикально<br><b>По центру</b> — модальное окно по центру экрана",
        selector: ".oor-placement-options",
        placement: "bottom"
      )

      create_step(tour, 5,
        title: "Стилизация",
        body: "Настройте внешний вид: цвет фона, текста, кнопок, шрифт и скругление углов. Изменения видны в предпросмотре справа.",
        selector: "h4",
        placement: "top"
      )
    end

    def upsert_tour(name:, description:, url_pattern:, priority:)
      tour = Tour.find_or_initialize_by(name: name)
      tour.assign_attributes(
        description: description,
        status: "active",
        trigger_type: "auto",
        url_pattern: url_pattern,
        frequency: "once",
        theme: "tooltip",
        priority: priority,
        ab_test_id: "self_tour"
      )
      tour.save!
      tour
    end

    def create_step(tour, position, title:, body:, selector:, placement:)
      tour.steps.create!(
        position: position,
        title: title,
        body: body,
        selector: selector,
        placement: placement,
        action_type: "next"
      )
    end
  end
end
