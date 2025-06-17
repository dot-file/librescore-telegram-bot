import telebot, subprocess, tempfile, os, pathlib
from telebot.util import quick_markup
from urllib.parse import urlparse

BOT_TOKEN = os.getenv("BOT_TOKEN")
LIBRESCORE_BIN = os.getenv("LIBRESCORE_BIN")

bot = telebot.TeleBot(BOT_TOKEN)


def is_valid_url(url: str):
    parsed_url = urlparse(url)
    return parsed_url.scheme and parsed_url.netloc


@bot.message_handler(commands=['start'])
def on_start_command(message):
    chat_id = message.chat.id

    bot.send_message(
        chat_id=chat_id,
        parse_mode="HTML",
        text='''
<b>Бот для скачивания нот с musescore.com</b>

Пришлите ссылку на страницу с нотами.
        ''',
    )


@bot.callback_query_handler(func=lambda call: True)
def on_any_callback_query(call):
    bot.answer_callback_query(call.id)

    call_data_splitted = call.data.split(' ')
    link = call_data_splitted[0]
    file_type = call_data_splitted[1]

    bot.send_message(
        chat_id=call.message.chat.id,
        parse_mode="HTML",
        text=f"Начинается загрузка формата <b>{file_type}</b>. Это может занять несколько минут.",
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        type_and_link_args = call.data
        command = f"{LIBRESCORE_BIN} -o {tmpdir} -i {link} -t {file_type}"

        proc = subprocess.Popen(
            command.split(' '),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )
        proc.wait()

        stdout = proc.stdout.read().decode()
        output_files = list(pathlib.Path(tmpdir).iterdir())

        if proc.returncode != 0 or "Done" not in stdout or not output_files:
            bot.send_message(
                chat_id=call.message.chat.id,
                text=f"Ошибка:\n{stdout}",
            )
            return

        with open(output_files[0], 'rb') as result_file:
            bot.send_document(
                chat_id=call.message.chat.id,
                parse_mode="HTML",
                document=result_file,
                caption=f"Файл в формате <b>{file_type}</b> со страницы: {link}",
            )


@bot.message_handler(func=lambda message: True, content_types=['text'])
def on_text_message(message):
    link = message.text

    if not is_valid_url(link):
        bot.send_message(
            chat_id=message.chat.id,
            parse_mode="HTML",
            text="Похоже, это не ссылка. Проверьте, есть ли в начале адреса сайта протокол подключения: <code>https://</code>.",
        )

        return

    types = [
        'pdf',
        'midi',
        'mp3',
    ]

    buttons = {t: {'callback_data': f"{link} {t}"} for t in types}

    reply_markup = quick_markup(buttons)

    bot.send_message(
        chat_id=message.chat.id,
        reply_markup=reply_markup,
        text=f'''
Выберите формат для скачивания со страницы: {link}
        ''',
    )


bot.polling(non_stop=True)
