class Insight {
  final String id; // new
  final String heading;
  final String content;
  final String author;
  final String date;

  Insight({
    required this.id,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'content': content,
      'author': author,
      'date': date,
    };
  }

  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      id: map['id'],
      heading: map['heading'],
      content: map['content'],
      author: map['author'],
      date: map['date'],
    );
  }
}

// List of insights
final List<Insight> insightsList = [
  Insight(
    id: 'panic_1',
    heading: 'Understanding Panic Attacks',
    content: "What is a Panic Attack?\nImagine you are at school, work, or relaxing at home, and suddenly you feel very scared without knowing why. Your heart might start beating really fast, you might feel shaky, or it might feel like you cannot breathe very well. That is what we call a panic attack.\n\nA panic attack is like your body alarm going off by mistake, thinking there is danger even when everything is okay. It is just the way of your body getting ready to protect you, even when it does not need to.\n\nHow Does It Feel?\nHere are some things you might feel during a panic attack:\n\nFast Heartbeat: Like your heart is racing.\nShaking: Your hands or legs might tremble.\nBreathing Hard: It might feel like you cannot catch your breath.\nDizziness: The world might spin a little bit.\n\nBut remember, it is only a feeling, and it will pass soon. You are safe.",
    author: 'Team MindSarthi',
    date: 'Aug 8, 2024',
  ),
  Insight(
    id: 'panic_2',
    heading: 'Handling a Panic Attack',
    content: 'What Can You Do When It Happens?\nIf you ever have a panic attack, here are some things you can try to feel better:\n\n1. Take Deep Breaths:\nBreathe in slowly through your nose like you are smelling a flower.\nHold your breath for a moment.\nBreathe out slowly through your mouth like you are blowing out a candle.\n\n2. Hold Something Comforting:\nHolding something soft and comforting can make you feel safe and loved.\n\n3. Count to Ten:\nCounting slowly helps you focus on something other than the panic.\n\n4. Think Happy Thoughts:\nPicture your favorite place or remember a fun time with friends or family.\n\n5. Ask for a Hug:\nSometimes a hug from a loved one can make everything feel better.',
    author: 'Team MindSarthi',
    date: 'Aug 8, 2024',
  ),
  Insight(
    id: 'depression_1',
    heading: 'Understanding Depression',
    content: 'What is Depression?\nImagine waking up and feeling very sad, tired, or uninterested in things you usually enjoy. You might feel like this for weeks, even when nothing bad has happened. That is what we call "depression."\n\nDepression is like carrying a heavy backpack that makes everything feel harder. It\'s a medical condition that affects your mood, thoughts, and daily activities, but it can be treated with the right help and support.\n\nHow Does It Feel?\nHere are some common feelings and symptoms of depression:\n\n - Persistent Sadness: Feeling sad or empty most of the time.\n - Loss of Interest: Not wanting to do activities you used to enjoy.\n - Fatigue: Feeling tired all the time, even after a good nights sleep.\n - Changes in Sleep: Sleeping too much or having trouble sleeping.\n - Changes in Appetite: Eating too much or not wanting to eat at all.\n - Difficulty Concentrating: Finding it hard to focus or make decisions.\n\nRemember, feeling this way does not mean you are weak. It is okay to seek help.',
    author: 'Team MindSarthi',
    date: 'Aug 8, 2024',
  ),
  // Add more Insight instances if needed
];
