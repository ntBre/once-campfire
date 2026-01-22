module EmojiHelper
  # Quick reactions shown in the reactions menu
  QUICK_REACTIONS = {
    "👍" => "Thumbs up",
    "👏" => "Clapping",
    "👋" => "Waving hand",
    "💪" => "Muscle",
    "❤️" => "Red heart",
    "😂" => "Face with tears of joy",
    "🎉" => "Party popper",
    "🔥" => "Fire"
  }

  # Returns standard emojis grouped by category from the gemoji gem
  def standard_emojis
    @standard_emojis ||= Gemoji.emojis.group_by { |emoji| emoji.category || "Other" }
  end

  # Legacy emoji picker structure (kept for backward compatibility during transition)
  EMOJI_PICKER = {
    "Smileys" => {
      "😀" => "Grinning face",
      "😃" => "Grinning face with big eyes",
      "😄" => "Grinning face with smiling eyes",
      "😁" => "Beaming face with smiling eyes",
      "😆" => "Grinning squinting face",
      "😅" => "Grinning face with sweat",
      "🤣" => "Rolling on the floor laughing",
      "😂" => "Face with tears of joy",
      "🙂" => "Slightly smiling face",
      "🙃" => "Upside down face",
      "😉" => "Winking face",
      "😊" => "Smiling face with smiling eyes",
      "😇" => "Smiling face with halo",
      "🥰" => "Smiling face with hearts",
      "😍" => "Smiling face with heart eyes",
      "🤩" => "Star struck",
      "😘" => "Kissing face with heart eyes",
      "😗" => "Kissing face",
      "😚" => "Kissing face with closed eyes",
      "😙" => "Kissing face with smiling eyes"
    },
    "Hand Gestures" => {
      "👋" => "Waving hand",
      "🤚" => "Raised back of hand",
      "🖐️" => "Hand with fingers splayed",
      "✋" => "Raised hand",
      "🖖" => "Vulcan salute",
      "👌" => "OK hand",
      "🤌" => "Pinched fingers",
      "🤏" => "Pinching hand",
      "✌️" => "Victory hand",
      "🤞" => "Crossed fingers",
      "🫱" => "Rightwards hand",
      "🫲" => "Leftwards hand",
      "🤟" => "Love you gesture",
      "🤘" => "Sign of the horns",
      "🤙" => "Call me hand",
      "👍" => "Thumbs up",
      "👎" => "Thumbs down",
      "✊" => "Raised fist",
      "👊" => "Oncoming fist",
      "👏" => "Clapping hands"
    },
    "People" => {
      "💪" => "Muscle",
      "🦾" => "Mechanical arm",
      "🦿" => "Mechanical leg",
      "🦵" => "Leg",
      "🦶" => "Foot",
      "👂" => "Ear",
      "👃" => "Nose",
      "🧠" => "Brain",
      "🦷" => "Tooth",
      "🦴" => "Bone",
      "🎂" => "Birthday cake",
      "🎈" => "Balloon",
      "🎉" => "Party popper",
      "🎊" => "Confetti ball",
      "🎁" => "Wrapped gift"
    },
    "Hearts & Love" => {
      "❤️" => "Red heart",
      "🧡" => "Orange heart",
      "💛" => "Yellow heart",
      "💚" => "Green heart",
      "💙" => "Blue heart",
      "💜" => "Purple heart",
      "🖤" => "Black heart",
      "🤍" => "White heart",
      "🤎" => "Brown heart",
      "🤝" => "Handshake",
      "💋" => "Kiss mark",
      "💞" => "Revolving hearts",
      "💕" => "Two hearts",
      "💓" => "Beating heart",
      "💗" => "Growing heart"
    },
    "Symbols" => {
      "✨" => "Sparkles",
      "⭐" => "Star",
      "🌟" => "Glowing star",
      "💫" => "Dizzy",
      "⚡" => "High voltage",
      "🔥" => "Fire",
      "💥" => "Collision",
      "🌈" => "Rainbow",
      "☀️" => "Sun",
      "🌙" => "Moon",
      "👍" => "Thumbs up",
      "🎯" => "Direct hit",
      "🚀" => "Rocket",
      "⚙️" => "Gear",
      "💡" => "Light bulb"
    },
    "Nature" => {
      "🌹" => "Rose",
      "🌺" => "Hibiscus",
      "🌸" => "Cherry blossom",
      "🌼" => "Sunflower",
      "🌻" => "Sunflower",
      "🌞" => "Sun with face",
      "🐶" => "Dog face",
      "🐱" => "Cat face",
      "🐭" => "Mouse face",
      "🐹" => "Hamster",
      "🐰" => "Rabbit face",
      "🦊" => "Fox",
      "🐻" => "Bear",
      "🐼" => "Panda",
      "🐨" => "Koala"
    }
  }
end
