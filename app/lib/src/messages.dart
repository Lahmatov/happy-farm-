/// Server error texts are English identifiers; show Russian to the player.
const _ru = {
  'not enough coins': 'Не хватает монет',
  'level too low': 'Нужен уровень выше',
  'plot locked': 'Грядка закрыта',
  'plot busy': 'Грядка занята',
  'not ready': 'Ещё не созрело',
  'nothing planted': 'Здесь ничего не посажено',
  'nothing to steal': 'Красть пока нечего',
  'already stolen from this plot': 'Вы уже брали отсюда урожай',
  'plot picked clean': 'Тут уже всё растащили',
  'not friends': 'Вы не друзья',
  'user not found': 'Игрок не найден',
  'cannot befriend yourself': 'Нельзя дружить с самим собой',
  'cannot steal from yourself': 'Нельзя красть у себя',
  'unauthorized': 'Нужно войти заново',
  'bad plot': 'Нет такой грядки',
  'unknown crop': 'Неизвестная культура',
  'all plots unlocked': 'Все грядки уже куплены',
  'name taken': 'Это имя уже занято',
  'name must be 2-20 chars': 'Имя: от 2 до 20 символов',
};

String localize(String serverMessage) => _ru[serverMessage] ?? serverMessage;
