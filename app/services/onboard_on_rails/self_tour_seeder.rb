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
      tour = find_or_create_tour(
        name: "Урок 1: Знакомство с панелью",
        description: "Обзор основных элементов панели управления турами.",
        url_pattern: ["/onboard/admin"],
        priority: 100
      )

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
        body: "В разделе 'Уроки' вы можете пройти обучающие туры и повторить их в любое время.",
        selector: ".oor-admin-nav__links",
        placement: "bottom"
      )
    end

    def create_lesson_2_create_tour
      tour = find_or_create_tour(
        name: "Урок 2: Создание тура",
        description: "Научитесь создавать и настраивать онбординг-тур с нуля.",
        url_pattern: ["/onboard/admin/tours/new"],
        priority: 99
      )

      create_step(tour, 1,
        title: "Название тура",
        body: "Введите понятное название для тура. Оно видно только в админке.",
        selector: "input[name='tour[name]']",
        placement: "bottom"
      )

      create_step(tour, 2,
        title: "Статус",
        body: "Черновик — тур не показывается. Активный — тур виден пользователям. В архиве — тур скрыт.",
        selector: "select[name='tour[status]']",
        placement: "bottom"
      )

      create_step(tour, 3,
        title: "URL паттерн",
        body: "Укажите на каких страницах показывать тур. Используйте * как подстановку: /dashboard/* покроет все подстраницы.",
        selector: "input[name='tour[url_pattern]']",
        placement: "bottom"
      )

      create_step(tour, 4,
        title: "Тема оформления",
        body: "Выберите как будет выглядеть тур: тултип (всплывающая подсказка), модальное окно, баннер или выдвижная панель.",
        selector: "select[name='tour[theme]']",
        placement: "bottom"
      )

      create_step(tour, 5,
        title: "Готово!",
        body: "После заполнения формы нажмите 'Создать тур'. Затем добавьте шаги — перейдите к Уроку 3.",
        selector: ".oor-form-actions",
        placement: "top"
      )
    end

    def create_lesson_3_configure_steps
      tour = find_or_create_tour(
        name: "Урок 3: Настройка шагов",
        description: "Узнайте как добавлять шаги к туру, выбирать элементы и настраивать стили.",
        url_pattern: ["/onboard/admin/tours/*/steps/new", "/onboard/admin/tours/*/steps/*/edit"],
        priority: 98
      )

      create_step(tour, 1,
        title: "Заголовок и текст",
        body: "Введите заголовок и описание шага. Текст поддерживает HTML для форматирования.",
        selector: "input[name='step[title]']",
        placement: "bottom"
      )

      create_step(tour, 2,
        title: "CSS селектор",
        body: "Укажите CSS селектор элемента, к которому привяжется подсказка. Нажмите 'Выбрать' для визуального выбора.",
        selector: "input[name='step[selector]']",
        placement: "bottom"
      )

      create_step(tour, 3,
        title: "Расположение",
        body: "Выберите где появится подсказка относительно элемента: сверху, снизу, слева, справа или по центру экрана.",
        selector: ".oor-placement-options",
        placement: "bottom"
      )

      create_step(tour, 4,
        title: "Стилизация",
        body: "Настройте цвета, шрифт и скругление углов. Изменения видны в предпросмотре справа в реальном времени.",
        selector: "h4",
        placement: "top"
      )
    end

    def find_or_create_tour(name:, description:, url_pattern:, priority:)
      Tour.find_or_create_by!(name: name) do |tour|
        tour.description = description
        tour.status = "active"
        tour.trigger_type = "auto"
        tour.url_pattern = url_pattern
        tour.frequency = "once"
        tour.theme = "tooltip"
        tour.priority = priority
        tour.ab_test_id = "self_tour"
      end
    end

    def create_step(tour, position, title:, body:, selector:, placement:)
      tour.steps.find_or_create_by!(position: position) do |step|
        step.title = title
        step.body = body
        step.selector = selector
        step.placement = placement
        step.action_type = "next"
      end
    end
  end
end
