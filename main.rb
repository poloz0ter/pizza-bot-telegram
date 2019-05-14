require 'telegram/bot'
require 'dotenv/load'

#Shop prices array
pepperoni = JSON.generate([{label: 'Pepperoni', amount: 69000}, {label: 'Доставка', amount: 15000}])
alfredo = JSON.generate([{label: 'Alfredo', amount: 87000}, {label: 'Доставка', amount: 15000}])
toscana = JSON.generate([{label: 'Toscana', amount: 88000}, {label: 'Доставка', amount: 15000}])
corrida = JSON.generate([{label: 'Corrida', amount: 80000}, {label: 'Доставка', amount: 15000}])
macho = JSON.generate([{label: 'Macho', amount: 99000}, {label: 'Доставка', amount: 15000}])
margarita = JSON.generate([{label: 'Margarita', amount: 55000}, {label: 'Доставка', amount: 15000}])

PIZZAS = [
  { title: 'Pepperoni', prices: pepperoni, photo_url: 'http://pinokiopizza.com/wp-content/uploads/2018/09/pizza-peperoni.png', description: 'Пицца — соус, Моцарелла, Пепперони'},
  { title: 'Alfredo', prices: alfredo, photo_url: 'http://pinokiopizza.com/wp-content/uploads/2018/09/%D0%BA%D1%83%D1%80%D0%B8%D1%86%D0%B0_%D0%B3%D1%80%D0%B8%D0%B1%D1%8B-%D0%BA%D0%BE%D0%BF%D0%B8%D1%8F-300x300.png', description: 'Соус альфредо, Сыр моцарелла, Шампиньоны, Куриное филе, Шпинат, Помидоры черри'},
  { title: 'Toscana', prices: toscana, photo_url: 'http://pinokiopizza.com/wp-content/uploads/2018/09/DRS_9269-300x300.jpg', description: 'Пицца — соус, Моцарелла ( в рассоле ), Оливковое масло, Руккола, Черри, Песто соус'},
  { title: 'Macho', prices: macho, photo_url: 'http://pinokiopizza.com/wp-content/uploads/2018/09/DRS_9310-300x300.jpg', description: 'Пицца — соус, Моцарелла ( в рассоле ), Оливковое масло, Руккола, Черри, Хамон, Бальзамический крем'},
  { title: 'Margarita', prices: margarita, photo_url: 'http://pinokiopizza.com/wp-content/uploads/2018/09/Margarita-300x300.png', description: 'Пицца — соус, Свежие помидоры, Моцарелла ( в рассоле ), Свежий базилик, Оливковое масло, Орегано'}
]

loop do
  Telegram::Bot::Client.run(ENV['BOT_TOKEN']) do |bot|
    bot.listen do |message|
      @admin_id = 1#190128633

      begin
        Thread.start(message) do |message|
          unless message.is_a?(Telegram::Bot::Types::CallbackQuery)
            
            case message.text
            when '/start', '/start start'
              welcome = "Добро пожаловать, #{message.from.first_name}!"
              
              if message.from.id == @admin_id
                actions = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Создать пост'], one_time_keyboard: true)
              else
                actions = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['🍕Сделать заказ', '📸Наш Instagram', ['🗺Мы на карте', '📞Контакты']], one_time_keyboard: true)
              end
              bot.api.send_message(chat_id: message.from.id, text: welcome, reply_markup: actions)

            when '🍕Сделать заказ'
              #Inline buttons for order
              prev_button = Telegram::Bot::Types::InlineKeyboardButton.new(text: '< Предыдущая', callback_data: 'prev')
              next_button = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Следующая >', callback_data: 'next')
              pay_button = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Заказать🛒', callback_data: 'pay')
              @inline_buttons = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [pay_button, [prev_button, next_button]])
              @position = 0

              photo_of_pizza = bot.api.send_photo(
                chat_id: message.from.id,
                photo: (PIZZAS[@position][:photo_url]),
                caption: (PIZZAS[@position][:description]),
                reply_markup: @inline_buttons)
              @photo_message_id = photo_of_pizza['result']['message_id']
            when '📸Наш Instagram'
              bot.api.send_message(chat_id: message.from.id, text: "Подписывайтесь на наш [инстаграм](https://www.instagram.com/pinokio_pizza/)!", parse_mode: "Markdown")
            when '📞Контакты'
              bot.api.send_message(chat_id: message.from.id, text: "**Бронь столика:**    ☎️68-58-58\n**Доставка:**             ☎️68-68-68", parse_mode: "Markdown")
            when '🗺Мы на карте'
              bot.api.send_venue(chat_id: message.from.id, title: 'Pinokio Pizza Bar', address: '2й километр осн. трассы, Магадан, Магаданская обл., Россия, 685007', latitude: 59.571278, longitude: 150.811452 )
            else
              bot.api.send_message(chat_id: message.from.id, text: "Используйте кнопки внизу 👇")
            end
          else
            if message.data == 'prev'
              if @position > 0
                @position -= 1
              else
                @position = PIZZAS.size - 1
              end  

              photo = JSON.generate({type: 'photo', media: (PIZZAS[@position][:photo_url]), caption: (PIZZAS[@position][:description])})
              bot.api.edit_message_media(chat_id: message.message.chat.id, message_id: @photo_message_id, media: photo, reply_markup: @inline_buttons)
            elsif message.data == 'next'
              if @position < PIZZAS.size - 1
                @position += 1
              else
                @position = 0
              end
              
              photo = JSON.generate({type: 'photo', media: (PIZZAS[@position][:photo_url]), caption: (PIZZAS[@position][:description])})
              bot.api.edit_message_media(chat_id: message.message.chat.id, message_id: @photo_message_id, media: photo, reply_markup: @inline_buttons)
            elsif message.data == 'pay'
              bot.api.send_invoice(
                chat_id: message.from.id,
                title: PIZZAS[@position][:title],
                description: (PIZZAS[@position][:description]),
                payload: '32',
                provider_token: (ENV['SBERBANK_TEST_TOKEN']),
                start_parameter: (0...8).map { (65 + rand(26)).chr }.join,
                currency: 'RUB',
                prices: (PIZZAS[@position][:prices]),
                photo_url: (PIZZAS[@position][:photo_url]),
                need_name: true,
                need_phone_number: true,
                need_shipping_address: true)  
            end
          end
        rescue Exception => e
          bot.api.send_message(chat_id: message.from.id, text: "Ошибка: #{e.message}\n#{self.class}")
        end
      end
    end
  end
end
